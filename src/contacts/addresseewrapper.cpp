// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "addresseewrapper.h"
#include "merkuro_contact_debug.h"
#include <KContacts/VCardConverter>
#include <QGuiApplication>

AddresseeWrapper::AddresseeWrapper(QObject *parent)
    : QObject(parent)
    , m_addressesModel(new AddressModel(this))
    , m_emailModel(new EmailModel(this))
    , m_imppModel(new ImppModel(this))
    , m_phoneModel(new PhoneModel(this))
{
    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload();
    scope.fetchAllAttributes();
    scope.setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
    setFetchScope(scope);

    connect(m_emailModel, &EmailModel::changed, this, [this](const KContacts::Email::List &emails) {
        m_addressee.setEmailList(emails);
    });

    connect(m_phoneModel, &PhoneModel::changed, this, [this](const KContacts::PhoneNumber::List &phoneNumbers) {
        m_addressee.setPhoneNumbers(phoneNumbers);
    });

    connect(m_imppModel, &ImppModel::changed, this, [this](const KContacts::Impp::List &impps) {
        m_addressee.setImppList(impps);
    });
}

AddresseeWrapper::~AddresseeWrapper() = default;

void AddresseeWrapper::notifyDataChanged()
{
    Q_EMIT collectionChanged();
    Q_EMIT formattedNameChanged();
    Q_EMIT additionalNameChanged();
    Q_EMIT familyNameChanged();
    Q_EMIT givenNameChanged();
    Q_EMIT prefixChanged();
    Q_EMIT suffixChanged();
    Q_EMIT birthdayChanged();
    Q_EMIT photoChanged();
    Q_EMIT phoneNumbersChanged();
    Q_EMIT preferredEmailChanged();
    Q_EMIT uidChanged();
    Q_EMIT noteChanged();
    Q_EMIT nickNameChanged();
    Q_EMIT blogFeedChanged();
    Q_EMIT anniversaryChanged();
    Q_EMIT spousesNameChanged();
    Q_EMIT organizationChanged();
    Q_EMIT professionChanged();
    Q_EMIT titleChanged();
    Q_EMIT departmentChanged();
    Q_EMIT officeChanged();
    Q_EMIT managersNameChanged();
    Q_EMIT assistantsNameChanged();
}

Akonadi::Item AddresseeWrapper::addresseeItem() const
{
    return item();
}

AddressModel *AddresseeWrapper::addressesModel() const
{
    return m_addressesModel;
}

ImppModel *AddresseeWrapper::imppModel() const
{
    return m_imppModel;
}

void AddresseeWrapper::setAddresseeItem(const Akonadi::Item &addresseeItem)
{
    Akonadi::ItemMonitor::setItem(addresseeItem);
    if (addresseeItem.hasPayload<KContacts::Addressee>()) {
        setAddressee(addresseeItem.payload<KContacts::Addressee>());
        Q_EMIT addresseeItemChanged();
        Q_EMIT collectionChanged();
    } else {
        // Payload not found, try to fetch it
        auto job = new Akonadi::ItemFetchJob(addresseeItem);
        job->fetchScope().fetchFullPayload();
        connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
            auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
            auto item = fetchJob->items().at(0);
            if (item.hasPayload<KContacts::Addressee>()) {
                setAddressee(item.payload<KContacts::Addressee>());
                Q_EMIT addresseeItemChanged();
                Q_EMIT collectionChanged();
            } else {
                qCWarning(MERKURO_CONTACT_LOG) << "This is not an addressee item.";
            }
        });
    }
}

void AddresseeWrapper::itemChanged(const Akonadi::Item &item)
{
    setAddressee(item.payload<KContacts::Addressee>());
}

KContacts::Addressee AddresseeWrapper::addressee() const
{
    return m_addressee;
}

void AddresseeWrapper::setAddressee(const KContacts::Addressee &addressee)
{
    m_addressee = addressee;
    m_addressesModel->setAddresses(addressee.addresses());
    m_emailModel->loadContact(addressee);
    m_phoneModel->loadContact(addressee);
    m_imppModel->loadContact(addressee);
    notifyDataChanged();
}

QString AddresseeWrapper::uid() const
{
    return m_addressee.uid();
}

Akonadi::Collection AddresseeWrapper::collection() const
{
    return m_collection.isValid() ? m_collection : item().parentCollection();
}

