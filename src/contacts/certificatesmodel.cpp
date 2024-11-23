// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "certificatesmodel.h"

#include <QProcess>
#include <QStandardPaths>

#include <KLocalizedString>

#include <Libkleo/Formatting>
#include <Libkleo/KeyCache>

#include <gpgme++/key.h>

CertificatesModel::CertificatesModel(QObject *parent)
    : QAbstractListModel(parent)
{
    auto keyCache = Kleo::KeyCache::instance();
    connect(keyCache.get(), &Kleo::KeyCache::keyListingDone, this, [this](const GpgME::KeyListResult &) {
        refresh();
    });
}

CertificatesModel::~CertificatesModel() = default;

QStringList CertificatesModel::emails() const
{
    return m_emails;
}

void CertificatesModel::setEmails(const QStringList &emails)
{
    if (emails == m_emails) {
        return;
    }
    m_emails = emails;
    Q_EMIT emailsChanged();

    refresh();
}

void CertificatesModel::refresh()
{
    auto keyCache = Kleo::KeyCache::instance();

    beginResetModel();
    m_keys.clear();
    for (const auto &email : m_emails) {
        const auto keys = keyCache->findByEMailAddress(email.toStdString());
        m_keys.insert(m_keys.end(), keys.begin(), keys.end());
    }

    auto last = std::unique(m_keys.begin(), m_keys.end(), [](GpgME::Key a, GpgME::Key b) {
        return a.primaryFingerprint() == b.primaryFingerprint();
    });
    m_keys.erase(last, m_keys.end());

    endResetModel();
}

int CertificatesModel::rowCount(const QModelIndex &index) const
{
    return index.isValid() ? 0 : m_keys.size();
}

QVariant CertificatesModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto &key = m_keys[index.row()];

    switch (role) {
    case Qt::DisplayRole:
        return Kleo::Formatting::prettyUserID(key.userIDs()[0]);
    case FingerprintRole:
        return Kleo::Formatting::prettyID(key.primaryFingerprint());
    case FingerprintAccessRole:
        return Kleo::Formatting::accessibleHexID(key.primaryFingerprint());
    case TagsRole: {
        QStringList tags;
        tags << Kleo::Formatting::displayName(key.protocol());
        if (key.isRevoked()) {
            tags << i18nc("@info: shorthand for the key is revoked", "Revoked");
        }
        if (key.isExpired()) {
            tags << i18nc("@info: shorthand for the key is expired", "Expired");
        }
        if (key.isDisabled()) {
            tags << i18nc("@info: shorthand for the key is disabled", "Disabled");
        }
        if (key.isInvalid()) {
            tags << i18nc("@info: shorthand for the key is invalid", "Invalid");
        }
        if (!key.isBad()) {
            tags << i18nc("@info: shorthand for the key is valid", "Valid");
        }
        QString compliance = Kleo::Formatting::complianceStringShort(key);
        compliance.replace(0, 1, compliance[0].toUpper());
        tags << compliance;
        return tags;
    }
    default:
        return {};
    }
}

QHash<int, QByteArray> CertificatesModel::roleNames() const
{
    return {
        {Qt::DisplayRole, "displayName"},
        {FingerprintRole, "fingerprint"},
        {FingerprintAccessRole, "fingerprintAccess"},
        {TagsRole, "tags"},
    };
}

void CertificatesModel::openKleopatra(const int row, QWindow *window)
{
    Q_ASSERT(checkIndex(index(row, 0), QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto &key = m_keys[row];

    QStringList lst;
    lst << QStringLiteral("--parent-windowid") << QString::number(static_cast<qlonglong>(window->winId())) << QStringLiteral("--query")
        << QString::fromStdString(key.primaryFingerprint());
#ifdef Q_OS_WIN
    QString exec = QStandardPaths::findExecutable(QStringLiteral("kleopatra.exe"), {QCoreApplication::applicationDirPath()});
    if (exec.isEmpty()) {
        exec = QStandardPaths::findExecutable(QStringLiteral("kleopatra.exe"));
    }
#else
    const QString exec = QStandardPaths::findExecutable(QStringLiteral("kleopatra"));
#endif

    QProcess::startDetached(exec, lst);
}

#include "moc_certificatesmodel.cpp"
