#!/usr/bin/env bash
# Offline function tests. Never call main or use the deployment host.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export CPA_DEPLOY_LIBRARY_ONLY=1
source "$ROOT/cpa-deploy.sh"

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cpa-oss-tests.XXXXXX")
TEST_DIR=$(cd -- "$TEST_DIR" && pwd)
TEST_PARENT=$(dirname -- "$TEST_DIR")
cleanup_tests() {
    cleanup
    # Only remove the exact, resolved temporary test directory.
    if [[ -n "$TEST_PARENT" && "$TEST_DIR" == "$TEST_PARENT"/cpa-oss-tests.* ]]; then
        rm -rf -- "$TEST_DIR"
    fi
}
trap cleanup_tests EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_failure() {
    if "$@" >/dev/null 2>&1; then
        fail "unexpected success: $1"
    fi
}

TEST_POSIX_MODE=1
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        TEST_POSIX_MODE=0
        printf 'SKIP: POSIX permission assertion on Windows; Linux CI checks mode 0600\n'
        ;;
esac

secret=$(generate_deployment_secret 'test-')
[[ "$secret" =~ ^test-[0-9a-fA-F]{32}$ ]] || fail 'secret shape'
(
    openssl() { return 1; }
    fallback=$(generate_deployment_secret 'test-')
    [[ "$fallback" =~ ^test-[0-9a-fA-F]{32}$ ]] || fail 'secure random fallback'
)
(
    openssl() { return 1; }
    head() { return 1; }
    expect_failure generate_deployment_secret 'test-'
)
(
    openssl() { printf 'short\n'; }
    head() { return 1; }
    expect_failure generate_deployment_secret 'test-'
)
(
    generate_deployment_secret() { return 1; }
    expect_failure collect_deployment_inputs 1 0 0
)
test_default='fixture-default-value'
prompt_output=$(
    prompt_deployment_key entered 'Test key' "$test_default" <<< '' 2>&1
    [[ "$entered" == "$test_default" ]] || fail 'default was not accepted'
)
[[ "$prompt_output" != *"$test_default"* ]] || fail 'default leaked in prompt'
prompt_output=$(
    prompt_deployment_key entered 'Test key' <<< 'fixture-entered-value' 2>&1
    [[ "$entered" == 'fixture-entered-value' ]] || fail 'entered key was not accepted'
)
[[ "$prompt_output" != *'fixture-entered-value'* ]] || fail 'entered key leaked'
expect_failure valid_deployment_key 'short'
expect_failure valid_deployment_key 'bad key with spaces'
valid_deployment_domain 'api.example.com' || fail 'domain validation'
expect_failure valid_deployment_domain 'https://api.example.com/path'

DEPLOY_CPA_API_KEY='fixture-api-private'
DEPLOY_CPA_MGMT_KEY='fixture-management-private'
DEPLOY_CPAMP_ADMIN_KEY='fixture-admin-private'
CPAMP_BIN="$TEST_DIR/no-installed-cpamp"
summary=$(show_deployment_summary 'CPA 网关（含准入连接迁移）' 2>&1)
[[ "$summary" == *'http://127.0.0.1:8317/v1'* ]] || fail 'gateway endpoint missing'
for value in "$DEPLOY_CPA_API_KEY" "$DEPLOY_CPA_MGMT_KEY" "$DEPLOY_CPAMP_ADMIN_KEY"; do
    [[ "$summary" != *"$value"* ]] || fail 'summary leaked a secret'
done
(
    deployment_public_ip() { printf '203.0.113.9\n'; }
    DEPLOY_DOMAIN=''
    summary=$(show_deployment_summary '完整栈' 2>&1)
    [[ "$summary" == *'HTTP'* && "$summary" == *'HTTPS'* ]] || fail 'HTTP warning missing'
)

