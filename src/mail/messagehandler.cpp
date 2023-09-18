// SPDX-FileCopyrightText: 2023 Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "messagehandler.h"
#include <MimeTreeParserCore/FileOpener>

using namespace MimeTreeParser::Core;

void MessageHandler::open(const QUrl &file)
{
    const auto messages = FileOpener::openFile(file.toLocalFile());
    if (!messages.isEmpty()) {
        Q_EMIT messageOpened(messages[0]);
    }
}
