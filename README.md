# ButtonForge - The War Within/Midnight

Change Log:
2026-03-04
Updated and tested with ButtonForge 1.3.4.2

I updated my script that creates "ButtonForge Global" tested and working with 1.3.4.2
Here's the creator script, that makes the new "ButtonForge Global" addon folder:

If you cannot run the script in bash, I will include the zip file of the addon.

2026-02-13
I found a conflict when trying to set keybinds between the 2 versions, and corrected it.
Both links below are updated to new files.

This is a branch of ButtonForge originally created by Alternator
https://www.curseforge.com/wow/addons/button-forge

Until the addon is updated to allow global palettes, I created this script to do it.
Runs in bash, under macOS, but should run in Windows under wsl or git bash. I cannot test for windows now.

## Instructions
run the script, and it creates another addon folder ButtonForgeGlobal
/reload wow, and it should load.
Global palettes are a little darker, so you can see they are global.
/bufog and /buttonforgeglobal are the new slash commands.

Here's a toggle macro:
/click [nomod,button:1] BFToolbarToggle
/click [mod,button:1][button:2] BFGToolbarToggle

This bash script does NOT modify the original, and they work together.

Since I made this to copy the original, it should allow you to run it again, after an update, to re-create the new golobal version.

Hopefully, the author can get around to allowing palettes to be flagged as global.
This is a lot of rework though. I did it, and it had issues as you logged into more than 4 toons.
This way, this version, keeps it completely isolated as a new addon, so there should never be a conflict.

I wanted to make this for my own use, and decided to share, because it was a LOT of work, nad maybe the author can use it.


just in case you can't run the script on Windows, here's a link to the created version:
ButtonForgeGlobal.zip

# <LAST_SAVED> 20261023 00:42:14
