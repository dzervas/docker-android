#!/bin/bash
set -ex

BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color

function check_emulator_status() {
	printf "${G}==> ${BL}Checking emulator booting up status 🧐${NC}\n"
	start_time=$(date +%s)
	# Get the timeout value from the environment variable or use the default value of 300 seconds (5 minutes)
	timeout=${EMULATOR_TIMEOUT:-300}

	while true; do
		result=$(adb shell getprop sys.boot_completed 2>&1)

		if [ "$result" == "1" ]; then
			printf "\e[K${G}==> \u2713 Emulator is ready : '$result'${NC}\n"
			adb devices -l
			adb shell input keyevent 82
			break
		fi

		current_time=$(date +%s)
		elapsed_time=$((current_time - start_time))

		if [ $elapsed_time -gt $timeout ]; then
			printf "${RED}==> Timeout after ${timeout} seconds elapsed 🕛.. ${NC}\n"
			break
		fi

		sleep 4
	done
}

function install_root() {
	case $ROOT in
		false|no|n|0)
			return
			;;
	esac

	git clone https://gitlab.com/newbit/rootAVD.git /app/rootAVD
	pushd /app/rootAVD
	./rootAVD.sh system-images/android-34/google_apis_playstore/x86_64/ramdisk.img
	./rootAVD.sh InstallApps
	popd
}

function run_adb_commands() {
	printf "${G}==> ${BL}Running ADB commands${NC}\n"
	adb shell settings put global window_animation_scale 0.0
	adb shell settings put global transition_animation_scale 0.0
	adb shell settings put global animator_duration_scale 0.0
	adb shell settings put global hidden_api_policy_pre_p_apps 1
	adb shell settings put global hidden_api_policy_p_apps 1
	adb shell settings put global hidden_api_policy 1
	adb shell settings put global development_settings_enabled 1
	adb shell settings put global adb_wifi_enabled 1

	if [ ! -z "$HTTP_PROXY_HOST" ] && [ ! -z "$HTTP_PROXY_PORT" ]; then
		adb shell settings put global http_proxy ${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
		adb shell settings put global global_http_proxy_host ${HTTP_PROXY_HOST}
		adb shell settings put global global_http_proxy_port ${HTTP_PROXY_PORT}
	elif [ ! -z "$HOST_HTTP_PROXY_PORT" ]; then
		adb shell settings put global http_proxy host.docker.internal:${HOST_HTTP_PROXY_PORT}
		adb shell settings put global global_http_proxy_host host.docker.internal
		adb shell settings put global global_http_proxy_port ${HOST_HTTP_PROXY_PORT}
	fi
}

function install_apks() {
	printf "${G}==> ${BL}Installing APKs${NC}\n"
	find / -iname "*.apk" -depth 1 -exec adb install {} \;
}

function install_frida() {
	case $RUN_FRIDA in
		false|no|n|0)
			return
			;;
	esac

	case $ROOT in
		false|no|n|0)
			printf "${RED}==> ${YE}Frida cannot be installed on a non-rooted device${NC}\n"
			return
			;;
	esac

	printf "${G}==> ${BL}Installing Frida${NC}\n"

	OS='android'
	PARCH=$(adb shell getprop ro.product.cpu.abi)
	curl -s https://api.github.com/repos/frida/frida/releases \
		| jq '.[0] | .assets[] | select(.browser_download_url | match("server(.*?)'${OS}'-'${PARCH}'*\\.xz")).browser_download_url' \
		| xargs wget -q -O frida-server.xz $1
	unxz frida-server.xz
	# adb root

	adb push frida-server /sdcard
	adb shell mv /sdcard/frida-server /data/local/tmp/frida-server
	adb shell chmod 755 /data/local/tmp/frida-server
	adb shell "su -c /data/local/tmp/frida-server &" &
}

check_emulator_status
sleep 1
install_root
run_adb_commands
install_apks
install_frida
