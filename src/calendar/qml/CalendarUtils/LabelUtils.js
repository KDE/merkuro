// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

.import org.kde.merkuro.components as MerkuroComponents

// This regex detects URLs in the description text, so we can turn them into links
const urlRegexp = /^(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?$/ig

function numberToString(number) {
    // The code in here was adapted from an article by Johnathan Wood, see:
    // http://www.blackbeltcoder.com/Articles/strings/converting-numbers-to-ordinal-strings

    let numSuffixes = [ "th",
    "st",
    "nd",
    "rd",
    "th",
    "th",
    "th",
    "th",
    "th",
    "th"];

    let i = (number % 100);
    let j = (i > 10 && i < 20) ? 0 : (number % 10);
    return i18n(number + numSuffixes[j]);
}

function getDarkness(background) {
    // Thanks to Gojir4 from the Qt forum
    // https://forum.qt.io/topic/106362/best-way-to-set-text-color-for-maximum-contrast-on-background-color/
    var temp = Qt.darker(background, 1);
    var a = 1 - ( 0.299 * temp.r + 0.587 * temp.g + 0.114 * temp.b);
    return a;
}

function isDarkColor(background) {
    var temp = Qt.darker(background, 1);
    return temp.a > 0 && getDarkness(background) >= 0.4;
}

function getIncidenceDelegateBackgroundColor(backgroundColor, darkMode, eventEnd = null, pastEventsDimLevel = 0.0) {
    let bgColor = getDarkness(backgroundColor) > 0.9 ? Qt.lighter(backgroundColor, 1.5) : backgroundColor;
    if(darkMode) {
        if(getDarkness(backgroundColor) >= 0.5) {
            bgColor.a = 0.6;
        } else {
            bgColor.a = 0.4;
        }
    } else {
        bgColor.a = 0.7;
    }

    if (pastEventsDimLevel > 0 && eventEnd && eventEnd.isValid) {
        if (eventEnd.msecsTo(MerkuroComponents.KDateTimeFactory.now()) > 0) {
            bgColor.a = Math.max(0.0, bgColor.a - pastEventsDimLevel);
        }
    }
    return bgColor;
}

function getIncidenceLabelColor(background, darkMode) {

    if(getDarkness(background) >= 0.9) {
        return "white";
    } else if(darkMode) {
        if(getDarkness(background) >= 0.5) {
            return Qt.lighter(background, 2.1);
        } else {
            return Qt.lighter(background, 1.5);
        }
    }
    else if(getDarkness(background) >= 0.68) {
        return Qt.lighter(background, 2.4);
    } else {
        return Qt.darker(background, 2.1);
    }

}

function priorityString(priority) {
    if(priority === 1) {
        return i18nc("%1 is the priority level number", "%1 (Highest priority)", priority);
    } else if (priority < 5) {
        return i18nc("%1 is the priority level number", "%1 (Mid-high priority)", priority);
    } else if (priority === 5) {
        return i18nc("%1 is the priority level number", "%1 (Medium priority)", priority);
    } else if (priority < 9) {
        return i18nc("%1 is the priority level number", "%1 (Mid-low priority)", priority);
    } else if (priority === 9) {
        return i18nc("%1 is the priority level number", "%1 (Lowest priority)", priority);
    } else {
        return i18n("No set priority level");
    }
}
