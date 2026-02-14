#!/bin/bash

# Check new patch:
get_date() {
	case "$2" in
		latest)
			updated_at=$(echo "$1" | jq -r 'first(.[] | select(.prerelease == false) | .assets[] | select(.name | test("'$3'")) | .updated_at)')
			;;
		prerelease)
			updated_at=$(echo "$1" | jq -r 'first(.[] | select(.prerelease == true) | .assets[] | select(.name | test("'$3'")) | .updated_at)')
			;;
		*)
			updated_at=$(echo "$1" | jq -r 'first(.[] | select(.tag_name == "'$2'") | .assets[] | select(.name | test("'$3'")) | .updated_at)')
			;;
	esac
	echo "$updated_at"
}

checker(){
	local date1 date2 date1_sec date2_sec repo=$1 ur_repo=$repository check=$3
	json=$(wget -qO- "https://api.github.com/repos/$repo/releases")
	date1=$(get_date "$json" "$2" "^(.*\\\.jar|.*\\\.rvp|.*\\\.mpp)$")
	date1_sec=$(date -d "$date1" +%s)

	case "$2" in
		latest)
			patch_version=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == false) | .tag_name)')
			;;
		prerelease)
			patch_version=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == true) | .tag_name)')
			;;
		*)
		patch_version=$2
		;;
	esac
	echo "patch_version=$patch_version" >> "$GITHUB_OUTPUT"
	echo -e "\e[32mLatest patch version: $patch_version\e[0m"
	
	json=$(wget -qO- "https://api.github.com/repos/$ur_repo/releases")
	date2=$(get_date "$json" "$2" "^(.*\\\.apk)$")
	date2_sec=$(date -d "$date2" +%s)

	if [ -z "$date2" ] || [ "$date1_sec" -gt "$date2_sec" ]; then
		echo "new_patch=1" >> "$GITHUB_OUTPUT"
		echo -e "\e[32mUpdate status: true\e[0m"
	elif [ "$date1_sec" -lt "$date2_sec" ]; then
		echo "new_patch=0" >> "$GITHUB_OUTPUT"
		echo -e "\e[32mUpdate status: false\e[0m"
	fi	
}

checker $1 $2 $3