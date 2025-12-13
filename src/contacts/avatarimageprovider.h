// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QQuickAsyncImageProvider>
#include <qqmlintegration.h>

class AvatarImageProvider : public QQuickAsyncImageProvider
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    using QQuickAsyncImageProvider::QQuickAsyncImageProvider;
    static AvatarImageProvider *create(QQmlEngine *engine, QJSEngine *);
    Q_INVOKABLE void init()
    {
    } // Hack for registering the image provider
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

private:
    AvatarImageProvider() = default;
};

class AvatarResponse : public QQuickImageResponse
{
public:
    AvatarResponse(const QString &itemId);
    QQuickTextureFactory *textureFactory() const override;

private:
    QImage m_image;
};
