#!/bin/bash

# Check new patch:
get_date() {
	json=$(wget -qO- "https://api.github.com/repos/$1/releases")
	case "$2" in
		latest)
			updated_at=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == false) | .assets[] | select(.name | test("'$3'")) | .updated_at)')
            patch_version=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == false) | .tag_name)')
			;;
		prerelease)
			updated_at=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == true) | .assets[] | select(.name | test("'$3'")) | .updated_at)')
            patch_version=$(echo "$json" | jq -r 'first(.[] | select(.prerelease == true) | .tag_name)')
			;;
		*)
			updated_at=$(echo "$json" | jq -r 'first(.[] | select(.tag_name == "'$2'") | .assets[] | select(.name | test("'$3'")) | .updated_at)')
            patch_version=$(echo "$json" | jq -r 'first(.[] | .tag_name)')
			;;
	esac

    if [[ $1 == "Revanced/revanced-patches" ]]; then
		echo "patch_version=${patch_version}" >> $GITHUB_OUTPUT
	fi

	echo "$updated_at"
}

checker(){
	local date1 date2 date1_sec date1_sec repo=$1 ur_repo=$repository check=$3
	date1=$(get_date "$repo" "$2" "^(.*\\\.jar|.*\\\.rvp|.*\\\.mpp)$")
	date2=$(get_date "$ur_repo" "$2" "^(.*\\\.apk)$")
	date1_sec=$(date -d "$date1" +%s)
	date2_sec=$(date -d "$date2" +%s)
	if [ -z "$date2" ] || [ "$date1_sec" -gt "$date2_sec" ]; then
		echo "new_patch=1" >> $GITHUB_OUTPUT
		echo -e "\e[32mNew patch, building...\e[0m"
	elif [ "$date1_sec" -lt "$date2_sec" ]; then
		echo "new_patch=0" >> $GITHUB_OUTPUT
		echo -e "\e[32mOld patch, not build.\e[0m"
	fi
}

checker $1 $2 $3