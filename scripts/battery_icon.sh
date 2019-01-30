#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

# script global variables
charged_icon=""
charging_icon=""
attached_icon=""
# discharging_icon=""
full_charge_icon=""
high_charge_icon=""
medium_charge_icon=""
low_charge_icon=""

charged_default="❇ "
charged_default_osx="🔋 "
charging_default="⚡️ "
attached_default="⚠️ "
full_charge_icon_default="🌕 "
high_charge_icon_default="🌖 "
medium_charge_icon_default="🌗 "
low_charge_icon_default="🌘 "
very_low_charge_icon_default="🌑 "

charged_default() {
	if is_osx; then
		echo "$charged_default_osx"
	else
		echo "$charged_default"
	fi
}

# icons are set as script global variables
get_icon_settings() {
	charged_icon=$(get_tmux_option "@batt_charged_icon" "$(charged_default)")
	charging_icon=$(get_tmux_option "@batt_charging_icon" "$charging_default")
	attached_icon=$(get_tmux_option "@batt_attached_icon" "$attached_default")
	full_charge_icon=$(get_tmux_option "@batt_full_charge_icon" "$full_charge_icon_default")
	high_charge_icon=$(get_tmux_option "@batt_high_charge_icon" "$high_charge_icon_default")
	medium_charge_icon=$(get_tmux_option "@batt_medium_charge_icon" "$medium_charge_icon_default")
	low_charge_icon=$(get_tmux_option "@batt_low_charge_icon" "$low_charge_icon_default")
	very_low_charge_icon=$(get_tmux_option "@batt_very_low_charge_icon" "$very_low_charge_icon_default")
}

print_icon() {
	local status=$1
	if [[ $status =~ (charged) || $status =~ (full) ]]; then
		printf "$charged_icon"
	elif [[ $status =~ (^charging) ]]; then
		printf "$charging_icon"
	elif [[ $status =~ (^discharging) ]]; then
        # use code from the bg color
        percentage=$($CURRENT_DIR/battery_percentage.sh | sed -e 's/%//')
        if [ $percentage -le 100 -a $percentage -ge 90 ]; then
            printf "$full_charge_icon"
        elif [ $percentage -le 89 -a $percentage -ge 65 ];then
            printf "$high_charge_icon"
        elif [ $percentage -le 64 -a $percentage -ge 40 ];then
            printf "$medium_charge_icon"
        elif [ $percentage -le 39 -a $percentage -ge 20 ];then
            printf "$low_charge_icon"
        elif [ "$percentage" == "" ];then
            printf "$full_charge_icon_default"  # assume it's a desktop
        else
            printf "$very_low_charge_icon"
        fi
	elif [[ $status =~ (attached) ]]; then
		printf "$attached_icon"
	fi
}

main() {
	get_icon_settings
	local status=$(battery_status)
	print_icon "$status"
}
main
