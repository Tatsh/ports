#!/bin/sh
# PumpkinOS keeps its file system, registry and log in the working directory. Give each user a
# copy of the installed file system in ~/Library/Application Support/PumpkinOS and run from there.
# PUMPKIN_WINDOWED=1 starts it in a window instead of fullscreen; PUMPKIN_DEBUG sets the log level.
libdir="@PREFIX@/libexec/pumpkinos"
data="${HOME}/Library/Application Support/PumpkinOS"
mkdir -p "${data}" || exit 1
if [ ! -d "${data}/vfs" ]; then
    cp -R "${libdir}/vfs" "${data}/" || exit 1
fi
# New and updated built-in applications are installed from app_install on every start.
cp -R "${libdir}/vfs/app_install/." "${data}/vfs/app_install/" 2>/dev/null
mkdir -p "${data}/vfs/app_storage" "${data}/registry"
cd "${data}" || exit 1
DYLD_LIBRARY_PATH="${libdir}/bin" exec "${libdir}/pumpkin" -d "${PUMPKIN_DEBUG:-1}" -f pumpkin.log \
    -s libscriptlua "${libdir}/script/pumpkin_mac.lua" "$@"
