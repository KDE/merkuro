// SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmetadata.h"

#include "attributes/contactmetadataattribute_p.h"

#include <Akonadi/Item>

using namespace Akonadi;
using namespace Qt::Literals::StringLiterals;
ContactMetaData::ContactMetaData() = default;

ContactMetaData::~ContactMetaData() = default;

void ContactMetaData::load(const Akonadi::Item &contact)
{
    if (!contact.hasAttribute("contactmetadata")) {
        return;
    }
    const auto attribute = contact.attribute<ContactMetaDataAttribute>();
    const QVariantMap metaData = attribute->metaData();
    loadMetaData(metaData);
}

void ContactMetaData::store(Akonadi::Item &contact)
{
    auto attribute = contact.attribute<ContactMetaDataAttribute>(Item::AddIfMissing);

    attribute->setMetaData(storeMetaData());
}

void ContactMetaData::loadMetaData(const QVariantMap &metaData)
{
    m_displayNameMode = metaData.value(u"DisplayNameMode"_s, -1).toInt();

    m_customFieldDescriptions = metaData.value(u"CustomFieldDescriptions"_s).toList();
}

QVariantMap ContactMetaData::storeMetaData() const
{
    QVariantMap metaData;
    if (m_displayNameMode != -1) {
        metaData.insert(u"DisplayNameMode"_s, QVariant(m_displayNameMode));
    }

    if (m_customFieldDescriptions.isEmpty()) {
        metaData.insert(u"CustomFieldDescriptions"_s, m_customFieldDescriptions);
    }
    return metaData;
}

void ContactMetaData::setDisplayNameMode(int mode)
{
    m_displayNameMode = mode;
}

int ContactMetaData::displayNameMode() const
{
    return m_displayNameMode;
}

void ContactMetaData::setCustomFieldDescriptions(const QVariantList &descriptions)
{
    m_customFieldDescriptions = descriptions;
}

QVariantList ContactMetaData::customFieldDescriptions() const
{
    return m_customFieldDescriptions;
}
