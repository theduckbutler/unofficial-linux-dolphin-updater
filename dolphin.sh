#!/bin/bash
if ! [[ "`cat /home/$(whoami)/dolphin-emu/.git/refs/heads/master`" == "`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`" ]]; then
	new_beta="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`"
	else
		new_beta='0'
fi
binary_search()
{
	low=0
	high="`curl "https://dolphin-emu.org/download/list/master/1/" 2>/dev/null \ | grep "/download/list/master/" | sed -n 'x;$p' | cut -c 40-42`"
	var+="${OPTARG}<"
	var_rel="${var:0:3}"
	var_ver="${OPTARG:4}"
	while [ $low -le $high ];  
    do
        mid=$((( $low + $high )/2))
        if [[ "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep "/download/dev"`" == *"$var"* ]];
            then
                version_searched="`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep "/download/dev" | grep "$var" | cut -c 67-106`"
			    echo "The commit hash that corresponds with $OPTARG is $version_searched"
				if [[ "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2</dev/null | grep "amd64.deb"`" == *"${var::-1}"* ]];
					then
						echo "This version(${var::-1}) has an associated .deb download"
						read -p "Download .deb file for ${var::-1}? [Y/n] "
						if [[ ${REPLY::1} == "y" ]];
							then
								xdg-open "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2</dev/null | grep "amd64.deb" | grep "${var::-1}" | cut -c 10-82`"
								exit
							elif [[ ${REPLY::1} == "n" ]];
								then
									exit
							else
								echo "Error: Invalid option"
								exit
						fi
				fi
                exit
            else
				if [[ $mid == 0 ]];
					then
						echo "Error: Invalid option"
						exit
				fi
				if [[ "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep -m1 "/download/dev"`" == *"$var_rel"* ]];
					then
						if [[ "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep "/download/dev" | tail -1`" == *"$var_rel"* ]];
							then
								version_searched="`curl "https://dolphin-emu.org/download/list/master/$mid/" 2</dev/null \ | grep -m1 "/download/dev" | cut -c 110-122`"
								while [[ $version_searched == *"<"* ]];
									do version_searched="`echo "$version_searched" | rev | cut -c2- | rev`"
								done
								version_searched=${version_searched:4}
								if [ $var_ver -lt $version_searched ];
									then
										low=$((mid+1))
									else
										high=$((mid-1))
								fi
							else
								high=$((mid-1))
						fi
					else
						if [[ "`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep "/download/dev" | tail -1`" == *"$var_rel"* ]];
							then
								low=$((mid+1))
							else
								version_searched="`curl "https://dolphin-emu.org/download/list/master/$mid/" 2>/dev/null \ | grep -m1 "/download/dev" | cut -c 110-112`"
								if ! [[ $((10#${var_rel/.})) > $((10#${version_searched/.})) ]];
									then
										low=$((mid+1))
									else
										high=$((mid-1))
								fi
						fi
				fi

        fi
        
	done
	echo "Error: Invalid option"
}
new_beta()
{
	if ! [[ $new_beta == '0' ]]; then
		echo "There is a new beta(official) version available!"
	fi
}
version() {
	current_version_commit="`cat /home/$(whoami)/dolphin-emu/.git/refs/heads/master`"
	current_version="`curl "https://dolphin-emu.org/download/dev/$current_version_commit/" 2>/dev/null \ | grep 'Information for' | cut -c 25-33`"
}
proceed() {
	exec bash "${BASH_SOURCE}"
}
current_check() {
	if [[ $current_version_commit == $commit_code ]]; then
		echo "Already updated to selected version"
		exit
	fi
}
commands() {
	echo "Commands:
	-h: returns the help message
	-c (dev or beta): returns the commit hash of the specified, most recent version
	-v (dev or beta or commit hash or version): returns the version of the specified, most recent version, or of the commit hash  or version specified
	-l: returns the current local version
	-u (dev or beta or commit hash): updates to most recent version of dev or beta selected, or of a specified commit hash"
}
getsomehelp() {
	echo "Instructions:"
	echo "Option 1: Update to the most recent beta or dev version
	1. Run '-u beta' to update to the most recent beta(official) version
	or
	2. Run '-u dev' to update to the most recent development version"
	echo "Option 2: Input a commit hash
	1. Go to 'https://dolphin-emu.org/download/'
	2. Click on the blue text to the left of the verison you want to update to
	3. Copy the commit hash listed on the page
	4. Execute this file with the argument '-u (commit hash)'"
	echo
	echo "Troubleshooting Steps:
	1. Make sure you have 'curl' installed on your computer
	2. Confirm the directory in which you have your dolphin files is within your home directory and named 'dolphin-emu'
	3. Confirm that the build directory within the dolphin directory is named 'Build'
	4. Ensure you have copied the entire, correct commit code for the version you want
	5. Make sure you have a secure internet connection"
	commands
	echo
}
build() {
	cmake /home/$(whoami)/dolphin-emu/
	make -j$(nproc)
}
specificversion() {
	cd /home/$(whoami)/dolphin-emu/
	echo 'Downloading commit code version...'
	git reset --hard --recurse-submodules $commit_code
}
do-it()
{
	url="https://dolphin-emu.org/download/dev/$commit_code"
	if curl --output /dev/null --silent --head --fail "$url";
		then specificversion
			echo "Valid commit code: $commit_code"
			cd /home/$(whoami)/dolphin-emu/
			sudo rm -r Build/
		else 
			echo "Sorry, invalid commit code or command: $commit_code"
			proceed
	fi
	mkdir /home/$(whoami)/dolphin-emu/Build && cd /home/$(whoami)/dolphin-emu/Build
	build && echo 'Compiled successfully.'
	sudo make install
	echo 'Installation success!'
	version
	echo "Current local version: $current_version" 
}
declare -A pkgmng;
pkgmng[/etc/redhat-release]=yum
pkgmng[/etc/arch-release]=pacman
pkgmng[/etc/gentoo-release]=emerge
pkgmng[/etc/SuSE-release]=zypp
pkgmng[/etc/debian_version]=apt-get
pkgmng[/etc/alpine-release]=apk
if [ -d /home/$(whoami)/dolphin-emu ];
	then
		if ! [ -d /home/$(whoami)/dolphin-emu/Build ];
			then
				echo "Error: 'Build' folder is either missing or incorrectly labeled"
				getsomehelp
				exit
		fi
	else
		echo "Error: 'dolphin-emu' folder is either missing or incorrectly labeled"
		getsomehelp
		exit
fi
for f in ${!pkgmng[@]}
do
	if [[ -f $f ]];
		then
			if [[ $(dpkg-query -W -f='${Status}' curl 2>/dev/null \ | grep -c "ok installed") -eq 0 ]];
			then
				echo "curl required for this script"
				sudo ${pkgmng[$f]} install curl
			fi
   	fi
done
version
while getopts ":h(help):lc:u:v:" option; do
	case $option in
		h)
			getsomehelp
			exit;;
		u)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					commit_code="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106`"
					current_check
					do-it
					exit
				else
					if [[ $OPTARG == "beta" ]];
						then
							commit_code="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`"
							current_check
							do-it
							exit
						else
							commit_code=$OPTARG
							current_check
							do_it
							exit
					fi
			fi
			;;
		c)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					new_beta
					version="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106`"
					echo "The most recent development commit hash is: $version"
					if [ $version == $current_version_commit ]; then
						echo "This is your current version"
					fi
				else
					if [[ $OPTARG == "beta" ]];
						then
							new_beta
							version="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`"
							echo "The most recent beta(official) commit hash is: $version"
							if [ $version == $current_version_commit ]; then
								echo "This is your current version"
							fi
						else
							echo "Error: Invalid option"
					fi
			fi
			;;			
		v)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					new_beta
					version="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'Download the latest version of the Dolphin Emulator' -m 1 | cut -c 96-104`"
					echo "The most recent development version is: $version"
					if [ $version == $current_version ]; then
						echo "This is your current version"
					fi
				else
					if [[ $OPTARG == "beta" ]];
						then
							new_beta
							version="`curl "https://dolphin-emu.org/download/" 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 110-118`"
							echo "The most recent beta(official) version is: $version"
							if [[ $version == $current_version ]]; then
								echo "This is your current version"
							fi
						else
							if [[ $OPTARG == *"."* ]];
								then
									binary_search
								else
									version="`curl "https://dolphin-emu.org/download/dev/$OPTARG/" 2>/dev/null \ | grep 'Information on' | cut -c 50-65`"
									if [[ $version == *"5."* || $version == *"3."* || $version == *"4."* ]];
										then
											while [[ $version == *"<"* ]];
												do version="`echo "$version" | rev | cut -c2- | rev`"
											done
											echo "The version that corresponds with the commit hash $OPTARG is $version"
										else
											echo "Error: Invalid option"
									fi
							fi
					fi
			fi
			;;
		l)
			version
			echo "Current local version: $current_version" 
			exit;;
		\?)
			echo "Error: Invalid option"
			exit;;
	esac
done
