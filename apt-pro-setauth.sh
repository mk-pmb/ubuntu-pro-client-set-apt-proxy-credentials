#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
set -o errexit -o pipefail
trap 'echo T: "Failed at $BASH_SOURCE line $LINENO: $BASH_COMMAND" >&2' ERR
[ "$(whoami)" == root ] || { echo E: 'Must run as root!' >&2; exit 4; }

cd /etc/apt/auth.conf.d
DEST="00ubuntu-pro-auth-override"
>"$DEST"
chown _apt:root -- "$DEST"
chmod a=,u+r -- "$DEST"

PRO_TOKENS='/var/lib/ubuntu-advantage/private/machine-token.json'
for FEAT in apps infra; do
  KEY='.resourceTokens[] | first(select(.type == "esm-'"$FEAT"'")) | .token'
  KEY="$(<"$PRO_TOKENS" jq --raw-output "$KEY")"
  [ -n "$KEY" ] || { echo E: "Cannot find $FEAT token!" >&2; exit 4; }
  VAL="esm.ubuntu.com/$FEAT/ubuntu/ login bearer password $KEY"

  VAL+="  # ubuntu-pro-client" # Appending the comment is optional.
  # I just do it to make the wdiff below even more obvious.

  ( echo "machine http://snapshot.$FEAT-security.$VAL"
    echo "machine http://snapshot.$FEAT-updates.$VAL"
    echo "machine http://$VAL"
  ) >>"$DEST"
done

SED_CENSOR_PSWD='s~( password \S{3})\S*~\1…~'
SED_NOSPACE_HTTP='s~ http://~& <nospace> ~g'
PRO_CLIENT_AUTH_FILE='90ubuntu-advantage'
FMT_DEL=$'\x1B[91m'
FMT_INS=$'\x1B[94m'
FMT_END=$'\x1B[0m'

echo
echo "$FMT_DEL--- $PRO_CLIENT_AUTH_FILE$FMT_END $FMT_INS+++ $DEST$FMT_END"
( wdiff \
  --start-delete="$FMT_DEL" \
  --start-insert="$FMT_INS" \
  --end-{delete,insert}="$FMT_END" \
  <( LANG=C sed -re "$SED_CENSOR_PSWD" -- "$PRO_CLIENT_AUTH_FILE" || echo ) \
  <( LANG=C sed -re "$SED_CENSOR_PSWD;$SED_NOSPACE_HTTP" -- "$DEST") \
  || true
) | LANG=C sed -re 's~ <nospace>(\x1B\[[0-9]*m|) ~\1~g'
echo
