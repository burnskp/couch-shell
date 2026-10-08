#pragma once

#include <QObject>
#include <QQuickTextDocument>
#include <QTextDocument>
#include <QtQml/qqmlregistration.h>

class GuardedTextDocument final : public QTextDocument {
public:
    using QTextDocument::QTextDocument;
protected:
    QVariant loadResource(int type, const QUrl &name) override;
};

class MarkdownResourceGuard final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    using QObject::QObject;
    Q_INVOKABLE bool install(QQuickTextDocument *document);
};
