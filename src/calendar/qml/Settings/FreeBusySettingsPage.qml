// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.akonadi
import org.kde.merkuro.calendar as Calendar
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: freeBusySettingsPage

    title: i18n("Configure Availability")

    FormCard.FormHeader {
        title: i18n("Availability Publishing settings")
    }

    FormCard.FormCard {
        id: freeBusyPublishSection

        FormCard.FormTextDelegate {
            id: freeBusyPublishInfo
            description: i18n("When you publish your availability information, it enables others to consider your calendar availability when inviting you to a meeting. Only the times that are already marked as busy are disclosed, without revealing the specific reasons for your availability.")
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormCheckDelegate {
            id: autoPublishDelegate
            text: i18n("Publish your availability information automatically")
            checked: Calendar.CalendarSettings.freeBusyPublishAuto
            onCheckedChanged: {
                Calendar.CalendarSettings.freeBusyPublishAuto = checked;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSpinBoxDelegate {
            id: autoPublishDelayDelegate
            Layout.fillWidth: true
            visible: autoPublishDelegate.checked
            label: i18n("Minimum time (in minutes) between uploads")
            value: Calendar.CalendarSettings.freeBusyPublishDelay
            from: 1
            to: 10080
            onValueChanged: {
                Calendar.CalendarSettings.freeBusyPublishDelay = value;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSpinBoxDelegate {
            id: publishDaysDelegate
            Layout.fillWidth: true
            label: i18n("Number of days of availability info to publish: ")
            value: Calendar.CalendarSettings.freeBusyPublishDays
            from: 1
            to: 365
            onValueChanged: {
                Calendar.CalendarSettings.freeBusyPublishDays = value;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormTextDelegate {
            id: publishServerTitle
            description: i18n("Server information")
        }
        FormCard.FormTextFieldDelegate {
            id: publishServerUrl
            label: i18n("Server URL")
            text: Calendar.CalendarSettings.freeBusyPublishUrl
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyPublishUrl = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormTextFieldDelegate {
            id: publishServerUser
            label: i18n("Username")
            text: Calendar.CalendarSettings.freeBusyPublishUser
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyPublishUser = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormPasswordFieldDelegate {
            id: publishServerPassword
            label: i18n("Password")
            text: Calendar.CalendarSettings.freeBusyPublishPassword
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyPublishPassword = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormCheckDelegate {
            id: publishServerSavePassword
            text: i18n("Save password")
            checked: Calendar.CalendarSettings.freeBusyPublishSavePassword
            onCheckedChanged: {
                Calendar.CalendarSettings.freeBusyPublishSavePassword = checked;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormButtonDelegate {
            id: freeBusyPublishButton
            text: i18n("Click here to publish availability information manually")
            onClicked: Calendar.FreeBusyManager.publishFreeBusy();
        }
        FormCard.FormDelegateSeparator {}
        FormCard.AbstractFormDelegate {
            id: freeBusyMailDelegate
            background: null
            Layout.fillWidth: true
            contentItem: RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: i18n("Email availability")
                }
                QQC2.TextField {
                    id: freeBusyMailAddress
                    Layout.fillWidth: true
                    placeholderText: i18n("Enter email of recipient...")
                }
                QQC2.Button {
                    text: i18n("Send")
                    onClicked: Calendar.FreeBusyManager.mailFreeBusy(freeBusyMailAddress.text);
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Availability Retrieval settings")
    }

    FormCard.FormCard {
        id: freeBusyRetrieveSection

        FormCard.FormTextDelegate {
            id: freeBusyRetrieveInfo
            description: i18n("By retrieving Availability information that others have published, you can take their calendar into account when inviting them to a meeting.")
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormCheckDelegate {
            id: autoRetrieveDelegate
            text: i18n("Retrieve others' availability information automatically")
            checked: Calendar.CalendarSettings.freeBusyRetrieveAuto
            onCheckedChanged: {
                Calendar.CalendarSettings.freeBusyRetrieveAuto = checked;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormCheckDelegate {
            id: fullDomainRetrievalDelegate
            text: i18n("Use full email address for retrieval")
            checked: Calendar.CalendarSettings.freeBusyFullDomainRetrieval
            onCheckedChanged: {
                Calendar.CalendarSettings.freeBusyFullDomainRetrieval = checked;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormTextDelegate {
            id: retrieveServerTitle
            description: i18n("Server information")
        }
        FormCard.FormTextFieldDelegate {
            id: retrieveServerUrl
            label: i18n("Server URL")
            text: Calendar.CalendarSettings.freeBusyRetrieveUrl
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyRetrieveUrl = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormTextFieldDelegate {
            id: retrieveServerUser
            label: i18n("Username")
            text: Calendar.CalendarSettings.freeBusyRetrieveUser
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyRetrieveUser = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormPasswordFieldDelegate {
            id: retrieveServerPassword
            label: i18n("Password")
            text: Calendar.CalendarSettings.freeBusyRetrievePassword
            onEditingFinished: {
                Calendar.CalendarSettings.freeBusyRetrievePassword = text;
                Calendar.CalendarSettings.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormCheckDelegate {
            id: retrieveServerSavePassword
            text: i18n("Save password")
            checked: Calendar.CalendarSettings.freeBusyRetrieveSavePassword
            onCheckedChanged: {
                Calendar.CalendarSettings.freeBusyRetrieveSavePassword = checked;
                Calendar.CalendarSettings.save();
            }
        }
    }
}
