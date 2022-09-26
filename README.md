# unofficial-linux-dolphin-updater
Have you ever wanted to switch to a specific version of Dolphin to play with friends on netplay, or maybe some other reason? But then realized you run Linux like an awesome person, but can't update to the precise version you want because the Linux support isn't as good as other OS's?

Well now you can!

I've written a relatively simple bash script to do just that! Download the .sh file here dolphin(v1.4).sh, and store it somewhere on your computer. Whenever you have the desire to update(or even downgrade if you feel like it), simply run the script using bash, NOT SH.

The only prerequisites needed are Dolphin(obviously), but it must be built and compiled as described on the official 'Building Dolphin for Linux' page, with the folder containing Dolphin being named 'dolphin-emu' and the build folder named 'Build', as described in the instructions. The script will also install curl the first time you run it, if you don't already have curl installed.
