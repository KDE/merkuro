#!/bin/sh

# Use custom instance to avoid clash with stable or
# system-wide instance
export AKONADI_INSTANCE="flatpak-nightly-merkuro"

function stop_akonadi {
    local akonadictl="akonadictl --instance=${AKONADI_INSTANCE}"
    ${akonadictl} stop
    while [[ $({$akonadictl} status 2>&1 | grep "running") ]]; do
        sleep 1
    done
}

# Make sure we run against our own Akonadi instance
stop_akonadi

# Make sure that our Akonadi is stopped when this script exits, as there
# is no way to shut it down later and it would interfere with the next run.
trap stop_akonadi EXIT

# Merkuro requires that ksycoca cache exists, but cannot run kbuildsycoca5
# automatically (because KDED lives outside of the sandbox).
# As a workaround we force-run it ourselves. It's really only needed once,
# but detecting whether it already exists or not is hard and the overhead
# is minimal.
kbuildsycoca5

# .. aaaaand lift-off
merkuro "$@"
