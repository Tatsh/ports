#!/bin/sh
# Runs @ROOM@ from the settings in @PREFIX@/etc/@ROOM@.conf, for its launchd service.
conf="@PREFIX@/etc/@ROOM@.conf"
if [ ! -r "${conf}" ]; then
    echo "@ROOM@: ${conf} is missing" >&2
    exit 1
fi
. "${conf}"
if [ -z "${ROOM_NAME}" ] || [ -z "${PREFERRED_GAME}" ]; then
    echo "@ROOM@: set ROOM_NAME and PREFERRED_GAME in ${conf}" >&2
    exit 1
fi
set -- \
    --room-name "${ROOM_NAME}" \
    --preferred-game "${PREFERRED_GAME}" \
    --port "${PORT:-24872}" \
    --max_members "${MAX_MEMBERS:-4}" \
    --ban-list-file "@DATADIR@/ban_list.json" \
    --log-file "@DATADIR@/room.log"
[ -n "${ROOM_DESCRIPTION}" ] && set -- "$@" --room-description "${ROOM_DESCRIPTION}"
[ -n "${PREFERRED_GAME_ID}" ] && set -- "$@" --preferred-game-id "${PREFERRED_GAME_ID}"
[ -n "${PASSWORD}" ] && set -- "$@" --password "${PASSWORD}"
exec "@PREFIX@/bin/@ROOM@" "$@" < /dev/null
