#!/bin/sh
CCLESTE_CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/ccleste"
CCLESTE_INPUT_CFG_PATH="${CCLESTE_INPUT_CFG_PATH:-${CCLESTE_CFG_DIR}/input-cfg.txt}"
export CCLESTE_INPUT_CFG_PATH
mkdir -p "$(dirname "${CCLESTE_INPUT_CFG_PATH}")" || exit 1
exec @PREFIX@/libexec/ccleste/ccleste "$@"
