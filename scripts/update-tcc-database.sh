#!/bin/bash

source ~/.zprofile

# Set shell options to enable fail-fast behavior
#
# * -e: fail the script when an error occurs or command fails
# * -u: fail the script when attempting to reference unset parameters
# * -o pipefail: by default an exit status of a pipeline is that of its
#                last command, this fails the pipe early if an error in
#                any of its commands occurs
#
set -euo pipefail

update_tcc_database() {
  sudo sqlite3 "$1" <<-'EOF'
	INSERT OR REPLACE
	INTO access (
	  service,
	  client_type,
	  client,
	  auth_value,
	  auth_reason,
	  auth_version,
	  indirect_object_identifier_type,
	  indirect_object_identifier
	) VALUES
	-- Indirect osascript invocation via SSH
	('kTCCServiceAccessibility', 1, '/usr/libexec/sshd-keygen-wrapper', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceScreenCapture', 1, '/usr/libexec/sshd-keygen-wrapper', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServicePostEvent', 1, '/usr/libexec/sshd-keygen-wrapper', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceAppleEvents', 1, '/usr/libexec/sshd-keygen-wrapper', 2, 0, 1, 0, 'com.apple.systemevents'),
	('kTCCServiceAppleEvents', 1, '/usr/libexec/sshd-keygen-wrapper', 2, 0, 1, 0, 'com.apple.Safari'),
	-- Direct osascript invocation
	('kTCCServiceAccessibility', 1, '/usr/bin/osascript', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceScreenCapture', 1, '/usr/bin/osascript', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServicePostEvent', 1, '/usr/bin/osascript', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceAppleEvents', 1, '/usr/bin/osascript', 2, 0, 1, 0, 'com.apple.systemevents'),
	('kTCCServiceAppleEvents', 1, '/usr/bin/osascript', 2, 0, 1, 0, 'com.apple.Safari');
	EOF
}

# Update TCC.db for all users
update_tcc_database "/Library/Application Support/com.apple.TCC/TCC.db"

# Update TCC.db for the current user
update_tcc_database "${HOME}/Library/Application Support/com.apple.TCC/TCC.db"
