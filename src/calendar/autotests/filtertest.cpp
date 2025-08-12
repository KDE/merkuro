// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "filter.h"

#include <QSignalSpy>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class FilterTest : public QObject
{
    Q_OBJECT

public:
    FilterTest() = default;
    ~FilterTest() override = default;

private:
    static constexpr qint64 m_testCollectionId = 1;
    const QString m_testName = u"name"_s;
    const QStringList m_testTags{u"tag-1"_s, u"tag-2"_s, u"tag-3"_s};

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testProperties()
    {
        Filter filter;
        QSignalSpy collectionIdChanged(&filter, &Filter::collectionIdChanged);
        QSignalSpy tagsChanged(&filter, &Filter::tagsChanged);
        QSignalSpy nameChanged(&filter, &Filter::nameChanged);

        filter.setCollectionId(m_testCollectionId);
        QCOMPARE(collectionIdChanged.count(), 1);
        QCOMPARE(filter.collectionId(), m_testCollectionId);

        filter.setTags(m_testTags);
        QCOMPARE(tagsChanged.count(), 1);
        QCOMPARE(filter.tags(), m_testTags);

        filter.setName(m_testName);
        QCOMPARE(nameChanged.count(), 1);
        QCOMPARE(filter.name(), m_testName);
    }
};

QTEST_MAIN(FilterTest)
#include "filtertest.moc"
