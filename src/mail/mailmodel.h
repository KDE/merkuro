// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "mailpresentationmodel.h"

#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>

class MailModel : public MailPresentationModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString folderName READ folderName NOTIFY folderNameChanged)
public:
    explicit MailModel(QObject *parent = nullptr);

    [[nodiscard]] QString folderName() const;

Q_SIGNALS:
    void folderNameChanged();

private:
    void updateFolderName();
    void updateFolderNameFromSelection();

    QMetaObject::Connection m_collectionSelectionConnection;
    QString m_folderName;
};
