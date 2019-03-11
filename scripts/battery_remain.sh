#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

update_interval=$(get_tmux_option @batt_remaining_update_interval 0)
last_update_filename="/tmp/tmux-battery-remaining-last-update"

short=false

get_remain_settings() {
	short=$(get_tmux_option "@batt_remain_short" false)
}

battery_discharging() {
	local status="$(battery_status)"
	[[ $status =~ (discharging) ]]
}

battery_charged() {
	local status="$(battery_status)"
	[[ $status =~ (charged) ]]
}

pmset_battery_remaining_time() {
	local status="$(pmset -g batt)"
	if echo $status | grep 'no estimate' >/dev/null 2>&1; then
		if $short; then
			echo '~?:??'
		else
			echo '- Calculating estimate...'
		fi
	else
		local remaining_time="$(echo $status | grep -o '[0-9]\{1,2\}:[0-9]\{1,2\}')"
		if battery_discharging; then
			if $short; then
				echo $remaining_time | awk '{printf "~%s", $1}'
			else
				echo $remaining_time | awk '{printf "- %s left", $1}'
			fi
		elif battery_charged; then
			if $short; then
				echo $remaining_time | awk '{printf "charged", $1}'
			else
				echo $remaining_time | awk '{printf "fully charged", $1}'
			fi
		else
			if $short; then
				echo $remaining_time | awk '{printf "~%s", $1}'
			else
				echo $remaining_time | awk '{printf "- %s till full", $1}'
			fi
		fi
	fi
}

upower_battery_remaining_time() {
	battery=$(upower -e | grep -E 'battery|DisplayDevice'| tail -n1)
	if battery_discharging; then
		local remaining_time
		remaining_time=$(upower -i "$battery" | grep -E '(remain|time to empty)')
		if $short; then
			echo "$remaining_time" | awk '{printf "%s%s", $(NF-1), substr($(NF), 1, 1)}'  # 12.6 hours -> 12.6h
		else
			echo "$remaining_time" | awk '{printf "%s %s left", $(NF-1), $(NF)}'
		fi
	elif battery_charged; then
		if $short; then
			echo ""
		else
			echo "charged"
		fi
	else
		local remaining_time
		remaining_time=$(upower -i "$battery" | grep -E 'time to full')
		if $short; then
			echo "$remaining_time" | awk '{printf "%s %s", $(NF-1), $(NF)}'
		else
			echo "$remaining_time" | awk '{printf "%s %s to full", $(NF-1), $(NF)}'
		fi
	fi
}

acpi_battery_remaining_time() {
	if $short; then
		acpi -b | grep -m 1 -Eo "[0-9]+:[0-9]+"
	else
		acpi -b | grep -m 1 -Eo "[0-9]+:[0-9]+:[0-9]+"
	fi
}

print_battery_remain() {
	local do_actual_update=false
	if [ "${update_interval}" -gt 0 ]; then
		if [ ! -f "${last_update_filename}" ]; then
			do_actual_update=true
		else
			local seconds_elapsed=$(($(date +%s) - $(date +%s -r "${last_update_filename}")))
			[ "${seconds_elapsed}" -gt "${update_interval}" ] && do_actual_update=true
		fi
	fi

	if [ "${do_actual_update}" = true ]; then
		local output=""
		if command_exists "acpi"; then
			output=$(acpi_battery_remaining_time)
		elif command_exists "upower"; then
			output=$(upower_battery_remaining_time)
		elif command_exists "pmset"; then
			output=$(pmset_battery_remaining_time)
		fi
		echo "${output}" > "${last_update_filename}"
	fi

	cat "${last_update_filename}"
}

main() {
	get_remain_settings
	print_battery_remain
}
main
