// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "identitywrapper.h"

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{

IdentityWrapper::IdentityWrapper(Identity &identity, QObject *const parent)
    : QObject(parent)
    , m_identity(identity)
{
}

bool IdentityWrapper::mailingAllowed() const
{
    return m_identity.mailingAllowed();
}

QString IdentityWrapper::identityName() const
{
    return m_identity.identityName();
}

void IdentityWrapper::setIdentityName(const QString &identityName)
{
    if (m_identity.identityName() == identityName) {
        return;
    }

    m_identity.setIdentityName(identityName);
    Q_EMIT identityNameChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::fullName() const
{
    return m_identity.fullName();
}

void IdentityWrapper::setFullName(const QString &fullName)
{
    if (m_identity.fullName() == fullName) {
        return;
    }

    m_identity.setFullName(fullName);
    Q_EMIT fullNameChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::organization() const
{
    return m_identity.organization();
}

void IdentityWrapper::setOrganization(const QString &organization)
{
    if (m_identity.organization() == organization) {
        return;
    }

    m_identity.setOrganization(organization);
    Q_EMIT organizationChanged();
    Q_EMIT isNullChanged();
}

QByteArray IdentityWrapper::pgpEncryptionKey() const
{
    return m_identity.pgpEncryptionKey();
}

void IdentityWrapper::setPGPEncryptionKey(const QByteArray &pgpEncryptionKey)
{
    if (m_identity.pgpEncryptionKey() == pgpEncryptionKey) {
        return;
    }

    m_identity.setPGPEncryptionKey(pgpEncryptionKey);
    Q_EMIT pgpEncryptionKeyChanged();
    Q_EMIT isNullChanged();
}

QByteArray IdentityWrapper::pgpSigningKey() const
{
    return m_identity.pgpSigningKey();
}

void IdentityWrapper::setPGPSigningKey(const QByteArray &pgpSigningKey)
{
    if (m_identity.pgpSigningKey() == pgpSigningKey) {
        return;
    }

    m_identity.setPGPSigningKey(pgpSigningKey);
    Q_EMIT pgpSigningKeyChanged();
    Q_EMIT isNullChanged();
}

QByteArray IdentityWrapper::smimeEncryptionKey() const
{
    return m_identity.smimeEncryptionKey();
}

void IdentityWrapper::setSMIMEEncryptionKey(const QByteArray &smimeEncryptionKey)
{
    if (m_identity.smimeEncryptionKey() == smimeEncryptionKey) {
        return;
    }

    m_identity.setSMIMEEncryptionKey(smimeEncryptionKey);
    Q_EMIT smimeEncryptionKeyChanged();
    Q_EMIT isNullChanged();
}

QByteArray IdentityWrapper::smimeSigningKey() const
{
    return m_identity.smimeSigningKey();
}

void IdentityWrapper::setSMIMESigningKey(const QByteArray &smimeSigningKey)
{
    if (m_identity.smimeSigningKey() == smimeSigningKey) {
        return;
    }

    m_identity.setSMIMESigningKey(smimeSigningKey);
    Q_EMIT smimeSigningKeyChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::preferredCryptoMessageFormat() const
{
    return m_identity.preferredCryptoMessageFormat();
}

void IdentityWrapper::setPreferredCryptoMessageFormat(const QString &preferredCryptoMessageFormat)
{
    if (m_identity.preferredCryptoMessageFormat() == preferredCryptoMessageFormat) {
        return;
    }

    m_identity.setPreferredCryptoMessageFormat(preferredCryptoMessageFormat);
    Q_EMIT preferredCryptoMessageFormatChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::primaryEmailAddress() const
{
    return m_identity.primaryEmailAddress();
}

void IdentityWrapper::setPrimaryEmailAddress(const QString &primaryEmailAddress)
{
    if (m_identity.primaryEmailAddress() == primaryEmailAddress) {
        return;
    }

    m_identity.setPrimaryEmailAddress(primaryEmailAddress);
    Q_EMIT primaryEmailAddressChanged();
    Q_EMIT mailingAllowedChanged();
    Q_EMIT isNullChanged();
}

const QStringList IdentityWrapper::emailAliases() const
{
    return m_identity.emailAliases();
}

void IdentityWrapper::setEmailAliases(const QStringList &emailAliases)
{
    if (m_identity.emailAliases() == emailAliases) {
        return;
    }

    m_identity.setEmailAliases(emailAliases);
    Q_EMIT emailAliasesChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::vCardFile() const
{
    return m_identity.vCardFile();
}

void IdentityWrapper::setVCardFile(const QString &vCardFile)
{
    if (m_identity.vCardFile() == vCardFile) {
        return;
    }

    m_identity.setVCardFile(vCardFile);
    Q_EMIT vCardFileChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::fullEmailAddr() const
{
    return m_identity.fullEmailAddr();
}

QString IdentityWrapper::replyToAddr() const
{
    return m_identity.replyToAddr();
}

void IdentityWrapper::setReplyToAddr(const QString &replyToAddr)
{
    if (m_identity.replyToAddr() == replyToAddr) {
        return;
    }

    m_identity.setReplyToAddr(replyToAddr);
    Q_EMIT replyToAddrChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::bcc() const
{
    return m_identity.bcc();
}

void IdentityWrapper::setBcc(const QString &bcc)
{
    if (m_identity.bcc() == bcc) {
        return;
    }

    m_identity.setBcc(bcc);
    Q_EMIT bccChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::cc() const
{
    return m_identity.cc();
}

void IdentityWrapper::setCc(const QString &cc)
{
    if (m_identity.cc() == cc) {
        return;
    }

    m_identity.setCc(cc);
    Q_EMIT ccChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::attachVcard() const
{
    return m_identity.attachVcard();
}

void IdentityWrapper::setAttachVcard(bool attachVcard)
{
    if (m_identity.attachVcard() == attachVcard) {
        return;
    }

    m_identity.setAttachVcard(attachVcard);
    Q_EMIT attachVcardChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::autocorrectionLanguage() const
{
    return m_identity.autocorrectionLanguage();
}

void IdentityWrapper::setAutocorrectionLanguage(const QString &autocorrectionLanguage)
{
    if (m_identity.autocorrectionLanguage() == autocorrectionLanguage) {
        return;
    }

    m_identity.setAutocorrectionLanguage(autocorrectionLanguage);
    Q_EMIT autocorrectionLanguageChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::disabledFcc() const
{
    return m_identity.disabledFcc();
}

void IdentityWrapper::setDisabledFcc(bool disabledFcc)
{
    if (m_identity.disabledFcc() == disabledFcc) {
        return;
    }

    m_identity.setDisabledFcc(disabledFcc);
    Q_EMIT disabledFccChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::pgpAutoSign() const
{
    return m_identity.pgpAutoSign();
}

void IdentityWrapper::setPgpAutoSign(bool pgpAutoSign)
{
    if (m_identity.pgpAutoSign() == pgpAutoSign) {
        return;
    }

    m_identity.setPgpAutoSign(pgpAutoSign);
    Q_EMIT pgpAutoSignChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::pgpAutoEncrypt() const
{
    return m_identity.pgpAutoEncrypt();
}

void IdentityWrapper::setPgpAutoEncrypt(bool pgpAutoEncrypt)
{
    if (m_identity.pgpAutoEncrypt() == pgpAutoEncrypt) {
        return;
    }

    m_identity.setPgpAutoEncrypt(pgpAutoEncrypt);
    Q_EMIT pgpAutoEncryptChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::autocryptEnabled() const
{
    return m_identity.autocryptEnabled();
}

void IdentityWrapper::setAutocryptEnabled(bool autocryptEnabled)
{
    if (m_identity.autocryptEnabled() == autocryptEnabled) {
        return;
    }

    m_identity.setAutocryptEnabled(autocryptEnabled);
    Q_EMIT autocryptEnabledChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::autocryptPrefer() const
{
    return m_identity.autocryptPrefer();
}

void IdentityWrapper::setAutocryptPrefer(bool autocryptPrefer)
{
    if (m_identity.autocryptPrefer() == autocryptPrefer) {
        return;
    }

    m_identity.setAutocryptPrefer(autocryptPrefer);
    Q_EMIT autocryptPreferChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::encryptionOverride() const
{
    return m_identity.encryptionOverride();
}

void IdentityWrapper::setEncryptionOverride(bool encryptionOverride)
{
    if (m_identity.encryptionOverride() == encryptionOverride) {
        return;
    }

    m_identity.setEncryptionOverride(encryptionOverride);
    Q_EMIT encryptionOverrideChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::warnNotSign() const
{
    return m_identity.warnNotSign();
}

void IdentityWrapper::setWarnNotSign(bool warnNotSign)
{
    if (m_identity.warnNotSign() == warnNotSign) {
        return;
    }

    m_identity.setWarnNotSign(warnNotSign);
    Q_EMIT warnNotSignChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::warnNotEncrypt() const
{
    return m_identity.warnNotEncrypt();
}

void IdentityWrapper::setWarnNotEncrypt(bool warnNotEncrypt)
{
    if (m_identity.warnNotEncrypt() == warnNotEncrypt) {
        return;
    }

    m_identity.setWarnNotEncrypt(warnNotEncrypt);
    Q_EMIT warnNotEncryptChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::defaultDomainName() const
{
    return m_identity.defaultDomainName();
}

void IdentityWrapper::setDefaultDomainName(const QString &defaultDomainName)
{
    if (m_identity.defaultDomainName() == defaultDomainName) {
        return;
    }

    m_identity.setDefaultDomainName(defaultDomainName);
    Q_EMIT defaultDomainNameChanged();
    Q_EMIT isNullChanged();
}

Signature IdentityWrapper::signature()
{
    return m_identity.signature();
}

void IdentityWrapper::setSignature(const Signature &signature)
{
    if (m_identity.signature() == signature) {
        return;
    }

    m_identity.setSignature(signature);
    Q_EMIT signatureChanged();
    Q_EMIT signatureTextChanged();
    Q_EMIT signatureIsInlinedHtmlChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::signatureText() const
{
    return m_identity.signatureText();
}

bool IdentityWrapper::signatureIsInlinedHtml() const
{
    return m_identity.signatureIsInlinedHtml();
}

QString IdentityWrapper::transport() const
{
    return m_identity.transport();
}

void IdentityWrapper::setTransport(const QString &transport)
{
    if (m_identity.transport() == transport) {
        return;
    }

    m_identity.setTransport(transport);
    Q_EMIT transportChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::fcc() const
{
    return m_identity.fcc();
}

void IdentityWrapper::setFcc(const QString &fcc)
{
    if (m_identity.fcc() == fcc) {
        return;
    }

    m_identity.setFcc(fcc);
    Q_EMIT fccChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::drafts() const
{
    return m_identity.drafts();
}

void IdentityWrapper::setDrafts(const QString &drafts)
{
    if (m_identity.drafts() == drafts) {
        return;
    }

    m_identity.setDrafts(drafts);
    Q_EMIT draftsChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::templates() const
{
    return m_identity.templates();
}

void IdentityWrapper::setTemplates(const QString &templates)
{
    if (m_identity.templates() == templates) {
        return;
    }

    m_identity.setTemplates(templates);
    Q_EMIT templatesChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::dictionary() const
{
    return m_identity.dictionary();
}

void IdentityWrapper::setDictionary(const QString &dictionary)
{
    if (m_identity.dictionary() == dictionary) {
        return;
    }

    m_identity.setDictionary(dictionary);
    Q_EMIT dictionaryChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::xface() const
{
    return m_identity.xface();
}

void IdentityWrapper::setXFace(const QString &xface)
{
    if (m_identity.xface() == xface) {
        return;
    }

    m_identity.setXFace(xface);
    Q_EMIT xfaceChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::isXFaceEnabled() const
{
    return m_identity.isXFaceEnabled();
}

void IdentityWrapper::setXFaceEnabled(bool xfaceEnabled)
{
    if (m_identity.isXFaceEnabled() == xfaceEnabled) {
        return;
    }

    m_identity.setXFaceEnabled(xfaceEnabled);
    Q_EMIT isXFaceEnabledChanged();
    Q_EMIT isNullChanged();
}

QString IdentityWrapper::face() const
{
    return m_identity.face();
}

void IdentityWrapper::setFace(const QString &face)
{
    if (m_identity.face() == face) {
        return;
    }

    m_identity.setFace(face);
    Q_EMIT faceChanged();
    Q_EMIT isNullChanged();
}

bool IdentityWrapper::isFaceEnabled() const
{
    return m_identity.isFaceEnabled();
}

void IdentityWrapper::setFaceEnabled(bool faceEnabled)
{
    if (m_identity.isFaceEnabled() == faceEnabled) {
        return;
    }

    m_identity.setFaceEnabled(faceEnabled);
    Q_EMIT isFaceEnabledChanged();
    Q_EMIT isNullChanged();
}

uint IdentityWrapper::uoid() const
{
    return m_identity.uoid();
}

bool IdentityWrapper::isNull() const
{
    return m_identity.isNull();
}
}
}