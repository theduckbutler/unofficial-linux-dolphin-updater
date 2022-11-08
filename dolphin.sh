#!/bin/bash
if [[ "$FIRST_RUN" == "" ]]; then
	FIRST_RUN=no
	export FIRST_RUN
	if ! [[ "`cat /home/$(whoami)/dolphin-emu/.git/refs/heads/master`" == "`wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`" ]]; then
		echo "There is a new beta(official) version available!"
	fi
fi
version() {
	current_version_commit="`cat /home/$(whoami)/dolphin-emu/.git/refs/heads/master`"
	echo "`wget --output-document=- https://dolphin-emu.org/download/dev/$current_version_commit/ 2>/dev/null \ | grep 'Information for' | cut -c 25-33`"
}
proceed() {
	exec bash "${BASH_SOURCE}"
}
current_check() {
	if [[ "`cat /home/$(whoami)/dolphin-emu/.git/refs/heads/master`" == $commit_code ]]; then
		echo "Already updated to selected version"
		exit
	fi
}
commands() {
	echo "Commands:
	-c (dev or beta): returns the commit hash of the specified, most recent version
	-v (dev or beta): returns the version of the specified, most recent version
	-l: returns the current local version
	-u (dev or beta or commit hash): updates to most recent version of dev or beta selected, or of a specified commit hash"
}
getsomehelp() {
	echo "Instructions:"
	echo "Option 1: Update to the most recent beta or dev version
	1. Run '-u beta' to update to the most recent beta(official) version
	or
	2. Run '-u dev' to update to the most recent development version"
	echo "Option 2: Input a commit code
	1. Go to 'https://dolphin-emu.org/download/'
	2. Click on the blue text to the left of the verison you want to update to
	3. Copy the commit code listed on the page
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
			if [[ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]];
			then
				echo "curl required for this script"
				sudo ${pkgmng[$f]} install curl
			fi
   	fi
done
while getopts ":h(help):lc:u:v:" option; do
	case $option in
		h)
			getsomehelp
			exit;;
		u)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					commit_code="`wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106`"
					current_check
					do-it
					exit
				else
					if [[ $OPTARG == "beta" ]];
						then
							commit_code="`wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`"
							current_check
							do-it
							exit
						else
							commit_code=$OPTARG
							echo "$commit_code"
					fi
			fi
			;;
		c)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106
				else
					if [[ $OPTARG == "beta" ]];
						then
							version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106
						else
							echo "Error: Invalid option"
					fi
			fi
			;;			
		v)
			if [[ $OPTARG == "dev" || $OPTARG == "development" ]];
				then
					version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'Download the latest version of the Dolphin Emulator' -m 1 | cut -c 96-104
				else
					if [[ $OPTARG == "beta" ]];
						then
							version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 110-118
						else
							echo "Error: Invalid option"
					fi
			fi
			;;
		l)
			version
			exit;;
		\?)
			echo "Error: Invalid option"
			exit;;
	esac
done
