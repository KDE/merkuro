// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailmodel.h"

MailModel::MailModel(QObject *parent)
    : MailPresentationModel(parent)
{
    connect(this, &MailPresentationModel::collectionSelectionModelChanged, this, &MailModel::updateFolderName);
    updateFolderName();
}

void MailModel::updateFolderName()
{
    if (m_collectionSelectionConnection) {
        disconnect(m_collectionSelectionConnection);
    }

    if (auto *const selectionModel = collectionSelectionModel()) {
        m_collectionSelectionConnection = connect(selectionModel, &QItemSelectionModel::selectionChanged, this, &MailModel::updateFolderNameFromSelection);
    }
    updateFolderNameFromSelection();
}

void MailModel::updateFolderNameFromSelection()
{
    QString name;
    if (auto *const selectionModel = collectionSelectionModel()) {
        const auto indexes = selectionModel->selectedIndexes();
        if (!indexes.isEmpty()) {
            QModelIndex index = indexes[0];
            while (index.isValid()) {
                if (name.isEmpty()) {
                    name = index.data(Qt::DisplayRole).toString();
                } else {
                    name = index.data(Qt::DisplayRole).toString() + QLatin1StringView(" / ") + name;
                }
                index = index.parent();
            }
        }
    }

    if (m_folderName == name) {
        return;
    }

    m_folderName = name;
    Q_EMIT folderNameChanged();
}

QString MailModel::folderName() const
{
    return m_folderName;
}

#include "moc_mailmodel.cpp"
