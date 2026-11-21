#!/bin/sh
set -a
. @PREFIX@/etc/nanomdm/nanomdm.conf
set +a
exec @PREFIX@/bin/nanomdm
