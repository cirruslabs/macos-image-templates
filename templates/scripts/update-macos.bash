#!/bin/bash -euo pipefail

function main() {
	declare -r username="${1:-"${VM_USERNAME:-"admin"}"}"
	declare -r password="${2:-"${VM_PASSWORD:-"admin"}"}"

	declare -ra setup_assistant_overrides=(
		DidSeeAccessibility
		DidSeeActivationLock
		DidSeeAppStore
		DidSeeAppearanceSetup
		DidSeeApplePaySetup
		DidSeeCloudSetup
		DidSeeLockdownMode
		DidSeePrivacy
		DidSeeScreenTime
		DidSeeSiriSetup
		DidSeeSyncSetup
		DidSeeSyncSetup2
		DidSeeTermsOfAddress
		DidSeeTouchIDSetup
		DidSeeiCloudLoginForStorageServices
	)

	# Trick macOS into thinking the Setup Assistant has already been run
	for key in "${setup_assistant_overrides[@]}"; do
		defaults write com.apple.SetupAssistant "${key}" -bool TRUE
	done

	for key in "${setup_assistant_overrides[@]}"; do
		sudo defaults write /Library/Preferences/com.apple.SetupAssistant "${key}" -bool TRUE
	done

	# Trick macOS into thinking this version/build has already been set up
	sudo defaults write /Library/Preferences/com.apple.SetupAssistant LastPrivacyBundleVersion "999999"
	sudo defaults write /Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "99Z999"
	sudo defaults write /Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "99.99.99"

	# Run softwareupdate to check for available updates
	softwareupdate --list

	declare -r os_major_version="$(sw_vers -productVersion | cut -d '.' -f 1)"
	declare -r update_label=$(
		softwareupdate --list | grep "${os_major_version}" | grep -E 'Label:.*' | sed 's/^[^:]*: //'
	)

	echo "Installing macOS Update..."
	echo "${password}" | sudo softwareupdate \
		--install \
		--verbose \
		--restart \
		--user "${username}" \
		--stdinpass \
		"${update_label}"
}

main "$@"
