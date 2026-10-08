#include "markdownresourceguard.h"
#include <QGuiApplication>
#include <QFile>
#include <QImage>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTemporaryDir>
#include <QTest>
#include <QTextCursor>

class GuardTest : public QObject {
    Q_OBJECT
private slots:
    void resources() {
        QTemporaryDir directory;
        QImage local(12, 12, QImage::Format_ARGB32);
        local.fill(Qt::red);
        const auto path = directory.filePath("secret.png");
        QVERIFY(local.save(path));
        GuardedTextDocument document;
        int fallbacks = 0;
        document.setResourceProvider([&](const QUrl &) { ++fallbacks; return local; });
        for (const auto &url : {QUrl::fromLocalFile(path), QUrl("https://example.com/a"),
                 QUrl("http://127.0.0.1/a"), QUrl("qrc:/a"), QUrl("data:image/png;base64,AA=="), QUrl("relative.png")}) {
            const auto image = qvariant_cast<QImage>(document.resource(QTextDocument::ImageResource, url));
            QCOMPARE(image.size(), QSize(1, 1));
            QCOMPARE(image.pixelColor(0, 0).alpha(), 0);
            for (int type : {QTextDocument::HtmlResource, QTextDocument::StyleSheetResource, QTextDocument::MarkdownResource}) {
                const auto value = document.resource(type, url);
                QVERIFY(value.isValid());
                QVERIFY(value.toByteArray().isEmpty());
            }
        }
        QCOMPARE(fallbacks, 0);
    }

    void renderer() {
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        int requests = 0;
        connect(&server, &QTcpServer::newConnection, this, [&] {
            while (auto *socket = server.nextPendingConnection()) {
                connect(socket, &QTcpSocket::readyRead, socket, [&, socket] {
                    socket->readAll();
                    ++requests;
                    socket->write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                    socket->disconnectFromHost();
                });
                connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            }
        });
        QQmlEngine engine;
        QFile logic(qEnvironmentVariable("COUCH_MARKDOWN_LOGIC"));
        QVERIFY(logic.open(QIODevice::ReadOnly));
        QVERIFY(!engine.evaluate(QString::fromUtf8(logic.readAll())).isError());
        auto rewrite = engine.globalObject().property("renderImagesAsLinks");
        QVERIFY(rewrite.isCallable());
        QQmlComponent component(&engine);
        component.setData("import QtQuick\nTextEdit { width: 500; height: 400; readOnly: true; selectByMouse: true; selectByKeyboard: true; textFormat: TextEdit.MarkdownText }", QUrl());
        QScopedPointer<QObject> positive(component.create());
        QVERIFY2(positive, qPrintable(component.errorString()));
        QQuickWindow window;
        window.resize(640, 480);
        qobject_cast<QQuickItem *>(positive.data())->setParentItem(window.contentItem());
        window.show();
        const QString url = QString("http://127.0.0.1:%1/image").arg(server.serverPort());
        positive->setProperty("text", QString("![control](%1)").arg(url));
        QTRY_VERIFY_WITH_TIMEOUT(requests > 0, 3000);
        const QStringList bypasses = {
            QString("`\n\n![bypass](%1/paragraph)\n\n`").arg(url),
            QString("<!--\n~~~\n-->\n![bypass](%1/comment)\n~~~").arg(url),
        };
        for (const auto &bypass : bypasses) {
            const int before = requests;
            positive->setProperty("text", rewrite.call({bypass}).toString());
            QTRY_VERIFY_WITH_TIMEOUT(requests > before, 3000);
        }
        positive.reset();
        QTest::qWait(100);
        const int baseline = requests;

        QScopedPointer<QObject> guarded(component.create());
        qobject_cast<QQuickItem *>(guarded.data())->setParentItem(window.contentItem());
        auto *quickDocument = qvariant_cast<QQuickTextDocument *>(guarded->property("textDocument"));
        MarkdownResourceGuard guard;
        QVERIFY(!guard.install(nullptr));
        QVERIFY(guard.install(quickDocument));
        QVERIFY(guard.install(quickDocument));
        QStringList samples = {
            QString("![ordinary](%1)").arg(url),
            QString("![reference][asset]\n\n[asset]: %1").arg(url),
            QString("<img src=\"%1\">").arg(url),
        };
        for (const auto &bypass : bypasses)
            samples.append(rewrite.call({bypass}).toString());
        for (const auto &sample : samples) {
            guarded->setProperty("text", sample);
            QTest::qWait(60);
            QCOMPARE(requests, baseline);
            // Model incremental streaming, including incomplete image syntax.
            for (int i = 1; i <= sample.size(); ++i) {
                guarded->setProperty("text", sample.left(i));
                QCoreApplication::processEvents();
            }
            QTest::qWait(60);
            QCOMPARE(requests, baseline);
        }
        guarded->setProperty("text", "# Heading\n\n**Bold** and *italic*\n\n- item\n\n[link](https://example.com)");
        auto *document = quickDocument->textDocument();
        QVERIFY(document->toPlainText().contains("Heading"));
        QTextCursor cursor(document);
        cursor = document->find("Bold");
        QCOMPARE(cursor.charFormat().fontWeight(), QFont::Bold);
        cursor = document->find("italic");
        QVERIFY(cursor.charFormat().fontItalic());
        QVERIFY(QMetaObject::invokeMethod(guarded.data(), "selectAll"));
        QVERIFY(guarded->property("selectedText").toString().contains("Bold"));
        QVERIFY(!guard.install(qvariant_cast<QQuickTextDocument *>([&] {
            auto *item = component.create();
            item->setParent(&engine);
            item->setProperty("text", "Already populated");
            return item->property("textDocument");
        }())));
    }
};

QTEST_MAIN(GuardTest)
#include "tst_markdownresourceguard.moc"
