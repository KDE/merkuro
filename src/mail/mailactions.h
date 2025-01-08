// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>
namespace Akonadi
{
class MessageStatus;
}

// TODO this should interact with MailApplications
class MailActions : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QItemSelectionModel *selectionModel READ selectionModel WRITE setSelectionModel NOTIFY selectionModelChanged)

public:
    explicit MailActions(QObject *parent = nullptr);

    QItemSelectionModel *selectionModel() const;
    void setSelectionModel(QItemSelectionModel *selectionModel);

    Q_INVOKABLE void setReadState(bool isRead);
    Q_INVOKABLE void setImportantState(bool isRead);

Q_SIGNALS:
    void selectionModelChanged();

private:
    void modifyStatus(const QModelIndexList &indexes, std::function<Akonadi::MessageStatus(Akonadi::MessageStatus)> f);
    QItemSelectionModel *m_selectionModel = nullptr;
};
