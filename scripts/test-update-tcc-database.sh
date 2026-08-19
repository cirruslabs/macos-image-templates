#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TCC_TEST_ROOT
TCC_TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TCC_TEST_ROOT"' EXIT
export TCC_TEST_SQLITE
TCC_TEST_SQLITE=$(command -v sqlite3)
export TCC_TEST_SYSTEM_DB='/Library/Application Support/com.apple.TCC/TCC.db'
export TCC_TEST_LEGACY_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
export TCC_TEST_PROTECTED_DB='/private/var/containers/Data/ProtectedSystem/TEST-USER/Data/Library/Application Support/com.apple.TCC/TCC.db'
export TCC_TEST_AGENT='/opt/homebrew/Cellar/tart-guest-agent/0.13.0/bin/tart-guest-agent'

# Run the real provisioning script against temporary SQLite databases. Every
# privileged operation is intercepted; these tests never access the host's TCC.
source() {
  [[ $# == 1 && "$1" == "$HOME/.zprofile" ]]
}
sw_vers() {
  [[ $# == 1 && "$1" == -productVersion ]] || return 1
  printf '%s\n' "$TCC_TEST_MACOS_VERSION"
}
id() {
  [[ $# == 1 && "$1" == -u ]] || return 1
  printf '501\n'
}
realpath() {
  [[ $# == 1 && "$1" == /opt/homebrew/bin/tart-guest-agent ]] || return 1
  [[ "$TCC_TEST_AGENT_EXISTS" == 1 ]] || return 1
  printf '%s\n' "$TCC_TEST_AGENT"
}
sudo() {
  local subcommand="$1" database
  shift
  case "$subcommand" in
    lsof)
      [[ "$TCC_TEST_EXPECT_LSOF" == 1 && "$*" == '-a -u 501 -c tccd -Fn' ]] || return 1
      printf '%s\n' "$TCC_TEST_OPEN_FILES"
      return "$TCC_TEST_LSOF_STATUS"
      ;;
    test)
      [[ $# == 2 && "$1" == -f ]] || return 1
      case "$2" in
        "$TCC_TEST_LEGACY_DB") [[ "$TCC_TEST_LEGACY_EXISTS" == 1 ]] ;;
        "$TCC_TEST_PROTECTED_DB") [[ "$TCC_TEST_PROTECTED_EXISTS" == 1 ]] ;;
        *) return 1 ;;
      esac
      ;;
    stat)
      [[ $# == 3 && "$1" == -f && "$2" == %u && "$3" == "$TCC_TEST_PROTECTED_DB" ]] || return 1
      printf '%s\n' "$TCC_TEST_OWNER"
      ;;
    sqlite3)
      [[ $# == 1 ]] || return 1
      case "$1" in
        "$TCC_TEST_SYSTEM_DB") database="$TCC_TEST_ROOT/system.db" ;;
        "$TCC_TEST_LEGACY_DB"|"$TCC_TEST_PROTECTED_DB") database="$TCC_TEST_ROOT/user.db" ;;
        *) echo "Unexpected database: $1" >&2; return 1 ;;
      esac
      printf '%s\n' "$1" >> "$TCC_TEST_ROOT/writes"
      "$TCC_TEST_SQLITE" "$database"
      ;;
    *) echo "Unexpected sudo command: $subcommand" >&2; return 1 ;;
  esac
}
export -f source sw_vers id realpath sudo

reset_case() {
  export TCC_TEST_MACOS_VERSION=26.6.2 TCC_TEST_AGENT_EXISTS=1
  export TCC_TEST_LEGACY_EXISTS=1 TCC_TEST_PROTECTED_EXISTS=1 TCC_TEST_OWNER=501
  export TCC_TEST_EXPECT_LSOF=0 TCC_TEST_LSOF_STATUS=0 TCC_TEST_OPEN_FILES=''
  : > "$TCC_TEST_ROOT/writes"
  local database
  for database in system user; do
    "$TCC_TEST_SQLITE" "$TCC_TEST_ROOT/$database.db" <<'SQL'
DROP TABLE IF EXISTS access;
CREATE TABLE access (
  service TEXT NOT NULL,
  client_type INTEGER NOT NULL,
  client TEXT NOT NULL,
  auth_value INTEGER NOT NULL,
  auth_reason INTEGER NOT NULL,
  auth_version INTEGER NOT NULL,
  indirect_object_identifier_type INTEGER,
  indirect_object_identifier TEXT NOT NULL,
  PRIMARY KEY (service, client, client_type, indirect_object_identifier)
);
SQL
  done
}

golden_gate_case() {
  reset_case
  export TCC_TEST_MACOS_VERSION=27.0 TCC_TEST_EXPECT_LSOF=1
  # Include an obsolete legacy copy, the system database, a WAL, and duplicate
  # descriptors. Only the current user's active protected database may win.
  TCC_TEST_OPEN_FILES=$(printf 'p123\nn%s\nn%s-wal\nn%s\nn%s\nn%s\n' \
    "$TCC_TEST_SYSTEM_DB" "$TCC_TEST_PROTECTED_DB" "$TCC_TEST_LEGACY_DB" \
    "$TCC_TEST_PROTECTED_DB" "$TCC_TEST_PROTECTED_DB")
  export TCC_TEST_OPEN_FILES
}

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    printf 'Expected: %s\nActual: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

expect_success() {
  local user_database="$1" database expected_writes
  bash "$script_dir/update-tcc-database.sh"
  bash "$script_dir/update-tcc-database.sh"
  expected_writes=$(printf '%s\n%s\n%s\n%s' \
    "$TCC_TEST_SYSTEM_DB" "$user_database" "$TCC_TEST_SYSTEM_DB" "$user_database")
  assert_equal "$expected_writes" "$(< "$TCC_TEST_ROOT/writes")"
  for database in system user; do
    assert_equal 18 "$("$TCC_TEST_SQLITE" "$TCC_TEST_ROOT/$database.db" 'SELECT count(*) FROM access WHERE auth_value=2;')"
    assert_equal 4 "$("$TCC_TEST_SQLITE" "$TCC_TEST_ROOT/$database.db" "SELECT count(*) FROM access WHERE client='$TCC_TEST_AGENT' AND client_type=1;")"
    assert_equal 1 "$("$TCC_TEST_SQLITE" "$TCC_TEST_ROOT/$database.db" "SELECT count(*) FROM access WHERE client='org.python.python' AND service='kTCCServiceMicrophone';")"
  done
}

expect_failure() {
  if bash "$script_dir/update-tcc-database.sh" > "$TCC_TEST_ROOT/output" 2>&1; then
    echo 'Expected provisioning to fail' >&2
    exit 1
  fi
  if [[ -n "$1" ]] && ! grep -Fq "$1" "$TCC_TEST_ROOT/output"; then
    cat "$TCC_TEST_ROOT/output" >&2
    exit 1
  fi
  assert_equal '' "$(< "$TCC_TEST_ROOT/writes")"
}

reset_case
expect_success "$TCC_TEST_LEGACY_DB"
reset_case
TCC_TEST_MACOS_VERSION=12.7.6
expect_success "$TCC_TEST_LEGACY_DB"
golden_gate_case
expect_success "$TCC_TEST_PROTECTED_DB"

reset_case
TCC_TEST_LEGACY_EXISTS=0
expect_failure 'User TCC database does not exist'
golden_gate_case
TCC_TEST_LSOF_STATUS=1
expect_failure 'Unable to inspect the user TCC daemon'
golden_gate_case
TCC_TEST_OPEN_FILES="n$TCC_TEST_SYSTEM_DB"
expect_failure 'Unable to find the active user TCC database'
golden_gate_case
TCC_TEST_OPEN_FILES="$TCC_TEST_OPEN_FILES"$'\n'"n${TCC_TEST_PROTECTED_DB/TEST-USER/OTHER-USER}"
expect_failure 'Found multiple active user TCC databases'
golden_gate_case
TCC_TEST_PROTECTED_EXISTS=0
expect_failure 'User TCC database does not exist'
golden_gate_case
TCC_TEST_OWNER=502
expect_failure 'Unexpected owner for user TCC database'
golden_gate_case
TCC_TEST_AGENT_EXISTS=0
expect_failure ''
reset_case
TCC_TEST_MACOS_VERSION=invalid
expect_failure 'Unexpected macOS version'

echo 'TCC database tests passed'
