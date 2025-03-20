// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "contactapplication.h"
#include "merkuro_contact_export.h"

#include <Akonadi/Item>

#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>

class MERKURO_CONTACT_EXPORT ContactActions : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QItemSelectionModel *selectionModel READ selectionModel WRITE setSelectionModel NOTIFY selectionModelChanged)
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem RESET unsetItem NOTIFY itemChanged)
    Q_PROPERTY(ContactApplication *contactApplication READ contactApplication WRITE setContactApplication NOTIFY contactApplicationChanged)

public:
    explicit ContactActions(QObject *parent = nullptr);

    QItemSelectionModel *selectionModel() const;
    void setSelectionModel(QItemSelectionModel *selectionModel);

    Akonadi::Item item() const;
    void setItem(const Akonadi::Item &item);
    void unsetItem();

    ContactApplication *contactApplication() const;
    void setContactApplication(ContactApplication *contactApplication);

    Q_INVOKABLE void setActionState();
    Q_INVOKABLE void moveTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination);
    Q_INVOKABLE void copyTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination);

    Q_INVOKABLE Akonadi::Item::List selectionToItems() const;

Q_SIGNALS:
    void selectionModelChanged();
    void contactApplicationChanged();
    void itemChanged();

    void moveToRequested(const Akonadi::Item::List &items);
    void copyToRequested(const Akonadi::Item::List &items);
    void deleteRequested(const Akonadi::Item::List &items, const QStringList &names);
    void editContactGroup(const Akonadi::Item::Id &itemId);
    void editContact(const Akonadi::Item::Id &itemId);

private:
    QItemSelectionModel *m_selectionModel = nullptr;
    ContactApplication *m_contactApplication = nullptr;
    Akonadi::Item m_item;

    QAction *m_contactMoveToAction = nullptr;
    QAction *m_contactCopyToAction = nullptr;
    QAction *m_contactEditAction = nullptr;
    QAction *m_contactDeleteAction = nullptr;
};
