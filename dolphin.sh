#!/bin/bash
dupe_script=$(ps -ef | grep "$(basename $BASH_SOURCE)" | grep -v grep | wc -l | xargs)
if [ ${dupe_script} -gt 2 ]; then
    echo -e "Error: another instance of this script is already running"
    exit
fi
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
		echo -ne '\033[B'
		echo "Already updated to selected version"
		proceed
	fi
}
commands() {
	echo "Commands:
	--commands/-C: read the list of commands
	--commit-beta: returns the commit code of the most recent beta(official) version
	--commit-dev: returns the commit code of the most recent development version
	--help/-H: reads the help information
	--update-beta: updates to the most recent beta(official) version
	--update-dev: updates to the most recent development version
	--version/-V: returns the current version installed
	--version-beta: returns the most recent beta(official) version
	--version-dev: returns the most recent development version"
}
getsomehelp() {
	echo "Instructions:"
	echo "Option 1: Update to the most recent beta or dev version
	1. Run --update-beta to update to the most recent beta(official) version
	or
	2. Run --update-dev to update to the most recent development version"
	echo "Option 2: Input a commit code
	1. Go to 'https://dolphin-emu.org/download/'
	2. Click on the blue text to the left of the verison you want to update to
	3. Copy the commit code listed on the page
	4. Run this program
	5. When propmted a commit code, paste the commmit code you've just copied
	6. Now just press enter and you're good to go!"
	echo
	echo "Troubleshooting Steps:
	1. Make sure you have 'curl' installed on your computer
	2. Confirm the directory in which you have your dolphin files is within your home directory and named 'dolphin-emu'
	3. Confirm that the build directory within the dolphin directory is named 'Build'
	4. Ensure you have copied the entire, correct commit code for the version you want
	5. Make sure you have a secure internet connection
	6. Do NOT run this file as root
	7. Even you're not doing it now, running this file with 'sh' will not work, using 'bash' is a must
	8. It is crucial you are connected to the internet at all times while running this script"
	echo
}
build() {
	cmake /home/$(whoami)/dolphin-emu
	make
}
specificversion() {
	cd /home/$(whoami)/dolphin-emu/
	echo 'Downloading commit code version...'
	git reset --hard --recurse-submodules $commit_code
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
echo 'Please enter your commit code or command'
until ! [ ${#commit_code} == 0 ];
do
	read commit_code
	echo -ne '\033[A'
done
current_check
if [ $commit_code == '--help' ] || [ $commit_code == '-H' ];
	then echo -ne '\033[B'
	getsomehelp
	proceed
	else
		if [ $commit_code == '--commands' ] || [ $commit_code == '-C' ];
			then echo -ne '\033[B'
			commands
			proceed
			else
				if [[ $commit_code == "--version-beta" ]];
					then echo -ne '\033[B'
						version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 110-118
						proceed
						else
							if [[ $commit_code == "--commit-beta" ]]; then
								echo -ne '\033[B'
								version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106
								proceed
								else
									if [[ $commit_code == '--version-dev' ]]; then
										echo -ne '\033[B'
										version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'Download the latest version of the Dolphin Emulator' -m 1 | cut -c 96-104
										proceed
										else
											if [[ $commit_code == '--commit-dev' ]]; then
												echo -ne '\033[B'
												version= wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106
												proceed
												else
													if [[ $commit_code == '--update-beta' ]]; then
														echo -ne '\033[B'
														commit_code="`wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' -m 1 | cut -c 67-106`"
														current_check
														else
															if [[ $commit_code == '--update-dev' ]]; then
																echo -ne '\033[B'
																commit_code="`wget --output-document=- https://dolphin-emu.org/download 2>/dev/null \ | grep 'version always-ltr' | head -6 | tail -1 | cut -c 67-106`"
																current_check
																else
																	if [ $commit_code == "--version" ] || [ $commit_code == '-V' ]; then
																		echo -ne '\033[B'
																		version
																		proceed
																		else
																			if [[ $commit_code == "--exit" ]]; then
																				echo -ne '\033[B'
																				exit
																			else echo -ne '\033[B'
																			fi
																	fi
															fi
													fi
											fi
									fi
							fi
				fi
		fi
fi
url="https://dolphin-emu.org/download/dev/$commit_code"
#echo "Checking URL: $url" 
if curl --output /dev/null --silent --head --fail "$url";
	then specificversion
		echo "Valid commit code: $commit_code"
	else 
		echo "Sorry, invalid commit code or command: $commit_code"
		proceed
fi
mkdir -p /home/$(whoami)/dolphin-emu/Build
cd /home/$(whoami)/dolphin-emu/Build
build && echo 'Compiled successfully.'
sudo make install
echo 'Installation success!'
proceed
