// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0

MobileForm.FormCard {
    id: root

    readonly property IdentityModel _identityModel: IdentityModel {}

    contentItem: ColumnLayout {
        spacing: 0

        MobileForm.FormCardHeader {
            title: i18n("Identities")
        }

        Repeater {
            model: root._identityModel
            delegate: MobileForm.FormButtonDelegate {
                Loader {
                    id: dialogLoader
                    sourceComponent: Kirigami.PromptDialog {
                        id: dialog
                        title: i18n("Configure %1", model.display)
                        subtitle: i18n("Modify or delete this account agent.")
                        standardButtons: Kirigami.Dialog.NoButton

                        customFooterActions: [
                        Kirigami.Action {
                            text: i18n("Modify")
                            iconName: "edit-entry"
                        },
                        Kirigami.Action {
                            text: i18n("Delete")
                            iconName: "delete"
                        }
                        ]
                    }
                }

                leadingPadding: Kirigami.Units.largeSpacing
                leading: Kirigami.Icon {
                    source: model.decoration
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                }
                
                text: model.display
                //description: model.statusMessage

                onClicked: {
                    dialogLoader.active = true;
                    dialogLoader.item.open();
                }
            }
        }

        MobileForm.FormDelegateSeparator { below: addAccountDelegate }

        MobileForm.FormButtonDelegate {
            id: addIdentityDelegate
            text: i18n("Add Identity")
            icon.name: "list-add"
            //onClicked: pageStack.pushDialogLayer(addIdentityPage)
        }
    }
}
