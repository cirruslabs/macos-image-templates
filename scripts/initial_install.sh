#!/bin/zsh

ADMIN_USER_NAME=admin

# passwordless sudo
echo "${ADMIN_USER_NAME} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${ADMIN_USER_NAME}

# sleep off
sudo systemsetup -setdisplaysleep "Off"
sudo systemsetup -setsleep "Off"
sudo systemsetup -setcomputersleep "Off"

# lock screen off
sudo sysadminctl -screenLock off -password - # requires password :(

# screensaver off at login screen
sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0

# screensaver off for user: doesn't work despite the documentation
# https://developer.apple.com/documentation/devicemanagement/screensaveruser
# defaults write ~/Library/Preferences/com.apple.screensaver.user idleTime 0

# enable remote automation & develop menu
sudo safaridriver --enable
sudo defaults write com.apple.Safari IncludeDevelopMenu 1

 # autologin possible with this project but requires `brew` or `git` and neither available without further software installations
 # https://github.com/xfreebird/kcpassword
