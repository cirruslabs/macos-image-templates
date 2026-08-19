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

resolve_user_tcc_database() {
  local macos_version macos_major user_id open_files line candidate database=""
  macos_version="$(sw_vers -productVersion)"
  macos_major="${macos_version%%.*}"
  case "$macos_major" in
    ''|*[!0-9]*) echo "Unexpected macOS version: $macos_version" >&2; return 1 ;;
  esac

  if [[ "$macos_major" -lt 27 ]]; then
    database="${HOME}/Library/Application Support/com.apple.TCC/TCC.db"
  else
    # macOS 27 moved the user database into a per-user ProtectedSystem
    # container. Inspect the daemon's open files to avoid using a stale copy.
    # https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes#TCC
    user_id="$(id -u)"
    if ! open_files="$(sudo lsof -a -u "$user_id" -c tccd -Fn)"; then
      echo "Unable to inspect the user TCC daemon for UID $user_id" >&2
      return 1
    fi
    while IFS= read -r line; do
      case "$line" in
        n/private/var/containers/Data/ProtectedSystem/*/Data/Library/Application\ Support/com.apple.TCC/TCC.db)
          candidate="${line#n}"
          if [[ -n "$database" && "$database" != "$candidate" ]]; then
            echo "Found multiple active user TCC databases for UID $user_id" >&2
            return 1
          fi
          database="$candidate"
          ;;
      esac
    done <<< "$open_files"
    if [[ -z "$database" ]]; then
      echo "Unable to find the active user TCC database for UID $user_id" >&2
      return 1
    fi
  fi

  if ! sudo test -f "$database"; then
    echo "User TCC database does not exist: $database" >&2
    return 1
  fi
  if [[ "$macos_major" -ge 27 && "$(sudo stat -f %u "$database")" != "$user_id" ]]; then
    echo "Unexpected owner for user TCC database: $database" >&2
    return 1
  fi
  printf '%s\n' "$database"
}

update_tcc_database() {
  local tart_guest_agent_path
  tart_guest_agent_path="$(realpath /opt/homebrew/bin/tart-guest-agent)"

  sudo sqlite3 "$1" <<-EOF
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
	('kTCCServiceAppleEvents', 1, '/usr/bin/osascript', 2, 0, 1, 0, 'com.apple.Safari'),
	-- Direct Python invocation
	('kTCCServiceAccessibility', 0, 'org.python.python', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceScreenCapture', 0, 'org.python.python', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceMicrophone', 0, 'org.python.python', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServicePostEvent', 0, 'org.python.python', 2, 0, 1, NULL, 'UNUSED'),
	-- Commands invoked through the Tart Guest Agent
	('kTCCServiceAccessibility', 1, '${tart_guest_agent_path}', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceScreenCapture', 1, '${tart_guest_agent_path}', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServiceMicrophone', 1, '${tart_guest_agent_path}', 2, 0, 1, NULL, 'UNUSED'),
	('kTCCServicePostEvent', 1, '${tart_guest_agent_path}', 2, 0, 1, NULL, 'UNUSED');
	EOF
}

# Resolve the user database before making either update. Never create an empty
# database at an obsolete path or silently omit user-level grants.
user_tcc_database="$(resolve_user_tcc_database)"

# Update TCC.db for all users
update_tcc_database "/Library/Application Support/com.apple.TCC/TCC.db"

# Update TCC.db for the current user
update_tcc_database "$user_tcc_database"
