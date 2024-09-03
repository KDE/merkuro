<!--
SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@kde.org>
SPDX-License-Identifier: CC0-1.0
-->

# Merkuro

Merkuro is a application suite designed to make handling your emails, calendars, contacts, and tasks simple. Merkuro handles local and remote accounts of your choice, keeping changes synchronised across your Plasma desktop or phone.

Merkuro was formerly known as Kalendar.

**Get involved and join our Matrix channel: [#merkuro:kde.org](https://matrix.to/#/#merkuro:kde.org=)**

## Screenshots

![Screenshot of Merkuro calendar's month view](https://cdn.kde.org/screenshots/kalendar/month_view.png)
![Screenshot of Merkuro calendar's task view](https://cdn.kde.org/screenshots/kalendar/task_view.png)
![Screenshot of Merkuro calendar's week view](https://cdn.kde.org/screenshots/kalendar/week_view.png)
![Screenshot of Merkuro calendar's schedule view](https://cdn.kde.org/screenshots/kalendar/schedule_view.png)
![Screenshot of Merkuro calendar's schedule view on mobile](https://cdn.kde.org/screenshots/kalendar/mobile_view.png)

## Get it

Merkuro will soon be available on most major distributions with the release of KDE Gear 23.08.

If not, you can get prior versions of Merkuro (previously known as Kalendar) from most major distributions.

## Build

**Merkuro requires up-to-date KFrameworks and KDE PIM-related dependencies (e.g. Akonadi, kdepim-runtime) to be installed.** These may not yet be available in your distribution of choice, meaning Merkuro might not build. **We therefore recommend the use of kdesrc-build to build Merkuro easily and correctly.**

**We also strongly recommend you install the `kdepim-runtime` package before starting Merkuro** as without functionality of certain components, such as the calendar component, will be heavily restricted.

If you have already installed and started Merkuro and are now installing `kdepim-runtime`, make sure to run `akonadictl restart`; this will enable online resources after installing `kdepim-runtime`.

KDE Neon dependencies:
```
git cmake build-essential gettext extra-cmake-modules qtbase5-dev qtdeclarative5-dev libqt5svg5-dev qtquickcontrols2-5-dev qml-module-org-kde-kirigami2 kirigami2-dev libkf5i18n-dev gettext libkf5coreaddons-dev qml-module-qtquick-layouts qml-module-qtlocation qml-module-qt-labs-qmlmodels qtlocation5-dev qml-module-qtpositioning qtpositioning5-dev libkf5mime-dev libkf5calendarsupport-dev libkf5akonadicontact-dev libkf5akonadi-dev libkf5windowsystem-dev libkf5package-dev libkf5calendarcore-dev libkf5configwidgets-dev libkf5contacts-dev libkf5people-dev libkf5eventviews-dev libkf5notifications-dev libkf5qqc2desktopstyle-dev kdepim-runtime ninja-build
```

```
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/.local/kde -GNinja
ninja
```

## Frequently asked questions

### Does Merkuro calendar support Google/Exchange/Nextcloud calendars?

Yes. We support:

- CalDAV calendars (e.g. Nextcloud)
- Google calendars
- Exchange calendars
- iCal calendar files (.ics)
- iCal calendar folders
- Kolab groupware servers
- Open-Xchange groupware servers

#### Will support for Todoist/Proton Calendar/etc. be added?

Online event/task services such as Todoist that have non-standard implementations of calendars/task lists depend on someone taking the time to write code that adds support for the specific service in question. When (or if) that will happen will depend on how popular the service is, and on someone being willing to maintain support for said service.

Proton Calendar specifically is problematic, and it is impossible for us to support until Proton provides a way for us to interact and interface with the calendar (i.e. with the bridge application).

#### Does Merkuro calendar work with Plasma's digital clock calendar widget?

Yes. This can be configured by right-clicking on the digital clock -> Configure digital clock... -> Calendar -> enable PIM Events Plugin

This should reveal a new section in the widget settings, letting you configure which calendars' events will be visible in the widget.

#### Does Merkuro use Akonadi?

Yes. It is what allows us to support all the services that we support, and provides the core functionality of Merkuro's various apps (fetching, editing, creating, and deleting events from remote resources, for instance).

#### Why all the dependencies?

While we’re actively working on reducing our number of external dependencies, these removals often take time and require reimplementing things in a new way, which is not always easy.

Other dependencies we require are there so we don’t bloat Merkuro by copying functionality that can be provided by an external package also used by other applications.

#### Will \<insert Merkuro application> replace \<insert Kontact application>?

For the time being, no.

Kontact has an incredibly expansive feature set, which makes it a powerful tool for power users. Merkuro is instead focused on providing an approachable PIM suite for Plasma. You can expect great usability and a visually appealing interface that works on both desktop and mobile.

The intention is for the two suites to co-exist and for you to have the choice of using the one best suited to your needs. If you really need the advanced and expansive feature-set of Kontact, you will want to use that. If you want a versatile app set that is nice to use and you can comfortably use on your desktop and on your phone, Merkuro will fill that role well!

#### Will there be a flatpak?

Yes, Merkuro is part of the [org.kde.kontact flatpak](https://flathub.org/apps/details/org.kde.kontact). Please note that this package is missing some desktop integration features (e.g. the calendar applet plugin), and we generally recommend the use of the distro package if the version provided in the repositories is recent.

#### How can I install Merkuro on distro "X"?

This is unfortunately out of our hands. If you'd like a Merkuro package on your distribution of choice, ask your distribution's packagers (nicely!) if they'd like to package Merkuro.

## License

This project is licensed under GPL-3.0-or-later. Some files are licensed under
more permissive licenses. New contributions are expected to be under the
LGPL-2.1-or-later license.
