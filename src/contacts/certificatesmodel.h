// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "merkuro_contact_export.h"
#include <QAbstractListModel>
#include <QWindow>
#include <qqmlregistration.h>

namespace GpgME
{
class Key;
}

class MERKURO_CONTACT_EXPORT CertificatesModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QStringList emails READ emails WRITE setEmails NOTIFY emailsChanged)

public:
    enum ExtraRole {
        FingerprintRole = Qt::UserRole + 1,
        FingerprintAccessRole,
        TagsRole,
    };

    explicit CertificatesModel(QObject *parent = nullptr);
    ~CertificatesModel();

    QStringList emails() const;
    void setEmails(const QStringList &emails);

    int rowCount(const QModelIndex &index) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void openKleopatra(const int row, QWindow *window);

Q_SIGNALS:
    void emailsChanged();

private:
    void refresh();

    QStringList m_emails;
    std::vector<GpgME::Key> m_keys;
};
