// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <KIdentityManagement/Identity>
#include <KIdentityManagement/Signature>
#include <QObject>
#include <qobjectdefs.h>

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{
class IdentityWrapper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool mailingAllowed READ mailingAllowed NOTIFY mailingAllowedChanged)
    Q_PROPERTY(QString identityName READ identityName WRITE setIdentityName NOTIFY identityNameChanged)
    Q_PROPERTY(QString fullName READ fullName WRITE setFullName NOTIFY fullNameChanged)
    Q_PROPERTY(QString organization READ organization WRITE setOrganization NOTIFY organizationChanged)
    Q_PROPERTY(QByteArray pgpEncryptionKey READ pgpEncryptionKey WRITE setPGPEncryptionKey NOTIFY pgpEncryptionKeyChanged)
    Q_PROPERTY(QByteArray pgpSigningKey READ pgpSigningKey WRITE setPGPSigningKey NOTIFY pgpSigningKeyChanged)
    Q_PROPERTY(QByteArray smimeEncryptionKey READ smimeEncryptionKey WRITE setSMIMEEncryptionKey NOTIFY smimeEncryptionKeyChanged)
    Q_PROPERTY(QByteArray smimeSigningKey READ smimeSigningKey WRITE setSMIMESigningKey NOTIFY smimeSigningKeyChanged)
    Q_PROPERTY(
        QString preferredCryptoMessageFormat READ preferredCryptoMessageFormat WRITE setPreferredCryptoMessageFormat NOTIFY preferredCryptoMessageFormatChanged)
    Q_PROPERTY(QString primaryEmailAddress READ primaryEmailAddress WRITE setPrimaryEmailAddress NOTIFY primaryEmailAddressChanged)
    Q_PROPERTY(QStringList emailAliases READ emailAliases WRITE setEmailAliases NOTIFY emailAliasesChanged)
    Q_PROPERTY(QString vCardFile READ vCardFile WRITE setVCardFile NOTIFY vCardFileChanged)
    Q_PROPERTY(QString fullEmailAddr READ fullEmailAddr NOTIFY fullEmailAddrChanged)
    Q_PROPERTY(QString replyToAddr READ replyToAddr WRITE setReplyToAddr NOTIFY replyToAddrChanged)
    Q_PROPERTY(QString bcc READ bcc WRITE setBcc NOTIFY bccChanged)
    Q_PROPERTY(QString cc READ cc WRITE setCc NOTIFY ccChanged)
    Q_PROPERTY(bool attachVcard READ attachVcard WRITE setAttachVcard NOTIFY attachVcardChanged)
    Q_PROPERTY(QString autocorrectionLanguage READ autocorrectionLanguage WRITE setAutocorrectionLanguage NOTIFY autocorrectionLanguageChanged)
    Q_PROPERTY(bool disabledFcc READ disabledFcc WRITE setDisabledFcc NOTIFY disabledFccChanged)
    Q_PROPERTY(bool pgpAutoSign READ pgpAutoSign WRITE setPgpAutoSign NOTIFY pgpAutoSignChanged)
    Q_PROPERTY(bool pgpAutoEncrypt READ pgpAutoEncrypt WRITE setPgpAutoEncrypt NOTIFY pgpAutoEncryptChanged)
    Q_PROPERTY(bool autocryptEnabled READ autocryptEnabled WRITE setAutocryptEnabled NOTIFY autocryptEnabledChanged)
    Q_PROPERTY(bool autocryptPrefer READ autocryptPrefer WRITE setAutocryptPrefer NOTIFY autocryptPreferChanged)
    Q_PROPERTY(bool encryptionOverride READ encryptionOverride WRITE setEncryptionOverride NOTIFY encryptionOverrideChanged)
    Q_PROPERTY(bool warnNotSign READ warnNotSign WRITE setWarnNotSign NOTIFY warnNotSignChanged)
    Q_PROPERTY(bool warnNotEncrypt READ warnNotEncrypt WRITE setWarnNotEncrypt NOTIFY warnNotEncryptChanged)
    Q_PROPERTY(QString defaultDomainName READ defaultDomainName WRITE setDefaultDomainName NOTIFY defaultDomainNameChanged)
    Q_PROPERTY(Signature signature READ signature WRITE setSignature NOTIFY signatureChanged)
    Q_PROPERTY(QString signatureText READ signatureText NOTIFY signatureTextChanged)
    Q_PROPERTY(bool signatureIsInlinedHtml READ signatureIsInlinedHtml NOTIFY signatureIsInlinedHtmlChanged)
    Q_PROPERTY(QString transport READ transport WRITE setTransport NOTIFY transportChanged)
    Q_PROPERTY(QString fcc READ fcc WRITE setFcc NOTIFY fccChanged)
    Q_PROPERTY(QString drafts READ drafts WRITE setDrafts NOTIFY draftsChanged)
    Q_PROPERTY(QString templates READ templates WRITE setTemplates NOTIFY templatesChanged)
    Q_PROPERTY(QString dictionary READ dictionary WRITE setDictionary NOTIFY dictionaryChanged)
    Q_PROPERTY(QString xface READ xface WRITE setXFace NOTIFY xfaceChanged)
    Q_PROPERTY(bool isXFaceEnabled READ isXFaceEnabled WRITE setXFaceEnabled NOTIFY isXFaceEnabledChanged)
    Q_PROPERTY(QString face READ face WRITE setFace NOTIFY faceChanged)
    Q_PROPERTY(bool isFaceEnabled READ isFaceEnabled WRITE setFaceEnabled NOTIFY isFaceEnabledChanged)
    Q_PROPERTY(uint uoid READ uoid CONSTANT)
    Q_PROPERTY(bool isNull READ isNull NOTIFY isNullChanged)

