// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mousetracker.h"
#include "qdebug.h"

#include <QEvent>
#include <QMouseEvent>

MouseTracker::MouseTracker(QObject *parent)
    : QObject{parent}
{
}

QPointF MouseTracker::mousePosition() const
{
    return m_lastMousePos;
}

// This is the method is necessary for 'installEventFilter'
bool MouseTracker::eventFilter(QObject *watched, QEvent *event)
{
    Q_ASSERT(event);
    const auto type = event->type();

    switch (type) {
    case QEvent::MouseMove: {
        const auto mouseEvent = static_cast<QMouseEvent *>(event);
        m_lastMousePos = mouseEvent->windowPos();
        Q_EMIT mousePositionChanged(m_lastMousePos);
        break;
    }
    default:
        break;
    }

    return QObject::eventFilter(watched, event);
}
