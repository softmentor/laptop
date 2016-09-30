# Changelog

### 0.1.0 (2016-10-08)

- First Release of mac laptop setup
- Automate setting up mac environment setting
    - Added settings for the following: 
        ```
        defaults write com.apple.dock
        defaults write com.apple.screencapture
        defaults write com.apple.finder
        defaults write com.apple.DiskUtility
        ```
    - 
- Automate installation of following:
    - basics covered by Xcode
    - shell using ohmyzsh
    - package management using brew, cask
    - dotfile management using rcm (https://github.com/thoughtbot/rcm)
    -  