public:
    explicit IdentityWrapper(const Identity &identity);

    /** Tests if there are enough values set to allow mailing */
    Q_REQUIRED_RESULT bool mailingAllowed() const;

    /** Identity/nickname for this collection */
    Q_REQUIRED_RESULT QString identityName() const;
    void setIdentityName(const QString &name);

    /** @return whether this identity is the default identity */
    Q_REQUIRED_RESULT bool isDefault() const;

    /** Unique Object Identifier for this identity */
    Q_REQUIRED_RESULT uint uoid() const;

    /** Full name of the user */
    Q_REQUIRED_RESULT QString fullName() const;
    void setFullName(const QString &);

    /** The user's organization (optional) */
    Q_REQUIRED_RESULT QString organization() const;
    void setOrganization(const QString &);

    /** The user's OpenPGP encryption key */
    Q_REQUIRED_RESULT QByteArray pgpEncryptionKey() const;
    void setPGPEncryptionKey(const QByteArray &key);

    /** The user's OpenPGP signing key */
    Q_REQUIRED_RESULT QByteArray pgpSigningKey() const;
    void setPGPSigningKey(const QByteArray &key);

    /** The user's S/MIME encryption key */
    Q_REQUIRED_RESULT QByteArray smimeEncryptionKey() const;
    void setSMIMEEncryptionKey(const QByteArray &key);

    /** The user's S/MIME signing key */
    Q_REQUIRED_RESULT QByteArray smimeSigningKey() const;
    void setSMIMESigningKey(const QByteArray &key);

    Q_REQUIRED_RESULT QString preferredCryptoMessageFormat() const;
    void setPreferredCryptoMessageFormat(const QString &);

    /**
     * primary email address (without the user name - only name\@host).
     * The primary email address is used for all outgoing mail.
     */
    Q_REQUIRED_RESULT QString primaryEmailAddress() const;
    void setPrimaryEmailAddress(const QString &email);

    /** email address aliases */
    Q_REQUIRED_RESULT const QStringList emailAliases() const;
    void setEmailAliases(const QStringList &aliases);

    /**
     * @param addr the email address to check
     * @return true if this identity contains the email address @p addr, either
     *         as primary address or as alias
     */
    Q_REQUIRED_RESULT bool matchesEmailAddress(const QString &addr) const;

    /** vCard to attach to outgoing emails */
    Q_REQUIRED_RESULT QString vCardFile() const;
    void setVCardFile(const QString &);

    /**
     * email address in the format "username <name@host>" suitable for the
     * "From:" field of email messages.
     */
    Q_REQUIRED_RESULT QString fullEmailAddr() const;

    /** email address for the ReplyTo: field */
    Q_REQUIRED_RESULT QString replyToAddr() const;
    void setReplyToAddr(const QString &);

    /** email addresses for the BCC: field */
    Q_REQUIRED_RESULT QString bcc() const;
    void setBcc(const QString &);

    /** email addresses for the CC: field */
    Q_REQUIRED_RESULT QString cc() const;
    void setCc(const QString &);

    Q_REQUIRED_RESULT bool attachVcard() const;
    void setAttachVcard(bool attach);

    QString autocorrectionLanguage() const;
    void setAutocorrectionLanguage(const QString &language);

    Q_REQUIRED_RESULT bool disabledFcc() const;
    void setDisabledFcc(bool);

    Q_REQUIRED_RESULT bool pgpAutoSign() const;
    void setPgpAutoSign(bool);

    Q_REQUIRED_RESULT bool pgpAutoEncrypt() const;
    void setPgpAutoEncrypt(bool);

    Q_REQUIRED_RESULT bool autocryptEnabled() const;
    void setAutocryptEnabled(const bool);

    Q_REQUIRED_RESULT bool autocryptPrefer() const;
    void setAutocryptPrefer(const bool);

    Q_REQUIRED_RESULT bool encryptionOverride() const;
    void setEncryptionOverride(const bool);

    Q_REQUIRED_RESULT bool warnNotSign() const;
    void setWarnNotSign(const bool);

    Q_REQUIRED_RESULT bool warnNotEncrypt() const;
    void setWarnNotEncrypt(const bool);

    Q_REQUIRED_RESULT QString defaultDomainName() const;
    void setDefaultDomainName(const QString &domainName);

    Q_REQUIRED_RESULT Signature signature();
    void setSignature(const Signature &sig);

    /**
     * @return the signature with '-- \n' prepended to it if it is not
     *         present already. No newline in front of or after the signature
     *         is added.
     */
    Q_REQUIRED_RESULT QString signatureText() const;

    /**
     * @return true if the inlined signature is html formatted
     */
    Q_REQUIRED_RESULT bool signatureIsInlinedHtml() const;

    /** The transport that is set for this identity. Used to link a
     * transport with an identity.
     */
    Q_REQUIRED_RESULT QString transport() const;
    void setTransport(const QString &);

    /**
     * The folder where sent messages from this identity will be
     * stored by default.
     */
    Q_REQUIRED_RESULT QString fcc() const;
    void setFcc(const QString &);

    /**
     * The folder where draft messages from this identity will be
     * stored by default.
     */
    Q_REQUIRED_RESULT QString drafts() const;
    void setDrafts(const QString &);

    /**
     * The folder where template messages from this identity will be
     * stored by default.
     */
    Q_REQUIRED_RESULT QString templates() const;
    void setTemplates(const QString &);

    /**
     * Dictionary which should be used for spell checking
     *
     * Note that this is the localized language name (e.g. "British English"),
     * _not_ the language code or dictionary name!
     */
    Q_REQUIRED_RESULT QString dictionary() const;
    void setDictionary(const QString &);

    /** a X-Face header for this identity */
    Q_REQUIRED_RESULT QString xface() const;
    void setXFace(const QString &);
    Q_REQUIRED_RESULT bool isXFaceEnabled() const;
    void setXFaceEnabled(bool);

    /** a Face header for this identity */
    Q_REQUIRED_RESULT QString face() const;
    void setFace(const QString &);
    Q_REQUIRED_RESULT bool isFaceEnabled() const;
    void setFaceEnabled(bool);

    /**
     * Get random properties
     *  @param key the key of the property to get
     */
    Q_REQUIRED_RESULT QVariant property(const QString &key) const;
    void setProperty(const QString &key, const QVariant &value);

    Q_REQUIRED_RESULT bool isNull() const;

