#!/bin/bash

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
			printf "\e[K${G}==> \u2713 Emulator is ready : '$result'           ${NC}\n"
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

function run_adb_commands() {
	printf "${G}==> ${BL}Running ADB commands${NC}\n"
	adb shell "settings put global window_animation_scale 0.0"
	adb shell "settings put global transition_animation_scale 0.0"
	adb shell "settings put global animator_duration_scale 0.0"
	adb shell "settings put global hidden_api_policy_pre_p_apps 1"
	adb shell "settings put global hidden_api_policy_p_apps 1"
	adb shell "settings put global hidden_api_policy 1"
	adb shell "settings put global development_settings_enabled 1"
	adb shell "settings put global adb_wifi_enabled 1"
}

check_emulator_status
sleep 1
run_adb_commands
printf "${G}==> ${BL}Installing APKs${NC}\n"
find / -iname "*.apk" -exec adb install {} \;