(
    DEPLOY_TMP="$TEST_DIR"
    DEPLOY_CREDENTIALS_FILE="$TEST_DIR/credentials.conf"
    admission_atomic_install() {
        [[ "$3" == 0600 && "$4" == root && "$5" == root ]] || return 1
        cp -- "$1" "$2" && chmod "$3" "$2"
    }
    receipt_output=$(save_deployment_credentials 2>&1)
    [[ "$receipt_output" != *"$DEPLOY_CPA_MGMT_KEY"* ]] || fail 'receipt echoed a secret'
    grep -Fqx "CPA_MGMT_KEY=$DEPLOY_CPA_MGMT_KEY" "$DEPLOY_CREDENTIALS_FILE" \
        || fail 'original management key was not retained'
    DEPLOY_CPA_API_KEY=''
    DEPLOY_CPA_MGMT_KEY=''
    DEPLOY_CPAMP_ADMIN_KEY='fixture-new-admin'
    save_deployment_credentials || fail 'receipt merge'
    grep -Fqx 'CPA_API_KEY=fixture-api-private' "$DEPLOY_CREDENTIALS_FILE" \
        || fail 'receipt dropped an existing key'
    grep -Fqx 'CPAMP_ADMIN_KEY=fixture-new-admin' "$DEPLOY_CREDENTIALS_FILE" \
        || fail 'receipt did not update admin key'
    if [[ "$TEST_POSIX_MODE" == 1 ]]; then
        [[ "$(stat -c %a "$DEPLOY_CREDENTIALS_FILE")" == 600 ]] || fail 'receipt mode'
    fi
    prior=$(sha256sum "$DEPLOY_CREDENTIALS_FILE")
    admission_atomic_install() { return 1; }
    expect_failure save_deployment_credentials
    [[ "$(sha256sum "$DEPLOY_CREDENTIALS_FILE")" == "$prior" ]] || fail 'failed receipt write changed old file'
)

admission_set_defaults
admission_validate_settings || fail 'default admission settings'
(
    DEFAULT_ACTIVE=65
    expect_failure admission_validate_settings
)
(
    DEFAULT_BACKLOG=1
    expect_failure admission_validate_settings
)
printf 'DEFAULT_ACTIVE=$(touch %s)\nDEFAULT_BACKLOG=16\n' "$TEST_DIR/injected" > "$TEST_DIR/injection.conf"
expect_failure admission_load_settings "$TEST_DIR/injection.conf"
[[ ! -e "$TEST_DIR/injected" ]] || fail 'config was executed'
printf 'DEFAULT_ACTIVE=6\nDEFAULT_BACKLOG=6\n' > "$TEST_DIR/legacy.conf"
admission_load_settings "$TEST_DIR/legacy.conf" || fail 'legacy configuration migration'
[[ "$DEFAULT_ACTIVE" == 6 && "$DEFAULT_BODY_LIMIT_MB" == 32 ]] || fail 'legacy defaults'
printf 'DEFAULT_ACTIVE=6\nDEFAULT_ACTIVE=7\nDEFAULT_BACKLOG=8\n' > "$TEST_DIR/duplicate.conf"
expect_failure admission_load_settings "$TEST_DIR/duplicate.conf"

(
    systemctl() { return 0; }
    cpamp_admin_key() { printf 'fixture-maintenance-secret\n'; }
    cpamp_http_origin() { printf 'http://127.0.0.1:18317\n'; }
    curl() {
        local body='' header='' argument
        for argument in "$@"; do
            [[ "$argument" != *'fixture-maintenance-secret'* ]] || return 9
        done
        while (( $# )); do
            case "$1" in
                -o) body="$2"; shift 2 ;;
                --header) header="${2#@}"; shift 2 ;;
                *) shift ;;
            esac
        done
        [[ -n "$header" && -f "$header" ]] || return 9
        if [[ "$TEST_POSIX_MODE" == 1 ]]; then
            [[ "$(stat -c %a "$header")" == 600 ]] || return 9
        fi
        grep -Fq 'fixture-maintenance-secret' "$header" || return 9
        printf '{"databaseMaintenance":{"required":false}}\n' > "$body"
        printf '200'
    }
    rc=0
    cpamp_database_maintenance_required || rc=$?
    [[ "$rc" == 1 ]] || fail "maintenance header-file authentication: ${CPAMP_MAINT_LAST_ERROR}"
)

printf '{"today":{"total_calls":1},"top_models_today":[{"model":"fixture-admin-secret"}]}\n' > "$TEST_DIR/raw.json"
expect_failure public_status_sanitize_payload "$TEST_DIR/raw.json" "$TEST_DIR/clean.json" 'fixture-admin-secret'
[[ ! -e "$TEST_DIR/clean.json" ]] || fail 'leaking snapshot was retained'
printf '{"today":{"total_calls":1},"authorization":"private","request_body":"private"}\n' > "$TEST_DIR/raw.json"
public_status_sanitize_payload "$TEST_DIR/raw.json" "$TEST_DIR/clean.json" || fail 'sanitizer'
jq -e '.today.requests == 1 and (has("authorization") | not) and (has("request_body") | not)' \
    "$TEST_DIR/clean.json" >/dev/null || fail 'sanitizer allowlist'

printf 'PASS: offline shell regressions\n'