qint64 AddresseeWrapper::collectionId() const
{
    return collection().id();
}

void AddresseeWrapper::setCollection(Akonadi::Collection collection)
{
    m_collection = collection;
    Q_EMIT collectionChanged();
}

QString AddresseeWrapper::formattedName() const
{
    return m_addressee.formattedName();
}

void AddresseeWrapper::setFormattedName(const QString &name)
{
    if (name == m_addressee.formattedName()) {
        return;
    }
    m_addressee.setNameFromString(name);
    Q_EMIT formattedNameChanged();
    Q_EMIT givenNameChanged();
    Q_EMIT familyNameChanged();
    Q_EMIT suffixChanged();
    Q_EMIT prefixChanged();
    Q_EMIT additionalNameChanged();
}

QDateTime AddresseeWrapper::birthday() const
{
    return m_addressee.birthday();
}

void AddresseeWrapper::setBirthday(const QDateTime &birthday)
{
    if (birthday == m_addressee.birthday()) {
        return;
    }
    m_addressee.setBirthday(birthday);
    Q_EMIT birthdayChanged();
}

KContacts::PhoneNumber::List AddresseeWrapper::phoneNumbers() const
{
    return m_addressee.phoneNumbers();
}

KContacts::Picture AddresseeWrapper::photo() const
{
    return m_addressee.photo();
}

QString AddresseeWrapper::preferredEmail() const
{
    return m_addressee.preferredEmail();
}

EmailModel *AddresseeWrapper::emailModel() const
{
    return m_emailModel;
}

PhoneModel *AddresseeWrapper::phoneModel() const
{
    return m_phoneModel;
}

QString AddresseeWrapper::qrCodeData() const
{
    KContacts::VCardConverter converter;
    KContacts::Addressee addr(m_addressee);
    addr.setPhoto(KContacts::Picture());
    addr.setLogo(KContacts::Picture());
    return QString::fromUtf8(converter.createVCard(addr));
}

void AddresseeWrapper::updatePhoto(const KContacts::Picture &loadedPhoto)
{
    m_addressee.setPhoto(loadedPhoto);
    Q_EMIT photoChanged();
}

KContacts::Picture AddresseeWrapper::preparePhoto(const QUrl &path) const
{
    const QImage image(path.toLocalFile());
    // Scale the photo down to make sure contacts are not taking too
    // long time to load their photos
    constexpr auto unscaledWidth = 200;
    const auto scaleFactor = dynamic_cast<QGuiApplication *>(QCoreApplication::instance())->devicePixelRatio();
    const auto avatarSize = int(unscaledWidth * scaleFactor);
    const QSize size(avatarSize, avatarSize);

    return KContacts::Picture(image.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation));
}

QString AddresseeWrapper::note() const
{
    return m_addressee.note();
}

QDateTime AddresseeWrapper::anniversary() const
{
    return QDateTime(m_addressee.anniversary(), QTime());
}

QString AddresseeWrapper::spousesName() const
{
    return m_addressee.spousesName();
}

QString AddresseeWrapper::organization() const
{
    return m_addressee.organization();
}

QString AddresseeWrapper::profession() const
{
    return m_addressee.profession();
}

QString AddresseeWrapper::title() const
{
    return m_addressee.title();
}

QString AddresseeWrapper::department() const
{
    return m_addressee.department();
}

QString AddresseeWrapper::office() const
{
    return m_addressee.office();
}

QString AddresseeWrapper::managersName() const
{
    return m_addressee.managersName();
}

QString AddresseeWrapper::assistantsName() const
{
    return m_addressee.assistantsName();
}

void AddresseeWrapper::setNote(const QString &note)
{
    if (note == m_addressee.note()) {
        return;
    }
    m_addressee.setNote(note);
    Q_EMIT noteChanged();
}

void AddresseeWrapper::setAnniversary(const QDateTime &anniversary)
{
    if (anniversary.date() == m_addressee.anniversary()) {
        return;
    }
    m_addressee.setAnniversary(anniversary.date());
    Q_EMIT anniversaryChanged();
}

void AddresseeWrapper::setSpousesName(const QString &spousesName)
{
    if (spousesName == m_addressee.spousesName()) {
        return;
    }
    m_addressee.setSpousesName(spousesName);
    Q_EMIT spousesNameChanged();
}

