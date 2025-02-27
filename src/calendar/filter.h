// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later
#pragma once
#include <QObject>

/**
 * This class is used to enable cross-compatible filtering of data in models.
 */
class Filter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QStringList tags READ tags WRITE setTags NOTIFY tagsChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool showCurrentDayOnly READ showCurrentDayOnly WRITE setShowCurrentDayOnly NOTIFY showCurrentDayOnlyChanged)

public:
    [[nodiscard]] qint64 collectionId() const;
    [[nodiscard]] QStringList tags() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] bool showCurrentDayOnly() const;

public Q_SLOTS:
    void setCollectionId(const qint64 collectionId);
    void setTags(const QStringList &tags);
    void setName(const QString &name);
    void setShowCurrentDayOnly(bool show);

    void toggleFilterTag(const QString tagName);
    void reset();
    void removeTag(const QString &tagName);

Q_SIGNALS:
    void collectionIdChanged();
    void tagsChanged();
    void nameChanged();
    void showCurrentDayOnlyChanged();

private:
    qint64 m_collectionId = -1;
    QStringList m_tags;
    QString m_name;
    bool m_showCurrentDayOnly = false;
};
