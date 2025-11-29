// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "certificatesmodel.h"

#include <QProcess>
#include <QStandardPaths>

#include <KLocalizedString>

#include <Libkleo/Formatting>
#include <Libkleo/KeyCache>

#include <gpgme++/key.h>
using namespace Qt::Literals::StringLiterals;
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
    for (const auto &email : std::as_const(m_emails)) {
        const auto keys = keyCache->findByEMailAddress(email.toStdString());
        m_keys.insert(m_keys.end(), keys.begin(), keys.end());
    }

    auto last = std::unique(m_keys.begin(), m_keys.end(), [](const GpgME::Key &a, const GpgME::Key &b) {
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
        {Qt::DisplayRole, "displayName"_ba},
        {FingerprintRole, "fingerprint"_ba},
        {FingerprintAccessRole, "fingerprintAccess"_ba},
        {TagsRole, "tags"_ba},
    };
}

void CertificatesModel::openKleopatra(const int row, QWindow *window)
{
    Q_ASSERT(checkIndex(index(row, 0), QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto &key = m_keys[row];

    QStringList lst;
    lst << u"--parent-windowid"_s << QString::number(static_cast<qlonglong>(window->winId())) << u"--query"_s
        << QString::fromStdString(key.primaryFingerprint());
#ifdef Q_OS_WIN
    QString exec = QStandardPaths::findExecutable(u"kleopatra.exe"_s, {QCoreApplication::applicationDirPath()});
    if (exec.isEmpty()) {
        exec = QStandardPaths::findExecutable(u"kleopatra.exe"_s);
    }
#else
    const QString exec = QStandardPaths::findExecutable(u"kleopatra"_s);
#endif

    QProcess::startDetached(exec, lst);
}

#include "moc_certificatesmodel.cpp"