void AddresseeWrapper::setOrganization(const QString &organization)
{
    if (organization == m_addressee.organization()) {
        return;
    }
    m_addressee.setOrganization(organization);
    Q_EMIT organizationChanged();
}

void AddresseeWrapper::setProfession(const QString &profession)
{
    if (profession == m_addressee.profession()) {
        return;
    }
    m_addressee.setProfession(profession);
    Q_EMIT professionChanged();
}

void AddresseeWrapper::setTitle(const QString &title)
{
    if (title == m_addressee.title()) {
        return;
    }
    m_addressee.setTitle(title);
    Q_EMIT titleChanged();
}

void AddresseeWrapper::setDepartment(const QString &department)
{
    if (department == m_addressee.department()) {
        return;
    }
    m_addressee.setDepartment(department);
    Q_EMIT departmentChanged();
}

void AddresseeWrapper::setOffice(const QString &office)
{
    if (office == m_addressee.office()) {
        return;
    }
    m_addressee.setOffice(office);
    Q_EMIT officeChanged();
}

void AddresseeWrapper::setManagersName(const QString &managersName)
{
    if (managersName == m_addressee.managersName()) {
        return;
    }
    m_addressee.setManagersName(managersName);
    Q_EMIT managersNameChanged();
}

void AddresseeWrapper::setAssistantsName(const QString &assistantsName)
{
    if (assistantsName == m_addressee.assistantsName()) {
        return;
    }
    m_addressee.setAssistantsName(assistantsName);
    Q_EMIT assistantsNameChanged();
}

QString AddresseeWrapper::nickName() const
{
    return m_addressee.nickName();
}

void AddresseeWrapper::setNickName(const QString &nickName)
{
    if (nickName == m_addressee.nickName()) {
        return;
    }
    m_addressee.setNickName(nickName);
    Q_EMIT nickNameChanged();
}

QUrl AddresseeWrapper::blogFeed() const
{
    return m_addressee.blogFeed();
}

void AddresseeWrapper::setBlogFeed(const QUrl &blogFeed)
{
    if (blogFeed == m_addressee.blogFeed()) {
        return;
    }
    m_addressee.setBlogFeed(blogFeed);
    Q_EMIT blogFeedChanged();
}

AddresseeWrapper::DisplayType AddresseeWrapper::displayType() const
{
    return m_displayType;
}

void AddresseeWrapper::setDisplayType(AddresseeWrapper::DisplayType displayType)
{
    if (m_displayType == displayType) {
        return;
    }
    m_displayType = displayType;
    Q_EMIT displayTypeChanged();
}

QString AddresseeWrapper::additionalName() const
{
    return m_addressee.additionalName();
}

void AddresseeWrapper::setAdditionalName(const QString &name)
{
    if (name == m_addressee.additionalName()) {
        return;
    }
    m_addressee.setAdditionalName(name);
    setFormattedName(m_addressee.assembledName());
    Q_EMIT additionalNameChanged();
}

QString AddresseeWrapper::givenName() const
{
    return m_addressee.givenName();
}

void AddresseeWrapper::setGivenName(const QString &name)
{
    if (name == m_addressee.givenName()) {
        return;
    }
    m_addressee.setGivenName(name);
    setFormattedName(m_addressee.assembledName());
    Q_EMIT givenNameChanged();
}

QString AddresseeWrapper::familyName() const
{
    return m_addressee.familyName();
}

void AddresseeWrapper::setFamilyName(const QString &name)
{
    if (name == m_addressee.familyName()) {
        return;
    }
    m_addressee.setFamilyName(name);
    setFormattedName(m_addressee.assembledName());
    Q_EMIT familyNameChanged();
}

QString AddresseeWrapper::prefix() const
{
    return m_addressee.prefix();
}

void AddresseeWrapper::setPrefix(const QString &name)
{
    if (name == m_addressee.prefix()) {
        return;
    }
    m_addressee.setPrefix(name);
    setFormattedName(m_addressee.assembledName());
    Q_EMIT prefixChanged();
}

QString AddresseeWrapper::suffix() const
{
    return m_addressee.suffix();
}

void AddresseeWrapper::setSuffix(const QString &name)
{
    if (name == m_addressee.suffix()) {
        return;
    }
    m_addressee.setSuffix(name);
    setFormattedName(m_addressee.assembledName());
    Q_EMIT suffixChanged();
}

#include "moc_addresseewrapper.cpp"
