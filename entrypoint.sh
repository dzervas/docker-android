#!/bin/bash
set -ex

ENABLE_X=${ENABLE_X:-yes}
RUN_FLUXBOX=${RUN_FLUXBOX:-yes}
RUN_NOVNC=${RUN_NOVNC:-yes}
RUN_APPIUM=${RUN_APPIUM:-no}
APPIUM_PORT=${APPIUM_PORT:-4723}
APPIUM_PLUGINS=${APPIUM_PLUGINS:-""}
EMULATOR_FLAGS=${EMULATOR_FLAGS:-"-no-snapshot -no-audio"}
ROOT=${ROOT:-no}

case $ROOT in
	true|yes|y|1)
		EMULATOR_FLAGS="$EMULATOR_FLAGS -writable-system -shell"
		;;
esac

case $ENABLE_X in
	false|no|n|0)
		rm -f /app/conf.d/x11vnc.conf
		rm -f /app/conf.d/xvfb.conf
		rm -f /app/conf.d/fluxbox.conf
		rm -f /app/conf.d/websockify.conf
		EMULATOR_FLAGS="$EMULATOR_FLAGS -no-qt -no-window -no-snapshot -no-audio"
		;;
esac

case $RUN_FLUXBOX in
	false|no|n|0)
		rm -f /app/conf.d/fluxbox.conf
		;;
esac

case $RUN_NOVNC in
	false|no|n|0)
		rm -f /app/conf.d/websockify.conf
		;;
esac

case $RUN_APPIUM in
	false|no|n|0)
		rm -f /app/conf.d/appium.conf
		;;
	*)
		for plugin in ${APPIUM_PLUGINS//,/ }; do
			appium plugin install "$plugin"
		done
		;;
esac

exec supervisord -c /app/supervisord.conf
