// SPDX-FileCopyrightText: 2026 KDE contributors
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../models/timezonelistmodel.h"

#include <QAbstractItemModelTester>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QTest>
#include <QUrl>

#include <memory>

using namespace Qt::StringLiterals;

class TimeZoneTarget : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QByteArray timeZone READ timeZone WRITE setTimeZone NOTIFY timeZoneChanged)

public:
    QByteArray timeZone() const
    {
        return m_timeZone;
    }

    void setTimeZone(const QByteArray &timeZone)
    {
        if (m_timeZone == timeZone) {
            return;
        }
        m_timeZone = timeZone;
        Q_EMIT timeZoneChanged();
    }

Q_SIGNALS:
    void timeZoneChanged();

private:
    QByteArray m_timeZone;
};

class TimeZoneListModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testTimezoneLookupForEveryRow()
    {
        TimeZoneListModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(model.rowCount() > 0);

        for (int row = 0; row < model.rowCount(); ++row) {
            const auto index = model.index(row, 0);
            QVERIFY(index.isValid());

            const auto id = index.data(TimeZoneListModel::IdRole).toString();
            const auto matchingRow = model.getTimeZoneRow(id.toUtf8());
            QVERIFY(matchingRow >= 0 && matchingRow < model.rowCount());
            QCOMPARE(model.index(matchingRow, 0).data(TimeZoneListModel::IdRole).toString(), id);
        }
    }

    void testComboBoxCurrentValueForEveryTimezone()
    {
        TimeZoneListModel model;
        TimeZoneTarget target;
        QQmlEngine engine;
        engine.rootContext()->setContextProperty(u"timeZonesModel"_s, &model);
        engine.rootContext()->setContextProperty(u"target"_s, &target);

        QQmlComponent component(&engine);
        component.setData(R"qml(
            import QtQuick
            import QtQuick.Controls

            Item {
                ComboBox {
                    id: comboBox
                    model: timeZonesModel
                    textRole: "displayName"
                    valueRole: "id"
                    currentIndex: timeZonesModel.getTimeZoneRow("UTC")
                    onCurrentValueChanged: target.timeZone = currentValue
                }

                property alias selectedIndex: comboBox.currentIndex
            }
        )qml",
                          QUrl(u"Test.qml"_s));

        std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));

        for (int row = 0; row < model.rowCount(); ++row) {
            const auto id = model.index(row, 0).data(TimeZoneListModel::IdRole).toString().toUtf8();
            QVERIFY(object->setProperty("selectedIndex", row));
            QTRY_COMPARE(target.timeZone(), id);
        }
    }
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    TimeZoneListModelTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "timezonelistmodeltest.moc"