Q_SIGNALS:
    void mailingAllowedChanged();
    void identityNameChanged();
    void fullNameChanged();
    void organizationChanged();
    void pgpEncryptionKeyChanged();
    void pgpSigningKeyChanged();
    void smimeEncryptionKeyChanged();
    void smimeSigningKeyChanged();
    void preferredCryptoMessageFormatChanged();
    void primaryEmailAddressChanged();
    void emailAliasesChanged();
    void vCardFileChanged();
    void fullEmailAddrChanged();
    void replyToAddrChanged();
    void bccChanged();
    void ccChanged();
    void attachVcardChanged();
    void autocorrectionLanguageChanged();
    void disabledFccChanged();
    void pgpAutoSignChanged();
    void pgpAutoEncryptChanged();
    void autocryptEnabledChanged();
    void autocryptPreferChanged();
    void encryptionOverrideChanged();
    void warnNotSignChanged();
    void warnNotEncryptChanged();
    void defaultDomainNameChanged();
    void signatureChanged();
    void signatureTextChanged();
    void signatureIsInlinedHtmlChanged();
    void transportChanged();
    void fccChanged();
    void draftsChanged();
    void templatesChanged();
    void dictionaryChanged();
    void xfaceChanged();
    void isXFaceEnabledChanged();
    void faceChanged();
    void isFaceEnabledChanged();
    void uoidChanged();
    void isNullChanged();

private:
    Identity m_identity;
};
}
}
