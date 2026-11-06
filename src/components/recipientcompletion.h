// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QTimer>
#include <qqmlregistration.h>

class RecipientCompletion : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QStringList suggestions READ suggestions NOTIFY suggestionsChanged)

public:
    explicit RecipientCompletion(QObject *parent = nullptr);

    [[nodiscard]] QString searchText() const;
    void setSearchText(const QString &text);
    [[nodiscard]] QStringList suggestions() const;

Q_SIGNALS:
    void searchTextChanged();
    void suggestionsChanged();

private:
    QString m_searchText;
    QStringList m_suggestions;
    QTimer m_searchTimer;
    quint64 m_revision = 0;
};
