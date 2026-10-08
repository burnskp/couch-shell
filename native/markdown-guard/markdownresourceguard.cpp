#include "markdownresourceguard.h"
#include <QImage>

QVariant GuardedTextDocument::loadResource(int type, const QUrl &) {
    // Never delegate to Qt's loader, even for file, qrc or data URLs.
    // A valid result also prevents fallback to the global resource provider.
    if (type == QTextDocument::ImageResource) {
        QImage placeholder(1, 1, QImage::Format_ARGB32_Premultiplied);
        placeholder.fill(Qt::transparent);
        return placeholder;
    }
    return QByteArray("");
}

bool MarkdownResourceGuard::install(QQuickTextDocument *document) {
    if (!document || !document->textDocument())
        return false;
    if (dynamic_cast<GuardedTextDocument *>(document->textDocument()))
        return true;
    // Callers must keep untrusted content empty until installation succeeds.
    if (!document->textDocument()->isEmpty())
        return false;
    auto *guarded = new GuardedTextDocument(document);
    guarded->setDefaultFont(document->textDocument()->defaultFont());
    guarded->setDocumentMargin(document->textDocument()->documentMargin());
    document->setTextDocument(guarded);
    return document->textDocument() == guarded;
}
