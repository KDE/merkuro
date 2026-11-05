// SPDX-FileCopyrightText: 2019 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.ki18n
import org.kde.merkuro.mail

ColumnLayout {
    id: root

    property string content
    property bool autoLoadImages: false
    property string searchString
    readonly property int contentHeight: implicitHeight

    readonly property CalendarInvitation invitation: CalendarInvitation {
        content: root.content
    }

    spacing: Kirigami.Units.largeSpacing

    component Detail: FormCard.FormTextDelegate {
        id: detail

        visible: detail.text.length > 0
        verticalPadding: Kirigami.Units.smallSpacing
        textItem.textFormat: Text.PlainText
        textItem.wrapMode: Text.WordWrap
        textItem.elide: Text.ElideNone
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
        visible: !root.invitation.valid
        type: Kirigami.MessageType.Warning
        text: KI18n.i18nc("@info", "This calendar invitation could not be read.")
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: root.invitation.errorString.length > 0
        type: Kirigami.MessageType.Error
        text: root.invitation.errorString
    }

    FormCard.FormCard {
        autoSeparators: true

        Layout.topMargin: Kirigami.Units.largeSpacing
        visible: root.invitation.valid

        FormCard.AbstractFormDelegate {
            verticalPadding: Kirigami.Units.largeSpacing
            background: null
            contentItem: Kirigami.Heading {
                level: 2
                font.weight: Font.DemiBold
                text: root.invitation.summary || KI18n.i18nc("@title", "Calendar event")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }
        }
        Detail {
            text: root.invitation.replyStatusMessage
            textItem.color: root.invitation.replyDeclined ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
            icon.name: "mail-replied-symbolic"
            Accessible.name: root.invitation.replyStatusMessage
        }
        Detail {
            text: root.invitation.statusMessage
            icon.name: "dialog-ok-symbolic"
            Accessible.name: root.invitation.statusMessage
        }
        Detail {
            visible: root.invitation.canceled
            text: KI18n.i18nc("@info", "This event has been canceled.")
            icon.name: "dialog-warning-symbolic"
        }
        Detail {
            text: root.invitation.allDay ? KI18n.i18nc("@info", "%1 · All day", root.invitation.dateTimeRange) : root.invitation.dateTimeRange
            icon.name: "view-calendar"
            Accessible.name: KI18n.i18nc("@info:accessibility", "When: %1", root.invitation.dateTimeRange)
        }
        FormCard.FormLinkDelegate {
            verticalPadding: Kirigami.Units.smallSpacing
            text: root.invitation.location || KI18n.i18nc("@label", "Location")
            icon.name: "mark-location-symbolic"
            Accessible.name: KI18n.i18nc("@info:accessibility", "Location: %1", root.invitation.location)
            url: root.invitation.locationUrl.toString()
        }
        Detail {
            text: root.invitation.organizer.length > 0 ? KI18n.i18nc("@info", "%1 (organizer)", root.invitation.organizer) : ""
            icon.name: "im-user-symbolic"
            Accessible.name: KI18n.i18nc("@info:accessibility", "Organizer: %1", root.invitation.organizer)
        }
        Detail {
            text: root.invitation.attendees.join("\n")
            icon.name: "system-users-symbolic"
            Accessible.name: KI18n.i18nc("@info:accessibility", "Attendees: %1", root.invitation.attendees.join(", "))
        }
        Detail {
            text: root.invitation.description
            icon.name: "documentinfo"
            Accessible.name: KI18n.i18nc("@info:accessibility", "Details: %1", root.invitation.description)
        }
        FormCard.AbstractFormDelegate {
            visible: root.invitation.responseAddresses.length > 0
            background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: KI18n.i18nc("@label", "Respond as %1", responseAddress.currentText)
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                }
                QQC2.ComboBox {
                    id: responseAddress

                    Layout.fillWidth: true
                    visible: count > 1
                    enabled: !root.invitation.busy
                    model: root.invitation.responseAddresses
                    Accessible.name: KI18n.i18nc("@info:accessibility", "Response email address")
                }
                RowLayout {
                    QQC2.Button {
                        text: KI18n.i18nc("@action:button", "Accept")
                        icon.name: "dialog-ok-symbolic"
                        enabled: !root.invitation.busy && responseAddress.currentText.length > 0
                        onClicked: root.invitation.respond(responseAddress.currentText, true)
                    }
                    QQC2.Button {
                        text: KI18n.i18nc("@action:button", "Decline")
                        icon.name: "dialog-cancel-symbolic"
                        enabled: !root.invitation.busy && responseAddress.currentText.length > 0
                        onClicked: root.invitation.respond(responseAddress.currentText, false)
                    }
                    QQC2.BusyIndicator {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        running: root.invitation.busy
                        visible: running
                        Accessible.name: KI18n.i18nc("@info:accessibility", "Responding to invitation")
                    }
                }
            }
        }
    }
}
