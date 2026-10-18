#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 CPA Deploy contributors

set -uo pipefail

SCRIPT_VERSION="2.44-oss.1"
SYSTEMD_UNIT_DIR="/etc/systemd/system"
CPA_DIR="/opt/cpa"
CPA_BIN="${CPA_DIR}/CLIProxyAPI"
CPA_SERVICE="cpa.service"
CPA_UNIT_FILE="/etc/systemd/system/${CPA_SERVICE}"
CPA_PUBLIC_PORT=8317
CPA_BACKEND_PORT=18318
CPAMP_DIR="/opt/cpamp"
CPAMP_BIN="${CPAMP_DIR}/cpa-manager-plus"
CPAMP_SERVICE="cpamp.service"
CPAMP_UNIT_FILE="/etc/systemd/system/${CPAMP_SERVICE}"
CPAMP_MAINT_SERVICE="cpamp-db-maintenance.service"
CPAMP_MAINT_MANUAL_SERVICE="cpamp-db-maintenance-manual.service"
CPAMP_MAINT_TIMER="cpamp-db-maintenance.timer"
CPAMP_MAINT_SERVICE_FILE="/etc/systemd/system/${CPAMP_MAINT_SERVICE}"
CPAMP_MAINT_MANUAL_SERVICE_FILE="/etc/systemd/system/${CPAMP_MAINT_MANUAL_SERVICE}"
CPAMP_MAINT_TIMER_FILE="/etc/systemd/system/${CPAMP_MAINT_TIMER}"
CPAMP_MAINT_PENDING="${CPAMP_DIR}/.database-maintenance-pending"
CPAMP_MAINT_ADMIN_KEY_FILE="/etc/cpa-cpamp-maintenance.key"
CPAMP_MAINT_RUNTIME_STATE="/run/lock/cpa-cpamp-maintenance.state"
PUBLIC_STATUS_CONFIG_DIR="/etc/cpa-public-status"
PUBLIC_STATUS_CONFIG="${PUBLIC_STATUS_CONFIG_DIR}/status.conf"
PUBLIC_STATUS_QUOTA_CONFIG="${PUBLIC_STATUS_CONFIG_DIR}/quota.conf"
PUBLIC_STATUS_QUOTA_REMARKS="${PUBLIC_STATUS_CONFIG_DIR}/quota-remarks.json"
PUBLIC_STATUS_CUSTOM_ALLOW="${PUBLIC_STATUS_CONFIG_DIR}/allowlist.custom"
PUBLIC_STATUS_CN4="${PUBLIC_STATUS_CONFIG_DIR}/cn-ipv4.txt"
PUBLIC_STATUS_CN6="${PUBLIC_STATUS_CONFIG_DIR}/cn-ipv6.txt"
PUBLIC_STATUS_CN_METADATA="${PUBLIC_STATUS_CONFIG_DIR}/cn-metadata.conf"
PUBLIC_STATUS_DIR="/var/lib/cpamp-public"
PUBLIC_STATUS_WEB_ROOT="${PUBLIC_STATUS_DIR}/www"
PUBLIC_STATUS_SNAPSHOT="${PUBLIC_STATUS_WEB_ROOT}/snapshot.json"
PUBLIC_STATUS_LAST_ERROR="${PUBLIC_STATUS_DIR}/last-error"
PUBLIC_STATUS_CADDY_DIR="/etc/caddy/cpa.d/sites"
PUBLIC_STATUS_CADDY_FILE="${PUBLIC_STATUS_CADDY_DIR}/cpamp-public.caddy"
PUBLIC_STATUS_CADDY_IMPORT='import /etc/caddy/cpa.d/sites/*.caddy'
PUBLIC_STATUS_CADDY_LOCK="/run/lock/cpa-caddy-config.lock"
PUBLIC_STATUS_SNAPSHOT_LOCK="/run/lock/cpamp-public-snapshot.lock"
PUBLIC_STATUS_SERVICE="cpamp-public-snapshot.service"
PUBLIC_STATUS_TIMER="cpamp-public-snapshot.timer"
PUBLIC_STATUS_CN_SERVICE="cpamp-public-cn-update.service"
PUBLIC_STATUS_CN_TIMER="cpamp-public-cn-update.timer"
PUBLIC_STATUS_QUOTA_SERVICE="cpamp-public-quota-refresh.service"
PUBLIC_STATUS_QUOTA_TIMER="cpamp-public-quota-refresh.timer"
PUBLIC_STATUS_QUOTA_ACTIVE_CACHE="${PUBLIC_STATUS_DIR}/quota-active.json"
PUBLIC_STATUS_QUOTA_REFRESH_LOCK="/run/lock/cpamp-public-quota-refresh.lock"
PUBLIC_STATUS_SERVICE_FILE="/etc/systemd/system/${PUBLIC_STATUS_SERVICE}"
PUBLIC_STATUS_TIMER_FILE="/etc/systemd/system/${PUBLIC_STATUS_TIMER}"
PUBLIC_STATUS_CN_SERVICE_FILE="/etc/systemd/system/${PUBLIC_STATUS_CN_SERVICE}"
PUBLIC_STATUS_CN_TIMER_FILE="/etc/systemd/system/${PUBLIC_STATUS_CN_TIMER}"
PUBLIC_STATUS_QUOTA_SERVICE_FILE="/etc/systemd/system/${PUBLIC_STATUS_QUOTA_SERVICE}"
PUBLIC_STATUS_QUOTA_TIMER_FILE="/etc/systemd/system/${PUBLIC_STATUS_QUOTA_TIMER}"
PUBLIC_STATUS_STATUS_LOG="/var/log/caddy/status-access.log"
PUBLIC_STATUS_RICH_HELPER="/usr/local/lib/cpa-public-status-rich.py"
PUBLIC_STATUS_CN4_URL="https://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone"
PUBLIC_STATUS_CN6_URL="https://www.ipdeny.com/ipv6/ipaddresses/aggregated/cn-aggregated.zone"
CADDY_CONFIG_FILE="/etc/caddy/Caddyfile"
CADDY_LOG_DIR="/var/log/caddy"
CADDY_LOG_PATTERN="access*"
CPA_ADMISSION_SOCKET="cpa-admission.socket"
CPA_ADMISSION_SERVICE="cpa-admission.service"
CPA_ADMISSION_SOCKET_FILE="/etc/systemd/system/${CPA_ADMISSION_SOCKET}"
CPA_ADMISSION_SERVICE_FILE="/etc/systemd/system/${CPA_ADMISSION_SERVICE}"
CPA_ADMISSION_ADDR="127.0.0.1:${CPA_PUBLIC_PORT}"
CPA_ADMISSION_ACTIVE="${CPA_ADMISSION_ACTIVE:-6}"
CPA_ADMISSION_BACKLOG="${CPA_ADMISSION_BACKLOG:-6}"
CPA_TRANSLATE_PORT=8318
CPA_GLOBAL_PORT=18319
CPA_TRANSLATE_ADDR="127.0.0.1:${CPA_TRANSLATE_PORT}"
CPA_GLOBAL_ADDR="127.0.0.1:${CPA_GLOBAL_PORT}"
CPA_TRANSLATE_SOCKET="cpa-translate-admission.socket"
CPA_TRANSLATE_SERVICE="cpa-translate-admission.service"
CPA_GLOBAL_SOCKET="cpa-global-admission.socket"
CPA_GLOBAL_SERVICE="cpa-global-admission.service"
CPA_TRANSLATE_DROPIN="/etc/systemd/system/${CPA_TRANSLATE_SERVICE}.d/20-resource-guard.conf"
CPA_GLOBAL_DROPIN="/etc/systemd/system/${CPA_GLOBAL_SERVICE}.d/20-resource-guard.conf"
ADMISSION_CONFIG="/etc/cpa-admission.conf"
ADMISSION_CADDY_FILE="${PUBLIC_STATUS_CADDY_DIR}/cpa-translate.caddy"
ADMISSION_LOCK="/run/lock/cpa-admission-config.lock"
ADMISSION_STATE_DIR="/var/lib/cpa-admission"
ADMISSION_LOCK_HELD=0
ADMISSION_CONFIG_VALID=1
ADMISSION_PROXY_LIMIT_OFFSET=""
DEFAULT_ACTIVE=12
DEFAULT_BACKLOG=16
TRANSLATE_ENABLED=false
TRANSLATE_DOMAIN=""
TRANSLATE_ACTIVE=18
TRANSLATE_BACKLOG=24
GLOBAL_ACTIVE=18
GLOBAL_BACKLOG=24
DEFAULT_BODY_LIMIT_MB=32
TRANSLATE_BODY_LIMIT_MB=8
ADMISSION_SCHEMA_VERSION=2
SCHEMA_VERSION=2
ADMISSION_TXN_DIR=""
ADMISSION_TXN_ARMED=0
ADMISSION_MENU_TMP=""
ADMISSION_STAGE_TMP=""
SELF_INSTALL_TXN_DIR=""
SELF_INSTALL_TXN_ARMED=0
SELF_INSTALL_BINARY_REPLACED=0
EXPORT_DIR="${CPA_DIR}/exports"
RETENTION_CONFIG="/etc/cpa-log-retention.conf"
RETENTION_SERVICE="/etc/systemd/system/cpa-log-retention.service"
RETENTION_TIMER="/etc/systemd/system/cpa-log-retention.timer"
INSTALL_PATH="/usr/local/bin/cpa"
DEPLOY_STATE="/etc/cpa-deploy.conf"
DEPLOY_CREDENTIALS_FILE="/etc/cpa-deploy-credentials.conf"
FAIL2BAN_JAIL_NAME="cpa-caddy"
FAIL2BAN_STATE="/etc/cpa-fail2ban.conf"
FAIL2BAN_FILTER_FILE="/etc/fail2ban/filter.d/cpa-caddy.conf"
FAIL2BAN_JAIL_FILE="/etc/fail2ban/jail.d/cpa-caddy.conf"
FAIL2BAN_DB_FILE="/etc/fail2ban/fail2ban.d/cpa-retention.conf"
CPA_RESOURCE_DROPIN_DIR="/etc/systemd/system/${CPA_SERVICE}.d"
CPA_RESOURCE_DROPIN="${CPA_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CPAMP_RESOURCE_DROPIN_DIR="/etc/systemd/system/${CPAMP_SERVICE}.d"
CPAMP_RESOURCE_DROPIN="${CPAMP_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CADDY_RESOURCE_DROPIN_DIR="/etc/systemd/system/caddy.service.d"
CADDY_RESOURCE_DROPIN="${CADDY_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CPA_ADMISSION_DROPIN_DIR="/etc/systemd/system/${CPA_ADMISSION_SERVICE}.d"
CPA_ADMISSION_DROPIN="${CPA_ADMISSION_DROPIN_DIR}/20-resource-guard.conf"
PUBLIC_STATUS_RESOURCE_DROPIN_DIR="/etc/systemd/system/${PUBLIC_STATUS_SERVICE}.d"
PUBLIC_STATUS_RESOURCE_DROPIN="${PUBLIC_STATUS_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
PUBLIC_STATUS_CN_RESOURCE_DROPIN_DIR="/etc/systemd/system/${PUBLIC_STATUS_CN_SERVICE}.d"
PUBLIC_STATUS_CN_RESOURCE_DROPIN="${PUBLIC_STATUS_CN_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
PUBLIC_STATUS_QUOTA_RESOURCE_DROPIN_DIR="/etc/systemd/system/${PUBLIC_STATUS_QUOTA_SERVICE}.d"
PUBLIC_STATUS_QUOTA_RESOURCE_DROPIN="${PUBLIC_STATUS_QUOTA_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CPAMP_MAINT_RESOURCE_DROPIN_DIR="/etc/systemd/system/${CPAMP_MAINT_SERVICE}.d"
CPAMP_MAINT_RESOURCE_DROPIN="${CPAMP_MAINT_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CPAMP_MAINT_MANUAL_RESOURCE_DROPIN_DIR="/etc/systemd/system/${CPAMP_MAINT_MANUAL_SERVICE}.d"
CPAMP_MAINT_MANUAL_RESOURCE_DROPIN="${CPAMP_MAINT_MANUAL_RESOURCE_DROPIN_DIR}/20-resource-guard.conf"
CPA_STACK_SLICE="cpa-stack.slice"
CPA_BACKGROUND_SLICE="cpa-stack-background.slice"
CPA_STACK_SLICE_FILE="/etc/systemd/system/${CPA_STACK_SLICE}"
CPA_BACKGROUND_SLICE_FILE="/etc/systemd/system/${CPA_BACKGROUND_SLICE}"
RESOURCE_GUARD_STATE_DIR="/var/lib/cpa-resource-guard"
RESOURCE_GUARD_PENDING_DIR="${RESOURCE_GUARD_STATE_DIR}/pending"
RESOURCE_GUARD_VERIFIED_DIR="${RESOURCE_GUARD_STATE_DIR}/verified"
RESOURCE_GUARD_VERIFIED_MANIFEST="${RESOURCE_GUARD_VERIFIED_DIR}/manifest"
RESOURCE_GUARD_BASELINE_DIR="${RESOURCE_GUARD_STATE_DIR}/baseline"
RESOURCE_GUARD_BASELINE_MANIFEST="${RESOURCE_GUARD_BASELINE_DIR}/manifest"
BACKGROUND_HEAVY_LOCK="/run/lock/cpa-heavy-background.lock"
RESOURCE_PROFILE="${CPA_RESOURCE_PROFILE:-}"
LOW_MEMORY_THRESHOLD_MIB="${CPA_LOW_MEMORY_THRESHOLD_MIB:-1536}"
BACKGROUND_MIN_AVAILABLE_MIB="${CPA_BACKGROUND_MIN_AVAILABLE_MIB:-192}"
UPDATE_TMP=""
EXPORT_TMP=""
DEPLOY_TMP=""
EXPORT_START=0
EXPORT_END=0
EXPORT_LABEL=""
EXPORT_SLUG=""
DEPLOY_DOMAIN=""
DEPLOY_CPA_API_KEY=""
DEPLOY_CPA_MGMT_KEY=""
DEPLOY_CPAMP_ADMIN_KEY=""
DEPLOY_CPA_CANDIDATE=""
DEPLOY_CPA_VERSION=""
DEPLOY_CPA_ASSET=""
DEPLOY_CPAMP_CANDIDATE=""
DEPLOY_CPAMP_VERSION=""
DEPLOY_CPAMP_ASSET=""
CPAMP_MAINT_RECOVERY_ARMED=0
CPAMP_MAINT_RECOVERY_OWNER_UNIT=""
CPAMP_MAINT_LOCK_FD=""
F2B_BANTIME=86400
F2B_FINDTIME=600
F2B_MAXRETRY=5
F2B_IGNOREIPS="127.0.0.1/8 ::1"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BOLD=''
    NC=''
fi

info()  { printf '%b[INFO]%b %s\n' "$GREEN" "$NC" "$*"; }
warn()  { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*" >&2; }
error() { printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*" >&2; }
die()   { error "$*"; exit 1; }

running_in_systemd_unit() {
    local unit

    [[ -n "${INVOCATION_ID:-}" && -r /proc/self/cgroup ]] || return 1
    for unit in "$@"; do
        grep -Fq -- "/${unit}" /proc/self/cgroup && return 0
    done
    return 1
}

require_systemd_unit_invocation() {
    local action="$1"
    shift

    running_in_systemd_unit "$@" || {
        error "${action} 只能由对应的受控 systemd 单元调用。"
        return 1
    }
}

cleanup_update_tmp() {
    case "${UPDATE_TMP:-}" in
        /tmp/cpa-update.*|/tmp/cpamp-update.*)
            [[ -d "$UPDATE_TMP" ]] && rm -rf -- "$UPDATE_TMP"
            ;;
    esac
    UPDATE_TMP=""
}

cleanup_export_tmp() {
    case "${EXPORT_TMP:-}" in
        /tmp/cpa-export.*)
            [[ -d "$EXPORT_TMP" ]] && rm -rf -- "$EXPORT_TMP"
            ;;
    esac
    EXPORT_TMP=""
}

backup_stamp() {
    printf '%s-%s\n' "$(date +%Y%m%d-%H%M%S-%N)" "$BASHPID"
}

restore_service_enablement() {
    local unit="$1" was_enabled="$2"

    if [[ "$was_enabled" == "1" ]]; then
        systemctl enable "$unit" >/dev/null 2>&1
    else
        systemctl disable "$unit" >/dev/null 2>&1 \
            || ! systemctl is-enabled --quiet "$unit" 2>/dev/null
    fi
}

ensure_data_backup_space() {
    local data_dir="$1" backup_dir="$2" label="$3"
    local data_kib available_kib reserve_kib=65536

    [[ -d "$data_dir" ]] || return 0
    data_kib=$(du -sk "$data_dir" 2>/dev/null | awk 'NR == 1 {print $1}' || true)
    available_kib=$(df -Pk "$backup_dir" 2>/dev/null | awk 'NR == 2 {print $4}' || true)
    if [[ "$data_kib" =~ ^[0-9]+$ && "$available_kib" =~ ^[0-9]+$ \
        && "$available_kib" -le $((data_kib + reserve_kib)) ]]; then
        die "${label} 数据备份空间不足：至少需要约 $((data_kib + reserve_kib)) KiB 可用空间。"
    fi
}

cleanup() {
    if [[ "${SELF_INSTALL_TXN_ARMED:-0}" == "1" ]]; then
        SELF_INSTALL_TXN_ARMED=0
        install_self_restore_transaction "$SELF_INSTALL_TXN_DIR" \
            "$SELF_INSTALL_BINARY_REPLACED" || true
    fi
    if [[ "${ADMISSION_TXN_ARMED:-0}" == "1" ]]; then
        ADMISSION_TXN_ARMED=0
        admission_restore_transaction "$ADMISSION_TXN_DIR" || true
    fi
    case "${ADMISSION_MENU_TMP:-}" in
        /tmp/cpa-admission-menu.*) rm -f -- "$ADMISSION_MENU_TMP" ;;
    esac
    case "${ADMISSION_STAGE_TMP:-}" in
        /tmp/cpa-admission-stage.*) rm -rf -- "$ADMISSION_STAGE_TMP" ;;
    esac
    if [[ "${CPAMP_MAINT_RECOVERY_ARMED:-0}" == "1" ]]; then
        cpamp_maintenance_recover_service >/dev/null 2>&1 || true
    fi
    cleanup_update_tmp
    cleanup_export_tmp
    if [[ -n "${DEPLOY_TMP:-}" && -d "$DEPLOY_TMP" ]]; then
        rm -rf -- "$DEPLOY_TMP"
    fi
}

trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

usage() {
    cat <<'EOF'
CPA 部署与运维工具

用法:
  cpa                 打开交互菜单
  cpa deploy          部署或重装 CPA/CPAMP/Caddy
  cpa status          查看当前工作状态
  cpa traffic         查看流量统计
  cpa export-logs     按时间范围导出脱敏请求日志
  cpa log-cleanup     管理日志保留与自动清理
  cpa fail2ban        管理黑名单、封禁条件和白名单
  cpa cpamp-maintenance  检查/安排/诊断 CPAMP 数据库离线维护
  cpa cpamp-maintenance --set-admin-key  保存维护检测专用 Admin Key
  cpa public-status    管理 CN+额外 IP 白名单的静态只读 Dashboard
  cpa resource-guard  查看或应用 CPA/CPAMP 内存与重启保护
  cpa admission      管理双入口准入、共享上限和预设档
  cpa admission --status  查看已保存与实际生效的准入配置
  cpa admission --apply   验证并应用 /etc/cpa-admission.conf
  cpa update [-y]     更新 CPA 和 CPAMP 到最新可用版本
  cpa install         将本脚本安装为 /usr/local/bin/cpa
  cpa version         显示脚本版本
  cpa help            显示帮助
EOF
}

become_root() {
    if (( EUID == 0 )); then
        return 0
    fi

    if command -v sudo >/dev/null 2>&1; then
        exec sudo -- /usr/bin/env bash "${BASH_SOURCE[0]}" "$@"
    fi

    die "此操作需要 root 权限，请先执行 sudo -i。"
}

require_deployment() {
    [[ -d "$CPA_DIR" ]] || die "未找到 ${CPA_DIR}，请先选择菜单 1 部署 CPA。"
    [[ -f "$CPA_BIN" ]] || die "未找到 ${CPA_BIN}，CPA 可能尚未正确安装。"
    command -v systemctl >/dev/null 2>&1 || die "未找到 systemctl。"
}

human_bytes() {
    local value="${1:-0}"
    [[ "$value" =~ ^[0-9]+$ ]] || value=0

    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$value" 2>/dev/null || printf '%sB\n' "$value"
    else
        awk -v bytes="$value" 'BEGIN {
            split("B KiB MiB GiB TiB PiB", units, " ")
            i = 1
            while (bytes >= 1024 && i < 6) { bytes /= 1024; i++ }
            if (i == 1) printf "%.0f%s\n", bytes, units[i]
            else printf "%.2f%s\n", bytes, units[i]
        }'
    fi
}

proc_meminfo_kib() {
    local key="$1"
    awk -v key="$key" '$1 == key ":" {print $2; exit}' /proc/meminfo 2>/dev/null
}

system_total_memory_mib() {
    local value
    value=$(proc_meminfo_kib MemTotal)
    [[ "$value" =~ ^[0-9]+$ ]] || value=0
    printf '%s\n' "$((value / 1024))"
}

system_available_memory_mib() {
    local value
    value=$(proc_meminfo_kib MemAvailable)
    [[ "$value" =~ ^[0-9]+$ ]] || value=0
    printf '%s\n' "$((value / 1024))"
}

system_swap_used_bytes() {
    local total free
    total=$(proc_meminfo_kib SwapTotal)
    free=$(proc_meminfo_kib SwapFree)
    [[ "$total" =~ ^[0-9]+$ ]] || total=0
    [[ "$free" =~ ^[0-9]+$ ]] || free=0
    (( free > total )) && free="$total"
    printf '%s\n' "$(((total - free) * 1024))"
}

low_memory_profile_enabled() {
    local total_mib threshold="$LOW_MEMORY_THRESHOLD_MIB"

    [[ "$threshold" =~ ^[0-9]+$ ]] || threshold=1536
    case "$RESOURCE_PROFILE" in
        low) return 0 ;;
        off) return 1 ;;
        auto|standard) ;;
        *) RESOURCE_PROFILE="auto" ;;
    esac
    [[ "$RESOURCE_PROFILE" == "standard" ]] && return 1
    total_mib=$(system_total_memory_mib)
    [[ "$total_mib" =~ ^[0-9]+$ && "$total_mib" -gt 0 && "$total_mib" -le "$threshold" ]]
}

initialize_resource_profile() {
    local saved=""

    if [[ -z "$RESOURCE_PROFILE" && -f "$DEPLOY_STATE" ]]; then
        saved=$(awk -F= '$1 == "RESOURCE_PROFILE" {print substr($0, length($1) + 2); exit}' \
            "$DEPLOY_STATE" 2>/dev/null || true)
    fi
    RESOURCE_PROFILE="${RESOURCE_PROFILE:-${saved:-auto}}"
    case "$RESOURCE_PROFILE" in
        auto|low|standard|off) ;;
        *)
            warn "未知资源档位 ${RESOURCE_PROFILE}，已回退到 auto。"
            RESOURCE_PROFILE="auto"
            ;;
    esac
}

resource_profile_name() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        printf 'off\n'
    elif low_memory_profile_enabled; then
        printf 'low-memory\n'
    else
        printf 'standard\n'
    fi
}

cpa_resource_directives() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
Slice=system.slice
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
OOMScoreAdjust=0
UnsetEnvironment=GOMEMLIMIT
EOF
        return 0
    fi
    if low_memory_profile_enabled; then
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=42%
MemoryMax=52%
MemorySwapMax=96M
Environment=GOMEMLIMIT=380MiB
OOMScoreAdjust=-200
EOF
    else
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=55%
MemoryMax=65%
MemorySwapMax=256M
Environment=GOMEMLIMIT=900MiB
OOMScoreAdjust=-100
EOF
    fi
}

cpamp_resource_directives() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
Slice=system.slice
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
OOMScoreAdjust=0
UnsetEnvironment=GOMEMLIMIT
EOF
        return 0
    fi
    if low_memory_profile_enabled; then
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=9%
MemoryMax=13%
MemorySwapMax=32M
Environment=GOMEMLIMIT=80MiB
OOMScoreAdjust=100
EOF
    else
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=14%
MemoryMax=20%
MemorySwapMax=64M
Environment=GOMEMLIMIT=220MiB
OOMScoreAdjust=100
EOF
    fi
}

background_resource_directives() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
Slice=system.slice
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
OOMScoreAdjust=0
CPUWeight=100
IOWeight=100
EOF
        return 0
    fi
    if low_memory_profile_enabled; then
        cat <<EOF
Slice=${CPA_BACKGROUND_SLICE}
MemoryAccounting=true
MemoryHigh=10%
MemoryMax=14%
MemorySwapMax=0
OOMScoreAdjust=500
CPUWeight=10
IOWeight=10
EOF
    else
        cat <<EOF
Slice=${CPA_BACKGROUND_SLICE}
MemoryAccounting=true
MemoryHigh=15%
MemoryMax=22%
MemorySwapMax=0
OOMScoreAdjust=400
CPUWeight=25
IOWeight=25
EOF
    fi
}

edge_resource_directives() {
    local service_kind="$1"
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
Slice=system.slice
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
OOMScoreAdjust=0
EOF
        return 0
    fi
    if [[ "$service_kind" == "admission" ]]; then
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=4%
MemoryMax=6%
MemorySwapMax=0
OOMScoreAdjust=150
EOF
    else
        cat <<EOF
Slice=${CPA_STACK_SLICE}
MemoryAccounting=true
MemoryHigh=7%
MemoryMax=10%
MemorySwapMax=16M
OOMScoreAdjust=100
EOF
    fi
}

stack_slice_directives() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
EOF
    elif low_memory_profile_enabled; then
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=60%
MemoryMax=68%
MemorySwapMax=96M
EOF
    else
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=72%
MemoryMax=82%
MemorySwapMax=256M
EOF
    fi
}

background_slice_directives() {
    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=infinity
MemoryMax=infinity
MemorySwapMax=infinity
CPUWeight=100
IOWeight=100
EOF
    elif low_memory_profile_enabled; then
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=10%
MemoryMax=14%
MemorySwapMax=0
CPUWeight=10
IOWeight=10
EOF
    else
        cat <<'EOF'
MemoryAccounting=true
MemoryHigh=15%
MemoryMax=22%
MemorySwapMax=0
CPUWeight=25
IOWeight=25
EOF
    fi
}

cpa_request_retry_count() {
    if low_memory_profile_enabled; then
        printf '1\n'
    else
        printf '2\n'
    fi
}

background_capacity_available() {
    local label="$1" required="${2:-$BACKGROUND_MIN_AVAILABLE_MIB}" available

    [[ "$required" =~ ^[0-9]+$ ]] || required=192
    low_memory_profile_enabled || return 0
    available=$(system_available_memory_mib)
    if [[ ! "$available" =~ ^[0-9]+$ || "$available" -le 0 ]]; then
        warn "${label} 已跳过：无法可靠读取 MemAvailable，按低内存处理。"
        return 1
    fi
    if [[ "$available" -lt "$required" ]]; then
        warn "${label} 已跳过：MemAvailable=${available}MiB，低于配置的后台退让阈值 ${required}MiB。"
        return 1
    fi
    return 0
}

human_systemd_bytes() {
    local value="${1:-}"
    if [[ -z "$value" || "$value" == "infinity" || "$value" == "18446744073709551615" ]]; then
        printf '无限制\n'
    else
        human_bytes "$value"
    fi
}

service_state() {
    local unit="$1"
    local load_state active_state sub_state

    load_state=$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)
    if [[ -z "$load_state" || "$load_state" == "not-found" ]]; then
        printf '%b未安装%b' "$YELLOW" "$NC"
        return 0
    fi

    active_state=$(systemctl is-active "$unit" 2>/dev/null || true)
    sub_state=$(systemctl show "$unit" -p SubState --value 2>/dev/null || true)
    if [[ "$active_state" == "active" ]]; then
        printf '%b运行中%b (%s)' "$GREEN" "$NC" "$sub_state"
    else
        printf '%b%s%b (%s)' "$RED" "${active_state:-unknown}" "$NC" "${sub_state:-unknown}"
    fi
}

current_version() {
    local version="" port

    if [[ -s "${CPA_DIR}/.version" ]]; then
        version=$(tr -d '[:space:]' < "${CPA_DIR}/.version")
    fi

    if [[ -z "$version" ]] && command -v curl >/dev/null 2>&1; then
        port=$(configured_cpa_port)
        version=$(curl -sS -D - -o /dev/null --max-time 3 \
            "http://127.0.0.1:${port}/v0/management/config" 2>/dev/null \
            | awk -F': *' 'tolower($1) == "x-cpa-version" { gsub(/\r/, "", $2); print $2; exit }')
    fi

    if [[ -z "$version" ]] && command -v journalctl >/dev/null 2>&1; then
        version=$(journalctl -u "$CPA_SERVICE" -n 500 --no-pager -o cat 2>/dev/null \
            | sed -n 's/.*CLIProxyAPI Version: \([^,[:space:]]*\).*/\1/p' \
            | tail -n 1)
    fi

    version="${version#v}"
    printf '%s\n' "${version:-未知}"
}

current_cpamp_version() {
    local version=""

    if [[ -s "${CPAMP_DIR}/.version" ]]; then
        version=$(tr -d '[:space:]' < "${CPAMP_DIR}/.version")
    fi
    version="${version#v}"
    printf '%s\n' "${version:-未知（首次由管理脚本接管）}"
}

show_status() {
    require_deployment

    local version cpamp_version pid memory memory_peak memory_high memory_max memory_swap_max
    local since health_code backend_code backend_port disk_usage f2b_jail_state total_mib available_mib swap_used restarts
    version=$(current_version)
    cpamp_version=$(current_cpamp_version)
    pid=$(systemctl show "$CPA_SERVICE" -p MainPID --value 2>/dev/null || true)
    memory=$(systemctl show "$CPA_SERVICE" -p MemoryCurrent --value 2>/dev/null || true)
    memory_peak=$(systemctl show "$CPA_SERVICE" -p MemoryPeak --value 2>/dev/null || true)
    memory_high=$(systemctl show "$CPA_SERVICE" -p MemoryHigh --value 2>/dev/null || true)
    memory_max=$(systemctl show "$CPA_SERVICE" -p MemoryMax --value 2>/dev/null || true)
    memory_swap_max=$(systemctl show "$CPA_SERVICE" -p MemorySwapMax --value 2>/dev/null || true)
    restarts=$(systemctl show "$CPA_SERVICE" -p NRestarts --value 2>/dev/null || true)
    since=$(systemctl show "$CPA_SERVICE" -p ActiveEnterTimestamp --value 2>/dev/null || true)
    health_code=$(curl -sS -o /dev/null --max-time 3 -w '%{http_code}' \
        "http://127.0.0.1:${CPA_PUBLIC_PORT}/v1/models" 2>/dev/null || true)
    backend_port=$(configured_cpa_port)
    backend_code=$(curl -sS -o /dev/null --max-time 3 -w '%{http_code}' \
        "http://127.0.0.1:${backend_port}/v1/models" 2>/dev/null || true)
    disk_usage=$(du -sh "$CPA_DIR" 2>/dev/null | awk '{print $1}')
    total_mib=$(system_total_memory_mib)
    available_mib=$(system_available_memory_mib)
    swap_used=$(system_swap_used_bytes)
    if command -v fail2ban-client >/dev/null 2>&1 \
        && fail2ban-client status "$FAIL2BAN_JAIL_NAME" >/dev/null 2>&1; then
        f2b_jail_state="已启用 (${FAIL2BAN_JAIL_NAME})"
    else
        f2b_jail_state="未启用"
    fi

    printf '\n%bCPA 当前工作状态%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  CPA 网关:       %b\n' "$(service_state "$CPA_SERVICE")"
    printf '  CPAMP 面板:     %b\n' "$(service_state 'cpamp.service')"
    printf '  准入网关:      %b\n' "$(service_state "$CPA_ADMISSION_SOCKET")"
    printf '  公网共享准入:  %b\n' "$(service_state "$CPA_GLOBAL_SOCKET")"
    printf '  高并发准入:    %b\n' "$(service_state "$CPA_TRANSLATE_SOCKET")"
    printf '  准入配置:      普通 %s / 高并发 %s / 共享 %s\n' \
        "$DEFAULT_ACTIVE" "$TRANSLATE_ACTIVE" "$GLOBAL_ACTIVE"
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        printf '  高并发 API:    https://%s/v1\n' "$TRANSLATE_DOMAIN"
    fi
    printf '  Caddy 反代:     %b\n' "$(service_state 'caddy.service')"
    printf '  Fail2Ban:       %b\n' "$(service_state 'fail2ban.service')"
    printf '  CPA Web 防护:   %s\n' "$f2b_jail_state"
    printf '  CPA 版本:       %s\n' "$version"
    printf '  CPAMP 版本:     %s\n' "$cpamp_version"
    printf '  CPA PID:        %s\n' "${pid:-未知}"
    printf '  CPA 内存:       %s\n' "$(human_bytes "$memory")"
    [[ "$memory_peak" =~ ^[0-9]+$ ]] \
        && printf '  CPA 峰值内存:   %s\n' "$(human_bytes "$memory_peak")"
    printf '  资源档位:      %s\n' "$(resource_profile_name)"
    printf '  CPA MemoryHigh: %s\n' "$(human_systemd_bytes "$memory_high")"
    printf '  CPA MemoryMax:  %s\n' "$(human_systemd_bytes "$memory_max")"
    printf '  CPA SwapMax:    %s\n' "$(human_systemd_bytes "$memory_swap_max")"
    printf '  CPA 重启次数:   %s\n' "${restarts:-0}"
    printf '  系统内存:      %s MiB 总量 / %s MiB 可用\n' "${total_mib:-0}" "${available_mib:-0}"
    printf '  已用 Swap:     %s\n' "$(human_bytes "$swap_used")"
    printf '  启动时间:       %s\n' "${since:-未知}"
    printf '  安装目录占用:   %s\n' "${disk_usage:-未知}"

    if [[ "$health_code" =~ ^(200|401|403)$ ]]; then
        printf '  准入端口检查:   %b正常%b (HTTP %s)\n' "$GREEN" "$NC" "$health_code"
    elif [[ -n "$health_code" && "$health_code" != "000" ]]; then
        printf '  准入端口检查:   %b异常响应%b (HTTP %s)\n' "$YELLOW" "$NC" "$health_code"
    else
        printf '  准入端口检查:   %b无法连接%b\n' "$RED" "$NC"
    fi
    if [[ "$backend_code" =~ ^(200|401|403)$ ]]; then
        printf '  CPA 后端检查:  %b正常%b (HTTP %s)\n' "$GREEN" "$NC" "$backend_code"
    else
        printf '  CPA 后端检查:  %b异常%b (HTTP %s)\n' "$RED" "$NC" "${backend_code:-000}"
    fi

    printf '%s\n' '--------------------------------------------------'
    printf '  最近日志:\n'
    journalctl -u "$CPA_SERVICE" -n 5 --no-pager -o short-iso 2>/dev/null \
        | sed 's/^/    /' || true
    printf '\n'
}

stream_caddy_logs() {
    local file

    while IFS= read -r -d '' file; do
        case "$file" in
            *.gz) gzip -cd -- "$file" 2>/dev/null || true ;;
            *)    cat -- "$file" 2>/dev/null || true ;;
        esac
    done < <(find "$CADDY_LOG_DIR" -maxdepth 1 -type f -name "$CADDY_LOG_PATTERN" -print0 2>/dev/null)
}

show_traffic() {
    require_deployment

    local today_start stats row
    local today_requests today_2xx today_4xx today_5xx today_in today_out
    local all_requests all_2xx all_4xx all_5xx all_in all_out

    today_start=$(date -d 'today 00:00:00' +%s 2>/dev/null || date +%s)

    if [[ -d "$CADDY_LOG_DIR" ]] && command -v jq >/dev/null 2>&1; then
        stats=$(stream_caddy_logs | jq -Rn --argjson start "$today_start" '
            reduce (
                inputs
                | fromjson?
                | select(type == "object")
            ) as $r (
                {
                    today: {requests: 0, ok: 0, c4xx: 0, c5xx: 0, input: 0, output: 0},
                    all:   {requests: 0, ok: 0, c4xx: 0, c5xx: 0, input: 0, output: 0}
                };
                ($r.status // 0) as $status
                | ($r.bytes_read // 0) as $input
                | ($r.size // 0) as $output
                | .all.requests += 1
                | .all.input += $input
                | .all.output += $output
                | if ($status >= 200 and $status < 300) then .all.ok += 1 else . end
                | if ($status >= 400 and $status < 500) then .all.c4xx += 1 else . end
                | if ($status >= 500 and $status < 600) then .all.c5xx += 1 else . end
                | if (($r.ts // 0) >= $start) then
                    .today.requests += 1
                    | .today.input += $input
                    | .today.output += $output
                    | if ($status >= 200 and $status < 300) then .today.ok += 1 else . end
                    | if ($status >= 400 and $status < 500) then .today.c4xx += 1 else . end
                    | if ($status >= 500 and $status < 600) then .today.c5xx += 1 else . end
                  else . end
            )
        ' 2>/dev/null || true)
    else
        stats=""
    fi

    if [[ -n "$stats" ]]; then
        row=$(jq -r '[
            .today.requests, .today.ok, .today.c4xx, .today.c5xx, .today.input, .today.output,
            .all.requests, .all.ok, .all.c4xx, .all.c5xx, .all.input, .all.output
        ] | @tsv' <<< "$stats" 2>/dev/null || true)
        IFS=$'\t' read -r \
            today_requests today_2xx today_4xx today_5xx today_in today_out \
            all_requests all_2xx all_4xx all_5xx all_in all_out <<< "$row"
    else
        today_requests=0; today_2xx=0; today_4xx=0; today_5xx=0; today_in=0; today_out=0
        all_requests=0; all_2xx=0; all_4xx=0; all_5xx=0; all_in=0; all_out=0
    fi

    printf '\n%bCPA 流量统计%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  统计口径: 仅 CPA 的 Caddy API 请求日志\n'
    printf '  隔离说明: 不读取总网卡，不操作防火墙或 sing-box 统计规则\n'
    printf '\n'
    printf '  API 请求（今天，本机时区）\n'
    printf '    总请求:       %s\n' "${today_requests:-0}"
    printf '    2xx 成功:     %s\n' "${today_2xx:-0}"
    printf '    4xx 错误:     %s\n' "${today_4xx:-0}"
    printf '    5xx 错误:     %s\n' "${today_5xx:-0}"
    printf '    请求体流量:   %s\n' "$(human_bytes "${today_in:-0}")"
    printf '    响应体流量:   %s\n' "$(human_bytes "${today_out:-0}")"
    printf '\n'
    printf '  API 请求（Caddy 当前保留的全部日志）\n'
    printf '    总请求:       %s\n' "${all_requests:-0}"
    printf '    2xx/4xx/5xx:  %s / %s / %s\n' \
        "${all_2xx:-0}" "${all_4xx:-0}" "${all_5xx:-0}"
    printf '    请求体流量:   %s\n' "$(human_bytes "${all_in:-0}")"
    printf '    响应体流量:   %s\n' "$(human_bytes "${all_out:-0}")"
    printf '%s\n' '--------------------------------------------------'

    if [[ ! -d "$CADDY_LOG_DIR" ]]; then
        warn "未找到 ${CADDY_LOG_DIR}，API 请求统计显示为 0。"
    elif ! command -v jq >/dev/null 2>&1; then
        warn "未安装 jq，API 请求统计显示为 0。"
    fi
    printf '\n'
}

format_local_time() {
    date -d "@${1}" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || printf '%s\n' "$1"
}

select_export_range() {
    local choice="" now start_input="" end_input="" custom_start="" custom_end=""

    now=$(date +%s)
    while true; do
        printf '\n%b选择日志时间范围%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 近 1 小时\n'
        printf '  2. 近 24 小时\n'
        printf '  3. 今天（服务器本机时区）\n'
        printf '  4. 近 7 天\n'
        printf '  5. 近 30 天\n'
        printf '  6. 当前保留的全部日志\n'
        printf '  7. 自定义时间段\n'
        printf '  0. 返回\n'
        printf '%s\n' '--------------------------------------------------'

        if ! read -r -p '请输入选项 [0-7]: ' choice; then
            return 1
        fi

        case "$choice" in
            1)
                EXPORT_START=$((now - 3600))
                EXPORT_END=$now
                EXPORT_LABEL="近 1 小时"
                EXPORT_SLUG="last-1h"
                ;;
            2)
                EXPORT_START=$((now - 86400))
                EXPORT_END=$now
                EXPORT_LABEL="近 24 小时"
                EXPORT_SLUG="last-24h"
                ;;
            3)
                EXPORT_START=$(date -d 'today 00:00:00' +%s 2>/dev/null || true)
                EXPORT_END=$now
                EXPORT_LABEL="今天"
                EXPORT_SLUG="today"
                ;;
            4)
                EXPORT_START=$((now - 604800))
                EXPORT_END=$now
                EXPORT_LABEL="近 7 天"
                EXPORT_SLUG="last-7d"
                ;;
            5)
                EXPORT_START=$((now - 2592000))
                EXPORT_END=$now
                EXPORT_LABEL="近 30 天"
                EXPORT_SLUG="last-30d"
                ;;
            6)
                EXPORT_START=0
                EXPORT_END=$now
                EXPORT_LABEL="当前保留的全部日志"
                EXPORT_SLUG="all-retained"
                ;;
            7)
                printf '\n时间格式示例: 2026-08-01 00:00:00\n'
                read -r -p '开始时间: ' start_input || return 1
                read -r -p '结束时间（直接回车表示现在）: ' end_input || return 1
                if [[ -z "$start_input" ]]; then
                    warn "开始时间不能为空，请重新选择。"
                    continue
                fi
                custom_start=$(date -d "$start_input" +%s 2>/dev/null || true)
                if [[ -z "$end_input" ]]; then
                    custom_end=$now
                else
                    custom_end=$(date -d "$end_input" +%s 2>/dev/null || true)
                fi
                if [[ ! "$custom_start" =~ ^[0-9]+$ || ! "$custom_end" =~ ^[0-9]+$ ]]; then
                    warn "时间格式无法识别，请重新选择。"
                    continue
                fi
                EXPORT_START=$custom_start
                EXPORT_END=$custom_end
                EXPORT_LABEL="自定义时间段"
                EXPORT_SLUG="custom"
                ;;
            0|q|Q)
                return 1
                ;;
            *)
                warn "无效选项，请重新输入。"
                continue
                ;;
        esac

        if [[ ! "$EXPORT_START" =~ ^[0-9]+$ || ! "$EXPORT_END" =~ ^[0-9]+$ ]]; then
            warn "无法计算时间范围，请重新选择。"
            continue
        fi
        if (( EXPORT_START > EXPORT_END )); then
            warn "开始时间不能晚于结束时间，请重新选择。"
            continue
        fi
        return 0
    done
}

write_export_summary() {
    local jsonl="$1"
    local summary_json="$2"
    local summary_text="$3"
    local requested_start requested_end

    if (( EXPORT_START == 0 )); then
        requested_start="现存最早记录"
    else
        requested_start=$(format_local_time "$EXPORT_START")
    fi
    requested_end=$(format_local_time "$EXPORT_END")

    jq -n \
        --arg generated_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --arg range_label "$EXPORT_LABEL" \
        --arg requested_start "$requested_start" \
        --arg requested_end "$requested_end" \
        --argjson start "$EXPORT_START" \
        --argjson end "$EXPORT_END" '
        reduce inputs as $r (
            {
                metadata: {
                    generated_at_utc: $generated_at,
                    range: $range_label,
                    requested_start_local: $requested_start,
                    requested_end_local: $requested_end,
                    requested_start_unix: $start,
                    requested_end_unix: $end,
                    source: "Caddy retained access logs",
                    privacy: "Sensitive headers, cookies, Authorization and URI query strings are excluded; User-Agent is retained"
                },
                totals: {
                    requests: 0,
                    success_2xx: 0,
                    redirects_3xx: 0,
                    client_errors_4xx: 0,
                    server_errors_5xx: 0,
                    request_bytes: 0,
                    response_bytes: 0
                },
                actual_first_unix: null,
                actual_last_unix: null,
                status_codes: {},
                methods: {},
                paths: {},
                clients: {}
            };
            ($r.status | tostring) as $status_key
            | ($r.method // "UNKNOWN") as $method
            | ($r.path // "") as $path
            | ($r.client_ip // "") as $client
            | .totals.requests += 1
            | .totals.request_bytes += ($r.request_bytes // 0)
            | .totals.response_bytes += ($r.response_bytes // 0)
            | if ($r.status >= 200 and $r.status < 300) then .totals.success_2xx += 1 else . end
            | if ($r.status >= 300 and $r.status < 400) then .totals.redirects_3xx += 1 else . end
            | if ($r.status >= 400 and $r.status < 500) then .totals.client_errors_4xx += 1 else . end
            | if ($r.status >= 500 and $r.status < 600) then .totals.server_errors_5xx += 1 else . end
            | .actual_first_unix = if .actual_first_unix == null or $r.timestamp_unix < .actual_first_unix then $r.timestamp_unix else .actual_first_unix end
            | .actual_last_unix = if .actual_last_unix == null or $r.timestamp_unix > .actual_last_unix then $r.timestamp_unix else .actual_last_unix end
            | .status_codes[$status_key] = ((.status_codes[$status_key] // 0) + 1)
            | .methods[$method] = ((.methods[$method] // 0) + 1)
            | .paths[$path] = ((.paths[$path] // 0) + 1)
            | if $client != "" then .clients[$client] = ((.clients[$client] // 0) + 1) else . end
        )
        | .status_codes = (.status_codes | to_entries | sort_by(.key | tonumber))
        | .methods = (.methods | to_entries | sort_by(-.value, .key))
        | .top_paths = (.paths | to_entries | sort_by(-.value, .key) | .[:100])
        | .top_clients = (.clients | to_entries | sort_by(-.value, .key) | .[:100])
        | .actual_first_utc = if .actual_first_unix == null then null else ((.actual_first_unix | floor) | todateiso8601) end
        | .actual_last_utc = if .actual_last_unix == null then null else ((.actual_last_unix | floor) | todateiso8601) end
        | del(.paths, .clients)
    ' "$jsonl" > "$summary_json"

    jq -r '
        [
            "CPA 请求日志导出摘要",
            "====================",
            "生成时间 (UTC): " + .metadata.generated_at_utc,
            "选择范围: " + .metadata.range,
            "开始时间: " + .metadata.requested_start_local,
            "结束时间: " + .metadata.requested_end_local,
            "",
            "总请求数: " + (.totals.requests | tostring),
            "2xx 成功: " + (.totals.success_2xx | tostring),
            "3xx 重定向: " + (.totals.redirects_3xx | tostring),
            "4xx 客户端错误: " + (.totals.client_errors_4xx | tostring),
            "5xx 服务端错误: " + (.totals.server_errors_5xx | tostring),
            "请求体字节: " + (.totals.request_bytes | tostring),
            "响应体字节: " + (.totals.response_bytes | tostring),
            "",
            "说明:",
            "- 数据来自 Caddy 当前保留的访问日志，超出日志保留期的数据无法恢复。",
            "- 除 User-Agent 外，已移除请求头、Cookie、Authorization 和 URI 查询参数。",
            "- 这不是匿名数据：仍含客户端 IP、Host、路径和 User-Agent；请勿直接公开。",
            "- requests.jsonl 和 requests.csv 按请求时间升序排列。",
            "- summary.json 包含状态码、方法、热门路径和客户端 IP 汇总。"
        ] | join("\n")
    ' "$summary_json" > "$summary_text"
}

export_request_logs() {
    local staged package_dir jsonl csv summary_json summary_text
    local archive archive_tmp timestamp count checksum actual_first actual_last

    require_deployment
    command -v jq >/dev/null 2>&1 || die "未安装 jq。"
    command -v tar >/dev/null 2>&1 || die "未安装 tar。"
    command -v sort >/dev/null 2>&1 || die "未安装 sort。"
    [[ -d "$CADDY_LOG_DIR" ]] || die "未找到 Caddy 日志目录 ${CADDY_LOG_DIR}。"

    if ! select_export_range; then
        warn "已取消日志导出。"
        return 0
    fi
    warn "导出仅去除认证头和查询参数，仍含客户端 IP、域名、路径和 User-Agent；请勿直接公开。"

    printf '\n  选择范围: %s\n' "$EXPORT_LABEL"
    if (( EXPORT_START == 0 )); then
        printf '  开始时间: 现存最早记录\n'
    else
        printf '  开始时间: %s\n' "$(format_local_time "$EXPORT_START")"
    fi
    printf '  结束时间: %s\n\n' "$(format_local_time "$EXPORT_END")"

    install -d -m 0700 -o root -g root "$EXPORT_DIR" \
        || die "无法创建导出目录 ${EXPORT_DIR}。"
    EXPORT_TMP=$(mktemp -d /tmp/cpa-export.XXXXXX) || die "无法创建导出临时目录。"
    package_dir="${EXPORT_TMP}/package"
    mkdir -p "$package_dir"
    staged="${EXPORT_TMP}/requests.tsv"
    jsonl="${package_dir}/requests.jsonl"
    csv="${package_dir}/requests.csv"
    summary_json="${package_dir}/summary.json"
    summary_text="${package_dir}/summary.txt"

    info "正在读取并脱敏 Caddy 请求日志..."
    if ! stream_caddy_logs | jq -Rr \
        --argjson start "$EXPORT_START" \
        --argjson end "$EXPORT_END" '
        fromjson? as $r
        | ($r.ts // 0) as $ts
        | select($ts >= $start and $ts <= $end)
        | {
            timestamp_unix: $ts,
            timestamp_utc: (($ts | floor) | todateiso8601),
            client_ip: ($r.request.client_ip // $r.request.remote_ip // ""),
            method: ($r.request.method // ""),
            host: ($r.request.host // ""),
            path: (($r.request.uri // "") | split("?")[0]),
            protocol: ($r.request.proto // ""),
            status: ($r.status // 0),
            duration_ms: (($r.duration // 0) * 1000),
            request_bytes: ($r.bytes_read // 0),
            response_bytes: ($r.size // 0),
            user_agent: ($r.request.headers["User-Agent"][0] // "")
        }
        | (.timestamp_unix | tostring) + "\t" + tojson
    ' > "$staged"; then
        die "读取 Caddy 日志失败。"
    fi

    LC_ALL=C sort -n -k1,1 "$staged" | cut -f2- > "$jsonl"
    count=$(wc -l < "$jsonl" | tr -d '[:space:]')

    jq -nr '[
        "timestamp_utc", "timestamp_unix", "client_ip", "method", "host", "path",
        "protocol", "status", "duration_ms", "request_bytes", "response_bytes", "user_agent"
    ] | @csv' > "$csv"
    if [[ -s "$jsonl" ]]; then
        jq -r '[
            .timestamp_utc, .timestamp_unix, .client_ip, .method, .host, .path,
            .protocol, .status, .duration_ms, .request_bytes, .response_bytes, .user_agent
        ] | @csv' "$jsonl" >> "$csv"
    fi

    write_export_summary "$jsonl" "$summary_json" "$summary_text" \
        || die "生成日志摘要失败。"
    actual_first=$(jq -r '.actual_first_unix // empty' "$summary_json")
    actual_last=$(jq -r '.actual_last_unix // empty' "$summary_json")

    timestamp=$(backup_stamp)
    archive="${EXPORT_DIR}/cpa-request-logs-${timestamp}-${EXPORT_SLUG}.tar.gz"
    archive_tmp="${archive}.tmp"
    if ! tar -czf "$archive_tmp" -C "$package_dir" \
        requests.jsonl requests.csv summary.json summary.txt \
        || ! chown root:root "$archive_tmp" \
        || ! chmod 0600 "$archive_tmp" \
        || ! mv -f "$archive_tmp" "$archive"; then
        rm -f "$archive_tmp"
        die "打包或保存日志失败。"
    fi
    checksum=$(sha256sum "$archive" 2>/dev/null | awk '{print $1}' || true)

    printf '\n%b日志导出完成%b\n' "$GREEN" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  匹配请求数: %s\n' "$count"
    printf '  压缩包:     %s\n' "$archive"
    printf '  SFTP 目录:  %s\n' "$EXPORT_DIR"
    [[ -n "$checksum" ]] && printf '  SHA-256:    %s\n' "$checksum"
    if [[ -n "$actual_first" && -n "$actual_last" ]]; then
        printf '  实际首条:   %s\n' "$(format_local_time "${actual_first%.*}")"
        printf '  实际末条:   %s\n' "$(format_local_time "${actual_last%.*}")"
    fi
    printf '%s\n' '--------------------------------------------------'
    printf '请使用 root 账号通过 SFTP 进入上述目录下载。\n\n'

    if [[ "$count" == "0" ]]; then
        warn "所选时间范围没有匹配记录；压缩包仍已生成。"
    elif (( EXPORT_START > 0 )) && [[ "$actual_first" =~ ^[0-9]+([.][0-9]+)?$ ]] \
        && (( ${actual_first%.*} > EXPORT_START + 60 )); then
        warn "最早匹配记录晚于所选起点；此前可能没有请求，或旧日志已被 Caddy 轮转。"
    fi
    cleanup_export_tmp
}

directory_size_bytes() {
    local dir="$1" value=0

    if [[ -d "$dir" ]]; then
        value=$(du -sb "$dir" 2>/dev/null | awk 'NR == 1 {print $1}' || true)
        if [[ ! "$value" =~ ^[0-9]+$ ]]; then
            value=$(du -sk "$dir" 2>/dev/null | awk 'NR == 1 {print $1 * 1024}' || true)
        fi
    fi
    [[ "$value" =~ ^[0-9]+$ ]] || value=0
    printf '%s\n' "$value"
}

caddy_log_size_bytes() {
    if [[ -d "$CADDY_LOG_DIR" ]]; then
        find "$CADDY_LOG_DIR" -maxdepth 1 -type f -name "$CADDY_LOG_PATTERN" \
            -printf '%s\n' 2>/dev/null | awk '{sum += $1} END {printf "%.0f\n", sum + 0}'
    else
        printf '0\n'
    fi
}

export_archive_size_bytes() {
    if [[ -d "$EXPORT_DIR" ]]; then
        find "$EXPORT_DIR" -maxdepth 1 -type f -name 'cpa-request-logs-*.tar.gz' \
            -printf '%s\n' 2>/dev/null | awk '{sum += $1} END {printf "%.0f\n", sum + 0}'
    else
        printf '0\n'
    fi
}

managed_log_size_bytes() {
    local caddy_size cpa_size export_size

    caddy_size=$(caddy_log_size_bytes)
    cpa_size=$(directory_size_bytes "${CPA_DIR}/logs")
    export_size=$(export_archive_size_bytes)
    printf '%s\n' "$((caddy_size + cpa_size + export_size))"
}

managed_log_file_count() {
    local count=0 value

    if [[ -d "$CADDY_LOG_DIR" ]]; then
        value=$(find "$CADDY_LOG_DIR" -maxdepth 1 -type f -name "$CADDY_LOG_PATTERN" \
            -printf '.' 2>/dev/null | wc -c | tr -d '[:space:]')
        count=$((count + ${value:-0}))
    fi
    if [[ -d "${CPA_DIR}/logs" ]]; then
        value=$(find "${CPA_DIR}/logs" -type f -printf '.' 2>/dev/null \
            | wc -c | tr -d '[:space:]')
        count=$((count + ${value:-0}))
    fi
    if [[ -d "$EXPORT_DIR" ]]; then
        value=$(find "$EXPORT_DIR" -maxdepth 1 -type f -name 'cpa-request-logs-*.tar.gz' \
            -printf '.' 2>/dev/null | wc -c | tr -d '[:space:]')
        count=$((count + ${value:-0}))
    fi
    printf '%s\n' "$count"
}

filesystem_available_bytes() {
    local value
    value=$(df -B1 --output=avail "$CPA_DIR" 2>/dev/null | awk 'NR == 2 {print $1}' || true)
    [[ "$value" =~ ^[0-9]+$ ]] || value=0
    printf '%s\n' "$value"
}

read_retention_days() {
    local days=""

    if [[ -s "$RETENTION_CONFIG" ]]; then
        days=$(awk -F= '$1 == "RETENTION_DAYS" {print $2; exit}' "$RETENTION_CONFIG" \
            | tr -d '[:space:]')
    fi
    if [[ "$days" =~ ^[0-9]+$ ]] && (( days >= 7 && days <= 3650 )); then
        printf '%s\n' "$days"
    fi
}

show_log_storage() {
    local caddy_size cpa_size export_size total_size
    local fs_total fs_used fs_available fs_percent retention_days timer_active timer_enabled

    caddy_size=$(caddy_log_size_bytes)
    cpa_size=$(directory_size_bytes "${CPA_DIR}/logs")
    export_size=$(export_archive_size_bytes)
    total_size=$((caddy_size + cpa_size + export_size))
    read -r fs_total fs_used fs_available fs_percent <<< "$(
        df -B1 --output=size,used,avail,pcent "$CPA_DIR" 2>/dev/null \
            | awk 'NR == 2 {print $1, $2, $3, $4}'
    )"
    retention_days=$(read_retention_days)
    timer_active=$(systemctl is-active 'cpa-log-retention.timer' 2>/dev/null || true)
    timer_enabled=$(systemctl is-enabled 'cpa-log-retention.timer' 2>/dev/null || true)

    printf '\n%bCPA 日志存储状态%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  文件系统总容量:     %s\n' "$(human_bytes "${fs_total:-0}")"
    printf '  文件系统已使用:     %s (%s)\n' \
        "$(human_bytes "${fs_used:-0}")" "${fs_percent:-未知}"
    printf '  文件系统可用:       %s\n' "$(human_bytes "${fs_available:-0}")"
    printf '\n'
    printf '  Caddy 请求日志:     %s  (%s)\n' \
        "$(human_bytes "$caddy_size")" "$CADDY_LOG_DIR"
    printf '  CPA 程序日志:       %s  (%s)\n' \
        "$(human_bytes "$cpa_size")" "${CPA_DIR}/logs"
    printf '  请求日志导出包:     %s  (%s)\n' \
        "$(human_bytes "$export_size")" "$EXPORT_DIR"
    printf '  上述三类合计:       %s\n' "$(human_bytes "$total_size")"
    printf '\n'
    if [[ -n "$retention_days" && "$timer_active" == "active" ]]; then
        printf '  自动清理策略:       %b已启用%b，保留 %s 天\n' \
            "$GREEN" "$NC" "$retention_days"
        printf '  systemd timer:      %s / %s\n' "$timer_enabled" "$timer_active"
    elif [[ -n "$retention_days" ]]; then
        printf '  自动清理策略:       %b配置为 %s 天，但 timer 未运行%b\n' \
            "$YELLOW" "$retention_days" "$NC"
    else
        printf '  自动清理策略:       %b未启用%b\n' "$YELLOW" "$NC"
    fi
    printf '%s\n' '--------------------------------------------------'
    printf '  说明: 保留天数是最长清理期限；Caddy/CPA 自身的大小轮转可能更早删除旧日志。\n'
}

prune_log_storage() {
    local days="$1" minutes before_size after_size before_count after_count
    local before_free after_free freed deleted errors=0

    [[ "$days" =~ ^[0-9]+$ ]] || die "日志保留天数必须是整数。"
    (( days >= 7 && days <= 3650 )) || die "日志保留天数必须在 7 到 3650 之间。"
    minutes=$((days * 1440))
    before_size=$(managed_log_size_bytes)
    before_count=$(managed_log_file_count)
    before_free=$(filesystem_available_bytes)

    # Never remove the active Caddy or CPA log file. Only rotated/history files
    # and completed export archives are eligible for age-based deletion.
    if [[ -d "$CADDY_LOG_DIR" ]]; then
        find "$CADDY_LOG_DIR" -maxdepth 1 -type f -name "$CADDY_LOG_PATTERN" \
            ! -name 'access.log' -mmin "+${minutes}" -delete 2>/dev/null || errors=1
    fi
    if [[ -d "${CPA_DIR}/logs" ]]; then
        find "${CPA_DIR}/logs" -type f ! -name 'main.log' \
            -mmin "+${minutes}" -delete 2>/dev/null || errors=1
        find "${CPA_DIR}/logs" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    fi
    if [[ -d "$EXPORT_DIR" ]]; then
        find "$EXPORT_DIR" -maxdepth 1 -type f -name 'cpa-request-logs-*.tar.gz' \
            -mmin "+${minutes}" -delete 2>/dev/null || errors=1
    fi

    after_size=$(managed_log_size_bytes)
    after_count=$(managed_log_file_count)
    after_free=$(filesystem_available_bytes)
    if (( before_size >= after_size )); then freed=$((before_size - after_size)); else freed=0; fi
    if (( before_count >= after_count )); then deleted=$((before_count - after_count)); else deleted=0; fi

    printf '\n%bCPA 日志清理结果%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  保留时长:       %s 天\n' "$days"
    printf '  删除文件:       %s 个\n' "$deleted"
    printf '  清理前占用:     %s\n' "$(human_bytes "$before_size")"
    printf '  清理后占用:     %s\n' "$(human_bytes "$after_size")"
    printf '  释放空间:       %s\n' "$(human_bytes "$freed")"
    printf '  清理前磁盘可用: %s\n' "$(human_bytes "$before_free")"
    printf '  清理后磁盘可用: %s\n' "$(human_bytes "$after_free")"
    printf '%s\n' '--------------------------------------------------'

    if (( errors != 0 )); then
        warn "部分日志无法删除，请检查 systemd 日志中的权限错误。"
        return 1
    fi
    return 0
}

install_retention_policy() {
    local days="$1" installed_version old_umask stage_config stage_service stage_timer
    local config_old=0 service_old=0 timer_old=0 was_active=0 was_enabled=0
    local apply_ok=1 rollback_ok=1

    installed_version=$("$INSTALL_PATH" --version 2>/dev/null || true)
    if [[ "$installed_version" != "cpa management script v${SCRIPT_VERSION}" ]]; then
        die "请先用当前脚本执行 install，确保 ${INSTALL_PATH} 已更新到 v${SCRIPT_VERSION}。"
    fi

    ensure_deploy_tmp
    stage_config="${DEPLOY_TMP}/cpa-log-retention.conf"
    stage_service="${DEPLOY_TMP}/cpa-log-retention.service"
    stage_timer="${DEPLOY_TMP}/cpa-log-retention.timer"
    old_umask=$(umask)
    umask 077
    if ! cat > "$stage_config" <<EOF
RETENTION_DAYS=${days}
UPDATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
EOF
    then
        umask "$old_umask"
        die "写入日志保留配置失败。"
    fi
    umask "$old_umask"

    if ! cat > "$stage_service" <<EOF
[Unit]
Description=Prune old CPA request and application logs
After=cpa.service caddy.service

[Service]
Type=oneshot
ExecStart=${INSTALL_PATH} prune-logs --scheduled
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=-${CADDY_LOG_DIR} -${CPA_DIR}/logs -${EXPORT_DIR}
EOF
    then
        die "写入日志清理 service 失败。"
    fi

    if ! cat > "$stage_timer" <<'EOF'
[Unit]
Description=Daily CPA log retention cleanup

[Timer]
OnCalendar=*-*-* 03:27:00
AccuracySec=5min
RandomizedDelaySec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF
    then
        die "写入日志清理 timer 失败。"
    fi

    if [[ -f "$RETENTION_CONFIG" ]]; then
        config_old=1
        cp -a "$RETENTION_CONFIG" "${DEPLOY_TMP}/retention.conf.original" \
            || die "备份原日志保留配置失败。"
    fi
    if [[ -f "$RETENTION_SERVICE" ]]; then
        service_old=1
        cp -a "$RETENTION_SERVICE" "${DEPLOY_TMP}/retention.service.original" \
            || die "备份原日志清理 service 失败。"
    fi
    if [[ -f "$RETENTION_TIMER" ]]; then
        timer_old=1
        cp -a "$RETENTION_TIMER" "${DEPLOY_TMP}/retention.timer.original" \
            || die "备份原日志清理 timer 失败。"
    fi
    systemctl is-active --quiet 'cpa-log-retention.timer' && was_active=1
    systemctl is-enabled --quiet 'cpa-log-retention.timer' 2>/dev/null && was_enabled=1

    install -m 0600 -o root -g root "$stage_config" "$RETENTION_CONFIG" || apply_ok=0
    install -m 0644 -o root -g root "$stage_service" "$RETENTION_SERVICE" || apply_ok=0
    install -m 0644 -o root -g root "$stage_timer" "$RETENTION_TIMER" || apply_ok=0
    if [[ "$apply_ok" == "1" ]]; then
        systemctl daemon-reload || apply_ok=0
        systemctl enable --now 'cpa-log-retention.timer' || apply_ok=0
    fi
    if [[ "$apply_ok" != "1" ]]; then
        error "自动清理策略未能生效，正在恢复原配置..."
        if [[ "$config_old" == "1" ]]; then
            cp -a "${DEPLOY_TMP}/retention.conf.original" "$RETENTION_CONFIG" || rollback_ok=0
        else
            rm -f "$RETENTION_CONFIG" || rollback_ok=0
        fi
        if [[ "$service_old" == "1" ]]; then
            cp -a "${DEPLOY_TMP}/retention.service.original" "$RETENTION_SERVICE" || rollback_ok=0
        else
            rm -f "$RETENTION_SERVICE" || rollback_ok=0
        fi
        if [[ "$timer_old" == "1" ]]; then
            cp -a "${DEPLOY_TMP}/retention.timer.original" "$RETENTION_TIMER" || rollback_ok=0
        else
            rm -f "$RETENTION_TIMER" || rollback_ok=0
        fi
        systemctl daemon-reload || rollback_ok=0
        restore_service_enablement 'cpa-log-retention.timer' "$was_enabled" || rollback_ok=0
        if [[ "$was_active" == "1" ]]; then
            systemctl start 'cpa-log-retention.timer' || rollback_ok=0
        else
            if ! systemctl stop 'cpa-log-retention.timer' >/dev/null 2>&1 \
                && systemctl is-active --quiet 'cpa-log-retention.timer'; then
                rollback_ok=0
            fi
        fi
        [[ "$rollback_ok" == "1" ]] || error "日志清理策略回滚不完整，请检查 systemd 配置。"
        return 1
    fi
    info "已启用自动清理：每天清除 ${days} 天以前的 CPA 历史日志。"
}

disable_retention_policy() {
    local errors=0

    systemctl disable --now 'cpa-log-retention.timer' >/dev/null 2>&1 || true
    systemctl is-active --quiet 'cpa-log-retention.timer' && errors=1
    rm -f "$RETENTION_SERVICE" "$RETENTION_TIMER" "$RETENTION_CONFIG" || errors=1
    systemctl daemon-reload || errors=1
    systemctl reset-failed 'cpa-log-retention.service' >/dev/null 2>&1 || true
    if [[ "$errors" != "0" ]]; then
        error "关闭自动清理不完整，请检查 systemd 单元和文件权限。"
        return 1
    fi
    info "已关闭 CPA 日志自动清理；现有日志没有被删除。"
}

run_scheduled_log_cleanup() {
    local days
    days=$(read_retention_days)
    [[ -n "$days" ]] || die "未找到有效的日志保留策略。"
    prune_log_storage "$days"
}

log_cleanup_menu() {
    local choice="" days="" custom_days=""

    require_deployment
    show_log_storage
    while true; do
        printf '\n%b日志保留与自动清理%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 自动清除 30 天以前的日志\n'
        printf '  2. 自动清除 90 天以前的日志\n'
        printf '  3. 自动清除 180 天以前的日志\n'
        printf '  4. 自动清除 365 天以前的日志\n'
        printf '  5. 自动清除 730 天以前的日志\n'
        printf '  6. 自动清除 1095 天以前的日志\n'
        printf '  7. 自定义保留天数（7-3650 天）\n'
        printf '  8. 关闭自动清理（不删除现有日志）\n'
        printf '  0. 返回主菜单\n'
        printf '%s\n' '--------------------------------------------------'
        printf '  提示: 设置后会立即清理一次，并在每天 03:27 自动执行。\n'

        if ! read -r -p '请输入选项 [0-8]: ' choice; then
            return 0
        fi
        case "$choice" in
            1) days=30 ;;
            2) days=90 ;;
            3) days=180 ;;
            4) days=365 ;;
            5) days=730 ;;
            6) days=1095 ;;
            7)
                read -r -p '请输入保留天数 [7-3650]: ' custom_days || return 0
                if [[ ! "$custom_days" =~ ^[0-9]+$ ]] \
                    || (( 10#$custom_days < 7 || 10#$custom_days > 3650 )); then
                    warn "保留天数无效，请重新选择。"
                    continue
                fi
                days=$((10#$custom_days))
                ;;
            8)
                disable_retention_policy || return 1
                show_log_storage
                return 0
                ;;
            0|q|Q)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                continue
                ;;
        esac

        install_retention_policy "$days" || return 1
        prune_log_storage "$days" || warn "本次清理存在警告，自动清理会在下次定时运行时重试。"
        show_log_storage
        return 0
    done
}

detect_release_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  printf 'linux_amd64\n' ;;
        aarch64|arm64) printf 'linux_aarch64\n' ;;
        *) return 1 ;;
    esac
}

fetch_latest_release() {
    local arch="$1"

    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 45 \
        -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: cpa-management-script' \
        'https://api.github.com/repos/router-for-me/CLIProxyAPI/releases?per_page=20' \
        | jq -c --arg arch "$arch" '
            if type != "array" then empty else
                first(
                    .[]
                    | select(.draft == false and .prerelease == false)
                    | . as $release
                    | ($release.tag_name | sub("^v"; "")) as $version
                    | ("CLIProxyAPI_" + $version + "_" + $arch + ".tar.gz") as $asset_name
                    | ([$release.assets[]? | select(.name == $asset_name)][0] // null) as $asset
                    | select($asset != null)
                    | {
                        tag: $release.tag_name,
                        version: $version,
                        asset_name: $asset_name,
                        url: $asset.browser_download_url,
                        checksum_url: ([$release.assets[]? | select(.name == "checksums.txt") | .browser_download_url][0] // "")
                    }
                )
            end
        '
}

detect_cpamp_release_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  printf 'linux_amd64\n' ;;
        aarch64|arm64) printf 'linux_arm64\n' ;;
        *) return 1 ;;
    esac
}

fetch_latest_cpamp_release() {
    local arch="$1"

    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 45 \
        -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: cpa-management-script' \
        'https://api.github.com/repos/seakee/CPA-Manager-Plus/releases?per_page=20' \
        | jq -c --arg arch "$arch" '
            if type != "array" then empty else
                first(
                    .[]
                    | select(.draft == false and .prerelease == false)
                    | . as $release
                    | ($release.tag_name | sub("^v"; "")) as $version
                    | ("cpa-manager-plus_" + $release.tag_name + "_" + $arch + ".tar.gz") as $asset_name
                    | ([$release.assets[]? | select(.name == $asset_name)][0] // null) as $asset
                    | select($asset != null)
                    | {
                        tag: $release.tag_name,
                        version: $version,
                        asset_name: $asset_name,
                        url: $asset.browser_download_url,
                        checksum_url: ([$release.assets[]? | select(.name == "checksums.txt") | .browser_download_url][0] // "")
                    }
                )
            end
        '
}

checksum_for_asset() {
    local checksum_file="$1" asset_name="$2"

    awk -v name="$asset_name" '
        {
            hash = ""
            file = ""

            if (toupper($1) == "SHA256" && $3 == "=") {
                file = $2
                sub(/^\(/, "", file)
                sub(/\)$/, "", file)
                hash = $4
            } else {
                hash = $1
                file = $2
            }

            sub(/^\*/, "", file)
            sub(/^\.\//, "", file)
            if (file == name) {
                print tolower(hash)
                exit
            }
        }
    ' "$checksum_file"
}

cpamp_env_value() {
    local file="$1" key="$2"

    [[ -f "$file" ]] || return 0
    awk -v key="$key" '
        index($0, key "=") == 1 {
            print substr($0, length(key) + 2)
            exit
        }
    ' "$file"
}

append_cpamp_env_mapping() {
    local file="$1" new_key="$2" old_key="$3" value

    grep -q "^${new_key}=" "$file" 2>/dev/null && return 0
    value=$(cpamp_env_value "$file" "$old_key")
    [[ -n "$value" ]] || return 0
    printf '%s=%s\n' "$new_key" "$value" >> "$file"
}

prepare_cpamp_env_compat() {
    local source="$1" target="$2"

    [[ -f "$source" ]] || return 0
    cp -a "$source" "$target" || return 1
    append_cpamp_env_mapping "$target" 'HTTP_ADDR' 'LISTEN_ADDR' || return 1
    append_cpamp_env_mapping "$target" 'USAGE_DATA_DIR' 'DATA_DIR' || return 1
    append_cpamp_env_mapping "$target" 'CPA_MANAGER_ADMIN_KEY' 'ADMIN_SECRET' || return 1
    append_cpamp_env_mapping "$target" 'CPA_UPSTREAM_URL' 'CPA_URL' || return 1
    append_cpamp_env_mapping "$target" 'CPA_MANAGEMENT_KEY' 'CPA_SECRET' || return 1
    set_cpamp_backend_urls "$target"
}

set_cpamp_backend_urls() {
    local file="$1" tmp

    [[ -f "$file" ]] || return 0
    tmp="${file}.backend.${BASHPID}"
    awk -v origin="http://127.0.0.1:${CPA_BACKEND_PORT}" '
        BEGIN { seen_upstream = 0; seen_url = 0 }
        /^CPA_UPSTREAM_URL=/ { print "CPA_UPSTREAM_URL=" origin; seen_upstream = 1; next }
        /^CPA_URL=/ { print "CPA_URL=" origin; seen_url = 1; next }
        { print }
        END {
            if (!seen_upstream) print "CPA_UPSTREAM_URL=" origin
            if (!seen_url) print "CPA_URL=" origin
        }
    ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
    chmod --reference="$file" "$tmp" 2>/dev/null || chmod 0600 "$tmp" || true
    mv -f "$tmp" "$file"
}

# Read exactly one unambiguous CPA listener from either supported YAML layout:
# legacy top-level host/port, or server.host/server.port. Other nested fields
# (e.g. plugin ports) must never be treated as the CPA listener.
# Output: layout<TAB>host<TAB>port<TAB>port-line-number.
cpa_config_endpoint() {
    local source="$1"
    [[ -f "$source" ]] || return 1
    awk '
        function scalar(line,    value, first, last) {
            value = line
            sub(/^[^:]*:[ \t]*/, "", value)
            sub(/[ \t]+#.*/, "", value)
            gsub(/^[ \t]+|[ \t]+$/, "", value)
            first = substr(value, 1, 1)
            last = substr(value, length(value), 1)
            if (length(value) >= 2 && ((first == "\"" && last == "\"") || \
                (first == "\047" && last == "\047"))) {
                value = substr(value, 2, length(value) - 2)
            }
            return value
        }
        {
            line = $0
            sub(/\r$/, "", line)
            if (line ~ /^[ \t]*(#|$)/) next
            if (line ~ /^\t/) { invalid = 1; next }
            match(line, /[^ \t]/)
            indent = RSTART - 1
            field = substr(line, indent + 1)
            if (indent == 0) {
                in_server = 0
                if (field ~ /^server:[ \t]*(#.*)?$/) {
                    server_count++
                    in_server = 1
                    next
                }
                if (field ~ /^server:[ \t]*[^# \t]/) {
                    server_count++
                    invalid = 1
                    next
                }
                if (field ~ /^host[ \t]*:/) {
                    root_host_count++
                    root_host = scalar(field)
                }
                if (field ~ /^port[ \t]*:/) {
                    root_port_count++
                    root_port = scalar(field)
                    root_port_line = NR
                }
            } else if (in_server && field ~ /^[A-Za-z0-9_-]+[ \t]*:/) {
                if (min_server_indent == 0 || indent < min_server_indent) \
                    min_server_indent = indent
                if (field ~ /^host[ \t]*:/) {
                    server_host_count[indent]++
                    server_host[indent] = scalar(field)
                }
                if (field ~ /^port[ \t]*:/) {
                    server_port_count[indent]++
                    server_port[indent] = scalar(field)
                    server_port_line[indent] = NR
                }
            }
        }
        END {
            if (invalid || server_count > 1) exit 2
            if (server_count == 1) {
                if (root_host_count || root_port_count || min_server_indent == 0 || \
                    server_host_count[min_server_indent] != 1 || \
                    server_port_count[min_server_indent] != 1) exit 2
                layout = "server"
                host = server_host[min_server_indent]
                port = server_port[min_server_indent]
                port_line = server_port_line[min_server_indent]
            } else {
                if (root_host_count != 1 || root_port_count != 1) exit 2
                layout = "legacy"
                host = root_host
                port = root_port
                port_line = root_port_line
            }
            if (host == "" || port !~ /^[0-9]+$/ || port + 0 < 1 || \
                port + 0 > 65535 || port_line < 1) exit 2
            printf "%s\t%s\t%s\t%d\n", layout, host, port, port_line
        }
    ' "$source"
}

configured_cpa_port() {
    local port="" endpoint layout host line

    if [[ -f "${CPA_DIR}/config.yaml" ]] \
        && endpoint=$(cpa_config_endpoint "${CPA_DIR}/config.yaml"); then
        IFS=$'\t' read -r layout host port line <<< "$endpoint"
    fi
    if [[ ! "$port" =~ ^[0-9]+$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); then
        port="$CPA_BACKEND_PORT"
    fi
    printf '%s\n' "$port"
}

wait_for_cpa_port() {
    local port="$1" attempt code

    [[ "$port" =~ ^[0-9]+$ ]] && (( 10#$port >= 1 && 10#$port <= 65535 )) || return 1

    for (( attempt = 1; attempt <= 20; attempt++ )); do
        if systemctl is-active --quiet "$CPA_SERVICE"; then
            code=$(curl -sS -o /dev/null --max-time 2 -w '%{http_code}' \
                "http://127.0.0.1:${port}/v1/models" 2>/dev/null || true)
            if [[ "$code" =~ ^(200|401|403)$ ]]; then
                return 0
            fi
        fi
        sleep 1
    done

    return 1
}

wait_for_cpa() {
    wait_for_cpa_port "$(configured_cpa_port)"
}

wait_for_cpamp() {
    local attempt response

    for (( attempt = 1; attempt <= 30; attempt++ )); do
        if systemctl is-active --quiet "$CPAMP_SERVICE"; then
            response=$(curl -fsS --max-time 2 'http://127.0.0.1:18317/health' 2>/dev/null || true)
            if jq -e '.ok == true and .service == "cpa-manager-plus"' \
                >/dev/null 2>&1 <<< "$response"; then
                return 0
            fi
        fi
        sleep 1
    done

    return 1
}

rollback_cpa_update() {
    local backup_file="$1" marker_backup="$2" marker_was_present="$3"
    local old_version="$4" was_active="$5"
    local rollback_ok=1 service_ok=0

    admission_stop_proxies || return 1
    systemctl stop "$CPA_SERVICE" >/dev/null 2>&1 || return 1
    rm -f "${CPA_DIR}/.CLIProxyAPI.new" "${CPA_DIR}/.version.new"
    if ! install -m 0755 -o cpa -g cpa "$backup_file" \
        "${CPA_DIR}/.CLIProxyAPI.rollback" \
        || ! mv -f "${CPA_DIR}/.CLIProxyAPI.rollback" "$CPA_BIN"; then
        error "恢复 CPA 旧二进制失败。"
        rollback_ok=0
    fi
    if [[ "$marker_was_present" == "1" ]]; then
        cp -a "$marker_backup" "${CPA_DIR}/.version" || rollback_ok=0
    else
        rm -f "${CPA_DIR}/.version" || rollback_ok=0
    fi

    if [[ "$rollback_ok" != "1" ]]; then
        error "CPA 回滚文件未完整恢复，保持停止，拒绝重新开放准入。"
        return 1
    fi
    if [[ "$was_active" == "1" ]]; then
        if systemctl start "$CPA_SERVICE" && wait_for_cpa; then
            service_ok=1
        else
            error "CPA 回滚后仍未恢复，请执行：journalctl -u cpa -n 80 --no-pager"
        fi
    else
        service_ok=1
    fi

    if [[ "$rollback_ok" == "1" && "$service_ok" == "1" ]]; then
        warn "已成功回滚到原版本 ${old_version}，服务启停状态保持不变。"
        return 0
    fi
    return 1
}

update_cpa() {
    admission_with_lock update_cpa_locked "$@"
}

update_cpa_locked() {
    local assume_yes="${1:-0}"
    local force_reinstall="${2:-0}"
    local arch release latest_version tag asset_name download_url checksum_url current
    local archive checksum_file expected actual extract_dir candidate candidate_line candidate_version
    local backup_dir backup_file backup_version marker_backup answer="" timestamp admission_state
    local marker_was_present=0 was_active=0

    require_deployment
    command -v curl >/dev/null 2>&1 || die "未安装 curl。"
    command -v jq >/dev/null 2>&1 || die "未安装 jq。"
    command -v tar >/dev/null 2>&1 || die "未安装 tar。"
    command -v sha256sum >/dev/null 2>&1 || die "未安装 sha256sum。"
    id -u cpa >/dev/null 2>&1 || die "未找到 cpa 系统用户，请用菜单 1 重新部署。"
    [[ "$(systemctl show "$CPA_SERVICE" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] \
        || die "未找到可用的 ${CPA_SERVICE}，请用菜单 1 重新部署。"

    arch=$(detect_release_arch) || die "不支持的 CPU 架构: $(uname -m)"
    current=$(current_version)

    info "正在查询最新可用版本..."
    release=$(fetch_latest_release "$arch" 2>/dev/null || true)
    [[ -n "$release" ]] || die "无法从 GitHub 获取适用于 ${arch} 的最新安装包。"

    latest_version=$(jq -r '.version' <<< "$release")
    tag=$(jq -r '.tag' <<< "$release")
    asset_name=$(jq -r '.asset_name' <<< "$release")
    download_url=$(jq -r '.url' <<< "$release")
    checksum_url=$(jq -r '.checksum_url' <<< "$release")

    printf '\n  当前版本: %s\n' "$current"
    printf '  最新版本: %s\n' "$latest_version"
    printf '  安装包:   %s\n\n' "$asset_name"

    if [[ "${current#v}" == "${latest_version#v}" && "$force_reinstall" != "1" ]]; then
        info "当前已是最新可用版本，无需更新。"
        return 0
    fi

    if [[ "$assume_yes" != "1" ]]; then
        read -r -p "确认更新 CPA？配置和授权文件会保留 [y/N]: " answer || return 0
        [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消更新。"; return 0; }
    fi

    UPDATE_TMP=$(mktemp -d /tmp/cpa-update.XXXXXX) || die "无法创建临时目录。"
    archive="${UPDATE_TMP}/${asset_name}"
    checksum_file="${UPDATE_TMP}/checksums.txt"
    extract_dir="${UPDATE_TMP}/extracted"
    mkdir -p "$extract_dir"

    info "正在下载 ${tag}..."
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$archive" "$download_url" || die "CPA 安装包下载失败。"

    [[ -n "$checksum_url" ]] || die "该 Release 没有 checksums.txt，已停止更新。"
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 60 \
        -o "$checksum_file" "$checksum_url" || die "校验文件下载失败。"

    expected=$(checksum_for_asset "$checksum_file" "$asset_name")
    actual=$(sha256sum "$archive" | awk '{print tolower($1)}')
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "校验文件中未找到 ${asset_name}。"
    [[ "$actual" == "$expected" ]] || die "SHA-256 校验失败，安装包可能不完整。"
    info "SHA-256 校验通过。"

    tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$extract_dir" \
        || die "解压安装包失败。"
    candidate=$(find "$extract_dir" -type f \
        \( -iname 'cli-proxy-api' -o -iname 'cliproxyapi' \) \
        -print -quit 2>/dev/null || true)
    if [[ -z "$candidate" || ! -s "$candidate" ]]; then
        error "安装包内未找到 CPA 可执行文件。压缩包内容如下："
        tar -tzf "$archive" 2>/dev/null | sed -n '1,20p' | sed 's/^/  /' >&2 || true
        die "期望文件名为 cli-proxy-api 或 CLIProxyAPI。"
    fi
    chmod 0755 "$candidate"
    info "已定位新版二进制: $(basename "$candidate")"

    candidate_line=$(timeout 3 "$candidate" -config "${UPDATE_TMP}/missing.yaml" 2>&1 \
        | head -n 1 || true)
    candidate_version=$(sed -n 's/.*CLIProxyAPI Version: \([^,[:space:]]*\).*/\1/p' <<< "$candidate_line")
    candidate_version="${candidate_version#v}"
    [[ "$candidate_version" == "$latest_version" ]] \
        || die "安装包版本验证失败（期望 ${latest_version}，检测到 ${candidate_version:-未知}）。"

    timestamp=$(backup_stamp)
    backup_dir="${CPA_DIR}/backups"
    backup_version="${current//[^a-zA-Z0-9._-]/_}"
    backup_file="${backup_dir}/CLIProxyAPI.${backup_version}.${timestamp}"
    marker_backup="${UPDATE_TMP}/version.marker"
    install -d -m 0700 -o root -g root "$backup_dir" \
        || die "无法创建 CPA 更新备份目录。"
    cp -a "$CPA_BIN" "$backup_file" || die "创建旧版本备份失败。"
    if [[ -f "${CPA_DIR}/.version" ]]; then
        cp -a "${CPA_DIR}/.version" "$marker_backup" || die "备份 CPA 版本标记失败。"
        marker_was_present=1
    fi

    systemctl is-active --quiet "$CPA_SERVICE" && was_active=1

    info "正在停止 CPA 并替换二进制文件..."
    admission_state="${UPDATE_TMP}/admission.state"
    admission_suspend_runtime "$admission_state" || {
        admission_resume_runtime "$admission_state" || true
        die "无法暂停准入入口，未替换 CPA 二进制。"
    }
    systemctl stop "$CPA_SERVICE" || {
        admission_resume_runtime "$admission_state" || true
        die "无法停止 CPA 服务。"
    }

    if ! install -m 0755 -o cpa -g cpa "$candidate" "${CPA_DIR}/.CLIProxyAPI.new" \
        || ! mv -f "${CPA_DIR}/.CLIProxyAPI.new" "$CPA_BIN"; then
        error "安装新二进制失败，正在恢复服务。"
        rollback_cpa_update "$backup_file" "$marker_backup" "$marker_was_present" \
            "$current" "$was_active" && admission_resume_runtime "$admission_state" || true
        return 1
    fi

    if ! (printf '%s\n' "$latest_version" > "${UPDATE_TMP}/cpa.version" \
        && install -m 0644 -o cpa -g cpa "${UPDATE_TMP}/cpa.version" \
            "${CPA_DIR}/.version.new" \
        && mv -f "${CPA_DIR}/.version.new" "${CPA_DIR}/.version"); then
        error "写入 CPA 版本标记失败，正在回滚。"
        rollback_cpa_update "$backup_file" "$marker_backup" "$marker_was_present" \
            "$current" "$was_active" && admission_resume_runtime "$admission_state" || true
        return 1
    fi

    info "正在检查新版本服务..."
    if systemctl start "$CPA_SERVICE" && wait_for_cpa; then
        if { [[ "$was_active" == "1" ]] || systemctl stop "$CPA_SERVICE"; } \
            && admission_resume_runtime "$admission_state"; then
            info "更新完成：${current} -> ${latest_version}"
            [[ "$was_active" == "0" ]] && info "CPA 更新前处于停止状态，现已恢复为停止。"
            info "旧二进制已备份到 ${backup_file}"
            return 0
        fi
        error "新版验证通过，但无法恢复 CPA 原停止状态。"
    fi

    error "新版本未能正常启动，正在自动回滚..."
    rollback_cpa_update "$backup_file" "$marker_backup" "$marker_was_present" \
        "$current" "$was_active" && admission_resume_runtime "$admission_state" || true
    return 1
}

cpamp_strip_env_value() {
    local value="$1"

    value="${value%\"}"; value="${value#\"}"
    value="${value%\'}"; value="${value#\'}"
    printf '%s\n' "$value"
}

cpamp_process_env_value() {
    local key="$1" pid="" value=""

    pid=$(systemctl show "$CPAMP_SERVICE" -p MainPID --value 2>/dev/null || true)
    [[ "$pid" =~ ^[1-9][0-9]*$ && -r "/proc/${pid}/environ" ]] || return 0
    value=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null \
        | awk -v key="$key" 'index($0, key "=") == 1 {print substr($0, length(key) + 2); exit}' \
        || true)
    cpamp_strip_env_value "$value"
}

cpamp_effective_env_value() {
    local key="$1" value=""

    # The live process is authoritative when a systemd drop-in overrides .env.
    value=$(cpamp_process_env_value "$key")
    if [[ -z "$value" && -f "${CPAMP_DIR}/.env" ]]; then
        value=$(cpamp_env_value "${CPAMP_DIR}/.env" "$key")
        value=$(cpamp_strip_env_value "$value")
    fi
    printf '%s\n' "$value"
}

cpamp_data_directory() {
    local value=""

    value=$(cpamp_effective_env_value 'USAGE_DATA_DIR')
    [[ -n "$value" ]] || value=$(cpamp_effective_env_value 'DATA_DIR')
    [[ -n "$value" ]] || value="${CPAMP_DIR}/data"
    [[ "$value" == /* ]] || value="${CPAMP_DIR}/${value}"
    readlink -m "$value" 2>/dev/null || printf '%s\n' "$value"
}

cpamp_database_path() {
    local value=""

    value=$(cpamp_effective_env_value 'USAGE_DB_PATH')
    if [[ -z "$value" ]]; then
        value="$(cpamp_data_directory)/usage.sqlite"
    elif [[ "$value" != /* ]]; then
        value="${CPAMP_DIR}/${value}"
    fi
    readlink -m "$value" 2>/dev/null || printf '%s\n' "$value"
}

cpamp_admin_key_file() {
    local path=""

    path=$(cpamp_process_env_value 'CPA_MANAGER_ADMIN_KEY_FILE')
    if [[ -z "$path" && -f "${CPAMP_DIR}/.env" ]]; then
        path=$(cpamp_env_value "${CPAMP_DIR}/.env" 'CPA_MANAGER_ADMIN_KEY_FILE')
        path=$(cpamp_strip_env_value "$path")
    fi
    [[ -n "$path" ]] || path='/run/secrets/cpa_admin_key'
    [[ "$path" == /* ]] || path="${CPAMP_DIR}/${path}"
    printf '%s\n' "$path"
}

CPAMP_MAINT_ADMIN_KEY_OVERRIDE=""

cpamp_maintenance_admin_key_from_file() {
    local value=""

    [[ -r "$CPAMP_MAINT_ADMIN_KEY_FILE" && -s "$CPAMP_MAINT_ADMIN_KEY_FILE" ]] || return 0
    value=$(cat -- "$CPAMP_MAINT_ADMIN_KEY_FILE" 2>/dev/null || true)
    value="${value//$'\r'/}"
    value="${value//$'\n'/}"
    printf '%s\n' "$value"
}

cpamp_admin_key() {
    local value="" key_file=""

    # A separately stored maintenance key is preferred.  CPAMP may keep the
    # effective Admin Key in its database while an older bootstrap value remains
    # in the service environment; blindly trusting /proc/<pid>/environ can then
    # produce HTTP 401 even though the user's current Admin Key is valid.
    if [[ -n "${CPAMP_MAINT_ADMIN_KEY_OVERRIDE:-}" ]]; then
        value="$CPAMP_MAINT_ADMIN_KEY_OVERRIDE"
    else
        value=$(cpamp_maintenance_admin_key_from_file)
    fi
    [[ -n "$value" ]] || value=$(cpamp_process_env_value 'CPA_MANAGER_ADMIN_KEY')
    [[ -n "$value" ]] || value=$(cpamp_process_env_value 'ADMIN_SECRET')
    if [[ -z "$value" && -f "${CPAMP_DIR}/.env" ]]; then
        value=$(cpamp_env_value "${CPAMP_DIR}/.env" 'CPA_MANAGER_ADMIN_KEY')
        [[ -n "$value" ]] || value=$(cpamp_env_value "${CPAMP_DIR}/.env" 'ADMIN_SECRET')
        value=$(cpamp_strip_env_value "$value")
    fi
    if [[ -z "$value" ]]; then
        key_file=$(cpamp_admin_key_file)
        if [[ -r "$key_file" ]]; then
            value=$(cat -- "$key_file" 2>/dev/null || true)
            value="${value//$'\r'/}"
            value="${value//$'\n'/}"
        fi
    fi
    printf '%s\n' "$value"
}

cpamp_admin_key_source() {
    local value="" key_file=""

    if [[ -n "${CPAMP_MAINT_ADMIN_KEY_OVERRIDE:-}" ]]; then
        printf '%s\n' '临时输入的维护验证 Key'
        return 0
    fi
    value=$(cpamp_maintenance_admin_key_from_file)
    if [[ -n "$value" ]]; then
        printf '%s\n' "维护专用 Key 文件 ${CPAMP_MAINT_ADMIN_KEY_FILE}（root 0600）"
        return 0
    fi

    value=$(cpamp_process_env_value 'CPA_MANAGER_ADMIN_KEY')
    [[ -n "$value" ]] && { printf '%s\n' '运行中进程环境 CPA_MANAGER_ADMIN_KEY'; return 0; }
    value=$(cpamp_process_env_value 'ADMIN_SECRET')
    [[ -n "$value" ]] && { printf '%s\n' '运行中进程环境 ADMIN_SECRET（兼容项）'; return 0; }

    if [[ -f "${CPAMP_DIR}/.env" ]]; then
        value=$(cpamp_env_value "${CPAMP_DIR}/.env" 'CPA_MANAGER_ADMIN_KEY')
        [[ -n "$value" ]] && { printf '%s\n' '.env 的 CPA_MANAGER_ADMIN_KEY'; return 0; }
        value=$(cpamp_env_value "${CPAMP_DIR}/.env" 'ADMIN_SECRET')
        [[ -n "$value" ]] && { printf '%s\n' '.env 的 ADMIN_SECRET（兼容项）'; return 0; }
    fi

    key_file=$(cpamp_admin_key_file)
    if [[ -r "$key_file" && -s "$key_file" ]]; then
        if [[ "$key_file" == '/run/secrets/cpa_admin_key' ]]; then
            printf '%s\n' '默认 Admin Key secret 文件'
        else
            printf '%s\n' 'CPA_MANAGER_ADMIN_KEY_FILE 指定的 secret 文件'
        fi
        return 0
    fi
    printf '%s\n' '未找到'
}

cpamp_maintenance_set_admin_key() {
    local value="" confirm="" tmp_file="" rc=2 old_umask

    [[ -t 0 ]] || {
        error "设置维护 Admin Key 需要交互式终端，以免密钥进入命令行参数或 shell 历史。"
        return 1
    }
    read -r -s -p '请输入当前有效的 CPAMP Admin Key: ' value || return 1
    printf '\n'
    [[ -n "$value" ]] || { error "Admin Key 不能为空。"; return 1; }
    if (( ${#value} < 8 || ${#value} > 512 )); then
        error "Admin Key 长度异常，已取消保存。"
        unset value
        return 1
    fi

    CPAMP_MAINT_ADMIN_KEY_OVERRIDE="$value"
    cpamp_database_maintenance_required
    rc=$?
    CPAMP_MAINT_ADMIN_KEY_OVERRIDE=""
    if [[ "$rc" == "2" ]]; then
        error "这个 Admin Key 未通过本机 CPAMP /status 验证，未保存。"
        [[ -n "$CPAMP_MAINT_LAST_ERROR" ]] && error "原因：${CPAMP_MAINT_LAST_ERROR}"
        unset value
        return 1
    fi

    old_umask=$(umask)
    umask 077
    tmp_file=$(mktemp "${CPAMP_MAINT_ADMIN_KEY_FILE}.XXXXXX") || {
        umask "$old_umask"
        unset value
        error "无法创建维护 Key 临时文件。"
        return 1
    }
    if ! printf '%s\n' "$value" > "$tmp_file" \
        || ! chown root:root "$tmp_file" \
        || ! chmod 0600 "$tmp_file" \
        || ! mv -f "$tmp_file" "$CPAMP_MAINT_ADMIN_KEY_FILE"; then
        rm -f "$tmp_file"
        umask "$old_umask"
        unset value
        error "保存维护 Admin Key 失败。"
        return 1
    fi
    umask "$old_umask"
    unset value

    info "维护检测专用 Admin Key 已验证并保存到 ${CPAMP_MAINT_ADMIN_KEY_FILE}（root:root 0600）。"
    if [[ "$rc" == "0" ]]; then
        info "当前 CPAMP 报告数据库需要维护；正在按策略安排凌晨维护。"
        schedule_cpamp_maintenance detected || {
            warn "Key 已保存，但创建凌晨维护任务失败；可稍后执行 cpa cpamp-maintenance --check。"
            return 1
        }
        show_cpamp_maintenance_timer
    else
        clear_cpamp_maintenance_schedule
        info "当前 CPAMP 数据库无需离线维护；未创建凌晨停机任务。"
    fi
}

cpamp_maintenance_clear_admin_key() {
    if [[ -e "$CPAMP_MAINT_ADMIN_KEY_FILE" ]]; then
        rm -f -- "$CPAMP_MAINT_ADMIN_KEY_FILE" || {
            error "删除维护 Admin Key 文件失败。"
            return 1
        }
        info "已删除维护检测专用 Admin Key；CPAMP 自身的 Admin Key 未被修改。"
    else
        info "未配置维护检测专用 Admin Key。"
    fi
}

cpamp_http_addr() {
    local value=""

    value=$(cpamp_effective_env_value 'HTTP_ADDR')
    [[ -n "$value" ]] || value=$(cpamp_effective_env_value 'LISTEN_ADDR')
    [[ -n "$value" ]] || value='127.0.0.1:18317'
    printf '%s\n' "$value"
}

cpamp_http_origin() {
    local addr host port

    addr=$(cpamp_http_addr)
    case "$addr" in
        http://*|https://*)
            printf '%s\n' "${addr%/}"
            return 0
            ;;
    esac

    host='127.0.0.1'
    port='18317'
    if [[ "$addr" =~ ^\[([^]]+)\]:([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    elif [[ "$addr" =~ ^([^:]*):([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    elif [[ "$addr" =~ ^[0-9]+$ ]]; then
        port="$addr"
    fi

    case "$host" in
        ''|'0.0.0.0'|'*') host='127.0.0.1' ;;
        '::'|'[::]') host='::1' ;;
    esac
    if [[ "$host" == *:* ]]; then
        printf 'http://[%s]:%s\n' "$host" "$port"
    else
        printf 'http://%s:%s\n' "$host" "$port"
    fi
}

CPAMP_MAINT_LAST_ERROR=""
CPAMP_MAINT_LAST_HTTP_CODE=""
CPAMP_MAINT_LAST_URL=""
CPAMP_MAINT_LAST_DEFERRED=""
CPAMP_MAINT_LAST_OFFLINE_JOBS=""

cpamp_database_maintenance_required() {
    local admin_key origin path url body_file err_file header_file http_code curl_rc response
    local tmp_dir="" first=1

    CPAMP_MAINT_LAST_ERROR=""
    CPAMP_MAINT_LAST_HTTP_CODE=""
    CPAMP_MAINT_LAST_URL=""
    CPAMP_MAINT_LAST_DEFERRED=""
    CPAMP_MAINT_LAST_OFFLINE_JOBS=""

    if ! systemctl is-active --quiet "$CPAMP_SERVICE"; then
        CPAMP_MAINT_LAST_ERROR="${CPAMP_SERVICE} 当前不是 active 状态"
        return 2
    fi
    command -v curl >/dev/null 2>&1 || {
        CPAMP_MAINT_LAST_ERROR='未安装 curl'
        return 2
    }
    command -v jq >/dev/null 2>&1 || {
        CPAMP_MAINT_LAST_ERROR='未安装 jq'
        return 2
    }

    admin_key=$(cpamp_admin_key)
    if [[ -z "$admin_key" ]]; then
        CPAMP_MAINT_LAST_ERROR='未找到可用于本机 /status 认证的 CPAMP Admin Key'
        return 2
    fi
    origin=$(cpamp_http_origin)
    tmp_dir=$(mktemp -d /tmp/cpamp-maint-status.XXXXXX) || {
        CPAMP_MAINT_LAST_ERROR='无法创建状态检查临时目录'
        return 2
    }
    body_file="${tmp_dir}/body"
    err_file="${tmp_dir}/curl.err"
    header_file="${tmp_dir}/auth.headers"
    if ! printf 'Authorization: Bearer %s\nAccept: application/json\n' "$admin_key" > "$header_file" \
        || ! chmod 0600 "$header_file"; then
        unset admin_key
        rm -rf -- "$tmp_dir"
        CPAMP_MAINT_LAST_ERROR='无法创建私有认证头文件'
        return 2
    fi
    unset admin_key

    # Prefer the lightweight maintenance scope. Fall back to full /status for
    # releases/proxies that do not recognize the scope query.
    for path in '/status?scope=database-maintenance' '/status'; do
        url="${origin}${path}"
        : > "$body_file"
        : > "$err_file"
        http_code=$(curl -sS --noproxy '*' --max-time 5 -o "$body_file" -w '%{http_code}' \
            --header "@${header_file}" "$url" 2>"$err_file")
        curl_rc=$?
        CPAMP_MAINT_LAST_HTTP_CODE="${http_code:-000}"
        CPAMP_MAINT_LAST_URL="$url"

        if [[ "$curl_rc" != "0" ]]; then
            CPAMP_MAINT_LAST_ERROR="无法连接 CPAMP 状态接口（curl ${curl_rc}）"
            if [[ -s "$err_file" ]]; then
                CPAMP_MAINT_LAST_ERROR+="：$(head -n 1 "$err_file" | tr -d '\r\n')"
            fi
            rm -rf -- "$tmp_dir"
            return 2
        fi
        if [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
            CPAMP_MAINT_LAST_ERROR="CPAMP 状态接口返回 HTTP ${http_code}，Admin Key 认证失败；可执行 cpa cpamp-maintenance --set-admin-key 更新维护专用 Key"
            rm -rf -- "$tmp_dir"
            return 2
        fi
        if [[ "$http_code" == "404" && "$first" == "1" ]]; then
            first=0
            continue
        fi
        if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            CPAMP_MAINT_LAST_ERROR="CPAMP 状态接口返回 HTTP ${http_code:-未知}"
            rm -rf -- "$tmp_dir"
            return 2
        fi

        response=$(cat -- "$body_file" 2>/dev/null || true)
        if ! jq -e . >/dev/null 2>&1 <<< "$response"; then
            CPAMP_MAINT_LAST_ERROR="CPAMP 状态接口 HTTP ${http_code}，但返回内容不是有效 JSON"
            rm -rf -- "$tmp_dir"
            return 2
        fi
        CPAMP_MAINT_LAST_DEFERRED=$(jq -r '.databaseMaintenance.deferredIndexes // empty' <<< "$response" 2>/dev/null || true)
        CPAMP_MAINT_LAST_OFFLINE_JOBS=$(jq -r '.databaseMaintenance.offlineJobs // empty' <<< "$response" 2>/dev/null || true)
        if jq -e '.databaseMaintenance.required == true' >/dev/null 2>&1 <<< "$response"; then
            rm -rf -- "$tmp_dir"
            return 0
        fi
        if jq -e '.databaseMaintenance.required == false' >/dev/null 2>&1 <<< "$response"; then
            rm -rf -- "$tmp_dir"
            return 1
        fi

        if [[ "$first" == "1" ]]; then
            first=0
            continue
        fi
        CPAMP_MAINT_LAST_ERROR='CPAMP /status 未返回 databaseMaintenance.required 布尔值'
        rm -rf -- "$tmp_dir"
        return 2
    done

    rm -rf -- "$tmp_dir"
    CPAMP_MAINT_LAST_ERROR='无法从 CPAMP /status 读取 databaseMaintenance 状态'
    return 2
}

stage_cpamp_maintenance_units() {
    local target_dir="$1"

    mkdir -p "$target_dir" || return 1
    cat > "${target_dir}/${CPAMP_MAINT_SERVICE}" <<EOF
[Unit]
Description=Offline CPA Manager Plus database maintenance
After=network-online.target
ConditionPathExists=${CPAMP_MAINT_PENDING}

[Service]
Type=oneshot
WorkingDirectory=${CPAMP_DIR}
ExecStart=${INSTALL_PATH} cpamp-maintenance --scheduled-direct
ExecStopPost=${INSTALL_PATH} cpamp-maintenance --recover-service
TimeoutStartSec=1800
TimeoutStopSec=240
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=${CPAMP_DIR} /etc/systemd/system /run/lock
EOF

    cat > "${target_dir}/${CPAMP_MAINT_MANUAL_SERVICE}" <<EOF
[Unit]
Description=Manual offline CPA Manager Plus database maintenance
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=${CPAMP_DIR}
ExecStart=${INSTALL_PATH} cpamp-maintenance --run-now-direct
ExecStopPost=${INSTALL_PATH} cpamp-maintenance --recover-service
TimeoutStartSec=1800
TimeoutStopSec=240
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=${CPAMP_DIR} /etc/systemd/system /run/lock
EOF

    cat > "${target_dir}/${CPAMP_MAINT_TIMER}" <<EOF
[Unit]
Description=Run pending CPAMP database maintenance around 04:00

[Timer]
OnCalendar=*-*-* 04:00:00
AccuracySec=1min
RandomizedDelaySec=10min
Persistent=false
Unit=${CPAMP_MAINT_SERVICE}

[Install]
WantedBy=timers.target
EOF
}

install_cpamp_maintenance_units() {
    local stage_dir

    [[ -x "$INSTALL_PATH" ]] || install_self
    stage_dir=$(mktemp -d /tmp/cpa-cpamp-maint-units.XXXXXX) || return 1
    stage_cpamp_maintenance_units "$stage_dir" || { rm -rf -- "$stage_dir"; return 1; }

    if ! install -m 0644 -o root -g root "${stage_dir}/${CPAMP_MAINT_SERVICE}" "$CPAMP_MAINT_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${stage_dir}/${CPAMP_MAINT_MANUAL_SERVICE}" "$CPAMP_MAINT_MANUAL_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${stage_dir}/${CPAMP_MAINT_TIMER}" "$CPAMP_MAINT_TIMER_FILE" \
        || ! systemctl daemon-reload; then
        rm -rf -- "$stage_dir"
        return 1
    fi
    rm -rf -- "$stage_dir"
}

refresh_existing_cpamp_maintenance_units() {
    local stage_dir backup_dir timer_enabled timer_active rc=0 file target
    local -a files=("$CPAMP_MAINT_SERVICE" "$CPAMP_MAINT_MANUAL_SERVICE" "$CPAMP_MAINT_TIMER")

    if [[ ! -f "$CPAMP_MAINT_SERVICE_FILE" && ! -f "$CPAMP_MAINT_TIMER_FILE" \
        && ! -f "$CPAMP_MAINT_PENDING" ]]; then
        return 0
    fi
    stage_dir=$(mktemp -d /tmp/cpa-cpamp-maint-refresh.XXXXXX) || return 1
    backup_dir="${stage_dir}/backup"
    mkdir -p "$backup_dir" || { rm -rf -- "$stage_dir"; return 1; }
    stage_cpamp_maintenance_units "$stage_dir" || { rm -rf -- "$stage_dir"; return 1; }
    timer_enabled=$(systemctl is-enabled "$CPAMP_MAINT_TIMER" 2>/dev/null || true)
    timer_active=$(systemctl is-active "$CPAMP_MAINT_TIMER" 2>/dev/null || true)

    for file in "${files[@]}"; do
        target="/etc/systemd/system/${file}"
        if [[ -f "$target" ]]; then
            cp -a -- "$target" "${backup_dir}/${file}" || { rc=1; break; }
        else
            : > "${backup_dir}/${file}.absent" || { rc=1; break; }
        fi
    done
    if [[ "$rc" == "0" ]]; then
        for file in "${files[@]}"; do
            install -m 0644 -o root -g root "${stage_dir}/${file}" "/etc/systemd/system/${file}" \
                || { rc=1; break; }
        done
    fi
    [[ "$rc" != "0" ]] || systemctl daemon-reload || rc=1
    if [[ "$rc" == "0" ]]; then
        if [[ "$timer_enabled" == "enabled" ]]; then
            systemctl enable "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || rc=1
        else
            systemctl disable "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        fi
        if [[ "$timer_active" == "active" ]]; then
            systemctl start "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || rc=1
        else
            systemctl stop "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        fi
    fi

    if [[ "$rc" != "0" ]]; then
        for file in "${files[@]}"; do
            target="/etc/systemd/system/${file}"
            if [[ -f "${backup_dir}/${file}" ]]; then
                cp -a -- "${backup_dir}/${file}" "$target" || true
            elif [[ -f "${backup_dir}/${file}.absent" ]]; then
                rm -f -- "$target" || true
            fi
        done
        systemctl daemon-reload >/dev/null 2>&1 || true
        if [[ "$timer_enabled" == "enabled" ]]; then
            systemctl enable "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        else
            systemctl disable "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        fi
        if [[ "$timer_active" == "active" ]]; then
            systemctl start "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        else
            systemctl stop "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
        fi
    fi
    rm -rf -- "$stage_dir"
    return "$rc"
}

clear_cpamp_maintenance_schedule() {
    rm -f "$CPAMP_MAINT_PENDING"
    systemctl disable --now "$CPAMP_MAINT_TIMER" >/dev/null 2>&1 || true
}

schedule_cpamp_maintenance() {
    local reason="${1:-detected}" marker_tmp

    install_cpamp_maintenance_units || return 1
    marker_tmp=$(mktemp "${CPAMP_DIR}/.database-maintenance-pending.XXXXXX") || return 1
    if ! {
        printf 'scheduled_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf 'reason=%s\n' "$reason"
    } > "$marker_tmp" \
        || ! chown root:root "$marker_tmp" \
        || ! chmod 0600 "$marker_tmp" \
        || ! mv -f "$marker_tmp" "$CPAMP_MAINT_PENDING"; then
        rm -f "$marker_tmp"
        return 1
    fi
    if ! systemctl enable --now "$CPAMP_MAINT_TIMER" >/dev/null; then
        rm -f "$CPAMP_MAINT_PENDING"
        return 1
    fi
    if [[ "$reason" == "manual" ]]; then
        info "已手动安排 CPAMP 数据库离线维护：服务器本机时间 04:00 后随机 0-10 分钟内执行。"
    else
        info "检测到 CPAMP 数据库需要离线维护；已安排在服务器本机时间 04:00 后随机 0-10 分钟内执行。"
    fi
}

check_and_schedule_cpamp_maintenance() {
    local rc

    cpamp_database_maintenance_required
    rc=$?
    case "$rc" in
        0)
            schedule_cpamp_maintenance detected || {
                warn "检测到数据库维护需求，但自动安排 04:00 维护失败。"
                return 1
            }
            ;;
        1)
            clear_cpamp_maintenance_schedule
            info "CPAMP 数据库无需离线维护。"
            ;;
        *)
            warn "暂时无法读取 CPAMP databaseMaintenance 状态；本次未自动安排停机维护。"
            [[ -n "$CPAMP_MAINT_LAST_ERROR" ]] && warn "原因：${CPAMP_MAINT_LAST_ERROR}"
            warn "可执行：cpa cpamp-maintenance --diagnose"
            if [[ ! -s "$CPAMP_MAINT_ADMIN_KEY_FILE" ]]; then
                warn "如果诊断显示 HTTP 401/403，请执行：cpa cpamp-maintenance --set-admin-key"
            fi
            return 2
            ;;
    esac
    return 0
}

show_cpamp_maintenance_timer() {
    if [[ -f "$CPAMP_MAINT_PENDING" ]]; then
        systemctl list-timers "$CPAMP_MAINT_TIMER" --no-pager 2>/dev/null || true
    fi
}

cpamp_maintenance_diagnose() {
    local service_state load_state admin_source http_addr origin data_dir db_path rc
    local timer_active timer_enabled pending='否' db_exists='否' maint_key='未配置'

    load_state=$(systemctl show "$CPAMP_SERVICE" -p LoadState --value 2>/dev/null || true)
    service_state=$(systemctl is-active "$CPAMP_SERVICE" 2>/dev/null || true)
    admin_source=$(cpamp_admin_key_source)
    http_addr=$(cpamp_http_addr)
    origin=$(cpamp_http_origin)
    data_dir=$(cpamp_data_directory)
    db_path=$(cpamp_database_path)
    [[ -f "$db_path" ]] && db_exists='是'
    [[ -f "$CPAMP_MAINT_PENDING" ]] && pending='是'
    [[ -r "$CPAMP_MAINT_ADMIN_KEY_FILE" && -s "$CPAMP_MAINT_ADMIN_KEY_FILE" ]] && maint_key='已配置（root 0600）'
    timer_active=$(systemctl is-active "$CPAMP_MAINT_TIMER" 2>/dev/null || true)
    timer_enabled=$(systemctl is-enabled "$CPAMP_MAINT_TIMER" 2>/dev/null || true)

    printf '\n%bCPAMP 数据库维护诊断%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  管理脚本版本:       %s\n' "$SCRIPT_VERSION"
    printf '  CPAMP 版本:         %s\n' "$(current_cpamp_version)"
    printf '  cpamp.service:      %s / %s\n' "${load_state:-unknown}" "${service_state:-unknown}"
    printf '  HTTP_ADDR:          %s\n' "$http_addr"
    printf '  本机状态接口:       %s/status\n' "$origin"
    printf '  Admin Key 来源:     %s\n' "$admin_source"
    printf '  维护专用 Key:       %s\n' "$maint_key"
    printf '  数据目录:           %s\n' "$data_dir"
    printf '  SQLite:             %s (%s)\n' "$db_path" "$db_exists"
    printf '  待维护标记:         %s\n' "$pending"
    printf '  维护 timer:         %s / %s\n' "${timer_enabled:-unknown}" "${timer_active:-unknown}"

    cpamp_database_maintenance_required
    rc=$?
    case "$rc" in
        0)
            printf '  databaseMaintenance: %b需要维护%b\n' "$YELLOW" "$NC"
            ;;
        1)
            printf '  databaseMaintenance: %b正常，无需维护%b\n' "$GREEN" "$NC"
            ;;
        *)
            printf '  databaseMaintenance: %b无法判定%b\n' "$YELLOW" "$NC"
            ;;
    esac
    [[ -n "$CPAMP_MAINT_LAST_HTTP_CODE" ]] \
        && printf '  状态接口 HTTP:      %s\n' "$CPAMP_MAINT_LAST_HTTP_CODE"
    [[ -n "$CPAMP_MAINT_LAST_DEFERRED" ]] \
        && printf '  待建查询索引:       %s\n' "$CPAMP_MAINT_LAST_DEFERRED"
    [[ -n "$CPAMP_MAINT_LAST_OFFLINE_JOBS" ]] \
        && printf '  离线清理任务:       %s\n' "$CPAMP_MAINT_LAST_OFFLINE_JOBS"
    [[ -n "$CPAMP_MAINT_LAST_ERROR" ]] \
        && printf '  诊断原因:           %s\n' "$CPAMP_MAINT_LAST_ERROR"
    if [[ "$CPAMP_MAINT_LAST_HTTP_CODE" =~ ^(401|403)$ ]]; then
        printf '  修复命令:           cpa cpamp-maintenance --set-admin-key\n'
    fi
    printf '%s\n' '--------------------------------------------------'
    printf '诊断不会显示 Admin Key 内容。\n\n'

    show_cpamp_maintenance_timer
    return 0
}

cpamp_maintenance_arm_recovery() {
    local state_tmp owner_invocation owner_unit existing_invocation

    owner_invocation="${INVOCATION_ID:-}"
    owner_unit="${CPAMP_MAINT_RECOVERY_OWNER_UNIT:-}"
    if [[ -z "$owner_unit" ]]; then
        if running_in_systemd_unit "$CPAMP_MAINT_SERVICE"; then
            owner_unit="$CPAMP_MAINT_SERVICE"
        elif running_in_systemd_unit "$CPAMP_MAINT_MANUAL_SERVICE"; then
            owner_unit="$CPAMP_MAINT_MANUAL_SERVICE"
        fi
    fi
    [[ -n "$owner_invocation" && -n "$owner_unit" ]] || {
        error "无法确认当前维护任务的 systemd invocation，拒绝建立无主恢复状态。"
        return 1
    }
    if [[ -f "$CPAMP_MAINT_RUNTIME_STATE" ]]; then
        existing_invocation=$(cpamp_maintenance_state_value owner_invocation_id)
        if [[ -n "$existing_invocation" && "$existing_invocation" != "$owner_invocation" ]]; then
            cpamp_maintenance_recover_service "$owner_unit" || {
                error "已有 CPAMP 维护恢复状态无法安全接管，拒绝继续离线维护。"
                return 1
            }
            existing_invocation=$(cpamp_maintenance_state_value owner_invocation_id)
            if [[ -n "$existing_invocation" && "$existing_invocation" != "$owner_invocation" ]]; then
                error "已有其他 CPAMP 维护 invocation 持有恢复状态，拒绝覆盖。"
                return 1
            fi
        fi
    fi

    install -d -m 0755 -o root -g root "$(dirname "$CPAMP_MAINT_RUNTIME_STATE")" || return 1
    state_tmp="${CPAMP_MAINT_RUNTIME_STATE}.new.${BASHPID}"
    if ! printf 'restart_required=1\nowner_invocation_id=%s\nowner_unit=%s\narmed_at=%s\n' \
        "$owner_invocation" "$owner_unit" "$(date '+%Y-%m-%d %H:%M:%S %Z')" > "$state_tmp" \
        || ! chmod 0600 "$state_tmp" \
        || ! mv -f "$state_tmp" "$CPAMP_MAINT_RUNTIME_STATE"; then
        rm -f "$state_tmp"
        return 1
    fi
    CPAMP_MAINT_RECOVERY_ARMED=1
}

cpamp_maintenance_disarm_recovery() {
    local expected_invocation="${1:-${INVOCATION_ID:-}}" state_invocation

    state_invocation=$(cpamp_maintenance_state_value owner_invocation_id)
    if [[ -n "$expected_invocation" && -n "$state_invocation" \
        && "$state_invocation" != "$expected_invocation" ]]; then
        return 0
    fi
    rm -f "$CPAMP_MAINT_RUNTIME_STATE" || return 1
    CPAMP_MAINT_RECOVERY_ARMED=0
}

cpamp_maintenance_state_value() {
    local key="$1"

    [[ -f "$CPAMP_MAINT_RUNTIME_STATE" ]] || return 0
    awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2); exit}' \
        "$CPAMP_MAINT_RUNTIME_STATE" 2>/dev/null || true
}

cpamp_maintenance_owner_active() {
    local unit="$1" current_unit="$2" current_invocation="$3"
    local load_state active_state active_invocation

    load_state=$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)
    active_state=$(systemctl show "$unit" -p ActiveState --value 2>/dev/null || true)
    case "$active_state" in
        inactive|failed|dead)
            return 1
            ;;
        active|activating|deactivating|reloading)
            active_invocation=$(systemctl show "$unit" -p InvocationID --value 2>/dev/null || true)
            if [[ "$unit" == "$current_unit" \
                && -n "$current_invocation" \
                && "$active_invocation" == "$current_invocation" ]]; then
                return 1
            fi
            return 0
            ;;
    esac

    # An unloaded unit cannot still execute the invocation recorded in the
    # recovery state. Unknown loaded states remain fail-closed.
    [[ -n "$load_state" && "$load_state" != "loaded" ]] && return 1
    return 0
}

cpamp_maintenance_release_lock() {
    local lock_fd="${CPAMP_MAINT_LOCK_FD:-}"

    if [[ "$lock_fd" =~ ^[0-9]+$ ]]; then
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        eval "exec ${lock_fd}>&-" || true
    fi
    CPAMP_MAINT_LOCK_FD=""
}

cpamp_maintenance_recover_service() {
    local expected_unit="${1:-${CPAMP_MAINT_RECOVERY_OWNER_UNIT:-}}"
    local state_invocation state_unit lock_fd="" owns_lock=0 rc=1
    local current_invocation="${INVOCATION_ID:-}"

    [[ -f "$CPAMP_MAINT_RUNTIME_STATE" ]] || {
        CPAMP_MAINT_RECOVERY_ARMED=0
        return 0
    }

    state_invocation=$(cpamp_maintenance_state_value owner_invocation_id)
    state_unit=$(cpamp_maintenance_state_value owner_unit)
    [[ -n "$expected_unit" ]] || expected_unit="$state_unit"
    [[ -n "$state_invocation" && -n "$state_unit" && -n "$current_invocation" ]] || {
        error "CPAMP 维护恢复状态不完整，拒绝自动接管。"
        return 1
    }
    running_in_systemd_unit "$expected_unit" || return 0

    if [[ "$state_invocation" == "$current_invocation" ]]; then
        [[ "$state_unit" == "$expected_unit" ]] || return 0
    elif cpamp_maintenance_owner_active \
        "$state_unit" "$expected_unit" "$current_invocation"; then
        error "旧 CPAMP 维护 invocation 仍在运行，暂不接管恢复状态。"
        return 1
    fi

    if [[ "${CPAMP_MAINT_LOCK_FD:-}" =~ ^[0-9]+$ ]]; then
        lock_fd="$CPAMP_MAINT_LOCK_FD"
    else
        install -d -m 0755 -o root -g root "$(dirname "$BACKGROUND_HEAVY_LOCK")" || return 1
        exec {lock_fd}>"$BACKGROUND_HEAVY_LOCK" || return 1
        if ! flock -w 180 "$lock_fd"; then
            eval "exec ${lock_fd}>&-" || true
            error "等待重任务锁超时，未启动 CPAMP；恢复状态仍保留。"
            return 1
        fi
        owns_lock=1
    fi

    # The state may have been replaced while recovery waited for the lock.
    state_invocation=$(cpamp_maintenance_state_value owner_invocation_id)
    state_unit=$(cpamp_maintenance_state_value owner_unit)
    if [[ -z "$state_invocation" || -z "$state_unit" ]]; then
        if [[ "$owns_lock" == "1" ]]; then
            flock -u "$lock_fd" >/dev/null 2>&1 || true
            eval "exec ${lock_fd}>&-" || true
        fi
        return 0
    fi
    if [[ "$state_invocation" == "$current_invocation" ]]; then
        if [[ "$state_unit" != "$expected_unit" ]]; then
            if [[ "$owns_lock" == "1" ]]; then
                flock -u "$lock_fd" >/dev/null 2>&1 || true
                eval "exec ${lock_fd}>&-" || true
            fi
            return 0
        fi
    elif cpamp_maintenance_owner_active \
        "$state_unit" "$expected_unit" "$current_invocation"; then
        error "旧 CPAMP 维护 invocation 在恢复等待期间仍处于活动状态。"
        if [[ "$owns_lock" == "1" ]]; then
            flock -u "$lock_fd" >/dev/null 2>&1 || true
            eval "exec ${lock_fd}>&-" || true
        fi
        return 1
    fi

    if systemctl start "$CPAMP_SERVICE" >/dev/null 2>&1 && wait_for_cpamp \
        && cpamp_maintenance_disarm_recovery "$state_invocation"; then
        rc=0
    else
        error "检测到未完成的数据库维护，但 CPAMP 自动恢复失败。"
    fi
    if [[ "$owns_lock" == "1" ]]; then
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        eval "exec ${lock_fd}>&-" || true
    fi
    return "$rc"
}

run_cpamp_database_maintenance() {
    local scheduled="${1:-0}" lock_fd rc

    install -d -m 0755 -o root -g root "$(dirname "$BACKGROUND_HEAVY_LOCK")" || return 1
    exec {lock_fd}>"$BACKGROUND_HEAVY_LOCK" || return 1
    if ! flock -n "$lock_fd"; then
        warn "另一项重后台任务正在运行，本次 CPAMP 数据库维护已退让。"
        exec {lock_fd}>&-
        [[ "$scheduled" == "1" ]] && return 0
        return 1
    fi

    CPAMP_MAINT_LOCK_FD="$lock_fd"
    if ! cpamp_maintenance_recover_service "${CPAMP_MAINT_RECOVERY_OWNER_UNIT:-}"; then
        cpamp_maintenance_release_lock
        [[ "$scheduled" == "1" ]] && return 0
        return 1
    fi
    if ! background_capacity_available "CPAMP 数据库维护" "$BACKGROUND_MIN_AVAILABLE_MIB"; then
        if [[ "$scheduled" == "1" ]]; then
            info "保留待维护标记，等待下一次低压力窗口。"
            cpamp_maintenance_release_lock
            return 0
        fi
        cpamp_maintenance_release_lock
        return 1
    fi
    run_cpamp_database_maintenance_locked "$scheduled"
    rc=$?
    if [[ "${CPAMP_MAINT_RECOVERY_ARMED:-0}" == "1" ]] \
        && ! cpamp_maintenance_recover_service "${CPAMP_MAINT_RECOVERY_OWNER_UNIT:-}"; then
        rc=1
    fi
    cpamp_maintenance_release_lock
    return "$rc"
}

run_cpamp_database_maintenance_locked() {
    local scheduled="${1:-0}"
    local data_dir db_path backup_dir backup_file backup_tmp timestamp
    local was_active=0 rc=0 status_rc=2

    [[ -f "$CPAMP_BIN" ]] || { error "未找到 ${CPAMP_BIN}。"; return 1; }
    [[ "$(systemctl show "$CPAMP_SERVICE" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] \
        || { error "未找到可用的 ${CPAMP_SERVICE}。"; return 1; }
    id -u cpamp >/dev/null 2>&1 || { error "未找到 cpamp 系统用户。"; return 1; }
    command -v runuser >/dev/null 2>&1 || { error "未找到 runuser，无法以 cpamp 用户执行维护。"; return 1; }
    command -v tar >/dev/null 2>&1 || { error "未安装 tar。"; return 1; }

    if systemctl is-active --quiet "$CPAMP_SERVICE"; then
        was_active=1
        cpamp_database_maintenance_required
        status_rc=$?
        if [[ "$status_rc" == "1" ]]; then
            clear_cpamp_maintenance_schedule
            info "CPAMP 数据库维护状态已经正常，无需停机。"
            return 0
        fi
        if [[ "$status_rc" == "2" && ! -f "$CPAMP_MAINT_PENDING" ]]; then
            warn "无法确认数据库是否需要维护；为避免误停机，本次不执行。"
            [[ -n "$CPAMP_MAINT_LAST_ERROR" ]] && warn "原因：${CPAMP_MAINT_LAST_ERROR}"
            return 2
        fi
        if [[ "$status_rc" == "2" && -f "$CPAMP_MAINT_PENDING" ]]; then
            warn "当前无法复核 /status，但已有待维护标记，将按既定凌晨维护计划继续。"
        fi
    elif [[ ! -f "$CPAMP_MAINT_PENDING" ]]; then
        warn "CPAMP 当前未运行且没有待维护标记，本次不执行。"
        return 0
    fi

    data_dir=$(cpamp_data_directory)
    db_path=$(cpamp_database_path)
    [[ -d "$data_dir" ]] || { error "未找到 CPAMP 数据目录 ${data_dir}。"; return 1; }
    [[ -f "$db_path" ]] || { error "未找到 CPAMP 数据库 ${db_path}。"; return 1; }
    case "$data_dir" in
        "${CPAMP_DIR}"/*) ;;
        *) error "CPAMP 数据目录不在 ${CPAMP_DIR} 内，拒绝自动维护: ${data_dir}"; return 1 ;;
    esac
    case "$data_dir" in
        "${CPAMP_DIR}/backups"|"${CPAMP_DIR}/backups"/*)
            error "CPAMP 数据目录与备份目录重叠，拒绝自动维护: ${data_dir}"
            return 1
            ;;
    esac
    case "$db_path" in
        "$data_dir"/*) ;;
        *) error "CPAMP 数据库不在数据目录内，拒绝自动维护: ${db_path}"; return 1 ;;
    esac

    backup_dir="${CPAMP_DIR}/backups"
    install -d -m 0700 -o root -g root "$backup_dir" \
        || { error "无法创建 CPAMP 维护备份目录。"; return 1; }
    ensure_data_backup_space "$data_dir" "$backup_dir" "CPAMP 维护"

    timestamp=$(backup_stamp)
    backup_file="${backup_dir}/cpamp-maintenance.${timestamp}.tar.gz"
    backup_tmp="${backup_file}.tmp"

    info "准备执行 CPAMP 离线数据库维护，正在停止面板服务..."
    if [[ "$was_active" == "1" ]]; then
        if ! cpamp_maintenance_arm_recovery; then
            error "无法建立 CPAMP 异常恢复状态，已取消维护。"
            return 1
        fi
        if ! systemctl stop "$CPAMP_SERVICE"; then
            error "无法停止 CPAMP 服务，已取消维护。"
            return 1
        fi
    fi
    if systemctl is-active --quiet "$CPAMP_SERVICE"; then
        error "CPAMP 服务仍在运行，已取消维护。"
        return 1
    fi

    info "正在创建维护前一致性数据备份..."
    if ! tar --sparse -czf "$backup_tmp" -C "$(dirname "$data_dir")" "$(basename "$data_dir")" \
        || ! chown root:root "$backup_tmp" \
        || ! chmod 0600 "$backup_tmp" \
        || ! mv -f "$backup_tmp" "$backup_file"; then
        rm -f "$backup_tmp"
        error "CPAMP 维护前备份失败，已取消维护。"
        if [[ "$was_active" == "1" ]]; then
            systemctl start "$CPAMP_SERVICE" >/dev/null 2>&1 || true
        fi
        return 1
    fi

    info "正在执行 cleanup-derived（可能需要一些时间）..."
    if ! runuser -u cpamp -- sh -c 'cd "$1" && exec "$2" cleanup-derived --db-path "$3"' \
        sh "$CPAMP_DIR" "$CPAMP_BIN" "$db_path"; then
        error "CPAMP cleanup-derived 执行失败；备份保留在 ${backup_file}。"
        if [[ "$was_active" == "1" ]]; then
            systemctl start "$CPAMP_SERVICE" >/dev/null 2>&1 || true
        fi
        return 1
    fi

    if [[ "$was_active" == "1" ]]; then
        info "维护完成，正在恢复 CPAMP 服务..."
        if ! systemctl start "$CPAMP_SERVICE" || ! wait_for_cpamp; then
            error "数据库维护已完成，但 CPAMP 未能恢复，请检查：journalctl -u cpamp -n 80 --no-pager"
            return 1
        fi
        cpamp_database_maintenance_required
        status_rc=$?
        if [[ "$status_rc" == "0" ]]; then
            warn "cleanup-derived 已完成，但 CPAMP 仍报告需要维护；保留定时任务，明天凌晨将重试。"
            return 1
        elif [[ "$status_rc" == "2" ]]; then
            warn "cleanup-derived 已成功完成，但当前无法通过 /status 复核；为避免重复停机，本次任务视为完成。"
            [[ -n "$CPAMP_MAINT_LAST_ERROR" ]] && warn "复核原因：${CPAMP_MAINT_LAST_ERROR}"
        fi
    fi

    clear_cpamp_maintenance_schedule
    [[ "$was_active" != "1" ]] || cpamp_maintenance_disarm_recovery || return 1
    info "CPAMP 数据库离线维护完成。备份: ${backup_file}"
    [[ "$scheduled" == "1" ]] && info "凌晨维护任务已自动停用；以后升级若再次需要会重新安排。"
    return "$rc"
}

start_manual_cpamp_maintenance_service() {
    install_cpamp_maintenance_units || {
        error "无法安装受控的 CPAMP 手动维护单元。"
        return 1
    }
    systemctl start "$CPAMP_MAINT_MANUAL_SERVICE"
}

cpamp_maintenance_command() {
    local action="${1:---check}" rc

    case "$action" in
        --check|check)
            check_and_schedule_cpamp_maintenance
            rc=$?
            [[ "$rc" == "0" ]] && show_cpamp_maintenance_timer
            return "$rc"
            ;;
        --diagnose|diagnose)
            cpamp_maintenance_diagnose
            ;;
        --set-admin-key|set-admin-key)
            cpamp_maintenance_set_admin_key
            ;;
        --clear-admin-key|clear-admin-key)
            cpamp_maintenance_clear_admin_key
            ;;
        --schedule|schedule)
            # 2.23 intentionally no longer force-schedules an unverified outage.
            # It is now an alias of --check: only required=true creates the timer.
            check_and_schedule_cpamp_maintenance
            rc=$?
            [[ "$rc" == "0" ]] && show_cpamp_maintenance_timer
            return "$rc"
            ;;
        --force-schedule|force-schedule)
            warn "正在强制安排数据库维护；此模式不会先确认 required=true。"
            schedule_cpamp_maintenance manual || {
                error "无法创建凌晨 CPAMP 维护任务。"
                return 1
            }
            show_cpamp_maintenance_timer
            ;;
        --run-now|run-now)
            start_manual_cpamp_maintenance_service
            ;;
        --run-now-direct)
            require_systemd_unit_invocation --run-now-direct "$CPAMP_MAINT_MANUAL_SERVICE" \
                || return 1
            CPAMP_MAINT_RECOVERY_OWNER_UNIT="$CPAMP_MAINT_MANUAL_SERVICE"
            run_cpamp_database_maintenance 0
            ;;
        --scheduled|--scheduled-direct)
            require_systemd_unit_invocation --scheduled-direct "$CPAMP_MAINT_SERVICE" \
                || return 1
            CPAMP_MAINT_RECOVERY_OWNER_UNIT="$CPAMP_MAINT_SERVICE"
            run_cpamp_database_maintenance 1
            ;;
        --recover-service)
            require_systemd_unit_invocation --recover-service \
                "$CPAMP_MAINT_SERVICE" "$CPAMP_MAINT_MANUAL_SERVICE" || return 1
            if running_in_systemd_unit "$CPAMP_MAINT_SERVICE"; then
                CPAMP_MAINT_RECOVERY_OWNER_UNIT="$CPAMP_MAINT_SERVICE"
            else
                CPAMP_MAINT_RECOVERY_OWNER_UNIT="$CPAMP_MAINT_MANUAL_SERVICE"
            fi
            cpamp_maintenance_recover_service "$CPAMP_MAINT_RECOVERY_OWNER_UNIT"
            ;;
        *)
            error "未知 CPAMP 维护参数: ${action}"
            printf '用法: cpa cpamp-maintenance [--check|--diagnose|--set-admin-key|--clear-admin-key|--schedule|--force-schedule|--run-now]\n'
            return 2
            ;;
    esac
}

rollback_cpamp_update() {
    local backup_file="$1" env_backup="$2" env_was_present="$3"
    local marker_backup="$4" marker_was_present="$5" restore_data="$6"
    local data_dir="$7" data_parent="$8" data_backup="$9"
    local data_was_present="${10}" failed_data="${11}" old_version="${12}"
    local was_active="${13}"
    local rollback_ok=1 can_restore_data=1 service_ok=0

    systemctl stop "$CPAMP_SERVICE" >/dev/null 2>&1 || true
    rm -f "${CPAMP_DIR}/.cpa-manager-plus.new" "${CPAMP_DIR}/.version.new"

    if ! install -m 0755 -o cpamp -g cpamp "$backup_file" \
        "${CPAMP_DIR}/.cpa-manager-plus.rollback" \
        || ! mv -f "${CPAMP_DIR}/.cpa-manager-plus.rollback" "$CPAMP_BIN"; then
        error "恢复 CPAMP 旧二进制失败。"
        rollback_ok=0
    fi

    if [[ "$env_was_present" == "1" ]]; then
        if ! install -m 0600 -o cpamp -g cpamp "$env_backup" "${CPAMP_DIR}/.env"; then
            error "恢复 CPAMP 原环境文件失败。"
            rollback_ok=0
        fi
    elif ! rm -f "${CPAMP_DIR}/.env"; then
        error "清除更新过程中产生的 CPAMP 环境文件失败。"
        rollback_ok=0
    fi

    if [[ "$marker_was_present" == "1" ]]; then
        if ! install -m 0644 -o cpamp -g cpamp "$marker_backup" "${CPAMP_DIR}/.version"; then
            error "恢复 CPAMP 原版本标记失败。"
            rollback_ok=0
        fi
    elif ! rm -f "${CPAMP_DIR}/.version"; then
        error "清除更新过程中产生的 CPAMP 版本标记失败。"
        rollback_ok=0
    fi

    if [[ "$restore_data" == "1" ]]; then
        if [[ -e "$data_dir" || -L "$data_dir" ]]; then
            if ! mv -- "$data_dir" "$failed_data"; then
                error "无法移开 CPAMP 更新失败后的数据目录，未覆盖现有数据。"
                rollback_ok=0
                can_restore_data=0
            else
                warn "CPAMP 更新失败后的数据已保留在 ${failed_data}"
            fi
        fi

        if [[ "$can_restore_data" == "1" && "$data_was_present" == "1" ]]; then
            if [[ ! -f "$data_backup" ]] \
                || ! tar -xzf "$data_backup" -C "$data_parent" \
                || [[ ! -d "$data_dir" ]] \
                || ! chown -R cpamp:cpamp "$data_dir"; then
                error "恢复 CPAMP 更新前的数据备份失败。"
                rollback_ok=0
            fi
        fi
    fi

    if [[ "$was_active" == "1" ]]; then
        if systemctl start "$CPAMP_SERVICE" && wait_for_cpamp; then
            service_ok=1
        else
            error "CPAMP 回滚后仍未恢复，请执行：journalctl -u cpamp -n 80 --no-pager"
        fi
    else
        service_ok=1
    fi

    if [[ "$rollback_ok" == "1" && "$service_ok" == "1" ]]; then
        warn "CPAMP 已成功回滚到原版本 ${old_version}，服务启停状态保持不变。"
        return 0
    fi
    return 1
}

update_cpamp() {
    local assume_yes="${1:-0}"
    local force_reinstall="${2:-0}"
    local arch release latest_version tag asset_name download_url checksum_url current
    local archive checksum_file expected actual extract_dir candidate smoke_output smoke_dir
    local backup_dir backup_file backup_version marker_backup env_backup env_stage env_persistent_backup
    local data_dir data_parent data_name data_backup data_backup_tmp failed_data
    local answer="" timestamp env_was_present=0 marker_was_present=0 data_was_present=0
    local was_active=0

    if [[ ! -d "$CPAMP_DIR" || ! -f "$CPAMP_BIN" ]]; then
        warn "未检测到 ${CPAMP_BIN}，跳过 CPAMP 更新。"
        return 2
    fi
    command -v systemctl >/dev/null 2>&1 || die "未找到 systemctl。"
    command -v curl >/dev/null 2>&1 || die "未安装 curl。"
    command -v jq >/dev/null 2>&1 || die "未安装 jq。"
    command -v tar >/dev/null 2>&1 || die "未安装 tar。"
    command -v sha256sum >/dev/null 2>&1 || die "未安装 sha256sum。"
    id -u cpamp >/dev/null 2>&1 || die "未找到 cpamp 系统用户。"
    [[ "$(systemctl show "$CPAMP_SERVICE" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] \
        || die "未找到可用的 ${CPAMP_SERVICE}，请用菜单 1 重新部署。"

    arch=$(detect_cpamp_release_arch) || die "CPAMP 不支持的 CPU 架构: $(uname -m)"
    current=$(current_cpamp_version)

    info "正在查询 CPAMP 最新可用版本..."
    release=$(fetch_latest_cpamp_release "$arch" 2>/dev/null || true)
    [[ -n "$release" ]] || die "无法从 GitHub 获取适用于 ${arch} 的 CPAMP 安装包。"

    latest_version=$(jq -r '.version' <<< "$release")
    tag=$(jq -r '.tag' <<< "$release")
    asset_name=$(jq -r '.asset_name' <<< "$release")
    download_url=$(jq -r '.url' <<< "$release")
    checksum_url=$(jq -r '.checksum_url' <<< "$release")

    printf '\n  CPAMP 当前版本: %s\n' "$current"
    printf '  CPAMP 最新版本: %s\n' "$latest_version"
    printf '  CPAMP 安装包:   %s\n\n' "$asset_name"

    if [[ "${current#v}" == "${latest_version#v}" && "$force_reinstall" != "1" ]]; then
        info "CPAMP 当前已是最新可用版本，无需更新。"
        if systemctl is-active --quiet "$CPAMP_SERVICE"; then
            check_and_schedule_cpamp_maintenance || true
        fi
        return 0
    fi

    if [[ "$assume_yes" != "1" ]]; then
        read -r -p "确认更新 CPAMP？面板配置和数据会保留 [y/N]: " answer || return 0
        [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消 CPAMP 更新。"; return 0; }
    fi

    UPDATE_TMP=$(mktemp -d /tmp/cpamp-update.XXXXXX) || die "无法创建 CPAMP 更新临时目录。"
    archive="${UPDATE_TMP}/${asset_name}"
    checksum_file="${UPDATE_TMP}/checksums.txt"
    extract_dir="${UPDATE_TMP}/extracted"
    smoke_dir="${UPDATE_TMP}/smoke-data"
    mkdir -p "$extract_dir" "$smoke_dir"

    info "正在下载 CPAMP ${tag}..."
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$archive" "$download_url" || die "CPAMP 安装包下载失败。"
    [[ -n "$checksum_url" ]] || die "CPAMP Release 没有 checksums.txt，已停止更新。"
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 60 \
        -o "$checksum_file" "$checksum_url" || die "CPAMP 校验文件下载失败。"

    expected=$(checksum_for_asset "$checksum_file" "$asset_name")
    actual=$(sha256sum "$archive" | awk '{print tolower($1)}')
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "CPAMP 校验文件中未找到 ${asset_name}。"
    [[ "$actual" == "$expected" ]] || die "CPAMP SHA-256 校验失败。"
    info "CPAMP SHA-256 校验通过。"

    tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$extract_dir" \
        || die "CPAMP 安装包解压失败。"
    candidate=$(find "$extract_dir" -type f -name 'cpa-manager-plus' -print -quit 2>/dev/null || true)
    [[ -n "$candidate" && -s "$candidate" ]] || die "CPAMP 安装包内未找到 cpa-manager-plus。"
    chmod 0755 "$candidate"

    info "正在隔离环境中验证 CPAMP 新二进制..."
    smoke_output=$(timeout --signal=TERM --kill-after=2s 6s env \
        HTTP_ADDR='127.0.0.1:0' \
        USAGE_DATA_DIR="$smoke_dir" \
        CPA_MANAGER_ADMIN_KEY='cpamp-update-smoke-admin' \
        CPA_UPSTREAM_URL="http://127.0.0.1:${CPA_BACKEND_PORT}" \
        CPA_MANAGEMENT_KEY='cpamp-update-smoke-management' \
        USAGE_COLLECTOR_MODE='http' \
        "$candidate" 2>&1 || true)
    if ! grep -q 'cpa-manager-plus listening on' <<< "$smoke_output"; then
        error "CPAMP 新二进制冒烟测试失败，最近输出："
        tail -n 20 <<< "$smoke_output" >&2
        die "CPAMP 新二进制未通过启动验证。"
    fi

    data_dir=$(cpamp_data_directory)
    case "$data_dir" in
        "${CPAMP_DIR}"/*) ;;
        *) die "CPAMP 数据目录不在 ${CPAMP_DIR} 内，拒绝自动迁移: ${data_dir}" ;;
    esac
    case "$data_dir" in
        "${CPAMP_DIR}/backups"|"${CPAMP_DIR}/backups"/*)
            die "CPAMP 数据目录与更新备份目录重叠，拒绝更新: ${data_dir}"
            ;;
    esac
    data_parent=$(dirname "$data_dir")
    data_name=$(basename "$data_dir")
    timestamp=$(backup_stamp)
    backup_version="${current//[^a-zA-Z0-9._-]/_}"
    backup_dir="${CPAMP_DIR}/backups"
    backup_file="${backup_dir}/cpa-manager-plus.${backup_version}.${timestamp}"
    marker_backup="${UPDATE_TMP}/version.marker"
    env_backup="${UPDATE_TMP}/cpamp.env.original"
    env_stage="${UPDATE_TMP}/cpamp.env.compat"
    env_persistent_backup="${backup_dir}/cpamp.env.${timestamp}"
    data_backup="${backup_dir}/cpamp-data.${backup_version}.${timestamp}.tar.gz"
    data_backup_tmp="${data_backup}.tmp"
    failed_data="${backup_dir}/data.failed.${timestamp}"

    install -d -m 0700 -o root -g root "$backup_dir" \
        || die "无法创建 CPAMP 更新备份目录。"
    ensure_data_backup_space "$data_dir" "$backup_dir" "CPAMP"
    cp -a "$CPAMP_BIN" "$backup_file" || die "创建 CPAMP 二进制备份失败。"
    if [[ -f "${CPAMP_DIR}/.version" ]]; then
        cp -a "${CPAMP_DIR}/.version" "$marker_backup" || die "备份 CPAMP 版本标记失败。"
        marker_was_present=1
    fi
    if [[ -f "${CPAMP_DIR}/.env" ]]; then
        env_was_present=1
        cp -a "${CPAMP_DIR}/.env" "$env_backup" || die "备份 CPAMP 环境文件失败。"
        cp -a "${CPAMP_DIR}/.env" "$env_persistent_backup" || die "保存 CPAMP 环境备份失败。"
        chmod 0600 "$env_persistent_backup" || die "设置 CPAMP 环境备份权限失败。"
        prepare_cpamp_env_compat "${CPAMP_DIR}/.env" "$env_stage" \
            || die "生成 CPAMP 新版兼容环境文件失败。"
    fi

    systemctl is-active --quiet "$CPAMP_SERVICE" && was_active=1
    info "正在停止 CPAMP 并创建一致性数据备份..."
    systemctl stop "$CPAMP_SERVICE" || die "无法停止 CPAMP 服务。"
    if [[ -d "$data_dir" ]]; then
        data_was_present=1
        if ! tar --sparse -czf "$data_backup_tmp" -C "$data_parent" "$data_name"; then
            rm -f "$data_backup_tmp"
            if [[ "$was_active" == "1" ]]; then
                systemctl start "$CPAMP_SERVICE" || true
            fi
            die "CPAMP 数据备份失败，旧服务状态已恢复。"
        fi
        if ! mv -f "$data_backup_tmp" "$data_backup" || ! chmod 0600 "$data_backup"; then
            rm -f "$data_backup_tmp" "$data_backup"
            if [[ "$was_active" == "1" ]]; then
                systemctl start "$CPAMP_SERVICE" || true
            fi
            die "保存 CPAMP 数据备份失败，旧服务状态已恢复。"
        fi
    else
        data_backup=""
    fi

    if ! install -m 0755 -o cpamp -g cpamp "$candidate" "${CPAMP_DIR}/.cpa-manager-plus.new" \
        || ! mv -f "${CPAMP_DIR}/.cpa-manager-plus.new" "$CPAMP_BIN"; then
        error "安装 CPAMP 新二进制失败，正在回滚。"
        rollback_cpamp_update "$backup_file" "$env_backup" "$env_was_present" \
            "$marker_backup" "$marker_was_present" 0 "$data_dir" "$data_parent" \
            "$data_backup" "$data_was_present" "$failed_data" "$current" \
            "$was_active" || true
        return 1
    fi
    if [[ -f "$env_stage" ]]; then
        if ! install -m 0600 -o cpamp -g cpamp "$env_stage" "${CPAMP_DIR}/.env"; then
            error "安装 CPAMP 兼容环境文件失败，正在回滚。"
            rollback_cpamp_update "$backup_file" "$env_backup" "$env_was_present" \
                "$marker_backup" "$marker_was_present" 0 "$data_dir" "$data_parent" \
                "$data_backup" "$data_was_present" "$failed_data" "$current" \
                "$was_active" || true
            return 1
        fi
    fi
    if ! (printf '%s\n' "$latest_version" > "${UPDATE_TMP}/cpamp.version" \
        && install -m 0644 -o cpamp -g cpamp "${UPDATE_TMP}/cpamp.version" \
            "${CPAMP_DIR}/.version.new" \
        && mv -f "${CPAMP_DIR}/.version.new" "${CPAMP_DIR}/.version"); then
        error "写入 CPAMP 版本标记失败，正在回滚。"
        rollback_cpamp_update "$backup_file" "$env_backup" "$env_was_present" \
            "$marker_backup" "$marker_was_present" 0 "$data_dir" "$data_parent" \
            "$data_backup" "$data_was_present" "$failed_data" "$current" \
            "$was_active" || true
        return 1
    fi

    info "正在检查 CPAMP 新版本健康状态..."
    if systemctl start "$CPAMP_SERVICE" && wait_for_cpamp; then
        check_and_schedule_cpamp_maintenance || true
        if [[ "$was_active" == "1" ]] || systemctl stop "$CPAMP_SERVICE"; then
            info "CPAMP 更新完成：${current} -> ${latest_version}"
            [[ "$was_active" == "0" ]] && info "CPAMP 更新前处于停止状态，现已恢复为停止。"
            info "CPAMP 二进制备份: ${backup_file}"
            [[ -n "$data_backup" ]] && info "CPAMP 数据备份: ${data_backup}"
            return 0
        fi
        error "新版验证通过，但无法恢复 CPAMP 原停止状态。"
    fi

    error "CPAMP 新版本未能正常启动，正在自动回滚二进制、环境和数据..."
    rollback_cpamp_update "$backup_file" "$env_backup" "$env_was_present" \
        "$marker_backup" "$marker_was_present" 1 "$data_dir" "$data_parent" \
        "$data_backup" "$data_was_present" "$failed_data" "$current" \
        "$was_active" || true
    return 1
}

update_all_components() {
    admission_with_lock update_all_components_locked "$@"
}

update_all_components_locked() {
    local assume_yes="${1:-0}" answer="" cpa_ok=0 cpamp_ok=0 cpamp_skipped=0 cpamp_rc=0

    admission_load_settings || return 1
    if [[ "$assume_yes" != "1" ]]; then
        printf '\n将依次检查并更新 CPA 网关与 CPAMP 面板。\n'
        read -r -p '配置、授权和面板数据都会保留，确认继续 [y/N]: ' answer || return 0
        [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消更新。"; return 0; }
    fi

    printf '\n%b[1/2] 更新 CPA 网关%b\n' "$BOLD" "$NC"
    if ( UPDATE_TMP=""; trap cleanup_update_tmp EXIT; update_cpa 1 ); then
        cpa_ok=1
    else
        error "CPA 更新未完成；已继续检查 CPAMP。"
    fi

    printf '\n%b[2/2] 更新 CPAMP 面板%b\n' "$BOLD" "$NC"
    ( UPDATE_TMP=""; trap cleanup_update_tmp EXIT; update_cpamp 1 )
    cpamp_rc=$?
    case "$cpamp_rc" in
        0) cpamp_ok=1 ;;
        2) cpamp_skipped=1 ;;
        *) error "CPAMP 更新未完成。" ;;
    esac

    printf '\n%b组件更新结果%b\n' "$BOLD" "$NC"
    printf '  CPA:   %s\n' "$([[ "$cpa_ok" == "1" ]] && printf '正常' || printf '失败/已回滚')"
    if [[ "$cpamp_ok" == "1" ]]; then
        printf '  CPAMP: 正常\n'
    elif [[ "$cpamp_skipped" == "1" ]]; then
        printf '  CPAMP: 未安装/已跳过\n'
    else
        printf '  CPAMP: 失败/已回滚\n'
    fi
    if systemctl is-active --quiet "$CPA_SERVICE"; then
        if wait_for_all_admission; then
            info "更新后准入连通性正常；持久并发配置保持不变。"
        else
            error "更新后准入连通性检查失败，请检查准入单元；未修改并发配置。"
            cpa_ok=0
        fi
    fi
    [[ "$cpa_ok" == "1" && ( "$cpamp_ok" == "1" || "$cpamp_skipped" == "1" ) ]]
}

ensure_deploy_tmp() {
    if [[ -z "${DEPLOY_TMP:-}" || ! -d "$DEPLOY_TMP" ]]; then
        DEPLOY_TMP=$(mktemp -d /tmp/cpa-deploy.XXXXXX) || die "无法创建部署临时目录。"
    fi
}

deployment_preflight() {
    local available_kib disk_target="/"

    [[ "$(uname -s)" == "Linux" ]] || die "部署功能仅支持 Linux。"
    command -v systemctl >/dev/null 2>&1 || die "未找到 systemd/systemctl。"
    command -v apt-get >/dev/null 2>&1 || die "仅支持使用 apt 的 Debian/Ubuntu。"
    if [[ -r /etc/os-release ]] \
        && ! grep -Eiq '^(ID|ID_LIKE)=.*(debian|ubuntu)' /etc/os-release; then
        die "当前系统不是受支持的 Debian/Ubuntu。"
    fi
    detect_release_arch >/dev/null \
        || die "不支持的 CPU 架构: $(uname -m)"

    [[ -d /opt ]] && disk_target="/opt"
    available_kib=$(df -Pk "$disk_target" 2>/dev/null | awk 'NR == 2 {print $4}' || true)
    if [[ "$available_kib" =~ ^[0-9]+$ ]] && (( available_kib < 524288 )); then
        die "根分区可用空间不足 512 MiB，拒绝开始部署。"
    fi
}

install_deployment_dependencies() {
    local -a required_commands=(curl jq tar gzip sha256sum openssl gpg timeout find readlink \
        getent useradd groupadd usermod flock python3 ss)
    local -a packages=(ca-certificates curl jq tar gzip coreutils openssl gnupg \
        findutils passwd util-linux python3-minimal iproute2 \
        debian-keyring debian-archive-keyring apt-transport-https)
    local command_name missing=0

    for command_name in "${required_commands[@]}"; do
        command -v "$command_name" >/dev/null 2>&1 || missing=1
    done
    if [[ "$missing" == "0" ]]; then
        info "部署依赖已齐全。"
        return 0
    fi

    info "正在更新软件包索引并安装部署依赖..."
    apt-get update -y || die "apt-get update 失败，请检查软件源和网络。"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" \
        || die "部署依赖安装失败。"
}

generate_deployment_secret() {
    local prefix="$1"
    local random_value=""

    if command -v openssl >/dev/null 2>&1; then
        random_value=$(openssl rand -hex 16 2>/dev/null || true)
    fi
    if [[ ! "$random_value" =~ ^[0-9a-fA-F]{32}$ && -r /dev/urandom ]]; then
        random_value=$(head -c 16 /dev/urandom 2>/dev/null \
            | od -An -tx1 | tr -d ' \n' || true)
    fi
    [[ "$random_value" =~ ^[0-9a-fA-F]{32}$ ]] || {
        error "无法从安全随机源生成密钥，已停止；请检查 openssl 或 /dev/urandom。"
        return 1
    }
    printf '%s%s\n' "$prefix" "$random_value"
}

valid_deployment_key() {
    local value="$1"
    [[ ${#value} -ge 8 && ${#value} -le 256 \
        && "$value" =~ ^[A-Za-z0-9._~:/+=@-]+$ ]]
}

prompt_deployment_key() {
    local variable_name="$1" label="$2" default_value="${3:-}" value=""

    while true; do
        if [[ -n "$default_value" ]]; then
            read -r -s -p "${label} [隐藏输入；留空使用自动生成的密钥]: " value \
                || { printf '\n' >&2; return 1; }
            printf '\n' >&2
            value="${value:-$default_value}"
        else
            read -r -s -p "${label} [隐藏输入]: " value \
                || { printf '\n' >&2; return 1; }
            printf '\n' >&2
        fi
        if valid_deployment_key "$value"; then
            printf -v "$variable_name" '%s' "$value"
            return 0
        fi
        warn "仅允许 8-256 位字母、数字及 . _ ~ : / + = @ -。"
    done
}

valid_deployment_domain() {
    local value="$1" label
    local -a labels=()

    [[ -z "$value" ]] && return 0
    [[ ${#value} -le 253 && "$value" =~ ^[A-Za-z0-9.-]+$ \
        && "$value" != .* && "$value" != *. && "$value" != *..* ]] || return 1
    IFS='.' read -r -a labels <<< "$value"
    for label in "${labels[@]}"; do
        [[ ${#label} -le 63 \
            && "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] \
            || return 1
    done
}

deployment_state_value() {
    local key="$1"

    [[ -f "$DEPLOY_STATE" ]] || return 0
    awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2); exit}' \
        "$DEPLOY_STATE"
}

existing_cpa_management_key() {
    [[ -f "${CPA_DIR}/config.yaml" ]] || return 0
    awk '
        /^[^[:space:]]/ { in_remote = ($0 ~ /^remote-management:[[:space:]]*$/) }
        in_remote && /^[[:space:]]+secret-key:[[:space:]]*/ {
            value = $0
            sub(/^[^:]+:[[:space:]]*/, "", value)
            gsub(/^"|"$/, "", value)
            print value
            exit
        }
    ' "${CPA_DIR}/config.yaml"
}

collect_deployment_inputs() {
    local need_cpa="$1" need_cpamp="$2" need_caddy="$3"
    local value default_value existing_key

    if [[ "$need_caddy" == "1" ]]; then
        default_value=$(deployment_state_value DOMAIN)
        while true; do
            if [[ -n "$default_value" ]]; then
                read -r -p "公网域名 [当前: ${default_value}，输入 - 改用 HTTP/IP]: " value \
                    || return 1
                if [[ "$value" == "-" ]]; then
                    DEPLOY_DOMAIN=""
                else
                    DEPLOY_DOMAIN="${value:-$default_value}"
                fi
            else
                read -r -p '公网域名（可留空，使用 HTTP/IP）: ' value || return 1
                DEPLOY_DOMAIN="$value"
            fi
            DEPLOY_DOMAIN="${DEPLOY_DOMAIN//[[:space:]]/}"
            valid_deployment_domain "$DEPLOY_DOMAIN" && break
            warn "域名格式无效；不要包含 http://、端口或路径。"
        done
    fi

    if [[ "$need_cpa" == "1" ]]; then
        default_value=$(generate_deployment_secret 'sk-cpa-') || return 1
        prompt_deployment_key DEPLOY_CPA_API_KEY '客户端 API Key' \
            "$default_value" || return 1
        default_value=$(generate_deployment_secret 'mgmt-') || return 1
        prompt_deployment_key DEPLOY_CPA_MGMT_KEY 'CPA 管理密钥' \
            "$default_value" || return 1
    fi

    if [[ "$need_cpamp" == "1" ]]; then
        if [[ -z "$DEPLOY_CPA_MGMT_KEY" ]]; then
            existing_key=$(existing_cpa_management_key)
            if valid_deployment_key "$existing_key"; then
                DEPLOY_CPA_MGMT_KEY="$existing_key"
                info "已从现有 CPA 配置读取管理密钥，将用于连接 CPAMP。"
            else
                prompt_deployment_key DEPLOY_CPA_MGMT_KEY \
                    '现有 CPA 管理密钥（必须与 config.yaml 一致）' || return 1
            fi
        fi
        default_value=$(generate_deployment_secret 'admin-') || return 1
        prompt_deployment_key DEPLOY_CPAMP_ADMIN_KEY 'CPAMP 面板管理密钥' \
            "$default_value" || return 1
    fi
}

save_deployment_credentials() {
    local staged variable key value

    [[ -n "$DEPLOY_CPA_API_KEY" || -n "$DEPLOY_CPA_MGMT_KEY" \
        || -n "$DEPLOY_CPAMP_ADMIN_KEY" ]] || return 0
    if [[ -L "$DEPLOY_CREDENTIALS_FILE" \
        || ( -e "$DEPLOY_CREDENTIALS_FILE" && ! -f "$DEPLOY_CREDENTIALS_FILE" ) ]]; then
        error "初始凭据记录不是普通文件，拒绝覆盖。"
        return 1
    fi
    ensure_deploy_tmp
    staged="${DEPLOY_TMP}/deployment-credentials.conf"
    printf '# Private initial/last-entered credentials; never publish.\n' > "$staged" \
        || return 1
    for variable in DEPLOY_CPA_API_KEY DEPLOY_CPA_MGMT_KEY DEPLOY_CPAMP_ADMIN_KEY; do
        key="${variable#DEPLOY_}"
        value="${!variable}"
        if [[ -z "$value" && -f "$DEPLOY_CREDENTIALS_FILE" ]]; then
            value=$(awk -F= -v key="$key" \
                '$1 == key {print substr($0, length(key) + 2); exit}' "$DEPLOY_CREDENTIALS_FILE")
        fi
        [[ -n "$value" ]] || continue
        valid_deployment_key "$value" || {
            error "初始凭据记录中的 ${key} 格式无效。"
            return 1
        }
        printf '%s=%s\n' "$key" "$value" >> "$staged" || return 1
    done
    if ! chmod 0600 "$staged" \
        || ! admission_atomic_install "$staged" "$DEPLOY_CREDENTIALS_FILE" 0600 root root; then
        error "无法安全保存初始凭据，已停止部署。"
        return 1
    fi
}

write_deployment_state() {
    ensure_deploy_tmp
    printf 'DOMAIN=%s\nRESOURCE_PROFILE=%s\nUPDATED_AT=%s\n' "$DEPLOY_DOMAIN" \
        "$RESOURCE_PROFILE" "$(date '+%Y-%m-%d %H:%M:%S %Z')" \
        > "${DEPLOY_TMP}/cpa-deploy.conf"
    install -m 0600 -o root -g root "${DEPLOY_TMP}/cpa-deploy.conf" "$DEPLOY_STATE" \
        || die "写入部署状态文件失败。"
}

persist_resource_profile() {
    local tmp updated_at

    tmp=$(mktemp /tmp/cpa-deploy-state.XXXXXX) || return 1
    updated_at=$(date '+%Y-%m-%d %H:%M:%S %Z')
    if [[ -f "$DEPLOY_STATE" ]]; then
        awk -v profile="$RESOURCE_PROFILE" -v updated_at="$updated_at" '
            BEGIN { profile_seen = 0; updated_seen = 0 }
            /^RESOURCE_PROFILE=/ {
                print "RESOURCE_PROFILE=" profile
                profile_seen = 1
                next
            }
            /^UPDATED_AT=/ {
                print "UPDATED_AT=" updated_at
                updated_seen = 1
                next
            }
            { print }
            END {
                if (!profile_seen) print "RESOURCE_PROFILE=" profile
                if (!updated_seen) print "UPDATED_AT=" updated_at
            }
        ' "$DEPLOY_STATE" > "$tmp" || { rm -f "$tmp"; return 1; }
    else
        printf 'DOMAIN=%s\nRESOURCE_PROFILE=%s\nUPDATED_AT=%s\n' \
            "${DEPLOY_DOMAIN:-}" "$RESOURCE_PROFILE" "$updated_at" > "$tmp" \
            || { rm -f "$tmp"; return 1; }
    fi
    install -m 0600 -o root -g root "$tmp" "$DEPLOY_STATE" \
        || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
}

fail2ban_state_value() {
    local key="$1"

    [[ -f "$FAIL2BAN_STATE" ]] || return 0
    awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2); exit}' \
        "$FAIL2BAN_STATE"
}

load_fail2ban_settings() {
    local value ssh_client=""

    F2B_BANTIME=86400
    F2B_FINDTIME=600
    F2B_MAXRETRY=5
    F2B_IGNOREIPS="127.0.0.1/8 ::1"

    if [[ -f "$FAIL2BAN_STATE" ]]; then
        value=$(fail2ban_state_value BANTIME)
        if [[ "$value" == "-1" ]]; then
            F2B_BANTIME=-1
        elif [[ "$value" =~ ^[0-9]+$ ]]; then
            value=$((10#$value))
            (( value >= 1 && value <= 315360000 )) && F2B_BANTIME="$value"
        fi
        value=$(fail2ban_state_value FINDTIME)
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            value=$((10#$value))
            (( value >= 1 && value <= 315360000 )) && F2B_FINDTIME="$value"
        fi
        value=$(fail2ban_state_value MAXRETRY)
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            value=$((10#$value))
            (( value >= 1 && value <= 100 )) && F2B_MAXRETRY="$value"
        fi
        value=$(fail2ban_state_value IGNOREIPS)
        if [[ -n "$value" && "$value" =~ ^[0-9A-Fa-f:./[:space:]]+$ ]]; then
            F2B_IGNOREIPS="$value"
        fi
    elif [[ -n "${SSH_CONNECTION:-}" ]]; then
        ssh_client="${SSH_CONNECTION%% *}"
        if [[ "$ssh_client" =~ ^[0-9A-Fa-f:.]+$ \
            && " ${F2B_IGNOREIPS} " != *" ${ssh_client} "* ]]; then
            F2B_IGNOREIPS+=" ${ssh_client}"
        fi
    fi
}

prepare_fail2ban_files() {
    local target_dir="$1"

    mkdir -p "$target_dir" || return 1
    cat > "${target_dir}/cpa-caddy-filter.conf" <<'EOF'
[Definition]
failregex = ^.*"remote_ip"\s*:\s*"<HOST>".*"uri"\s*:\s*"/(?:management\.html|v0/management(?:/[^\"?]*)?)(?:\?[^\"]*)?".*"status"\s*:\s*404(?:,|}).*$
            ^.*"remote_ip"\s*:\s*"<HOST>".*"status"\s*:\s*(?:401|403)(?:,|}).*$
ignoreregex =
datepattern = "ts"\s*:\s*{EPOCH}
EOF

    cat > "${target_dir}/cpa-caddy-jail.conf" <<EOF
[${FAIL2BAN_JAIL_NAME}]
enabled = true
filter = cpa-caddy
logpath = ${CADDY_LOG_DIR}/access.log
backend = auto
port = http,https
protocol = tcp
usedns = no
maxretry = ${F2B_MAXRETRY}
findtime = ${F2B_FINDTIME}
bantime = ${F2B_BANTIME}
ignoreip = ${F2B_IGNOREIPS}
EOF

    cat > "${target_dir}/cpa-retention.conf" <<'EOF'
[Definition]
dbpurgeage = 315360000
EOF

    cat > "${target_dir}/cpa-fail2ban.conf" <<EOF
BANTIME=${F2B_BANTIME}
FINDTIME=${F2B_FINDTIME}
MAXRETRY=${F2B_MAXRETRY}
IGNOREIPS=${F2B_IGNOREIPS}
UPDATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
EOF
}

restore_fail2ban_file() {
    local target="$1" backup="$2" existed="$3"

    if [[ "$existed" == "1" ]]; then
        cp -a "$backup" "$target" || return 1
    else
        rm -f "$target" || return 1
    fi
}

apply_fail2ban_settings() {
    local apply_dir filter_old=0 jail_old=0 db_old=0 state_old=0 apply_ok=1 restore_ok=1
    local was_active=0 was_enabled=0

    command -v fail2ban-client >/dev/null 2>&1 || die "未安装 Fail2Ban。"
    command -v caddy >/dev/null 2>&1 || die "未安装 Caddy，无法启用 CPA Web 防护。"
    id -u caddy >/dev/null 2>&1 || die "未找到 caddy 系统用户。"
    ensure_deploy_tmp
    apply_dir=$(mktemp -d "${DEPLOY_TMP}/fail2ban-apply.XXXXXX") \
        || die "无法创建 Fail2Ban 临时目录。"
    prepare_fail2ban_files "$apply_dir" || die "生成 Fail2Ban 配置失败。"
    systemctl is-active --quiet fail2ban && was_active=1
    systemctl is-enabled --quiet fail2ban 2>/dev/null && was_enabled=1

    install -d -m 0755 -o root -g root "$(dirname "$FAIL2BAN_FILTER_FILE")" \
        "$(dirname "$FAIL2BAN_JAIL_FILE")" "$(dirname "$FAIL2BAN_DB_FILE")" \
        || die "创建 Fail2Ban 配置目录失败。"
    install -d -m 0750 -o caddy -g caddy "$CADDY_LOG_DIR" \
        || die "创建 Caddy 日志目录失败。"
    if [[ ! -e "${CADDY_LOG_DIR}/access.log" ]]; then
        install -m 0640 -o caddy -g caddy /dev/null "${CADDY_LOG_DIR}/access.log" \
            || die "创建 Caddy access.log 失败。"
    else
        if ! chown caddy:caddy "${CADDY_LOG_DIR}/access.log" \
            || ! chmod 0640 "${CADDY_LOG_DIR}/access.log"; then
            die "修正 Caddy access.log 权限失败。"
        fi
    fi

    if [[ -f "$FAIL2BAN_FILTER_FILE" ]]; then
        filter_old=1
        cp -a "$FAIL2BAN_FILTER_FILE" "${apply_dir}/filter.original" || die "备份 Fail2Ban filter 失败。"
    fi
    if [[ -f "$FAIL2BAN_JAIL_FILE" ]]; then
        jail_old=1
        cp -a "$FAIL2BAN_JAIL_FILE" "${apply_dir}/jail.original" || die "备份 Fail2Ban jail 失败。"
    fi
    if [[ -f "$FAIL2BAN_STATE" ]]; then
        state_old=1
        cp -a "$FAIL2BAN_STATE" "${apply_dir}/state.original" || die "备份 Fail2Ban 设置失败。"
    fi
    if [[ -f "$FAIL2BAN_DB_FILE" ]]; then
        db_old=1
        cp -a "$FAIL2BAN_DB_FILE" "${apply_dir}/db.original" || die "备份 Fail2Ban 数据保留配置失败。"
    fi

    install -m 0644 -o root -g root "${apply_dir}/cpa-caddy-filter.conf" \
        "$FAIL2BAN_FILTER_FILE" || apply_ok=0
    install -m 0644 -o root -g root "${apply_dir}/cpa-caddy-jail.conf" \
        "$FAIL2BAN_JAIL_FILE" || apply_ok=0
    install -m 0644 -o root -g root "${apply_dir}/cpa-retention.conf" \
        "$FAIL2BAN_DB_FILE" || apply_ok=0
    install -m 0600 -o root -g root "${apply_dir}/cpa-fail2ban.conf" \
        "$FAIL2BAN_STATE" || apply_ok=0

    if [[ "$apply_ok" == "1" ]]; then
        fail2ban-client -t >/dev/null 2>&1 || apply_ok=0
    fi
    if [[ "$apply_ok" == "1" ]]; then
        systemctl enable fail2ban >/dev/null 2>&1 || apply_ok=0
        if [[ "$apply_ok" == "1" ]]; then
            if [[ "$was_active" == "1" ]]; then
                fail2ban-client reload >/dev/null 2>&1 || apply_ok=0
            else
                systemctl start fail2ban || apply_ok=0
            fi
        fi
    fi
    if [[ "$apply_ok" == "1" ]]; then
        fail2ban-client status "$FAIL2BAN_JAIL_NAME" >/dev/null 2>&1 || apply_ok=0
    fi
    if [[ "$apply_ok" == "1" ]]; then
        info "Fail2Ban CPA 防护配置已生效。"
        return 0
    fi

    error "Fail2Ban 新设置未能生效，正在恢复原配置..."
    restore_fail2ban_file "$FAIL2BAN_FILTER_FILE" "${apply_dir}/filter.original" "$filter_old" \
        || restore_ok=0
    restore_fail2ban_file "$FAIL2BAN_JAIL_FILE" "${apply_dir}/jail.original" "$jail_old" \
        || restore_ok=0
    restore_fail2ban_file "$FAIL2BAN_DB_FILE" "${apply_dir}/db.original" "$db_old" \
        || restore_ok=0
    restore_fail2ban_file "$FAIL2BAN_STATE" "${apply_dir}/state.original" "$state_old" \
        || restore_ok=0
    if [[ "$was_active" == "1" ]]; then
        fail2ban-client reload >/dev/null 2>&1 \
            || systemctl restart fail2ban >/dev/null 2>&1 \
            || restore_ok=0
    else
        systemctl stop fail2ban >/dev/null 2>&1 || restore_ok=0
    fi
    restore_service_enablement fail2ban "$was_enabled" || restore_ok=0
    [[ "$restore_ok" == "1" ]] \
        || error "Fail2Ban 配置回滚不完整，请检查 /etc/fail2ban。"
    return 1
}

initialize_fail2ban_security() {
    load_fail2ban_settings
    apply_fail2ban_settings
}

install_fail2ban_package() {
    if command -v fail2ban-client >/dev/null 2>&1; then
        return 0
    fi
    info "正在安装 Fail2Ban..."
    apt-get update -y || die "apt-get update 失败，无法安装 Fail2Ban。"
    DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban \
        || die "Fail2Ban 安装失败。"
}

parse_fail2ban_duration() {
    local input="${1,,}" number unit multiplier seconds

    [[ "$input" == "-1" ]] && { printf '%s\n' '-1'; return 0; }
    [[ "$input" =~ ^([1-9][0-9]{0,7})([smhdw]?)$ ]] || return 1
    number="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]:-s}"
    case "$unit" in
        s) multiplier=1 ;;
        m) multiplier=60 ;;
        h) multiplier=3600 ;;
        d) multiplier=86400 ;;
        w) multiplier=604800 ;;
        *) return 1 ;;
    esac
    seconds=$((number * multiplier))
    (( seconds >= 1 && seconds <= 315360000 )) || return 1
    printf '%s\n' "$seconds"
}

format_fail2ban_duration() {
    local seconds="$1"

    if [[ "$seconds" == "-1" ]]; then
        printf '永久'
    elif (( seconds % 86400 == 0 )); then
        printf '%s 天' "$((seconds / 86400))"
    elif (( seconds % 3600 == 0 )); then
        printf '%s 小时' "$((seconds / 3600))"
    elif (( seconds % 60 == 0 )); then
        printf '%s 分钟' "$((seconds / 60))"
    else
        printf '%s 秒' "$seconds"
    fi
}

ensure_fail2ban_management_ready() {
    local answer=""

    if ! command -v fail2ban-client >/dev/null 2>&1; then
        warn "尚未安装 Fail2Ban。"
        read -r -p '现在安装并配置 CPA Web 防护 [y/N]: ' answer || return 1
        [[ "$answer" =~ ^[Yy]$ ]] || return 1
        deployment_preflight
        install_fail2ban_package
    fi
    command -v caddy >/dev/null 2>&1 \
        || { error "未安装 Caddy，请先选择菜单 1 完整部署。"; return 1; }

    if ! fail2ban-client status "$FAIL2BAN_JAIL_NAME" >/dev/null 2>&1; then
        warn "CPA 专用 Fail2Ban jail 尚未启用。"
        read -r -p '现在按默认参数创建并启用 [y/N]: ' answer || return 1
        [[ "$answer" =~ ^[Yy]$ ]] || return 1
        initialize_fail2ban_security || return 1
    else
        load_fail2ban_settings
    fi
}

show_fail2ban_status() {
    local banned_ips=""

    load_fail2ban_settings
    printf '\n%bFail2Ban CPA 防护状态%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  jail:          %s\n' "$FAIL2BAN_JAIL_NAME"
    printf '  封禁时长:      %s (%s 秒)\n' \
        "$(format_fail2ban_duration "$F2B_BANTIME")" "$F2B_BANTIME"
    printf '  统计窗口:      %s (%s 秒)\n' \
        "$(format_fail2ban_duration "$F2B_FINDTIME")" "$F2B_FINDTIME"
    printf '  触发次数:      %s 次\n' "$F2B_MAXRETRY"
    printf '  白名单:        %s\n' "$F2B_IGNOREIPS"
    banned_ips=$(fail2ban-client get "$FAIL2BAN_JAIL_NAME" banip 2>/dev/null || true)
    printf '  当前黑名单:    %s\n' "${banned_ips:-无}"
    printf '%s\n' '--------------------------------------------------'
    fail2ban-client status "$FAIL2BAN_JAIL_NAME" 2>/dev/null | sed 's/^/  /' || true
    printf '\n'
}

fail2ban_ban_ip() {
    local ip=""

    read -r -p '请输入要加入黑名单的 IP: ' ip || return 1
    [[ -n "$ip" && "$ip" != *[[:space:]]* ]] \
        || { warn "IP 不能为空或包含空格。"; return 1; }
    if fail2ban-client set "$FAIL2BAN_JAIL_NAME" banip "$ip" >/dev/null; then
        info "已将 ${ip} 加入黑名单，封禁时长使用当前 bantime。"
    else
        error "加入黑名单失败，请检查 IP 格式。"
        return 1
    fi
}

fail2ban_unban_ip() {
    local ip=""

    read -r -p '请输入要从黑名单移除的 IP: ' ip || return 1
    [[ -n "$ip" && "$ip" != *[[:space:]]* ]] \
        || { warn "IP 不能为空或包含空格。"; return 1; }
    if fail2ban-client set "$FAIL2BAN_JAIL_NAME" unbanip "$ip" >/dev/null; then
        info "已解除 ${ip} 的封禁。"
    else
        error "解除封禁失败；该 IP 可能不在当前黑名单中。"
        return 1
    fi
}

configure_fail2ban_bantime() {
    local input="" seconds

    load_fail2ban_settings
    printf '当前封禁时长: %s\n' "$(format_fail2ban_duration "$F2B_BANTIME")"
    read -r -p '输入新时长（例如 30m、6h、1d、2w，-1 为永久）: ' input || return 1
    if ! seconds=$(parse_fail2ban_duration "$input"); then
        warn "时长格式无效，支持 s/m/h/d/w，最大 10 年。"
        return 1
    fi
    F2B_BANTIME="$seconds"
    if apply_fail2ban_settings; then
        info "封禁时长已调整为 $(format_fail2ban_duration "$F2B_BANTIME")。"
    else
        load_fail2ban_settings
        return 1
    fi
}

configure_fail2ban_trigger() {
    local retry_input="" window_input="" window_seconds

    load_fail2ban_settings
    printf '当前条件: %s 秒内失败 %s 次\n' "$F2B_FINDTIME" "$F2B_MAXRETRY"
    read -r -p '输入触发次数 [1-100]: ' retry_input || return 1
    [[ "$retry_input" =~ ^[0-9]+$ ]] \
        || { warn "触发次数必须是 1-100。"; return 1; }
    retry_input=$((10#$retry_input))
    (( retry_input >= 1 && retry_input <= 100 )) \
        || { warn "触发次数必须是 1-100。"; return 1; }
    read -r -p '输入统计窗口（例如 10m、1h、1d）: ' window_input || return 1
    if ! window_seconds=$(parse_fail2ban_duration "$window_input") \
        || [[ "$window_seconds" == "-1" ]]; then
        warn "统计窗口格式无效，不能使用永久值。"
        return 1
    fi
    F2B_MAXRETRY="$retry_input"
    F2B_FINDTIME="$window_seconds"
    if apply_fail2ban_settings; then
        info "触发条件已调整为 $(format_fail2ban_duration "$F2B_FINDTIME") 内 ${F2B_MAXRETRY} 次。"
    else
        load_fail2ban_settings
        return 1
    fi
}

fail2ban_whitelist_add() {
    local ip=""

    load_fail2ban_settings
    read -r -p '输入要加入白名单的 IP 或 CIDR: ' ip || return 1
    [[ -n "$ip" && "$ip" != *[[:space:]]* \
        && "$ip" =~ ^[0-9A-Fa-f:./]+$ ]] \
        || { warn "白名单值格式无效。"; return 1; }
    if [[ " ${F2B_IGNOREIPS} " == *" ${ip} "* ]]; then
        info "${ip} 已在白名单中。"
        return 0
    fi
    F2B_IGNOREIPS+=" ${ip}"
    if apply_fail2ban_settings; then
        fail2ban-client set "$FAIL2BAN_JAIL_NAME" unbanip "$ip" >/dev/null 2>&1 || true
        info "已将 ${ip} 加入白名单。"
    else
        load_fail2ban_settings
        return 1
    fi
}

fail2ban_whitelist_remove() {
    local ip="" item new_list=""

    load_fail2ban_settings
    printf '当前白名单: %s\n' "$F2B_IGNOREIPS"
    read -r -p '输入要移出白名单的 IP 或 CIDR: ' ip || return 1
    if [[ "$ip" == "127.0.0.1/8" || "$ip" == "::1" ]]; then
        warn "本机回环地址是强制安全白名单，不能删除。"
        return 1
    fi
    [[ " ${F2B_IGNOREIPS} " == *" ${ip} "* ]] \
        || { warn "${ip} 不在白名单中。"; return 1; }
    for item in $F2B_IGNOREIPS; do
        [[ "$item" == "$ip" ]] || new_list+="${new_list:+ }${item}"
    done
    F2B_IGNOREIPS="$new_list"
    if apply_fail2ban_settings; then
        info "已将 ${ip} 移出白名单。"
    else
        load_fail2ban_settings
        return 1
    fi
}

fail2ban_whitelist_menu() {
    local choice=""

    while true; do
        load_fail2ban_settings
        printf '\n%bFail2Ban 白名单管理%b\n' "$BOLD" "$NC"
        printf '  当前白名单: %s\n' "$F2B_IGNOREIPS"
        printf '  1. 添加 IP/CIDR 到白名单\n'
        printf '  2. 从白名单删除 IP/CIDR\n'
        printf '  0. 返回\n'
        if ! read -r -p '请选择 [0-2]: ' choice; then
            return 0
        fi
        case "$choice" in
            1) fail2ban_whitelist_add; pause_menu ;;
            2) fail2ban_whitelist_remove; pause_menu ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项，请重新输入。" ;;
        esac
    done
}

fail2ban_management_menu() {
    local choice=""

    ensure_fail2ban_management_ready || return 1
    while true; do
        printf '\n%bFail2Ban 安全管理%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 查看状态与当前黑名单\n'
        printf '  2. 手动添加黑名单 IP\n'
        printf '  3. 从黑名单解除 IP\n'
        printf '  4. 调整封禁时长\n'
        printf '  5. 调整触发次数与统计窗口\n'
        printf '  6. 白名单管理\n'
        printf '  0. 返回主菜单\n'
        printf '%s\n' '--------------------------------------------------'
        if ! read -r -p '请选择 [0-6]: ' choice; then
            return 0
        fi
        case "$choice" in
            1) show_fail2ban_status; pause_menu ;;
            2) fail2ban_ban_ip; pause_menu ;;
            3) fail2ban_unban_ip; pause_menu ;;
            4) configure_fail2ban_bantime; pause_menu ;;
            5) configure_fail2ban_trigger; pause_menu ;;
            6) fail2ban_whitelist_menu ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项，请重新输入。" ;;
        esac
    done
}

stage_cpa_for_deployment() {
    local arch release tag download_url checksum_url archive checksum_file extract_dir
    local expected actual candidate candidate_line candidate_version

    ensure_deploy_tmp
    arch=$(detect_release_arch) || die "不支持的 CPU 架构: $(uname -m)"
    info "正在查询 CPA 最新可用版本..."
    release=$(fetch_latest_release "$arch" 2>/dev/null || true)
    [[ -n "$release" ]] || die "无法从 GitHub 获取适用于 ${arch} 的 CPA 安装包。"

    DEPLOY_CPA_VERSION=$(jq -r '.version' <<< "$release")
    tag=$(jq -r '.tag' <<< "$release")
    DEPLOY_CPA_ASSET=$(jq -r '.asset_name' <<< "$release")
    download_url=$(jq -r '.url' <<< "$release")
    checksum_url=$(jq -r '.checksum_url' <<< "$release")
    extract_dir="${DEPLOY_TMP}/cpa-extracted"
    archive="${DEPLOY_TMP}/${DEPLOY_CPA_ASSET}"
    checksum_file="${DEPLOY_TMP}/cpa-checksums.txt"
    mkdir -p "$extract_dir" || die "无法创建 CPA 解压目录。"

    printf '  CPA 版本: %s\n  安装包:   %s\n' "$DEPLOY_CPA_VERSION" "$DEPLOY_CPA_ASSET"
    info "正在下载 CPA ${tag}..."
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$archive" "$download_url" || die "CPA 安装包下载失败。"
    [[ -n "$checksum_url" ]] || die "CPA Release 没有 checksums.txt。"
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 60 \
        -o "$checksum_file" "$checksum_url" || die "CPA 校验文件下载失败。"

    expected=$(checksum_for_asset "$checksum_file" "$DEPLOY_CPA_ASSET")
    actual=$(sha256sum "$archive" | awk '{print tolower($1)}')
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] \
        || die "CPA 校验文件中未找到 ${DEPLOY_CPA_ASSET}。"
    [[ "$actual" == "$expected" ]] || die "CPA SHA-256 校验失败。"

    tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$extract_dir" \
        || die "CPA 安装包解压失败。"
    candidate=$(find "$extract_dir" -type f \
        \( -iname 'cli-proxy-api' -o -iname 'cliproxyapi' \) \
        -print -quit 2>/dev/null || true)
    [[ -n "$candidate" && -s "$candidate" ]] \
        || die "CPA 安装包内未找到 cli-proxy-api。"
    chmod 0755 "$candidate" || die "无法设置 CPA 二进制权限。"

    candidate_line=$(timeout 3 "$candidate" -config "${DEPLOY_TMP}/missing.yaml" 2>&1 \
        | head -n 1 || true)
    candidate_version=$(sed -n 's/.*CLIProxyAPI Version: \([^,[:space:]]*\).*/\1/p' \
        <<< "$candidate_line")
    candidate_version="${candidate_version#v}"
    [[ "$candidate_version" == "$DEPLOY_CPA_VERSION" ]] \
        || die "CPA 安装包版本验证失败（期望 ${DEPLOY_CPA_VERSION}，检测到 ${candidate_version:-未知}）。"
    DEPLOY_CPA_CANDIDATE="$candidate"
    info "CPA 安装包校验与二进制验证通过。"
}

stage_cpamp_for_deployment() {
    local arch release tag download_url checksum_url archive checksum_file extract_dir
    local expected actual candidate smoke_output smoke_dir

    ensure_deploy_tmp
    arch=$(detect_cpamp_release_arch) || die "CPAMP 不支持的 CPU 架构: $(uname -m)"
    info "正在查询 CPAMP 最新可用版本..."
    release=$(fetch_latest_cpamp_release "$arch" 2>/dev/null || true)
    [[ -n "$release" ]] || die "无法从 GitHub 获取适用于 ${arch} 的 CPAMP 安装包。"

    DEPLOY_CPAMP_VERSION=$(jq -r '.version' <<< "$release")
    tag=$(jq -r '.tag' <<< "$release")
    DEPLOY_CPAMP_ASSET=$(jq -r '.asset_name' <<< "$release")
    download_url=$(jq -r '.url' <<< "$release")
    checksum_url=$(jq -r '.checksum_url' <<< "$release")
    extract_dir="${DEPLOY_TMP}/cpamp-extracted"
    smoke_dir="${DEPLOY_TMP}/cpamp-smoke-data"
    archive="${DEPLOY_TMP}/${DEPLOY_CPAMP_ASSET}"
    checksum_file="${DEPLOY_TMP}/cpamp-checksums.txt"
    mkdir -p "$extract_dir" "$smoke_dir" || die "无法创建 CPAMP 临时目录。"

    printf '  CPAMP 版本: %s\n  安装包:     %s\n' "$DEPLOY_CPAMP_VERSION" "$DEPLOY_CPAMP_ASSET"
    info "正在下载 CPAMP ${tag}..."
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$archive" "$download_url" || die "CPAMP 安装包下载失败。"
    [[ -n "$checksum_url" ]] || die "CPAMP Release 没有 checksums.txt。"
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 60 \
        -o "$checksum_file" "$checksum_url" || die "CPAMP 校验文件下载失败。"

    expected=$(checksum_for_asset "$checksum_file" "$DEPLOY_CPAMP_ASSET")
    actual=$(sha256sum "$archive" | awk '{print tolower($1)}')
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] \
        || die "CPAMP 校验文件中未找到 ${DEPLOY_CPAMP_ASSET}。"
    [[ "$actual" == "$expected" ]] || die "CPAMP SHA-256 校验失败。"

    tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$extract_dir" \
        || die "CPAMP 安装包解压失败。"
    candidate=$(find "$extract_dir" -type f -name 'cpa-manager-plus' \
        -print -quit 2>/dev/null || true)
    [[ -n "$candidate" && -s "$candidate" ]] \
        || die "CPAMP 安装包内未找到 cpa-manager-plus。"
    chmod 0755 "$candidate" || die "无法设置 CPAMP 二进制权限。"

    smoke_output=$(timeout --signal=TERM --kill-after=2s 6s env \
        HTTP_ADDR='127.0.0.1:0' \
        USAGE_DATA_DIR="$smoke_dir" \
        CPA_MANAGER_ADMIN_KEY='cpamp-deploy-smoke-admin' \
        CPA_UPSTREAM_URL="http://127.0.0.1:${CPA_BACKEND_PORT}" \
        CPA_MANAGEMENT_KEY='cpamp-deploy-smoke-management' \
        USAGE_COLLECTOR_MODE='http' \
        "$candidate" 2>&1 || true)
    if ! grep -q 'cpa-manager-plus listening on' <<< "$smoke_output"; then
        error "CPAMP 新二进制冒烟测试失败，最近输出："
        tail -n 20 <<< "$smoke_output" >&2
        die "CPAMP 新二进制未通过启动验证。"
    fi
    DEPLOY_CPAMP_CANDIDATE="$candidate"
    info "CPAMP 安装包校验与二进制验证通过。"
}

ensure_service_account() {
    local user_name="$1" home_dir="$2"

    if id -u "$user_name" >/dev/null 2>&1; then
        if ! getent group "$user_name" >/dev/null 2>&1; then
            groupadd --system "$user_name" || die "创建 ${user_name} 系统组失败。"
            usermod -g "$user_name" "$user_name" || die "修正 ${user_name} 主组失败。"
        fi
        return 0
    fi
    useradd --system --user-group --home-dir "$home_dir" --shell /usr/sbin/nologin \
        "$user_name" || die "创建 ${user_name} 系统用户失败。"
}

prepare_cpa_service_unit() {
    ensure_deploy_tmp
    cat > "${DEPLOY_TMP}/cpa.service" <<'EOF'
[Unit]
Description=CLIProxyAPI Gateway Service
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=cpa
Group=cpa
WorkingDirectory=/opt/cpa
ExecStart=/opt/cpa/CLIProxyAPI -config /opt/cpa/config.yaml
Restart=on-failure
RestartSec=10
TimeoutStopSec=45
LimitNOFILE=65536
UMask=0077

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/cpa
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}

prepare_new_cpa_config() {
    local retry_count
    [[ -f "${CPA_DIR}/config.yaml" ]] && return 0
    valid_deployment_key "$DEPLOY_CPA_API_KEY" \
        || die "缺少有效的 CPA 客户端 API Key。"
    valid_deployment_key "$DEPLOY_CPA_MGMT_KEY" \
        || die "缺少有效的 CPA 管理密钥。"

    ensure_deploy_tmp
    retry_count=$(cpa_request_retry_count)
    cat > "${DEPLOY_TMP}/cpa-config.yaml" <<EOF
host: "127.0.0.1"
port: ${CPA_BACKEND_PORT}

tls:
  enable: false

remote-management:
  allow-remote: true
  secret-key: "${DEPLOY_CPA_MGMT_KEY}"
  disable-control-panel: false

auth-dir: "/opt/cpa/.cli-proxy-api"

api-keys:
  - "${DEPLOY_CPA_API_KEY}"

debug: false
logging-to-file: true
logs-max-total-size-mb: 100
error-logs-max-files: 5
usage-statistics-enabled: true
redis-usage-queue-retention-seconds: 600

routing:
  strategy: "round-robin"

request-retry: ${retry_count}
EOF
}

deploy_cpa_component() {
    admission_with_lock deploy_cpa_component_locked
}

deploy_cpa_component_locked() {
    local timestamp current backup_dir backup_file="" unit_file marker_file
    local admission_state
    local old_binary=0 old_unit=0 old_marker=0 config_created=0 was_active=0 was_enabled=0
    local install_ok=1 rollback_ok=1

    [[ -n "$DEPLOY_CPA_CANDIDATE" && -s "$DEPLOY_CPA_CANDIDATE" ]] \
        || die "CPA 部署候选二进制尚未准备。"
    ensure_service_account cpa "$CPA_DIR"
    install -d -m 0750 -o cpa -g cpa "$CPA_DIR" "${CPA_DIR}/logs" \
        "${CPA_DIR}/plugins" || die "创建 CPA 目录失败。"
    install -d -m 0700 -o cpa -g cpa "${CPA_DIR}/.cli-proxy-api" \
        || die "创建 CPA 授权目录失败。"
    backup_dir="${CPA_DIR}/backups"
    install -d -m 0700 -o root -g root "$backup_dir" \
        || die "创建 CPA 备份目录失败。"

    prepare_new_cpa_config
    prepare_cpa_service_unit
    timestamp=$(backup_stamp)
    current=$(current_version 2>/dev/null || printf '未知\n')
    unit_file="$CPA_UNIT_FILE"
    marker_file="${CPA_DIR}/.version"

    if [[ -f "$CPA_BIN" ]]; then
        old_binary=1
        backup_file="${backup_dir}/CLIProxyAPI.${current//[^a-zA-Z0-9._-]/_}.${timestamp}"
        cp -a "$CPA_BIN" "$backup_file" || die "备份现有 CPA 二进制失败。"
    fi
    if [[ -f "$unit_file" ]]; then
        old_unit=1
        cp -a "$unit_file" "${DEPLOY_TMP}/cpa.service.original" \
            || die "备份现有 CPA systemd 单元失败。"
    fi
    if [[ -f "$marker_file" ]]; then
        old_marker=1
        cp -a "$marker_file" "${DEPLOY_TMP}/cpa.version.original" \
            || die "备份现有 CPA 版本标记失败。"
    fi
    systemctl is-active --quiet "$CPA_SERVICE" && was_active=1
    systemctl is-enabled --quiet "$CPA_SERVICE" 2>/dev/null && was_enabled=1

    admission_state="${DEPLOY_TMP}/cpa-admission.state"
    admission_suspend_runtime "$admission_state" || {
        admission_resume_runtime "$admission_state" || true
        die "无法暂停现有准入入口，未替换 CPA 二进制。"
    }
    if [[ "$was_active" == "1" ]] && ! systemctl stop "$CPA_SERVICE"; then
        admission_resume_runtime "$admission_state" || true
        die "无法停止现有 CPA 服务。"
    fi

    if [[ ! -f "${CPA_DIR}/config.yaml" ]]; then
        config_created=1
        if install -m 0600 -o cpa -g cpa "${DEPLOY_TMP}/cpa-config.yaml" \
            "${CPA_DIR}/config.yaml"; then
            :
        else
            install_ok=0
        fi
    fi

    if [[ "$install_ok" == "1" ]]; then
        install -m 0755 -o cpa -g cpa "$DEPLOY_CPA_CANDIDATE" \
            "${CPA_DIR}/.CLIProxyAPI.new" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        mv -f "${CPA_DIR}/.CLIProxyAPI.new" "$CPA_BIN" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        printf '%s\n' "$DEPLOY_CPA_VERSION" > "${DEPLOY_TMP}/cpa.version"
        install -m 0644 -o cpa -g cpa "${DEPLOY_TMP}/cpa.version" \
            "${CPA_DIR}/.version.new" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        mv -f "${CPA_DIR}/.version.new" "$marker_file" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        install -m 0644 -o root -g root "${DEPLOY_TMP}/cpa.service" "$unit_file" \
            || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        systemctl daemon-reload || install_ok=0
        systemctl enable "$CPA_SERVICE" >/dev/null 2>&1 || install_ok=0
    fi

    if [[ "$install_ok" == "1" ]] && systemctl restart "$CPA_SERVICE" && wait_for_cpa \
        && admission_resume_runtime "$admission_state"; then
        info "CPA ${DEPLOY_CPA_VERSION} 部署/重装完成。"
        [[ -n "$backup_file" ]] && info "原 CPA 二进制备份: ${backup_file}"
        return 0
    fi

    error "CPA 部署后未通过健康检查，正在恢复部署前状态..."
    admission_stop_proxies || return 1
    systemctl stop "$CPA_SERVICE" >/dev/null 2>&1 || return 1
    rm -f "${CPA_DIR}/.CLIProxyAPI.new" "${CPA_DIR}/.version.new"
    if [[ "$old_binary" == "1" ]]; then
        install -m 0755 -o cpa -g cpa "$backup_file" "$CPA_BIN" || rollback_ok=0
    else
        rm -f "$CPA_BIN" || rollback_ok=0
    fi
    if [[ "$old_marker" == "1" ]]; then
        cp -a "${DEPLOY_TMP}/cpa.version.original" "$marker_file" || rollback_ok=0
    else
        rm -f "$marker_file" || rollback_ok=0
    fi
    if [[ "$old_unit" == "1" ]]; then
        cp -a "${DEPLOY_TMP}/cpa.service.original" "$unit_file" || rollback_ok=0
        restore_service_enablement "$CPA_SERVICE" "$was_enabled" || rollback_ok=0
    else
        rm -f "$unit_file" || rollback_ok=0
        systemctl disable "$CPA_SERVICE" >/dev/null 2>&1 || true
    fi
    [[ "$config_created" == "1" ]] && rm -f "${CPA_DIR}/config.yaml"
    systemctl daemon-reload || rollback_ok=0

    if [[ "$rollback_ok" != "1" ]]; then
        error "CPA 部署回滚文件未完整恢复，保持停止，拒绝重新开放准入。"
        return 1
    fi
    if [[ "$old_binary" == "1" && "$old_unit" == "1" && "$was_active" == "1" ]]; then
        if ! systemctl start "$CPA_SERVICE" || ! wait_for_cpa; then
            rollback_ok=0
        fi
    fi
    [[ "$rollback_ok" != "1" ]] || admission_resume_runtime "$admission_state" || rollback_ok=0
    if [[ "$rollback_ok" == "1" ]]; then
        warn "CPA 已恢复到部署前状态。"
    else
        error "CPA 回滚不完整，请执行：journalctl -u cpa -n 80 --no-pager"
    fi
    return 1
}

prepare_cpamp_service_unit() {
    ensure_deploy_tmp
    cat > "${DEPLOY_TMP}/cpamp.service" <<'EOF'
[Unit]
Description=CPA-Manager-Plus Observability Service
After=network-online.target cpa.service
Wants=network-online.target cpa.service
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=cpamp
Group=cpamp
WorkingDirectory=/opt/cpamp
EnvironmentFile=/opt/cpamp/.env
ExecStart=/opt/cpamp/cpa-manager-plus
Restart=on-failure
RestartSec=10
TimeoutStopSec=45
LimitNOFILE=65536
UMask=0077

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/cpamp
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}

prepare_resource_guard_artifacts() {
    local target_dir="$1"

    mkdir -p "$target_dir" || return 1
    cat > "${target_dir}/cpa.conf" <<'EOF'
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Restart=on-failure
RestartSec=10
TimeoutStopSec=45
EOF
    cpa_resource_directives >> "${target_dir}/cpa.conf"

    cat > "${target_dir}/cpamp.conf" <<'EOF'
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Restart=on-failure
RestartSec=10
TimeoutStopSec=45
EOF
    cpamp_resource_directives >> "${target_dir}/cpamp.conf"

    printf '[Service]\n' > "${target_dir}/caddy.conf"
    edge_resource_directives caddy >> "${target_dir}/caddy.conf"
    printf '[Service]\n' > "${target_dir}/admission.conf"
    edge_resource_directives admission >> "${target_dir}/admission.conf"
    cp "${target_dir}/admission.conf" "${target_dir}/global-admission.conf" || return 1
    cp "${target_dir}/admission.conf" "${target_dir}/translate-admission.conf" || return 1
    for name in public-status.conf public-cn.conf public-quota.conf cpamp-maint.conf cpamp-maint-manual.conf; do
        printf '[Service]\n' > "${target_dir}/${name}"
        background_resource_directives >> "${target_dir}/${name}"
    done

    cat > "${target_dir}/${CPA_STACK_SLICE}" <<EOF
[Unit]
Description=Aggregate resource budget for CPA gateway stack

[Slice]
EOF
    stack_slice_directives >> "${target_dir}/${CPA_STACK_SLICE}"
    cat > "${target_dir}/${CPA_BACKGROUND_SLICE}" <<EOF
[Unit]
Description=Shared budget for CPA background jobs

[Slice]
EOF
    background_slice_directives >> "${target_dir}/${CPA_BACKGROUND_SLICE}"
}

resource_guard_artifact_pairs() {
    printf '%s|%s\n' \
        'cpa.conf' "$CPA_RESOURCE_DROPIN" \
        'cpamp.conf' "$CPAMP_RESOURCE_DROPIN" \
        'caddy.conf' "$CADDY_RESOURCE_DROPIN" \
        'admission.conf' "$CPA_ADMISSION_DROPIN" \
        'global-admission.conf' "$CPA_GLOBAL_DROPIN" \
        'translate-admission.conf' "$CPA_TRANSLATE_DROPIN" \
        'public-status.conf' "$PUBLIC_STATUS_RESOURCE_DROPIN" \
        'public-cn.conf' "$PUBLIC_STATUS_CN_RESOURCE_DROPIN" \
        'public-quota.conf' "$PUBLIC_STATUS_QUOTA_RESOURCE_DROPIN" \
        'cpamp-maint.conf' "$CPAMP_MAINT_RESOURCE_DROPIN" \
        'cpamp-maint-manual.conf' "$CPAMP_MAINT_MANUAL_RESOURCE_DROPIN" \
        "$CPA_STACK_SLICE" "$CPA_STACK_SLICE_FILE" \
        "$CPA_BACKGROUND_SLICE" "$CPA_BACKGROUND_SLICE_FILE"
}

background_resource_guard_artifact_pairs() {
    printf '%s|%s\n' \
        'public-status.conf' "$PUBLIC_STATUS_RESOURCE_DROPIN" \
        'public-cn.conf' "$PUBLIC_STATUS_CN_RESOURCE_DROPIN" \
        'public-quota.conf' "$PUBLIC_STATUS_QUOTA_RESOURCE_DROPIN" \
        'cpamp-maint.conf' "$CPAMP_MAINT_RESOURCE_DROPIN" \
        'cpamp-maint-manual.conf' "$CPAMP_MAINT_MANUAL_RESOURCE_DROPIN" \
        "$CPA_BACKGROUND_SLICE" "$CPA_BACKGROUND_SLICE_FILE"
}

install_pending_background_resource_guard() {
    local backup_dir name target rc=0

    [[ -d "$RESOURCE_GUARD_PENDING_DIR" ]] || return 1
    backup_dir=$(mktemp -d /tmp/cpa-background-resource-backup.XXXXXX) || return 1
    while IFS='|' read -r name target; do
        if [[ -f "$target" ]]; then
            cp -a -- "$target" "${backup_dir}/${name}" || { rc=1; break; }
        else
            : > "${backup_dir}/${name}.absent" || { rc=1; break; }
        fi
    done < <(background_resource_guard_artifact_pairs)

    if [[ "$rc" == "0" ]]; then
        while IFS='|' read -r name target; do
            install -d -m 0755 -o root -g root "$(dirname "$target")" || { rc=1; break; }
            install -m 0644 -o root -g root "${RESOURCE_GUARD_PENDING_DIR}/${name}" "$target" \
                || { rc=1; break; }
        done < <(background_resource_guard_artifact_pairs)
    fi
    [[ "$rc" != "0" ]] || systemctl daemon-reload || rc=1

    if [[ "$rc" != "0" ]]; then
        while IFS='|' read -r name target; do
            if [[ -f "${backup_dir}/${name}" ]]; then
                install -d -m 0755 -o root -g root "$(dirname "$target")" || true
                install -m 0644 -o root -g root "${backup_dir}/${name}" "$target" || true
            elif [[ -f "${backup_dir}/${name}.absent" ]]; then
                rm -f -- "$target" || true
            fi
        done < <(background_resource_guard_artifact_pairs)
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    rm -rf -- "$backup_dir"
    return "$rc"
}

resource_guard_snapshot_active() {
    local target_dir="$1" name target

    rm -rf -- "$target_dir"
    mkdir -p "$target_dir" || return 1
    while IFS='|' read -r name target; do
        if [[ -f "$target" ]]; then
            cp -a -- "$target" "${target_dir}/${name}" || return 1
        else
            : > "${target_dir}/${name}.absent" || return 1
        fi
    done < <(resource_guard_artifact_pairs)
}

resource_guard_snapshot_complete() {
    local source_dir="$1" name target

    [[ -f "${source_dir}/manifest" ]] || return 1
    while IFS='|' read -r name target; do
        [[ -f "${source_dir}/${name}" || -f "${source_dir}/${name}.absent" ]] \
            || return 1
    done < <(resource_guard_artifact_pairs)
}

resource_guard_snapshot_matches_active() {
    local source_dir="$1" name target
    resource_guard_snapshot_complete "$source_dir" || return 1
    while IFS='|' read -r name target; do
        if [[ -f "$target" ]]; then
            [[ -f "${source_dir}/${name}" ]] && cmp -s "$target" "${source_dir}/${name}" || return 1
        else
            [[ -f "${source_dir}/${name}.absent" ]] || return 1
        fi
    done < <(resource_guard_artifact_pairs)
}

resource_guard_snapshot_profile() {
    local source_dir="$1" profile
    profile=$(awk -F= '$1 == "profile_mode" {print $2; exit}' "${source_dir}/manifest" 2>/dev/null)
    if [[ -z "$profile" ]]; then
        profile=$(awk -F= '$1 == "profile" {print $2; exit}' "${source_dir}/manifest" 2>/dev/null)
    fi
    case "$profile" in
        auto|low|standard|off) printf '%s\n' "$profile" ;;
        low-memory) printf 'low\n' ;;
        *) return 1 ;;
    esac
}

resource_guard_unit_is_bounded() {
    local unit="$1" property value

    [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] \
        || return 1
    for property in MemoryHigh MemoryMax; do
        value=$(systemctl show "$unit" -p "$property" --value 2>/dev/null || true)
        [[ "$value" =~ ^[0-9]+$ ]] && (( value > 0 )) || return 1
    done
}

resource_guard_current_configuration_protected() {
    local unit

    for unit in "$CPA_SERVICE" "$CPAMP_SERVICE" caddy.service; do
        resource_guard_unit_is_bounded "$unit" || return 1
    done
    while IFS= read -r unit; do
        resource_guard_unit_is_bounded "$unit" || return 1
    done < <(admission_service_units)
    resource_guard_unit_is_bounded "$CPA_STACK_SLICE" || return 1
    resource_guard_unit_is_bounded "$CPA_BACKGROUND_SLICE" || return 1
    for unit in "$PUBLIC_STATUS_SERVICE" "$PUBLIC_STATUS_CN_SERVICE" \
        "$PUBLIC_STATUS_QUOTA_SERVICE" "$CPAMP_MAINT_SERVICE" "$CPAMP_MAINT_MANUAL_SERVICE"; do
        if [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]]; then
            resource_guard_unit_is_bounded "$unit" || return 1
        fi
    done
}

resource_guard_restore_snapshot() {
    local source_dir="$1" name target

    while IFS='|' read -r name target; do
        install -d -m 0755 -o root -g root "$(dirname "$target")" || return 1
        if [[ -f "${source_dir}/${name}" ]]; then
            install -m 0644 -o root -g root "${source_dir}/${name}" "$target" || return 1
        elif [[ -f "${source_dir}/${name}.absent" ]]; then
            rm -f -- "$target" || return 1
        else
            return 1
        fi
    done < <(resource_guard_artifact_pairs)
}

resource_guard_install_stage() {
    local source_dir="$1" name target

    while IFS='|' read -r name target; do
        install -d -m 0755 -o root -g root "$(dirname "$target")" || return 1
        install -m 0644 -o root -g root "${source_dir}/${name}" "$target" || return 1
    done < <(resource_guard_artifact_pairs)
}

resource_guard_save_verified() {
    local stage_dir previous_dir profile_name

    install -d -m 0700 -o root -g root "$RESOURCE_GUARD_STATE_DIR" || return 1
    stage_dir=$(mktemp -d "${RESOURCE_GUARD_STATE_DIR}/verified.new.XXXXXX") || return 1
    resource_guard_snapshot_active "$stage_dir" \
        || { rm -rf -- "$stage_dir"; return 1; }
    chmod 0700 "$stage_dir" || { rm -rf -- "$stage_dir"; return 1; }
    profile_name=$(resource_profile_name)
    if ! printf 'profile=%s\nverified_at=%s\nprofile_mode=%s\n' "$profile_name" \
        "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$RESOURCE_PROFILE" > "${stage_dir}/manifest"; then
        rm -rf -- "$stage_dir"
        return 1
    fi
    chmod 0600 "${stage_dir}/manifest" || { rm -rf -- "$stage_dir"; return 1; }

    previous_dir="${RESOURCE_GUARD_STATE_DIR}/verified.previous.${BASHPID}"
    rm -rf -- "$previous_dir"
    if [[ -d "$RESOURCE_GUARD_VERIFIED_DIR" ]]; then
        mv "$RESOURCE_GUARD_VERIFIED_DIR" "$previous_dir" \
            || { rm -rf -- "$stage_dir"; return 1; }
    fi
    if ! mv "$stage_dir" "$RESOURCE_GUARD_VERIFIED_DIR"; then
        [[ ! -d "$previous_dir" ]] \
            || mv "$previous_dir" "$RESOURCE_GUARD_VERIFIED_DIR" >/dev/null 2>&1 \
            || true
        rm -rf -- "$stage_dir"
        return 1
    fi
    rm -rf -- "$previous_dir"
}

resource_guard_save_baseline() {
    local stage_dir previous_dir baseline_type="active" protected=0 profile_mode

    resource_guard_current_configuration_protected && protected=1

    install -d -m 0700 -o root -g root "$RESOURCE_GUARD_STATE_DIR" || return 1
    stage_dir=$(mktemp -d "${RESOURCE_GUARD_STATE_DIR}/baseline.new.XXXXXX") || return 1
    if [[ "$protected" == "1" ]]; then
        resource_guard_snapshot_active "$stage_dir" \
            || { rm -rf -- "$stage_dir"; return 1; }
    else
        warn "当前配置没有形成完整资源保护；首次应用失败时将恢复到保守 low-memory 保护，而不是恢复无限制配置。"
        rm -rf -- "$stage_dir"
        stage_dir=$(mktemp -d "${RESOURCE_GUARD_STATE_DIR}/baseline.new.XXXXXX") || return 1
        if ! (
            RESOURCE_PROFILE=low
            prepare_resource_guard_artifacts "$stage_dir"
        ); then
            rm -rf -- "$stage_dir"
            return 1
        fi
        baseline_type="protective-low"
    fi
    profile_mode=$(deployment_state_value RESOURCE_PROFILE)
    profile_mode="${profile_mode:-$RESOURCE_PROFILE}"
    case "$profile_mode" in auto|low|standard|off) ;; *) profile_mode="$RESOURCE_PROFILE" ;; esac
    [[ "$baseline_type" != "protective-low" ]] || profile_mode=low
    chmod 0700 "$stage_dir" || { rm -rf -- "$stage_dir"; return 1; }
    if ! printf 'captured_at=%s\nhealth_checked=1\nbaseline_type=%s\nprofile_mode=%s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$baseline_type" "$profile_mode" > "${stage_dir}/manifest" \
        || ! chmod 0600 "${stage_dir}/manifest"; then
        rm -rf -- "$stage_dir"
        return 1
    fi
    previous_dir="${RESOURCE_GUARD_STATE_DIR}/baseline.previous.${BASHPID}"
    rm -rf -- "$previous_dir"
    [[ ! -d "$RESOURCE_GUARD_BASELINE_DIR" ]] \
        || mv "$RESOURCE_GUARD_BASELINE_DIR" "$previous_dir" \
        || { rm -rf -- "$stage_dir"; return 1; }
    if ! mv "$stage_dir" "$RESOURCE_GUARD_BASELINE_DIR"; then
        [[ ! -d "$previous_dir" ]] \
            || mv "$previous_dir" "$RESOURCE_GUARD_BASELINE_DIR" >/dev/null 2>&1 \
            || true
        rm -rf -- "$stage_dir"
        return 1
    fi
    rm -rf -- "$previous_dir"
}

stage_resource_guard_pending() {
    local stage_dir

    stage_dir=$(mktemp -d /tmp/cpa-resource-pending.XXXXXX) || return 1
    prepare_resource_guard_artifacts "$stage_dir" || { rm -rf -- "$stage_dir"; return 1; }
    install -d -m 0700 -o root -g root "$RESOURCE_GUARD_STATE_DIR" || { rm -rf -- "$stage_dir"; return 1; }
    rm -rf -- "$RESOURCE_GUARD_PENDING_DIR"
    mv "$stage_dir" "$RESOURCE_GUARD_PENDING_DIR" || return 1
    chmod 0700 "$RESOURCE_GUARD_PENDING_DIR" || return 1
    info "已生成 $(resource_profile_name) 候选资源配置，尚未应用。"
}

wait_for_admission() {
    local port="${1:-$CPA_PUBLIC_PORT}" attempt code
    for (( attempt = 1; attempt <= 20; attempt++ )); do
        code=$(curl -sS -o /dev/null --max-time 2 -w '%{http_code}' \
            "http://127.0.0.1:${port}/v1/models" 2>/dev/null || true)
        [[ "$code" =~ ^(200|401|403)$ ]] && return 0
        sleep 1
    done
    return 1
}

wait_for_all_admission() {
    wait_for_admission || return 1
    if [[ -f "${SYSTEMD_UNIT_DIR}/${CPA_GLOBAL_SOCKET}" ]]; then
        wait_for_admission "$CPA_GLOBAL_PORT" || return 1
    fi
    if [[ "$TRANSLATE_ENABLED" == "true" && -f "${SYSTEMD_UNIT_DIR}/${CPA_TRANSLATE_SOCKET}" ]]; then
        wait_for_admission "$CPA_TRANSLATE_PORT" || return 1
    fi
}

restart_and_verify_resource_services() {
    local cpamp_active="$1" caddy_active="$2" unit

    admission_stop_proxies || return 1
    systemctl restart "$CPA_SERVICE" && wait_for_cpa || return 1
    while IFS= read -r unit; do
        [[ -f "${SYSTEMD_UNIT_DIR}/${unit}" ]] || continue
        systemctl restart "$unit" || return 1
    done < <(admission_socket_units)
    wait_for_all_admission || return 1
    if [[ "$cpamp_active" == "1" ]]; then
        systemctl restart "$CPAMP_SERVICE" && wait_for_cpamp || return 1
    fi
    if [[ "$caddy_active" == "1" ]]; then
        systemctl restart caddy && systemctl is-active --quiet caddy || return 1
    fi
}

verify_current_resource_services() {
    local cpamp_active="$1" caddy_active="$2"

    wait_for_cpa || return 1
    wait_for_all_admission || return 1
    [[ "$cpamp_active" != "1" ]] || wait_for_cpamp || return 1
    [[ "$caddy_active" != "1" ]] || systemctl is-active --quiet caddy || return 1
}

systemd_value_is_infinity() {
    local value="$1"
    [[ "$value" == "infinity" || "$value" == "18446744073709551615" ]]
}

verify_systemd_percent_value() {
    local unit="$1" property="$2" percent="$3" actual total_kib expected tolerance diff

    actual=$(systemctl show "$unit" -p "$property" --value 2>/dev/null || true)
    [[ "$actual" =~ ^[0-9]+$ ]] || {
        error "${unit} 的 ${property} 未形成可验证的数值：${actual:-empty}"
        return 1
    }
    total_kib=$(proc_meminfo_kib MemTotal)
    [[ "$total_kib" =~ ^[0-9]+$ && "$total_kib" -gt 0 ]] || return 1
    expected=$((total_kib * 1024 * percent / 100))
    tolerance=$((expected / 100))
    (( tolerance >= 2097152 )) || tolerance=2097152
    if (( actual >= expected )); then diff=$((actual - expected)); else diff=$((expected - actual)); fi
    if (( diff > tolerance )); then
        error "${unit} 的 ${property}=${actual}，不符合预期 ${percent}%（约 ${expected}）。"
        return 1
    fi
}

verify_systemd_absolute_value() {
    local unit="$1" property="$2" expected="$3" actual

    actual=$(systemctl show "$unit" -p "$property" --value 2>/dev/null || true)
    if [[ "$expected" == "infinity" ]]; then
        systemd_value_is_infinity "$actual" || {
            error "${unit} 的 ${property} 应为 infinity，实际为 ${actual:-empty}。"
            return 1
        }
    elif [[ "$actual" != "$expected" ]]; then
        error "${unit} 的 ${property}=${actual:-empty}，预期为 ${expected}。"
        return 1
    fi
}

verify_unit_slice_and_limits() {
    local unit="$1" expected_slice="$2" high="$3" max="$4" swap="$5"
    local slice accounting

    [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] || return 0
    slice=$(systemctl show "$unit" -p Slice --value 2>/dev/null || true)
    accounting=$(systemctl show "$unit" -p MemoryAccounting --value 2>/dev/null || true)
    [[ "$slice" == "$expected_slice" ]] || {
        error "${unit} 实际 Slice=${slice:-empty}，预期为 ${expected_slice}。"
        return 1
    }
    [[ "$accounting" == "yes" ]] || {
        error "${unit} 的 MemoryAccounting 未生效。"
        return 1
    }
    if [[ "$high" == "infinity" ]]; then
        verify_systemd_absolute_value "$unit" MemoryHigh infinity || return 1
        verify_systemd_absolute_value "$unit" MemoryMax infinity || return 1
        verify_systemd_absolute_value "$unit" MemorySwapMax infinity || return 1
    else
        verify_systemd_percent_value "$unit" MemoryHigh "$high" || return 1
        verify_systemd_percent_value "$unit" MemoryMax "$max" || return 1
        verify_systemd_absolute_value "$unit" MemorySwapMax "$swap" || return 1
    fi
}

verify_active_unit_cgroup() {
    local unit="$1" expected_slice="$2" control_group slice_group

    systemctl is-active --quiet "$unit" 2>/dev/null || return 0
    [[ "$(systemctl show "$unit" -p Slice --value 2>/dev/null || true)" == "$expected_slice" ]] \
        || {
            error "${unit} 未使用预期的 Slice=${expected_slice}。"
            return 1
        }
    control_group=$(systemctl show "$unit" -p ControlGroup --value 2>/dev/null || true)
    slice_group=$(systemctl show "$expected_slice" -p ControlGroup --value 2>/dev/null || true)
    [[ -n "$slice_group" && "$control_group" == "${slice_group}/"* ]] || {
        error "${unit} 实际 ControlGroup=${control_group:-empty}，未进入 ${expected_slice} 的路径 ${slice_group:-empty}。"
        return 1
    }
}

verify_process_gomemlimit() {
    local unit="$1" expected="$2" pid value=""

    systemctl is-active --quiet "$unit" 2>/dev/null || return 0
    pid=$(systemctl show "$unit" -p MainPID --value 2>/dev/null || true)
    [[ "$pid" =~ ^[1-9][0-9]*$ && -r "/proc/${pid}/environ" ]] || {
        error "无法读取 ${unit} 主进程环境，不能验证 GOMEMLIMIT。"
        return 1
    }
    value=$(tr '\0' '\n' < "/proc/${pid}/environ" \
        | awk -F= '$1 == "GOMEMLIMIT" {print substr($0, length($1) + 2); exit}')
    if [[ -n "$expected" ]]; then
        [[ "$value" == "$expected" ]] || {
            error "${unit} 进程 GOMEMLIMIT=${value:-unset}，预期为 ${expected}。"
            return 1
        }
    elif [[ -n "$value" ]]; then
        error "${unit} 的 off 档仍残留 GOMEMLIMIT=${value}。"
        return 1
    fi
}

verify_unit_gomemlimit_setting() {
    local unit="$1" expected="$2" environment unset_environment unit_text

    [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] || return 0
    environment=$(systemctl show "$unit" -p Environment --value 2>/dev/null || true)
    if [[ -n "$expected" ]]; then
        [[ " $environment " == *" GOMEMLIMIT=${expected} "* ]] || {
            error "${unit} 的有效 Environment 未包含 GOMEMLIMIT=${expected}。"
            return 1
        }
    else
        # Environment may still show a value inherited from an older unit;
        # active process environment and UnsetEnvironment are the authoritative checks.
        if systemctl is-active --quiet "$unit" 2>/dev/null; then
            return 0
        fi
        unset_environment=$(systemctl show "$unit" -p UnsetEnvironment --value 2>/dev/null || true)
        if [[ " $unset_environment " == *"GOMEMLIMIT"* ]]; then
            return 0
        fi
        unit_text=$(systemctl cat "$unit" 2>/dev/null || true)
        if grep -Eq '^[[:space:]]*UnsetEnvironment=.*GOMEMLIMIT' <<< "$unit_text"; then
            return 0
        fi
        if [[ " $environment " == *" GOMEMLIMIT="* ]]; then
            error "${unit} 的 off 档未声明 UnsetEnvironment=GOMEMLIMIT。"
            return 1
        fi
    fi
}

verify_resource_guard_effective() {
    local cpa_high cpa_max cpa_swap cpa_go cpamp_high cpamp_max cpamp_swap cpamp_go
    local stack_high stack_max stack_swap background_high background_max expected_slice unit

    if [[ "$RESOURCE_PROFILE" == "off" ]]; then
        for unit in "$CPA_SERVICE" "$CPAMP_SERVICE" caddy.service \
            "$PUBLIC_STATUS_SERVICE" "$PUBLIC_STATUS_CN_SERVICE" "$PUBLIC_STATUS_QUOTA_SERVICE" \
            "$CPAMP_MAINT_SERVICE" "$CPAMP_MAINT_MANUAL_SERVICE"; do
            verify_unit_slice_and_limits "$unit" system.slice infinity infinity infinity || return 1
        done
        while IFS= read -r unit; do
            verify_unit_slice_and_limits "$unit" system.slice infinity infinity infinity || return 1
        done < <(admission_service_units)
        verify_unit_gomemlimit_setting "$CPA_SERVICE" "" || return 1
        verify_unit_gomemlimit_setting "$CPAMP_SERVICE" "" || return 1
        verify_process_gomemlimit "$CPA_SERVICE" "" || return 1
        verify_process_gomemlimit "$CPAMP_SERVICE" "" || return 1
        return 0
    fi

    expected_slice="$CPA_STACK_SLICE"
    if low_memory_profile_enabled; then
        cpa_high=42; cpa_max=52; cpa_swap=100663296; cpa_go=380MiB
        cpamp_high=9; cpamp_max=13; cpamp_swap=33554432; cpamp_go=80MiB
        stack_high=60; stack_max=68; stack_swap=100663296
        background_high=10; background_max=14
    else
        cpa_high=55; cpa_max=65; cpa_swap=268435456; cpa_go=900MiB
        cpamp_high=14; cpamp_max=20; cpamp_swap=67108864; cpamp_go=220MiB
        stack_high=72; stack_max=82; stack_swap=268435456
        background_high=15; background_max=22
    fi

    verify_systemd_percent_value "$CPA_STACK_SLICE" MemoryHigh "$stack_high" || return 1
    verify_systemd_percent_value "$CPA_STACK_SLICE" MemoryMax "$stack_max" || return 1
    verify_systemd_absolute_value "$CPA_STACK_SLICE" MemorySwapMax "$stack_swap" || return 1
    verify_systemd_percent_value "$CPA_BACKGROUND_SLICE" MemoryHigh "$background_high" || return 1
    verify_systemd_percent_value "$CPA_BACKGROUND_SLICE" MemoryMax "$background_max" || return 1
    verify_systemd_absolute_value "$CPA_BACKGROUND_SLICE" MemorySwapMax 0 || return 1
    [[ "$(systemctl show "$CPA_BACKGROUND_SLICE" -p Slice --value 2>/dev/null || true)" == "$CPA_STACK_SLICE" ]] || {
        error "${CPA_BACKGROUND_SLICE} 未挂在 ${CPA_STACK_SLICE} 下。"
        return 1
    }

    verify_unit_slice_and_limits "$CPA_SERVICE" "$expected_slice" "$cpa_high" "$cpa_max" "$cpa_swap" || return 1
    verify_unit_slice_and_limits "$CPAMP_SERVICE" "$expected_slice" "$cpamp_high" "$cpamp_max" "$cpamp_swap" || return 1
    verify_unit_slice_and_limits caddy.service "$expected_slice" 7 10 16777216 || return 1
    while IFS= read -r unit; do
        verify_unit_slice_and_limits "$unit" "$expected_slice" 4 6 0 || return 1
    done < <(admission_service_units)
    for unit in "$PUBLIC_STATUS_SERVICE" "$PUBLIC_STATUS_CN_SERVICE" "$PUBLIC_STATUS_QUOTA_SERVICE" \
        "$CPAMP_MAINT_SERVICE" "$CPAMP_MAINT_MANUAL_SERVICE"; do
        verify_unit_slice_and_limits "$unit" "$CPA_BACKGROUND_SLICE" \
            "$background_high" "$background_max" 0 || return 1
    done

    verify_active_unit_cgroup "$CPA_SERVICE" "$CPA_STACK_SLICE" || return 1
    verify_active_unit_cgroup "$CPAMP_SERVICE" "$CPA_STACK_SLICE" || return 1
    verify_active_unit_cgroup caddy.service "$CPA_STACK_SLICE" || return 1
    while IFS= read -r unit; do
        verify_active_unit_cgroup "$unit" "$CPA_STACK_SLICE" || return 1
    done < <(admission_service_units)
    verify_unit_gomemlimit_setting "$CPA_SERVICE" "$cpa_go" || return 1
    verify_unit_gomemlimit_setting "$CPAMP_SERVICE" "$cpamp_go" || return 1
    verify_process_gomemlimit "$CPA_SERVICE" "$cpa_go" || return 1
    verify_process_gomemlimit "$CPAMP_SERVICE" "$cpamp_go" || return 1
}

apply_resource_guard() {
    admission_with_lock apply_resource_guard_locked
}

apply_resource_guard_locked() {
    local stage_dir rollback_source baseline_type="" rollback_profile=""
    local cpamp_active=0 caddy_active=0 restored_ok=1

    admission_load_settings || return 1
    [[ -d "$RESOURCE_GUARD_PENDING_DIR" ]] || stage_resource_guard_pending || return 1
    stage_dir="$RESOURCE_GUARD_PENDING_DIR"
    systemctl is-active --quiet "$CPAMP_SERVICE" 2>/dev/null && cpamp_active=1
    systemctl is-active --quiet caddy 2>/dev/null && caddy_active=1
    if ! verify_current_resource_services "$cpamp_active" "$caddy_active"; then
        error "当前配置未通过应用前健康检查，拒绝覆盖或建立回滚基线。"
        return 1
    fi
    if resource_guard_snapshot_matches_active "$RESOURCE_GUARD_VERIFIED_DIR"; then
        rollback_source="$RESOURCE_GUARD_VERIFIED_DIR"
    else
        if [[ -f "$RESOURCE_GUARD_VERIFIED_MANIFEST" ]]; then
            warn "现有 verified 回滚点与当前资源配置或入口拓扑不一致，将捕获当前健康配置作为回滚基线。"
        fi
        resource_guard_save_baseline || {
            error "无法保存当前有效资源配置，拒绝首次应用。"
            return 1
        }
        rollback_source="$RESOURCE_GUARD_BASELINE_DIR"
        baseline_type=$(awk -F= '$1 == "baseline_type" {print substr($0, length($1) + 2); exit}' \
            "$RESOURCE_GUARD_BASELINE_MANIFEST" 2>/dev/null || true)
    fi

    if resource_guard_install_stage "$stage_dir" \
        && systemctl daemon-reload \
        && restart_and_verify_resource_services "$cpamp_active" "$caddy_active" \
        && verify_resource_guard_effective; then
        if resource_guard_save_verified; then
            persist_resource_profile \
                || warn "资源配置已验证，但无法把档位写入 ${DEPLOY_STATE}。"
            rm -rf -- "$RESOURCE_GUARD_PENDING_DIR" "$RESOURCE_GUARD_BASELINE_DIR"
            info "已应用并验证 $(resource_profile_name) 整栈资源预算。"
            return 0
        fi
        error "资源配置通过健康检查，但无法持久保存 verified 回滚点。"
    fi

    error "候选资源配置未能完成应用与验证提交，正在恢复 verified 配置或首次应用前基线..."
    resource_guard_restore_snapshot "$rollback_source" || restored_ok=0
    systemctl daemon-reload || restored_ok=0
    rollback_profile=$(resource_guard_snapshot_profile "$rollback_source") || restored_ok=0
    [[ -z "$rollback_profile" ]] || RESOURCE_PROFILE="$rollback_profile"
    if [[ "$restored_ok" != "1" ]]; then
        admission_stop_proxies || true
        systemctl stop "$CPAMP_SERVICE" "$CPA_SERVICE" >/dev/null 2>&1 || true
        error "资源回滚文件或单元加载未完整恢复，服务保持停止，拒绝在保护不完整时重新开放。"
        return 1
    fi
    restart_and_verify_resource_services "$cpamp_active" "$caddy_active" || restored_ok=0
    if [[ "$restored_ok" == "1" ]]; then
        verify_resource_guard_effective || restored_ok=0
        if [[ "$restored_ok" == "1" ]]; then
            persist_resource_profile \
                || warn "已恢复资源保护，但无法把回滚档位写入 ${DEPLOY_STATE}。"
        fi
    fi
    if [[ "$restored_ok" != "1" ]]; then
        admission_stop_proxies || true
        systemctl stop "$CPAMP_SERVICE" "$CPA_SERVICE" >/dev/null 2>&1 || true
        error "回滚后健康或有效资源限制检查仍失败，CPA/CPAMP 与准入代理保持停止，请立即检查相关单元。"
    fi
    return 1
}

resource_guard_command() {
    local action="${1:---status}"

    case "$action" in
        --status|status)
            printf '\n%bCPA 资源保护%b\n' "$BOLD" "$NC"
            printf '  配置模式:       %s\n' "$RESOURCE_PROFILE"
            printf '  当前有效档位:   %s\n' "$(resource_profile_name)"
            printf '  系统内存:       %s MiB 总量 / %s MiB 可用\n' \
                "$(system_total_memory_mib)" "$(system_available_memory_mib)"
            printf '  CPA drop-in:    %s\n' "$([[ -f "$CPA_RESOURCE_DROPIN" ]] && printf '已安装' || printf '未安装')"
            printf '  CPAMP drop-in:  %s\n' "$([[ -f "$CPAMP_RESOURCE_DROPIN" ]] && printf '已安装' || printf '未安装')"
            printf '  候选配置:       %s\n' "$([[ -d "$RESOURCE_GUARD_PENDING_DIR" ]] && printf '已生成' || printf '未生成')"
            printf '  已验证回滚点:   %s\n' "$([[ -f "$RESOURCE_GUARD_VERIFIED_MANIFEST" ]] && printf '已存在' || printf '尚无')"
            printf '  普通连接上限:   %s\n' "$(admission_active_limit)"
            printf '  Socket backlog: %s（仅启动/调度缓冲，不作为业务等待队列）\n' "$(admission_backlog_limit)"
            printf '  公网共享上限:   %s；高并发上限 %s\n' \
                "$GLOBAL_ACTIVE" "$TRANSLATE_ACTIVE"
            ;;
        --apply|apply)
            require_deployment
            admission_with_lock resource_guard_apply_with_admission
            ;;
        *)
            error "未知 resource-guard 参数: $action"
            printf '用法: cpa resource-guard [--status|--apply]\n'
            return 2
            ;;
    esac
}

resource_guard_apply_with_admission() {
    install_admission_gateway && stage_resource_guard_pending && apply_resource_guard
}

admission_config_keys() {
    printf '%s\n' SCHEMA_VERSION DEFAULT_ACTIVE DEFAULT_BACKLOG TRANSLATE_ENABLED \
        TRANSLATE_DOMAIN TRANSLATE_ACTIVE TRANSLATE_BACKLOG GLOBAL_ACTIVE GLOBAL_BACKLOG \
        DEFAULT_BODY_LIMIT_MB TRANSLATE_BODY_LIMIT_MB
}

admission_set_defaults() {
    SCHEMA_VERSION="$ADMISSION_SCHEMA_VERSION"
    DEFAULT_ACTIVE=12; DEFAULT_BACKLOG=16
    TRANSLATE_ENABLED=false; TRANSLATE_DOMAIN=""
    TRANSLATE_ACTIVE=18; TRANSLATE_BACKLOG=24
    GLOBAL_ACTIVE=18; GLOBAL_BACKLOG=24
    DEFAULT_BODY_LIMIT_MB=32; TRANSLATE_BODY_LIMIT_MB=8
}

admission_known_key() {
    case "$1" in
        SCHEMA_VERSION|DEFAULT_ACTIVE|DEFAULT_BACKLOG|TRANSLATE_ENABLED|TRANSLATE_DOMAIN|\
        TRANSLATE_ACTIVE|TRANSLATE_BACKLOG|GLOBAL_ACTIVE|GLOBAL_BACKLOG|\
        DEFAULT_BODY_LIMIT_MB|TRANSLATE_BODY_LIMIT_MB) return 0 ;;
        *) return 1 ;;
    esac
}

admission_key_schema_version() {
    case "$1" in
        DEFAULT_ACTIVE|DEFAULT_BACKLOG) printf '0\n' ;;
        TRANSLATE_ENABLED|TRANSLATE_DOMAIN|TRANSLATE_ACTIVE|TRANSLATE_BACKLOG|\
        GLOBAL_ACTIVE|GLOBAL_BACKLOG) printf '1\n' ;;
        DEFAULT_BODY_LIMIT_MB|TRANSLATE_BODY_LIMIT_MB) printf '2\n' ;;
        *) return 1 ;;
    esac
}

admission_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

admission_validate_settings() {
    local key value domain active_key backlog_key
    for key in DEFAULT_ACTIVE DEFAULT_BACKLOG TRANSLATE_ACTIVE TRANSLATE_BACKLOG \
        GLOBAL_ACTIVE GLOBAL_BACKLOG; do
        value="${!key}"
        if [[ ! "$value" =~ ^[0-9]{1,3}$ ]] \
            || (( 10#$value < 1 || 10#$value > 64 )); then
            error "${key} 必须是 1-64 的整数。"
            return 1
        fi
        printf -v "$key" '%s' "$((10#$value))"
    done
    for key in DEFAULT_BODY_LIMIT_MB TRANSLATE_BODY_LIMIT_MB; do
        value="${!key}"
        if [[ ! "$value" =~ ^[0-9]{1,3}$ ]] \
            || (( 10#$value < 1 || 10#$value > 64 )); then
            error "${key} 必须是 1-64 的整数（MB）。"
            return 1
        fi
        printf -v "$key" '%s' "$((10#$value))"
    done
    (( DEFAULT_ACTIVE <= GLOBAL_ACTIVE )) \
        || { error "DEFAULT_ACTIVE 不能大于 GLOBAL_ACTIVE。"; return 1; }
    (( TRANSLATE_ACTIVE <= GLOBAL_ACTIVE )) \
        || { error "TRANSLATE_ACTIVE 不能大于 GLOBAL_ACTIVE。"; return 1; }
    while IFS='|' read -r active_key backlog_key; do
        (( ${!backlog_key} >= ${!active_key} )) || {
            error "${backlog_key} 必须大于或等于 ${active_key}。"
            return 1
        }
    done < <(printf '%s|%s\n' DEFAULT_ACTIVE DEFAULT_BACKLOG \
        TRANSLATE_ACTIVE TRANSLATE_BACKLOG GLOBAL_ACTIVE GLOBAL_BACKLOG)
    case "$TRANSLATE_ENABLED" in
        true|1) TRANSLATE_ENABLED=true ;;
        false|0) TRANSLATE_ENABLED=false ;;
        *) error "TRANSLATE_ENABLED 只能是 true/false 或 1/0。"; return 1 ;;
    esac
    domain="${TRANSLATE_DOMAIN,,}"
    if [[ -n "$domain" ]]; then
        valid_deployment_domain "$domain" && [[ "$domain" == *.* && ! "${domain##*.}" =~ ^[0-9]+$ ]] \
            || { error "高并发域名无效；只填写完整域名，不含协议、端口或路径。"; return 1; }
    fi
    TRANSLATE_DOMAIN="$domain"
    [[ "$TRANSLATE_ENABLED" != "true" || -n "$domain" ]] \
        || { error "必须先填写高并发域名才能启用入口。"; return 1; }
}

admission_load_settings() {
    local source="${1:-$ADMISSION_CONFIG}" line key value number=0
    local source_schema=0 introduced
    local -A seen=()

    admission_set_defaults
    ADMISSION_CONFIG_VALID=0
    if [[ ! -f "$source" && ( -e "$source" || -L "$source" \
        || -f "${ADMISSION_STATE_DIR}/applied.conf" ) ]]; then
        error "${source} 缺失或不是普通配置文件，拒绝重新生成默认限额。"
        return 1
    fi
    if [[ -f "$source" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            (( number += 1 ))
            line=$(admission_trim "${line%$'\r'}")
            [[ -n "$line" && "$line" != \#* && "$line" != \;* ]] || continue
            if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)[[:space:]]*=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"
                admission_known_key "$key" || continue
                [[ -z "${seen[$key]:-}" ]] \
                    || { error "${source}:${number} 重复字段 ${key}。"; return 1; }
                seen["$key"]=1
                value=$(admission_trim "${value%%#*}")
                printf -v "$key" '%s' "$value"
            else
                error "${source}:${number} 不是合法的 KEY=value 配置。"
                return 1
            fi
        done < "$source"
        if [[ -n "${seen[SCHEMA_VERSION]:-}" ]]; then
            [[ "$SCHEMA_VERSION" =~ ^[0-9]{1,3}$ ]] || {
                error "${source} 的 SCHEMA_VERSION 不是合法整数。"; return 1;
            }
            source_schema=$((10#$SCHEMA_VERSION))
        fi
        (( source_schema <= ADMISSION_SCHEMA_VERSION )) || {
            error "${source} 使用较新的 schema ${source_schema}，拒绝降级覆盖。"; return 1;
        }
        # Missing new-version fields keep their defaults; established fields must exist.
        while IFS= read -r key; do
            [[ "$key" != SCHEMA_VERSION && -z "${seen[$key]:-}" ]] || continue
            introduced=$(admission_key_schema_version "$key") || return 1
            (( introduced > source_schema )) || {
                error "${source} 缺少 schema ${source_schema} 已有字段 ${key}。"; return 1;
            }
        done < <(admission_config_keys)
        SCHEMA_VERSION="$ADMISSION_SCHEMA_VERSION"
    else
        # Preserve the old documented limit rather than selecting a preset on upgrade.
        if [[ -f "$CPA_ADMISSION_SERVICE_FILE" ]]; then
            value=$(systemctl show "$CPA_ADMISSION_SERVICE" -p ExecStart --value 2>/dev/null \
                | sed -n 's/.*--connections-max=\([0-9][0-9]*\).*/\1/p' | head -n 1)
            [[ -n "$value" ]] || value=$(sed -n 's/.*--connections-max=\([0-9][0-9]*\).*/\1/p' \
                "$CPA_ADMISSION_SERVICE_FILE" | head -n 1)
            DEFAULT_ACTIVE="${value:-$CPA_ADMISSION_ACTIVE}"
            value=$(systemctl show "$CPA_ADMISSION_SOCKET" -p Backlog --value 2>/dev/null || true)
            [[ -n "$value" ]] || value=$(sed -n 's/^Backlog=//p' "$CPA_ADMISSION_SOCKET_FILE" \
                2>/dev/null | head -n 1)
            DEFAULT_BACKLOG="${value:-$CPA_ADMISSION_BACKLOG}"
        fi
    fi
    admission_validate_settings || return 1
    ADMISSION_CONFIG_VALID=1
}

admission_render_settings() {
    local output="$1" source="${2:-$ADMISSION_CONFIG}" line key suffix render_tmp
    local -A seen=()
    render_tmp=$(mktemp /tmp/cpa-admission-render.XXXXXX) || return 1
    {
        if [[ -f "$source" ]]; then
            while IFS= read -r line || [[ -n "$line" ]]; do
                [[ "$line" != '# GLOBAL_MIN_RESERVED_'* ]] || continue
                if [[ "$line" =~ ^[[:space:]]*([A-Z][A-Z0-9_]*)[[:space:]]*= ]]; then
                    key="${BASH_REMATCH[1]}"
                    [[ "$key" != GLOBAL_MIN_RESERVED_* ]] || continue
                    if admission_known_key "$key"; then
                        [[ -z "${seen[$key]:-}" ]] || continue
                        seen["$key"]=1
                        suffix=""
                        [[ "$line" != *'#'* ]] || suffix=" #${line#*#}"
                        printf '%s=%s%s\n' "$key" "${!key}" "$suffix"
                        continue
                    fi
                fi
                printf '%s\n' "$line"
            done < "$source"
        else
            printf '# CPA admission settings - preserved across upgrades\n'
        fi
        while IFS= read -r key; do
            [[ -n "${seen[$key]:-}" ]] || printf '%s=%s\n' "$key" "${!key}"
        done < <(admission_config_keys)
    } > "$render_tmp" || { rm -f "$render_tmp"; return 1; }
    mv -f -- "$render_tmp" "$output" || { rm -f "$render_tmp"; return 1; }
}

admission_atomic_install() {
    local source="$1" target="$2" mode="${3:-0644}" owner="${4:-root}" group="${5:-root}"
    local staged="${target}.admission-new.${BASHPID}"
    [[ -d "$(dirname "$target")" ]] \
        || install -d -m 0755 -o root -g root "$(dirname "$target")" || return 1
    if ! install -m "$mode" -o "$owner" -g "$group" "$source" "$staged" \
        || ! mv -f -- "$staged" "$target"; then
        rm -f -- "$staged"
        return 1
    fi
}

admission_with_lock() {
    local lock_fd rc
    if [[ "$ADMISSION_LOCK_HELD" == "1" ]]; then
        "$@"
        return $?
    fi
    command -v flock >/dev/null 2>&1 || { error "准入管理需要 flock。"; return 1; }
    install -d -m 0755 -o root -g root "$(dirname "$ADMISSION_LOCK")" || return 1
    exec {lock_fd}>"$ADMISSION_LOCK" || return 1
    if ! flock -w 120 "$lock_fd"; then
        exec {lock_fd}>&-
        error "等待准入配置锁超时，未修改配置。"
        return 1
    fi
    ADMISSION_LOCK_HELD=1
    "$@"
    rc=$?
    ADMISSION_LOCK_HELD=0
    flock -u "$lock_fd" >/dev/null 2>&1 || true
    exec {lock_fd}>&-
    return "$rc"
}

admission_installed_manager_schema_compatible() {
    local installed_schema=""
    if [[ -f "$INSTALL_PATH" ]]; then
        installed_schema=$(awk -F= '
            $1 == "ADMISSION_SCHEMA_VERSION" && $2 ~ /^[0-9]+$/ {print $2; exit}
        ' "$INSTALL_PATH" 2>/dev/null || true)
    fi
    if [[ "$installed_schema" =~ ^[0-9]{1,3}$ ]] \
        && (( 10#$installed_schema >= ADMISSION_SCHEMA_VERSION )); then
        return 0
    fi
    error "已安装的 cpa 管理脚本不支持 schema ${ADMISSION_SCHEMA_VERSION}；请先执行当前 v${SCRIPT_VERSION} 脚本的 install 命令，再应用准入配置。"
    return 1
}

admission_ensure_config_locked() {
    local staged
    admission_load_settings || return 1
    [[ "${SELF_INSTALL_TXN_ARMED:-0}" == "1" ]] \
        || admission_installed_manager_schema_compatible || return 1
    staged=$(mktemp /tmp/cpa-admission-config.XXXXXX) || return 1
    admission_render_settings "$staged" \
        && admission_atomic_install "$staged" "$ADMISSION_CONFIG" 0600
    local rc=$?
    rm -f -- "$staged"
    return "$rc"
}

admission_translate_effective_limit() {
    printf '%s\n' "$TRANSLATE_ACTIVE"
}

admission_socket_units() {
    printf '%s\n' "$CPA_GLOBAL_SOCKET" "$CPA_ADMISSION_SOCKET"
    [[ "$TRANSLATE_ENABLED" != "true" ]] || printf '%s\n' "$CPA_TRANSLATE_SOCKET"
    return 0
}

admission_service_units() {
    printf '%s\n' "$CPA_ADMISSION_SERVICE"
    [[ ! -f "${SYSTEMD_UNIT_DIR}/${CPA_GLOBAL_SERVICE}" ]] \
        || printf '%s\n' "$CPA_GLOBAL_SERVICE"
    [[ ! -f "${SYSTEMD_UNIT_DIR}/${CPA_TRANSLATE_SERVICE}" ]] \
        || printf '%s\n' "$CPA_TRANSLATE_SERVICE"
    return 0
}

admission_all_units() {
    printf '%s\n' "$CPA_ADMISSION_SOCKET" "$CPA_ADMISSION_SERVICE" \
        "$CPA_GLOBAL_SOCKET" "$CPA_GLOBAL_SERVICE" \
        "$CPA_TRANSLATE_SOCKET" "$CPA_TRANSLATE_SERVICE"
}

admission_calibrate_proxy_limit() {
    local binary offset=""
    binary=$(admission_proxy_binary) || return 1
    # A short loopback-only probe distinguishes vendor-patched >= from the old > check.
    if command -v python3 >/dev/null 2>&1; then
        offset=$(timeout --kill-after=2s 12s python3 - "$binary" <<'CPA239_LIMIT_PROBE'
import os
import signal
import socket
import sys
import time

backend = socket.socket()
backend.bind(("127.0.0.1", 0))
backend.listen(8)
backend_port = backend.getsockname()[1]
listener = socket.socket()
listener.bind(("127.0.0.1", 0))
listener.listen(8)
address = listener.getsockname()
pid = os.fork()
if pid == 0:
    os.dup2(listener.fileno(), 3, inheritable=True)
    nullfd = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(nullfd, fd)
    os.closerange(4, 1024)
    env = os.environ.copy()
    env.pop("NOTIFY_SOCKET", None)
    env.pop("LISTEN_PIDFD", None)
    env.pop("LISTEN_FDNAMES", None)
    env.update(LISTEN_PID=str(os.getpid()), LISTEN_FDS="1")
    os.execve(sys.argv[1], [sys.argv[1], "--connections-max=1",
                          "127.0.0.1:" + str(backend_port)], env)

clients = []
accepted = []
try:
    listener.close()
    backend.settimeout(3)
    clients.append(socket.create_connection(address, timeout=3))
    accepted.append(backend.accept()[0])
    clients.append(socket.create_connection(address, timeout=3))
    backend.settimeout(1.5)
    try:
        accepted.append(backend.accept()[0])
        result = 1
    except socket.timeout:
        # A closed second connection confirms rejection, rather than a stalled proxy.
        clients[1].settimeout(1)
        try:
            if clients[1].recv(1) != b"":
                raise RuntimeError("unexpected second-connection data")
        except ConnectionResetError:
            pass
        result = 0
    alive, _ = os.waitpid(pid, os.WNOHANG)
    if alive:
        raise RuntimeError("probe proxy exited")
    print(result)
finally:
    for conn in clients + accepted:
        conn.close()
    backend.close()
    try:
        os.kill(pid, signal.SIGTERM)
        deadline = time.monotonic() + 1
        while time.monotonic() < deadline:
            ended, _ = os.waitpid(pid, os.WNOHANG)
            if ended:
                break
            time.sleep(0.05)
        else:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
    except (ProcessLookupError, ChildProcessError):
        pass
CPA239_LIMIT_PROBE
        ) || offset=""
    fi
    case "$offset" in
        0|1) ADMISSION_PROXY_LIMIT_OFFSET="$offset" ;;
        *)
            ADMISSION_PROXY_LIMIT_OFFSET=1
            warn "无法确认 socket-proxyd 边界行为，按旧版多放行一个连接进行保守补偿；新版可能少用一个槽位。"
            ;;
    esac
}

admission_proxy_argument() {
    local requested="$1" offset="${ADMISSION_PROXY_LIMIT_OFFSET:-1}"
    (( requested > offset )) || {
        error "当前 socket-proxyd 限额补偿不支持上限 ${requested}，拒绝放宽保护。"
        return 1
    }
    printf '%s\n' "$((requested - offset))"
}

admission_check_domains() {
    local ordinary="${DEPLOY_DOMAIN:-}" status=""
    [[ -n "$ordinary" ]] || ordinary=$(deployment_state_value DOMAIN)
    if [[ -f "$PUBLIC_STATUS_CONFIG" ]]; then status=$(public_status_domain); fi
    if [[ -n "$TRANSLATE_DOMAIN" && ( "${TRANSLATE_DOMAIN,,}" == "${ordinary,,}" \
        || "${TRANSLATE_DOMAIN,,}" == "${status,,}" ) ]]; then
        error "高并发域名不能与普通 API 或 Public Status 域名相同。"
        return 1
    fi
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        [[ -f "$CADDY_CONFIG_FILE" ]] || {
            error "开启高并发域名入口前必须先部署 Caddy。"; return 1;
        }
        timeout 10s getent ahosts "$TRANSLATE_DOMAIN" >/dev/null 2>&1 || {
            error "高并发域名尚不能解析，请先配置 DNS 后再应用。"; return 1;
        }
    fi
}

admission_check_ports() {
    local unit port rows owned old_port
    old_port=$(configured_cpa_port)
    command -v ss >/dev/null 2>&1 || { error "准入端口检查需要 ss（iproute2）。"; return 1; }
    while IFS='|' read -r unit port; do
        rows=$(ss -H -ltn "( sport = :${port} )" 2>/dev/null) || return 1
        owned=0
        systemctl is-active --quiet "$unit" && owned=1
        if [[ "$port" == "$CPA_PUBLIC_PORT" && "$old_port" == "$CPA_PUBLIC_PORT" ]] \
            && systemctl is-active --quiet "$CPA_SERVICE"; then
            owned=1
        fi
        if [[ -n "$rows" && "$owned" == "0" ]]; then
            error "端口 ${port} 被其他监听占用，拒绝修改准入配置。"
            return 1
        fi
        if [[ -n "$rows" ]] && ! awk -v addr="127.0.0.1:${port}" \
            '$4 != addr {bad=1} END {exit bad}' <<< "$rows"; then
            error "端口 ${port} 存在非回环监听，拒绝继续。"
            return 1
        fi
    done < <(printf '%s|%s\n' "$CPA_ADMISSION_SOCKET" "$CPA_PUBLIC_PORT" \
        "$CPA_GLOBAL_SOCKET" "$CPA_GLOBAL_PORT" "$CPA_TRANSLATE_SOCKET" "$CPA_TRANSLATE_PORT")
    if [[ "$old_port" != "$CPA_BACKEND_PORT" ]]; then
        rows=$(ss -H -ltn "( sport = :${CPA_BACKEND_PORT} )" 2>/dev/null) || return 1
        [[ -z "$rows" ]] || { error "CPA 后端目标端口 ${CPA_BACKEND_PORT} 被占用。"; return 1; }
    fi
}

admission_proxy_binary() {
    local path
    for path in /usr/lib/systemd/systemd-socket-proxyd /lib/systemd/systemd-socket-proxyd; do
        [[ -x "$path" ]] && { printf '%s\n' "$path"; return 0; }
    done
    return 1
}

admission_active_limit() {
    printf '%s\n' "$DEFAULT_ACTIVE"
}

admission_backlog_limit() {
    printf '%s\n' "$DEFAULT_BACKLOG"
}

prepare_admission_pair() {
    local target_dir="$1" socket_unit="$2" service_unit="$3" address="$4"
    local active="$5" backlog="$6" upstream="$7" dependency="${8:-}"
    local proxy_bin argument
    proxy_bin=$(admission_proxy_binary) || return 1
    argument=$(admission_proxy_argument "$active") || return 1
    cat > "${target_dir}/${socket_unit}" <<EOF
[Unit]
Description=CPA bounded admission socket (${socket_unit})
Before=caddy.service

[Socket]
ListenStream=${address}
Accept=no
NoDelay=true
Backlog=${backlog}

[Install]
WantedBy=sockets.target
EOF
    cat > "${target_dir}/${service_unit}" <<EOF
# CPA desired connection cap: ${active}; proxy boundary offset: ${ADMISSION_PROXY_LIMIT_OFFSET:-1}
[Unit]
Description=CPA bounded admission proxy (${service_unit})
Requires=${socket_unit} ${CPA_SERVICE} ${dependency}
After=${socket_unit} ${CPA_SERVICE} ${dependency}
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
ExecStart=${proxy_bin} --connections-max=${argument} --exit-idle-time=5min ${upstream}
Restart=on-failure
RestartSec=3
TimeoutStopSec=45
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
EOF
    mkdir -p "${target_dir}/${service_unit}.d" || return 1
    printf '[Service]\n' > "${target_dir}/${service_unit}.d/20-resource-guard.conf"
    edge_resource_directives admission >> "${target_dir}/${service_unit}.d/20-resource-guard.conf"
}

prepare_admission_units() {
    local target_dir="$1" effective
    [[ "$ADMISSION_CONFIG_VALID" == "1" ]] || { error "准入配置无效，拒绝生成单元。"; return 1; }
    mkdir -p "$target_dir" || return 1
    prepare_admission_pair "$target_dir" "$CPA_GLOBAL_SOCKET" "$CPA_GLOBAL_SERVICE" \
        "$CPA_GLOBAL_ADDR" "$GLOBAL_ACTIVE" "$GLOBAL_BACKLOG" \
        "127.0.0.1:${CPA_BACKEND_PORT}" || return 1
    prepare_admission_pair "$target_dir" "$CPA_ADMISSION_SOCKET" "$CPA_ADMISSION_SERVICE" \
        "$CPA_ADMISSION_ADDR" "$DEFAULT_ACTIVE" "$DEFAULT_BACKLOG" \
        "$CPA_GLOBAL_ADDR" "$CPA_GLOBAL_SOCKET" || return 1
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        effective=$(admission_translate_effective_limit)
        prepare_admission_pair "$target_dir" "$CPA_TRANSLATE_SOCKET" "$CPA_TRANSLATE_SERVICE" \
            "$CPA_TRANSLATE_ADDR" "$effective" "$TRANSLATE_BACKLOG" \
            "$CPA_GLOBAL_ADDR" "$CPA_GLOBAL_SOCKET" || return 1
    fi
    return 0
}

cpa_config_matches_legacy_managed_layout() {
    local source="$1"

    awk '
        /^[[:space:]]*$/ || /^[[:space:]]*#/ { next }
        step == 0 && /^host:[[:space:]]*"127\.0\.0\.1"[[:space:]]*$/ { step = 1; next }
        step == 1 && /^port:[[:space:]]*(8317|18318)[[:space:]]*$/ { step = 2; next }
        step == 2 && /^tls:[[:space:]]*$/ { step = 3; next }
        step == 3 && /^  enable:[[:space:]]*false[[:space:]]*$/ { step = 4; next }
        step == 4 && /^remote-management:[[:space:]]*$/ { step = 5; next }
        step == 5 && /^  allow-remote:[[:space:]]*true[[:space:]]*$/ { step = 6; next }
        step == 6 && /^  secret-key:[[:space:]]*"[^"]+"[[:space:]]*$/ { step = 7; next }
        step == 7 && /^  disable-control-panel:[[:space:]]*false[[:space:]]*$/ { step = 8; next }
        step == 8 && /^auth-dir:[[:space:]]*"\/opt\/cpa\/\.cli-proxy-api"[[:space:]]*$/ { step = 9; next }
        step == 9 && /^api-keys:[[:space:]]*$/ { step = 10; next }
        step == 10 && /^  -[[:space:]]*"[^"]+"[[:space:]]*$/ { step = 11; next }
        step == 11 && /^debug:[[:space:]]*false[[:space:]]*$/ { step = 12; next }
        step == 12 && /^logging-to-file:[[:space:]]*true[[:space:]]*$/ { step = 13; next }
        step == 13 && /^logs-max-total-size-mb:[[:space:]]*100[[:space:]]*$/ { step = 14; next }
        step == 14 && /^error-logs-max-files:[[:space:]]*5[[:space:]]*$/ { step = 15; next }
        step == 15 && /^usage-statistics-enabled:[[:space:]]*true[[:space:]]*$/ { step = 16; next }
        step == 16 && /^redis-usage-queue-retention-seconds:[[:space:]]*600[[:space:]]*$/ { step = 17; next }
        step == 17 && /^routing:[[:space:]]*$/ { step = 18; next }
        step == 18 && /^  strategy:[[:space:]]*"round-robin"[[:space:]]*$/ { step = 19; next }
        step == 19 && /^request-retry:[[:space:]]*3[[:space:]]*$/ { step = 20; next }
        { invalid = 1 }
        END { exit !(step == 20 && !invalid) }
    ' "$source"
}

stage_cpa_backend_config() {
    local source="$1" target="$2" retry_count managed=0
    local endpoint layout host old_port port_line

    endpoint=$(cpa_config_endpoint "$source") || {
        error "无法安全识别 CPA 监听配置（支持顶层 host/port 或 server.host/server.port）。"
        return 1
    }
    IFS=$'\t' read -r layout host old_port port_line <<< "$endpoint"
    [[ "$host" == "127.0.0.1" \
        && ( "$old_port" == "$CPA_BACKEND_PORT" || "$old_port" == "$CPA_PUBLIC_PORT" ) \
        && "$port_line" =~ ^[1-9][0-9]*$ ]] || return 1

    retry_count=$(cpa_request_retry_count)
    cpa_config_matches_legacy_managed_layout "$source" && managed=1
    # A current v2 server.port needs no YAML rewrite and no CPA restart.
    # Also retain the source bytes exactly (including a missing final newline).
    if [[ "$old_port" == "$CPA_BACKEND_PORT" && "$managed" != "1" ]]; then
        cp -- "$source" "$target"
        return $?
    fi
    awk -v target_line="$port_line" -v old_port="$old_port" \
        -v port="$CPA_BACKEND_PORT" -v retry="$retry_count" -v managed="$managed" '
        BEGIN { port_seen = 0; retry_changed = 0 }
        NR == target_line {
            port_seen++
            if (old_port == port) { print; next }
            original = $0
            ending = (substr(original, length(original)) == "\r" ? "\r" : "")
            sub(/\r$/, "", original)
            prefix = original
            sub(/[^ \t].*$/, "", prefix)
            suffix = ""
            if (match(original, /[ \t]+#.*/)) suffix = substr(original, RSTART)
            print prefix "port: " port suffix ending
            next
        }
        managed && !retry_changed && /^request-retry:[[:space:]]*3[[:space:]]*$/ {
            print "request-retry: " retry
            retry_changed = 1
            next
        }
        { print }
        END { if (port_seen != 1) exit 2 }
    ' "$source" > "$target"
}

caddy_managed_cpa_site_info() {
    local source="$1" ordinary
    ordinary="${DEPLOY_DOMAIN:-$(deployment_state_value DOMAIN)}"

    awk -v ordinary="${ordinary,,}" '
        function lexer_reset() {
            lexer_quote = ""
            lexer_escaped = 0
        }
        function brace_delta(value,    i, ch, count) {
            count = 0
            for (i = 1; i <= length(value); i++) {
                ch = substr(value, i, 1)
                if (lexer_quote == "\"") {
                    if (lexer_escaped) {
                        lexer_escaped = 0
                    } else if (ch == "\\") {
                        lexer_escaped = 1
                    } else if (ch == "\"") {
                        lexer_quote = ""
                    }
                    continue
                }
                if (lexer_quote == "`") {
                    if (ch == "`") lexer_quote = ""
                    continue
                }
                if (ch == "#") break
                if (ch == "\"" || ch == "`") {
                    lexer_quote = ch
                } else if (ch == "{") {
                    count++
                } else if (ch == "}") {
                    count--
                }
            }
            return count
        }
        function trim_line(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }
        {
            lines[NR] = $0
        }
        END {
            marker = "^# Managed by cpa-deploy[.]sh[[:space:]]+[0-9]+([.][0-9]+)+[[:space:]]*$"
            lexer_reset()
            depth = 0
            in_block = 0
            block_count = 0
            last_marker = 0

            for (i = 1; i <= NR; i++) {
                line = lines[i]
                trimmed = trim_line(line)
                delta = brace_delta(line)
                if (depth == 0 && trimmed ~ marker) {
                    last_marker = i
                }
                if (!in_block && depth == 0 && delta > 0) {
                    in_block = 1
                    current_start = i
                }
                depth += delta
                if (in_block && depth == 0) {
                    block_count++
                    block_start[block_count] = current_start
                    block_end[block_count] = i
                    block_marker[block_count] = last_marker
                    in_block = 0
                }
            }

            for (block = 1; block <= block_count; block++) {
                if (block_marker[block] == 0) continue
                site_start = block_start[block]
                site_end = block_end[block]
                block_header = trim_line(lines[site_start])
                if (block_header == "{" || block_header ~ /^\([^)]*\)[[:space:]]*\{$/) continue
                has_request_body = 0
                has_management_block = 0
                has_management_path = 0
                has_management_response = 0
                body_line = 0
                proxy_line = 0
                proxy_mode = ""
                site_depth = 0
                request_body_depth = 0
                lexer_reset()
                for (i = site_start; i <= site_end; i++) {
                    trimmed = trim_line(lines[i])
                    quoted_continuation = (lexer_quote != "")
                    delta = brace_delta(lines[i])
                    if (quoted_continuation) {
                        site_depth += delta
                        continue
                    }
                    if (trimmed == "request_body {") {
                        has_request_body = 1
                        request_body_depth = site_depth + delta
                    }
                    if (body_line == 0 && request_body_depth > 0 \
                        && site_depth + delta == request_body_depth \
                        && trimmed ~ /^max_size [1-9][0-9]*MB$/) body_line = i
                    if (trimmed == "@management_block {") has_management_block = 1
                    if (trimmed == "path /management.html /v0/management /v0/management/*") has_management_path = 1
                    if (trimmed == "respond @management_block 404") has_management_response = 1
                    if (proxy_line == 0 && trimmed ~ /^reverse_proxy 127[.]0[.]0[.]1:(8317|18318)$/) {
                        proxy_line = i
                        proxy_mode = "simple"
                    }
                    if (proxy_line == 0 && trimmed ~ /^reverse_proxy 127[.]0[.]0[.]1:(8317|18318) \{$/) {
                        proxy_line = i
                        proxy_mode = "block"
                    }
                    site_depth += delta
                    if (request_body_depth > 0 && site_depth < request_body_depth) request_body_depth = 0
                }

                if (has_request_body && has_management_block && has_management_path \
                    && has_management_response && proxy_line != 0) {
                    candidates++
                    candidate[candidates] = site_start " " site_end " " body_line " " proxy_line " " proxy_mode
                    header = tolower(block_header)
                    sub(/[[:space:]]*\{$/, "", header)
                    if (ordinary != "" && header == ordinary) {
                        matched++
                        selected = candidates
                    }
                }
            }
            if (matched == 1) {
                print candidate[selected]
                exit 0
            }
            if (candidates == 1 && matched == 0) {
                print candidate[1]
                exit 0
            }
            exit 3
        }
    ' "$source"
}

caddy_config_matches_legacy_managed_layout() {
    local source="$1"

    caddy_managed_cpa_site_info "$source" >/dev/null
}

stage_caddy_admission_config() {
    local source="$1" target="$2" active body_limit site_info
    local cpa_start cpa_end body_line proxy_line proxy_mode

    active=$(admission_active_limit)
    body_limit="${DEFAULT_BODY_LIMIT_MB}MB"
    site_info=$(caddy_managed_cpa_site_info "$source" 2>/dev/null) || return 2
    read -r cpa_start cpa_end body_line proxy_line proxy_mode <<< "$site_info"
    [[ "$cpa_start" =~ ^[0-9]+$ && "$cpa_end" =~ ^[0-9]+$ \
        && "$body_line" =~ ^[1-9][0-9]*$ \
        && "$proxy_line" =~ ^[0-9]+$ && -n "$proxy_mode" ]] || return 2

    awk -v start="$cpa_start" -v end="$cpa_end" \
        -v body_line="$body_line" -v proxy_line="$proxy_line" \
        -v proxy_mode="$proxy_mode" -v addr="$CPA_ADMISSION_ADDR" \
        -v active="$active" -v body_limit="$body_limit" '
        function lexer_reset() {
            lexer_quote = ""
            lexer_escaped = 0
        }
        function brace_delta(value,    i, ch, count) {
            count = 0
            for (i = 1; i <= length(value); i++) {
                ch = substr(value, i, 1)
                if (lexer_quote == "\"") {
                    if (lexer_escaped) {
                        lexer_escaped = 0
                    } else if (ch == "\\") {
                        lexer_escaped = 1
                    } else if (ch == "\"") {
                        lexer_quote = ""
                    }
                    continue
                }
                if (lexer_quote == "`") {
                    if (ch == "`") lexer_quote = ""
                    continue
                }
                if (ch == "#") break
                if (ch == "\"" || ch == "`") {
                    lexer_quote = ch
                } else if (ch == "{") {
                    count++
                } else if (ch == "}") {
                    count--
                }
            }
            return count
        }
        function proxy_block(indent) {
            print indent "reverse_proxy " addr " {"
            print indent "    fail_duration 1s"
            print indent "    unhealthy_request_count " active
            print indent "    transport http {"
            print indent "        versions 1.1"
            print indent "        keepalive off"
            print indent "        dial_timeout 3s"
            print indent "    }"
            print indent "}"
        }
        BEGIN {
            changed = 0; in_proxy = 0; proxy_depth = 0
            in_transport = 0; transport_depth = 0; has_transport = 0
            lexer_reset()
        }
        {
            line = $0
            trimmed = line
            sub(/^[[:space:]]+/, "", trimmed)
            sub(/[[:space:]]+$/, "", trimmed)
            quoted_continuation = (lexer_quote != "")
            delta = brace_delta(line)
            if (NR < start || NR > end) {
                print line
                next
            }
        }
        NR == body_line {
            indent = line
            sub(/[^[:space:]].*$/, "", indent)
            print indent "max_size " body_limit
            next
        }
        NR == proxy_line && proxy_mode == "simple" {
            indent = line
            sub(/[^[:space:]].*$/, "", indent)
            proxy_block(indent)
            print ""
            print indent "handle_errors {"
            print indent "    @overloaded expression {err.status_code} == 502 || {err.status_code} == 503 || {err.status_code} == 504"
            print indent "    respond @overloaded \"CPA overloaded or temporarily unavailable\" 503"
            print indent "    respond \"{err.status_code} {err.status_text}\" {err.status_code}"
            print indent "}"
            changed = 1
            next
        }
        NR == proxy_line && proxy_mode == "block" {
            indent = line
            sub(/[^[:space:]].*$/, "", indent)
            print indent "reverse_proxy " addr " {"
            print indent "    fail_duration 1s"
            print indent "    unhealthy_request_count " active
            proxy_depth = delta
            in_proxy = 1
            changed = 1
            next
        }
        in_proxy {
            if (quoted_continuation) {
                print line
                proxy_depth += delta
                if (in_transport && proxy_depth < transport_depth) in_transport = 0
                if (proxy_depth <= 0) in_proxy = 0
                next
            }
            if (!in_transport && trimmed == "transport http {") {
                indent = line
                sub(/[^[:space:]].*$/, "", indent)
                print line
                print indent "    versions 1.1"
                print indent "    keepalive off"
                print indent "    dial_timeout 3s"
                transport_depth = proxy_depth + delta
                in_transport = 1
                has_transport = 1
                proxy_depth += delta
                next
            }
            if (in_transport && trimmed ~ /^(versions|keepalive|dial_timeout)[[:space:]]+/) {
                proxy_depth += delta
                next
            }
            if (trimmed ~ /^(flush_interval|fail_duration|unhealthy_request_count)[[:space:]]+/) {
                proxy_depth += delta
                if (proxy_depth <= 0) in_proxy = 0
                next
            }
            if (proxy_depth + delta <= 0 && !has_transport) {
                indent = line
                sub(/[^[:space:]].*$/, "", indent)
                print indent "    transport http {"
                print indent "        versions 1.1"
                print indent "        keepalive off"
                print indent "        dial_timeout 3s"
                print indent "    }"
            }
            print line
            proxy_depth += delta
            if (in_transport && proxy_depth < transport_depth) in_transport = 0
            if (proxy_depth <= 0) in_proxy = 0
            next
        }
        !quoted_continuation && trimmed == "respond \"CPA overloaded or temporarily unavailable\" 503" {
            indent = line
            sub(/[^[:space:]].*$/, "", indent)
            print indent "@overloaded expression {err.status_code} == 502 || {err.status_code} == 503 || {err.status_code} == 504"
            print indent "respond @overloaded \"CPA overloaded or temporarily unavailable\" 503"
            print indent "respond \"{err.status_code} {err.status_text}\" {err.status_code}"
            next
        }
        { print line }
        END { if (!changed) exit 3 }
    ' "$source" > "$target"
}

admission_emit_caddy_site() {
    local domain="$1" address="$2" active="$3" body_limit="${4}MB"
    cat <<EOF
${domain} {
    request_body {
        max_size ${body_limit}
    }
    @management_block {
        path /management.html /v0/management /v0/management/*
    }
    respond @management_block 404
    reverse_proxy ${address} {
        fail_duration 1s
        unhealthy_request_count ${active}
        transport http {
            versions 1.1
            keepalive off
            dial_timeout 3s
        }
    }
    handle_errors {
        @overloaded expression {err.status_code} == 502 || {err.status_code} == 503 || {err.status_code} == 504
        respond @overloaded "CPA overloaded or temporarily unavailable" 503
        respond "{err.status_code} {err.status_text}" {err.status_code}
    }
    log {
        output file /var/log/caddy/access.log {
            roll_size 10MiB
            roll_keep 10
            roll_keep_for 720h
        }
        format json
    }
}
EOF
}

admission_stage_caddy() {
    local stage_dir="$1" file name
    [[ -f "$CADDY_CONFIG_FILE" ]] || return 0
    mkdir -p "${stage_dir}/sites" || return 1
    if [[ -d "$PUBLIC_STATUS_CADDY_DIR" ]]; then
        # Keep relative imports and auxiliary files in their original layout.
        cp -a -- "${PUBLIC_STATUS_CADDY_DIR}/." "${stage_dir}/sites/" || return 1
        rm -f -- "${stage_dir}/sites/$(basename "$ADMISSION_CADDY_FILE")" || return 1
    fi
    if [[ -e "$ADMISSION_CADDY_FILE" ]] && ! grep -Eq \
        '^# Managed by cpa-deploy[.]sh [0-9.]+ - High concurrency API$' "$ADMISSION_CADDY_FILE"; then
        error "高并发站点文件存在但并非本脚本托管，拒绝覆盖。"
        return 1
    fi
    stage_caddy_admission_config "$CADDY_CONFIG_FILE" "${stage_dir}/Caddyfile" || {
        error "现有 Caddyfile 不是可安全迁移的 CPA 托管站点。"; return 1;
    }
    if ! grep -Fqx "$PUBLIC_STATUS_CADDY_IMPORT" "${stage_dir}/Caddyfile"; then
        printf '\n%s\n' "$PUBLIC_STATUS_CADDY_IMPORT" >> "${stage_dir}/Caddyfile" || return 1
    fi
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        name=$(basename "$ADMISSION_CADDY_FILE")
        {
            printf '# Managed by cpa-deploy.sh %s - High concurrency API\n' "$SCRIPT_VERSION"
            admission_emit_caddy_site "$TRANSLATE_DOMAIN" "$CPA_TRANSLATE_ADDR" \
                "$(admission_translate_effective_limit)" "$TRANSLATE_BODY_LIMIT_MB"
        } > "${stage_dir}/sites/${name}" || return 1
    fi
    awk -v live="$PUBLIC_STATUS_CADDY_IMPORT" \
        -v staged="import ${stage_dir}/sites/*.caddy" \
        '$0 == live {print staged; next} {print}' "${stage_dir}/Caddyfile" \
        > "${stage_dir}/Caddyfile.validate" || return 1
    caddy validate --config "${stage_dir}/Caddyfile.validate" --adapter caddyfile
}

admission_artifact_pairs() {
    local unit
    printf '%s|%s\n' admission.conf "$ADMISSION_CONFIG" Caddyfile "$CADDY_CONFIG_FILE" \
        translate.caddy "$ADMISSION_CADDY_FILE" config.yaml "${CPA_DIR}/config.yaml" \
        cpamp.env "${CPAMP_DIR}/.env" "$CPA_STACK_SLICE" "$CPA_STACK_SLICE_FILE" \
        applied.conf "${ADMISSION_STATE_DIR}/applied.conf"
    while IFS= read -r unit; do
        printf '%s|%s\n' "$unit" "${SYSTEMD_UNIT_DIR}/${unit}"
        if [[ "$unit" == *.service ]]; then
            printf '%s|%s\n' "${unit}.resource" \
                "${SYSTEMD_UNIT_DIR}/${unit}.d/20-resource-guard.conf"
        fi
    done < <(admission_all_units)
}

admission_backup_transaction() {
    local directory="$1" name target unit enabled active
    mkdir -p "$directory" || return 1
    chmod 0700 "$directory" || return 1
    while IFS='|' read -r name target; do
        if [[ -e "$target" || -L "$target" ]]; then
            cp -a -- "$target" "${directory}/${name}" || return 1
        else
            : > "${directory}/${name}.absent" || return 1
        fi
    done < <(admission_artifact_pairs)
    : > "${directory}/units.state" || return 1
    while IFS= read -r unit; do
        enabled=0; active=0
        systemctl is-enabled --quiet "$unit" 2>/dev/null && enabled=1
        systemctl is-active --quiet "$unit" 2>/dev/null && active=1
        printf '%s|%s|%s\n' "$unit" "$enabled" "$active" >> "${directory}/units.state" || return 1
    done < <(printf '%s\n' "$CPA_SERVICE" "$CPAMP_SERVICE" caddy.service; admission_all_units)
}

admission_stop_proxies() {
    local unit
    local -a units=()
    while IFS= read -r unit; do
        if [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]]; then
            units+=("$unit")
        fi
    done < <(admission_all_units)
    (( ${#units[@]} == 0 )) || systemctl stop "${units[@]}"
}

admission_prior_active() {
    awk -F'|' -v unit="$2" '$1 == unit {print $3; exit}' "$1/units.state"
}

admission_suspend_runtime() {
    local state_file="$1" unit active
    : > "$state_file" || return 1
    while IFS= read -r unit; do
        active=0
        systemctl is-active --quiet "$unit" 2>/dev/null && active=1
        printf '%s|%s\n' "$unit" "$active" >> "$state_file" || return 1
    done < <(admission_all_units)
    admission_stop_proxies
}

admission_resume_runtime() {
    local state_file="$1" unit active rc=0
    [[ -f "$state_file" ]] || return 1
    while IFS='|' read -r unit active; do
        [[ "$active" != "1" ]] || systemctl start "$unit" || rc=1
    done < "$state_file"
    systemctl is-active --quiet "$CPA_SERVICE" || return "$rc"
    while IFS='|' read -r unit active; do
        [[ "$active" == "1" && "$unit" == *.socket ]] || continue
        case "$unit" in
            "$CPA_ADMISSION_SOCKET") wait_for_admission || rc=1 ;;
            "$CPA_GLOBAL_SOCKET") wait_for_admission "$CPA_GLOBAL_PORT" || rc=1 ;;
            "$CPA_TRANSLATE_SOCKET") wait_for_admission "$CPA_TRANSLATE_PORT" || rc=1 ;;
        esac
    done < "$state_file"
    return "$rc"
}

admission_restore_transaction() {
    local directory="$1" name target unit enabled active rc=0
    [[ -f "${directory}/units.state" ]] || { error "准入回滚清单缺失。"; return 1; }
    warn "正在恢复准入应用前的配置和服务状态：${directory}"
    admission_stop_proxies || rc=1
    if [[ "$(systemctl show "$CPAMP_SERVICE" -p LoadState --value 2>/dev/null || true)" == "loaded" ]]; then
        systemctl stop "$CPAMP_SERVICE" >/dev/null 2>&1 || rc=1
    fi
    systemctl stop "$CPA_SERVICE" >/dev/null 2>&1 || rc=1
    for unit in "$CPA_ADMISSION_SOCKET" "$CPA_GLOBAL_SOCKET" "$CPA_TRANSLATE_SOCKET"; do
        systemctl disable "$unit" >/dev/null 2>&1 || true
    done
    if [[ "$(admission_prior_active "$directory" "$CPA_SERVICE")" == "0" ]]; then
        systemctl stop "$CPA_SERVICE" >/dev/null 2>&1 || true
    fi
    while IFS='|' read -r name target; do
        if [[ -e "${directory}/${name}" || -L "${directory}/${name}" ]]; then
            [[ -d "$(dirname "$target")" ]] || mkdir -p "$(dirname "$target")" || rc=1
            cp -a --remove-destination -- "${directory}/${name}" "$target" || rc=1
        elif [[ -f "${directory}/${name}.absent" ]]; then
            rm -f -- "$target" || rc=1
        else
            error "准入回滚文件缺失：${name}"
            rc=1
        fi
    done < <(admission_artifact_pairs)
    systemctl daemon-reload || rc=1
    if [[ "$rc" != "0" ]]; then
        error "关键回滚文件或单元加载未恢复，CPA/CPAMP 与准入代理保持停止，拒绝在保护缺失时重新开放。"
        return 1
    fi
    while IFS='|' read -r unit enabled active; do
        if [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]]; then
            restore_service_enablement "$unit" "$enabled" || rc=1
            if [[ "$active" == "1" ]]; then
                if [[ "$unit" == "$CPA_SERVICE" || "$unit" == "$CPAMP_SERVICE" ]]; then
                    systemctl restart "$unit" || rc=1
                elif [[ "$unit" == "caddy.service" ]]; then
                    caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
                        && { public_status_reload_caddy || systemctl restart caddy; } \
                        && systemctl is-active --quiet caddy || rc=1
                else
                    systemctl start "$unit" || rc=1
                fi
            else
                systemctl stop "$unit" >/dev/null 2>&1 || rc=1
            fi
        fi
    done < "${directory}/units.state"
    if [[ "$(admission_prior_active "$directory" "$CPA_SERVICE")" == "1" ]]; then
        wait_for_cpa || rc=1
    fi
    if [[ "$(admission_prior_active "$directory" "$CPA_ADMISSION_SOCKET")" == "1" ]]; then
        wait_for_admission || rc=1
    fi
    if [[ "$(admission_prior_active "$directory" "$CPA_GLOBAL_SOCKET")" == "1" ]]; then
        wait_for_admission "$CPA_GLOBAL_PORT" || rc=1
    fi
    if [[ "$(admission_prior_active "$directory" "$CPA_TRANSLATE_SOCKET")" == "1" ]]; then
        wait_for_admission "$CPA_TRANSLATE_PORT" || rc=1
    fi
    if [[ "$(admission_prior_active "$directory" "$CPAMP_SERVICE")" == "1" ]]; then
        wait_for_cpamp || rc=1
    fi
    [[ "$rc" == "0" ]] || error "准入回滚未完全恢复，请检查 cpa/cpamp/caddy 和三个准入单元。"
    return "$rc"
}

admission_install_staged_artifacts() {
    local stage_dir="$1" unit staged live
    while IFS= read -r unit; do
        staged="${stage_dir}/${unit}"
        live="${SYSTEMD_UNIT_DIR}/${unit}"
        if [[ -f "$staged" ]]; then
            admission_atomic_install "$staged" "$live" || return 1
        elif [[ "$unit" == "$CPA_TRANSLATE_SOCKET" || "$unit" == "$CPA_TRANSLATE_SERVICE" ]]; then
            systemctl disable "$unit" >/dev/null 2>&1 || true
            rm -f -- "$live" || return 1
        fi
        if [[ "$unit" == *.service ]]; then
            staged="${stage_dir}/${unit}.d/20-resource-guard.conf"
            live="${SYSTEMD_UNIT_DIR}/${unit}.d/20-resource-guard.conf"
            if [[ -f "$staged" ]]; then
                admission_atomic_install "$staged" "$live" || return 1
            elif [[ "$unit" == "$CPA_TRANSLATE_SERVICE" ]]; then
                rm -f -- "$live" || return 1
            fi
        fi
    done < <(admission_all_units)
    if [[ ! -f "$CPA_STACK_SLICE_FILE" ]]; then
        admission_atomic_install "${stage_dir}/${CPA_STACK_SLICE}" "$CPA_STACK_SLICE_FILE" || return 1
    fi
    if [[ -f "${stage_dir}/Caddyfile" ]]; then
        admission_atomic_install "${stage_dir}/Caddyfile" "$CADDY_CONFIG_FILE" || return 1
        staged="${stage_dir}/sites/$(basename "$ADMISSION_CADDY_FILE")"
        if [[ -f "$staged" ]]; then
            admission_atomic_install "$staged" "$ADMISSION_CADDY_FILE" || return 1
        else
            rm -f -- "$ADMISSION_CADDY_FILE" || return 1
        fi
    fi
}

admission_units_changed() {
    local stage_dir="$1" unit
    while IFS= read -r unit; do
        if [[ -f "${stage_dir}/${unit}" ]]; then
            cmp -s "${stage_dir}/${unit}" "${SYSTEMD_UNIT_DIR}/${unit}" || return 0
            if [[ "$unit" == *.service ]]; then
                cmp -s "${stage_dir}/${unit}.d/20-resource-guard.conf" \
                    "${SYSTEMD_UNIT_DIR}/${unit}.d/20-resource-guard.conf" || return 0
            fi
        elif [[ -e "${SYSTEMD_UNIT_DIR}/${unit}" ]]; then
            return 0
        fi
    done < <(admission_all_units)
    return 1
}

admission_verify_resource_limits() {
    local unit
    while IFS= read -r unit; do
        [[ -f "${SYSTEMD_UNIT_DIR}/${unit}" ]] || continue
        [[ "$(systemctl show "$unit" -p LoadState --value 2>/dev/null || true)" == "loaded" ]] \
            || { error "新准入服务未被正确加载：${unit}"; return 1; }
        if [[ "$RESOURCE_PROFILE" == "off" ]]; then
            verify_unit_slice_and_limits "$unit" system.slice infinity infinity infinity || return 1
        else
            verify_unit_slice_and_limits "$unit" "$CPA_STACK_SLICE" 4 6 0 || return 1
            verify_active_unit_cgroup "$unit" "$CPA_STACK_SLICE" || return 1
        fi
    done < <(printf '%s\n' "$CPA_ADMISSION_SERVICE" "$CPA_GLOBAL_SERVICE" "$CPA_TRANSLATE_SERVICE")
}

admission_verify_runtime_parameters() {
    local socket_unit service_unit address active backlog upstream argument actual exec_start listen
    local binary argv expected type
    binary=$(admission_proxy_binary) || return 1
    while IFS='|' read -r socket_unit service_unit address active backlog upstream; do
        argument=$(admission_proxy_argument "$active") || return 1
        exec_start=$(systemctl show "$service_unit" -p ExecStart --value 2>/dev/null) || return 1
        argv=$(sed -n 's/.*argv\[\]=\([^;]*\);.*/\1/p' <<< "$exec_start")
        argv=$(admission_trim "$argv")
        expected="${binary} --connections-max=${argument} --exit-idle-time=5min ${upstream}"
        type=$(systemctl show "$service_unit" -p Type --value 2>/dev/null) || return 1
        [[ "$argv" == "$expected" && "$type" == "simple" ]] || {
            error "${service_unit} 有效 ExecStart 与候选参数不符，请检查其他 drop-in。"
            return 1
        }
        actual=$(systemctl show "$socket_unit" -p Backlog --value 2>/dev/null) || return 1
        listen=$(systemctl show "$socket_unit" -p Listen --value 2>/dev/null) || return 1
        [[ "$actual" == "$backlog" && "$listen" == "${address} (Stream)" ]] || {
            error "${socket_unit} 有效监听地址或 Backlog 与候选配置不符。"
            return 1
        }
    done < <(
        printf '%s|%s|%s|%s|%s|%s\n' \
            "$CPA_GLOBAL_SOCKET" "$CPA_GLOBAL_SERVICE" "$CPA_GLOBAL_ADDR" "$GLOBAL_ACTIVE" \
            "$GLOBAL_BACKLOG" "127.0.0.1:${CPA_BACKEND_PORT}" \
            "$CPA_ADMISSION_SOCKET" "$CPA_ADMISSION_SERVICE" "$CPA_ADMISSION_ADDR" "$DEFAULT_ACTIVE" \
            "$DEFAULT_BACKLOG" "$CPA_GLOBAL_ADDR"
        if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
            printf '%s|%s|%s|%s|%s|%s\n' "$CPA_TRANSLATE_SOCKET" "$CPA_TRANSLATE_SERVICE" \
                "$CPA_TRANSLATE_ADDR" "$(admission_translate_effective_limit)" \
                "$TRANSLATE_BACKLOG" "$CPA_GLOBAL_ADDR"
        fi
    )
}

admission_apply_locked() {
    local source="${1:-$ADMISSION_CONFIG}" stage_dir backup_dir old_port host
    local endpoint layout port_line
    local cpa_changed=0 cpamp_changed=0 units_changed=0 rc=0 unit staged
    local cpamp_active=0 caddy_active=0
    local -a verify_units=()
    admission_load_settings "$source" || return 1
    admission_installed_manager_schema_compatible || return 1
    [[ -f "${CPA_DIR}/config.yaml" ]] || { error "未找到 CPA 配置。"; return 1; }
    systemctl is-active --quiet "$CPA_SERVICE" \
        || { error "CPA 当前未运行，拒绝准入变更；请先恢复服务。"; return 1; }
    wait_for_cpa || { error "CPA 未通过应用前健康检查，原配置未改动。"; return 1; }
    admission_check_domains && admission_check_ports || return 1
    admission_calibrate_proxy_limit || return 1
    endpoint=$(cpa_config_endpoint "${CPA_DIR}/config.yaml") || {
        error "CPA 配置缺少明确的监听字段（支持顶层 host/port 或 server.host/server.port），拒绝建立迁移基线。"
        return 1
    }
    IFS=$'\t' read -r layout host old_port port_line <<< "$endpoint"
    [[ "$old_port" == "$CPA_BACKEND_PORT" || "$old_port" == "$CPA_PUBLIC_PORT" ]] || {
        error "CPA 不是可迁移的 :8317/:18318 托管布局，拒绝修改。"
        return 1
    }
    [[ "$host" == "127.0.0.1" ]] || {
        error "CPA 后端必须只绑定 127.0.0.1，拒绝保留可绕过准入的公网监听。"; return 1;
    }
    stage_dir=$(mktemp -d /tmp/cpa-admission-stage.XXXXXX) || return 1
    ADMISSION_STAGE_TMP="$stage_dir"
    if ! admission_render_settings "${stage_dir}/admission.conf" "$source" \
        || ! prepare_admission_units "$stage_dir" \
        || ! stage_cpa_backend_config "${CPA_DIR}/config.yaml" "${stage_dir}/config.yaml" \
        || ! admission_stage_caddy "$stage_dir"; then
        rm -rf -- "$stage_dir"
        return 1
    fi
    if [[ -f "${CPAMP_DIR}/.env" ]]; then
        cp -a "${CPAMP_DIR}/.env" "${stage_dir}/cpamp.env" \
            && set_cpamp_backend_urls "${stage_dir}/cpamp.env" \
            || { rm -rf -- "$stage_dir"; return 1; }
        cmp -s "${stage_dir}/cpamp.env" "${CPAMP_DIR}/.env" || cpamp_changed=1
    fi
    cmp -s "${stage_dir}/config.yaml" "${CPA_DIR}/config.yaml" || cpa_changed=1
    admission_units_changed "$stage_dir" && units_changed=1
    {
        printf '[Unit]\nDescription=Aggregate resource budget for CPA gateway stack\n\n[Slice]\n'
        stack_slice_directives
    } > "${stage_dir}/${CPA_STACK_SLICE}" || { rm -rf -- "$stage_dir"; return 1; }
    while IFS= read -r unit; do
        [[ ! -f "${stage_dir}/${unit}" ]] || verify_units+=("${stage_dir}/${unit}")
    done < <(admission_all_units)
    if ! systemd-analyze verify "${verify_units[@]}" "${stage_dir}/${CPA_STACK_SLICE}"; then
        error "候选准入 systemd 单元验证失败，未应用任何配置。"
        rm -rf -- "$stage_dir"
        return 1
    fi
    systemctl is-active --quiet "$CPAMP_SERVICE" 2>/dev/null && cpamp_active=1
    systemctl is-active --quiet caddy 2>/dev/null && caddy_active=1
    if [[ "$cpamp_active" == "1" ]] && ! wait_for_cpamp; then
        error "CPAMP 未通过应用前健康检查，原配置未改动。"
        rm -rf -- "$stage_dir"
        return 1
    fi
    install -d -m 0700 -o root -g root "$ADMISSION_STATE_DIR" "${ADMISSION_STATE_DIR}/backups" \
        || { rm -rf -- "$stage_dir"; return 1; }
    backup_dir="${ADMISSION_STATE_DIR}/backups/$(backup_stamp)"
    admission_backup_transaction "$backup_dir" || { rm -rf -- "$stage_dir"; return 1; }
    ADMISSION_TXN_DIR="$backup_dir"
    ADMISSION_TXN_ARMED=1

    if [[ "$units_changed" == "1" || "$cpa_changed" == "1" ]]; then
        warn "正在切换准入连接配置，现有流式连接可能中断。"
        admission_stop_proxies || rc=1
    fi
    if [[ "$rc" == "0" && ( "$cpa_changed" == "1" || "$cpamp_changed" == "1" ) \
        && "$cpamp_active" == "1" ]]; then
        systemctl stop "$CPAMP_SERVICE" || rc=1
    fi
    if [[ "$rc" == "0" && "$cpa_changed" == "1" ]]; then
        systemctl stop "$CPA_SERVICE" \
            && admission_atomic_install "${stage_dir}/config.yaml" "${CPA_DIR}/config.yaml" 0600 cpa cpa \
            && systemctl start "$CPA_SERVICE" && wait_for_cpa || rc=1
    fi
    if [[ "$rc" == "0" && "$cpamp_changed" == "1" ]]; then
        admission_atomic_install "${stage_dir}/cpamp.env" "${CPAMP_DIR}/.env" 0600 cpamp cpamp || rc=1
    fi
    if [[ "$rc" == "0" ]]; then
        admission_install_staged_artifacts "$stage_dir" && systemctl daemon-reload || rc=1
    fi
    if [[ "$rc" == "0" ]]; then
        while IFS= read -r unit; do
            systemctl enable --now "$unit" >/dev/null || { rc=1; break; }
        done < <(admission_socket_units)
    fi
    [[ "$rc" != "0" ]] || wait_for_all_admission || rc=1
    [[ "$rc" != "0" ]] || admission_verify_runtime_parameters || rc=1
    [[ "$rc" != "0" ]] || admission_verify_resource_limits || rc=1
    if [[ "$rc" == "0" && "$cpamp_active" == "1" ]]; then
        systemctl start "$CPAMP_SERVICE" && wait_for_cpamp || rc=1
    fi
    if [[ "$rc" == "0" && "$caddy_active" == "1" ]]; then
        caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
            && public_status_reload_caddy && systemctl is-active --quiet caddy || rc=1
    fi
    if [[ "$rc" == "0" ]]; then
        admission_atomic_install "${stage_dir}/admission.conf" "$ADMISSION_CONFIG" 0600 || rc=1
    fi
    if [[ "$rc" == "0" ]]; then
        admission_atomic_install "${stage_dir}/admission.conf" "${ADMISSION_STATE_DIR}/applied.conf" 0600 || rc=1
    fi
    if [[ "$rc" == "0" ]]; then
        printf 'committed_at=%s\n' "$(date -Is)" > "${backup_dir}/committed" || rc=1
    fi
    ADMISSION_TXN_ARMED=0
    if [[ "$rc" != "0" ]]; then
        error "准入候选配置应用失败，正在自动回滚。"
        admission_restore_transaction "$backup_dir" || true
        admission_load_settings || true
        rm -rf -- "$stage_dir"
        return 1
    fi
    rm -rf -- "$stage_dir"
    info "已应用准入配置：普通 ${DEFAULT_ACTIVE}，高并发 ${TRANSLATE_ACTIVE}，共享 ${GLOBAL_ACTIVE}。"
    info "配置: ${ADMISSION_CONFIG}；应用前备份: ${backup_dir}"
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        info "高并发 API: https://${TRANSLATE_DOMAIN}/v1；证书由 Caddy 自动处理。"
        if [[ "$caddy_active" != "1" ]]; then
            warn "Caddy 当前未运行，站点配置已保存但公网入口尚未上线。"
        else
            staged=$(curl -sS --max-time 5 --resolve "${TRANSLATE_DOMAIN}:443:127.0.0.1" \
                -o /dev/null -w '%{http_code}' "https://${TRANSLATE_DOMAIN}/v1/models" 2>/dev/null || true)
            [[ "$staged" =~ ^(200|401|403)$ ]] \
                || warn "HTTPS 尚未确认可用，请检查 DNS、80/443 可达性和 Caddy 证书日志。"
        fi
    fi
    return 0
}

install_admission_gateway() {
    admission_with_lock public_status_with_lock admission_apply_locked "${1:-$ADMISSION_CONFIG}"
}

admission_select_preset() {
    local preset="$1"
    DEFAULT_ACTIVE=12; DEFAULT_BACKLOG=16
    case "$preset" in
        safe|1)
            TRANSLATE_ACTIVE=16; GLOBAL_ACTIVE=16
            TRANSLATE_BACKLOG=20; GLOBAL_BACKLOG=20
            ;;
        balanced|2)
            TRANSLATE_ACTIVE=18; GLOBAL_ACTIVE=18
            TRANSLATE_BACKLOG=24; GLOBAL_BACKLOG=24
            ;;
        throughput|3)
            TRANSLATE_ACTIVE=24; GLOBAL_ACTIVE=24
            TRANSLATE_BACKLOG=32; GLOBAL_BACKLOG=32
            ;;
        *) error "未知预设档。"; return 1 ;;
    esac
    info "已填入预设，尚未应用；域名和入口开关保持不变。"
}

admission_print_settings() {
    local ordinary
    ordinary="${DEPLOY_DOMAIN:-$(deployment_state_value DOMAIN)}"
    printf '  普通入口:        %s\n' "${ordinary:-HTTP/IP 或仅本机}"
    printf '  普通活动连接:    %s；Backlog %s\n' "$DEFAULT_ACTIVE" "$DEFAULT_BACKLOG"
    printf '  普通请求体上限:  %sMB\n' "$DEFAULT_BODY_LIMIT_MB"
    printf '  高并发入口:      %s；域名 %s\n' "$TRANSLATE_ENABLED" "${TRANSLATE_DOMAIN:-未配置}"
    printf '  高并发上限:      %s；Backlog %s\n' "$TRANSLATE_ACTIVE" "$TRANSLATE_BACKLOG"
    printf '  高并发请求上限:  %sMB\n' "$TRANSLATE_BODY_LIMIT_MB"
    printf '  公网共享上限:    %s；Backlog %s\n' "$GLOBAL_ACTIVE" "$GLOBAL_BACKLOG"
    printf '  配置 schema:     %s\n' "$SCHEMA_VERSION"
    printf '  配置文件:        %s\n' "$ADMISSION_CONFIG"
}

admission_show_status() {
    local label socket_unit service_unit configured configured_backlog argument backlog desired unit_text
    local offset actual expected_argument service_loaded socket_loaded active enabled mismatch=0
    local cap_mismatch backlog_mismatch
    admission_load_settings || return 1
    printf '\n%bCPA 准入与并发状态%b\n' "$BOLD" "$NC"
    admission_print_settings
    if [[ ! -f "$ADMISSION_CONFIG" ]]; then
        printf '  持久配置:        尚未创建，显示迁移候选值\n'
    elif [[ ! -f "${ADMISSION_STATE_DIR}/applied.conf" ]]; then
        printf '  应用记录:        尚未应用三层准入架构\n'
    elif cmp -s "$ADMISSION_CONFIG" "${ADMISSION_STATE_DIR}/applied.conf"; then
        printf '  应用记录:        已保存配置与最近应用记录一致\n'
    else
        printf '  应用记录:        配置与最近应用记录不同，尚需应用\n'
    fi
    printf '\n  单元实际参数（connections-max 已包含边界补偿）：\n'
    while IFS='|' read -r label socket_unit service_unit configured configured_backlog enabled; do
        service_loaded=$(systemctl show "$service_unit" -p LoadState --value 2>/dev/null || true)
        socket_loaded=$(systemctl show "$socket_unit" -p LoadState --value 2>/dev/null || true)
        active=$(systemctl is-active "$socket_unit" 2>/dev/null || true)
        if [[ "$enabled" == "false" && "$service_loaded" != "loaded" && "$socket_loaded" != "loaded" ]]; then
            printf '  %-10s configured=%s，Backlog configured=%s；入口已关闭，未安装运行单元\n' \
                "$label" "$configured" "$configured_backlog"
            continue
        fi
        argument=$(systemctl show "$service_unit" -p ExecStart --value 2>/dev/null \
            | sed -n 's/.*--connections-max=\([0-9][0-9]*\).*/\1/p' | head -n 1)
        backlog=$(systemctl show "$socket_unit" -p Backlog --value 2>/dev/null || true)
        unit_text=$(systemctl cat "$service_unit" 2>/dev/null || true)
        desired=$(sed -n 's/^# CPA desired connection cap: \([0-9]*\);.*/\1/p' <<< "$unit_text" | head -n 1)
        offset=$(sed -n 's/^# CPA desired connection cap: [0-9]*; proxy boundary offset: \([01]\)$/\1/p' \
            <<< "$unit_text" | head -n 1)
        actual="未知"; cap_mismatch=0; backlog_mismatch=0
        if [[ "$argument" =~ ^[0-9]{1,3}$ && "$offset" =~ ^[01]$ ]]; then
            actual=$((10#$argument + offset))
            expected_argument=$((configured - offset))
            [[ "$argument" == "$expected_argument" && "$actual" == "$configured" ]] || cap_mismatch=1
        else
            cap_mismatch=1
        fi
        [[ "$desired" == "$configured" && "$service_loaded" == "loaded" ]] || cap_mismatch=1
        [[ "$backlog" == "$configured_backlog" && "$socket_loaded" == "loaded" ]] || backlog_mismatch=1
        [[ "$enabled" == "true" ]] || cap_mismatch=1
        printf '  %-10s configured=%s，desired=%s，systemd cap=%s，proxy参数=%s，socket=%s；%s\n' \
            "$label" "$configured" "${desired:-未知}" "$actual" "${argument:-未知}" "${active:-未知}" \
            "$([[ "$cap_mismatch" == 0 ]] && printf '一致' || printf '不一致')"
        printf '             Backlog configured=%s，systemd=%s；%s\n' \
            "$configured_backlog" "${backlog:-未知}" "$([[ "$backlog_mismatch" == 0 ]] && printf '一致' || printf '不一致')"
        [[ "$cap_mismatch" == "0" && "$backlog_mismatch" == "0" ]] || mismatch=1
    done < <(printf '%s|%s|%s|%s|%s|%s\n' \
        DEFAULT "$CPA_ADMISSION_SOCKET" "$CPA_ADMISSION_SERVICE" "$DEFAULT_ACTIVE" "$DEFAULT_BACKLOG" true \
        TRANSLATE "$CPA_TRANSLATE_SOCKET" "$CPA_TRANSLATE_SERVICE" "$TRANSLATE_ACTIVE" "$TRANSLATE_BACKLOG" "$TRANSLATE_ENABLED" \
        GLOBAL "$CPA_GLOBAL_SOCKET" "$CPA_GLOBAL_SERVICE" "$GLOBAL_ACTIVE" "$GLOBAL_BACKLOG" true)
    if [[ "$mismatch" == "1" ]]; then
        printf 'WARNING: 配置与实际运行值不一致\n'
    fi
    printf '  口径: 活动代理连接；不是模型任务计数、公平队列或整机所有连接上限。\n'
    printf '  CPAMP/Dashboard 的内部管理访问不占上述公网准入槽位。\n\n'
}

admission_prompt_number() {
    local key="$1" label="$2" minimum="${3:-1}" value=""
    while true; do
        read -r -p "${label} [${!key}]: " value || return 1
        value="${value:-${!key}}"
        if [[ "$value" =~ ^[0-9]{1,3}$ ]] && (( 10#$value >= minimum && 10#$value <= 64 )); then
            printf -v "$key" '%s' "$((10#$value))"
            return 0
        fi
        warn "请输入 ${minimum}-64 的整数。"
    done
}

admission_prompt_domain() {
    local value="" suggestion="$TRANSLATE_DOMAIN" ordinary
    ordinary=$(deployment_state_value DOMAIN)
    if [[ -z "$suggestion" && -n "$ordinary" ]]; then
        if [[ "$ordinary" == api.* ]]; then
            suggestion="translate-api.${ordinary#api.}"
        else
            suggestion="translate-api.${ordinary}"
        fi
    fi
    while true; do
        read -r -p "高并发域名 [${suggestion:-请填写；- 清空}]: " value || return 1
        [[ "$value" != "-" ]] || {
            TRANSLATE_DOMAIN=""; TRANSLATE_ENABLED=false; return 0;
        }
        value="${value:-$suggestion}"
        if [[ -n "$value" && "$value" == *.* && ! "${value##*.}" =~ ^[0-9]+$ ]] \
            && valid_deployment_domain "$value"; then
            TRANSLATE_DOMAIN="${value,,}"
            return 0
        fi
        warn "请填写完整域名，不含协议、端口或路径。"
    done
}

admission_apply_menu_locked() {
    local source="$1" expected="$2" current
    current=$(sha256sum "$ADMISSION_CONFIG" | awk '{print $1}') || return 1
    [[ "$current" == "$expected" ]] || {
        error "已保存配置在菜单打开后被其他操作修改，请先重新加载。"; return 1;
    }
    public_status_with_lock admission_apply_locked "$source"
}

admission_menu() {
    local choice="" answer="" preset="" candidate expected rc
    admission_with_lock admission_ensure_config_locked || return 1
    candidate=$(mktemp /tmp/cpa-admission-menu.XXXXXX) || return 1
    ADMISSION_MENU_TMP="$candidate"
    cp -- "$ADMISSION_CONFIG" "$candidate" || { rm -f "$candidate"; return 1; }
    expected=$(sha256sum "$ADMISSION_CONFIG" | awk '{print $1}') || { rm -f "$candidate"; return 1; }
    admission_load_settings "$candidate" || { rm -f "$candidate"; return 1; }
    while true; do
        printf '\n%bCPA 准入与并发管理（以下为待应用值）%b\n' "$BOLD" "$NC"
        admission_print_settings
        cat <<'EOF'
--------------------------------------------------
  1. 修改普通入口活动连接 / Backlog
  2. 修改高并发入口活动连接 / Backlog
  3. 修改全局活动连接 / Backlog
  4. 修改高并发域名
  5. 开启 / 关闭高并发入口
  6. 选择安全 / 均衡 / 高吞吐预设
  7. 验证并应用配置
  8. 放弃修改并重新加载已保存配置
  9. 修改普通 / 高并发入口请求体上限（MB）
  0. 返回
EOF
        read -r -p '请选择 [0-9]: ' choice || { rm -f "$candidate"; return 0; }
        case "$choice" in
            1) admission_prompt_number DEFAULT_ACTIVE '普通活动连接' \
                && admission_prompt_number DEFAULT_BACKLOG '普通 Backlog' || break ;;
            2) admission_prompt_number TRANSLATE_ACTIVE '高并发配置活动连接' \
                && admission_prompt_number TRANSLATE_BACKLOG '高并发 Backlog' || break ;;
            3) admission_prompt_number GLOBAL_ACTIVE '全局活动连接' \
                && admission_prompt_number GLOBAL_BACKLOG '全局 Backlog' || break ;;
            9) admission_prompt_number DEFAULT_BODY_LIMIT_MB '普通入口请求体上限（MB）' \
                && admission_prompt_number TRANSLATE_BODY_LIMIT_MB '高并发入口请求体上限（MB）' || break ;;
            4) admission_prompt_domain || break ;;
            5)
                if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
                    TRANSLATE_ENABLED=false
                else
                    [[ -n "$TRANSLATE_DOMAIN" ]] || admission_prompt_domain || break
                    [[ -z "$TRANSLATE_DOMAIN" ]] || TRANSLATE_ENABLED=true
                    warn "启用前请确认 DNS 已解析到正确入口，公网 TCP 80/443 可达；无可用 IPv6 时不要设置 AAAA。"
                fi
                ;;
            6)
                printf '  1. 安全    普通12 / 高并发16 / 全局16 / Backlog16,20,20\n'
                printf '  2. 均衡    普通12 / 高并发18 / 全局18 / Backlog16,24,24\n'
                printf '  3. 高吞吐  普通12 / 高并发24 / 全局24 / Backlog16,32,32\n'
                read -r -p '预设 [1-3；其他取消]: ' preset || break
                case "$preset" in 1|2|3) admission_select_preset "$preset" ;; esac
                ;;
            7)
                admission_validate_settings || continue
                admission_render_settings "$candidate" "$candidate" || break
                warn "连接上限提高不代表内存一定安全；准入单元变化可能中断现有流式连接。"
                read -r -p '确认验证并应用以上配置 [y/N]: ' answer || break
                [[ "$answer" =~ ^[Yy]$ ]] || continue
                admission_with_lock admission_apply_menu_locked "$candidate" "$expected"
                rc=$?
                if [[ "$rc" == "0" ]]; then
                    cp -- "$ADMISSION_CONFIG" "$candidate" || break
                    expected=$(sha256sum "$ADMISSION_CONFIG" | awk '{print $1}') || break
                else
                    admission_load_settings "$candidate" || break
                    warn "本次未完成应用，候选值仍保留在菜单中。"
                fi
                ;;
            8)
                admission_load_settings || break
                cp -- "$ADMISSION_CONFIG" "$candidate" || break
                expected=$(sha256sum "$ADMISSION_CONFIG" | awk '{print $1}') || break
                ;;
            0|q|Q)
                rm -f -- "$candidate"
                admission_load_settings || true
                return 0
                ;;
            *) warn "无效选项。" ;;
        esac
    done
    rm -f -- "$candidate"
    admission_load_settings || true
    return 1
}

admission_command() {
    case "${1:-menu}" in
        menu) admission_menu ;;
        --status|status) admission_show_status ;;
        --apply|apply)
            require_deployment
            warn "将按持久配置切换准入；连接参数变化时现有流式连接可能中断。"
            install_admission_gateway
            ;;
        *)
            error "未知 admission 参数: $1"
            printf '用法: cpa admission [--status|--apply]\n'
            return 2
            ;;
    esac
}

prepare_cpamp_environment() {
    ensure_deploy_tmp
    if [[ -f "${CPAMP_DIR}/.env" ]]; then
        prepare_cpamp_env_compat "${CPAMP_DIR}/.env" "${DEPLOY_TMP}/cpamp.env" \
            || die "生成 CPAMP 兼容环境文件失败。"
        return 0
    fi

    valid_deployment_key "$DEPLOY_CPAMP_ADMIN_KEY" \
        || die "缺少有效的 CPAMP 面板管理密钥。"
    valid_deployment_key "$DEPLOY_CPA_MGMT_KEY" \
        || die "缺少有效的 CPA 管理密钥。"
    cat > "${DEPLOY_TMP}/cpamp.env" <<EOF
HTTP_ADDR=127.0.0.1:18317
LISTEN_ADDR=127.0.0.1:18317
USAGE_DATA_DIR=/opt/cpamp/data
DATA_DIR=/opt/cpamp/data
CPA_MANAGER_ADMIN_KEY=${DEPLOY_CPAMP_ADMIN_KEY}
ADMIN_SECRET=${DEPLOY_CPAMP_ADMIN_KEY}
CPA_UPSTREAM_URL=http://127.0.0.1:${CPA_BACKEND_PORT}
CPA_URL=http://127.0.0.1:${CPA_BACKEND_PORT}
CPA_MANAGEMENT_KEY=${DEPLOY_CPA_MGMT_KEY}
CPA_SECRET=${DEPLOY_CPA_MGMT_KEY}
USAGE_COLLECTOR_MODE=http
EOF
}

install_managed_cpamp_unit() {
    local unit_file="$CPAMP_UNIT_FILE"
    local had_unit=0 was_active=0 was_enabled=0 rollback_ok=1

    prepare_cpamp_service_unit
    systemctl is-active --quiet "$CPAMP_SERVICE" && was_active=1
    systemctl is-enabled --quiet "$CPAMP_SERVICE" 2>/dev/null && was_enabled=1
    if [[ -f "$unit_file" ]]; then
        had_unit=1
        cp -a "$unit_file" "${DEPLOY_TMP}/cpamp.service.before-managed" \
            || die "备份 CPAMP systemd 单元失败。"
    fi
    if install -m 0644 -o root -g root "${DEPLOY_TMP}/cpamp.service" "$unit_file" \
        && systemctl daemon-reload \
        && systemctl enable "$CPAMP_SERVICE" >/dev/null 2>&1 \
        && systemctl restart "$CPAMP_SERVICE" \
        && wait_for_cpamp; then
        return 0
    fi

    error "安装托管 CPAMP systemd 单元后健康检查失败，正在恢复原单元。"
    systemctl stop "$CPAMP_SERVICE" >/dev/null 2>&1 || true
    if [[ "$had_unit" == "1" ]]; then
        cp -a "${DEPLOY_TMP}/cpamp.service.before-managed" "$unit_file" || rollback_ok=0
    else
        rm -f "$unit_file" || rollback_ok=0
        systemctl disable "$CPAMP_SERVICE" >/dev/null 2>&1 || true
    fi
    systemctl daemon-reload || rollback_ok=0
    if [[ "$had_unit" == "1" ]]; then
        restore_service_enablement "$CPAMP_SERVICE" "$was_enabled" || rollback_ok=0
        if [[ "$was_active" == "1" ]]; then
            systemctl start "$CPAMP_SERVICE" || rollback_ok=0
        fi
    fi
    [[ "$rollback_ok" == "1" ]] || error "CPAMP 托管单元回滚不完整。"
    return 1
}

deploy_cpamp_component() {
    local timestamp backup_dir backup_file="" unit_file marker_file env_file
    local data_dir data_parent data_name data_backup="" data_backup_tmp failed_data
    local old_binary=0 old_unit=0 old_marker=0 old_env=0 was_active=0 was_enabled=0
    local install_ok=1 rollback_ok=1
    local data_was_present=0 data_created=0 service_attempted=0 can_restore_data=1

    unit_file="$CPAMP_UNIT_FILE"
    marker_file="${CPAMP_DIR}/.version"
    env_file="${CPAMP_DIR}/.env"

    if [[ -f "$CPAMP_BIN" && -f "$env_file" && -f "$unit_file" ]]; then
        info "检测到完整 CPAMP 安装，将保留环境和数据并强制重装最新版。"
        ( UPDATE_TMP=""; trap cleanup_update_tmp EXIT; update_cpamp 1 1 ) || return 1
        if install_managed_cpamp_unit; then
            info "CPAMP 托管服务单元已校正。"
            return 0
        fi
        return 1
    fi

    stage_cpamp_for_deployment
    ensure_service_account cpamp "$CPAMP_DIR"
    prepare_cpamp_environment
    prepare_cpamp_service_unit
    data_dir=$(cpamp_data_directory)
    backup_dir="${CPAMP_DIR}/backups"
    case "$data_dir" in
        "${CPAMP_DIR}"/*) ;;
        *) die "CPAMP 数据目录不在 ${CPAMP_DIR} 内，拒绝部署: ${data_dir}" ;;
    esac
    case "$data_dir" in
        "${CPAMP_DIR}/backups"|"${CPAMP_DIR}/backups"/*)
            die "CPAMP 数据目录与备份目录重叠，拒绝部署: ${data_dir}"
            ;;
    esac
    install -d -m 0750 -o cpamp -g cpamp "$CPAMP_DIR" \
        || die "创建 CPAMP 安装目录失败。"
    if [[ ! -d "$data_dir" ]]; then
        install -d -m 0750 -o cpamp -g cpamp "$data_dir" \
            || die "创建 CPAMP 数据目录失败。"
        data_created=1
    else
        data_was_present=1
    fi
    install -d -m 0700 -o root -g root "$backup_dir" \
        || die "创建 CPAMP 备份目录失败。"
    timestamp=$(backup_stamp)
    data_parent=$(dirname "$data_dir")
    data_name=$(basename "$data_dir")
    data_backup="${backup_dir}/cpamp-data.predeploy.${timestamp}.tar.gz"
    data_backup_tmp="${data_backup}.tmp"
    failed_data="${backup_dir}/data.failed.${timestamp}"
    [[ "$data_was_present" == "1" ]] \
        && ensure_data_backup_space "$data_dir" "$backup_dir" "CPAMP"

    if [[ -f "$CPAMP_BIN" ]]; then
        old_binary=1
        backup_file="${backup_dir}/cpa-manager-plus.predeploy.${timestamp}"
        cp -a "$CPAMP_BIN" "$backup_file" || die "备份现有 CPAMP 二进制失败。"
    fi
    if [[ -f "$unit_file" ]]; then
        old_unit=1
        cp -a "$unit_file" "${DEPLOY_TMP}/cpamp.service.original" \
            || die "备份现有 CPAMP systemd 单元失败。"
    fi
    if [[ -f "$marker_file" ]]; then
        old_marker=1
        cp -a "$marker_file" "${DEPLOY_TMP}/cpamp.version.original" \
            || die "备份现有 CPAMP 版本标记失败。"
    fi
    if [[ -f "$env_file" ]]; then
        old_env=1
        cp -a "$env_file" "${DEPLOY_TMP}/cpamp.env.original" \
            || die "备份现有 CPAMP 环境文件失败。"
        cp -a "$env_file" "${backup_dir}/cpamp.env.${timestamp}" \
            || die "保存 CPAMP 环境文件持久备份失败。"
        chmod 0600 "${backup_dir}/cpamp.env.${timestamp}" \
            || die "设置 CPAMP 环境备份权限失败。"
    fi
    systemctl is-active --quiet "$CPAMP_SERVICE" && was_active=1
    systemctl is-enabled --quiet "$CPAMP_SERVICE" 2>/dev/null && was_enabled=1
    if [[ "$was_active" == "1" ]] && ! systemctl stop "$CPAMP_SERVICE"; then
        die "无法停止现有 CPAMP 服务。"
    fi

    if [[ "$data_was_present" == "1" ]]; then
        if ! tar --sparse -czf "$data_backup_tmp" -C "$data_parent" "$data_name" \
            || ! mv -f "$data_backup_tmp" "$data_backup" \
            || ! chmod 0600 "$data_backup"; then
            rm -f "$data_backup_tmp" "$data_backup"
            if [[ "$was_active" == "1" ]]; then
                systemctl start "$CPAMP_SERVICE" || true
            fi
            die "创建 CPAMP 一致性数据备份失败，未执行二进制替换。"
        fi
    fi

    install -m 0600 -o cpamp -g cpamp "${DEPLOY_TMP}/cpamp.env" "$env_file" \
        || install_ok=0
    if [[ "$install_ok" == "1" ]]; then
        install -m 0755 -o cpamp -g cpamp "$DEPLOY_CPAMP_CANDIDATE" \
            "${CPAMP_DIR}/.cpa-manager-plus.new" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        mv -f "${CPAMP_DIR}/.cpa-manager-plus.new" "$CPAMP_BIN" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        printf '%s\n' "$DEPLOY_CPAMP_VERSION" > "${DEPLOY_TMP}/cpamp.version"
        install -m 0644 -o cpamp -g cpamp "${DEPLOY_TMP}/cpamp.version" \
            "${CPAMP_DIR}/.version.new" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        mv -f "${CPAMP_DIR}/.version.new" "$marker_file" || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        install -m 0644 -o root -g root "${DEPLOY_TMP}/cpamp.service" "$unit_file" \
            || install_ok=0
    fi
    if [[ "$install_ok" == "1" ]]; then
        systemctl daemon-reload || install_ok=0
        systemctl enable "$CPAMP_SERVICE" >/dev/null 2>&1 || install_ok=0
    fi

    if [[ "$install_ok" == "1" ]]; then
        service_attempted=1
        if systemctl restart "$CPAMP_SERVICE" && wait_for_cpamp; then
            info "CPAMP ${DEPLOY_CPAMP_VERSION} 部署/重装完成。"
            [[ -n "$backup_file" ]] && info "原 CPAMP 二进制备份: ${backup_file}"
            [[ "$data_was_present" == "1" ]] && info "CPAMP 数据备份: ${data_backup}"
            return 0
        fi
    fi

    error "CPAMP 部署后未通过健康检查，正在恢复部署前状态..."
    systemctl stop "$CPAMP_SERVICE" >/dev/null 2>&1 || true
    rm -f "${CPAMP_DIR}/.cpa-manager-plus.new" "${CPAMP_DIR}/.version.new"
    if [[ "$old_binary" == "1" ]]; then
        install -m 0755 -o cpamp -g cpamp "$backup_file" "$CPAMP_BIN" || rollback_ok=0
    else
        rm -f "$CPAMP_BIN" || rollback_ok=0
    fi
    if [[ "$old_env" == "1" ]]; then
        install -m 0600 -o cpamp -g cpamp "${DEPLOY_TMP}/cpamp.env.original" \
            "$env_file" || rollback_ok=0
    else
        rm -f "$env_file" || rollback_ok=0
    fi
    if [[ "$old_marker" == "1" ]]; then
        cp -a "${DEPLOY_TMP}/cpamp.version.original" "$marker_file" || rollback_ok=0
    else
        rm -f "$marker_file" || rollback_ok=0
    fi
    if [[ "$old_unit" == "1" ]]; then
        cp -a "${DEPLOY_TMP}/cpamp.service.original" "$unit_file" || rollback_ok=0
        restore_service_enablement "$CPAMP_SERVICE" "$was_enabled" || rollback_ok=0
    else
        rm -f "$unit_file" || rollback_ok=0
        systemctl disable "$CPAMP_SERVICE" >/dev/null 2>&1 || true
    fi
    if [[ "$service_attempted" == "1" ]]; then
        if [[ -e "$data_dir" || -L "$data_dir" ]]; then
            if ! mv -- "$data_dir" "$failed_data"; then
                error "无法移开 CPAMP 更新后的数据目录，未覆盖现有数据。"
                rollback_ok=0
                can_restore_data=0
            else
                warn "CPAMP 失败后的数据已保留在 ${failed_data}"
            fi
        fi
        if [[ "$can_restore_data" == "1" && "$data_was_present" == "1" ]]; then
            if ! tar -xzf "$data_backup" -C "$data_parent" \
                || [[ ! -d "$data_dir" ]] \
                || ! chown -R cpamp:cpamp "$data_dir"; then
                error "恢复 CPAMP 部署前的数据备份失败。"
                rollback_ok=0
            fi
        fi
    elif [[ "$data_created" == "1" ]]; then
        rmdir "$data_dir" 2>/dev/null || rollback_ok=0
    fi
    systemctl daemon-reload || rollback_ok=0
    if [[ "$old_binary" == "1" && "$old_unit" == "1" && "$was_active" == "1" ]]; then
        if ! systemctl start "$CPAMP_SERVICE" || ! wait_for_cpamp; then
            rollback_ok=0
        fi
    fi
    if [[ "$rollback_ok" == "1" ]]; then
        warn "CPAMP 已恢复到部署前状态，数据目录未被改动。"
    else
        error "CPAMP 回滚不完整，请执行：journalctl -u cpamp -n 80 --no-pager"
    fi
    return 1
}

install_caddy_package() {
    if command -v caddy >/dev/null 2>&1; then
        info "Caddy 已安装。"
        return 0
    fi

    ensure_deploy_tmp
    info "正在添加 Caddy 官方软件源..."
    curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 \
        -o "${DEPLOY_TMP}/caddy.gpg.key" \
        'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        || die "下载 Caddy 软件源密钥失败。"
    gpg --dearmor --yes --output "${DEPLOY_TMP}/caddy-archive-keyring.gpg" \
        "${DEPLOY_TMP}/caddy.gpg.key" || die "处理 Caddy 软件源密钥失败。"
    install -m 0644 -o root -g root "${DEPLOY_TMP}/caddy-archive-keyring.gpg" \
        /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
        || die "安装 Caddy 软件源密钥失败。"
    curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 \
        -o "${DEPLOY_TMP}/caddy-stable.list" \
        'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        || die "下载 Caddy 软件源配置失败。"
    install -m 0644 -o root -g root "${DEPLOY_TMP}/caddy-stable.list" \
        /etc/apt/sources.list.d/caddy-stable.list \
        || die "安装 Caddy 软件源配置失败。"

    apt-get update -y || die "更新 Caddy 软件源失败。"
    DEBIAN_FRONTEND=noninteractive apt-get install -y caddy \
        || die "安装 Caddy 失败。"
}

prepare_caddy_config() {
    local listen_entry status_domain

    ensure_deploy_tmp
    if [[ -n "$DEPLOY_DOMAIN" && -f "$PUBLIC_STATUS_CONFIG" ]]; then
        status_domain=$(public_status_domain)
        if [[ -n "$status_domain" && "${DEPLOY_DOMAIN,,}" == "${status_domain,,}" ]]; then
            die "CPA API 域名与 Public Status 域名冲突：${DEPLOY_DOMAIN}"
        fi
    fi
    if [[ -n "$DEPLOY_DOMAIN" && -n "$TRANSLATE_DOMAIN" \
        && "${DEPLOY_DOMAIN,,}" == "${TRANSLATE_DOMAIN,,}" ]]; then
        die "普通 API 域名与已保存的高并发域名冲突：${DEPLOY_DOMAIN}"
    fi
    if [[ -n "$DEPLOY_DOMAIN" ]]; then
        listen_entry="$DEPLOY_DOMAIN"
    else
        listen_entry=":80"
    fi
    {
        printf '# Managed by cpa-deploy.sh %s\n' "$SCRIPT_VERSION"
        admission_emit_caddy_site "$listen_entry" "$CPA_ADMISSION_ADDR" "$(admission_active_limit)" \
            "$DEFAULT_BODY_LIMIT_MB"
        printf '\n%s\n' "$PUBLIC_STATUS_CADDY_IMPORT"
    } > "${DEPLOY_TMP}/Caddyfile" || die "生成 CPA Caddy 配置失败。"
}

deploy_caddy_component() {
    local caddy_file="$CADDY_CONFIG_FILE" staged_file timestamp backup_file="" answer=""
    local had_config=0 was_active=0 was_enabled=0 rollback_ok=1

    install_caddy_package
    prepare_caddy_config
    timestamp=$(backup_stamp)
    staged_file="${caddy_file}.cpa-new.${BASHPID}"
    systemctl is-active --quiet caddy && was_active=1
    systemctl is-enabled --quiet caddy 2>/dev/null && was_enabled=1

    if [[ -s "$caddy_file" ]]; then
        had_config=1
        backup_file="${caddy_file}.cpa-backup.${timestamp}"
        cp -a "$caddy_file" "$backup_file" || die "备份现有 Caddyfile 失败。"
        if ! grep -q '^# Managed by cpa-deploy.sh ' "$caddy_file" \
            && ! grep -q 'root \* /usr/share/caddy' "$caddy_file"; then
            warn "检测到非本脚本管理的 Caddyfile，备份位于 ${backup_file}"
            read -r -p '确认用 CPA 反代配置替换现有 Caddyfile [y/N]: ' answer || return 1
            [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消替换 Caddy 配置。"; return 1; }
        fi
    fi

    install -d -m 0750 -o caddy -g caddy "$CADDY_LOG_DIR" \
        || die "创建 Caddy 日志目录失败。"
    if [[ ! -e "${CADDY_LOG_DIR}/access.log" ]]; then
        install -m 0640 -o caddy -g caddy /dev/null "${CADDY_LOG_DIR}/access.log" \
            || die "创建 Caddy access.log 失败。"
    else
        if ! chown caddy:caddy "${CADDY_LOG_DIR}/access.log" \
            || ! chmod 0640 "${CADDY_LOG_DIR}/access.log"; then
            die "修正 Caddy access.log 权限失败。"
        fi
    fi
    if ! install -m 0644 -o root -g root "${DEPLOY_TMP}/Caddyfile" "$staged_file"; then
        rm -f "$staged_file"
        die "安装 Caddyfile 失败。"
    fi

    if ! caddy validate --config "$staged_file" --adapter caddyfile; then
        rm -f "$staged_file"
        error "Caddy 配置验证失败，原配置未被改动。"
        return 1
    fi
    if ! mv -f "$staged_file" "$caddy_file"; then
        rm -f "$staged_file"
        die "替换 Caddyfile 失败。"
    fi
    if ! systemctl enable caddy >/dev/null 2>&1 \
        || ! systemctl restart caddy \
        || ! systemctl is-active --quiet caddy; then
        error "Caddy 启动失败，正在恢复原配置。"
        if [[ "$had_config" == "1" ]]; then
            cp -a "$backup_file" "$caddy_file" || rollback_ok=0
        else
            rm -f "$caddy_file" || rollback_ok=0
        fi
        if [[ "$was_active" == "1" ]]; then
            systemctl restart caddy || rollback_ok=0
        else
            systemctl stop caddy >/dev/null 2>&1 || rollback_ok=0
        fi
        restore_service_enablement caddy "$was_enabled" || rollback_ok=0
        [[ "$rollback_ok" == "1" ]] \
            || error "Caddy 回滚不完整，请执行：journalctl -u caddy -n 80 --no-pager"
        return 1
    fi

    if command -v ufw >/dev/null 2>&1 \
        && ufw status 2>/dev/null | grep -q '^Status: active'; then
        ufw allow 80/tcp comment 'CPA HTTP' >/dev/null || true
        ufw allow 443/tcp comment 'CPA HTTPS' >/dev/null || true
        info "UFW 已启用：仅补充放行 80/443，未改动 SSH 和其他规则。"
    else
        info "未启用 UFW，脚本未修改防火墙。"
    fi

    info "Caddy 反向代理部署完成。"
    [[ -n "$backup_file" ]] && info "原 Caddyfile 备份: ${backup_file}"
}

reset_deployment_context() {
    if [[ -n "${DEPLOY_TMP:-}" && "$DEPLOY_TMP" == /tmp/cpa-deploy.* \
        && -d "$DEPLOY_TMP" ]]; then
        rm -rf -- "$DEPLOY_TMP"
    fi
    DEPLOY_TMP=""
    DEPLOY_DOMAIN=""
    DEPLOY_CPA_API_KEY=""
    DEPLOY_CPA_MGMT_KEY=""
    DEPLOY_CPAMP_ADMIN_KEY=""
    DEPLOY_CPA_CANDIDATE=""
    DEPLOY_CPA_VERSION=""
    DEPLOY_CPA_ASSET=""
    DEPLOY_CPAMP_CANDIDATE=""
    DEPLOY_CPAMP_VERSION=""
    DEPLOY_CPAMP_ASSET=""
}

confirm_deployment_action() {
    local description="$1" answer=""

    printf '\n%b%s%b\n' "$BOLD" "$description" "$NC"
    printf '  CPA 配置与授权目录：存在则保留\n'
    printf '  CPAMP 环境与数据目录：存在则保留\n'
    printf '  旧二进制与关键配置：替换前备份\n\n'
    read -r -p '确认继续 [y/N]: ' answer || return 1
    [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消部署/重装。"; return 1; }
}

deployment_public_ip() {
    local ip=""
    ip=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
    [[ -n "$ip" ]] || ip=$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || true)
    printf '%s\n' "${ip:-<服务器IP>}"
}

show_deployment_summary() {
    local mode="$1" endpoint server_ip

    if [[ "$mode" == "完整栈" ]]; then
        server_ip=$(deployment_public_ip)
        if [[ -n "$DEPLOY_DOMAIN" ]]; then
            endpoint="https://${DEPLOY_DOMAIN}/v1"
        else
            endpoint="http://${server_ip}/v1"
        fi
    elif [[ "$mode" == "仅 CPA 网关" || "$mode" == "CPA 网关（含准入连接迁移）" ]]; then
        endpoint="http://127.0.0.1:${CPA_PUBLIC_PORT}/v1（仅本机；准入网关）"
    fi

    printf '\n%b部署结果%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  模式:            %s\n' "$mode"
    [[ -n "${endpoint:-}" ]] && printf '  API 地址:        %s\n' "$endpoint"
    if [[ -n "$DEPLOY_CPA_API_KEY" || -n "$DEPLOY_CPA_MGMT_KEY" ]]; then
        printf '  CPA 密钥:       不回显；请在受信任终端查看 %s/config.yaml\n' "$CPA_DIR"
    fi
    if [[ -n "$DEPLOY_CPAMP_ADMIN_KEY" ]]; then
        printf '  CPAMP 密钥:     不回显；请在受信任终端查看 %s/.env\n' "$CPAMP_DIR"
    fi
    if [[ -n "$DEPLOY_CPA_API_KEY" || -n "$DEPLOY_CPA_MGMT_KEY" || -n "$DEPLOY_CPAMP_ADMIN_KEY" ]]; then
        printf '  初始凭据记录:  %s（root:root 0600；轮换后以实际配置为准）\n' "$DEPLOY_CREDENTIALS_FILE"
    fi
    if [[ "${endpoint:-}" == http://* && "$mode" == "完整栈" ]]; then
        warn "当前公网入口使用明文 HTTP；仅用于受控网络测试，生产环境请配置域名和 HTTPS。"
    fi
    printf '  CPA 授权目录:    %s\n' "${CPA_DIR}/.cli-proxy-api"
    if [[ -f "$CPAMP_BIN" ]]; then
        printf '  CPAMP SSH 隧道:  本地 18317 -> 127.0.0.1:18317\n'
        printf '  CPAMP 本地地址:  http://127.0.0.1:18317/management.html\n'
    fi
    printf '  运维命令:        cpa\n'
    printf '  准入管理:        cpa admission（或主菜单 10）\n'
    printf '  准入参数:        普通 %s / 高并发 %s / 共享 %s\n' \
        "$DEFAULT_ACTIVE" "$TRANSLATE_ACTIVE" "$GLOBAL_ACTIVE"
    if [[ "$TRANSLATE_ENABLED" == "true" ]]; then
        printf '  高并发 API:      https://%s/v1\n' "$TRANSLATE_DOMAIN"
    fi
    printf '%s\n\n' '--------------------------------------------------'
}

deploy_full_stack() {
    local need_cpa=0 need_cpamp=0

    reset_deployment_context
    deployment_preflight
    [[ -f "${CPA_DIR}/config.yaml" ]] || need_cpa=1
    [[ -f "${CPAMP_DIR}/.env" ]] || need_cpamp=1
    collect_deployment_inputs "$need_cpa" "$need_cpamp" 1 \
        || { warn "输入已结束，已取消部署/重装。"; return 0; }
    confirm_deployment_action '完整部署/重装 CPA + CPAMP + Caddy + Fail2Ban' || return 0
    save_deployment_credentials || return 1

    install_deployment_dependencies
    stage_cpa_for_deployment
    deploy_cpa_component || return 1
    deploy_cpamp_component || return 1
    public_status_with_lock deploy_caddy_component || return 1
    install_self || return 1
    install_admission_gateway || return 1
    install_fail2ban_package
    initialize_fail2ban_security || return 1
    write_deployment_state
    apply_resource_guard || return 1
    show_deployment_summary '完整栈'
}

deploy_cpa_only() {
    local need_cpa=0

    reset_deployment_context
    deployment_preflight
    [[ -f "${CPA_DIR}/config.yaml" ]] || need_cpa=1
    collect_deployment_inputs "$need_cpa" 0 0 \
        || { warn "输入已结束，已取消部署/重装。"; return 0; }
    confirm_deployment_action '仅部署/重装 CPA 网关（保留 CPAMP/Caddy 程序与数据，必要时迁移本地连接配置）' || return 0
    save_deployment_credentials || return 1

    install_deployment_dependencies
    stage_cpa_for_deployment
    deploy_cpa_component || return 1
    install_self || return 1
    install_admission_gateway || return 1
    apply_resource_guard || return 1
    show_deployment_summary 'CPA 网关（含准入连接迁移）'
}

deploy_cpamp_only() {
    local need_cpamp=0

    reset_deployment_context
    deployment_preflight
    [[ -f "$CPA_BIN" && -f "${CPA_DIR}/config.yaml" ]] \
        || die "部署 CPAMP 前必须先安装并配置 CPA。"
    [[ -f "${CPAMP_DIR}/.env" ]] || need_cpamp=1
    collect_deployment_inputs 0 "$need_cpamp" 0 \
        || { warn "输入已结束，已取消部署/重装。"; return 0; }
    confirm_deployment_action '仅部署/重装 CPAMP 面板（保留数据）' || return 0
    save_deployment_credentials || return 1

    install_deployment_dependencies
    install_self || return 1
    install_admission_gateway || return 1
    deploy_cpamp_component || return 1
    apply_resource_guard || return 1
    show_deployment_summary '仅 CPAMP 面板'
}

deployment_menu() {
    local choice=""

    admission_load_settings || return 1
    while true; do
        printf '\n%b部署/重装 CPA%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 完整部署/重装 CPA + CPAMP + Caddy + Fail2Ban\n'
        printf '  2. 仅部署/重装 CPA 网关（必要时迁移本地连接）\n'
        printf '  3. 仅部署/重装 CPAMP 面板\n'
        printf '  0. 返回主菜单\n'
        printf '%s\n' '--------------------------------------------------'
        if ! read -r -p '请选择 [0-3]: ' choice; then
            return 0
        fi
        case "$choice" in
            1) deploy_full_stack; return $? ;;
            2) deploy_cpa_only; return $? ;;
            3) deploy_cpamp_only; return $? ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项，请重新输入。" ;;
        esac
    done
}

public_status_install_rich_helper() {
    local tmp_dir helper_tmp

    tmp_dir=$(mktemp -d /tmp/cpa-public-rich-helper.XXXXXX) || return 1
    helper_tmp="${tmp_dir}/cpa-public-status-rich.py"
    cat > "$helper_tmp" <<'CPA229_RICH_HELPER_EOF'
#!/usr/bin/env python3
"""CPA/CPAMP Public Status rich data layer helper.

This helper is intentionally frontend-agnostic. It reads only local, authenticated
CPAMP/SQLite sources, emits sanitized static JSON, and never exposes CPAMP Admin
Key, raw API key hashes, raw source values, client IPs, account snapshots, paths,
or failure bodies.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import sqlite3
import sys
import tempfile
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable
from urllib.parse import quote, urlencode

DATA_LAYER_VERSION = 4
PUBLIC_FILE_CAP = 4 * 1024 * 1024
CALLS_LIMIT = 100
MODEL_LIMIT = 100
KEY_LIMIT = 100
KEY_MODEL_LIMIT = 20
CACHE_DIR_NAME = "rich-cache"
REASONING_EFFORT_VALUES = frozenset({"none", "minimal", "low", "medium", "high", "xhigh", "max"})
QUOTA_PUBLIC_DISPLAY = "GPT Team 主账号"
QUOTA_CACHE_TTL = 120
QUOTA_FIVE_HOUR_MINUTES = 300
QUOTA_SEVEN_DAY_MINUTES = 10080
QUOTA_SCAN_LIMIT = 128
QUOTA_RAW_MAX_BYTES = 256 * 1024
QUOTA_RAW_TOTAL_MAX_BYTES = 1024 * 1024
QUOTA_RAW_FALLBACK_LIMIT = QUOTA_RAW_TOTAL_MAX_BYTES // QUOTA_RAW_MAX_BYTES
QUOTA_METADATA_MAX_BYTES = 64 * 1024
QUOTA_MAX_ACCOUNTS = 8
QUOTA_DISCOVERY_SCAN_LIMIT = 512
QUOTA_DISCOVERY_TTL = 900
QUOTA_DISCOVERY_MAX_AGE_MS = 30 * 24 * 3600 * 1000
ALL_TIME_CACHE_TTL = 3600
# v2.44: Public Status C low-I/O profile; 30-second core snapshot is unchanged.
# A single source of truth for helper cache refresh and public metadata TTLs.
HISTORY_WINDOW_CACHE_TTLS = {
    "last_24h": 600,
    "last_7d": 1800,
    "last_30d": 3600,
}
BREAKDOWN_WINDOW_CACHE_TTLS = {
    "last_24h": 180,
    "last_7d": 3600,
}
CACHE_FAILURE_BACKOFF_MIN = 60
CACHE_FAILURE_BACKOFF_MAX = 900
# Keep normal read-only queries tightly bounded on low-memory hosts.
SQLITE_QUERY_TIMEOUT_SECONDS = 5.0
# Full-history aggregation has a larger budget behind the hourly cache
# and background heavy lock.
ALL_TIME_QUERY_TIMEOUT_SECONDS = 30.0
QUOTA_ACTIVE_ACCOUNT_DELAY_SECONDS = 2
QUOTA_ACTIVE_HTTP_TIMEOUT = 35
QUOTA_ACTIVE_SOURCE_KIND = "active_wham_usage"
QUOTA_PASSIVE_SOURCE_KIND = "usage_response_headers"
QUOTA_EMAIL_RE = re.compile(
    r"[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+",
    re.I,
)

SECRETISH = re.compile(r"^(?:sk|key|token|api)[-_][A-Za-z0-9_\-.]{16,}$", re.I)
BANNED_PUBLIC_KEYS = {
    "api_key_hash", "source_hash", "client_ip", "x_forwarded_for",
    "user_agent", "account_snapshot", "auth_label_snapshot", "auth_file_snapshot",
    "auth_provider_snapshot", "auth_account_id_snapshot", "auth_project_id_snapshot",
    "request_id", "event_hash", "endpoint", "fail_summary", "header_trace_id",
}


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def clean_text(value: Any, max_len: int = 160) -> str:
    if not isinstance(value, str):
        return ""
    value = "".join(ch for ch in value if ord(ch) >= 32 and ord(ch) != 127)
    return value[:max_len]


def number(value: Any, default: float = 0) -> float:
    if isinstance(value, bool):
        return default
    if isinstance(value, (int, float)):
        return value
    return default


def integer(value: Any, default: int = 0) -> int:
    if isinstance(value, bool):
        return default
    if isinstance(value, (int, float)):
        try:
            return int(value)
        except (ValueError, OverflowError):
            return default
    return default


def nullable_number(value: Any) -> float | int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return value
    return None


def nullable_integer(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        try:
            return int(value)
        except (ValueError, OverflowError):
            return None
    return None


def normalize_reasoning_effort(value: Any) -> str | None:
    """Return a public-safe reasoning effort enum or None when unavailable.

    Do not infer an effort from reasoning token counts. Only an explicit upstream
    value is accepted. Unknown/new values stay unavailable until deliberately
    reviewed, which keeps the public dashboard from manufacturing semantics.
    """
    if not isinstance(value, str):
        return None
    effort = value.strip().lower()
    return effort if effort in REASONING_EFFORT_VALUES else None


def scalar_text(value: Any, max_len: int = 160) -> str:
    if isinstance(value, list):
        for item in value:
            text = scalar_text(item, max_len)
            if text:
                return text
        return ""
    if isinstance(value, (str, int, float)) and not isinstance(value, bool):
        return clean_text(str(value), max_len).strip()
    return ""


def normalize_key(value: Any) -> str:
    return re.sub(r"[^a-z0-9]", "", clean_text(value, 160).lower())


def walk_dicts(value: Any, depth: int = 0):
    if depth > 10:
        return
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_dicts(child, depth + 1)
    elif isinstance(value, list):
        for child in value[:256]:
            yield from walk_dicts(child, depth + 1)


def find_scalar(value: Any, aliases: set[str]) -> Any:
    wanted = {normalize_key(x) for x in aliases}
    for obj in walk_dicts(value):
        for key, item in obj.items():
            if normalize_key(key) in wanted:
                if isinstance(item, list):
                    for child in item:
                        if not isinstance(child, (dict, list)):
                            return child
                elif not isinstance(item, (dict, list)):
                    return item
    return None


def find_named_dict(value: Any, aliases: set[str]) -> dict[str, Any] | None:
    wanted = {normalize_key(x) for x in aliases}
    for obj in walk_dicts(value):
        for key, item in obj.items():
            if normalize_key(key) in wanted and isinstance(item, dict):
                return item
    return None


def parse_floatish(value: Any) -> float | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        out = float(value)
    else:
        text = scalar_text(value, 64)
        if not text:
            return None
        text = text.rstrip("%").strip()
        try:
            out = float(text)
        except (TypeError, ValueError):
            return None
    if out != out or out in (float("inf"), float("-inf")):
        return None
    return out


def parse_intish(value: Any) -> int | None:
    parsed = parse_floatish(value)
    if parsed is None:
        return None
    try:
        return int(parsed)
    except (ValueError, OverflowError):
        return None


def normalize_percent(value: Any) -> float | None:
    parsed = parse_floatish(value)
    if parsed is None or parsed < 0 or parsed > 100:
        return None
    return parsed


def normalize_window_minutes(value: Any) -> int | None:
    parsed = parse_intish(value)
    if parsed is None or parsed <= 0 or parsed > 5256000:
        return None
    return parsed


def normalize_reset_at_ms(value: Any) -> int | None:
    if value is None or isinstance(value, bool):
        return None
    parsed = parse_floatish(value)
    if parsed is not None:
        if parsed <= 0:
            return None
        # Provider headers normally use Unix seconds; accept milliseconds too.
        millis = int(parsed if parsed >= 10**11 else parsed * 1000)
        return millis if millis > 0 else None
    text = scalar_text(value, 80)
    if not text:
        return None
    try:
        iso = text[:-1] + "+00:00" if text.endswith("Z") else text
        dt = datetime.fromisoformat(iso)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return int(dt.timestamp() * 1000)
    except Exception:
        return None


def normalize_plan_type(value: Any) -> str | None:
    text = scalar_text(value, 32).lower()
    if not text or not re.fullmatch(r"[a-z0-9._-]{1,32}", text):
        return None
    return text


def parse_json_text(value: Any) -> Any:
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        return json.loads(value)
    except Exception:
        return None


def read_quota_targets(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return []
    targets: list[str] = []
    seen: set[str] = set()
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() != "QUOTA_TARGET_ACCOUNT":
            continue
        parsed = quota_targets_from_identity(value.strip())
        target = parsed[0] if parsed else ""
        if not target:
            continue
        marker = target.lower()
        if marker in seen:
            continue
        seen.add(marker)
        targets.append(target)
        if len(targets) >= QUOTA_MAX_ACCOUNTS:
            break
    return targets


def read_quota_remarks(quota_config: Path) -> dict[str, str]:
    path = quota_config.with_name("quota-remarks.json")
    try:
        with path.open("r", encoding="utf-8") as f:
            value = json.load(f)
    except Exception:
        return {}
    if not isinstance(value, dict):
        return {}
    out: dict[str, str] = {}
    for raw_target, raw_remark in value.items():
        if not isinstance(raw_target, str) or not isinstance(raw_remark, str):
            continue
        parsed = quota_targets_from_identity(raw_target)
        target = parsed[0] if parsed else ""
        remark = clean_text(raw_remark, 48).strip()
        if not target or not remark or "@" in remark:
            continue
        if SECRETISH.match(remark):
            continue
        out[target] = remark
    return out


def response_headers_from_obj(value: Any) -> dict[str, Any] | None:
    for obj in walk_dicts(value):
        # Prefer an explicitly named response header map.
        for key, item in obj.items():
            if normalize_key(key) in {"responseheaders", "responseheadermap"} and isinstance(item, dict):
                return item
        # Some structured metadata stores only the allow-listed header map itself.
        normalized = {normalize_key(k) for k in obj.keys()}
        if any(k.startswith("xcodex") for k in normalized):
            return obj
    return None


def header_value(headers: dict[str, Any] | None, name: str) -> Any:
    if not isinstance(headers, dict):
        return None
    wanted = normalize_key(name)
    for key, value in headers.items():
        if normalize_key(key) == wanted:
            if isinstance(value, list):
                return value[0] if value else None
            return value
    return None


def parse_quota_window(value: Any, prefix: str, event_at_ms: int, headers: dict[str, Any] | None) -> dict[str, Any] | None:
    prefix_norm = prefix.lower()
    nested = find_named_dict(value, {prefix_norm, f"{prefix_norm}_window", f"{prefix_norm}Window"})

    used = None
    minutes = None
    window_seconds = None
    reset_at = None
    reset_after = None
    if nested:
        used = find_scalar(nested, {"used_percent", "usedPercent", "quota_used_percent"})
        minutes = find_scalar(nested, {"window_minutes", "windowMinutes", "minutes"})
        window_seconds = find_scalar(nested, {"limit_window_seconds", "limitWindowSeconds", "window_seconds", "windowSeconds"})
        reset_at = find_scalar(nested, {"reset_at", "resetAt", "resets_at", "resetsAt"})
        reset_after = find_scalar(nested, {"reset_after_seconds", "resetAfterSeconds", "resets_in_seconds", "resetsInSeconds"})

    if used is None:
        used = find_scalar(value, {
            f"{prefix_norm}_used_percent", f"{prefix_norm}UsedPercent",
            f"codex_{prefix_norm}_used_percent", f"x-codex-{prefix_norm}-used-percent",
        })
    if minutes is None:
        minutes = find_scalar(value, {
            f"{prefix_norm}_window_minutes", f"{prefix_norm}WindowMinutes",
            f"codex_{prefix_norm}_window_minutes", f"x-codex-{prefix_norm}-window-minutes",
        })
    if window_seconds is None:
        window_seconds = find_scalar(value, {
            f"{prefix_norm}_limit_window_seconds", f"{prefix_norm}LimitWindowSeconds",
            f"{prefix_norm}_window_seconds", f"{prefix_norm}WindowSeconds",
        })
    if reset_at is None:
        reset_at = find_scalar(value, {
            f"{prefix_norm}_reset_at", f"{prefix_norm}ResetAt",
            f"{prefix_norm}_resets_at", f"{prefix_norm}ResetsAt",
            f"x-codex-{prefix_norm}-reset-at",
        })
    if reset_after is None:
        reset_after = find_scalar(value, {
            f"{prefix_norm}_reset_after_seconds", f"{prefix_norm}ResetAfterSeconds",
            f"x-codex-{prefix_norm}-reset-after-seconds",
        })

    if headers:
        used = used if used is not None else header_value(headers, f"x-codex-{prefix_norm}-used-percent")
        minutes = minutes if minutes is not None else header_value(headers, f"x-codex-{prefix_norm}-window-minutes")
        reset_at = reset_at if reset_at is not None else header_value(headers, f"x-codex-{prefix_norm}-reset-at")
        reset_after = reset_after if reset_after is not None else header_value(headers, f"x-codex-{prefix_norm}-reset-after-seconds")

    used_percent = normalize_percent(used)
    window_minutes = normalize_window_minutes(minutes)
    if window_minutes is None:
        seconds_value = parse_intish(window_seconds)
        if seconds_value is not None and seconds_value > 0 and seconds_value % 60 == 0:
            window_minutes = normalize_window_minutes(seconds_value // 60)
    reset_at_ms = normalize_reset_at_ms(reset_at)
    if reset_at_ms is None:
        reset_after_seconds = parse_intish(reset_after)
        if reset_after_seconds is not None and 0 <= reset_after_seconds <= 366 * 24 * 3600:
            reset_at_ms = event_at_ms + reset_after_seconds * 1000

    if used_percent is None and window_minutes is None and reset_at_ms is None:
        return None
    return {
        "used_percent": used_percent,
        "window_minutes": window_minutes,
        "reset_at_ms": reset_at_ms,
    }


def extract_quota_evidence(value: Any, event_at_ms: int, fallback_plan: Any = None) -> dict[str, Any]:
    headers = response_headers_from_obj(value)
    plan = find_scalar(value, {
        "plan_type", "planType", "codex_plan_type", "header_quota_plan_type", "x-codex-plan-type",
    })
    if plan is None and headers:
        plan = header_value(headers, "x-codex-plan-type")
    if plan is None:
        plan = fallback_plan

    primary = parse_quota_window(value, "primary", event_at_ms, headers)
    secondary = parse_quota_window(value, "secondary", event_at_ms, headers)
    return {
        "plan_type": normalize_plan_type(plan),
        "primary": primary,
        "secondary": secondary,
    }


def quota_window_public(window: dict[str, Any], event_at_ms: int) -> dict[str, Any] | None:
    minutes = normalize_window_minutes(window.get("window_minutes"))
    used = normalize_percent(window.get("used_percent"))
    reset_at_ms = normalize_reset_at_ms(window.get("reset_at_ms"))
    # Window identity is mandatory: never infer 5h/7d from position or reset horizon.
    if minutes not in {QUOTA_FIVE_HOUR_MINUTES, QUOTA_SEVEN_DAY_MINUTES}:
        return None
    if used is None and reset_at_ms is None:
        return None
    return {
        "window_minutes": minutes,
        "used_percent": used,
        "remaining_percent": (100.0 - used) if used is not None else None,
        "reset_at_ms": reset_at_ms,
        "observed_at_ms": event_at_ms,
    }


def quota_display_name(
    index: int,
    target: str = "",
    remarks: dict[str, str] | None = None,
) -> str:
    parsed = quota_targets_from_identity(target)
    marker = parsed[0] if parsed else ""
    if marker and isinstance(remarks, dict):
        remark = clean_text(remarks.get(marker), 48).strip()
        if remark and "@" not in remark and not SECRETISH.match(remark):
            return remark
    return QUOTA_PUBLIC_DISPLAY if index == 0 else f"GPT Team 账号 {index + 1}"


def unavailable_quota(
    now_ms: int,
    display: str = QUOTA_PUBLIC_DISPLAY,
    source_kind: str = QUOTA_PASSIVE_SOURCE_KIND,
) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "available": False,
        "partial": False,
        "account": {"display": display, "plan_type": None},
        "source": {"kind": source_kind, "event_at_ms": None},
        "windows": {"five_hour": None, "seven_day": None},
    }


def sqlite_column_names(conn: sqlite3.Connection, table: str) -> set[str]:
    return {str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})")}


def open_sqlite_readonly(db_path: Path, query_timeout: float = SQLITE_QUERY_TIMEOUT_SECONDS) -> sqlite3.Connection:
    resolved = str(db_path.resolve())
    uri = "file:" + quote(resolved, safe="/") + "?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=3.0)
    conn.execute("PRAGMA query_only=ON")
    conn.execute("PRAGMA busy_timeout=3000")
    deadline = time.monotonic() + max(1.0, query_timeout)

    def abort_slow_query() -> int:
        return 1 if time.monotonic() >= deadline else 0

    conn.set_progress_handler(abort_slow_query, 10000)
    return conn


def quota_identity_columns(columns: set[str]) -> list[str]:
    return [
        name for name in (
            "account_snapshot", "auth_label_snapshot", "auth_file_snapshot", "auth_account_id_snapshot"
        ) if name in columns
    ]


def quota_identity_sql(columns: set[str]) -> tuple[str, list[str]]:
    candidates = quota_identity_columns(columns)
    if not candidates:
        return "", []
    parts = [f"instr(lower(coalesce({name}, '')), ?) > 0" for name in candidates]
    return "(" + " OR ".join(parts) + ")", candidates


def quota_target_from_auth_filename(value: Any) -> str:
    if not isinstance(value, str) or not value.strip():
        return ""
    name = re.split(r"[\\/]", value.strip())[-1]
    # CPA Codex auth files currently use: codex-<hex-id>-<email>-team.json.
    # Parse that wrapper before generic email matching; otherwise the whole filename
    # can itself look like a syntactically valid email (the v2.30 duplicate-account bug).
    match = re.fullmatch(r"codex-[0-9a-f]{6,64}-(.+)-team\.json", name, re.I)
    if not match:
        return ""
    target = match.group(1).strip().lower()
    if len(target) > 320 or any(ch.isspace() for ch in target):
        return ""
    return target if QUOTA_EMAIL_RE.fullmatch(target) else ""


def quota_targets_from_identity(value: Any) -> list[str]:
    if not isinstance(value, str) or not value.strip():
        return []
    wrapped = quota_target_from_auth_filename(value)
    if wrapped:
        return [wrapped]

    text = value.strip()
    lowered = text.lower()
    if QUOTA_EMAIL_RE.fullmatch(text):
        # Never accept an auth filename-shaped pseudo-address as an account.
        if lowered.endswith(".json") or (lowered.startswith("codex-") and "-team." in lowered):
            return []
        return [lowered]

    found: list[str] = []
    seen: set[str] = set()
    for match in QUOTA_EMAIL_RE.finditer(text):
        target = match.group(0).lower()
        if target.endswith(".json") or (target.startswith("codex-") and "-team." in target):
            continue
        if target in seen or len(target) > 320:
            continue
        seen.add(target)
        found.append(target)
    return found


def discover_team_quota_targets(db_path: Path, now_ms: int) -> list[str]:
    conn = open_sqlite_readonly(db_path)
    conn.row_factory = sqlite3.Row
    try:
        columns = sqlite_column_names(conn, "usage_events")
        identity_columns = quota_identity_columns(columns)
        if "timestamp_ms" not in columns or not identity_columns:
            return []

        fields = []
        for name in (
            "id", "timestamp_ms", "response_metadata_json", "header_quota_plan_type",
            "account_snapshot", "auth_label_snapshot", "auth_file_snapshot", "auth_account_id_snapshot",
        ):
            if name not in columns:
                continue
            if name == "response_metadata_json":
                fields.append(
                    f"case when length(cast(response_metadata_json as blob)) <= {QUOTA_METADATA_MAX_BYTES} "
                    "then response_metadata_json else '' end as response_metadata_json"
                )
            else:
                fields.append(name)
        predicates = []
        if "response_metadata_json" in columns:
            predicates.append("coalesce(response_metadata_json, '') <> ''")
        if "header_quota_plan_type" in columns:
            predicates.append("coalesce(header_quota_plan_type, '') <> ''")
        if not predicates:
            return []

        order = "timestamp_ms desc"
        if "id" in columns:
            order += ", id desc"
        min_timestamp_ms = max(0, now_ms - QUOTA_DISCOVERY_MAX_AGE_MS)
        sql = (
            f"select {', '.join(fields)} from usage_events "
            f"where timestamp_ms >= ? and ({' OR '.join(predicates)}) "
            f"order by {order} limit ?"
        )
        rows = list(conn.execute(sql, (min_timestamp_ms, QUOTA_DISCOVERY_SCAN_LIMIT)))
    finally:
        conn.close()

    found: set[str] = set()
    for row in rows:
        event_at_ms = integer(row["timestamp_ms"] if "timestamp_ms" in row.keys() else 0)
        if event_at_ms <= 0:
            continue
        metadata = parse_json_text(row["response_metadata_json"]) if "response_metadata_json" in row.keys() else None
        evidence = extract_quota_evidence(
            metadata if metadata is not None else {},
            event_at_ms,
            row["header_quota_plan_type"] if "header_quota_plan_type" in row.keys() else None,
        )
        if evidence.get("plan_type") != "team":
            continue
        for name in identity_columns:
            if name not in row.keys():
                continue
            for target in quota_targets_from_identity(row[name]):
                found.add(target)
        if len(found) >= QUOTA_MAX_ACCOUNTS * 2:
            break
    return sorted(found)


def query_quota_rows(
    conn: sqlite3.Connection,
    columns: set[str],
    target: str,
    include_raw: bool,
    limit: int,
    now_ms: int,
) -> Any:
    identity_where, identity_columns = quota_identity_sql(columns)
    if not identity_where:
        return []
    fields = []
    for name in (
        "id", "timestamp_ms", "response_metadata_json", "header_quota_plan_type",
        "account_snapshot", "auth_label_snapshot", "auth_file_snapshot", "auth_account_id_snapshot",
    ):
        if name not in columns:
            continue
        if name == "response_metadata_json":
            fields.append(
                f"case when length(cast(response_metadata_json as blob)) <= {QUOTA_METADATA_MAX_BYTES} "
                "then response_metadata_json else '' end as response_metadata_json"
            )
        else:
            fields.append(name)
    if include_raw and "raw_json" in columns:
        fields.append("raw_json")
    elif "raw_json" in columns:
        fields.append("'' as raw_json")

    predicates = []
    if include_raw:
        if "raw_json" not in columns:
            return []
        predicates.append(
            f"(coalesce(raw_json, '') <> '' and length(cast(raw_json as blob)) <= {QUOTA_RAW_MAX_BYTES} "
            "and instr(lower(raw_json), 'x-codex-') > 0)"
        )
    else:
        if "response_metadata_json" in columns:
            predicates.append(
                f"(coalesce(response_metadata_json, '') <> '' "
                f"and length(cast(response_metadata_json as blob)) <= {QUOTA_METADATA_MAX_BYTES})"
            )
        if "header_quota_plan_type" in columns:
            predicates.append("coalesce(header_quota_plan_type, '') <> ''")
    if not predicates:
        return []

    order = "timestamp_ms desc"
    if "id" in columns:
        order += ", id desc"
    min_timestamp_ms = max(0, now_ms - QUOTA_DISCOVERY_MAX_AGE_MS)
    time_where = "timestamp_ms >= ? and " if "timestamp_ms" in columns else ""
    sql = (
        f"select {', '.join(fields)} from usage_events where {time_where}{identity_where} "
        f"and ({' OR '.join(predicates)}) order by {order} limit ?"
    )
    params: list[Any] = []
    if time_where:
        params.append(min_timestamp_ms)
    params.extend([target.lower()] * len(identity_columns))
    params.append(limit)
    return conn.execute(sql, params)


def latest_auth_file_for_target(db_path: Path, target: str) -> str:
    parsed = quota_targets_from_identity(target)
    canonical = parsed[0] if parsed else ""
    if not canonical:
        return ""
    conn = open_sqlite_readonly(db_path)
    conn.row_factory = sqlite3.Row
    try:
        columns = sqlite_column_names(conn, "usage_events")
        if "timestamp_ms" not in columns or "auth_file_snapshot" not in columns:
            return ""
        identity_where, identity_columns = quota_identity_sql(columns)
        if not identity_where:
            return ""
        order = "timestamp_ms desc"
        if "id" in columns:
            order += ", id desc"
        min_timestamp_ms = max(0, int(time.time() * 1000) - QUOTA_DISCOVERY_MAX_AGE_MS)
        sql = (
            f"select auth_file_snapshot from usage_events where timestamp_ms >= ? and {identity_where} "
            f"and coalesce(auth_file_snapshot, '') <> '' order by {order} limit 32"
        )
        rows = list(conn.execute(sql, [min_timestamp_ms] + [canonical] * len(identity_columns)))
    finally:
        conn.close()
    for row in rows:
        name = scalar_text(row["auth_file_snapshot"], 512).strip()
        if canonical in quota_targets_from_identity(name):
            return name
    return ""


def quota_from_evidence(
    evidence: dict[str, Any],
    event_at_ms: int,
    display: str,
    source_kind: str,
) -> dict[str, Any]:
    five_hour = None
    seven_day = None
    for window in (evidence.get("primary"), evidence.get("secondary")):
        if not isinstance(window, dict):
            continue
        public_window = quota_window_public(window, event_at_ms)
        if public_window is None:
            continue
        minutes = public_window["window_minutes"]
        if minutes == QUOTA_FIVE_HOUR_MINUTES and five_hour is None:
            five_hour = public_window
        elif minutes == QUOTA_SEVEN_DAY_MINUTES and seven_day is None:
            seven_day = public_window
    if five_hour is None and seven_day is None:
        return unavailable_quota(event_at_ms, display, source_kind)
    return {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": event_at_ms,
        "available": True,
        "partial": five_hour is None or seven_day is None,
        "account": {"display": display, "plan_type": normalize_plan_type(evidence.get("plan_type"))},
        "source": {"kind": source_kind, "event_at_ms": event_at_ms},
        "windows": {"five_hour": five_hour, "seven_day": seven_day},
    }


def quota_target_hash(target: str) -> str:
    return hashlib.sha256(target.strip().lower().encode("utf-8")).hexdigest()[:16]


def active_cache_entry_for_target(cache_obj: Any, target: str) -> dict[str, Any] | None:
    if not isinstance(cache_obj, dict):
        return None
    accounts = cache_obj.get("accounts")
    if not isinstance(accounts, dict):
        return None
    parsed = quota_targets_from_identity(target)
    canonical = parsed[0] if parsed else ""
    if not canonical:
        return None

    exact_key = quota_target_hash(canonical)
    best: dict[str, Any] | None = None
    best_score = (-1, -1, -1)
    for key, raw_entry in accounts.items():
        if not isinstance(raw_entry, dict):
            continue
        entry_targets = quota_targets_from_identity(raw_entry.get("target"))
        if str(key) != exact_key and canonical not in entry_targets:
            continue
        quota = raw_entry.get("quota") if isinstance(raw_entry.get("quota"), dict) else None
        score = (
            1 if isinstance(quota, dict) and quota.get("available") is True else 0,
            quota_event_at(quota),
            integer(raw_entry.get("last_success_ms")),
        )
        if score > best_score:
            best = raw_entry
            best_score = score
    return best


def active_quota_from_cache(cache_obj: Any, target: str) -> dict[str, Any] | None:
    entry = active_cache_entry_for_target(cache_obj, target)
    if not isinstance(entry, dict):
        return None
    quota = entry.get("quota")
    return quota if isinstance(quota, dict) else None


def quota_event_at(value: Any) -> int:
    if not isinstance(value, dict):
        return 0
    source = value.get("source")
    if not isinstance(source, dict):
        return 0
    return integer(source.get("event_at_ms"))


def choose_quota_value(
    passive: dict[str, Any],
    active: dict[str, Any] | None,
    display: str,
) -> dict[str, Any]:
    if not isinstance(active, dict):
        selected = passive
    elif active.get("available") is True and passive.get("available") is not True:
        selected = active
    elif passive.get("available") is True and active.get("available") is not True:
        selected = passive
    elif quota_event_at(active) >= quota_event_at(passive):
        selected = active
    else:
        selected = passive
    out = dict(selected)
    account = out.get("account") if isinstance(out.get("account"), dict) else {}
    out["account"] = {"display": display, "plan_type": normalize_plan_type(account.get("plan_type"))}
    return out


def read_secret_file(path: Path) -> str:
    try:
        value = path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""
    if not value or len(value) > 1024 or any(ch in value for ch in "\r\n"):
        return ""
    return value


def management_request_json(
    origin: str,
    management_key: str,
    path: str,
    method: str = "GET",
    payload: dict[str, Any] | None = None,
    timeout: float = QUOTA_ACTIVE_HTTP_TIMEOUT,
) -> tuple[int, Any]:
    url = origin.rstrip("/") + path
    data = None
    headers = {"Authorization": f"Bearer {management_key}", "Accept": "application/json"}
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(request, timeout=timeout) as response:
            raw = response.read(8 * 1024 * 1024 + 1)
            if len(raw) > 8 * 1024 * 1024:
                raise RuntimeError("management response too large")
            try:
                parsed = json.loads(raw.decode("utf-8")) if raw else {}
            except Exception:
                parsed = None
            return int(response.status), parsed
    except urllib.error.HTTPError as exc:
        try:
            raw = exc.read(1024 * 1024)
            parsed = json.loads(raw.decode("utf-8")) if raw else None
        except Exception:
            parsed = None
        return int(exc.code), parsed


def auth_files_list(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return [item for item in value if isinstance(item, dict)]
    if isinstance(value, dict):
        for key in ("files", "auth_files", "auth-files", "items", "data"):
            items = value.get(key)
            if isinstance(items, list):
                return [item for item in items if isinstance(item, dict)]
    return []


def auth_item_index(item: dict[str, Any]) -> str:
    for key in ("auth_index", "authIndex", "index", "id"):
        value = item.get(key)
        text = scalar_text(value, 256).strip()
        if text:
            return text
    name = scalar_text(item.get("name"), 256).strip()
    return name[:-5] if name.lower().endswith(".json") else name


def auth_item_name(item: dict[str, Any]) -> str:
    for key in ("name", "file", "filename", "auth_file"):
        value = scalar_text(item.get(key), 256).strip()
        if value:
            return value
    return ""


def auth_item_is_codex(item: dict[str, Any]) -> bool:
    if item.get("disabled") is True:
        return False
    provider = scalar_text(item.get("provider") or item.get("type"), 64).lower()
    if provider:
        return "codex" in provider or "openai" in provider
    name = auth_item_name(item).lower()
    return name.startswith("codex-") or "codex" in name


def auth_item_quota_targets(item: dict[str, Any]) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    # Prefer identity-ish fields, then inspect remaining string metadata.  Every value
    # goes through the same canonical parser, so auth filenames are aliases, not accounts.
    preferred_keys = (
        "email", "account", "account_email", "accountEmail", "label",
        "name", "file", "filename", "auth_file",
    )
    values: list[str] = []
    for key in preferred_keys:
        value = item.get(key)
        if isinstance(value, str):
            values.append(value)
    for obj in walk_dicts(item):
        for value in obj.values():
            if isinstance(value, str):
                values.append(value)
    for value in values:
        for target in quota_targets_from_identity(value):
            if target in seen:
                continue
            seen.add(target)
            found.append(target)
    return found


def auth_item_health_score(item: dict[str, Any]) -> int:
    score = 0
    if item.get("disabled") is True:
        return -10000
    if item.get("unavailable") is True:
        score -= 500
    status = scalar_text(item.get("status") or item.get("state"), 64).strip().lower()
    if status in {"active", "ready", "ok", "healthy", "available", "valid"}:
        score += 200
    elif status in {"disabled", "expired", "error", "failed", "unavailable", "invalid"}:
        score -= 200
    if auth_item_is_codex(item):
        score += 100
    return score


def find_auth_items_for_target(
    items: list[dict[str, Any]],
    target: str,
    preferred_auth_file: str = "",
) -> list[dict[str, Any]]:
    parsed = quota_targets_from_identity(target)
    canonical = parsed[0] if parsed else ""
    if not canonical:
        return []
    preferred_name = re.split(r"[\\/]", preferred_auth_file.strip())[-1].lower() if preferred_auth_file else ""
    scored: list[tuple[int, int, dict[str, Any]]] = []
    seen_index: set[str] = set()
    for order, item in enumerate(items):
        if item.get("disabled") is True or canonical not in auth_item_quota_targets(item):
            continue
        auth_index = auth_item_index(item)
        if auth_index and auth_index in seen_index:
            continue
        if auth_index:
            seen_index.add(auth_index)
        score = auth_item_health_score(item)
        name = re.split(r"[\\/]", auth_item_name(item).strip())[-1].lower()
        if preferred_name and name == preferred_name:
            score += 10000
        scored.append((score, -order, item))
    scored.sort(key=lambda row: (row[0], row[1]), reverse=True)
    return [item for _, _, item in scored]


def decode_jwt_payload(token: str) -> dict[str, Any]:
    parts = token.split(".")
    if len(parts) < 2:
        return {}
    try:
        padded = parts[1] + "=" * (-len(parts[1]) % 4)
        value = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")).decode("utf-8"))
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def account_id_from_value(value: Any) -> str:
    direct = find_scalar(value, {
        "account_id", "accountId", "chatgpt_account_id", "chatgptAccountId",
        "chatgpt-account-id", "chatgpt_account_id",
    })
    text = scalar_text(direct, 160).strip()
    if text:
        return text
    id_token = find_scalar(value, {"id_token", "idToken"})
    token_text = scalar_text(id_token, 65536).strip()
    if token_text:
        claims = decode_jwt_payload(token_text)
        auth_obj = claims.get("https://api.openai.com/auth") if isinstance(claims, dict) else None
        if isinstance(auth_obj, dict):
            text = scalar_text(auth_obj.get("chatgpt_account_id") or auth_obj.get("account_id"), 160).strip()
            if text:
                return text
    return ""


def resolve_account_id(
    origin: str,
    management_key: str,
    item: dict[str, Any],
) -> str:
    account_id = account_id_from_value(item)
    if account_id:
        return account_id
    name = auth_item_name(item)
    if not name:
        return ""
    status, value = management_request_json(
        origin,
        management_key,
        "/v0/management/auth-files/download?" + urlencode({"name": name}),
        timeout=10.0,
    )
    if status != 200 or value is None:
        return ""
    return account_id_from_value(value)


def active_quota_request(
    origin: str,
    management_key: str,
    auth_index: str,
    account_id: str,
    now_ms: int,
    display: str,
) -> tuple[dict[str, Any] | None, str, int | None]:
    headers = {
        "Authorization": "Bearer $TOKEN$",
        "Accept": "application/json",
        "User-Agent": "codex_cli_rs/0.76.0 (Debian 13.0.0; x86_64)",
        "Origin": "https://chatgpt.com",
        "Referer": "https://chatgpt.com/",
    }
    if account_id:
        headers["Chatgpt-Account-Id"] = account_id
    payload = {
        "auth_index": auth_index,
        "method": "GET",
        "url": "https://chatgpt.com/backend-api/wham/usage",
        "header": headers,
    }
    status, response = management_request_json(
        origin,
        management_key,
        "/v0/management/api-call",
        method="POST",
        payload=payload,
        timeout=QUOTA_ACTIVE_HTTP_TIMEOUT,
    )
    if status != 200 or not isinstance(response, dict):
        return None, f"management_http_{status}", status
    upstream_status = parse_intish(response.get("status_code"))
    if upstream_status != 200:
        return None, f"upstream_http_{upstream_status or 0}", upstream_status
    body = response.get("body")
    body_obj = parse_json_text(body) if isinstance(body, str) else body
    if not isinstance(body_obj, dict):
        return None, "invalid_usage_body", upstream_status
    evidence = extract_quota_evidence(body_obj, now_ms)
    quota = quota_from_evidence(evidence, now_ms, display, QUOTA_ACTIVE_SOURCE_KIND)
    if quota.get("available") is not True:
        return None, "unsupported_usage_shape", upstream_status
    return quota, "ok", upstream_status


def active_quota_refresh(
    db_path: Path,
    quota_config: Path,
    private_dir: Path,
    cpa_origin: str,
    management_key_file: Path,
) -> dict[str, Any]:
    now_ms = int(time.time() * 1000)

    configured = read_quota_targets(quota_config)
    configured_set = {target.lower() for target in configured}
    quota_remarks = {
        key: value for key, value in read_quota_remarks(quota_config).items()
        if key in configured_set
    }
    discovered = discover_team_quota_targets(db_path, now_ms)
    targets: list[str] = []
    seen: set[str] = set()
    for raw_target in configured + discovered:
        parsed = quota_targets_from_identity(raw_target)
        target = parsed[0] if parsed else ""
        if not target:
            continue
        marker = target.lower()
        if marker in seen:
            continue
        seen.add(marker)
        targets.append(target)
        if len(targets) >= QUOTA_MAX_ACCOUNTS:
            break

    active_path = private_dir / "quota-active.json"
    previous = load_json(active_path, {})
    previous_accounts = previous.get("accounts") if isinstance(previous, dict) else {}
    if not isinstance(previous_accounts, dict):
        previous_accounts = {}
    if not targets:
        result = dict(previous) if isinstance(previous, dict) else {}
        result["schema_version"] = integer(result.get("schema_version"), 1) or 1
        result["generated_at_ms"] = int(time.time() * 1000)
        result["last_run"] = {
            "started_at_ms": now_ms,
            "finished_at_ms": int(time.time() * 1000),
            "targets": 0,
            "success": 0,
            "failed": 0,
        }
        result["accounts"] = previous_accounts
        private_dir.mkdir(parents=True, exist_ok=True)
        os.chmod(private_dir, 0o755)
        atomic_write_json(active_path, result, 0o600)
        return result

    management_key = read_secret_file(management_key_file)
    if not management_key:
        raise RuntimeError("CPA management key unavailable")

    status, auth_value = management_request_json(
        cpa_origin,
        management_key,
        "/v0/management/auth-files",
        timeout=12.0,
    )
    if status != 200:
        raise RuntimeError(f"auth-files HTTP {status}")
    auth_items = auth_files_list(auth_value)

    accounts: dict[str, Any] = {}
    success = 0
    failed = 0

    for index, target in enumerate(targets):
        target_key = quota_target_hash(target)
        prior = active_cache_entry_for_target(previous, target)
        prior = prior if isinstance(prior, dict) else {}
        entry: dict[str, Any] = {
            "target": target,
            "last_attempt_ms": now_ms,
            "last_success_ms": integer(prior.get("last_success_ms")) or None,
            "last_status": "auth_not_found",
            "last_http_status": None,
        }
        prior_quota = prior.get("quota") if isinstance(prior.get("quota"), dict) else None
        if prior_quota is not None:
            entry["quota"] = prior_quota

        preferred_auth_file = latest_auth_file_for_target(db_path, target)
        candidates = find_auth_items_for_target(auth_items, target, preferred_auth_file)
        if not candidates:
            failed += 1
            accounts[target_key] = entry
            continue

        quota = None
        result_status = "auth_not_found"
        upstream_status = None
        attempted = 0
        for item in candidates[:4]:
            auth_index = auth_item_index(item)
            if not auth_index:
                continue
            attempted += 1
            account_id = resolve_account_id(cpa_origin, management_key, item)
            quota, result_status, upstream_status = active_quota_request(
                cpa_origin,
                management_key,
                auth_index,
                account_id,
                int(time.time() * 1000),
                quota_display_name(index, target, quota_remarks),
            )
            if quota is not None:
                break
            # A stale credential for the same logical email can return 401/403.
            # Only in that case try the next matching auth file; other failures are
            # treated as account/upstream failures and are not multiplied.
            if result_status not in {"upstream_http_401", "upstream_http_403"}:
                break

        if attempted == 0:
            result_status = "auth_index_missing"
        entry["last_status"] = result_status
        entry["last_http_status"] = upstream_status
        if quota is not None:
            entry["quota"] = quota
            entry["last_success_ms"] = quota_event_at(quota) or int(time.time() * 1000)
            success += 1
        else:
            failed += 1
        accounts[target_key] = entry
        if index + 1 < len(targets):
            time.sleep(QUOTA_ACTIVE_ACCOUNT_DELAY_SECONDS)

    result = {
        "schema_version": 1,
        "generated_at_ms": int(time.time() * 1000),
        "last_run": {
            "started_at_ms": now_ms,
            "finished_at_ms": int(time.time() * 1000),
            "targets": len(targets),
            "success": success,
            "failed": failed,
        },
        "accounts": accounts,
    }
    private_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(private_dir, 0o755)
    atomic_write_json(active_path, result, 0o600)
    return result


def active_quota_refresh_main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--active-quota-refresh", action="store_true", required=True)
    ap.add_argument("--db-path", required=True)
    ap.add_argument("--quota-config", required=True)
    ap.add_argument("--private-dir", required=True)
    ap.add_argument("--cpa-origin", required=True)
    ap.add_argument("--management-key-file", required=True)
    args = ap.parse_args(argv)
    result = active_quota_refresh(
        Path(args.db_path),
        Path(args.quota_config),
        Path(args.private_dir),
        args.cpa_origin,
        Path(args.management_key_file),
    )
    last_run = result.get("last_run") if isinstance(result, dict) else {}
    eprint(
        "[INFO] active quota refresh: "
        f"targets={integer(last_run.get('targets'))} "
        f"success={integer(last_run.get('success'))} "
        f"failed={integer(last_run.get('failed'))}"
    )
    targets = integer(last_run.get("targets"))
    success = integer(last_run.get("success"))
    failed = integer(last_run.get("failed"))
    if targets <= 0:
        return 10
    if success <= 0 and failed > 0:
        return 12
    if failed > 0:
        return 11
    return 0


def build_account_quota(db_path: Path, now_ms: int, quota_target: str, display: str = QUOTA_PUBLIC_DISPLAY) -> dict[str, Any]:
    five_hour = None
    seven_day = None
    plan_type = None
    source_event_ms = 0
    raw_total_bytes = 0

    def consume(rows_to_scan: Any, use_raw: bool) -> None:
        nonlocal five_hour, seven_day, plan_type, source_event_ms, raw_total_bytes
        for row in rows_to_scan:
            event_at_ms = integer(row["timestamp_ms"] if "timestamp_ms" in row.keys() else 0)
            if event_at_ms <= 0:
                continue
            metadata = parse_json_text(row["response_metadata_json"]) if "response_metadata_json" in row.keys() else None
            evidence = extract_quota_evidence(
                metadata if metadata is not None else {},
                event_at_ms,
                row["header_quota_plan_type"] if "header_quota_plan_type" in row.keys() else None,
            )
            if use_raw and (not evidence.get("primary") or not evidence.get("secondary")) and "raw_json" in row.keys():
                raw_text = row["raw_json"] if isinstance(row["raw_json"], str) else ""
                raw_bytes = len(raw_text.encode("utf-8", errors="ignore"))
                if raw_bytes <= 0:
                    continue
                if raw_total_bytes + raw_bytes > QUOTA_RAW_TOTAL_MAX_BYTES:
                    break
                raw_total_bytes += raw_bytes
                raw_obj = parse_json_text(raw_text)
                if raw_obj is not None:
                    raw_evidence = extract_quota_evidence(raw_obj, event_at_ms, evidence.get("plan_type"))
                    if not evidence.get("primary"):
                        evidence["primary"] = raw_evidence.get("primary")
                    if not evidence.get("secondary"):
                        evidence["secondary"] = raw_evidence.get("secondary")
                    if not evidence.get("plan_type"):
                        evidence["plan_type"] = raw_evidence.get("plan_type")

            if plan_type is None and evidence.get("plan_type"):
                plan_type = evidence["plan_type"]

            for window in (evidence.get("primary"), evidence.get("secondary")):
                if not isinstance(window, dict):
                    continue
                public_window = quota_window_public(window, event_at_ms)
                if public_window is None:
                    continue
                minutes = public_window["window_minutes"]
                if minutes == QUOTA_FIVE_HOUR_MINUTES and five_hour is None:
                    five_hour = public_window
                    source_event_ms = max(source_event_ms, event_at_ms)
                elif minutes == QUOTA_SEVEN_DAY_MINUTES and seven_day is None:
                    seven_day = public_window
                    source_event_ms = max(source_event_ms, event_at_ms)
            if five_hour is not None and seven_day is not None and plan_type is not None:
                break

    conn = open_sqlite_readonly(db_path)
    conn.row_factory = sqlite3.Row
    try:
        columns = sqlite_column_names(conn, "usage_events")
        if "timestamp_ms" not in columns:
            return unavailable_quota(now_ms, display)
        consume(
            query_quota_rows(conn, columns, quota_target, False, QUOTA_SCAN_LIMIT, now_ms),
            False,
        )
    finally:
        conn.close()

    if (five_hour is None or seven_day is None) and "raw_json" in columns:
        conn = open_sqlite_readonly(db_path)
        conn.row_factory = sqlite3.Row
        try:
            consume(
                query_quota_rows(
                    conn, columns, quota_target, True, QUOTA_RAW_FALLBACK_LIMIT, now_ms
                ),
                True,
            )
        finally:
            conn.close()

    if five_hour is None and seven_day is None:
        return unavailable_quota(now_ms, display)

    return {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "available": True,
        "partial": five_hour is None or seven_day is None,
        "account": {"display": display, "plan_type": plan_type},
        "source": {"kind": QUOTA_PASSIVE_SOURCE_KIND, "event_at_ms": source_event_ms or None},
        "windows": {"five_hour": five_hour, "seven_day": seven_day},
    }


def quota_account_public_item(value: dict[str, Any], display: str) -> dict[str, Any]:
    account = value.get("account") if isinstance(value.get("account"), dict) else {}
    source = value.get("source") if isinstance(value.get("source"), dict) else {}
    windows = value.get("windows") if isinstance(value.get("windows"), dict) else {}
    return {
        "available": value.get("available") is True,
        "partial": value.get("partial") is True,
        "account": {
            "display": display,
            "plan_type": normalize_plan_type(account.get("plan_type")),
        },
        "source": {
            "kind": clean_text(source.get("kind"), 64) if clean_text(source.get("kind"), 64) in {QUOTA_PASSIVE_SOURCE_KIND, QUOTA_ACTIVE_SOURCE_KIND} else QUOTA_PASSIVE_SOURCE_KIND,
            "event_at_ms": integer(source.get("event_at_ms")) or None,
        },
        "windows": {
            "five_hour": windows.get("five_hour") if isinstance(windows.get("five_hour"), dict) else None,
            "seven_day": windows.get("seven_day") if isinstance(windows.get("seven_day"), dict) else None,
        },
    }


def build_multi_account_quota_payload(now_ms: int, account_values: list[tuple[str, dict[str, Any]]]) -> dict[str, Any]:
    if not account_values:
        payload = unavailable_quota(now_ms)
        payload["account_count"] = 0
        payload["accounts"] = []
        return payload

    public_accounts = [quota_account_public_item(value, display) for display, value in account_values]
    legacy = next((item for item in public_accounts if item.get("available") is True), public_accounts[0])
    return {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "available": any(item.get("available") is True for item in public_accounts),
        "partial": any(item.get("available") is not True or item.get("partial") is True for item in public_accounts),
        "account_count": len(public_accounts),
        "accounts": public_accounts,
        # Backward-compatible single-account view for older frontends.
        "account": legacy["account"],
        "source": legacy["source"],
        "windows": legacy["windows"],
    }


def load_json(path: Path, default: Any = None) -> Any:
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def dump_bytes(obj: Any) -> bytes:
    return (json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=False) + "\n").encode("utf-8")


def atomic_write_json(path: Path, obj: Any, mode: int) -> None:
    data = dump_bytes(obj)
    if mode == 0o644 and len(data) > PUBLIC_FILE_CAP:
        raise RuntimeError(f"public JSON too large: {path.name}={len(data)} bytes")
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp_name, mode)
        os.replace(tmp_name, path)
    except Exception:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass
        raise


def atomic_write_json_if_changed(
    path: Path,
    obj: Any,
    mode: int,
    ignore_top_level_keys: tuple[str, ...] = (),
) -> bool:
    existing = load_json(path, None)
    if isinstance(existing, dict) and isinstance(obj, dict):
        ignored = set(ignore_top_level_keys)
        old_cmp = {k: v for k, v in existing.items() if k not in ignored}
        new_cmp = {k: v for k, v in obj.items() if k not in ignored}
        if old_cmp == new_cmp:
            return False
    elif existing == obj:
        return False
    atomic_write_json(path, obj, mode)
    return True


def file_age(path: Path) -> float:
    try:
        return max(0.0, time.time() - path.stat().st_mtime)
    except OSError:
        return 10**12


def unwrap(obj: Any) -> Any:
    if isinstance(obj, dict) and isinstance(obj.get("data"), dict):
        return obj["data"]
    if isinstance(obj, dict) and isinstance(obj.get("result"), dict):
        return obj["result"]
    return obj


def alias_array(obj: Any) -> list[dict[str, Any]]:
    if isinstance(obj, list):
        return [x for x in obj if isinstance(x, dict)]
    if isinstance(obj, dict):
        for key in ("items", "data"):
            value = obj.get(key)
            if isinstance(value, list):
                return [x for x in value if isinstance(x, dict)]
    return []


def event_array(obj: Any) -> list[dict[str, Any]]:
    if not isinstance(obj, dict):
        return []
    candidates = [obj]
    if isinstance(obj.get("data"), dict):
        candidates.append(obj["data"])
    for root in candidates:
        events = root.get("events") if isinstance(root, dict) else None
        if isinstance(events, dict) and isinstance(events.get("items"), list):
            return [x for x in events["items"] if isinstance(x, dict)]
    return []


def safe_alias(value: Any) -> str:
    text = clean_text(value, 80).strip()
    if not text:
        return ""
    # Never trust an alias blindly: users may accidentally paste a secret as a note.
    if SECRETISH.match(text) and "*" not in text and "..." not in text:
        return ""
    return text


def safe_mask(value: Any) -> str:
    text = clean_text(value, 120).strip()
    if text.startswith("m:"):
        text = text[2:]
    # Only expose CPAMP values that are already visibly masked.
    if not text or ("*" not in text and "..." not in text):
        return ""
    text = text.replace("...", "******")
    return text[:80]


def stable_key_id(api_key_hash: Any) -> str:
    h = clean_text(api_key_hash, 256)
    if not h:
        return "k_unknown"
    digest = hashlib.sha256(("cpamp-public-status-v2:" + h).encode("utf-8")).hexdigest()[:12]
    return "k_" + digest


def build_alias_map(alias_obj: Any) -> dict[str, str]:
    out: dict[str, str] = {}
    for item in alias_array(alias_obj):
        h = clean_text(item.get("apiKeyHash") or item.get("api_key_hash"), 256)
        a = safe_alias(item.get("alias"))
        if h and a:
            out[h] = a
    return out


def key_identity(api_key_hash: Any, source: Any, aliases: dict[str, str]) -> dict[str, str]:
    h = clean_text(api_key_hash, 256)
    kid = stable_key_id(h)
    alias = aliases.get(h, "") if h else ""
    if alias:
        return {"id": kid, "display": alias, "kind": "alias"}
    masked = safe_mask(source)
    if masked:
        return {"id": kid, "display": masked, "kind": "masked"}
    suffix = kid[-6:].upper() if kid != "k_unknown" else "UNKNOWN"
    return {"id": kid, "display": f"未备注 Key · {suffix}", "kind": "anonymous"}


def read_auth_header(path: Path) -> str:
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.lower().startswith("authorization:"):
                value = line.split(":", 1)[1].strip()
                if value:
                    return value
    except Exception:
        pass
    raise RuntimeError("missing private Authorization header")


def post_json(origin: str, auth_header: str, payload: dict[str, Any], timeout: float = 15.0, max_bytes: int = 8 * 1024 * 1024) -> dict[str, Any]:
    body = dump_bytes(payload)
    req = urllib.request.Request(
        origin.rstrip("/") + "/v0/management/monitoring/analytics",
        data=body,
        method="POST",
        headers={
            "Authorization": auth_header,
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "cpa-public-status-rich/3",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        if resp.status < 200 or resp.status >= 300:
            raise RuntimeError(f"Monitoring HTTP {resp.status}")
        raw = resp.read(max_bytes + 1)
        if len(raw) > max_bytes:
            raise RuntimeError("Monitoring response exceeds cap")
    parsed = json.loads(raw.decode("utf-8"))
    parsed = unwrap(parsed)
    if not isinstance(parsed, dict):
        raise RuntimeError("Monitoring response is not an object")
    return parsed


def summarize(summary: Any) -> dict[str, Any]:
    s = summary if isinstance(summary, dict) else {}
    return {
        "requests": nullable_integer(s.get("total_calls")),
        "success_requests": nullable_integer(s.get("success_calls")),
        "failed_requests": nullable_integer(s.get("failure_calls")),
        "success_rate": nullable_number(s.get("success_rate")),
        "tokens": {
            "input": nullable_integer(s.get("input_tokens")),
            "output": nullable_integer(s.get("output_tokens")),
            "cached": nullable_integer(s.get("cached_tokens")),
            "cache_read": nullable_integer(s.get("cache_read_tokens")),
            "cache_creation": nullable_integer(s.get("cache_creation_tokens")),
            "reasoning": nullable_integer(s.get("reasoning_tokens")),
            "total": nullable_integer(s.get("total_tokens")),
        },
        "cost_usd": nullable_number(s.get("total_cost")),
        "avg_cost_per_call_usd": nullable_number(s.get("average_cost_per_call")),
        "avg_latency_ms": nullable_number(s.get("average_latency_ms")),
        "p95_latency_ms": nullable_number(s.get("p95_latency_ms")),
        "p95_ttft_ms": nullable_number(s.get("p95_ttft_ms")),
        "rpm_30m": nullable_number(s.get("rpm_30m")),
        "tpm_30m": nullable_number(s.get("tpm_30m")),
    }


def sanitize_timeline(items: Any, cap: int = 1000) -> list[dict[str, Any]]:
    if not isinstance(items, list):
        return []
    out: list[dict[str, Any]] = []
    for p in items[-cap:]:
        if not isinstance(p, dict):
            continue
        out.append({
            "bucket_ms": nullable_integer(p.get("bucket_ms")),
            "label": clean_text(p.get("label"), 64),
            "requests": nullable_integer(p.get("calls")),
            "success_requests": nullable_integer(p.get("success")),
            "failed_requests": nullable_integer(p.get("failure")),
            "success_rate": nullable_number(p.get("success_rate")),
            "failure_rate": nullable_number(p.get("failure_rate")),
            "tokens": {
                "input": nullable_integer(p.get("input_tokens")),
                "output": nullable_integer(p.get("output_tokens")),
                "cached": nullable_integer(p.get("cached_tokens")),
                "cache_read": nullable_integer(p.get("cache_read_tokens")),
                "cache_creation": nullable_integer(p.get("cache_creation_tokens")),
                "reasoning": nullable_integer(p.get("reasoning_tokens")),
                "total": nullable_integer(p.get("total_tokens", p.get("tokens"))),
            },
            "cost_usd": nullable_number(p.get("cost")),
            "avg_latency_ms": nullable_number(p.get("average_latency_ms")),
            "p95_latency_ms": nullable_number(p.get("p95_latency_ms")),
            "p95_ttft_ms": nullable_number(p.get("p95_ttft_ms")),
        })
    return out


def fetch_history_window(origin: str, auth: str, name: str, from_ms: int, to_ms: int) -> dict[str, Any]:
    response = post_json(origin, auth, {
        "from_ms": from_ms,
        "to_ms": to_ms,
        "now_ms": to_ms,
        "include": {
            "summary": True,
            "summary_profile": "compact",
            "timeline": True,
        },
    })
    return {
        "name": name,
        "from_ms": from_ms,
        "to_ms": to_ms,
        "generated_at_ms": integer(response.get("generated_at_ms"), int(time.time() * 1000)),
        "granularity": clean_text(response.get("granularity"), 32),
        "summary": summarize(response.get("summary")),
        "points": sanitize_timeline(response.get("timeline")),
    }


def sanitize_model_stats(items: Any) -> list[dict[str, Any]]:
    if not isinstance(items, list):
        return []
    rows: list[dict[str, Any]] = []
    for m in items:
        if not isinstance(m, dict):
            continue
        rows.append({
            "model": clean_text(m.get("model") or "unknown", 160),
            "requests": nullable_integer(m.get("calls")),
            "success_requests": nullable_integer(m.get("success_calls")),
            "failed_requests": nullable_integer(m.get("failure_calls")),
            "success_rate": nullable_number(m.get("success_rate")),
            "tokens": {
                "input": nullable_integer(m.get("input_tokens")),
                "output": nullable_integer(m.get("output_tokens")),
                "cached": nullable_integer(m.get("cached_tokens")),
                "cache_read": nullable_integer(m.get("cache_read_tokens")),
                "cache_creation": nullable_integer(m.get("cache_creation_tokens")),
                "total": nullable_integer(m.get("total_tokens")),
            },
            "cache_hit_rate": nullable_number(m.get("cache_hit_rate")),
            "cost_usd": nullable_number(m.get("cost")),
        })
    rows.sort(key=lambda x: ((x["requests"] if x["requests"] is not None else -1), (x["tokens"]["total"] if x["tokens"]["total"] is not None else -1)), reverse=True)
    return rows[:MODEL_LIMIT]


def first_masked_source(row: dict[str, Any]) -> str:
    sources = row.get("sources")
    if isinstance(sources, list):
        for source in sources:
            masked = safe_mask(source)
            if masked:
                return masked
    contexts = row.get("contexts")
    if isinstance(contexts, list):
        for ctx in contexts:
            if isinstance(ctx, dict):
                masked = safe_mask(ctx.get("source"))
                if masked:
                    return masked
    return ""


def sanitize_api_key_stats(items: Any, aliases: dict[str, str]) -> list[dict[str, Any]]:
    if not isinstance(items, list):
        return []
    rows: list[dict[str, Any]] = []
    for k in items:
        if not isinstance(k, dict):
            continue
        h = k.get("api_key_hash")
        identity = key_identity(h, first_masked_source(k), aliases)
        models = k.get("models") if isinstance(k.get("models"), list) else []
        model_rows = []
        for m in models[:KEY_MODEL_LIMIT]:
            if not isinstance(m, dict):
                continue
            model_rows.append({
                "model": clean_text(m.get("model") or "unknown", 160),
                "requests": nullable_integer(m.get("calls")),
                "success_requests": nullable_integer(m.get("success_calls")),
                "failed_requests": nullable_integer(m.get("failure_calls")),
                "success_rate": nullable_number(m.get("success_rate")),
                "total_tokens": nullable_integer(m.get("total_tokens")),
                "cost_usd": nullable_number(m.get("cost")),
                "last_seen_ms": nullable_integer(m.get("last_seen_ms")),
            })
        rows.append({
            "api_key": identity,
            "requests": nullable_integer(k.get("calls")),
            "success_requests": nullable_integer(k.get("success_calls")),
            "failed_requests": nullable_integer(k.get("failure_calls")),
            "success_rate": nullable_number(k.get("success_rate")),
            "tokens": {
                "input": nullable_integer(k.get("input_tokens")),
                "output": nullable_integer(k.get("output_tokens")),
                "cached": nullable_integer(k.get("cached_tokens")),
                "cache_read": nullable_integer(k.get("cache_read_tokens")),
                "cache_creation": nullable_integer(k.get("cache_creation_tokens")),
                "total": nullable_integer(k.get("total_tokens")),
            },
            "cost_usd": nullable_number(k.get("cost")),
            "avg_latency_ms": nullable_number(k.get("average_latency_ms")),
            "last_seen_ms": nullable_integer(k.get("last_seen_ms")),
            "models": model_rows,
        })
    rows.sort(key=lambda x: ((x["requests"] if x["requests"] is not None else -1), (x["tokens"]["total"] if x["tokens"]["total"] is not None else -1)), reverse=True)
    return rows[:KEY_LIMIT]


def fetch_breakdown_window(origin: str, auth: str, aliases: dict[str, str], name: str, from_ms: int, to_ms: int) -> dict[str, Any]:
    response = post_json(origin, auth, {
        "from_ms": from_ms,
        "to_ms": to_ms,
        "now_ms": to_ms,
        "include": {
            "summary": True,
            "summary_profile": "compact",
            "model_stats": True,
            "api_key_stats": True,
        },
    }, timeout=18.0)
    return {
        "name": name,
        "from_ms": from_ms,
        "to_ms": to_ms,
        "generated_at_ms": integer(response.get("generated_at_ms"), int(time.time() * 1000)),
        "summary": summarize(response.get("summary")),
        "models": sanitize_model_stats(response.get("model_stats")),
        "api_keys": sanitize_api_key_stats(response.get("api_key_stats"), aliases),
    }


def cache_get_or_refresh(path: Path, ttl: int, builder: Callable[[], dict[str, Any]]) -> tuple[dict[str, Any] | None, bool, bool]:
    existing = load_json(path)
    fresh = isinstance(existing, dict) and file_age(path) < ttl
    if fresh:
        return existing, True, False
    failure_path = path.with_name(path.name + ".failure.json")
    failure = load_json(failure_path, {})
    now = int(time.time())
    retry_after = integer(failure.get("retry_after")) if isinstance(failure, dict) else 0
    if retry_after > now:
        if isinstance(existing, dict):
            return existing, True, False
        return None, False, False
    try:
        value = builder()
        if not isinstance(value, dict):
            raise RuntimeError("cache builder returned non-object")
        atomic_write_json(path, value, 0o600)
        try:
            failure_path.unlink()
        except FileNotFoundError:
            pass
        return value, True, True
    except Exception as exc:
        eprint(f"[WARN] rich cache refresh failed: {path.name}: {exc}")
        failures = max(0, integer(failure.get("failures"))) + 1 if isinstance(failure, dict) else 1
        backoff = min(CACHE_FAILURE_BACKOFF_MAX, CACHE_FAILURE_BACKOFF_MIN * (2 ** min(failures - 1, 4)))
        try:
            atomic_write_json(failure_path, {
                "failures": failures,
                "failed_at": now,
                "retry_after": now + backoff,
                "error": clean_text(str(exc), 240),
            }, 0o600)
        except Exception as marker_exc:
            eprint(f"[WARN] cache failure marker write failed: {path.name}: {marker_exc}")
        if isinstance(existing, dict):
            return existing, True, False
        return None, False, False


def query_all_time(db_path: Path) -> dict[str, Any]:
    conn = open_sqlite_readonly(
        db_path,
        query_timeout=ALL_TIME_QUERY_TIMEOUT_SECONDS,
    )
    try:
        cols = {row[1] for row in conn.execute("PRAGMA table_info(usage_events)")}
        if not {"failed", "total_tokens"}.issubset(cols):
            raise RuntimeError("usage_events missing required columns")
        row = conn.execute("""
            SELECT
                count(*),
                coalesce(sum(CASE WHEN failed = 0 THEN 1 ELSE 0 END), 0),
                coalesce(sum(CASE WHEN failed = 1 THEN 1 ELSE 0 END), 0),
                coalesce(sum(total_tokens), 0)
            FROM usage_events
        """).fetchone()
    finally:
        conn.close()
    if not row or len(row) != 4:
        raise RuntimeError("unexpected all-time aggregate")
    total, success, failure, tokens = [int(x or 0) for x in row]
    if min(total, success, failure, tokens) < 0:
        raise RuntimeError("negative all-time aggregate")
    return {
        "requests": total,
        "success_requests": success,
        "failed_requests": failure,
        "success_rate": (success / total) if total else 0,
        "total_tokens": tokens,
        "generated_at_ms": int(time.time() * 1000),
    }


def sanitize_calls(events_obj: Any, aliases: dict[str, str]) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for e in event_array(events_obj)[:CALLS_LIMIT]:
        failed = e.get("failed") is True
        code = integer(e.get("fail_status_code"), 0) or None
        identity = key_identity(e.get("api_key_hash"), e.get("source"), aliases)
        effort = normalize_reasoning_effort(e.get("reasoning_effort"))
        row = {
            "timestamp_ms": nullable_integer(e.get("timestamp_ms")),
            "api_key": identity,
            "model": clean_text(e.get("analytics_model") or e.get("resolved_model") or e.get("model") or e.get("requested_model") or "unknown", 160),
            "status": {
                "ok": not failed,
                "code": code,
                "label": (f"HTTP {code}" if failed and code else ("失败" if failed else "成功")),
            },
            "tokens": {
                "input": nullable_integer(e.get("input_tokens")),
                "output": nullable_integer(e.get("output_tokens")),
                "cached": nullable_integer(e.get("cached_tokens")),
                "cache_read": nullable_integer(e.get("cache_read_tokens")),
                "cache_creation": nullable_integer(e.get("cache_creation_tokens")),
                "reasoning": nullable_integer(e.get("reasoning_tokens")),
                "total": nullable_integer(e.get("total_tokens")),
            },
            "latency_ms": nullable_number(e.get("latency_ms")),
            "ttft_ms": nullable_number(e.get("ttft_ms")),
        }
        # Backward-compatible optional field. Missing/unknown stays absent rather
        # than being guessed from reasoning token counts.
        if effort is not None:
            row["reasoning_effort"] = effort
        items.append(row)
    return items


def ensure_no_banned_keys(obj: Any) -> None:
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in BANNED_PUBLIC_KEYS:
                raise RuntimeError(f"banned public key leaked: {k}")
            ensure_no_banned_keys(v)
    elif isinstance(obj, list):
        for v in obj:
            ensure_no_banned_keys(v)


def contains_secret(obj: Any, secret: str) -> bool:
    if not secret:
        return False
    try:
        return secret.encode("utf-8") in dump_bytes(obj)
    except Exception:
        return True


def file_meta(path: Path, refresh_seconds: int, public_path: str) -> dict[str, Any]:
    obj = load_json(path, {})
    generated_ms = 0
    if isinstance(obj, dict):
        generated_ms = integer(obj.get("generated_at_ms"))
        if not generated_ms:
            generated_ms = integer(obj.get("generated_unix")) * 1000
    available = path.is_file() and path.stat().st_size > 0
    age_seconds = file_age(path) if available else None
    return {
        "path": public_path,
        "available": available,
        "generated_at_ms": generated_ms,
        "refresh_seconds": refresh_seconds,
        "stale": bool(available and age_seconds is not None and age_seconds > max(30, refresh_seconds * 2)),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-snapshot", required=True)
    ap.add_argument("--events", required=True)
    ap.add_argument("--aliases", required=True)
    ap.add_argument("--auth-header-file", required=True)
    ap.add_argument("--origin", required=True)
    ap.add_argument("--db-path", required=True)
    ap.add_argument("--public-dir", required=True)
    ap.add_argument("--private-dir", required=True)
    ap.add_argument("--quota-config", required=True)
    ap.add_argument("--snapshot-refresh-seconds", type=int, default=10)
    args = ap.parse_args()

    base_path = Path(args.base_snapshot)
    events_path = Path(args.events)
    aliases_path = Path(args.aliases)
    auth_path = Path(args.auth_header_file)
    public_dir = Path(args.public_dir)
    private_dir = Path(args.private_dir)
    quota_config = Path(args.quota_config)
    cache_dir = private_dir / CACHE_DIR_NAME
    cache_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(cache_dir, 0o700)

    base = load_json(base_path)
    if not isinstance(base, dict) or base.get("schema_version") != 1:
        raise RuntimeError("base snapshot schema invalid")

    alias_obj = load_json(aliases_path, [])
    aliases = build_alias_map(alias_obj)
    events_obj = load_json(events_path, {"events": {"items": []}})
    auth = read_auth_header(auth_path)
    admin_secret = auth[7:].strip() if auth.lower().startswith("bearer ") else auth

    configured_quota_targets = read_quota_targets(quota_config)
    configured_quota_set = {target.lower() for target in configured_quota_targets}
    quota_remarks = {
        key: value for key, value in read_quota_remarks(quota_config).items()
        if key in configured_quota_set
    }
    now_ms = int(time.time() * 1000)
    windows = {
        "last_24h": (now_ms - 24 * 3600 * 1000, now_ms, HISTORY_WINDOW_CACHE_TTLS["last_24h"]),
        "last_7d": (now_ms - 7 * 24 * 3600 * 1000, now_ms, HISTORY_WINDOW_CACHE_TTLS["last_7d"]),
        "last_30d": (now_ms - 30 * 24 * 3600 * 1000, now_ms, HISTORY_WINDOW_CACHE_TTLS["last_30d"]),
    }
    breakdown_windows = {
        "last_24h": (now_ms - 24 * 3600 * 1000, now_ms, BREAKDOWN_WINDOW_CACHE_TTLS["last_24h"]),
        "last_7d": (now_ms - 7 * 24 * 3600 * 1000, now_ms, BREAKDOWN_WINDOW_CACHE_TTLS["last_7d"]),
    }

    # 1) All-time: strict local SQLite read-only aggregate, cached to avoid frequent full scans.
    all_time_cache_path = cache_dir / "all-time.json"
    all_time, all_time_ok, _ = cache_get_or_refresh(
        all_time_cache_path, ALL_TIME_CACHE_TTL,
        lambda: query_all_time(Path(args.db_path)),
    )
    if all_time_ok and isinstance(all_time, dict):
        base["all_time"] = {k: all_time[k] for k in ("requests", "success_requests", "failed_requests", "success_rate", "total_tokens")}
        base["all_time_available"] = True
        base["all_time_generated_at_ms"] = integer(all_time.get("generated_at_ms")) or None
        base["all_time_stale"] = file_age(all_time_cache_path) > ALL_TIME_CACHE_TTL * 2
    else:
        base["all_time"] = base.get("all_time") if isinstance(base.get("all_time"), dict) else None
        base["all_time_available"] = isinstance(base.get("all_time"), dict)
        base["all_time_stale"] = True

    # Additive compatibility metadata; schema_version stays 1 for the current app.js.
    base["data_layer_version"] = DATA_LAYER_VERSION
    base["data_files"] = {
        "calls": "/calls.json",
        "history": "/history.json",
        "breakdown": "/breakdown.json",
        "account_quota": "/account-quota.json",
        "meta": "/data-meta.json",
    }

    # 2) Recent calls: use the already-fetched Monitoring events; no duplicate API call.
    calls_obj = {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "limit": CALLS_LIMIT,
        "items": sanitize_calls(events_obj, aliases),
    }

    # 3) History: compact summary + timeline only. Each window has its own TTL/stale cache.
    history_values: dict[str, Any] = {}
    history_availability: dict[str, bool] = {}
    for name, (from_ms, to_ms, ttl) in windows.items():
        cache_path = cache_dir / f"history-{name}.json"
        value, ok, _ = cache_get_or_refresh(
            cache_path, ttl,
            lambda n=name, f=from_ms, t=to_ms: fetch_history_window(args.origin, auth, n, f, t),
        )
        history_availability[name] = ok
        if isinstance(value, dict):
            history_values[name] = value
    history_obj = {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "windows": history_values,
        "availability": history_availability,
    }

    # 4) Breakdowns: bounded model/API-key aggregates. Raw hashes/sources never leave this process.
    breakdown_values: dict[str, Any] = {}
    breakdown_availability: dict[str, bool] = {}
    for name, (from_ms, to_ms, ttl) in breakdown_windows.items():
        cache_path = cache_dir / f"breakdown-{name}.json"

        def build_breakdown(n=name, f=from_ms, t=to_ms) -> dict[str, Any]:
            return fetch_breakdown_window(args.origin, auth, aliases, n, f, t)

        raw_cached, ok, refreshed = cache_get_or_refresh(cache_path, ttl, build_breakdown)
        # Cached breakdown is already sanitized. If aliases changed but cache did not refresh,
        # display names may lag until the next cache refresh; stable IDs remain consistent.
        breakdown_availability[name] = ok
        if isinstance(raw_cached, dict):
            breakdown_values[name] = raw_cached
    breakdown_obj = {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "limits": {"models": MODEL_LIMIT, "api_keys": KEY_LIMIT, "models_per_api_key": KEY_MODEL_LIMIT},
        "windows": breakdown_values,
        "availability": breakdown_availability,
    }

    # 5) Passive GPT Team quota: keep configured targets first, then auto-discover
    # additional recently observed Team accounts from local SQLite. User remarks
    # only affect the public display title and never publish the account identity.
    # No provider request is made, and account identities never enter public JSON.
    discovered_cache, discovered_ok, _ = cache_get_or_refresh(
        cache_dir / "quota-discovered-targets.json",
        QUOTA_DISCOVERY_TTL,
        lambda: {"targets": discover_team_quota_targets(Path(args.db_path), now_ms)},
    )
    discovered_targets: list[str] = []
    discovered_seen: set[str] = set()
    if discovered_ok and isinstance(discovered_cache, dict) and isinstance(discovered_cache.get("targets"), list):
        for raw_target in discovered_cache["targets"]:
            for target in quota_targets_from_identity(raw_target):
                if target in discovered_seen:
                    continue
                discovered_seen.add(target)
                discovered_targets.append(target)

    quota_targets: list[str] = []
    quota_target_seen: set[str] = set()
    for target in configured_quota_targets + discovered_targets:
        marker = target.lower()
        if marker in quota_target_seen:
            continue
        quota_target_seen.add(marker)
        quota_targets.append(target)
        if len(quota_targets) >= QUOTA_MAX_ACCOUNTS:
            break

    active_quota_cache = load_json(private_dir / "quota-active.json", {})
    quota_values: list[tuple[str, dict[str, Any]]] = []
    for index, quota_target in enumerate(quota_targets):
        display = quota_display_name(index, quota_target, quota_remarks)
        quota_cache_key = quota_target_hash(quota_target)
        quota_cache = cache_dir / f"account-quota-{quota_cache_key}.json"
        quota_value, quota_ok, _ = cache_get_or_refresh(
            quota_cache, QUOTA_CACHE_TTL,
            lambda target=quota_target, label=display: build_account_quota(
                Path(args.db_path), now_ms, target, label
            ),
        )
        if not quota_ok or not isinstance(quota_value, dict):
            quota_value = unavailable_quota(now_ms, display)
        active_value = active_quota_from_cache(active_quota_cache, quota_target)
        quota_value = choose_quota_value(quota_value, active_value, display)
        quota_values.append((display, quota_value))

    quota_obj = build_multi_account_quota_payload(now_ms, quota_values)

    # Security gate before public publication.
    for obj in (base, calls_obj, history_obj, breakdown_obj, quota_obj):
        ensure_no_banned_keys(obj)
        if contains_secret(obj, admin_secret):
            raise RuntimeError("Admin Key leaked into public JSON")
        for quota_target in quota_targets:
            if contains_secret(obj, quota_target):
                raise RuntimeError("quota target account leaked into public JSON")

    # Base snapshot remains private until the surrounding shell publishes it atomically.
    atomic_write_json(base_path, base, 0o600)

    # Sidecars are independently atomic. Preserve an unchanged file (including mtime/ETag)
    # when only the exporter timestamp changed, enabling cheap HTTP conditional revalidation.
    volatile = ("generated_at_ms",)
    atomic_write_json_if_changed(public_dir / "calls.json", calls_obj, 0o644, volatile)
    atomic_write_json_if_changed(public_dir / "history.json", history_obj, 0o644, volatile)
    atomic_write_json_if_changed(public_dir / "breakdown.json", breakdown_obj, 0o644, volatile)
    atomic_write_json_if_changed(public_dir / "account-quota.json", quota_obj, 0o644, volatile)

    meta_obj = {
        "schema_version": 1,
        "data_layer_version": DATA_LAYER_VERSION,
        "generated_at_ms": now_ms,
        "conventions": {
            "timestamps": "unix_ms_utc",
            "success_rate": "ratio_0_to_1",
            "currency": "USD",
            "numbers": "raw_numbers_frontend_formats_K_M_B",
            "missing_numeric": None,
            "reasoning_effort": "optional_explicit_enum_never_inferred",
            "quota_percent": "0_to_100_used_and_remaining",
            "quota_windows": "identified_only_by_explicit_window_minutes",
            "quota_sources": "freshest_of_passive_usage_headers_or_active_wham_usage",
        },
        "security": {
            "browser_calls_cpamp": False,
            "raw_api_keys": False,
            "api_key_hashes": False,
            "client_ips": False,
            "account_snapshots": False,
            "account_email": False,
            "raw_response_headers": False,
            "request_or_response_bodies": False,
        },
        "files": {
            "snapshot": {"path": "/snapshot.json", "refresh_seconds": max(5, args.snapshot_refresh_seconds)},
            "calls": file_meta(public_dir / "calls.json", max(5, args.snapshot_refresh_seconds), "/calls.json"),
            "history": file_meta(public_dir / "history.json", 60, "/history.json"),
            "breakdown": file_meta(public_dir / "breakdown.json", 120, "/breakdown.json"),
            "account_quota": file_meta(public_dir / "account-quota.json", QUOTA_CACHE_TTL, "/account-quota.json"),
        },
        "window_cache_seconds": {
            "all_time": ALL_TIME_CACHE_TTL,
            **{"history_" + key: ttl for key, ttl in HISTORY_WINDOW_CACHE_TTLS.items()},
            **{"breakdown_" + key: ttl for key, ttl in BREAKDOWN_WINDOW_CACHE_TTLS.items()},
        },
    }
    ensure_no_banned_keys(meta_obj)
    atomic_write_json_if_changed(public_dir / "data-meta.json", meta_obj, 0o644, ("generated_at_ms",))
    return 0


if __name__ == "__main__":
    try:
        if "--active-quota-refresh" in sys.argv[1:]:
            raise SystemExit(active_quota_refresh_main(sys.argv[1:]))
        raise SystemExit(main())
    except Exception as exc:
        eprint(f"[ERROR] rich data layer: {exc}")
        raise SystemExit(1)
CPA229_RICH_HELPER_EOF

    if command -v python3 >/dev/null 2>&1; then
        if ! PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile "$helper_tmp" >/dev/null 2>&1; then
            rm -rf -- "$tmp_dir"
            error "Public Status Rich helper 语法检查失败。"
            return 1
        fi
    fi
    install -d -m 0755 -o root -g root "$(dirname "$PUBLIC_STATUS_RICH_HELPER")" || {
        rm -rf -- "$tmp_dir"
        return 1
    }
    if ! install -m 0755 -o root -g root "$helper_tmp" "${PUBLIC_STATUS_RICH_HELPER}.new.${BASHPID}" \
        || ! mv -f -- "${PUBLIC_STATUS_RICH_HELPER}.new.${BASHPID}" "$PUBLIC_STATUS_RICH_HELPER"; then
        rm -f -- "${PUBLIC_STATUS_RICH_HELPER}.new.${BASHPID}"
        rm -rf -- "$tmp_dir"
        return 1
    fi
    rm -rf -- "$tmp_dir"
    return 0
}

# A schema migration must not outlive a rollback to a pre-migration manager.
# Keep the install checkpoint across fatal exits until all early upgrade steps pass.
install_self_restore_transaction() {
    local checkpoint="$1" binary_replaced="$2" rc=0 staged=""

    [[ -n "$checkpoint" && -d "$checkpoint" ]] || {
        error "管理脚本安装回滚点缺失：${checkpoint:-未知}"; return 1;
    }
    warn "正在回滚管理脚本安装事务：${checkpoint}"

    # Restore the old schema FIRST: the old binary must never load a newer schema.
    if [[ -e "${checkpoint}/admission.conf" || -L "${checkpoint}/admission.conf" ]]; then
        staged="${ADMISSION_CONFIG}.install-restore.${BASHPID}"
        if ! cp -a -- "${checkpoint}/admission.conf" "$staged" \
            || ! mv -f -- "$staged" "$ADMISSION_CONFIG"; then
            rm -f -- "$staged"
            error "无法恢复原准入配置；不会恢复不兼容的旧管理脚本。"
            rc=1
        fi
    elif [[ -f "${checkpoint}/admission.absent" ]]; then
        rm -f -- "$ADMISSION_CONFIG" || rc=1
    else
        error "准入配置回滚标记缺失。"
        rc=1
    fi

    # v2.44 also migrates the standalone Rich Data helper. Restore it together
    # with the manager when an early install step fails, including failures
    # *after* the helper was replaced but before the install checkpoint commits.
    if [[ -e "${checkpoint}/rich-helper.original" || -L "${checkpoint}/rich-helper.original" ]]; then
        staged="${PUBLIC_STATUS_RICH_HELPER}.install-restore.${BASHPID}"
        if ! cp -a -- "${checkpoint}/rich-helper.original" "$staged" \
            || ! mv -f -- "$staged" "$PUBLIC_STATUS_RICH_HELPER"; then
            rm -f -- "$staged"
            error "无法恢复原 Public Status 富数据 helper。"
            rc=1
        fi
    elif [[ -f "${checkpoint}/rich-helper.absent" ]]; then
        rm -f -- "$PUBLIC_STATUS_RICH_HELPER" || rc=1
    else
        error "Public Status helper 回滚标记缺失。"
        rc=1
    fi

    if [[ "$rc" == "0" && "$binary_replaced" == "1" \
        && -f "${checkpoint}/admission.conf" && -f "${checkpoint}/cpa.original" ]]; then
        local saved_schema manager_schema
        saved_schema=$(sed -n 's/^SCHEMA_VERSION=\([0-9][0-9]*\)$/\1/p' \
            "${checkpoint}/admission.conf" | head -n 1)
        manager_schema=$(sed -n 's/^ADMISSION_SCHEMA_VERSION=\([0-9][0-9]*\)$/\1/p' \
            "${checkpoint}/cpa.original" | head -n 1)
        [[ "$manager_schema" =~ ^[0-9]{1,3}$ ]] || manager_schema=1
        if [[ "$saved_schema" =~ ^[0-9]{1,3}$ ]] \
            && (( 10#$saved_schema > 10#$manager_schema )); then
            if grep -Fqx "SCRIPT_VERSION=\"${SCRIPT_VERSION}\"" "$INSTALL_PATH" 2>/dev/null; then
                warn "安装前配置已超出旧管理脚本的 schema 能力；保留已安装的 v${SCRIPT_VERSION} 管理脚本，避免恢复不兼容版本。"
                binary_replaced=0
            else
                error "安装前管理脚本已不兼容原配置，且新版管理脚本未成功安装；请手动恢复兼容脚本。"
                rc=1
            fi
        fi
    fi
    if [[ "$rc" == "0" && "$binary_replaced" == "1" ]]; then
        if [[ -e "${checkpoint}/cpa.original" || -L "${checkpoint}/cpa.original" ]]; then
            staged="${INSTALL_PATH}.install-restore.${BASHPID}"
            if ! cp -a -- "${checkpoint}/cpa.original" "$staged" \
                || ! mv -f -- "$staged" "$INSTALL_PATH"; then
                rm -f -- "$staged"
                error "旧管理脚本恢复失败；准入配置已恢复，当前管理脚本可能仍是新版。"
                rc=1
            fi
        elif [[ -f "${checkpoint}/cpa.absent" ]]; then
            rm -f -- "$INSTALL_PATH" || rc=1
        else
            error "旧管理脚本回滚标记缺失。"
            rc=1
        fi
    fi

    if [[ "$rc" == "0" ]]; then
        rm -rf -- "$checkpoint" || rc=1
        if [[ "$rc" == "0" ]]; then
            info "管理脚本与准入配置已恢复至安装前状态。"
        fi
    fi
    if [[ "$rc" != "0" ]]; then
        error "管理脚本安装回滚不完整；保留检查点 ${checkpoint}，请人工检查。"
    fi
    return "$rc"
}

install_self() {
    admission_with_lock install_self_locked
}

install_self_locked() {
    local source_path backup_path="" checkpoint=""

    source_path=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)
    [[ -n "$source_path" && -f "$source_path" ]] \
        || die "无法定位脚本文件，请先将脚本保存到服务器后再安装。"

    checkpoint=$(mktemp -d /tmp/cpa-install-rollback.XXXXXX) \
        || die "无法创建管理脚本安装回滚点。"
    if [[ -e "$ADMISSION_CONFIG" || -L "$ADMISSION_CONFIG" ]]; then
        cp -a -- "$ADMISSION_CONFIG" "${checkpoint}/admission.conf" \
            || { rm -rf -- "$checkpoint"; die "备份准入配置失败，未开始升级。"; }
    else
        : > "${checkpoint}/admission.absent" \
            || { rm -rf -- "$checkpoint"; die "记录准入配置状态失败。"; }
    fi
    if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
        cp -a -- "$INSTALL_PATH" "${checkpoint}/cpa.original" \
            || { rm -rf -- "$checkpoint"; die "备份原管理脚本失败，未开始升级。"; }
    else
        : > "${checkpoint}/cpa.absent" \
            || { rm -rf -- "$checkpoint"; die "记录原管理脚本状态失败。"; }
    fi
    if [[ -e "$PUBLIC_STATUS_RICH_HELPER" || -L "$PUBLIC_STATUS_RICH_HELPER" ]]; then
        cp -a -- "$PUBLIC_STATUS_RICH_HELPER" "${checkpoint}/rich-helper.original" \
            || { rm -rf -- "$checkpoint"; die "备份原 Public Status helper 失败，未开始升级。"; }
    else
        : > "${checkpoint}/rich-helper.absent" \
            || { rm -rf -- "$checkpoint"; die "记录 Public Status helper 原始状态失败。"; }
    fi
    SELF_INSTALL_TXN_DIR="$checkpoint"
    SELF_INSTALL_BINARY_REPLACED=0
    SELF_INSTALL_TXN_ARMED=1

    admission_ensure_config_locked \
        || die "准入配置初始化/补齐失败；未替换管理脚本。"
    if [[ ! ( -e "$INSTALL_PATH" && "$source_path" == "$(readlink -f "$INSTALL_PATH" 2>/dev/null || true)" ) ]]; then
        if [[ -f "$INSTALL_PATH" ]]; then
            backup_path="${INSTALL_PATH}.pre-v${SCRIPT_VERSION}.$(backup_stamp)"
            cp -a -- "$INSTALL_PATH" "$backup_path" \
                || die "备份现有 ${INSTALL_PATH} 失败。"
            info "已备份当前管理脚本: ${backup_path}"
        fi
        # Arm restoration before any possible replacement of the live manager.
        SELF_INSTALL_BINARY_REPLACED=1
        if ! install -m 0755 -o root -g root "$source_path" "${INSTALL_PATH}.new.${BASHPID}" \
            || ! bash -n "${INSTALL_PATH}.new.${BASHPID}" \
            || ! mv -f -- "${INSTALL_PATH}.new.${BASHPID}" "$INSTALL_PATH"; then
            rm -f -- "${INSTALL_PATH}.new.${BASHPID}"
            die "安装到 ${INSTALL_PATH} 失败。"
        fi
    else
        info "管理命令已经安装在 ${INSTALL_PATH}。"
    fi

    if ! public_status_ensure_quota_config "$backup_path"; then
        die "迁移 Public Status quota 配置失败。"
    fi
    if ! public_status_install_rich_helper; then
        die "安装 Public Status Rich Data helper 失败。"
    fi
    if [[ -f "$CPA_UNIT_FILE" ]]; then
        if ! stage_resource_guard_pending \
            || ! install_pending_background_resource_guard; then
            die "生成并提交后台资源保护配置失败；现有后台 unit 未被替换。"
        fi
    fi
    if [[ -f "$PUBLIC_STATUS_CONFIG" ]]; then
        if ! public_status_refresh_all_units; then
            die "v${SCRIPT_VERSION} Public Status 资源保护单元安装失败。"
        fi
    fi

    # Past this point, the old implementation intentionally retains the new manager
    # on later frontend/maintenance errors to match already-migrated components.
    SELF_INSTALL_TXN_ARMED=0
    rm -rf -- "$checkpoint" || warn "安装回滚点清理失败：${checkpoint}"
    SELF_INSTALL_TXN_DIR=""
    SELF_INSTALL_BINARY_REPLACED=0

    # v2.30 keeps the accepted frontend and adds isolated multi-account quota management.
    # Existing Public Status assets are replaced atomically; the helper rolls back
    # index.html/app.css/app.js/meta.json if any write fails.
    if [[ -f "$PUBLIC_STATUS_CONFIG" && -d "$PUBLIC_STATUS_WEB_ROOT" ]]; then
        if ! public_status_refresh_live_assets; then
            die "v${SCRIPT_VERSION} Public Status 前端更新失败；原前端资源已自动回滚。"
        fi
        # Existing Status installs also retain the v2.29+ Caddy transport policy
        # (zstd/gzip + conditional revalidation) during a normal script upgrade.
        # public_status_apply_caddy_locked validates first and restores the previous
        # Caddy files on failure, so a transport-policy failure never breaks Status.
        if public_status_enabled \
            && command -v caddy >/dev/null 2>&1 \
            && command -v systemctl >/dev/null 2>&1 \
            && systemctl is-active --quiet caddy 2>/dev/null; then
            if public_status_with_lock public_status_apply_caddy_locked; then
                info "已应用 v${SCRIPT_VERSION} Status 压缩与条件缓存策略。"
            else
                warn "Status Caddy 优化未能应用；旧 Caddy 配置已保留，Status 不会因此中断。"
            fi
        fi
        if public_status_enabled \
            && command -v systemctl >/dev/null 2>&1 \
            && systemctl is-active --quiet "$CPAMP_SERVICE" 2>/dev/null \
            && [[ -f "$PUBLIC_STATUS_SERVICE_FILE" ]]; then
            if systemctl start "$PUBLIC_STATUS_SERVICE" >/dev/null 2>&1; then
                info "已触发一轮 v${SCRIPT_VERSION} 脱敏快照，Rich Data sidecars 将立即刷新。"
            else
                warn "未能立即触发 Public Status 快照；现有 timer 会按原周期继续刷新。"
            fi
        fi
    fi
    if ! refresh_existing_cpamp_maintenance_units; then
        die "迁移 CPAMP 数据库维护 unit 失败；原定时和待维护状态已保留，已安装的新管理脚本继续保留以匹配已迁移的其他 unit。"
    fi
    info "安装完成。现在输入 cpa 即可打开菜单。"
}

pause_menu() {
    if [[ -t 0 ]]; then
        printf '\n'
        read -r -p '按回车键返回菜单...' _
    fi

}

# -----------------------------------------------------------------------------
# Public read-only CPAMP snapshot dashboard
# ----------------------------------------------------------------------------

public_status_dashboard_summary_path() {
    local today_start_ms now_ms today_start_s

    today_start_s=$(date -d 'today 00:00:00' +%s 2>/dev/null || date +%s)
    [[ "$today_start_s" =~ ^[0-9]+$ ]] || return 1
    today_start_ms=$((today_start_s * 1000))
    now_ms=$(( $(date +%s) * 1000 ))

    printf '/v0/management/dashboard/summary?today_start_ms=%s&now_ms=%s&top_models=8&recent_failures=0' \
        "$today_start_ms" "$now_ms"
}

public_status_config_value() {
    local key="$1"

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || return 0
    awk -F= -v key="$key" '
        $1 == key { print substr($0, length(key) + 2); exit }
    ' "$PUBLIC_STATUS_CONFIG"
}

public_status_interval() {
    local value="" minimum=5

    value=$(public_status_config_value PUBLIC_STATUS_INTERVAL)
    low_memory_profile_enabled && minimum=30
    if [[ "$value" =~ ^[0-9]+$ ]] && (( 10#$value >= 5 && 10#$value <= 300 )); then
        value=$((10#$value))
        (( value < minimum )) && value="$minimum"
        printf '%s\n' "$value"
    else
        printf '%s\n' "$([[ "$minimum" -gt 10 ]] && printf '%s' "$minimum" || printf '10')"
    fi
}

public_status_domain() {
    public_status_config_value PUBLIC_STATUS_DOMAIN
}

public_status_enabled() {
    [[ "$(public_status_config_value PUBLIC_STATUS_ENABLED)" == "1" ]]
}

public_status_quota_targets() {
    [[ -f "$PUBLIC_STATUS_QUOTA_CONFIG" ]] || return 0
    awk -F= '$1 == "QUOTA_TARGET_ACCOUNT" {print substr($0, length($1) + 2)}' \
        "$PUBLIC_STATUS_QUOTA_CONFIG" 2>/dev/null \
        | awk 'NF && !seen[tolower($0)]++'
}

public_status_quota_target() {
    public_status_quota_targets | head -n 1
}

public_status_quota_config_value() {
    local key="$1"
    [[ -f "$PUBLIC_STATUS_QUOTA_CONFIG" ]] || return 0
    awk -F= -v key="$key" '$1 == key {print substr($0, length($1) + 2); exit}' \
        "$PUBLIC_STATUS_QUOTA_CONFIG" 2>/dev/null || true
}

public_status_quota_refresh_enabled() {
    local value
    value=$(public_status_quota_config_value QUOTA_ACTIVE_REFRESH)
    [[ -z "$value" || "$value" == "1" ]]
}

public_status_quota_interval_minutes() {
    local value
    value=$(public_status_quota_config_value QUOTA_ACTIVE_INTERVAL_MINUTES)
    if [[ "$value" =~ ^[0-9]+$ ]] && (( 10#$value >= 30 && 10#$value <= 1440 )); then
        printf '%s\n' "$((10#$value))"
    else
        printf '60\n'
    fi
}

public_status_normalize_quota_email() {
    local input="$1"
    python3 - "$input" <<'PYQEMAIL'
import re, sys
value = sys.argv[1].strip().lower()
pattern = re.compile(r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+$", re.I)
if not value or len(value) > 320 or any(ch.isspace() for ch in value) or not pattern.fullmatch(value):
    raise SystemExit(1)
print(value)
PYQEMAIL
}

public_status_ensure_quota_remarks() {
    local tmp_file old_umask
    install -d -m 0700 -o root -g root "$PUBLIC_STATUS_CONFIG_DIR" || return 1
    if [[ -e "$PUBLIC_STATUS_QUOTA_REMARKS" ]]; then
        jq -e 'type == "object"' "$PUBLIC_STATUS_QUOTA_REMARKS" >/dev/null 2>&1 || {
            error "额度备注文件不是有效 JSON：${PUBLIC_STATUS_QUOTA_REMARKS}"
            return 1
        }
        chown root:root "$PUBLIC_STATUS_QUOTA_REMARKS" || return 1
        chmod 0600 "$PUBLIC_STATUS_QUOTA_REMARKS" || return 1
        return 0
    fi
    old_umask=$(umask)
    umask 077
    tmp_file=$(mktemp "${PUBLIC_STATUS_QUOTA_REMARKS}.XXXXXX") || { umask "$old_umask"; return 1; }
    if ! printf '{}\n' > "$tmp_file" \
        || ! chown root:root "$tmp_file" \
        || ! chmod 0600 "$tmp_file" \
        || ! mv -f "$tmp_file" "$PUBLIC_STATUS_QUOTA_REMARKS"; then
        rm -f "$tmp_file"
        umask "$old_umask"
        return 1
    fi
    umask "$old_umask"
    return 0
}

public_status_quota_remark_for() {
    local target="${1,,}"
    [[ -s "$PUBLIC_STATUS_QUOTA_REMARKS" ]] || return 0
    jq -r --arg target "$target" '
      if type == "object" then (.[$target] // "") else "" end
    ' "$PUBLIC_STATUS_QUOTA_REMARKS" 2>/dev/null || true
}

public_status_normalize_quota_remark() {
    local input="$1"
    python3 - "$input" <<'PYQREMARK'
import re, sys
value = sys.argv[1].strip()
if not value or len(value) > 48:
    raise SystemExit(1)
if any(ord(ch) < 32 or ord(ch) == 127 for ch in value):
    raise SystemExit(1)
if "@" in value:
    raise SystemExit(1)
if re.fullmatch(r"(?:sk|key|token|api)[-_][A-Za-z0-9_.-]{16,}", value, re.I):
    raise SystemExit(1)
print(value)
PYQREMARK
}

public_status_write_quota_remark() {
    local target="${1,,}" remark="${2:-}" tmp_file old_umask
    public_status_ensure_quota_remarks || return 1
    old_umask=$(umask)
    umask 077
    tmp_file=$(mktemp "${PUBLIC_STATUS_QUOTA_REMARKS}.XXXXXX") || { umask "$old_umask"; return 1; }
    local jq_rc=0
    if [[ -n "$remark" ]]; then
        jq --arg target "$target" --arg remark "$remark" '
          (if type == "object" then . else {} end) | .[$target] = $remark
        ' "$PUBLIC_STATUS_QUOTA_REMARKS" > "$tmp_file" || jq_rc=$?
    else
        jq --arg target "$target" '
          (if type == "object" then . else {} end) | del(.[$target])
        ' "$PUBLIC_STATUS_QUOTA_REMARKS" > "$tmp_file" || jq_rc=$?
    fi
    if [[ "$jq_rc" != "0" ]] \
        || ! chown root:root "$tmp_file" \
        || ! chmod 0600 "$tmp_file" \
        || ! mv -f "$tmp_file" "$PUBLIC_STATUS_QUOTA_REMARKS"; then
        rm -f "$tmp_file"
        umask "$old_umask"
        return 1
    fi
    umask "$old_umask"
    return 0
}

public_status_write_quota_config() {
    local enabled="$1" interval="$2" tmp_file old_umask target
    shift 2
    local -a targets=("$@")

    [[ "$enabled" == "0" || "$enabled" == "1" ]] || return 1
    [[ "$interval" =~ ^[0-9]+$ ]] && (( 10#$interval >= 30 && 10#$interval <= 1440 )) || return 1
    (( ${#targets[@]} <= 8 )) || return 1

    install -d -m 0700 -o root -g root "$PUBLIC_STATUS_CONFIG_DIR" || return 1
    old_umask=$(umask)
    umask 077
    tmp_file=$(mktemp "${PUBLIC_STATUS_QUOTA_CONFIG}.XXXXXX") || { umask "$old_umask"; return 1; }
    {
        printf '# GPT Team quota accounts. Order is preserved; private remarks may override public display titles.\n'
        for target in "${targets[@]}"; do
            [[ -n "$target" ]] && printf 'QUOTA_TARGET_ACCOUNT=%s\n' "$target"
        done
        printf 'QUOTA_ACTIVE_REFRESH=%s\n' "$enabled"
        printf 'QUOTA_ACTIVE_INTERVAL_MINUTES=%s\n' "$((10#$interval))"
        printf 'UPDATED_AT=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    } > "$tmp_file" \
        && chown root:root "$tmp_file" \
        && chmod 0600 "$tmp_file" \
        && mv -f "$tmp_file" "$PUBLIC_STATUS_QUOTA_CONFIG"
    local rc=$?
    [[ "$rc" == "0" ]] || rm -f "$tmp_file"
    umask "$old_umask"
    return "$rc"
}

public_status_ensure_quota_config() {
    local legacy_script="${1:-}" target="" source enabled interval normalized
    local -a targets=()

    if [[ -s "$PUBLIC_STATUS_QUOTA_CONFIG" ]]; then
        while IFS= read -r target; do
            normalized=$(public_status_normalize_quota_email "$target" 2>/dev/null || true)
            [[ -n "$normalized" ]] || continue
            if [[ " ${targets[*],,} " != *" ${normalized,,} "* ]]; then
                targets+=("$normalized")
            fi
            (( ${#targets[@]} >= 8 )) && break
        done < <(public_status_quota_targets)
    fi

    if (( ${#targets[@]} == 0 )); then
        # v2.30 migration: recover the previous single target from an installed helper
        # or pre-upgrade script, but never bake account identities into this script.
        for source in "$PUBLIC_STATUS_RICH_HELPER" "$legacy_script"; do
            [[ -f "$source" ]] || continue
            target=$(python3 - "$source" <<'PYQ'
import re, sys
from pathlib import Path
try:
    text = Path(sys.argv[1]).read_text(encoding='utf-8', errors='ignore')
except OSError:
    raise SystemExit(0)
m = re.search(r'^QUOTA_TARGET_ACCOUNT\s*=\s*["\']([^"\']{1,320})["\']\s*$', text, re.M)
if m and not any(ch.isspace() for ch in m.group(1)):
    print(m.group(1))
PYQ
            )
            normalized=$(public_status_normalize_quota_email "$target" 2>/dev/null || true)
            [[ -n "$normalized" ]] && { targets+=("$normalized"); break; }
        done
    fi

    enabled=$(public_status_quota_config_value QUOTA_ACTIVE_REFRESH)
    [[ "$enabled" == "0" || "$enabled" == "1" ]] || enabled=1
    interval=$(public_status_quota_interval_minutes)
    public_status_write_quota_config "$enabled" "$interval" "${targets[@]}" || return 1
    public_status_ensure_quota_remarks || return 1
    if (( ${#targets[@]} == 0 )); then
        warn "未配置固定 GPT Team quota 账号；仍会保留自动发现，亦可在 Dashboard 子菜单中添加账号。"
    fi
    return 0
}

public_status_ensure_dependencies() {
    local -a packages=()

    command -v python3 >/dev/null 2>&1 || packages+=(python3)
    command -v flock >/dev/null 2>&1 || packages+=(util-linux)

    if (( ${#packages[@]} > 0 )); then
        command -v apt-get >/dev/null 2>&1 \
            || { error "缺少 ${packages[*]}，且系统没有 apt-get。"; return 1; }
        info "正在安装 Public Status 所需依赖：${packages[*]}"
        apt-get update -y || return 1
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" || return 1
    fi

    local command_name
    for command_name in curl jq python3 flock caddy tar sha256sum awk sed grep sort; do
        command -v "$command_name" >/dev/null 2>&1 \
            || { error "Public Status 缺少命令：${command_name}"; return 1; }
    done
    return 0
}

public_status_with_lock() {
    local lock_fd rc

    if ! command -v flock >/dev/null 2>&1; then
        warn "未找到 flock；当前也无法存在由本功能安装的并发更新 timer，将直接执行 Caddy 操作。"
        "$@"
        return $?
    fi
    install -d -m 0755 -o root -g root "$(dirname "$PUBLIC_STATUS_CADDY_LOCK")" \
        || return 1
    exec {lock_fd}>"$PUBLIC_STATUS_CADDY_LOCK" || return 1
    if ! flock -w 120 "$lock_fd"; then
        error "等待 Caddy 配置锁超时；未执行任何配置修改。"
        exec {lock_fd}>&-
        return 1
    fi

    "$@"
    rc=$?
    flock -u "$lock_fd" >/dev/null 2>&1 || true
    exec {lock_fd}>&-
    return "$rc"
}

public_status_normalize_domain() {
    local input="$1"

    python3 - "$input" <<'PY'
import ipaddress
import sys

value = sys.argv[1].strip().rstrip('.')
if not value or len(value) > 253:
    raise SystemExit(1)
if '://' in value or '/' in value or ':' in value or any(ch.isspace() for ch in value):
    raise SystemExit(1)
try:
    ipaddress.ip_address(value)
except ValueError:
    pass
else:
    raise SystemExit(1)
try:
    ascii_name = value.encode('idna').decode('ascii').lower()
except UnicodeError:
    raise SystemExit(1)
labels = ascii_name.split('.')
if len(labels) < 2:
    raise SystemExit(1)
for label in labels:
    if not (1 <= len(label) <= 63):
        raise SystemExit(1)
    if label[0] == '-' or label[-1] == '-':
        raise SystemExit(1)
    if not all(ch.isalnum() or ch == '-' for ch in label):
        raise SystemExit(1)
if labels[-1].isdigit():
    raise SystemExit(1)
print(ascii_name)
PY
}

public_status_normalize_ip_or_cidr() {
    local input="$1"

    python3 - "$input" <<'PY'
import ipaddress
import sys

value = sys.argv[1].strip()
if not value or any(ch.isspace() for ch in value):
    raise SystemExit(1)
try:
    if '/' in value:
        network = ipaddress.ip_network(value, strict=False)
    else:
        address = ipaddress.ip_address(value)
        network = ipaddress.ip_network(f"{address}/{address.max_prefixlen}", strict=False)
except ValueError:
    raise SystemExit(1)
minimum_prefix = 8 if network.version == 4 else 16
if network.prefixlen < minimum_prefix or network.is_unspecified or network.is_multicast:
    raise SystemExit(1)
print(network.compressed)
PY
}

public_status_current_cpa_domain() {
    local value=""

    if [[ -f "$DEPLOY_STATE" ]]; then
        value=$(awk -F= '$1 == "DOMAIN" {print substr($0, length($1) + 2); exit}' \
            "$DEPLOY_STATE" 2>/dev/null || true)
    fi
    printf '%s\n' "${value,,}"
}

public_status_check_domain_collision() {
    local status_domain="$1" cpa_domain="" translate_domain=""

    cpa_domain=$(public_status_current_cpa_domain)
    if [[ -n "$cpa_domain" && "${status_domain,,}" == "$cpa_domain" ]]; then
        error "Status 域名不能与 CPA API 域名相同：${status_domain}"
        return 1
    fi
    if [[ -n "${DEPLOY_DOMAIN:-}" && "${status_domain,,}" == "${DEPLOY_DOMAIN,,}" ]]; then
        error "Status 域名不能与本次准备部署的 CPA API 域名相同：${status_domain}"
        return 1
    fi
    translate_domain=$(
        admission_load_settings >/dev/null 2>&1 || exit 1
        printf '%s\n' "$TRANSLATE_DOMAIN"
    ) || { error "无法安全读取高并发域名配置，拒绝修改 Status 域名。"; return 1; }
    if [[ -n "$translate_domain" && "${status_domain,,}" == "${translate_domain,,}" ]]; then
        error "Status 域名不能与已保存的高并发 API 域名相同：${status_domain}"
        return 1
    fi
    return 0
}

public_status_write_config() {
    local domain="$1" interval="$2" enabled="$3"
    local tmp_file old_umask

    [[ "$interval" =~ ^[0-9]+$ ]] && (( 10#$interval >= 5 && 10#$interval <= 300 )) \
        || { error "快照间隔必须是 5-300 秒的整数。"; return 1; }
    [[ "$enabled" == "0" || "$enabled" == "1" ]] \
        || { error "Public Status enabled 状态无效。"; return 1; }

    install -d -m 0700 -o root -g root "$PUBLIC_STATUS_CONFIG_DIR" || return 1
    old_umask=$(umask)
    umask 077
    tmp_file=$(mktemp "${PUBLIC_STATUS_CONFIG}.XXXXXX") || {
        umask "$old_umask"
        return 1
    }
    if ! {
        printf 'PUBLIC_STATUS_DOMAIN=%s\n' "$domain"
        printf 'PUBLIC_STATUS_INTERVAL=%s\n' "$((10#$interval))"
        printf 'PUBLIC_STATUS_ENABLED=%s\n' "$enabled"
        printf 'UPDATED_AT=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    } > "$tmp_file" \
        || ! chown root:root "$tmp_file" \
        || ! chmod 0600 "$tmp_file" \
        || ! mv -f "$tmp_file" "$PUBLIC_STATUS_CONFIG"; then
        rm -f "$tmp_file"
        umask "$old_umask"
        return 1
    fi
    umask "$old_umask"
    return 0
}

public_status_ensure_custom_allowlist() {
    local tmp_file

    install -d -m 0700 -o root -g root "$PUBLIC_STATUS_CONFIG_DIR" || return 1
    if [[ ! -e "$PUBLIC_STATUS_CUSTOM_ALLOW" ]]; then
        tmp_file=$(mktemp "${PUBLIC_STATUS_CUSTOM_ALLOW}.XXXXXX") || return 1
        : > "$tmp_file"
        chown root:root "$tmp_file" || { rm -f "$tmp_file"; return 1; }
        chmod 0600 "$tmp_file" || { rm -f "$tmp_file"; return 1; }
        mv -f "$tmp_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" || {
            rm -f "$tmp_file"
            return 1
        }
    fi
    chown root:root "$PUBLIC_STATUS_CUSTOM_ALLOW" || return 1
    chmod 0600 "$PUBLIC_STATUS_CUSTOM_ALLOW" || return 1
}

public_status_validate_cn_file() {
    local family="$1" source_file="$2" output_file="$3" old_file="${4:-}"

    python3 - "$family" "$source_file" "$output_file" "$old_file" <<'PY'
import ipaddress
import pathlib
import sys

family = int(sys.argv[1])
source = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
old_path = pathlib.Path(sys.argv[4]) if sys.argv[4] else None

networks = set()
for raw in source.read_text(encoding='utf-8', errors='strict').splitlines():
    value = raw.strip()
    if not value or value.startswith('#') or value.startswith(';'):
        continue
    try:
        network = ipaddress.ip_network(value, strict=False)
    except ValueError as exc:
        raise SystemExit(f"invalid network {value!r}: {exc}")
    if network.version != family:
        raise SystemExit(f"wrong address family: {value}")
    minimum_prefix = 8 if family == 4 else 16
    if network.prefixlen < minimum_prefix:
        raise SystemExit(f"network is unexpectedly broad: {network}")
    if network.is_unspecified or network.is_loopback or network.is_link_local or network.is_multicast:
        raise SystemExit(f"unsafe network: {network}")
    networks.add(network)

minimum_count = 500 if family == 4 else 50
maximum_count = 20000
if not (minimum_count <= len(networks) <= maximum_count):
    raise SystemExit(f"unexpected network count: {len(networks)}")

coverage = sum(network.num_addresses for network in networks)
maximum_coverage = (1 << 30) if family == 4 else (1 << 116)
if coverage > maximum_coverage:
    raise SystemExit("aggregate coverage is unexpectedly broad")

if old_path and old_path.is_file():
    old_count = sum(1 for line in old_path.read_text(encoding='utf-8', errors='ignore').splitlines()
                    if line.strip() and not line.lstrip().startswith(('#', ';')))
    if old_count >= minimum_count:
        lower = max(minimum_count, old_count // 2)
        upper = min(maximum_count, (old_count * 3) // 2 + 1)
        if not (lower <= len(networks) <= upper):
            raise SystemExit(f"network count changed too much: old={old_count}, new={len(networks)}")

ordered = sorted(networks, key=lambda item: (int(item.network_address), item.prefixlen))
output.write_text(''.join(f"{network.compressed}\n" for network in ordered), encoding='ascii')
PY
}

public_status_download_cn_lists() {
    local output4="$1" output6="$2" tmp_dir raw4 raw6 old4="" old6=""

    tmp_dir=$(mktemp -d /tmp/cpamp-public-cn.XXXXXX) || return 1
    raw4="${tmp_dir}/cn4.raw"
    raw6="${tmp_dir}/cn6.raw"
    [[ -s "$PUBLIC_STATUS_CN4" ]] && old4="$PUBLIC_STATUS_CN4"
    [[ -s "$PUBLIC_STATUS_CN6" ]] && old6="$PUBLIC_STATUS_CN6"

    info "正在下载 CN IPv4 网段..."
    if ! curl -fL --proto '=https' --tlsv1.2 --compressed \
        --retry 4 --retry-all-errors --retry-delay 2 \
        --connect-timeout 12 --max-time 120 \
        -H 'User-Agent: cpa-public-status/2.28' \
        -o "$raw4" "$PUBLIC_STATUS_CN4_URL"; then
        rm -rf -- "$tmp_dir"
        return 1
    fi

    info "正在下载 CN IPv6 网段..."
    if ! curl -fL --proto '=https' --tlsv1.2 --compressed \
        --retry 4 --retry-all-errors --retry-delay 2 \
        --connect-timeout 12 --max-time 120 \
        -H 'User-Agent: cpa-public-status/2.28' \
        -o "$raw6" "$PUBLIC_STATUS_CN6_URL"; then
        rm -rf -- "$tmp_dir"
        return 1
    fi

    if ! public_status_validate_cn_file 4 "$raw4" "$output4" "$old4" \
        || ! public_status_validate_cn_file 6 "$raw6" "$output6" "$old6"; then
        error "CN IP 网段校验失败；旧白名单未被替换。"
        rm -rf -- "$tmp_dir"
        return 1
    fi
    rm -rf -- "$tmp_dir"
    return 0
}

public_status_stage_assets() {
    local target_dir="$1" interval="$2"

    mkdir -p "$target_dir" || return 1
    cat > "${target_dir}/index.html" <<'CPA229_INDEX_EOF'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CPA / CPAMP 运行状态</title>
  <link rel="stylesheet" href="app.css">
</head>
<body>
  <!-- Background Glowing Ambient Mesh -->
  <div class="ambient-glow glow-1" aria-hidden="true"></div>
  <div class="ambient-glow glow-2" aria-hidden="true"></div>
  <div class="ambient-glow glow-3" aria-hidden="true"></div>

  <div class="shell">
    <!-- Top Hero Header -->
    <header class="hero-header glass-card">
      <div class="hero-main-row">
      <div class="hero-left">
        <div class="brand-logo-wrap" title="CPAMP 运行监控中心">
          <svg class="brand-cpamp-svg" viewBox="0 0 176 38" fill="none" aria-label="CPAMP Logo">
            <g class="logo-strokes" stroke="currentColor" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round">
              <!-- C -->
              <path d="M 31 6.5 H 12 C 7.5 6.5 4.5 9.5 4.5 14 V 24 C 4.5 28.5 7.5 31.5 12 31.5 H 31" />
              <!-- P -->
              <path d="M 45 31.5 V 6.5 H 57 C 62.5 6.5 66 10 66 14 C 66 18 62.5 21.5 57 21.5 H 45" />
              <!-- A -->
              <path d="M 74 31.5 L 88 6.5 L 102 31.5" />
              <!-- M -->
              <path d="M 111 31.5 V 6.5 L 123.5 21.5 L 136 6.5 V 31.5" />
              <!-- P -->
              <path d="M 148 31.5 V 6.5 H 160 C 165.5 6.5 169 10 169 14 C 169 18 165.5 21.5 160 21.5 H 148" />
            </g>
            <!-- Diamond in A -->
            <polygon class="logo-diamond" points="88,18 92.5,24 88,30 83.5,24" />
          </svg>
        </div>
        <div class="hero-headings">
          <div class="hero-tags">
            <span class="pill-tag gradient-pill">公网只读状态</span>
            <span id="hero-data-layer-tag" class="pill-tag subtle-pill">Data Layer —</span>
            <span id="cpamp-version-tag" class="pill-tag subtle-pill is-hidden"></span>
          </div>
          <h1 class="hero-title">运行状态监控</h1>
          <p class="hero-subtitle">基于只读数据层与白名单脱敏的实时监控快照</p>
        </div>
      </div>

      <div class="hero-right">
        <!-- Global Number Format Switcher -->
        <div class="segmented-control" role="group" aria-label="数字格式切换">
          <button type="button" class="segment-btn active" id="btn-format-intl" data-format="intl" title="使用国际标准千分位缩写 (1.23K / 1.56M / 2.73B)">
            国际 (K/M/B)
          </button>
          <button type="button" class="segment-btn" id="btn-format-cn" data-format="cn" title="使用中文单位缩写 (万 / 亿)">
            中文 (万/亿)
          </button>
        </div>

        <!-- Manual Refresh & Auto Countdown Button -->
        <button type="button" class="action-btn icon-btn" id="btn-manual-refresh" title="立即同步所有数据" aria-label="立即同步">
          <svg class="refresh-icon" viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/>
          </svg>
          <span id="refresh-countdown-text">同步</span>
        </button>
      </div>
      </div>

      <!-- Snapshot & Refresh Shelf Under Title Bar (Image #3) -->
      <div class="hero-snapshot-shelf" id="hero-snapshot-shelf">
        <div class="shelf-left">
          <div class="shelf-status-badge">
            <span id="global-status-dot" class="status-pulse-dot ok"></span>
            <span id="global-status-text" class="shelf-status-name">数据层运行正常</span>
          </div>
          <div class="shelf-divider"></div>
          <div class="shelf-meta-item">
            <span class="shelf-label">快照时间：</span>
            <strong id="hero-snapshot-time" class="shelf-val">--:--:--</strong>
            <span id="hero-snapshot-iso" class="shelf-iso"></span>
          </div>
          <div class="shelf-divider"></div>
          <div class="shelf-meta-item">
            <span class="shelf-label">刷新间隔：</span>
            <strong id="hero-refresh-interval" class="shelf-val">10 秒</strong>
          </div>
          <div class="shelf-divider"></div>
          <div class="shelf-meta-item">
            <span class="shelf-label">下次自动同步：</span>
            <strong id="hero-countdown-val" class="shelf-val">10 秒</strong>
          </div>
        </div>
        <div class="shelf-right">
          <span class="shelf-subtle-hint">全量快照只读脱敏 · 静态聚合分发</span>
        </div>
      </div>
    </header>

    <!-- Today Core Metrics (6 Cards Grid) -->
    <section class="section-container" aria-label="今日核心指标">
      <div class="section-header-compact">
        <h2 class="section-title-sm">今日核心指标</h2>
        <span class="section-badge-info">当日实时聚合</span>
      </div>
      <div class="cards-grid today-grid">
        <article class="metric-card glass-card card-requests">
          <div class="metric-icon-wrap icon-indigo">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
          </div>
          <div class="metric-body">
            <span class="metric-label">今日总请求</span>
            <strong id="today-requests" class="metric-value">—</strong>
            <span id="today-requests-sub" class="metric-sub">成功 — · 失败 —</span>
          </div>
        </article>

        <article class="metric-card glass-card card-rate">
          <div class="metric-icon-wrap icon-emerald">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          </div>
          <div class="metric-body">
            <span class="metric-label">今日成功率</span>
            <strong id="today-success-rate" class="metric-value">—</strong>
            <span id="today-success-rate-sub" class="metric-sub">健康运行中</span>
          </div>
        </article>

        <article class="metric-card glass-card card-tokens">
          <div class="metric-icon-wrap icon-violet">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
          </div>
          <div class="metric-body">
            <span class="metric-label">今日消耗 Token</span>
            <strong id="today-tokens" class="metric-value">—</strong>
            <span id="today-tokens-sub" class="metric-sub">入 — · 出 —</span>
          </div>
        </article>

        <article class="metric-card glass-card card-cost">
          <div class="metric-icon-wrap icon-amber">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
          </div>
          <div class="metric-body">
            <span class="metric-label">今日预估费用</span>
            <strong id="today-cost" class="metric-value">—</strong>
            <span id="today-cost-sub" class="metric-sub">USD 计费估算</span>
          </div>
        </article>

        <article class="metric-card glass-card card-latency">
          <div class="metric-icon-wrap icon-cyan">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </div>
          <div class="metric-body">
            <span class="metric-label">平均响应延迟</span>
            <strong id="today-latency" class="metric-value">—</strong>
            <span id="today-latency-sub" class="metric-sub">单次调用平均</span>
          </div>
        </article>

        <article class="metric-card glass-card card-rolling">
          <div class="metric-icon-wrap icon-rose">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
          </div>
         <div class="metric-body">
           <span class="metric-label">近 30 分钟活动</span>
           <strong id="recent-requests" class="metric-value">—</strong>
           <span id="recent-rolling-sub" class="metric-sub">RPM: — · TPM: —</span>
         </div>
       </article>
     </div>
   </section>

    <!-- GPT Team Quota Section (from /account-quota.json) -->
    <section class="section-container is-hidden" id="quota-section" aria-label="GPT Team 额度">
      <div class="panel glass-card">
        <div class="panel-header flex-wrap-mobile">
          <div class="panel-title-group">
            <div class="title-with-pill">
              <h2 class="panel-title">GPT Team 额度</h2>
              <span class="pill-tag gradient-pill" id="quota-account-badge">GPT Team 主账号</span>
            </div>
            <span class="panel-subtitle" id="quota-update-time">额度数据更新于 — · 上游实时观测</span>
          </div>
          <div class="panel-actions-group">
            <span class="badge-status-subtle" id="quota-status-badge">实时监测</span>
          </div>
        </div>
        <div class="quota-cards-grid" id="quota-cards-grid">
          <!-- Populated by JS -->
        </div>
      </div>
    </section>

    <!-- Cumulative Overview (All-Time) -->
    <section class="section-container" id="all-time-section" aria-label="累计历史概览">
      <div class="panel glass-card">
        <div class="panel-header">
          <div class="panel-title-group">
            <h2 class="panel-title">累计历史概览</h2>
            <span class="panel-subtitle">来源：usage.sqlite 本地只读只查询模式 · 60s 缓存</span>
          </div>
          <span class="badge-status-subtle" id="all-time-status-badge">全量历史已连接</span>
        </div>
        <div class="overview-grid" id="all-time-grid">
          <div class="overview-stat-box">
            <span class="overview-label">累计总请求</span>
            <strong id="all-requests" class="overview-val">—</strong>
          </div>
          <div class="overview-stat-box">
            <span class="overview-label">累计消耗 Token</span>
            <strong id="all-tokens" class="overview-val">—</strong>
          </div>
          <div class="overview-stat-box">
            <span class="overview-label">累计成功请求</span>
            <strong id="all-success" class="overview-val color-emerald">—</strong>
          </div>
          <div class="overview-stat-box">
            <span class="overview-label">累计失败请求</span>
            <strong id="all-failed" class="overview-val color-rose">—</strong>
          </div>
          <div class="overview-stat-box">
            <span class="overview-label">累计平均成功率</span>
            <strong id="all-rate" class="overview-val color-indigo">—</strong>
          </div>
        </div>
      </div>
    </section>

    <!-- Historical Trends Section -->
    <section class="section-container" id="history-section" aria-label="历史趋势分析">
      <div class="panel glass-card">
        <div class="panel-header flex-wrap-mobile">
          <div class="panel-title-group">
            <div class="title-with-pill">
              <h2 class="panel-title">历史趋势分析</h2>
              <span id="history-window-label" class="pill-tag subtle-pill">24小时</span>
            </div>
            <span class="panel-subtitle" id="history-update-time">数据每 60 秒刷新一次</span>
          </div>

          <!-- Trend Controls -->
          <div class="panel-actions-group">
            <!-- Time window segmented buttons -->
            <div class="segmented-control" role="group" aria-label="趋势时间窗口">
              <button type="button" class="segment-btn active" data-history-win="last_24h">24小时</button>
              <button type="button" class="segment-btn" data-history-win="last_7d">7天</button>
              <button type="button" class="segment-btn" data-history-win="last_30d">30天</button>
            </div>

            <!-- Metric choice dropdown or segmented buttons -->
            <div class="segmented-control metric-segment" role="group" aria-label="趋势指标切换">
              <button type="button" class="segment-btn active" data-history-metric="requests">请求趋势</button>
              <button type="button" class="segment-btn" data-history-metric="tokens">Token 消耗</button>
              <button type="button" class="segment-btn" data-history-metric="cost">费用</button>
              <button type="button" class="segment-btn" data-history-metric="success_rate">成功率</button>
              <button type="button" class="segment-btn" data-history-metric="latency">响应延迟</button>
            </div>
          </div>
        </div>

        <!-- Window Summary Ribbon -->
        <div class="window-summary-ribbon" id="history-summary-ribbon">
          <div class="summary-ribbon-item"><span>窗口总请求</span><strong id="hsum-requests">—</strong></div>
          <div class="summary-ribbon-item"><span>窗口总 Token</span><strong id="hsum-tokens">—</strong></div>
          <div class="summary-ribbon-item"><span>窗口总费用</span><strong id="hsum-cost">—</strong></div>
          <div class="summary-ribbon-item"><span>窗口成功率</span><strong id="hsum-rate">—</strong></div>
          <div class="summary-ribbon-item"><span>平均延迟</span><strong id="hsum-latency">—</strong></div>
        </div>

        <!-- Interactive SVG Chart Area -->
        <div class="chart-wrapper" id="history-chart-wrapper">
          <div class="chart-container" id="history-chart-container">
            <svg id="history-svg-chart" aria-label="历史趋势折线图"></svg>
            <!-- Floating Glass Tooltip -->
            <div id="chart-tooltip" class="chart-tooltip glass-card"></div>
          </div>
          <div id="history-chart-empty" class="chart-empty-state is-hidden">
            <p>所选时间窗口暂无可用的趋势数据</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Breakdown Section (Models & API Keys) -->
    <section class="section-container" id="breakdown-section" aria-label="模型与 API KEY 聚合分析">
      <div class="panel glass-card">
        <div class="panel-header flex-wrap-mobile">
          <div class="panel-title-group">
            <div class="title-with-pill">
              <h2 class="panel-title">聚合分布与排行榜</h2>
              <span id="breakdown-window-label" class="pill-tag subtle-pill">过去 24 小时</span>
            </div>
            <span class="panel-subtitle" id="breakdown-update-time">模型与 API Key 多维度聚合 · 每 120 秒刷新</span>
          </div>

          <div class="panel-actions-group">
            <!-- Tab: Models vs API Keys -->
            <div class="segmented-control" role="group" aria-label="分析对象切换">
              <button type="button" class="segment-btn active" id="btn-tab-models" data-breakdown-tab="models">模型分布</button>
              <button type="button" class="segment-btn" id="btn-tab-keys" data-breakdown-tab="keys">API KEY 排行</button>
            </div>

            <!-- Window: 24h vs 7d -->
            <div class="segmented-control" role="group" aria-label="分析时间窗口">
              <button type="button" class="segment-btn active" data-breakdown-win="last_24h">24h</button>
              <button type="button" class="segment-btn" data-breakdown-win="last_7d">7d</button>
            </div>

            <!-- Sort metric -->
            <div class="segmented-control" role="group" aria-label="排序指标">
              <button type="button" class="segment-btn active" data-breakdown-sort="requests">按请求</button>
              <button type="button" class="segment-btn" data-breakdown-sort="tokens">按 Token</button>
              <button type="button" class="segment-btn" data-breakdown-sort="cost">按费用</button>
            </div>
          </div>
        </div>

        <!-- Breakdown Content View: Models -->
        <div id="breakdown-models-view" class="breakdown-view">
          <div class="table-wrap">
            <table class="status-table" id="models-table">
              <thead id="models-table-head">
                <tr>
                  <th class="col-rank">#</th>
                  <th>模型名称</th>
                  <th class="col-req-bar">请求量</th>
                  <th>成功率</th>
                  <th>Token 消耗</th>
                  <th>缓存命中率</th>
                  <th>预估费用</th>
                </tr>
              </thead>
              <tbody id="breakdown-models-body">
                <tr><td colspan="7" class="empty-cell">正在加载模型数据...</td></tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Breakdown Content View: API Keys -->
        <div id="breakdown-keys-view" class="breakdown-view is-hidden">
          <div class="table-wrap">
            <table class="status-table" id="keys-table">
              <thead id="keys-table-head">
                <tr>
                  <th class="col-rank">#</th>
                  <th>API KEY 备注 / 身份</th>
                  <th class="col-req-bar">请求量</th>
                  <th>成功率</th>
                  <th>Token 消耗</th>
                  <th>预估费用</th>
                  <th>平均延迟</th>
                  <th>最近活跃</th>
                  <th class="col-action">详情</th>
                </tr>
              </thead>
              <tbody id="breakdown-keys-body">
                <tr><td colspan="9" class="empty-cell">正在加载 API KEY 数据...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </section>

    <!-- Recent Calls Table (from calls.json) -->
    <section class="section-container" id="recent-calls-section" aria-label="最近调用明细">
      <div class="panel glass-card">
        <div class="panel-header flex-wrap-mobile">
          <div class="panel-title-group">
            <div class="title-with-pill">
              <h2 class="panel-title">最近调用明细</h2>
              <span class="pill-tag gradient-pill" id="calls-count-badge">最新 100 条</span>
            </div>
            <span class="panel-subtitle" id="calls-update-time">包含模型、状态、耗时与 Token 分解 · 每 10 秒刷新</span>
          </div>

          <!-- Calls Search and Filter Controls -->
          <div class="panel-actions-group">
            <div class="search-input-wrap">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input type="text" id="calls-search-input" placeholder="搜索 Key / 模型 / 思考强度..." aria-label="搜索最近调用">
            </div>

            <div class="segmented-control" role="group" aria-label="状态筛选">
              <button type="button" class="segment-btn active" data-calls-filter="all">全部</button>
              <button type="button" class="segment-btn" data-calls-filter="ok">成功</button>
              <button type="button" class="segment-btn" data-calls-filter="failed">失败</button>
              <button type="button" class="segment-btn" data-calls-filter="429">HTTP 429</button>
            </div>
          </div>
        </div>

        <!-- Table of recent calls -->
        <div class="table-wrap">
          <table class="status-table" id="calls-table">
            <thead>
              <tr>
                <th class="col-time">请求时间</th>
                <th>API KEY</th>
                <th>模型</th>
                <th>状态</th>
                <th>Token 消耗</th>
                <th>总延迟</th>
                <th>首字延迟 (TTFT)</th>
                <th class="col-action-wide">详情</th>
              </tr>
            </thead>
            <tbody id="calls-table-body">
              <tr><td colspan="8" class="empty-cell">正在加载最近调用明细...</td></tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination bar -->
        <div class="table-pagination-bar" id="calls-pagination-bar">
          <span class="pagination-info" id="calls-pagination-info">第 1 / 1 页 · 共 0 条记录</span>
          <div class="pagination-buttons">
            <button type="button" class="btn-page" id="calls-page-prev" disabled>上一页</button>
            <button type="button" class="btn-page" id="calls-page-next" disabled>下一页</button>
          </div>
        </div>
      </div>
    </section>

    <!-- System Footer & Security Notice -->
    <footer class="footer glass-card">
      <div class="footer-top">
        <div class="security-notice">
          <span>本页面为公网受保护只读监控看板。绝不暴露、传输或推导完整 API Key、管理密钥、客户端 IP、请求正文、响应正文或账号凭据。</span>
        </div>
      </div>

      <!-- Sidecars Independent Health Indicators -->
      <div class="sidecars-status-bar">
        <span class="sidecar-item" id="sidecar-snapshot">
          <span class="sidecar-dot ok"></span> 快照 <code id="sidecar-snapshot-refresh">10s</code>
        </span>
        <span class="sidecar-item" id="sidecar-calls">
          <span class="sidecar-dot ok"></span> 调用明细 <code id="sidecar-calls-refresh">10s</code>
        </span>
        <span class="sidecar-item" id="sidecar-history">
          <span class="sidecar-dot ok"></span> 历史趋势 <code id="sidecar-history-refresh">60s</code>
        </span>
        <span class="sidecar-item" id="sidecar-breakdown">
          <span class="sidecar-dot ok"></span> 聚合分布 <code id="sidecar-breakdown-refresh">120s</code>
        </span>
        <span class="sidecar-item" id="sidecar-meta">
          <span class="sidecar-dot ok"></span> 契约元数据
        </span>
      </div>
    </footer>
  </div>

  <script src="app.js" defer></script>
</body>
</html>
CPA229_INDEX_EOF

    cat > "${target_dir}/app.css" <<'CPA229_CSS_EOF'
/* CPA / CPAMP Public Status Dashboard CSS v2 */
:root {
  color-scheme: light dark;
  --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
  --font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;

  /* Core Light Palette - Luminous Pearl & Crisp Frosted Glass */
  --bg: #fbfcfe;
  --bg-gradient: radial-gradient(at 0% 0%, rgba(56, 189, 248, 0.12) 0px, transparent 50%),
                 radial-gradient(at 100% 0%, rgba(244, 114, 182, 0.09) 0px, transparent 50%),
                 radial-gradient(at 50% 100%, rgba(129, 140, 248, 0.08) 0px, transparent 52%),
                 radial-gradient(at 85% 45%, rgba(56, 189, 248, 0.06) 0px, transparent 48%);

  --surface: rgba(255, 255, 255, 0.76);
  --surface-hover: rgba(255, 255, 255, 0.9);
  --surface-active: rgba(255, 255, 255, 0.98);
  --surface-opaque: #ffffff;

  --surface-card: rgba(255, 255, 255, 0.78);
  --surface-card-hover: rgba(255, 255, 255, 0.92);
  --surface-card-subtle: rgba(255, 255, 255, 0.65);
  --surface-metric: rgba(255, 255, 255, 0.74);
  --surface-metric-hover: rgba(255, 255, 255, 0.92);
  --surface-table-head: rgba(241, 245, 249, 0.85);
  --surface-table-head-text: #475569;
  --surface-table-row-hover: rgba(240, 249, 255, 0.75);
  --surface-table-row-alt: rgba(248, 250, 252, 0.45);
  --surface-table-border: rgba(226, 232, 240, 0.8);
  --surface-table-detail: rgba(248, 250, 252, 0.85);
  --surface-control: rgba(255, 255, 255, 0.75);
  --surface-control-active: rgba(255, 255, 255, 0.95);
  --surface-input: rgba(255, 255, 255, 0.85);
  --surface-tooltip: rgba(255, 255, 255, 0.95);
  --surface-ribbon: rgba(241, 245, 249, 0.65);
  --surface-shelf: rgba(255, 255, 255, 0.55);
  --surface-pill: rgba(241, 245, 249, 0.8);

  --text-main: #0f172a;
  --text-secondary: #475569;
  --text-muted: #64748b;
  --text-subtle: #94a3b8;

  --border-glass: rgba(255, 255, 255, 0.9);
  --border-card: rgba(255, 255, 255, 0.85);
  --border-card-subtle: rgba(226, 232, 240, 0.8);
  --border-line: rgba(226, 232, 240, 0.7);
  --border-hover: rgba(56, 189, 248, 0.45);
  --border-control: rgba(56, 189, 248, 0.3);
  --border-control-active: rgba(14, 165, 233, 0.6);

  /* Sky Blue & Cyan Refined Accents */
  --sky-blue: #0ea5e9;
  --sky-blue-light: #38bdf8;
  --sky-blue-deep: #0284c7;
  --sky-border: rgba(56, 189, 248, 0.45);
  --sky-border-hover: rgba(14, 165, 233, 0.75);
  --sky-glow: 0 4px 18px -2px rgba(14, 165, 233, 0.22);
  --sky-glow-lg: 0 8px 30px -4px rgba(14, 165, 233, 0.32);

  /* Vibrant Rainbow Accents */
  --accent-indigo: #6366f1;
  --accent-violet: #8b5cf6;
  --accent-emerald: #10b981;
  --accent-amber: #f59e0b;
  --accent-rose: #f43f5e;
  --accent-cyan: #06b6d4;
  --accent-sky: #0284c7;

  /* Glass Elevation & Shadows */
  --shadow-card: 0 6px 28px -3px rgba(15, 23, 42, 0.03), 0 1px 3px rgba(15, 23, 42, 0.02), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  --shadow-card-hover: 0 20px 44px -8px rgba(15, 23, 42, 0.07), 0 6px 20px -2px rgba(14, 165, 233, 0.15), 0 0 0 1px rgba(56, 189, 248, 0.35), inset 0 1px 0 rgba(255, 255, 255, 1);
  --shadow-glow: 0 0 25px rgba(14, 165, 233, 0.2);

  /* Chart colors */
  --chart-grid: rgba(203, 213, 225, 0.6);
  --chart-axis: #64748b;
  --chart-x-axis: #64748b;

  /* Transitions & Curves */
  --ease-spring: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-soft: cubic-bezier(0.2, 0.8, 0.2, 1);
  --transition-fast: 0.15s ease;
  --transition-normal: 0.25s var(--ease-spring);
  --transition-card: 0.42s var(--ease-spring);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #090d16;
    --bg-gradient: radial-gradient(at 0% 0%, rgba(56, 189, 248, 0.16) 0px, transparent 50%),
                   radial-gradient(at 100% 0%, rgba(244, 114, 182, 0.12) 0px, transparent 50%),
                   radial-gradient(at 50% 100%, rgba(56, 189, 248, 0.12) 0px, transparent 50%);

    --surface: rgba(17, 24, 39, 0.78);
    --surface-hover: rgba(24, 33, 53, 0.88);
    --surface-active: rgba(30, 41, 65, 0.95);
    --surface-opaque: #0f172a;

    --surface-card: rgba(15, 23, 42, 0.82);
    --surface-card-hover: rgba(24, 36, 64, 0.92);
    --surface-card-subtle: rgba(15, 23, 42, 0.7);
    --surface-metric: rgba(15, 23, 42, 0.82);
    --surface-metric-hover: rgba(24, 36, 64, 0.92);
    --surface-table-head: rgba(30, 41, 59, 0.92);
    --surface-table-head-text: #94a3b8;
    --surface-table-row-hover: rgba(30, 58, 95, 0.45);
    --surface-table-row-alt: rgba(15, 23, 42, 0.45);
    --surface-table-border: rgba(51, 65, 85, 0.6);
    --surface-table-detail: rgba(15, 23, 42, 0.9);
    --surface-control: rgba(15, 23, 42, 0.8);
    --surface-control-active: rgba(30, 41, 59, 0.95);
    --surface-input: rgba(15, 23, 42, 0.88);
    --surface-tooltip: rgba(15, 23, 42, 0.96);
    --surface-ribbon: rgba(30, 41, 59, 0.7);
    --surface-shelf: rgba(15, 23, 42, 0.7);
    --surface-pill: rgba(30, 41, 59, 0.8);

    --text-main: #f8fafc;
    --text-secondary: #cbd5e1;
    --text-muted: #94a3b8;
    --text-subtle: #64748b;

    --border-glass: rgba(255, 255, 255, 0.12);
    --border-card: rgba(56, 189, 248, 0.22);
    --border-card-subtle: rgba(51, 65, 85, 0.6);
    --border-line: rgba(51, 65, 85, 0.6);
    --border-hover: rgba(56, 189, 248, 0.5);
    --border-control: rgba(56, 189, 248, 0.35);
    --border-control-active: rgba(56, 189, 248, 0.7);

    --chart-grid: rgba(51, 65, 85, 0.5);
    --chart-axis: #94a3b8;
    --chart-x-axis: #64748b;

    --shadow-card: 0 10px 30px -5px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.08);
    --shadow-card-hover: 0 18px 40px -6px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(56, 189, 248, 0.45);
  }
}

/* Global Box Sizing & Reset */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html, body {
  width: 100%;
  min-height: 100vh;
  overflow-x: hidden;
  background-color: var(--bg);
  background-image: var(--bg-gradient);
  background-attachment: fixed;
  color: var(--text-main);
  font-family: var(--font-family);
  font-size: 14px;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  position: relative;
  overflow-x: hidden;
}

/* Ambient Glowing Mesh Background */
.ambient-glow {
  position: fixed;
  border-radius: 50%;
  filter: blur(115px);
  pointer-events: none;
  z-index: 0;
  opacity: 0.65;
  animation: floatAmbient 20s ease-in-out infinite alternate;
}

.glow-1 {
  width: 580px;
  height: 580px;
  top: -120px;
  left: -80px;
  background: radial-gradient(circle, rgba(56, 189, 248, 0.25) 0%, rgba(14, 165, 233, 0.08) 65%, transparent 100%);
}

.glow-2 {
  width: 620px;
  height: 620px;
  top: 15%;
  right: -140px;
  background: radial-gradient(circle, rgba(244, 114, 182, 0.18) 0%, rgba(236, 72, 153, 0.05) 65%, transparent 100%);
  animation-delay: -7s;
}

.glow-3 {
  width: 680px;
  height: 680px;
  bottom: -150px;
  left: 20%;
  background: radial-gradient(circle, rgba(129, 140, 248, 0.16) 0%, rgba(56, 189, 248, 0.08) 65%, transparent 100%);
  animation-delay: -14s;
}

@keyframes floatAmbient {
  0% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(35px, 25px) scale(1.06); }
  100% { transform: translate(-25px, -15px) scale(0.95); }
}

/* Main Layout Shell */
.shell {
  position: relative;
  z-index: 1;
  width: min(1560px, calc(100% - 48px));
  margin: 28px auto 60px;
  display: flex;
  flex-direction: column;
  gap: 22px;
}

/* Frosted Glass Card Primitive */
.glass-card {
  background: var(--surface-card);
  backdrop-filter: blur(28px) saturate(190%);
  -webkit-backdrop-filter: blur(28px) saturate(190%);
  border: 1px solid var(--border-glass);
  border-radius: 20px;
  box-shadow: var(--shadow-card);
  transition: transform var(--transition-card), box-shadow var(--transition-card), border-color var(--transition-card), background var(--transition-card);
  position: relative;
}

.hero-header:hover,
.panel:hover,
.footer:hover {
  transform: translateY(-2px);
  border-color: rgba(56, 189, 248, 0.38);
  background: var(--surface-hover);
  box-shadow: 0 20px 48px -10px rgba(15, 23, 42, 0.07), 0 8px 24px -4px rgba(14, 165, 233, 0.12), inset 0 1px 0 rgba(255, 255, 255, 1);
}

/* Top Hero Header */
.hero-header {
  padding: 22px 28px 18px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.hero-main-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 24px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 18px;
}

/* Brand Logo: Clean CPAMP Vector Wordmark (Image #5 reference) */
.brand-logo-wrap {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 12px;
  cursor: default;
  user-select: none;
  text-decoration: none;
  padding: 4px 2px;
  flex-shrink: 0;
  transition: transform 0.25s var(--ease-spring);
}

.brand-logo-wrap:hover {
  transform: translateY(-1px);
}

.brand-cpamp-svg {
  width: 148px;
  height: 32px;
  display: block;
}

.brand-cpamp-svg .logo-strokes {
  stroke: #0b132b;
  transition: stroke 0.3s ease;
}

.brand-cpamp-svg .logo-diamond {
  fill: #0066ff;
  transition: fill 0.3s ease, filter 0.3s ease;
}

.brand-logo-wrap:hover .brand-cpamp-svg .logo-diamond {
  filter: drop-shadow(0 0 6px rgba(0, 102, 255, 0.75));
}

.hero-headings {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.hero-tags {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pill-tag {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 11px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.02em;
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);
  transition: all 0.35s var(--ease-spring);
}

.gradient-pill {
  background: linear-gradient(135deg, rgba(240, 249, 255, 0.85) 0%, rgba(224, 242, 254, 0.65) 100%);
  color: #0284c7;
  border: 1px solid rgba(56, 189, 248, 0.55);
  box-shadow: 0 2px 8px rgba(14, 165, 233, 0.12), inset 0 1px 0 rgba(255, 255, 255, 0.95);
}

.gradient-pill:hover {
  transform: translateY(-1px);
  border-color: rgba(14, 165, 233, 0.75);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.96) 0%, rgba(224, 242, 254, 0.85) 100%);
  box-shadow: 0 4px 16px -1px rgba(14, 165, 233, 0.28), inset 0 1px 0 #ffffff;
}

.subtle-pill {
  background: rgba(240, 249, 255, 0.65);
  color: #0284c7;
  border: 1px solid rgba(186, 230, 253, 0.85);
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.05);
}

.subtle-pill:hover {
  border-color: rgba(56, 189, 248, 0.65);
  background: var(--surface-card-hover);
  transform: translateY(-1px);
}

.hero-title {
  font-size: clamp(22px, 2.5vw, 30px);
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-main);
}

.hero-subtitle {
  font-size: 13px;
  color: var(--text-muted);
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

/* Snapshot Shelf below Title Bar (Image #3 style) */
.hero-snapshot-shelf {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-top: 14px;
  border-top: 1px solid rgba(186, 230, 253, 0.65);
  font-size: 12px;
  flex-wrap: wrap;
}

.shelf-left {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

.shelf-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 4px 12px;
  background: rgba(240, 249, 255, 0.85);
  border: 1px solid rgba(56, 189, 248, 0.45);
  border-radius: 9999px;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.08);
}

.shelf-status-name {
  font-size: 12px;
  font-weight: 600;
  color: #0284c7;
}

.shelf-divider {
  width: 1px;
  height: 14px;
  background: rgba(186, 230, 253, 0.8);
}

.shelf-meta-item {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
}

.shelf-label {
  color: var(--text-muted);
  font-size: 12px;
}

.shelf-val {
  color: var(--text-main);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  font-size: 12px;
}

.shelf-iso {
  color: var(--text-subtle);
  font-size: 11px;
  font-family: ui-monospace, monospace;
}

.shelf-right {
  display: flex;
  align-items: center;
}

.shelf-subtle-hint {
  font-size: 11px;
  color: var(--text-muted);
}

@media (prefers-color-scheme: dark) {
  .hero-snapshot-shelf {
    border-top-color: rgba(51, 65, 85, 0.7);
  }
  .shelf-status-badge {
    background: rgba(30, 41, 59, 0.75);
    border-color: rgba(56, 189, 248, 0.4);
  }
  .shelf-status-name {
    color: #38bdf8;
  }
  .shelf-divider {
    background: rgba(51, 65, 85, 0.8);
  }
  .brand-cpamp-svg .logo-strokes {
    stroke: #f8fafc;
  }
  .brand-cpamp-svg .logo-diamond {
    fill: #38bdf8;
  }
}

.status-pulse-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #10b981;
  position: relative;
}

.status-pulse-dot.ok {
  background: #10b981;
  box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  animation: pulseGreen 2.5s infinite;
}

.status-pulse-dot.stale {
  background: #f59e0b;
  box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.7);
  animation: pulseAmber 2.5s infinite;
}

.status-pulse-dot.bad {
  background: #ef4444;
  box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7);
  animation: pulseRed 2.5s infinite;
}

@keyframes pulseGreen {
  0% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.6); }
  70% { box-shadow: 0 0 0 7px rgba(16, 185, 129, 0); }
  100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
}

@keyframes pulseAmber {
  0% { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.6); }
  70% { box-shadow: 0 0 0 7px rgba(245, 158, 11, 0); }
  100% { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0); }
}

@keyframes pulseRed {
  0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.6); }
  70% { box-shadow: 0 0 0 7px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}

.status-texts {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.status-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-main);
}

.status-timestamp {
  font-size: 10px;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
}

/* Segmented Controls (Buttons) */
.segmented-control {
  display: inline-flex;
  align-items: center;
  padding: 3px;
  background: rgba(240, 249, 255, 0.65);
  backdrop-filter: blur(20px) saturate(190%);
  -webkit-backdrop-filter: blur(20px) saturate(190%);
  border: 1px solid rgba(56, 189, 248, 0.35);
  border-radius: 14px;
  gap: 3px;
  box-shadow: inset 0 1px 3px rgba(15, 23, 42, 0.03), 0 2px 8px rgba(14, 165, 233, 0.06);
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.segmented-control:hover {
  border-color: rgba(56, 189, 248, 0.55);
  box-shadow: inset 0 1px 3px rgba(15, 23, 42, 0.03), 0 4px 14px rgba(14, 165, 233, 0.12);
}

.segment-btn {
  padding: 6px 14px;
  border: 1px solid transparent;
  background: transparent;
  border-radius: 11px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  white-space: nowrap;
  position: relative;
  transition: all 0.32s var(--ease-spring);
}

.segment-btn:hover:not(.active) {
  color: #0284c7;
  background: var(--surface-card-hover);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border-color: rgba(56, 189, 248, 0.35);
  transform: translateY(-1px);
  box-shadow: 0 3px 10px rgba(14, 165, 233, 0.1);
}

.segment-btn.active {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.96) 0%, rgba(240, 249, 255, 0.92) 100%);
  color: #0284c7;
  font-weight: 600;
  border: 1px solid rgba(56, 189, 248, 0.5);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  box-shadow: 0 3px 12px -1px rgba(14, 165, 233, 0.22), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  transform: translateY(0);
}

.segment-btn.active:hover {
  transform: translateY(-0.5px);
  border-color: rgba(14, 165, 233, 0.75);
  box-shadow: 0 4px 16px -1px rgba(14, 165, 233, 0.3), inset 0 1px 0 #ffffff;
}

.segment-btn:active {
  transform: translateY(0.5px) scale(0.98);
}

@media (prefers-color-scheme: dark) {
  .segmented-control {
    background: rgba(15, 23, 42, 0.65);
    border-color: rgba(56, 189, 248, 0.3);
  }
  .segment-btn:hover:not(.active) {
    background: rgba(255, 255, 255, 0.06);
    color: #38bdf8;
    border-color: rgba(56, 189, 248, 0.3);
  }
  .segment-btn.active {
    background: rgba(30, 41, 59, 0.9);
    color: #38bdf8;
    border-color: rgba(56, 189, 248, 0.6);
  }
}

/* Buttons & Icon Actions */
.action-btn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 7px 15px;
  border-radius: 14px;
  border: 1px solid var(--border-control);
  background: var(--surface-control);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  color: var(--text-main);
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 10px rgba(14, 165, 233, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  transition: all 0.35s var(--ease-spring);
}

.action-btn:hover {
  background: var(--surface-control-active);
  border-color: rgba(14, 165, 233, 0.75);
  color: #0284c7;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px -2px rgba(14, 165, 233, 0.28), 0 0 0 2px rgba(56, 189, 248, 0.2), inset 0 1px 0 #ffffff;
}

.action-btn:active {
  transform: translateY(0.5px) scale(0.98);
}

.action-btn:active .refresh-icon {
  transform: rotate(180deg);
}

.refresh-icon {
  transition: transform 0.4s ease;
}

/* Section Headers */
.section-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-header-compact {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 6px;
}

.section-title-sm {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.01em;
}

.section-badge-info {
  font-size: 11px;
  color: var(--text-muted);
  background: rgba(148, 163, 184, 0.12);
  padding: 2px 8px;
  border-radius: 9999px;
}

/* Metric Cards Grid (Today Core Metrics) */
.cards-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: 16px;
}

.metric-card {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  position: relative;
  overflow: hidden;
  border-radius: 18px;
  border: 1px solid var(--border-card-subtle);
  background: var(--surface-metric);
  backdrop-filter: blur(24px) saturate(180%);
  -webkit-backdrop-filter: blur(24px) saturate(180%);
  box-shadow: 0 4px 20px -2px rgba(15, 23, 42, 0.03), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  transition: transform 0.42s var(--ease-spring), box-shadow 0.42s var(--ease-spring), border-color 0.42s ease, background 0.42s ease;
}

.metric-card::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: transparent;
  transition: background 0.3s ease;
}

.metric-card.card-requests::before { background: linear-gradient(90deg, #0284c7, #38bdf8); }
.metric-card.card-rate::before { background: linear-gradient(90deg, #10b981, #34d399); }
.metric-card.card-tokens::before { background: linear-gradient(90deg, #8b5cf6, #a78bfa); }
.metric-card.card-cost::before { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
.metric-card.card-latency::before { background: linear-gradient(90deg, #06b6d4, #38bdf8); }
.metric-card.card-rolling::before { background: linear-gradient(90deg, #f43f5e, #fb7185); }

.metric-card:hover {
  background: var(--surface-metric-hover);
  box-shadow: 0 18px 36px -6px rgba(15, 23, 42, 0.07), 0 6px 18px -2px rgba(14, 165, 233, 0.15), inset 0 1px 0 #ffffff;
}

.metric-icon-wrap {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-indigo { background: rgba(14, 165, 233, 0.12); color: #0284c7; }
.icon-emerald { background: rgba(16, 185, 129, 0.12); color: #10b981; }
.icon-violet { background: rgba(139, 92, 246, 0.12); color: #8b5cf6; }
.icon-amber { background: rgba(245, 158, 11, 0.12); color: #f59e0b; }
.icon-cyan { background: rgba(6, 182, 212, 0.12); color: #06b6d4; }
.icon-rose { background: rgba(244, 63, 94, 0.12); color: #f43f5e; }

.metric-body {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.metric-label {
  font-size: 12px;
  color: var(--text-muted);
  font-weight: 500;
}

.metric-value {
  font-size: clamp(22px, 2vw, 28px);
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
  line-height: 1.15;
}

.metric-sub {
  font-size: 11px;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Panels & Panel Headers */
.panel {
  padding: 24px 28px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.flex-wrap-mobile {
  flex-wrap: wrap;
}

.panel-title-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.title-with-pill {
  display: flex;
  align-items: center;
  gap: 10px;
}

.panel-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.01em;
}

.panel-subtitle {
  font-size: 12px;
  color: var(--text-muted);
}

.panel-actions-group {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* Cumulative Overview (All-Time) Grid */
.badge-status-subtle {
  font-size: 11px;
  font-weight: 600;
  color: #0284c7;
  background: rgba(240, 249, 255, 0.85);
  border: 1px solid rgba(56, 189, 248, 0.45);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  padding: 3px 10px;
  border-radius: 9999px;
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.08);
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 14px;
}

.overview-stat-box {
  padding: 16px 18px;
  background: var(--surface-card-subtle);
  border: 1px solid var(--border-card-subtle);
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.02), inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition: transform 0.4s var(--ease-spring), box-shadow 0.4s var(--ease-spring), border-color 0.4s ease, background 0.4s ease;
}

.overview-stat-box:hover {
  background: var(--surface-card-hover);
  border-color: rgba(56, 189, 248, 0.6);
  box-shadow: 0 10px 24px -4px rgba(14, 165, 233, 0.16), inset 0 1px 0 #ffffff;
}

@media (prefers-color-scheme: dark) {
  .overview-stat-box {
    background: rgba(30, 41, 59, 0.55);
    border-color: rgba(51, 65, 85, 0.7);
  }
  .gradient-pill {
    background: rgba(14, 165, 233, 0.15);
    border-color: rgba(56, 189, 248, 0.45);
    color: #38bdf8;
  }
  .subtle-pill {
    background: rgba(30, 41, 59, 0.6);
    border-color: rgba(56, 189, 248, 0.35);
    color: #7dd3fc;
  }
}

.overview-label {
  font-size: 12px;
  color: var(--text-muted);
  font-weight: 500;
}

.overview-val {
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.01em;
  font-variant-numeric: tabular-nums;
}

.color-emerald { color: #10b981; }
.color-rose { color: #f43f5e; }
.color-indigo { color: #0284c7; }

/* Window Summary Ribbon */
.window-summary-ribbon {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 13px 20px;
  background: linear-gradient(135deg, rgba(240, 249, 255, 0.75) 0%, rgba(248, 250, 252, 0.65) 100%);
  border: 1px solid rgba(56, 189, 248, 0.38);
  border-radius: 16px;
  flex-wrap: wrap;
  backdrop-filter: blur(18px) saturate(180%);
  -webkit-backdrop-filter: blur(18px) saturate(180%);
  box-shadow: 0 4px 18px -2px rgba(14, 165, 233, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition: all 0.35s var(--ease-spring);
}

.window-summary-ribbon:hover {
  border-color: rgba(56, 189, 248, 0.58);
  box-shadow: 0 6px 22px -2px rgba(14, 165, 233, 0.14), inset 0 1px 0 #ffffff;
}

@media (prefers-color-scheme: dark) {
  .window-summary-ribbon {
    background: rgba(14, 165, 233, 0.1);
    border-color: rgba(56, 189, 248, 0.35);
    box-shadow: 0 4px 18px -2px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.05);
  }
  .window-summary-ribbon:hover {
    border-color: rgba(56, 189, 248, 0.55);
    box-shadow: 0 6px 22px -2px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  }
}

.summary-ribbon-item {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.summary-ribbon-item span {
  font-size: 11px;
  color: var(--text-muted);
}

.summary-ribbon-item strong {
  font-size: 14px;
  font-weight: 700;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
}

/* SVG Chart Wrapper & Tooltip */
.chart-wrapper {
  position: relative;
  width: 100%;
  min-height: 340px;
}

.chart-container {
  position: relative;
  width: 100%;
  height: 340px;
}

#history-svg-chart {
  width: 100%;
  height: 100%;
  display: block;
  overflow: visible;
}

/* Axis Typography (Item #2) */
.chart-axis-text {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", "PingFang SC", "Hiragino Sans GB", sans-serif;
  font-size: 11.5px;
  font-weight: 600;
  fill: #475569;
  letter-spacing: 0.025em;
  user-select: none;
  font-variant-numeric: tabular-nums;
}

.chart-x-axis-text {
  font-weight: 500;
  fill: #64748b;
  font-size: 11px;
}

@media (prefers-color-scheme: dark) {
  .chart-axis-text {
    fill: #94a3b8;
  }
  .chart-x-axis-text {
    fill: #64748b;
  }
}

.chart-tooltip {
  position: absolute;
  padding: 10px 15px;
  font-size: 12px;
  color: var(--text-main);
  border-radius: 14px;
  background: var(--surface-tooltip);
  backdrop-filter: blur(24px) saturate(190%);
  -webkit-backdrop-filter: blur(24px) saturate(190%);
  border: 1px solid rgba(56, 189, 248, 0.45);
  box-shadow: 0 14px 34px -4px rgba(15, 23, 42, 0.12), 0 4px 14px rgba(14, 165, 233, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  z-index: 10;
  transition: opacity 0.15s ease;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  visibility: hidden;
}

.chart-tooltip-fo {
  overflow: visible;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.chart-tooltip-fo.is-visible {
  opacity: 1;
}

.chart-tooltip-fo .chart-tooltip {
  position: static;
  transform: none;
  display: inline-block;
  white-space: nowrap;
  pointer-events: none;
}

@media (prefers-color-scheme: dark) {
  .chart-tooltip {
    background: rgba(15, 23, 42, 0.92);
    border-color: rgba(56, 189, 248, 0.45);
  }
}

.chart-tooltip-title {
  font-weight: 600;
  margin-bottom: 4px;
  color: var(--text-muted);
  font-size: 11px;
}

.chart-tooltip-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
}

.chart-tooltip-value {
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}

.chart-empty-state {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  font-size: 14px;
  background: rgba(148, 163, 184, 0.05);
  border-radius: 14px;
}

/* Search Input Wrap */
.search-input-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  background: var(--surface-input);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid var(--border-line);
  border-radius: 14px;
  color: var(--text-muted);
  box-shadow: 0 2px 8px rgba(14, 165, 233, 0.05), inset 0 1px 0 rgba(255, 255, 255, 0.95);
  transition: all 0.3s var(--ease-spring);
}

.search-input-wrap:hover {
  border-color: rgba(56, 189, 248, 0.6);
}

.search-input-wrap:focus-within {
  background: var(--surface-card-hover);
  border-color: rgba(14, 165, 233, 0.8);
  box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.2), 0 4px 16px rgba(14, 165, 233, 0.12), inset 0 1px 0 #ffffff;
}

.search-input-wrap input {
  border: none;
  background: transparent;
  font-family: inherit;
  font-size: 12px;
  color: var(--text-main);
  outline: none;
  width: 180px;
}

.search-input-wrap input::placeholder {
  color: var(--text-muted);
}

@media (prefers-color-scheme: dark) {
  .search-input-wrap {
    background: rgba(30, 41, 59, 0.6);
    border-color: rgba(56, 189, 248, 0.35);
  }
  .search-input-wrap:focus-within {
    background: rgba(30, 41, 59, 0.95);
  }
}

/* Table Styles */
.table-wrap {
  width: 100%;
  overflow-x: auto;
  border-radius: 16px;
  border: 1px solid rgba(186, 230, 253, 0.7);
  background: var(--surface-card-subtle);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.02);
}

.status-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  min-width: 680px;
}

.status-table th {
  text-align: left;
  padding: 12px 14px;
  background: rgba(148, 163, 184, 0.08);
  color: var(--text-muted);
  font-weight: 600;
  font-size: 11px;
  letter-spacing: 0.03em;
  border-bottom: 1px solid var(--border-line);
}

.status-table td {
  padding: 10px 14px;
  border-bottom: 1px solid var(--border-line);
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
  vertical-align: middle;
}

.status-table tbody tr {
  transition: background var(--transition-fast);
}

.status-table tbody tr:hover {
  background: rgba(14, 165, 233, 0.035);
}

.status-table tbody tr.row-expanded {
  background: rgba(14, 165, 233, 0.06);
}

.empty-cell {
  text-align: center !important;
  padding: 30px !important;
  color: var(--text-muted) !important;
}

/* Status Badges */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 9px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
}

.status-badge.status-ok {
  background: rgba(16, 185, 129, 0.12);
  color: #059669;
  border: 1px solid rgba(16, 185, 129, 0.25);
}

.status-badge.status-429 {
  background: rgba(245, 158, 11, 0.12);
  color: #d97706;
  border: 1px solid rgba(245, 158, 11, 0.25);
}

.status-badge.status-5xx,
.status-badge.status-fail {
  background: rgba(244, 63, 94, 0.12);
  color: #e11d48;
  border: 1px solid rgba(244, 63, 94, 0.25);
}

/* Call Model Cell & Reasoning Effort */
.call-model-cell {
  vertical-align: middle;
}

.call-model-wrap {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  gap: 3px;
  min-width: 0;
}

.call-model-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  line-height: 1.3;
  word-break: break-word;
}

.call-model-effort {
  font-size: 11px;
  font-weight: 500;
  color: var(--text-muted);
  line-height: 1.2;
  letter-spacing: 0.01em;
  white-space: nowrap;
}

/* API Key Identity Pill */
.key-identity-wrap {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.key-name {
  font-weight: 600;
  color: var(--text-main);
  word-break: break-word;
}

.key-tag {
  padding: 1px 6px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 600;
  white-space: nowrap;
  flex-shrink: 0;
}

.key-tag-alias {
  background: rgba(240, 249, 255, 0.85);
  color: #0284c7;
  border: 1px solid rgba(56, 189, 248, 0.5);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.08);
}

@media (prefers-color-scheme: dark) {
  .key-tag-alias {
    background: rgba(14, 165, 233, 0.2);
    color: #38bdf8;
    border-color: rgba(56, 189, 248, 0.45);
  }
}

.key-tag-masked {
  background: rgba(100, 116, 139, 0.12);
  color: #475569;
}

.key-tag-anon {
  background: rgba(148, 163, 184, 0.15);
  color: var(--text-muted);
}

.key-id-sub {
  font-size: 10px;
  color: var(--text-subtle);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  margin-top: 3px;
  line-height: 1.2;
}

/* Table Detail Expander & Drilldown Rows */
.row-detail-container {
  padding: 16px 20px !important;
  background: rgba(148, 163, 184, 0.04) !important;
}

.call-detail-card {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  padding: 16px;
  border-radius: 14px;
  background: var(--surface-table-detail);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(56, 189, 248, 0.35);
  box-shadow: 0 4px 16px rgba(14, 165, 233, 0.06), inset 0 1px 0 #ffffff;
}

@media (prefers-color-scheme: dark) {
  .call-detail-card {
    background: rgba(30, 41, 59, 0.85);
    border-color: rgba(56, 189, 248, 0.35);
  }
}

.detail-stat-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.detail-stat-label {
  font-size: 11px;
  color: var(--text-muted);
}

.detail-stat-val {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
}

.btn-expand-toggle {
  background: rgba(240, 249, 255, 0.75);
  border: 1px solid rgba(56, 189, 248, 0.4);
  color: #0284c7;
  cursor: pointer;
  padding: 5px 9px;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-family: inherit;
  font-size: 11px;
  font-weight: 600;
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  box-shadow: 0 1px 4px rgba(14, 165, 233, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition: all 0.28s var(--ease-spring);
}

.btn-expand-toggle.icon-only {
  width: 32px;
  height: 32px;
  padding: 0;
  border-radius: 8px;
}

.btn-expand-toggle:hover {
  background: var(--surface-card-hover);
  border-color: rgba(14, 165, 233, 0.75);
  color: #0369a1;
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(14, 165, 233, 0.2), inset 0 1px 0 #ffffff;
}

.btn-expand-toggle:active {
  transform: translateY(0.5px) scale(0.97);
}

.btn-expand-toggle .chevron-icon {
  width: 13px;
  height: 13px;
  stroke: currentColor;
  stroke-width: 2.2;
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  display: inline-block;
  vertical-align: middle;
}

.btn-expand-toggle.is-expanded .chevron-icon {
  transform: rotate(180deg);
}

.btn-key-expand {
  padding: 4px 8px;
  border-radius: 9px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  line-height: 1.15;
}

.btn-text-2line {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  color: #0284c7;
  white-space: nowrap;
}

.btn-key-expand:hover .btn-text-2line {
  color: #0369a1;
}

/* Progress / Share Bar */
.metric-progress-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 120px;
}

progress.metric-progress-bar {
  appearance: none;
  -webkit-appearance: none;
  width: 100%;
  height: 5px;
  border: none;
  border-radius: 9999px;
  background: rgba(148, 163, 184, 0.18);
  overflow: hidden;
  display: block;
}

progress.metric-progress-bar::-webkit-progress-bar {
  background: rgba(148, 163, 184, 0.18);
  border-radius: 9999px;
}

progress.metric-progress-bar::-webkit-progress-value {
  background: linear-gradient(90deg, #0284c7 0%, #38bdf8 100%);
  box-shadow: 0 1px 6px rgba(14, 165, 233, 0.3);
  border-radius: 9999px;
  transition: width 0.3s ease;
}

progress.metric-progress-bar::-moz-progress-bar {
  background: linear-gradient(90deg, #0284c7 0%, #38bdf8 100%);
  box-shadow: 0 1px 6px rgba(14, 165, 233, 0.3);
  border-radius: 9999px;
}

/* Quota Section (GPT Team Quota) — refined aesthetic telemetry v2.31 */
.quota-accounts-list {
  display: flex;
  flex-direction: column;
  gap: 18px;
  margin-top: 12px;
}

.quota-account-block + .quota-account-block {
  border-top: 1px solid var(--border-line);
  padding-top: 18px;
}

.quota-account-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.quota-account-heading {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px 12px;
  min-width: 0;
}

.quota-account-update {
  color: var(--text-muted);
  font-size: 12px;
}

.quota-cards-grid {
  margin-top: 10px;
}

.quota-account-card-grid {
  margin-top: 12px;
}

.quota-account-empty {
  width: 100%;
}

.quota-combined-card {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  background: var(--surface-control);
  border: 1px solid var(--border-line);
  border-radius: 18px;
  overflow: hidden;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  box-shadow: 0 4px 18px rgba(14, 165, 233, 0.05), inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition: all 0.3s var(--ease-spring);
}

.quota-combined-card:hover {
  border-color: rgba(14, 165, 233, 0.35);
  box-shadow: 0 8px 24px rgba(14, 165, 233, 0.1), inset 0 1px 0 #ffffff;
  transform: translateY(-2px);
}

.quota-combined-card.quota-waiting-refresh {
  border-color: rgba(245, 158, 11, 0.45);
}

.quota-window {
  min-width: 0;
  padding: 16px 22px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 12px;
}

.quota-window + .quota-window {
  position: relative;
  border-left: none;
}

/* Desktop Aesthetic Etched Divider with specular glow */
.quota-window + .quota-window::before {
  content: "";
  position: absolute;
  left: 0;
  top: 14px;
  bottom: 14px;
  width: 1px;
  background: linear-gradient(
    180deg,
    rgba(226, 232, 240, 0) 0%,
    rgba(186, 230, 253, 0.4) 15%,
    rgba(56, 189, 248, 0.55) 50%,
    rgba(186, 230, 253, 0.4) 85%,
    rgba(226, 232, 240, 0) 100%
  );
  box-shadow: 1px 0 0 rgba(255, 255, 255, 0.9);
  pointer-events: none;
  transition: all 0.35s var(--ease-spring);
}

.quota-combined-card:hover .quota-window + .quota-window::before {
  background: linear-gradient(
    180deg,
    rgba(56, 189, 248, 0) 0%,
    rgba(56, 189, 248, 0.6) 20%,
    rgba(14, 165, 233, 0.85) 50%,
    rgba(56, 189, 248, 0.6) 80%,
    rgba(56, 189, 248, 0) 100%
  );
  box-shadow: 1px 0 0 #ffffff, 0 0 8px rgba(14, 165, 233, 0.2);
}

.quota-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.quota-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.quota-card-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.01em;
  margin: 0;
  white-space: nowrap;
}

.quota-card-empty {
  padding: 18px 0;
  text-align: center;
  color: var(--text-muted);
  font-size: 13px;
}

/* Frosted Reset Status Pill */
.quota-reset-pill {
  display: inline-flex;
  align-items: center;
  gap: 5.5px;
  padding: 3px 11px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-variant-numeric: tabular-nums;
  background: rgba(241, 245, 249, 0.75);
  border: 1px solid rgba(226, 232, 240, 0.85);
  color: var(--text-secondary);
  white-space: nowrap;
  line-height: 1.3;
  transition: all 0.25s ease;
  flex-shrink: 1;
  min-width: 0;
}

.quota-reset-pill svg {
  flex-shrink: 0;
  color: var(--text-muted);
  transition: color 0.25s ease;
}

.quota-reset-text {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.quota-window.quota-waiting-refresh .quota-reset-pill {
  background: rgba(254, 243, 199, 0.7);
  border-color: rgba(245, 158, 11, 0.4);
  color: #b45309;
}

.quota-window.quota-waiting-refresh .quota-reset-pill svg {
  color: #d97706;
}

/* Metric Row — Remaining & Used tightly hugging progress bar */
.quota-metric-row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 7px;
}

.quota-metric-left {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
}

.quota-metric-label {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--text-muted);
}

.quota-metric-value {
  font-size: 29px;
  font-weight: 800;
  letter-spacing: -0.025em;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
  line-height: 1;
}

.quota-metric-percent {
  font-size: 17px;
  font-weight: 700;
  color: var(--text-muted);
  margin-left: 1.5px;
}

.quota-metric-right {
  display: inline-flex;
  align-items: baseline;
  gap: 4px;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.quota-metric-sublabel {
  font-size: 12.5px;
  font-weight: 500;
  color: var(--text-muted);
}

.quota-metric-subvalue {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--text-secondary);
}

/* Bar Section */
.quota-bar-wrapper {
  width: 100%;
}

progress.quota-progress-bar {
  appearance: none;
  -webkit-appearance: none;
  width: 100%;
  height: 7px;
  border: none;
  border-radius: 9999px;
  background: rgba(148, 163, 184, 0.16);
  overflow: hidden;
  display: block;
}

progress.quota-progress-bar::-webkit-progress-bar {
  background: rgba(148, 163, 184, 0.16);
  border-radius: 9999px;
}

progress.quota-progress-bar::-webkit-progress-value {
  background: linear-gradient(90deg, #0284c7 0%, #38bdf8 100%);
  border-radius: 9999px;
  box-shadow: 0 1px 6px rgba(14, 165, 233, 0.25);
  transition: width 0.4s ease;
}

progress.quota-progress-bar::-moz-progress-bar {
  background: linear-gradient(90deg, #0284c7 0%, #38bdf8 100%);
  border-radius: 9999px;
  box-shadow: 0 1px 6px rgba(14, 165, 233, 0.25);
}

.quota-empty-notice {
  padding: 36px 20px;
  text-align: center;
  color: var(--text-muted);
  font-size: 13px;
}

.share-bar-container {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: 100%;
}

.share-bar-track {
  height: 6px;
  width: 100%;
  background: rgba(148, 163, 184, 0.15);
  border-radius: 9999px;
  overflow: hidden;
}

.share-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #0284c7 0%, #38bdf8 100%);
  box-shadow: 0 1px 6px rgba(14, 165, 233, 0.3);
  border-radius: 9999px;
  transition: width 0.4s var(--ease-spring);
}

/* Pagination Bar */
.table-pagination-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 4px 0;
  font-size: 12px;
  color: var(--text-muted);
}

.pagination-buttons {
  display: flex;
  gap: 8px;
}

.btn-page {
  padding: 6px 14px;
  border-radius: 10px;
  border: 1px solid var(--border-line);
  background: var(--surface-control);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  font-family: inherit;
  font-size: 12px;
  font-weight: 500;
  color: var(--text-main);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.05), inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition: all 0.3s var(--ease-spring);
}

.btn-page:hover:not(:disabled) {
  background: var(--surface-control-active);
  border-color: rgba(14, 165, 233, 0.7);
  color: #0284c7;
  transform: translateY(-1.5px);
  box-shadow: 0 4px 14px rgba(14, 165, 233, 0.2), inset 0 1px 0 #ffffff;
}

.btn-page:active:not(:disabled) {
  transform: translateY(0.5px) scale(0.98);
}

.btn-page:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* Footer & Sidecars Status Bar */
.footer {
  padding: 22px 28px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.footer-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.security-notice {
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1.6;
}

.sidecars-status-bar {
  display: flex;
  align-items: center;
  gap: 18px;
  flex-wrap: wrap;
  padding-top: 14px;
  border-top: 1px solid var(--border-line);
}

.sidecar-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--text-secondary);
}

.sidecar-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #10b981;
}

.sidecar-dot.stale { background: #f59e0b; }
.sidecar-dot.bad { background: #ef4444; }

.sidecar-item code {
  background: rgba(148, 163, 184, 0.15);
  padding: 1px 5px;
  border-radius: 4px;
  font-family: ui-monospace, monospace;
  font-size: 10px;
}

/* Responsive Breakpoints */
@media (max-width: 1400px) {
  .cards-grid.today-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 992px) {
  .overview-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
  .call-detail-card {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .quota-combined-card {
    grid-template-columns: 1fr;
  }

  .quota-window {
    padding: 14px 16px;
  }

  .quota-window + .quota-window::before {
    display: none;
  }

  .quota-window + .quota-window {
    border-left: 0;
    border-top: 1px solid var(--border-line);
  }

  .quota-account-header {
    align-items: flex-start;
  }

  .quota-card-header {
    flex-wrap: wrap;
    gap: 8px;
  }

  .quota-metric-value {
    font-size: 25px;
  }

  .chart-tooltip {
    position: absolute;
    top: 14px;
    bottom: auto;
    transform: none;
    max-width: calc(100% - 28px);
    z-index: 20;
  }
  .chart-tooltip.chart-tooltip-align-left {
    left: 14px;
    right: auto;
  }
  .chart-tooltip.chart-tooltip-align-right {
    right: 14px;
    left: auto;
  }

  .shell {
    width: calc(100% - 24px);
    margin: 14px auto 40px;
    gap: 16px;
  }

  .hero-header {
    flex-direction: column;
    align-items: flex-start;
    padding: 18px 16px;
    gap: 18px;
  }

  .hero-main-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
    width: 100%;
  }

  .hero-right {
    width: 100%;
    justify-content: space-between;
  }

  .hero-snapshot-shelf {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
    width: 100%;
  }

  .shelf-left {
    gap: 10px;
    width: 100%;
  }

  .shelf-divider {
    display: none;
  }

  .cards-grid.today-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }

  .overview-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .panel {
    padding: 18px;
    gap: 16px;
  }

  .panel-actions-group {
    width: 100%;
    overflow-x: auto;
    padding-bottom: 4px;
  }

  .search-input-wrap input {
    width: 120px;
  }
}

@media (max-width: 480px) {
  .cards-grid.today-grid {
    grid-template-columns: 1fr;
  }

  .overview-grid {
    grid-template-columns: 1fr;
  }

  .call-detail-card {
    grid-template-columns: 1fr;
  }

  .hero-right {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
  }

  .status-indicator-pill {
    justify-content: center;
  }

  .segmented-control {
    width: 100%;
    justify-content: space-around;
  }

  .segment-btn {
    flex: 1;
    text-align: center;
  }
}

/* ==========================================================================
   CSP Utility Classes & Semantic State Helpers
   ========================================================================== */
.is-hidden {
  display: none !important;
}

.chart-tooltip.is-visible {
  opacity: 1 !important;
  visibility: visible !important;
}

.col-rank {
  width: 60px;
}

.col-req-bar {
  min-width: 140px;
}

.col-time {
  min-width: 100px;
}

.col-action {
  width: 60px;
  text-align: center;
}

.col-action-wide {
  width: 70px;
  text-align: center;
}

.cell-center {
  text-align: center;
}

.cell-strong {
  font-weight: 600;
}

.cell-muted {
  color: var(--text-muted);
}

.rank-cell {
  font-weight: 600;
  color: var(--text-muted);
}

.rank-cell.rank-top {
  color: var(--accent-sky);
}

.chart-overlay {
  cursor: crosshair;
}

.chart-crosshair {
  pointer-events: none;
}

.chart-hover-dot {
  pointer-events: none;
}

.chart-tooltip-sub {
  font-size: 11px;
  color: var(--text-muted);
}

.subtable-wrap {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.subtable-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--accent-sky);
}

.subtable-grid {
  font-size: 12px;
}

/* Warnings, Stale & Availability Badges */
.status-badge.status-warn {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  border: 1px solid rgba(245, 158, 11, 0.35);
}

.status-pulse-dot.warn,
.status-pulse-dot.stale {
  background: #f59e0b;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.25);
}

.sidecar-dot.warn,
.sidecar-dot.stale {
  background: #f59e0b;
}

.pill-tag.status-pill.warn,
.pill-tag.status-pill.stale {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  border-color: rgba(245, 158, 11, 0.35);
}

.pill-tag.status-pill.ok {
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
  border-color: rgba(16, 185, 129, 0.35);
}

.pill-tag.status-pill.bad {
  background: rgba(244, 63, 94, 0.15);
  color: #f43f5e;
  border-color: rgba(244, 63, 94, 0.35);
}

@media (prefers-color-scheme: dark) {
  .quota-combined-card {
    background: var(--surface-control);
    border-color: var(--border-line);
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.05);
  }
  .quota-combined-card:hover {
    border-color: rgba(56, 189, 248, 0.45);
    box-shadow: 0 8px 24px rgba(14, 165, 233, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.08);
  }
  .quota-window + .quota-window::before {
    background: linear-gradient(
      180deg,
      rgba(56, 189, 248, 0) 0%,
      rgba(56, 189, 248, 0.25) 20%,
      rgba(56, 189, 248, 0.6) 50%,
      rgba(56, 189, 248, 0.25) 80%,
      rgba(56, 189, 248, 0) 100%
    );
    box-shadow: -1px 0 0 rgba(0, 0, 0, 0.4), 1px 0 0 rgba(255, 255, 255, 0.06);
  }
  .quota-combined-card:hover .quota-window + .quota-window::before {
    background: linear-gradient(
      180deg,
      rgba(56, 189, 248, 0) 0%,
      rgba(56, 189, 248, 0.5) 20%,
      rgba(14, 165, 233, 0.9) 50%,
      rgba(56, 189, 248, 0.5) 80%,
      rgba(56, 189, 248, 0) 100%
    );
    box-shadow: 0 0 10px rgba(56, 189, 248, 0.3), 1px 0 0 rgba(255, 255, 255, 0.12);
  }
  .quota-reset-pill {
    background: rgba(30, 41, 59, 0.6);
    border-color: rgba(51, 65, 85, 0.7);
    color: var(--text-secondary);
  }
  .quota-reset-pill svg {
    color: var(--text-muted);
  }
  .quota-window.quota-waiting-refresh .quota-reset-pill {
    background: rgba(120, 53, 15, 0.35);
    border-color: rgba(245, 158, 11, 0.5);
    color: #fbbf24;
  }
  .quota-window.quota-waiting-refresh .quota-reset-pill svg {
    color: #fbbf24;
  }
  progress.quota-progress-bar,
  progress.metric-progress-bar {
    background: rgba(255, 255, 255, 0.12);
  }
  progress.quota-progress-bar::-webkit-progress-bar,
  progress.metric-progress-bar::-webkit-progress-bar {
    background: rgba(255, 255, 255, 0.12);
  }
}
CPA229_CSS_EOF

    cat > "${target_dir}/app.js" <<'CPA229_JS_EOF'
'use strict';

/**
 * CPA / CPAMP Public Status Dashboard Frontend v2
 * Fully static, zero external dependencies, CSP-friendly.
 */


// Safe Storage Helpers
function safeGetStorage(key, defaultVal) {
  try {
    const v = localStorage.getItem(key);
    return v !== null ? v : defaultVal;
  } catch (e) {
    return defaultVal;
  }
}

function safeSetStorage(key, val) {
  try {
    localStorage.setItem(key, val);
  } catch (e) {}
}

// Time Reference & Staleness Evaluator
let _virtualTimeOffset = 0;
function initTimeReference() {
  if (window.STANDALONE_DATA) {
    let maxMs = 0;
    try {
      for (const k in window.STANDALONE_DATA) {
        const d = window.STANDALONE_DATA[k];
        if (d && d.generated_at_ms) maxMs = Math.max(maxMs, Number(d.generated_at_ms));
        if (d && d.generated_unix) maxMs = Math.max(maxMs, Number(d.generated_unix) * 1000);
      }
    } catch (e) {}
    if (maxMs > 0) {
      _virtualTimeOffset = Date.now() - maxMs;
    }
  }
}

function getNow() {
  return Date.now() - _virtualTimeOffset;
}

function checkStaleness(generatedAtMs, expectedTtlSec) {
  if (!generatedAtMs || !Number.isFinite(Number(generatedAtMs))) {
    return { isStale: false, ageSec: 0, thresholdSec: 60 };
  }
  const ageSec = Math.max(0, (getNow() - Number(generatedAtMs)) / 1000);
  const thresholdSec = Math.max(30, (expectedTtlSec || 60) * 2.5);
  return { isStale: ageSec > thresholdSec, ageSec, thresholdSec };
}

// DOM SVG Icon Helper (CSP-friendly, zero innerHTML)
function createChevronIcon() {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", "chevron-icon");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("fill", "none");
  svg.setAttribute("stroke", "currentColor");
  svg.setAttribute("stroke-width", "2.2");
  svg.setAttribute("stroke-linecap", "round");
  svg.setAttribute("stroke-linejoin", "round");
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute("d", "M6 9l6 6 6-6");
  svg.appendChild(path);
  return svg;
}

// Global State
const state = {
  // Config & Metadata
  meta: null,
  dataMeta: null,
  refreshSeconds: {
    snapshot: 10,
    calls: 10,
    history: 60,
    breakdown: 120,
    quota: 30,
    meta: 300
  },
  // v2.44 low-I/O C defaults; data-meta.json overrides them after loading.
  windowCacheSeconds: {
    all_time: 3600,
    history_last_24h: 600,
    history_last_7d: 1800,
    history_last_30d: 3600,
    breakdown_last_24h: 180,
    breakdown_last_7d: 3600
  },
  nextRefreshIn: 10,

  // Raw Datasets
  snapshot: null,
  calls: null,
  history: null,
  breakdown: null,
  quota: null,

  // Fetch Status & Timestamps
  lastFetched: {
    snapshot: 0,
    calls: 0,
    history: 0,
    breakdown: 0,
    quota: 0,
    meta: 0
  },
  fetchErrors: {
    snapshot: null,
    calls: null,
    history: null,
    breakdown: null,
    quota: null
  },

  // Interactive View Settings
  numFormat: safeGetStorage('cpa_num_format', 'intl'), // 'intl' | 'cn'
  historyWindow: 'last_24h', // 'last_24h' | 'last_7d' | 'last_30d'
  historyMetric: 'requests', // 'requests' | 'tokens' | 'cost' | 'success_rate' | 'latency'
  breakdownWindow: 'last_24h', // 'last_24h' | 'last_7d'
  breakdownTab: 'models', // 'models' | 'keys'
  breakdownSort: 'requests', // 'requests' | 'tokens' | 'cost'
  breakdownExpandedKeyId: null,

  // Calls Table Settings
  callsSearch: '',
  callsFilter: 'all', // 'all' | 'ok' | 'failed' | '429'
  callsPage: 1,
  callsPageSize: 15,
  callsExpandedId: null
};

// DOM Helper
const $ = (id) => document.getElementById(id);

// Number and Unit Formatters
function isNumeric(val) {
  return typeof val === 'number' && Number.isFinite(val);
}

function formatCompactNumber(value) {
  if (value === null || value === undefined || !isNumeric(Number(value))) return '—';
  const n = Number(value);
  const a = Math.abs(n);

  if (state.numFormat === 'cn') {
    // Chinese Format (万 / 亿)
    if (a >= 1e8) return `${(n / 1e8).toFixed(2)}亿`;
    if (a >= 1e4) return `${(n / 1e4).toFixed(2)}万`;
    return Math.round(n).toLocaleString('zh-CN');
  }

  // International Format (K / M / B)
  if (a >= 1e9) return `${(n / 1e9).toFixed(2)}B`;
  if (a >= 1e6) return `${(n / 1e6).toFixed(2)}M`;
  if (a >= 1e3) return `${(n / 1e3).toFixed(2)}K`;
  return Math.round(n).toLocaleString('en-US');
}

function formatInteger(value) {
  if (value === null || value === undefined || !isNumeric(Number(value))) return '—';
  return Math.round(Number(value)).toLocaleString('en-US');
}

function formatCurrency(value) {
  if (value === null || value === undefined || !isNumeric(Number(value))) return '—';
  const n = Number(value);
  if (n < 0.01 && n > 0) return '$' + n.toFixed(4);
  return '$' + n.toFixed(2);
}

function formatLatency(value) {
  if (value === null || value === undefined || !isNumeric(Number(value))) return '—';
  const ms = Number(value);
  if (ms >= 1000) return `${(ms / 1000).toFixed(2)} s`;
  return `${Math.round(ms)} ms`;
}

function formatRate(value) {
  if (value === null || value === undefined || !isNumeric(Number(value))) return '—';
  const ratio = Number(value);
  return `${(ratio * 100).toFixed(2)}%`;
}

// Beijing Time (Asia/Shanghai, UTC+8) Formatters
const beijingTimeFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false
});

const beijingHourFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false
});

const beijingDateFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  month: '2-digit',
  day: '2-digit'
});

const beijingDateTimeFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false
});

const beijingDateTimeShortFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false
});

const beijingResetTimeFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false
});

const beijingResetDateTimeFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false
});

const beijingDateYMDFmt = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit'
});

function formatTime(ms) {
  if (!ms || !Number.isFinite(Number(ms))) return '—';
  const d = new Date(Number(ms));
  return beijingTimeFmt.format(d);
}

function formatDateTime(ms) {
  if (!ms || !Number.isFinite(Number(ms))) return '—';
  const d = new Date(Number(ms));
  return beijingDateTimeFmt.format(d);
}

function setText(id, text) {
  const el = $(id);
  if (el) el.textContent = String(text);
}

// Data Fetcher
async function fetchStaticJson(path) {
  if (window.STANDALONE_DATA) {
    const cleanPath = path.startsWith('/') ? path : '/' + path;
    const nameWithoutSlash = cleanPath.substring(1);
    if (window.STANDALONE_DATA[cleanPath] !== undefined) return window.STANDALONE_DATA[cleanPath];
    if (window.STANDALONE_DATA[nameWithoutSlash] !== undefined) return window.STANDALONE_DATA[nameWithoutSlash];
    if (window.STANDALONE_DATA[path] !== undefined) return window.STANDALONE_DATA[path];
  }
  const resp = await fetch(path, { cache: 'no-cache', credentials: 'omit' });
  if (!resp.ok) {
    throw new Error(`HTTP ${resp.status}`);
  }
  return await resp.json();
}

// Load Meta Configuration
async function loadMeta() {
  try {
    const data = await fetchStaticJson('/data-meta.json');
    if (data) {
      state.meta = data;
      state.dataMeta = data;
      if (data.files) {
        if (data.files.snapshot && data.files.snapshot.refresh_seconds) {
          state.refreshSeconds.snapshot = Number(data.files.snapshot.refresh_seconds);
        }
        if (data.files.calls && data.files.calls.refresh_seconds) {
          state.refreshSeconds.calls = Number(data.files.calls.refresh_seconds);
        }
        if (data.files.history && data.files.history.refresh_seconds) {
          state.refreshSeconds.history = Number(data.files.history.refresh_seconds);
        }
        if (data.files.breakdown && data.files.breakdown.refresh_seconds) {
          state.refreshSeconds.breakdown = Number(data.files.breakdown.refresh_seconds);
        }
        const quotaMeta = data.files.account_quota || data.files.quota;
        if (quotaMeta && quotaMeta.refresh_seconds) {
          state.refreshSeconds.quota = Number(quotaMeta.refresh_seconds);
        }
      }
      if (data.window_cache_seconds) {
        Object.assign(state.windowCacheSeconds, data.window_cache_seconds);
      }
      state.fetchErrors.meta = null;
    }
    state.lastFetched.meta = Date.now();
  } catch (err) {
    console.warn('[CPA] Meta load error (fallback to default refresh intervals):', err);
    state.fetchErrors.meta = err.message;
  }
  updateDataLayerTag();
  updateGlobalStatus();
  updateSidecarsStatus();
}

// Load Core Snapshot
async function loadSnapshot() {
  try {
    const data = await fetchStaticJson('/snapshot.json');
    if (!data || data.schema_version !== 1) {
      throw new Error('Invalid snapshot schema');
    }
    const isSame = state.snapshot && state.snapshot.generated_unix === data.generated_unix;
    state.snapshot = data;
    state.lastFetched.snapshot = Date.now();
    state.fetchErrors.snapshot = null;
    if (!isSame) {
      renderTodayCards();
      renderAllTime();
    }
  } catch (err) {
    console.error('[CPA] Snapshot fetch failed:', err);
    state.fetchErrors.snapshot = err.message;
  }
  updateDataLayerTag();
  updateGlobalStatus();
  updateSidecarsStatus();
}

// Load Recent Calls
async function loadCalls() {
  try {
    const data = await fetchStaticJson('/calls.json');
    if (data && Array.isArray(data.items)) {
      const isSame = state.calls && state.calls.generated_at_ms === data.generated_at_ms;
      state.calls = data;
      state.lastFetched.calls = Date.now();
      state.fetchErrors.calls = null;
      if (!isSame) {
        renderRecentCalls();
      }
    }
  } catch (err) {
    console.warn('[CPA] Calls fetch failed:', err);
    state.fetchErrors.calls = err.message;
  }
  updateGlobalStatus();
  updateSidecarsStatus();
}

// Load History
async function loadHistory() {
  try {
    const data = await fetchStaticJson('/history.json');
    if (data && data.windows) {
      const isSame = state.history && state.history.generated_at_ms === data.generated_at_ms;
      state.history = data;
      state.lastFetched.history = Date.now();
      state.fetchErrors.history = null;
      if (!isSame) {
        renderHistory();
      }
    }
  } catch (err) {
    console.warn('[CPA] History fetch failed:', err);
    state.fetchErrors.history = err.message;
  }
  updateGlobalStatus();
  updateSidecarsStatus();
}

// Load Breakdown
async function loadBreakdown() {
  try {
    const data = await fetchStaticJson('/breakdown.json');
    if (data && data.windows) {
      const isSame = state.breakdown && state.breakdown.generated_at_ms === data.generated_at_ms;
      state.breakdown = data;
      state.lastFetched.breakdown = Date.now();
      state.fetchErrors.breakdown = null;
      if (!isSame) {
        renderBreakdown();
      }
    }
  } catch (err) {
    console.warn('[CPA] Breakdown fetch failed:', err);
    state.fetchErrors.breakdown = err.message;
  }
  updateGlobalStatus();
  updateSidecarsStatus();
}

// Load Account Quota (from /account-quota.json)
async function loadAccountQuota() {
  try {
    const data = await fetchStaticJson('/account-quota.json');
    if (data && typeof data === 'object') {
      const isSame = state.quota && state.quota.generated_at_ms === data.generated_at_ms;
      state.quota = data;
      state.lastFetched.quota = Date.now();
      state.fetchErrors.quota = null;
      if (!isSame || !$('quota-cards-grid')?.hasChildNodes()) {
        renderAccountQuota();
      }
    }
  } catch (err) {
    state.quota = null;
    state.fetchErrors.quota = err.message;
    renderAccountQuota();
  }
}

// UI Render: Today Core Cards
function renderTodayCards() {
  if (!state.snapshot) return;
  const today = state.snapshot.today || {};
  const rolling = state.snapshot.rolling_30m || {};

  setText('today-requests', formatInteger(today.requests));
  setText('today-requests-sub', `成功 ${formatInteger(today.success_requests)} · 失败 ${formatInteger(today.failed_requests)}`);

  setText('today-success-rate', formatRate(today.success_rate));
  let rateSub = '—';
  if (today.success_rate !== null && today.success_rate !== undefined && isNumeric(Number(today.success_rate))) {
    const rateVal = Number(today.success_rate);
    rateSub = rateVal >= 0.98 ? '高可用状态 (≥98%)' : (rateVal >= 0.95 ? '运行稳定 (≥95%)' : '存在异常关注 (<95%)');
  }
  setText('today-success-rate-sub', rateSub);

  setText('today-tokens', formatCompactNumber(today.total_tokens));
  setText('today-tokens-sub', `入: ${formatCompactNumber(today.input_tokens)} · 出: ${formatCompactNumber(today.output_tokens)}`);

  setText('today-cost', formatCurrency(today.cost_usd));
  setText('today-cost-sub', '基于模型单价估算');

  setText('today-latency', formatLatency(today.avg_latency_ms));
  setText('today-latency-sub', '请求端到端响应耗时');

  setText('recent-requests', formatInteger(rolling.requests));
  const rpm = isNumeric(rolling.rpm) ? rolling.rpm.toFixed(1) : '—';
  const tpm = isNumeric(rolling.tpm) ? formatCompactNumber(rolling.tpm) : '—';
  setText('recent-rolling-sub', `RPM: ${rpm} · TPM: ${tpm}`);

  if (state.snapshot.cpamp_version) {
    const vTag = $('cpamp-version-tag');
    if (vTag) {
      vTag.textContent = `CPAMP v${state.snapshot.cpamp_version}`;
      vTag.classList.remove('is-hidden');
    }
  }

  updateDataLayerTag();
}

function updateDataLayerTag() {
  const version = state.snapshot?.data_layer_version ?? state.dataMeta?.data_layer_version ?? null;
  const tag = $('hero-data-layer-tag');
  if (tag) {
    if (version !== null && version !== undefined) {
      tag.textContent = `Data Layer v${version}`;
    } else {
      tag.textContent = 'Data Layer';
    }
  }
}

// UI Render: Cumulative Overview (All-Time)
function renderAllTime() {
  if (!state.snapshot) return;
  const allAvailable = state.snapshot.all_time_available === true;
  const allStale = state.snapshot.all_time_stale === true;
  const all = state.snapshot.all_time || {};

  const badge = $('all-time-status-badge');
  if (badge) {
    badge.textContent = !allAvailable ? '全量历史暂未就绪' : (allStale ? '全量历史缓存陈旧' : '全量历史已连接');
    badge.className = 'pill-tag status-pill ' + (allAvailable && !allStale ? 'ok' : 'warn');
  }

  if (allAvailable && all) {
    setText('all-requests', formatInteger(all.requests));
    setText('all-tokens', formatCompactNumber(all.total_tokens));
    setText('all-success', formatInteger(all.success_requests));
    setText('all-failed', formatInteger(all.failed_requests));
    setText('all-rate', formatRate(all.success_rate));
  } else {
    setText('all-requests', '—');
    setText('all-tokens', '—');
    setText('all-success', '—');
    setText('all-failed', '—');
    setText('all-rate', '—');
  }
}

// UI Render: GPT Team Quota
function quotaAccountsFromPayload(quota) {
  if (Array.isArray(quota?.accounts) && quota.accounts.length > 0) {
    return quota.accounts.filter((item) => item && typeof item === "object");
  }
  return quota && typeof quota === "object" ? [quota] : [];
}

function quotaEventTime(quota) {
  const value = Number(quota?.source?.event_at_ms);
  return Number.isFinite(value) && value > 0 ? value : null;
}

function quotaSourceLabel(quota) {
  return quota?.source?.kind === "active_wham_usage" ? "主动查询" : "上游实时观测";
}

function renderAccountQuota() {
  const section = $("quota-section");
  if (!section) return;

  const quota = state.quota;
  if (!quota || (state.fetchErrors.quota && !quota.windows && !Array.isArray(quota.accounts))) {
    section.classList.add("is-hidden");
    return;
  }

  const grid = $("quota-cards-grid");
  if (!grid) return;
  const accounts = quotaAccountsFromPayload(quota);
  const hasMultiAccountPayload = Array.isArray(quota.accounts);

  section.classList.remove("is-hidden");

  // Preserve the accepted single-account layout exactly when only one account exists.
  if (accounts.length <= 1) {
    const single = accounts[0] || quota;
    grid.className = "quota-cards-grid";
    grid.replaceChildren();
    setText("quota-account-badge", single.account?.display || "GPT Team 主账号");

    if (single.available === false) {
      setText("quota-update-time", "暂无上游额度数据");
      setText("quota-status-badge", "暂无数据");
      const emptyDiv = document.createElement("div");
      emptyDiv.className = "quota-empty-notice quota-account-empty";
      emptyDiv.textContent = hasMultiAccountPayload && Number(quota.account_count) === 0
        ? "尚未观测到可识别的 GPT Team 账号额度；账号产生请求后会自动出现"
        : "暂无额度数据";
      grid.appendChild(emptyDiv);
      return;
    }

    setText("quota-status-badge", single.partial === true ? "部分数据可用" : "实时监测");
    const eventTime = quotaEventTime(single);
    setText("quota-update-time", `额度数据更新于 ${eventTime ? formatDateTime(eventTime) : "—"} · ${quotaSourceLabel(single)}`);
    renderQuotaCombinedCard(grid, single.windows?.five_hour, single.windows?.seven_day);
    return;
  }

  const availableCount = accounts.filter((item) => item.available === true).length;
  const latestAccount = accounts.reduce((latest, item) => (quotaEventTime(item) || 0) >= (quotaEventTime(latest) || 0) ? item : latest, null);
  const latestEventMs = quotaEventTime(latestAccount) || 0;
  const hasPartial = accounts.some((item) => item.available !== true || item.partial === true);
  setText("quota-account-badge", `${accounts.length} 个账号`);
  setText("quota-status-badge", hasPartial ? `${availableCount}/${accounts.length} 可用` : "实时监测");
  setText(
    "quota-update-time",
    `按账号独立展示 · 最近更新于 ${latestEventMs ? formatDateTime(latestEventMs) : "—"} · ${latestAccount ? quotaSourceLabel(latestAccount) : "上游实时观测"}`
  );

  grid.className = "quota-accounts-list";
  grid.replaceChildren();
  accounts.forEach((accountQuota, index) => renderQuotaAccountBlock(grid, accountQuota, index));
}

function renderQuotaAccountBlock(container, accountQuota, index) {
  const block = document.createElement("div");
  block.className = "quota-account-block";

  const header = document.createElement("div");
  header.className = "quota-account-header";

  const heading = document.createElement("div");
  heading.className = "quota-account-heading";

  const accountBadge = document.createElement("span");
  accountBadge.className = "pill-tag gradient-pill";
  accountBadge.textContent = accountQuota.account?.display || (index === 0 ? "GPT Team 主账号" : `GPT Team 账号 ${index + 1}`);
  heading.appendChild(accountBadge);

  const updateText = document.createElement("span");
  updateText.className = "quota-account-update";
  const eventTime = quotaEventTime(accountQuota);
  updateText.textContent = accountQuota.available === false
    ? "暂无上游额度数据"
    : `额度数据更新于 ${eventTime ? formatDateTime(eventTime) : "—"} · ${quotaSourceLabel(accountQuota)}`;
  heading.appendChild(updateText);
  header.appendChild(heading);

  // Per-account status badge was redundant with the section-level status badge.
  block.appendChild(header);

  const cards = document.createElement("div");
  cards.className = "quota-cards-grid quota-account-card-grid";
  if (accountQuota.available === false) {
    const emptyDiv = document.createElement("div");
    emptyDiv.className = "quota-empty-notice quota-account-empty";
    emptyDiv.textContent = "该账号暂无额度数据";
    cards.appendChild(emptyDiv);
  } else {
    renderQuotaCombinedCard(cards, accountQuota.windows?.five_hour, accountQuota.windows?.seven_day);
  }
  block.appendChild(cards);
  container.appendChild(block);
}

function renderQuotaCombinedCard(container, fiveHourData, sevenDayData) {
  const combined = document.createElement("div");
  combined.className = "quota-combined-card";

  renderQuotaWindow(combined, "5 小时额度", fiveHourData);
  renderQuotaWindow(combined, "7 天额度", sevenDayData);
  combined.classList.toggle("quota-waiting-refresh", Boolean(combined.querySelector(".quota-window.quota-waiting-refresh")));

  container.appendChild(combined);
}

function renderQuotaWindow(container, title, winData) {
  const windowEl = document.createElement("div");
  windowEl.className = "quota-window";

  const header = document.createElement("div");
  header.className = "quota-card-header";

  const titleWrap = document.createElement("div");
  titleWrap.className = "quota-title-wrap";

  const titleEl = document.createElement("h3");
  titleEl.className = "quota-card-title";
  titleEl.textContent = title;
  titleWrap.appendChild(titleEl);
  header.appendChild(titleWrap);

  if (!winData || typeof winData.remaining_percent !== "number") {
    windowEl.appendChild(header);
    const emptyNotice = document.createElement("div");
    emptyNotice.className = "quota-card-empty";
    emptyNotice.textContent = "暂无数据";
    windowEl.appendChild(emptyNotice);
    container.appendChild(windowEl);
    return;
  }

  const remPct = Math.max(0, Math.min(100, Number(winData.remaining_percent)));
  const usedPct = typeof winData.used_percent === "number"
    ? Math.max(0, Math.min(100, Number(winData.used_percent)))
    : Math.max(0, 100 - remPct);

  // Reset Status Pill (Header row, right-aligned)
  const resetPill = document.createElement("div");
  resetPill.className = "quota-reset-pill";

  const resetIcon = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  resetIcon.setAttribute("viewBox", "0 0 24 24");
  resetIcon.setAttribute("width", "13");
  resetIcon.setAttribute("height", "13");
  resetIcon.setAttribute("fill", "none");
  resetIcon.setAttribute("stroke", "currentColor");
  resetIcon.setAttribute("stroke-width", "2");
  resetIcon.setAttribute("stroke-linecap", "round");
  resetIcon.setAttribute("stroke-linejoin", "round");
  const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
  circle.setAttribute("cx", "12");
  circle.setAttribute("cy", "12");
  circle.setAttribute("r", "10");
  const poly = document.createElementNS("http://www.w3.org/2000/svg", "polyline");
  poly.setAttribute("points", "12 6 12 12 16 14");
  resetIcon.appendChild(circle);
  resetIcon.appendChild(poly);
  resetPill.appendChild(resetIcon);

  const resetText = document.createElement("span");
  resetText.className = "quota-reset-text";
  resetText.setAttribute("data-reset-ms", String(winData.reset_at_ms || ""));
  resetText.setAttribute("data-window-type", title.includes("7 天") ? "7d" : "5h");

  const resetAtMs = Number(winData.reset_at_ms);
  if (resetAtMs && Number.isFinite(resetAtMs)) {
    const is7d = title.includes("7 天");
    const isSameDay = isSameDayShanghai(resetAtMs, Date.now());
    const resetFormatted = (is7d || !isSameDay)
      ? beijingResetDateTimeFmt.format(new Date(resetAtMs))
      : beijingResetTimeFmt.format(new Date(resetAtMs));

    const diff = resetAtMs - Date.now();
    if (diff <= 0) {
      resetText.textContent = `${resetFormatted} 重置 · 已到重置时间，等待下一次请求刷新`;
      windowEl.classList.add("quota-waiting-refresh");
    } else {
      const countdownStr = formatCountdown(resetAtMs);
      resetText.textContent = `${resetFormatted} 重置 · ${countdownStr}`;
    }
  } else {
    resetText.textContent = "重置时间未知";
  }

  resetPill.appendChild(resetText);
  header.appendChild(resetPill);
  windowEl.appendChild(header);

  // Metric Row (Remaining on left, Used on right — tightly hugging the bar)
  const metricRow = document.createElement("div");
  metricRow.className = "quota-metric-row";

  const metricLeft = document.createElement("div");
  metricLeft.className = "quota-metric-left";

  const remLabel = document.createElement("span");
  remLabel.className = "quota-metric-label";
  remLabel.textContent = "剩余";
  metricLeft.appendChild(remLabel);

  const remValue = document.createElement("span");
  remValue.className = "quota-metric-value";
  remValue.textContent = remPct.toFixed(1);

  const remUnit = document.createElement("span");
  remUnit.className = "quota-metric-percent";
  remUnit.textContent = "%";
  remValue.appendChild(remUnit);
  metricLeft.appendChild(remValue);

  metricRow.appendChild(metricLeft);

  const metricRight = document.createElement("div");
  metricRight.className = "quota-metric-right";

  const usedLabel = document.createElement("span");
  usedLabel.className = "quota-metric-sublabel";
  usedLabel.textContent = "已用";
  metricRight.appendChild(usedLabel);

  const usedValue = document.createElement("span");
  usedValue.className = "quota-metric-subvalue";
  usedValue.textContent = `${usedPct.toFixed(1)}%`;
  metricRight.appendChild(usedValue);

  metricRow.appendChild(metricRight);
  windowEl.appendChild(metricRow);

  // Progress Bar Wrapper
  const barWrapper = document.createElement("div");
  barWrapper.className = "quota-bar-wrapper";

  const prog = document.createElement("progress");
  prog.className = "quota-progress-bar";
  prog.value = remPct;
  prog.max = 100;
  barWrapper.appendChild(prog);
  windowEl.appendChild(barWrapper);

  container.appendChild(windowEl);
}

function updateQuotaCountdowns() {
  document.querySelectorAll(".quota-reset-text[data-reset-ms]").forEach((el) => {
    const resetMsStr = el.getAttribute("data-reset-ms");
    const resetAtMs = Number(resetMsStr);
    if (!resetAtMs || !Number.isFinite(resetAtMs)) return;

    const is7d = el.getAttribute("data-window-type") === "7d";
    const isSameDay = isSameDayShanghai(resetAtMs, Date.now());
    const resetFormatted = (is7d || !isSameDay)
      ? beijingResetDateTimeFmt.format(new Date(resetAtMs))
      : beijingResetTimeFmt.format(new Date(resetAtMs));

    const windowEl = el.closest(".quota-window");
    const combined = el.closest(".quota-combined-card");
    const diff = resetAtMs - Date.now();
    if (diff <= 0) {
      el.textContent = `${resetFormatted} 重置 · 已到重置时间，等待下一次请求刷新`;
      if (windowEl) windowEl.classList.add("quota-waiting-refresh");
    } else {
      const countdownStr = formatCountdown(resetAtMs);
      el.textContent = `${resetFormatted} 重置 · ${countdownStr}`;
      if (windowEl) windowEl.classList.remove("quota-waiting-refresh");
    }
    if (combined) {
      combined.classList.toggle("quota-waiting-refresh", Boolean(combined.querySelector(".quota-window.quota-waiting-refresh")));
    }
  });
}

function formatCountdown(targetMs) {
  const diff = targetMs - Date.now();
  if (diff <= 0) {
    return "已到重置时间，等待下一次请求刷新";
  }
  const totalMinutes = Math.floor(diff / (60 * 1000));
  const days = Math.floor(totalMinutes / (24 * 60));
  const hours = Math.floor((totalMinutes % (24 * 60)) / 60);
  const minutes = totalMinutes % 60;

  if (days > 0) {
    return `还剩 ${days} 天 ${hours} 小时`;
  }
  if (hours > 0) {
    return `还剩 ${hours} 小时 ${minutes} 分`;
  }
  return `还剩 ${Math.max(1, minutes)} 分钟`;
}

function isSameDayShanghai(ts1, ts2) {
  const d1 = new Intl.DateTimeFormat("zh-CN", { timeZone: "Asia/Shanghai", day: "numeric", month: "numeric" }).format(new Date(ts1));
  const d2 = new Intl.DateTimeFormat("zh-CN", { timeZone: "Asia/Shanghai", day: "numeric", month: "numeric" }).format(new Date(ts2));
  return d1 === d2;
}

// UI Render: Historical Trends & SVG Chart
function renderHistory() {
  const summaryRibbon = $("history-summary-ribbon");
  const emptyState = $("history-chart-empty");
  const svg = $("history-svg-chart");

  // Update Window label
  const labels = { last_24h: "24小时", last_7d: "7天", last_30d: "30天" };
  setText("history-window-label", labels[state.historyWindow] || state.historyWindow);

  // Check Availability
  const metaAvail = state.dataMeta?.files?.history?.available !== false;
  const winAvail = state.history?.availability ? (state.history.availability[state.historyWindow] !== false) : true;
  const hasError = Boolean(state.fetchErrors.history);
  const win = state.history?.windows ? state.history.windows[state.historyWindow] : null;
  const isAvailable = metaAvail && winAvail && !hasError && win && Array.isArray(win.points) && win.points.length > 0;

  if (!isAvailable) {
    if (emptyState) {
      emptyState.classList.remove("is-hidden");
      emptyState.replaceChildren();
      const icon = document.createElement("div");
      icon.className = "chart-empty-icon";
      icon.textContent = "⚠";
      const strong = document.createElement("strong");
      strong.textContent = "该时间窗口历史趋势暂不可用";
      const span = document.createElement("span");
      span.textContent = hasError ? "数据同步异常或网络中断" : "后端 Exporter 暂未就绪或未聚合此范围数据";
      emptyState.appendChild(icon);
      emptyState.appendChild(strong);
      emptyState.appendChild(span);
    }
    if (svg) svg.replaceChildren();
    if (summaryRibbon) summaryRibbon.classList.add("is-hidden");
    setText("history-update-time", "状态：暂不可用 · 后端未就绪");
    setText("hsum-requests", "—");
    setText("hsum-tokens", "—");
    setText("hsum-cost", "—");
    setText("hsum-rate", "—");
    setText("hsum-latency", "—");
    return;
  }

  if (emptyState) emptyState.classList.add("is-hidden");
  if (summaryRibbon) summaryRibbon.classList.remove("is-hidden");

  // Dynamic Cache TTL and Staleness Check
  const cacheTtl = state.windowCacheSeconds["history_" + state.historyWindow] || 60;
  const { isStale } = checkStaleness(win.generated_at_ms, cacheTtl);

  if (win.generated_at_ms) {
    const timeStr = formatDateTime(win.generated_at_ms);
    const staleNotice = isStale ? " · 已陈旧" : "";
    setText("history-update-time", `快照时间：${timeStr} · ${cacheTtl}s 缓存${staleNotice}`);
  }

  // Render Window Summary Ribbon
  const sum = win.summary || {};
  setText("hsum-requests", formatInteger(sum.requests));
  const totalTokens = sum.tokens ? sum.tokens.total : sum.total_tokens;
  setText("hsum-tokens", formatCompactNumber(totalTokens));
  setText("hsum-cost", formatCurrency(sum.cost_usd));
  setText("hsum-rate", formatRate(sum.success_rate));
  setText("hsum-latency", formatLatency(sum.avg_latency_ms));

  // Draw Interactive SVG Chart with Strict Null Skipping
  drawSvgChart(win.points, state.historyMetric);
}

function drawSvgChart(points, metricKey) {
  const svg = $("history-svg-chart");
  if (!svg) return;

  const container = $("history-chart-container") || svg.parentElement;
  const tooltip = $("chart-tooltip");
  if (tooltip && container && tooltip.parentElement !== container) {
    container.appendChild(tooltip);
  }

  svg.replaceChildren();

  const clientWidth = container ? container.clientWidth : 0;
  const width = Math.max(480, Math.round(clientWidth || 1000));
  const height = 340;
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);

  const padLeft = 68;
  const padRight = 28;
  const padTop = 32;
  const padBottom = 44;
  const plotWidth = width - padLeft - padRight;
  const plotHeight = height - padTop - padBottom;

  // Extract values strictly preserving null (NO "|| 0" for nulls!)
  const data = points.map((p) => {
    let val = null;
    if (metricKey === "requests") {
      val = (p.requests !== null && p.requests !== undefined && Number.isFinite(Number(p.requests))) ? Number(p.requests) : null;
    } else if (metricKey === "tokens") {
      const t = (p.tokens && p.tokens.total !== undefined && p.tokens.total !== null) ? p.tokens.total : p.total_tokens;
      val = (t !== null && t !== undefined && Number.isFinite(Number(t))) ? Number(t) : null;
    } else if (metricKey === "cost") {
      val = (p.cost_usd !== null && p.cost_usd !== undefined && Number.isFinite(Number(p.cost_usd))) ? Number(p.cost_usd) : null;
    } else if (metricKey === "success_rate") {
      val = (p.success_rate !== null && p.success_rate !== undefined && Number.isFinite(Number(p.success_rate))) ? Number(p.success_rate) : null;
    } else if (metricKey === "latency") {
      val = (p.avg_latency_ms !== null && p.avg_latency_ms !== undefined && Number.isFinite(Number(p.avg_latency_ms))) ? Number(p.avg_latency_ms) : null;
    }

    const pointStamp = (p.bucket_ms !== null && p.bucket_ms !== undefined && Number.isFinite(Number(p.bucket_ms))) ? Number(p.bucket_ms) : null;
    let pointLabel = "";

    if (pointStamp) {
      const d = new Date(pointStamp);
      if (state.historyWindow === "last_24h") {
        pointLabel = beijingHourFmt.format(d);
      } else {
        pointLabel = beijingDateFmt.format(d);
      }
    } else {
      pointLabel = p.label || "";
    }

    return {
      raw: p,
      val: val,
      stamp: pointStamp,
      label: pointLabel
    };
  });

  const validVals = data.filter((d) => d.val !== null).map((d) => d.val);

  if (validVals.length === 0) {
    const emptyText = document.createElementNS("http://www.w3.org/2000/svg", "text");
    emptyText.setAttribute("x", String(width / 2));
    emptyText.setAttribute("y", String(height / 2));
    emptyText.setAttribute("text-anchor", "middle");
    emptyText.setAttribute("class", "chart-axis-text");
    emptyText.textContent = "当前时间窗口暂无有效指标数据";
    svg.appendChild(emptyText);
    return;
  }

  // Calculate Extents from valid numbers only
  let minVal = 0;
  let maxVal = Math.max(...validVals, 0);

  if (metricKey === "success_rate") {
    maxVal = 1;
    minVal = 0;
  } else if (maxVal === 0) {
    maxVal = 10;
  } else {
    maxVal = maxVal * 1.15; // 15% headroom
  }

  // Coordinate mapper
  const getX = (i) => padLeft + (data.length > 1 ? (i / (data.length - 1)) * plotWidth : plotWidth / 2);
  const getY = (val) => padTop + plotHeight - ((val - minVal) / (maxVal - minVal)) * plotHeight;

  // SVG Definitions (Gradients)
  const defs = document.createElementNS("http://www.w3.org/2000/svg", "defs");
  const gradId = "chartGradient-" + metricKey;
  const grad = document.createElementNS("http://www.w3.org/2000/svg", "linearGradient");
  grad.setAttribute("id", gradId);
  grad.setAttribute("x1", "0");
  grad.setAttribute("y1", "0");
  grad.setAttribute("x2", "0");
  grad.setAttribute("y2", "1");

  let strokeColor = "#0284c7";
  let stopColor1 = "rgba(14, 165, 233, 0.35)";
  let stopColor2 = "rgba(14, 165, 233, 0.02)";

  if (metricKey === "tokens") {
    strokeColor = "#8b5cf6";
    stopColor1 = "rgba(139, 92, 246, 0.35)";
    stopColor2 = "rgba(139, 92, 246, 0.02)";
  } else if (metricKey === "cost") {
    strokeColor = "#f59e0b";
    stopColor1 = "rgba(245, 158, 11, 0.35)";
    stopColor2 = "rgba(245, 158, 11, 0.02)";
  } else if (metricKey === "success_rate") {
    strokeColor = "#10b981";
    stopColor1 = "rgba(16, 185, 129, 0.35)";
    stopColor2 = "rgba(16, 185, 129, 0.02)";
  } else if (metricKey === "latency") {
    strokeColor = "#06b6d4";
    stopColor1 = "rgba(6, 182, 212, 0.35)";
    stopColor2 = "rgba(6, 182, 212, 0.02)";
  }

  const stop1 = document.createElementNS("http://www.w3.org/2000/svg", "stop");
  stop1.setAttribute("offset", "0%");
  stop1.setAttribute("stop-color", stopColor1);

  const stop2 = document.createElementNS("http://www.w3.org/2000/svg", "stop");
  stop2.setAttribute("offset", "100%");
  stop2.setAttribute("stop-color", stopColor2);

  grad.appendChild(stop1);
  grad.appendChild(stop2);
  defs.appendChild(grad);
  svg.appendChild(defs);

  // Background Grid Lines & Y-Labels
  const yTicks = 4;
  for (let i = 0; i <= yTicks; i++) {
    const yVal = minVal + (i / yTicks) * (maxVal - minVal);
    const yPos = getY(yVal);

    const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
    line.setAttribute("x1", String(padLeft));
    line.setAttribute("y1", String(yPos));
    line.setAttribute("x2", String(width - padRight));
    line.setAttribute("y2", String(yPos));
    line.setAttribute("class", "chart-grid-line");
    line.setAttribute("stroke-dasharray", "3 4");
    line.setAttribute("stroke-width", "1");
    svg.appendChild(line);

    // Label
    let labelText = "";
    if (metricKey === "requests") labelText = formatCompactNumber(yVal);
    else if (metricKey === "tokens") labelText = formatCompactNumber(yVal);
    else if (metricKey === "cost") labelText = formatCurrency(yVal);
    else if (metricKey === "success_rate") labelText = `${Math.round(yVal * 100)}%`;
    else if (metricKey === "latency") labelText = formatLatency(yVal);

    const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
    text.setAttribute("x", String(padLeft - 14));
    text.setAttribute("y", String(yPos + 4));
    text.setAttribute("text-anchor", "end");
    text.setAttribute("class", "chart-axis-text chart-y-axis-text");
    text.textContent = labelText;
    svg.appendChild(text);
  }

  // Draw X-axis labels
  const targetLabelCount = Math.max(3, Math.min(8, Math.floor(plotWidth / 120)));
  const step = Math.max(1, Math.floor(data.length / targetLabelCount));
  data.forEach((d, i) => {
    if (i % step === 0 || i === data.length - 1) {
      const x = getX(i);
      const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
      text.setAttribute("x", String(x));
      text.setAttribute("y", String(height - 14));
      text.setAttribute("text-anchor", "middle");
      text.setAttribute("class", "chart-axis-text chart-x-axis-text");
      text.textContent = d.label;
      svg.appendChild(text);
    }
  });

  // Construct Disconnected Segments (Breaking line across null points)
  const segments = [];
  let currentSeg = [];
  data.forEach((d, i) => {
    if (d.val !== null) {
      currentSeg.push({ ...d, index: i });
    } else {
      if (currentSeg.length > 0) {
        segments.push(currentSeg);
        currentSeg = [];
      }
    }
  });
  if (currentSeg.length > 0) {
    segments.push(currentSeg);
  }

  const baselineY = padTop + plotHeight;

  // Render each contiguous segment
  segments.forEach((seg) => {
    if (seg.length === 1) {
      // Single isolated point
      const dot = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      dot.setAttribute("cx", String(getX(seg[0].index)));
      dot.setAttribute("cy", String(getY(seg[0].val)));
      dot.setAttribute("r", "3.5");
      dot.setAttribute("fill", strokeColor);
      svg.appendChild(dot);
    } else if (seg.length > 1) {
      let lineD = `M ${getX(seg[0].index)} ${getY(seg[0].val)}`;
      for (let k = 1; k < seg.length; k++) {
        lineD += ` L ${getX(seg[k].index)} ${getY(seg[k].val)}`;
      }

      // Area Fill
      const areaD = `${lineD} L ${getX(seg[seg.length - 1].index)} ${baselineY} L ${getX(seg[0].index)} ${baselineY} Z`;
      const areaPath = document.createElementNS("http://www.w3.org/2000/svg", "path");
      areaPath.setAttribute("d", areaD);
      areaPath.setAttribute("fill", `url(#${gradId})`);
      svg.appendChild(areaPath);

      // Stroke Line
      const linePath = document.createElementNS("http://www.w3.org/2000/svg", "path");
      linePath.setAttribute("d", lineD);
      linePath.setAttribute("fill", "none");
      linePath.setAttribute("stroke", strokeColor);
      linePath.setAttribute("stroke-width", "2.5");
      linePath.setAttribute("stroke-linejoin", "round");
      linePath.setAttribute("stroke-linecap", "round");
      svg.appendChild(linePath);
    }
  });

  // Crosshair and Interactive Elements (CSP-friendly attributes)
  const crosshair = document.createElementNS("http://www.w3.org/2000/svg", "line");
  crosshair.setAttribute("y1", String(padTop));
  crosshair.setAttribute("y2", String(padTop + plotHeight));
  crosshair.setAttribute("stroke", strokeColor);
  crosshair.setAttribute("stroke-width", "1.5");
  crosshair.setAttribute("stroke-dasharray", "3 3");
  crosshair.setAttribute("opacity", "0");
  crosshair.setAttribute("class", "chart-crosshair");
  svg.appendChild(crosshair);

  const hoverDot = document.createElementNS("http://www.w3.org/2000/svg", "circle");
  hoverDot.setAttribute("r", "5");
  hoverDot.setAttribute("fill", "#ffffff");
  hoverDot.setAttribute("stroke", strokeColor);
  hoverDot.setAttribute("stroke-width", "3");
  hoverDot.setAttribute("opacity", "0");
  hoverDot.setAttribute("class", "chart-hover-dot");
  svg.appendChild(hoverDot);

  // Overlay Rect for Mouse/Touch Tracking
  const overlay = document.createElementNS("http://www.w3.org/2000/svg", "rect");
  overlay.setAttribute("x", String(padLeft));
  overlay.setAttribute("y", String(padTop));
  overlay.setAttribute("width", String(plotWidth));
  overlay.setAttribute("height", String(plotHeight));
  overlay.setAttribute("fill", "transparent");
  overlay.setAttribute("class", "chart-overlay");
  svg.appendChild(overlay);

  // Floating Tooltip container for desktop: SVG foreignObject
  let fo = $("chart-tooltip-fo");
  if (!fo) {
    fo = document.createElementNS("http://www.w3.org/2000/svg", "foreignObject");
    fo.setAttribute("id", "chart-tooltip-fo");
    fo.setAttribute("class", "chart-tooltip-fo");
    fo.setAttribute("overflow", "visible");
    fo.setAttribute("width", "250");
    fo.setAttribute("height", "130");
  }
  svg.appendChild(fo);

  function handleHover(clientX) {
    const rect = svg.getBoundingClientRect();
    const svgX = ((clientX - rect.left) / rect.width) * width;
    if (svgX < padLeft || svgX > width - padRight) {
      handleLeave();
      return;
    }

    const ratio = (svgX - padLeft) / plotWidth;
    const idx = Math.min(data.length - 1, Math.max(0, Math.round(ratio * (data.length - 1))));
    const item = data[idx];
    if (!item) return;

    const ptX = getX(idx);
    crosshair.setAttribute("x1", String(ptX));
    crosshair.setAttribute("x2", String(ptX));
    crosshair.setAttribute("opacity", "1");

    let ptY = padTop + plotHeight / 2;
    if (item.val !== null) {
      ptY = getY(item.val);
      hoverDot.setAttribute("cx", String(ptX));
      hoverDot.setAttribute("cy", String(ptY));
      hoverDot.setAttribute("opacity", "1");
    } else {
      hoverDot.setAttribute("opacity", "0");
    }

    // Tooltip Content Creation via textContent (No raw innerHTML)
    if (tooltip) {
      tooltip.replaceChildren();

      const titleEl = document.createElement("div");
      titleEl.className = "chart-tooltip-title";
      titleEl.textContent = item.label || (item.stamp ? formatDateTime(item.stamp) : "—");
      tooltip.appendChild(titleEl);

      const rowMain = document.createElement("div");
      rowMain.className = "chart-tooltip-row";

      const labelSpan = document.createElement("span");
      let valFormatted = "—";
      if (metricKey === "requests") {
        labelSpan.textContent = "总请求:";
        if (item.val !== null) valFormatted = formatInteger(item.val);
      } else if (metricKey === "tokens") {
        labelSpan.textContent = "总 Token:";
        if (item.val !== null) valFormatted = formatCompactNumber(item.val);
      } else if (metricKey === "cost") {
        labelSpan.textContent = "预估费用:";
        if (item.val !== null) valFormatted = formatCurrency(item.val);
      } else if (metricKey === "success_rate") {
        labelSpan.textContent = "成功率:";
        if (item.val !== null) valFormatted = formatRate(item.val);
      } else if (metricKey === "latency") {
        labelSpan.textContent = "平均延迟:";
        if (item.val !== null) valFormatted = formatLatency(item.val);
      }

      const valSpan = document.createElement("span");
      valSpan.className = "chart-tooltip-value";
      valSpan.textContent = valFormatted;
      rowMain.appendChild(labelSpan);
      rowMain.appendChild(valSpan);
      tooltip.appendChild(rowMain);

      // Supplementary context lines
      const raw = item.raw;
      if (item.val === null) {
        const nullRow = document.createElement("div");
        nullRow.className = "chart-tooltip-sub";
        nullRow.textContent = "该时段数据缺失或未统计";
        tooltip.appendChild(nullRow);
      } else if (metricKey === "requests") {
        const subRow = document.createElement("div");
        subRow.className = "chart-tooltip-sub";
        subRow.textContent = `成功: ${formatInteger(raw.success_requests)} · 失败: ${formatInteger(raw.failed_requests)}`;
        tooltip.appendChild(subRow);
      } else if (metricKey === "tokens" && raw.tokens) {
        const subRow = document.createElement("div");
        subRow.className = "chart-tooltip-sub";
        subRow.textContent = `入: ${formatCompactNumber(raw.tokens.input)} · 出: ${formatCompactNumber(raw.tokens.output)} · 缓存: ${formatCompactNumber(raw.tokens.cache_read)}`;
        tooltip.appendChild(subRow);
      } else if (metricKey === "latency" && raw.p95_latency_ms !== null && raw.p95_latency_ms !== undefined) {
        const subRow = document.createElement("div");
        subRow.className = "chart-tooltip-sub";
        subRow.textContent = `P95: ${formatLatency(raw.p95_latency_ms)} · TTFT: ${formatLatency(raw.p95_ttft_ms)}`;
        tooltip.appendChild(subRow);
      }

      // Responsive CSP-safe Tooltip Positioning
      const isMobile = window.innerWidth <= 768;

      if (isMobile) {
        if (tooltip.parentElement !== container) {
          container.appendChild(tooltip);
        }
        if (fo) fo.classList.remove("is-visible");

        tooltip.classList.remove("chart-tooltip-align-left", "chart-tooltip-align-right");
        if (ptX < width / 2) {
          // Left half data point -> Tooltip on top-right
          tooltip.classList.add("chart-tooltip-align-right");
        } else {
          // Right half data point -> Tooltip on top-left
          tooltip.classList.add("chart-tooltip-align-left");
        }
        tooltip.classList.add("is-visible");
      } else {
        if (tooltip.parentElement !== fo) {
          fo.appendChild(tooltip);
        }
        tooltip.classList.remove("chart-tooltip-align-left", "chart-tooltip-align-right");
        tooltip.classList.add("is-visible");
        fo.classList.add("is-visible");

        // Dynamically measure actual tooltip dimensions
        const tipRect = tooltip.getBoundingClientRect();
        const tipWidth = Math.max(130, Math.ceil(tooltip.offsetWidth || tipRect.width || 150));
        const tipHeight = Math.max(64, Math.ceil(tooltip.offsetHeight || tipRect.height || 85));

        // Desktop: horizontally centered above data point by default
        let foX = ptX - tipWidth / 2;
        let foY = ptY - tipHeight - 12;

        // If space above is insufficient (close to top boundary), place below data point
        if (foY < 8) {
          foY = ptY + 16;
        }

        // Horizontal boundary clamping:
        // 1. Left edge: Do NOT overlap Y-axis numbers (padLeft is 68). Ensure tooltip stays to the right of Y-axis.
        // 2. Right edge: Do NOT overflow chart right boundary (width - 12).
        if (foX < padLeft + 8) {
          foX = padLeft + 8;
        } else if (foX + tipWidth > width - 12) {
          foX = width - tipWidth - 12;
        }

        fo.setAttribute("x", String(Math.round(foX)));
        fo.setAttribute("y", String(Math.round(foY)));
        fo.setAttribute("width", String(Math.ceil(tipWidth + 8)));
        fo.setAttribute("height", String(Math.ceil(tipHeight + 8)));
      }
    }
  }

  function handleLeave() {
    crosshair.setAttribute("opacity", "0");
    hoverDot.setAttribute("opacity", "0");
    if (fo) fo.classList.remove("is-visible");
    if (tooltip) {
      tooltip.classList.remove("is-visible");
      tooltip.classList.remove("chart-tooltip-align-left", "chart-tooltip-align-right");
    }
  }

  overlay.addEventListener("mousemove", (e) => handleHover(e.clientX));
  overlay.addEventListener("mouseleave", handleLeave);
  overlay.addEventListener("touchstart", (e) => {
    if (e.touches.length) handleHover(e.touches[0].clientX);
  }, { passive: true });
  overlay.addEventListener("touchmove", (e) => {
    if (e.touches.length) handleHover(e.touches[0].clientX);
  }, { passive: true });
  overlay.addEventListener("touchend", handleLeave);
}

// UI Render: Breakdown & Distribution (Models & Keys)
function renderBreakdown() {
  const winLabels = { last_24h: "过去 24 小时", last_7d: "过去 7 天" };
  setText("breakdown-window-label", winLabels[state.breakdownWindow] || state.breakdownWindow);

  // Check Availability
  const metaAvail = state.dataMeta?.files?.breakdown?.available !== false;
  const winAvail = state.breakdown?.availability ? (state.breakdown.availability[state.breakdownWindow] !== false) : true;
  const hasError = Boolean(state.fetchErrors.breakdown);
  const win = state.breakdown?.windows ? state.breakdown.windows[state.breakdownWindow] : null;
  const isAvailable = metaAvail && winAvail && !hasError && win;

  // Dynamic Cache TTL and Staleness Check
  const cacheTtl = state.windowCacheSeconds["breakdown_" + state.breakdownWindow] || 120;

  if (!isAvailable) {
    setText("breakdown-update-time", "状态：暂不可用 · 后端未就绪");
  } else if (win && win.generated_at_ms) {
    const { isStale } = checkStaleness(win.generated_at_ms, cacheTtl);
    const staleNotice = isStale ? " · 已陈旧" : "";
    setText("breakdown-update-time", `快照时间：${formatDateTime(win.generated_at_ms)} · ${cacheTtl}s 缓存${staleNotice}`);
  }

  const modelsView = $("breakdown-models-view");
  const keysView = $("breakdown-keys-view");

  if (state.breakdownTab === "models") {
    if (modelsView) modelsView.classList.remove("is-hidden");
    if (keysView) keysView.classList.add("is-hidden");
    renderModelsBreakdown(isAvailable && win ? win.models : null, !isAvailable);
  } else {
    if (modelsView) modelsView.classList.add("is-hidden");
    if (keysView) keysView.classList.remove("is-hidden");
    renderKeysBreakdown(isAvailable && win ? win.api_keys : null, !isAvailable);
  }
}

const modelColDefs = {
  requests: {
    title: "请求量",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatInteger(item.requests);
      return td;
    }
  },
  tokens: {
    title: "Token 消耗",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatCompactNumber(item.tokens?.total);
      if (item.tokens) {
        td.title = `输入: ${formatInteger(item.tokens.input)} / 输出: ${formatInteger(item.tokens.output)} / 缓存读: ${formatInteger(item.tokens.cache_read)}`;
      }
      return td;
    }
  },
  cost: {
    title: "预估费用",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatCurrency(item.cost_usd);
      return td;
    }
  },
  cache_hit_rate: {
    title: "缓存命中率",
    render: (item) => {
      const td = document.createElement("td");
      td.textContent = formatRate(item.cache_hit_rate);
      return td;
    }
  }
};

const keyColDefs = {
  requests: {
    title: "请求量",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatInteger(item.requests);
      return td;
    }
  },
  tokens: {
    title: "Token 消耗",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatCompactNumber(item.tokens?.total);
      if (item.tokens) {
        td.title = `输入: ${formatInteger(item.tokens.input)} / 输出: ${formatInteger(item.tokens.output)} / 缓存读: ${formatInteger(item.tokens.cache_read)}`;
      }
      return td;
    }
  },
  cost: {
    title: "预估费用",
    render: (item) => {
      const td = document.createElement("td");
      td.className = "cell-strong";
      td.textContent = formatCurrency(item.cost_usd);
      return td;
    }
  }
};

const metricConfig = {
  requests: {
    key: "requests",
    label: "请求量",
    getValue: (item) => (item?.requests !== null && item?.requests !== undefined && Number.isFinite(Number(item.requests)) ? Number(item.requests) : null),
    formatPrimary: (val) => formatInteger(val),
    modelSecondaryCols: ["tokens", "cache_hit_rate", "cost"],
    keySecondaryCols: ["tokens", "cost"]
  },
  tokens: {
    key: "tokens",
    label: "Token 消耗",
    getValue: (item) => {
      const v = item?.tokens?.total ?? item?.total_tokens;
      return (v !== null && v !== undefined && Number.isFinite(Number(v))) ? Number(v) : null;
    },
    formatPrimary: (val) => formatCompactNumber(val),
    modelSecondaryCols: ["cache_hit_rate", "requests", "cost"],
    keySecondaryCols: ["requests", "cost"]
  },
  cost: {
    key: "cost",
    label: "预估费用",
    getValue: (item) => (item?.cost_usd !== null && item?.cost_usd !== undefined && Number.isFinite(Number(item.cost_usd)) ? Number(item.cost_usd) : null),
    formatPrimary: (val) => formatCurrency(val),
    modelSecondaryCols: ["cache_hit_rate", "requests", "tokens"],
    keySecondaryCols: ["requests", "tokens"]
  }
};

function createRateBadge(rateVal) {
  const rateBadge = document.createElement("span");
  if (rateVal !== null && rateVal !== undefined && Number.isFinite(Number(rateVal))) {
    const val = Number(rateVal);
    rateBadge.className = `status-badge ${val >= 0.95 ? "status-ok" : "status-fail"}`;
    rateBadge.textContent = formatRate(rateVal);
  } else {
    rateBadge.className = "status-badge";
    rateBadge.textContent = "—";
  }
  return rateBadge;
}

function createMetricBarCell(val, maxVal, formatter) {
  const td = document.createElement("td");
  td.className = "col-req-bar";

  if (val === null || val === undefined || !Number.isFinite(Number(val))) {
    const dash = document.createElement("span");
    dash.className = "cell-muted";
    dash.textContent = "—";
    td.appendChild(dash);
    return td;
  }

  const wrap = document.createElement("div");
  wrap.className = "metric-progress-cell";

  const numSpan = document.createElement("span");
  numSpan.className = "cell-strong";
  numSpan.textContent = formatter(val);
  wrap.appendChild(numSpan);

  const prog = document.createElement("progress");
  prog.className = "metric-progress-bar";
  prog.value = Math.max(0, val);
  prog.max = maxVal > 0 ? maxVal : 1;
  wrap.appendChild(prog);

  td.appendChild(wrap);
  return td;
}

function updateModelsTableHead(sortKey) {
  const thead = $("models-table-head");
  if (!thead) return;
  thead.replaceChildren();

  const currentMetric = metricConfig[sortKey] || metricConfig.requests;
  const tr = document.createElement("tr");
  const cols = [
    { title: "#", className: "col-rank" },
    { title: "模型名称" },
    { title: currentMetric.label, className: "col-req-bar" },
    { title: "成功率" },
    ...currentMetric.modelSecondaryCols.map((c) => ({ title: modelColDefs[c].title }))
  ];

  cols.forEach((c) => {
    const th = document.createElement("th");
    th.textContent = c.title;
    if (c.className) th.className = c.className;
    tr.appendChild(th);
  });
  thead.appendChild(tr);
}

function updateKeysTableHead(sortKey) {
  const thead = $("keys-table-head");
  if (!thead) return;
  thead.replaceChildren();

  const currentMetric = metricConfig[sortKey] || metricConfig.requests;
  const tr = document.createElement("tr");
  const cols = [
    { title: "#", className: "col-rank" },
    { title: "API KEY 备注 / 身份" },
    { title: currentMetric.label, className: "col-req-bar" },
    { title: "成功率" },
    ...currentMetric.keySecondaryCols.map((c) => ({ title: keyColDefs[c].title })),
    { title: "平均延迟" },
    { title: "最近活跃" },
    { title: "详情", className: "col-action" }
  ];

  cols.forEach((c) => {
    const th = document.createElement("th");
    th.textContent = c.title;
    if (c.className) th.className = c.className;
    tr.appendChild(th);
  });
  thead.appendChild(tr);
}

function renderModelsBreakdown(models, isUnavailable) {
  const tbody = $("breakdown-models-body");
  if (!tbody) return;
  tbody.replaceChildren();

  const sortKey = state.breakdownSort;
  updateModelsTableHead(sortKey);

  if (isUnavailable) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 7;
    td.className = "empty-cell";
    td.textContent = "⚠ 该时间窗口模型分布暂不可用 (后端未就绪或未聚合此范围)";
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  if (!Array.isArray(models) || models.length === 0) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 7;
    td.className = "empty-cell";
    td.textContent = "当前时间窗口暂无模型分布数据";
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  const currentMetric = metricConfig[sortKey] || metricConfig.requests;
  const sorted = [...models].sort((a, b) => {
    const valA = currentMetric.getValue(a);
    const valB = currentMetric.getValue(b);
    if (valA === null && valB === null) return 0;
    if (valA === null) return 1;
    if (valB === null) return -1;
    return valB - valA;
  });
  const validVals = sorted.map((m) => currentMetric.getValue(m)).filter((v) => v !== null && Number.isFinite(v));
  const maxVal = validVals.length > 0 ? Math.max(...validVals, 1) : 1;

  sorted.forEach((item, index) => {
    const tr = document.createElement("tr");

    // 1. Rank
    const tdRank = document.createElement("td");
    tdRank.className = index < 3 ? "rank-cell rank-top" : "rank-cell";
    tdRank.textContent = String(index + 1);
    tr.appendChild(tdRank);

    // 2. Model Name
    const tdModel = document.createElement("td");
    tdModel.className = "cell-strong";
    tdModel.textContent = item.model || "未知模型";
    tr.appendChild(tdModel);

    // 3. Primary Metric Bar & Value
    const tdPrimary = createMetricBarCell(currentMetric.getValue(item), maxVal, currentMetric.formatPrimary);
    tr.appendChild(tdPrimary);

    // 4. Success Rate Badge
    const tdRate = document.createElement("td");
    tdRate.appendChild(createRateBadge(item.success_rate));
    tr.appendChild(tdRate);

    // 5, 6, 7. Secondary Columns according to metricConfig
    currentMetric.modelSecondaryCols.forEach((colKey) => {
      tr.appendChild(modelColDefs[colKey].render(item));
    });

    tbody.appendChild(tr);
  });
}

function renderKeysBreakdown(keys, isUnavailable) {
  const tbody = $("breakdown-keys-body");
  if (!tbody) return;
  tbody.replaceChildren();

  const sortKey = state.breakdownSort;
  updateKeysTableHead(sortKey);

  if (isUnavailable) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 9;
    td.className = "empty-cell";
    td.textContent = "⚠ 该时间窗口 API KEY 分布暂不可用 (后端未就绪或未聚合此范围)";
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  if (!Array.isArray(keys) || keys.length === 0) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 9;
    td.className = "empty-cell";
    td.textContent = "当前时间窗口暂无 API KEY 统计数据";
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  const currentMetric = metricConfig[sortKey] || metricConfig.requests;
  const sorted = [...keys].sort((a, b) => {
    const valA = currentMetric.getValue(a);
    const valB = currentMetric.getValue(b);
    if (valA === null && valB === null) return 0;
    if (valA === null) return 1;
    if (valB === null) return -1;
    return valB - valA;
  });
  const validVals = sorted.map((k) => currentMetric.getValue(k)).filter((v) => v !== null && Number.isFinite(v));
  const maxVal = validVals.length > 0 ? Math.max(...validVals, 1) : 1;

  sorted.forEach((item, index) => {
    const apiKey = item.api_key || {};
    const keyId = apiKey.id || `k_${index}`;
    const isExpanded = state.breakdownExpandedKeyId === keyId;

    const tr = document.createElement("tr");

    // 1. Rank
    const tdRank = document.createElement("td");
    tdRank.className = index < 3 ? "rank-cell rank-top" : "rank-cell";
    tdRank.textContent = String(index + 1);
    tr.appendChild(tdRank);

    // 2. Key Identity Pill
    const tdKey = document.createElement("td");
    const keyWrap = document.createElement("div");
    keyWrap.className = "key-identity-wrap";

    const displaySpan = document.createElement("span");
    displaySpan.className = "key-name";
    displaySpan.textContent = apiKey.display || apiKey.id || "未知 API Key";
    keyWrap.appendChild(displaySpan);

    if (apiKey.kind === "alias") {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-alias";
      tag.textContent = "别名";
      keyWrap.appendChild(tag);
    } else if (apiKey.kind === "masked") {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-masked";
      tag.textContent = "脱敏";
      keyWrap.appendChild(tag);
    } else if (apiKey.kind) {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-anon";
      tag.textContent = "匿名";
      keyWrap.appendChild(tag);
    }
    tdKey.appendChild(keyWrap);

    if (apiKey.id && apiKey.display && apiKey.id !== apiKey.display) {
      const idSpan = document.createElement("div");
      idSpan.className = "key-subid";
      idSpan.textContent = apiKey.id;
      tdKey.appendChild(idSpan);
    }
    tr.appendChild(tdKey);

    // 3. Primary Metric Bar & Value
    const tdPrimary = createMetricBarCell(currentMetric.getValue(item), maxVal, currentMetric.formatPrimary);
    tr.appendChild(tdPrimary);

    // 4. Success Rate Badge
    const tdRate = document.createElement("td");
    tdRate.appendChild(createRateBadge(item.success_rate));
    tr.appendChild(tdRate);

    // 5, 6. Secondary Columns according to metricConfig
    currentMetric.keySecondaryCols.forEach((colKey) => {
      tr.appendChild(keyColDefs[colKey].render(item));
    });

    // 7. Avg Latency
    const tdLatency = document.createElement("td");
    tdLatency.textContent = formatLatency(item.avg_latency_ms);
    tr.appendChild(tdLatency);

    // 8. Last Seen
    const tdSeen = document.createElement("td");
    tdSeen.className = "cell-muted";
    tdSeen.textContent = item.last_seen_ms ? formatTime(item.last_seen_ms) : "—";
    tr.appendChild(tdSeen);

    // 9. Details Drill-down Toggle Button
    const tdAction = document.createElement("td");
    tdAction.className = "cell-center";
    const hasModels = Array.isArray(item.models) && item.models.length > 0;
    if (hasModels) {
      const btnToggle = document.createElement("button");
      btnToggle.type = "button";
      btnToggle.className = "btn-expand-toggle icon-only" + (isExpanded ? " is-expanded" : "");
      btnToggle.title = isExpanded ? "收起模型明细" : "展开模型明细";
      btnToggle.setAttribute("aria-label", isExpanded ? "收起模型明细" : "展开模型明细");
      btnToggle.appendChild(createChevronIcon());
      btnToggle.addEventListener("click", () => {
        state.breakdownExpandedKeyId = isExpanded ? null : keyId;
        renderKeysBreakdown(keys, false);
      });
      tdAction.appendChild(btnToggle);
    } else {
      tdAction.textContent = "—";
      tdAction.className = "cell-center cell-muted";
    }
    tr.appendChild(tdAction);

    tbody.appendChild(tr);

    // Expanded Row: Model details for this API Key
    if (isExpanded && hasModels) {
      const detailTr = document.createElement("tr");
      detailTr.className = "row-detail";
      const detailTd = document.createElement("td");
      detailTd.colSpan = 9;
      detailTd.className = "row-detail-container";

      const innerWrap = document.createElement("div");
      innerWrap.className = "subtable-wrap";

      const title = document.createElement("span");
      title.className = "subtable-title";
      title.textContent = `↳ 该 Key 所调用的模型明细 (${item.models.length} 个模型):`;
      innerWrap.appendChild(title);

      const subTable = document.createElement("table");
      subTable.className = "status-table subtable-grid";

      const sthead = document.createElement("thead");
      const sthRow = document.createElement("tr");
      ["模型名称", "调用请求", "成功率", "Token 消耗", "费用", "最近调用"].forEach((h) => {
        const th = document.createElement("th");
        th.textContent = h;
        sthRow.appendChild(th);
      });
      sthead.appendChild(sthRow);
      subTable.appendChild(sthead);

      const stbody = document.createElement("tbody");
      item.models.forEach((m) => {
        const sr = document.createElement("tr");
        [
          String(m.model || "unknown"),
          formatInteger(m.requests),
          formatRate(m.success_rate),
          formatCompactNumber(m.total_tokens),
          formatCurrency(m.cost_usd),
          m.last_seen_ms ? formatTime(m.last_seen_ms) : "—"
        ].forEach((txt, idx) => {
          const sc = document.createElement("td");
          sc.textContent = txt;
          if (idx === 0) sc.className = "cell-strong";
          sr.appendChild(sc);
        });
        stbody.appendChild(sr);
      });
      subTable.appendChild(stbody);
      innerWrap.appendChild(subTable);
      detailTd.appendChild(innerWrap);
      detailTr.appendChild(detailTd);
      tbody.appendChild(detailTr);
    }
  });
}

// UI Render: Recent Calls (calls.json)
function renderRecentCalls() {
  const tbody = $("calls-table-body");
  if (!tbody) return;
  tbody.replaceChildren();

  // Check Availability
  const callsAvail = (state.dataMeta?.files?.calls?.available !== false) && !state.fetchErrors.calls;
  if (!callsAvail || !state.calls) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 8;
    td.className = "empty-cell";
    td.textContent = "⚠ 最近调用记录暂不可用 (后端未就绪或已禁用)";
    tr.appendChild(td);
    tbody.appendChild(tr);
    setText("calls-update-time", "最新更新：暂不可用");
    updateCallsPagination(0, 0, 0);
    return;
  }

  const items = state.calls.items || [];

  // Search filter
  const query = (state.callsSearch || "").trim().toLowerCase();
  let filtered = items.filter((item) => {
    if (query) {
      const model = (item.model || "").toLowerCase();
      const apiKey = item.api_key || {};
      const display = (apiKey.display || "").toLowerCase();
      const id = (apiKey.id || "").toLowerCase();
      const effort = (typeof item.reasoning_effort === "string" ? item.reasoning_effort.trim() : "").toLowerCase();
      const effortLabel = effort ? `思考 · ${effort}` : "";
      if (!model.includes(query) && !display.includes(query) && !id.includes(query) && !effort.includes(query) && !effortLabel.includes(query)) {
        return false;
      }
    }

    const status = item.status || {};
    if (state.callsFilter === "ok") return status.ok === true;
    if (state.callsFilter === "failed") return status.ok === false;
    if (state.callsFilter === "429") return status.code === 429;

    return true;
  });

  const totalFiltered = filtered.length;
  const badge = $("calls-count-badge");
  if (badge) {
    badge.textContent = `共 ${totalFiltered} 条记录`;
  }

  if (state.calls.generated_at_ms) {
    setText("calls-update-time", `最近数据变更：${formatDateTime(state.calls.generated_at_ms)} · ${state.refreshSeconds.calls}s 轮询`);
  }

  if (totalFiltered === 0) {
    const tr = document.createElement("tr");
    const td = document.createElement("td");
    td.colSpan = 8;
    td.className = "empty-cell";
    td.textContent = "暂无符合筛选条件的调用记录";
    tr.appendChild(td);
    tbody.appendChild(tr);
    updateCallsPagination(0, 0, 0);
    return;
  }

  // Pagination slice
  const pageSize = state.callsPageSize;
  const totalPages = Math.ceil(totalFiltered / pageSize) || 1;
  if (state.callsPage > totalPages) state.callsPage = totalPages;
  if (state.callsPage < 1) state.callsPage = 1;

  const startIndex = (state.callsPage - 1) * pageSize;
  const pagedItems = filtered.slice(startIndex, startIndex + pageSize);

  pagedItems.forEach((call, index) => {
    const tr = document.createElement("tr");
    const apiKey = call.api_key || {};
    const keyId = apiKey.id || `k_${index}`;
    const callUid = `${call.timestamp_ms}_${keyId}_${call.model}`;
    const isExpanded = state.callsExpandedId === callUid;

    // 1. Timestamp
    const tdTime = document.createElement("td");
    tdTime.className = "cell-muted";
    tdTime.textContent = formatTime(call.timestamp_ms);
    tdTime.title = formatDateTime(call.timestamp_ms);
    tr.appendChild(tdTime);

    // 2. API Key
    const tdKey = document.createElement("td");
    const keyInfo = call.api_key || {};
    const keyWrap = document.createElement("div");
    keyWrap.className = "key-identity-wrap";

    const displaySpan = document.createElement("span");
    displaySpan.className = "key-name";
    displaySpan.textContent = keyInfo.display || keyInfo.id || "未知 Key";
    keyWrap.appendChild(displaySpan);

    if (keyInfo.kind === "alias") {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-alias";
      tag.textContent = "别名";
      keyWrap.appendChild(tag);
    } else if (keyInfo.kind === "masked") {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-masked";
      tag.textContent = "脱敏";
      keyWrap.appendChild(tag);
    } else if (keyInfo.kind) {
      const tag = document.createElement("span");
      tag.className = "key-tag key-tag-anon";
      tag.textContent = "匿名";
      keyWrap.appendChild(tag);
    }
    tdKey.appendChild(keyWrap);

    if (keyInfo.id && keyInfo.display && keyInfo.id !== keyInfo.display) {
      const idSpan = document.createElement("div");
      idSpan.className = "key-id-sub";
      idSpan.textContent = keyInfo.id;
      tdKey.appendChild(idSpan);
    }
    tr.appendChild(tdKey);

    // 3. Model
    const tdModel = document.createElement("td");
    tdModel.className = "call-model-cell";

    const modelWrap = document.createElement("div");
    modelWrap.className = "call-model-wrap";

    const modelName = document.createElement("div");
    modelName.className = "call-model-name";
    modelName.textContent = call.model || "—";
    modelWrap.appendChild(modelName);

    const effort = (typeof call.reasoning_effort === "string" ? call.reasoning_effort.trim() : "");
    if (effort) {
      const modelEffort = document.createElement("div");
      modelEffort.className = "call-model-effort";
      modelEffort.textContent = `思考 · ${effort.toLowerCase()}`;
      modelWrap.appendChild(modelEffort);
    }

    tdModel.appendChild(modelWrap);
    tr.appendChild(tdModel);

    // 4. Status Badge
    const tdStatus = document.createElement("td");
    const statusObj = call.status || {};
    const badge = document.createElement("span");

    if (statusObj.ok) {
      badge.className = "status-badge status-ok";
      badge.textContent = "成功";
    } else if (statusObj.code === 429) {
      badge.className = "status-badge status-429";
      badge.textContent = "HTTP 429";
    } else if (statusObj.code && statusObj.code >= 500) {
      badge.className = "status-badge status-5xx";
      badge.textContent = `HTTP ${statusObj.code}`;
    } else {
      badge.className = "status-badge status-fail";
      badge.textContent = statusObj.label || (statusObj.code ? `HTTP ${statusObj.code}` : "失败");
    }
    tdStatus.appendChild(badge);
    tr.appendChild(tdStatus);

    // 5. Total Tokens
    const tdTokens = document.createElement("td");
    const totalTokens = (call.tokens && call.tokens.total !== undefined) ? call.tokens.total : null;
    tdTokens.textContent = formatCompactNumber(totalTokens);
    if (call.tokens) {
      tdTokens.title = `输入: ${formatInteger(call.tokens.input)} / 输出: ${formatInteger(call.tokens.output)} / 缓存读: ${formatInteger(call.tokens.cache_read)}`;
    }
    tr.appendChild(tdTokens);

    // 6. Latency
    const tdLatency = document.createElement("td");
    tdLatency.textContent = formatLatency(call.latency_ms);
    tr.appendChild(tdLatency);

    // 7. TTFT
    const tdTtft = document.createElement("td");
    tdTtft.textContent = formatLatency(call.ttft_ms);
    tr.appendChild(tdTtft);

    // 8. Expand Action
    const tdExpand = document.createElement("td");
    tdExpand.className = "cell-center";
    const btnExp = document.createElement("button");
    btnExp.type = "button";
    btnExp.className = "btn-expand-toggle icon-only" + (isExpanded ? " is-expanded" : "");
    btnExp.title = isExpanded ? "收起详情" : "展开详情";
    btnExp.setAttribute("aria-label", isExpanded ? "收起详情" : "展开详情");
    btnExp.appendChild(createChevronIcon());
    btnExp.addEventListener("click", () => {
      state.callsExpandedId = isExpanded ? null : callUid;
      renderRecentCalls();
    });
    tdExpand.appendChild(btnExp);
    tr.appendChild(tdExpand);

    tbody.appendChild(tr);

    // Expanded Card Detail Row
    if (isExpanded) {
      const detailTr = document.createElement("tr");
      detailTr.className = "row-detail";
      const detailTd = document.createElement("td");
      detailTd.colSpan = 8;
      detailTd.className = "row-detail-container";

      const grid = document.createElement("div");
      grid.className = "call-detail-card";

      const detailItems = [
        { label: "完整时间（北京时间）", val: formatDateTime(call.timestamp_ms) },
        { label: "API KEY 身份", val: apiKey.display ? `${apiKey.display} (${apiKey.id || "ID: 无"})` : (apiKey.id || "—") },
        { label: "模型名称", val: call.model || "—" }
      ];

      const effortVal = (typeof call.reasoning_effort === "string" ? call.reasoning_effort.trim() : "");
      if (effortVal) {
        detailItems.push({ label: "思考强度", val: `思考 · ${effortVal.toLowerCase()}` });
      }

      detailItems.push(
        { label: "状态代码", val: statusObj.code ? `HTTP ${statusObj.code}` : (statusObj.ok ? "HTTP 200" : "—") },
        { label: "输入 Token", val: formatInteger(call.tokens?.input) },
        { label: "输出 Token", val: formatInteger(call.tokens?.output) },
        { label: "Cache Read", val: formatInteger(call.tokens?.cache_read) },
        { label: "总 Token 消耗", val: formatInteger(call.tokens?.total) },
        { label: "端到端总延迟", val: formatLatency(call.latency_ms) },
        { label: "首字生成时间 (TTFT)", val: formatLatency(call.ttft_ms) }
      );

      detailItems.forEach((d) => {
        const box = document.createElement("div");
        box.className = "detail-stat-item";
        const lbl = document.createElement("span");
        lbl.className = "detail-stat-label";
        lbl.textContent = d.label;
        const val = document.createElement("strong");
        val.className = "detail-stat-val";
        val.textContent = d.val;
        box.appendChild(lbl);
        box.appendChild(val);
        grid.appendChild(box);
      });

      detailTd.appendChild(grid);
      detailTr.appendChild(detailTd);
      tbody.appendChild(detailTr);
    }
  });

  updateCallsPagination(state.callsPage, totalPages, totalFiltered);
}

// Pagination Controls Updater
function updateCallsPagination(current, total, count) {
  const info = $("calls-pagination-info");
  if (info) {
    info.textContent = `第 ${current} / ${total} 页 · 共 ${count} 条记录`;
  }
  const btnPrev = $("calls-page-prev");
  if (btnPrev) {
    btnPrev.disabled = current <= 1;
  }
  const btnNext = $("calls-page-next");
  if (btnNext) {
    btnNext.disabled = current >= total;
  }
}

// Global & Sidecars Status Indicators
function updateGlobalStatus() {
  const dot = $("global-status-dot");
  const text = $("global-status-text");
  const time = $("global-status-time");

  // 1. Check Snapshot (Core critical)
  const snapAvail = state.dataMeta?.files?.snapshot?.available !== false;
  const snapErr = Boolean(state.fetchErrors.snapshot || !state.snapshot || !snapAvail);

  if (snapErr) {
    if (dot) dot.className = "status-pulse-dot bad";
    if (text) text.textContent = "快照连接中断";
    setText("hero-snapshot-time", "--:--:--");
    setText("hero-snapshot-iso", "");
    updateDataLayerTag();
    return;
  }

  const generatedUnix = Number(state.snapshot.generated_unix || 0) * 1000;
  const snapStale = checkStaleness(generatedUnix, state.refreshSeconds.snapshot).isStale;

  if (state.snapshot.generated_at || state.snapshot.generated_unix) {
    const d = new Date(state.snapshot.generated_at || Number(state.snapshot.generated_unix) * 1000);
    const timeStr = beijingTimeFmt.format(d);
    if (time) time.textContent = `快照: ${timeStr}`;
    setText("hero-snapshot-time", timeStr);
    const dateStr = beijingDateYMDFmt.format(d).replace(/\//g, "-");
    setText("hero-snapshot-iso", `(${dateStr})`);
  }

  updateDataLayerTag();

  if (state.refreshSeconds.snapshot) {
    setText("hero-refresh-interval", `${state.refreshSeconds.snapshot} 秒`);
  }

  // 2. Check Sidecars Availability
  const callsAvail = (state.dataMeta?.files?.calls?.available !== false) && !state.fetchErrors.calls;

  let historyAvail = (state.dataMeta?.files?.history?.available !== false) && !state.fetchErrors.history;
  if (historyAvail && state.history?.availability) {
    if (Object.values(state.history.availability).some((v) => v === false)) {
      historyAvail = false;
    }
  }

  let breakdownAvail = (state.dataMeta?.files?.breakdown?.available !== false) && !state.fetchErrors.breakdown;
  if (breakdownAvail && state.breakdown?.availability) {
    if (Object.values(state.breakdown.availability).some((v) => v === false)) {
      breakdownAvail = false;
    }
  }

  const allTimeAvail = state.snapshot.all_time_available === true;
  const allTimeStale = state.snapshot.all_time_stale === true;

  // 3. Check Staleness of sidecars
  const callsStale = state.lastFetched.calls > 0
    ? checkStaleness(state.lastFetched.calls, state.refreshSeconds.calls).isStale
    : false;
  const historyTtl = state.windowCacheSeconds["history_" + state.historyWindow] || 60;
  const historyStale = state.history ? checkStaleness(state.history.windows?.[state.historyWindow]?.generated_at_ms, historyTtl).isStale : false;
  const breakdownTtl = state.windowCacheSeconds["breakdown_" + state.breakdownWindow] || 120;
  const breakdownStale = state.breakdown ? checkStaleness(state.breakdown.windows?.[state.breakdownWindow]?.generated_at_ms, breakdownTtl).isStale : false;

  const anyPartialUnavail = !callsAvail || !historyAvail || !breakdownAvail || !allTimeAvail;
  const anyStale = snapStale || callsStale || historyStale || breakdownStale || allTimeStale;

  if (dot && text) {
    dot.className = "status-pulse-dot";
    if (anyPartialUnavail) {
      dot.classList.add("warn");
      text.textContent = "部分数据暂不可用";
    } else if (anyStale) {
      dot.classList.add("stale");
      text.textContent = "数据已陈旧 (显示缓存快照)";
    } else {
      dot.classList.add("ok");
      text.textContent = "数据层运行正常";
    }
  }
}

function updateSidecarsStatus() {
  const check = (key, elemId, refreshId, metaFileKey) => {
    const item = $(elemId);
    if (!item) return;
    const dot = item.querySelector(".sidecar-dot");
    const refCode = $(refreshId);

    const refreshSec = state.refreshSeconds[key] || 10;
    if (refCode) {
      refCode.textContent = `${refreshSec}s`;
    }

    if (dot) {
      dot.className = "sidecar-dot";
      const hasError = Boolean(state.fetchErrors[key]);
      const isMetaAvail = state.dataMeta?.files?.[metaFileKey]?.available !== false;

      let isWindowAvail = true;
      if (key === "history" && state.history?.availability) {
        isWindowAvail = Object.values(state.history.availability).every((v) => v !== false);
      } else if (key === "breakdown" && state.breakdown?.availability) {
        isWindowAvail = Object.values(state.breakdown.availability).every((v) => v !== false);
      } else if (key === "snapshot") {
        isWindowAvail = state.snapshot?.all_time_available !== false;
      }

      let isStale = false;
      if (key === "snapshot" && state.snapshot?.generated_unix) {
        isStale = checkStaleness(state.snapshot.generated_unix * 1000, refreshSec).isStale
          || state.snapshot?.all_time_stale === true;
      } else if (key === "calls" && state.lastFetched.calls > 0) {
        isStale = checkStaleness(state.lastFetched.calls, refreshSec).isStale;
      } else if (key === "history" && state.history?.generated_at_ms) {
        isStale = checkStaleness(state.history.generated_at_ms, 60).isStale;
      } else if (key === "breakdown" && state.breakdown?.generated_at_ms) {
        isStale = checkStaleness(state.breakdown.generated_at_ms, 120).isStale;
      }

      if (hasError) {
        dot.classList.add("bad");
      } else if (!isMetaAvail || !isWindowAvail) {
        dot.classList.add("warn");
      } else if (isStale) {
        dot.classList.add("stale");
      } else if (state.lastFetched[key] > 0) {
        dot.classList.add("ok");
      } else {
        dot.classList.add("warn");
      }
    }
  };

  check("snapshot", "sidecar-snapshot", "sidecar-snapshot-refresh", "snapshot");
  check("calls", "sidecar-calls", "sidecar-calls-refresh", "calls");
  check("history", "sidecar-history", "sidecar-history-refresh", "history");
  check("breakdown", "sidecar-breakdown", "sidecar-breakdown-refresh", "breakdown");
  check("meta", "sidecar-meta", null, null);
}

// Re-render when number format toggled
function rerenderFormattedNumbers() {
  renderTodayCards();
  renderAllTime();
  renderHistory();
  renderBreakdown();
  renderRecentCalls();
}

// Global Poller & Event Listeners
function setupEventListeners() {
  // 1. Format Switcher
  const btnIntl = $("btn-format-intl");
  const btnCn = $("btn-format-cn");

  const updateFormatButtons = () => {
    if (state.numFormat === "intl") {
      btnIntl.classList.add("active");
      btnCn.classList.remove("active");
    } else {
      btnCn.classList.add("active");
      btnIntl.classList.remove("active");
    }
  };
  updateFormatButtons();

  btnIntl.addEventListener("click", () => {
    if (state.numFormat !== "intl") {
      state.numFormat = "intl";
      safeSetStorage("cpa_num_format", "intl");
      updateFormatButtons();
      rerenderFormattedNumbers();
    }
  });

  btnCn.addEventListener("click", () => {
    if (state.numFormat !== "cn") {
      state.numFormat = "cn";
      safeSetStorage("cpa_num_format", "cn");
      updateFormatButtons();
      rerenderFormattedNumbers();
    }
  });

  // 2. Manual Refresh
  const btnRefresh = $("btn-manual-refresh");
  if (btnRefresh) {
    btnRefresh.addEventListener("click", async () => {
      btnRefresh.disabled = true;
      setText("refresh-countdown-text", "同步中");
      await Promise.allSettled([
        loadSnapshot(),
        loadCalls(),
        loadHistory(),
        loadBreakdown(),
        loadAccountQuota()
      ]);
      updateQuotaCountdowns();
      state.nextRefreshIn = state.refreshSeconds.snapshot;
      setText("hero-countdown-val", `${state.nextRefreshIn} 秒`);
      setText("refresh-countdown-text", "已同步");
      setTimeout(() => {
        btnRefresh.disabled = false;
        setText("refresh-countdown-text", "同步");
      }, 1000);
    });
  }

  // 3. History Window Selector
  document.querySelectorAll("[data-history-win]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-history-win]").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.historyWindow = btn.getAttribute("data-history-win");
      renderHistory();
    });
  });

  // 4. History Metric Selector
  document.querySelectorAll("[data-history-metric]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-history-metric]").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.historyMetric = btn.getAttribute("data-history-metric");
      renderHistory();
    });
  });

  // 5. Breakdown Tab Selector
  const btnTabModels = $("btn-tab-models");
  const btnTabKeys = $("btn-tab-keys");
  if (btnTabModels && btnTabKeys) {
    btnTabModels.addEventListener("click", () => {
      btnTabModels.classList.add("active");
      btnTabKeys.classList.remove("active");
      state.breakdownTab = "models";
      renderBreakdown();
    });
    btnTabKeys.addEventListener("click", () => {
      btnTabKeys.classList.add("active");
      btnTabModels.classList.remove("active");
      state.breakdownTab = "keys";
      renderBreakdown();
    });
  }

  // 6. Breakdown Window Selector
  document.querySelectorAll("[data-breakdown-win]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-breakdown-win]").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.breakdownWindow = btn.getAttribute("data-breakdown-win");
      renderBreakdown();
    });
  });

  // 7. Breakdown Sort Selector
  document.querySelectorAll("[data-breakdown-sort]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-breakdown-sort]").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.breakdownSort = btn.getAttribute("data-breakdown-sort");
      renderBreakdown();
    });
  });

  // 8. Recent Calls Search Input
  const searchInput = $("calls-search-input");
  if (searchInput) {
    searchInput.addEventListener("input", (e) => {
      state.callsSearch = e.target.value;
      state.callsPage = 1;
      renderRecentCalls();
    });
  }

  // 9. Recent Calls Filter Segment
  document.querySelectorAll("[data-calls-filter]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-calls-filter]").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.callsFilter = btn.getAttribute("data-calls-filter");
      state.callsPage = 1;
      renderRecentCalls();
    });
  });

  // 10. Recent Calls Pagination Buttons
  const btnPrev = $("calls-page-prev");
  const btnNext = $("calls-page-next");
  if (btnPrev) {
    btnPrev.addEventListener("click", () => {
      if (state.callsPage > 1) {
        state.callsPage--;
        renderRecentCalls();
      }
    });
  }
  if (btnNext) {
    btnNext.addEventListener("click", () => {
      state.callsPage++;
      renderRecentCalls();
    });
  }

  // 11. Chart Auto Resize
  if (window.ResizeObserver) {
    const chartContainer = $("history-chart-container");
    if (chartContainer) {
      let resizeTimer = null;
      const ro = new ResizeObserver(() => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => {
          if (state.history && state.history.windows) {
            const win = state.history.windows[state.historyWindow];
            if (win && Array.isArray(win.points) && win.points.length > 0) {
              drawSvgChart(win.points, state.historyMetric);
            }
          }
        }, 60);
      });
      ro.observe(chartContainer);
    }
  } else {
    window.addEventListener("resize", () => {
      if (state.history && state.history.windows) {
        const win = state.history.windows[state.historyWindow];
        if (win && Array.isArray(win.points) && win.points.length > 0) {
          drawSvgChart(win.points, state.historyMetric);
        }
      }
    });
  }
}

// Independent Polling Scheduler
const BACKGROUND_REFRESH_SECONDS = Object.freeze({
  snapshot: 60,
  calls: 60,
  history: 300,
  breakdown: 600,
  quota: 120,
  meta: 600
});

function effectiveRefreshSeconds(key) {
  const base = Math.max(1, Number(state.refreshSeconds[key] || 10));
  if (!document.hidden) return base;
  return Math.max(base, Number(BACKGROUND_REFRESH_SECONDS[key] || base));
}

function refreshVisibleDataNow() {
  if (document.hidden) return;
  state.nextRefreshIn = state.refreshSeconds.snapshot;
  setText("hero-countdown-val", `${state.nextRefreshIn} 秒`);
  Promise.allSettled([
    loadMeta(),
    loadSnapshot(),
    loadCalls(),
    loadHistory(),
    loadBreakdown(),
    loadAccountQuota()
  ]);
}

function startSchedulers() {
  state.nextRefreshIn = state.refreshSeconds.snapshot;
  setText("hero-countdown-val", `${state.nextRefreshIn} 秒`);

  let elapsedSec = 0;
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) refreshVisibleDataNow();
  });

  window.setInterval(() => {
    elapsedSec++;

    // Ticker countdown reflects foreground snapshot cadence.
    if (!document.hidden) {
      if (state.nextRefreshIn > 0) {
        state.nextRefreshIn--;
      } else {
        state.nextRefreshIn = state.refreshSeconds.snapshot;
      }
      setText("hero-countdown-val", `${state.nextRefreshIn} 秒`);
    }

    // Periodic staleness check for live badges
    if (elapsedSec % 5 === 0) {
      updateGlobalStatus();
      updateSidecarsStatus();
    }

    // Foreground keeps the original cadence; background tabs are throttled.
    if (elapsedSec % effectiveRefreshSeconds("snapshot") === 0) loadSnapshot();
    if (elapsedSec % effectiveRefreshSeconds("calls") === 0) loadCalls();
    if (elapsedSec % effectiveRefreshSeconds("history") === 0) loadHistory();
    if (elapsedSec % effectiveRefreshSeconds("breakdown") === 0) loadBreakdown();
    if (elapsedSec % effectiveRefreshSeconds("meta") === 0) loadMeta();
    if (elapsedSec % effectiveRefreshSeconds("quota") === 0) loadAccountQuota();
    if (elapsedSec % 10 === 0) updateQuotaCountdowns();
  }, 1000);
}

// Application Initialization Entry Point
async function init() {
  initTimeReference();
  setupEventListeners();

  // Initial concurrent load
  await loadMeta();
  await Promise.allSettled([
    loadSnapshot(),
    loadCalls(),
    loadHistory(),
    loadBreakdown(),
    loadAccountQuota()
  ]);

  startSchedulers();
}

document.addEventListener("DOMContentLoaded", init, { once: true });
CPA229_JS_EOF

    cat > "${target_dir}/meta.json" <<EOF
{"schema_version":1,"refresh_seconds":$((10#$interval))}
EOF

    chmod 0644 "${target_dir}/index.html" "${target_dir}/app.css" \
        "${target_dir}/app.js" "${target_dir}/meta.json"
}

public_status_refresh_live_assets() {
    local interval stage_dir backup_dir file rc=0

    [[ -d "$PUBLIC_STATUS_WEB_ROOT" ]] || return 0
    interval=$(public_status_interval)
    [[ "$interval" =~ ^[0-9]+$ ]] || interval=10
    stage_dir=$(mktemp -d /tmp/cpamp-public-assets.XXXXXX) || return 1
    backup_dir="${stage_dir}/backup"
    mkdir -p "$backup_dir" || { rm -rf -- "$stage_dir"; return 1; }

    public_status_stage_assets "${stage_dir}/new" "$interval" || {
        rm -rf -- "$stage_dir"
        return 1
    }

    for file in index.html app.css app.js meta.json; do
        [[ -f "${PUBLIC_STATUS_WEB_ROOT}/${file}" ]] && cp -a -- "${PUBLIC_STATUS_WEB_ROOT}/${file}" "${backup_dir}/${file}" || true
        if ! install -m 0644 -o root -g root "${stage_dir}/new/${file}" "${PUBLIC_STATUS_WEB_ROOT}/.${file}.v229" \
            || ! mv -f -- "${PUBLIC_STATUS_WEB_ROOT}/.${file}.v229" "${PUBLIC_STATUS_WEB_ROOT}/${file}"; then
            rc=1
            break
        fi
    done

    if [[ "$rc" != "0" ]]; then
        for file in index.html app.css app.js meta.json; do
            rm -f -- "${PUBLIC_STATUS_WEB_ROOT}/.${file}.v229"
            if [[ -f "${backup_dir}/${file}" ]]; then
                cp -a -- "${backup_dir}/${file}" "${PUBLIC_STATUS_WEB_ROOT}/${file}" || true
            fi
        done
        rm -rf -- "$stage_dir"
        return 1
    fi

    rm -rf -- "$stage_dir"
    info "已同步 v${SCRIPT_VERSION} Public Status 前端资源（无需 reload Caddy）。"
    return 0
}

PUBLIC_STATUS_LAST_HTTP_CODE=""
PUBLIC_STATUS_LAST_FETCH_ERROR=""

# v2.29: obsolete pre-Rich sanitizer removed; canonical sanitizer is defined below.
public_status_fetch_dashboard() {
    local output_file="$1" work_dir="$2"
    local admin_key origin header_file body_file err_file path url http_code curl_rc

    PUBLIC_STATUS_LAST_HTTP_CODE=""
    PUBLIC_STATUS_LAST_FETCH_ERROR=""

    systemctl is-active --quiet "$CPAMP_SERVICE" || {
        PUBLIC_STATUS_LAST_FETCH_ERROR="${CPAMP_SERVICE} 当前不是 active 状态"
        return 1
    }
    admin_key=$(cpamp_admin_key)
    if [[ -z "$admin_key" ]]; then
        PUBLIC_STATUS_LAST_FETCH_ERROR="未找到可用的 CPAMP Admin Key"
        return 1
    fi
    origin=$(cpamp_http_origin)
    header_file="${work_dir}/auth.headers"
    body_file="${work_dir}/dashboard.json"
    err_file="${work_dir}/curl.err"
    if ! printf 'Authorization: Bearer %s\nAccept: application/json\n' "$admin_key" > "$header_file" \
        || ! chmod 0600 "$header_file"; then
        PUBLIC_STATUS_LAST_FETCH_ERROR="无法创建私有认证头文件"
        unset admin_key
        return 1
    fi

    for path in \
        '/v0/management/dashboard/summary' \
        '/v0/management/dashboard/summary?range=30d' \
        "$(public_status_dashboard_summary_path)"; do
        url="${origin}${path}"
        : > "$body_file"
        : > "$err_file"
        http_code=$(curl -sS --noproxy '*' --max-time 12 --connect-timeout 3 \
            --max-filesize 16777216 -o "$body_file" -w '%{http_code}' \
            --header "@${header_file}" "$url" 2>"$err_file")
        curl_rc=$?
        PUBLIC_STATUS_LAST_HTTP_CODE="${http_code:-000}"
        if [[ "$curl_rc" != "0" ]]; then
            PUBLIC_STATUS_LAST_FETCH_ERROR="连接 CPAMP Dashboard 失败（curl ${curl_rc}）"
            continue
        fi
        if [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
            PUBLIC_STATUS_LAST_FETCH_ERROR="CPAMP Admin Key 认证失败（HTTP ${http_code}）"
            unset admin_key
            return 2
        fi
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]] \
            && jq -e . "$body_file" >/dev/null 2>&1 \
            && jq -e '
                (if (.data | type) == "object" then .data
                 elif (.result | type) == "object" then .result
                 else . end) as $r
                | ($r | type) == "object"
                and (
                    ($r | has("rolling_30m")) or ($r | has("rolling30m"))
                    or ($r | has("rolling_24h")) or ($r | has("today"))
                    or ($r | has("all_time")) or ($r | has("top_models"))
                    or ($r | has("windows")) or ($r | has("summary"))
                    or ($r | has("totals"))
                )
            ' "$body_file" >/dev/null 2>&1; then
            cp -- "$body_file" "$output_file"
            chmod 0600 "$output_file" || { unset admin_key; return 1; }
            printf '%s' "$admin_key" > "${work_dir}/admin-key.check"
            chmod 0600 "${work_dir}/admin-key.check" || true
            unset admin_key
            return 0
        fi
        PUBLIC_STATUS_LAST_FETCH_ERROR="Dashboard 接口 ${path} 返回 HTTP ${http_code:-000} 或未知 JSON 结构"
    done

    unset admin_key
    if [[ -s "$err_file" ]]; then
        PUBLIC_STATUS_LAST_FETCH_ERROR+="：$(head -n 1 "$err_file" | tr -d '\r\n')"
    fi
    return 1
}

public_status_record_error() {
    local message="$1" tmp_file

    install -d -m 0755 -o root -g root "$PUBLIC_STATUS_DIR" >/dev/null 2>&1 || return 0
    tmp_file=$(mktemp "${PUBLIC_STATUS_LAST_ERROR}.XXXXXX") || return 0
    {
        printf 'time=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'message=%s\n' "${message//$'\n'/ }"
        [[ -n "$PUBLIC_STATUS_LAST_HTTP_CODE" ]] \
            && printf 'http=%s\n' "$PUBLIC_STATUS_LAST_HTTP_CODE"
    } > "$tmp_file"
    chown root:root "$tmp_file" >/dev/null 2>&1 || true
    chmod 0600 "$tmp_file" >/dev/null 2>&1 || true
    mv -f "$tmp_file" "$PUBLIC_STATUS_LAST_ERROR" >/dev/null 2>&1 || rm -f "$tmp_file"
}

# v2.29: obsolete base-only snapshot implementation removed.
# BEGIN v2.26 PUBLIC STATUS SUMMARY+DETAILS
# Scope: Public Status data adapter only. No Caddy/CN/timer/CPA/CPAMP/sing-box changes.
public_status_fetch_recent_details() {
    local events_file="$1" aliases_file="$2" work_dir="$3"
    local origin header_file now_ms from_ms request_file http_code curl_rc=0

    printf '{"events":{"items":[]}}\n' > "$events_file"
    printf '[]\n' > "$aliases_file"
    header_file="${work_dir}/auth.headers"
    [[ -s "$header_file" ]] || return 0
    origin=$(cpamp_http_origin)
    now_ms=$(( $(date +%s) * 1000 ))
    from_ms=$(( now_ms - 86400000 ))
    request_file="${work_dir}/monitoring.request.json"

    jq -n --argjson from "$from_ms" --argjson to "$now_ms" '{
      from_ms:$from,
      to_ms:$to,
      now_ms:$to,
      include:{events_page:{limit:100}}
    }' > "$request_file" || return 0

    http_code=$(curl -sS --noproxy '*' --max-time 12 --connect-timeout 3 \
        --max-filesize 8388608 -o "${work_dir}/monitoring.json" -w '%{http_code}' \
        --header "@${header_file}" -H 'Content-Type: application/json' \
        --data-binary "@${request_file}" \
        "${origin}/v0/management/monitoring/analytics" 2>/dev/null) || curl_rc=$?
    if [[ "$curl_rc" == "0" && "$http_code" =~ ^2[0-9][0-9]$ ]] \
        && jq -e '((.events.items // .data.events.items // []) | type) == "array"' \
            "${work_dir}/monitoring.json" >/dev/null 2>&1; then
        cp -- "${work_dir}/monitoring.json" "$events_file" || true
    else
        warn "最近调用明细暂不可用（Monitoring HTTP ${http_code:-000}）；主快照仍会正常生成。"
    fi

    curl_rc=0
    http_code=$(curl -sS --noproxy '*' --max-time 8 --connect-timeout 3 \
        --max-filesize 2097152 -o "${work_dir}/aliases.json" -w '%{http_code}' \
        --header "@${header_file}" \
        "${origin}/v0/management/api-key-aliases" 2>/dev/null) || curl_rc=$?
    if [[ "$curl_rc" == "0" && "$http_code" =~ ^2[0-9][0-9]$ ]] \
        && jq -e '
          if type == "array" then true
          elif (.items | type) == "array" then true
          elif (.data | type) == "array" then true
          else false end
        ' "${work_dir}/aliases.json" >/dev/null 2>&1; then
        cp -- "${work_dir}/aliases.json" "$aliases_file" || true
    else
        warn "API Key 备注暂不可用（aliases HTTP ${http_code:-000}）；将使用安全脱敏标识。"
    fi
    return 0
}

public_status_sanitize_payload() {
    local input_file="$1" output_file="$2" admin_key="${3:-}"
    local events_file="${4:-}" aliases_file="${5:-}"
    local empty_events empty_aliases

    empty_events=$(mktemp) || return 1
    empty_aliases=$(mktemp) || { rm -f "$empty_events"; return 1; }
    printf '{"events":{"items":[]}}\n' > "$empty_events"
    printf '[]\n' > "$empty_aliases"
    [[ -s "$events_file" ]] || events_file="$empty_events"
    [[ -s "$aliases_file" ]] || aliases_file="$empty_aliases"

    if ! jq -n \
        --slurpfile dash "$input_file" \
        --slurpfile events "$events_file" \
        --slurpfile aliases "$aliases_file" '
      def root($x):
        if (($x.data // null) | type) == "object" then $x.data
        elif (($x.result // null) | type) == "object" then $x.result
        else $x end;
      def n($x): if ($x | type) == "number" then $x else null end;
      def nullable_n($x): if ($x | type) == "number" then $x else null end;
      def clean_text($x; $max):
        if ($x | type) == "string" then
          ($x | explode | map(select(. >= 32 and . != 127)) | implode | .[0:$max])
        else "" end;
      def alias_array($x):
        if ($x | type) == "array" then $x
        elif (($x.items // null) | type) == "array" then $x.items
        elif (($x.data // null) | type) == "array" then $x.data
        else [] end;
      def event_array($x):
        if (($x.events.items // null) | type) == "array" then $x.events.items
        elif (($x.data.events.items // null) | type) == "array" then $x.data.events.items
        else [] end;
      def aliases: alias_array($aliases[0]);
      def alias_for($hash):
        ([aliases[]? |
          select((.apiKeyHash // .api_key_hash // "") == $hash) |
          clean_text((.alias // ""); 80) |
          select(length > 0) |
          select((test("^(?i:(?:sk|key|token|api)[-_][A-Za-z0-9_.-]{16,})$") and (test("\\*|\\.\\.\\.") | not)) | not)] | first) // "";
      def safe_mask($source; $hash):
        (clean_text($source; 120)) as $s |
        if (($s | test("\\*|\\.\\.\\.")) and ($s | length) <= 120) then
          ($s | sub("^m:"; "") | gsub("\\.\\.\\."; "******") | .[0:80])
        else "未备注 Key" end;
      def key_display($e):
        ($e.api_key_hash // "") as $h |
        (alias_for($h)) as $a |
        if ($a | length) > 0 then $a else safe_mask(($e.source // ""); $h) end;

      def reasoning_effort($x):
        (clean_text($x; 16) | ascii_downcase) as $v |
        if (["none","minimal","low","medium","high","xhigh","max"] | index($v)) != null
        then $v else null end;

      (root($dash[0])) as $r |
      (event_array($events[0])) as $ev |
      {
        schema_version: 1,
        generated_at: (now | todateiso8601),
        generated_unix: (now | floor),
        source: "cpamp-dashboard-summary",
        cpamp_version: clean_text(($r.cpamp_version // $r.version // ""); 32),
        rolling_30m: {
          requests: n($r.rolling_30m.total_calls),
          success_requests: null,
          failed_requests: null,
          success_rate: null,
          total_tokens: n($r.rolling_30m.total_tokens),
          rpm: n($r.rolling_30m.rpm),
          tpm: n($r.rolling_30m.tpm)
        },
        rolling_24h: null,
        today: {
          requests: n($r.today.total_calls),
          success_requests: n($r.today.success_calls),
          failed_requests: n($r.today.failure_calls),
          success_rate: n($r.today.success_rate),
          input_tokens: n($r.today.input_tokens),
          output_tokens: n($r.today.output_tokens),
          cache_tokens: n($r.today.cached_tokens),
          total_tokens: n($r.today.total_tokens),
          cost_usd: n($r.today.total_cost),
          avg_latency_ms: nullable_n($r.today.average_latency_ms),
          p50_latency_ms: null,
          p95_latency_ms: null
        },
        all_time: null,
        all_time_available: false,
        top_models: [
          $r.top_models_today[]? | {
            model: clean_text((.model // "unknown"); 160),
            requests: n(.calls),
            total_tokens: n(.tokens),
            cost_usd: n(.cost),
            success_rate: n(.success_rate)
          }
        ][0:20],
        hourly: [
          $r.traffic_timeline[]? | {
            timestamp_ms: n(.bucket_ms),
            label: clean_text((.bucket_label // ""); 64),
            requests: n(.calls),
            total_tokens: n(.tokens),
            success_requests: n(.success),
            failed_requests: n(.failure),
            failure_rate: n(.failure_rate)
          }
        ][-24:],
        daily: [],
        recent_calls: [
          $ev[]? | {
            timestamp_ms: n(.timestamp_ms),
            api_key: key_display(.),
            model: clean_text((.analytics_model // .resolved_model // .model // .requested_model // "unknown"); 160),
            reasoning_effort: reasoning_effort(.reasoning_effort),
            status: (if (.failed == true) then
                       (if ((.fail_status_code // null) | type) == "number"
                        then "HTTP " + (.fail_status_code | tostring)
                        else "失败" end)
                     else "成功" end),
            failed: (.failed == true),
            total_tokens: n(.total_tokens),
            latency_ms: nullable_n(.latency_ms)
          }
        ][0:20]
      }
    ' > "$output_file"; then
        rm -f "$empty_events" "$empty_aliases" "$output_file"
        error "Public Status 脱敏转换失败。"
        return 1
    fi
    rm -f "$empty_events" "$empty_aliases"

    if [[ -n "$admin_key" ]] \
        && grep -Fq -f <(printf '%s\n' "$admin_key") "$output_file"; then
        rm -f "$output_file"
        error "安全检查失败：脱敏快照意外包含 Admin Key。"
        return 1
    fi
    if jq -e '
      .. | objects |
      keys[]? |
      select(. == "api_key_hash" or . == "source_hash" or
             . == "endpoint" or . == "path" or . == "client_ip" or
             . == "account_snapshot" or . == "auth_file_snapshot" or
             . == "fail_summary")
    ' "$output_file" | grep -q .; then
        rm -f "$output_file"
        error "安全检查失败：脱敏快照含有禁止字段。"
        return 1
    fi
    if ! jq -e '
      .schema_version == 1 and
      ((.today.requests == null) or ((.today.requests | type) == "number")) and
      (.top_models | type) == "array" and
      (.hourly | type) == "array" and
      (.recent_calls | type) == "array" and
      ([.recent_calls[]? | keys_unsorted - ["timestamp_ms","api_key","model","reasoning_effort","status","failed","total_tokens","latency_ms"]] | all(length == 0))
    ' "$output_file" >/dev/null 2>&1; then
        rm -f "$output_file"
        error "安全检查失败：Public Status 快照结构不符合白名单。"
        return 1
    fi
    if (( $(wc -c < "$output_file") > 4194304 )); then
        rm -f "$output_file"
        error "脱敏快照超过 4 MiB，已拒绝发布。"
        return 1
    fi
    chmod 0600 "$output_file" || return 1
    return 0
}

public_status_preserve_stale_all_time() {
    local clean_file="$1" merge_tmp

    [[ -s "$PUBLIC_STATUS_SNAPSHOT" ]] || return 0
    jq -e '.all_time_available == true and (.all_time | type) == "object"' \
        "$PUBLIC_STATUS_SNAPSHOT" >/dev/null 2>&1 || return 0
    merge_tmp="${clean_file}.all-time.${BASHPID}"
    if ! jq --slurpfile old "$PUBLIC_STATUS_SNAPSHOT" '
        if .all_time_available == true then .
        else
          .all_time = $old[0].all_time
          | .all_time_available = true
          | .all_time_stale = true
          | .all_time_generated_at_ms = ($old[0].all_time_generated_at_ms // null)
        end
    ' "$clean_file" > "$merge_tmp"; then
        rm -f "$merge_tmp"
        return 1
    fi
    chmod 0600 "$merge_tmp" || { rm -f "$merge_tmp"; return 1; }
    mv -f "$merge_tmp" "$clean_file"
}


# BEGIN v2.27 PUBLIC STATUS RICH DATA LAYER
# Frontend-agnostic sanitized static data sidecars.
public_status_build_rich_data() {
    local clean_file="$1" events_file="$2" aliases_file="$3" work_dir="$4"
    local db_path origin interval

    [[ -x "$PUBLIC_STATUS_RICH_HELPER" ]] || return 1
    background_capacity_available "Public Status 富数据层" "$BACKGROUND_MIN_AVAILABLE_MIB" || return 1
    db_path=$(cpamp_database_path)
    [[ -n "$db_path" && -r "$db_path" ]] || return 1
    origin=$(cpamp_http_origin)
    [[ -n "$origin" ]] || return 1
    interval=$(public_status_interval)
    [[ -s "${work_dir}/auth.headers" ]] || return 1

    install -d -m 0700 -o root -g root "${PUBLIC_STATUS_DIR}/rich-cache" >/dev/null 2>&1 || return 1

    if ! flock -n "$BACKGROUND_HEAVY_LOCK" python3 "$PUBLIC_STATUS_RICH_HELPER" \
        --base-snapshot "$clean_file" \
        --events "$events_file" \
        --aliases "$aliases_file" \
        --auth-header-file "${work_dir}/auth.headers" \
        --origin "$origin" \
        --db-path "$db_path" \
        --public-dir "$PUBLIC_STATUS_WEB_ROOT" \
        --private-dir "$PUBLIC_STATUS_DIR" \
        --quota-config "$PUBLIC_STATUS_QUOTA_CONFIG" \
        --snapshot-refresh-seconds "$interval"; then
        warn "Public Status 富数据层未取得重任务锁或生成失败。"
        return 1
    fi
}
# END v2.27 PUBLIC STATUS RICH DATA LAYER

public_status_snapshot() {
    local lock_fd tmp_dir raw_file clean_file key_file publish_tmp base_publish_tmp rc=0 rich_ok=0
    local events_file aliases_file admin_key_check=""

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] \
        || { error "未配置 Public Status。"; return 1; }
    install -d -m 0755 -o root -g root "$PUBLIC_STATUS_DIR" "$PUBLIC_STATUS_WEB_ROOT" \
        "$(dirname "$PUBLIC_STATUS_SNAPSHOT_LOCK")" || return 1
    exec {lock_fd}>"$PUBLIC_STATUS_SNAPSHOT_LOCK" || return 1
    if ! flock -n "$lock_fd"; then
        warn "已有快照任务正在运行，本次跳过。"
        exec {lock_fd}>&-
        return 0
    fi

    if ! background_capacity_available "Public Status 快照" "$BACKGROUND_MIN_AVAILABLE_MIB"; then
        info "保留上一份成功快照，本轮不访问 CPAMP。"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 0
    fi

    tmp_dir=$(mktemp -d "${PUBLIC_STATUS_DIR}/.snapshot.XXXXXX") || {
        exec {lock_fd}>&-
        return 1
    }
    chmod 0700 "$tmp_dir" || true
    raw_file="${tmp_dir}/raw.json"
    clean_file="${tmp_dir}/clean.json"
    key_file="${tmp_dir}/admin-key.check"
    events_file="${tmp_dir}/events.json"
    aliases_file="${tmp_dir}/aliases.public-source.json"

    public_status_fetch_dashboard "$raw_file" "$tmp_dir"
    rc=$?
    if [[ "$rc" != "0" ]]; then
        public_status_record_error "${PUBLIC_STATUS_LAST_FETCH_ERROR:-无法读取 CPAMP Dashboard}"
        error "${PUBLIC_STATUS_LAST_FETCH_ERROR:-无法读取 CPAMP Dashboard}；旧快照保持不变。"
        rm -rf -- "$tmp_dir"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return "$rc"
    fi

    # Optional: details/aliases never block the aggregate snapshot.
    public_status_fetch_recent_details "$events_file" "$aliases_file" "$tmp_dir" || true
    admin_key_check=$(cat "$key_file" 2>/dev/null || true)
    if ! public_status_sanitize_payload "$raw_file" "$clean_file" "$admin_key_check" \
        "$events_file" "$aliases_file"; then
        unset admin_key_check
        public_status_record_error "Dashboard 脱敏或结构校验失败"
        rm -rf -- "$tmp_dir"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    fi
    unset admin_key_check

    if ! public_status_preserve_stale_all_time "$clean_file"; then
        warn "无法合并上一份全历史统计；本轮仍继续生成新快照。"
    fi

    # Publish the sanitized base snapshot before optional database/API enrichment.
    # Under pressure the public status page stays current even when rich data is skipped.
    base_publish_tmp="${PUBLIC_STATUS_WEB_ROOT}/.snapshot.base.${BASHPID}"
    if ! install -m 0644 -o root -g root "$clean_file" "$base_publish_tmp" \
        || ! mv -f "$base_publish_tmp" "$PUBLIC_STATUS_SNAPSHOT"; then
        rm -f "$base_publish_tmp"
        public_status_record_error "原子发布基础 snapshot.json 失败"
        rm -rf -- "$tmp_dir"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    fi

    if public_status_build_rich_data "$clean_file" "$events_file" "$aliases_file" "$tmp_dir"; then
        rich_ok=1
    else
        warn "Public Status 富数据层本轮生成失败；继续发布基础脱敏快照，并保留已有 sidecar。"
    fi

    if [[ "$rich_ok" == "1" ]]; then
        publish_tmp="${PUBLIC_STATUS_WEB_ROOT}/.snapshot.json.${BASHPID}"
        if ! install -m 0644 -o root -g root "$clean_file" "$publish_tmp" \
            || ! mv -f "$publish_tmp" "$PUBLIC_STATUS_SNAPSHOT"; then
            rm -f "$publish_tmp"
            public_status_record_error "原子发布富数据 snapshot.json 失败"
            rm -rf -- "$tmp_dir"
            flock -u "$lock_fd" >/dev/null 2>&1 || true
            exec {lock_fd}>&-
            return 1
        fi
    fi

    rm -f "$PUBLIC_STATUS_LAST_ERROR"
    rm -rf -- "$tmp_dir"
    flock -u "$lock_fd" >/dev/null 2>&1 || true
    exec {lock_fd}>&-
    return 0
}
# END v2.26 PUBLIC STATUS SUMMARY+DETAILS


public_status_emit_remote_ip_routes() {
    local prefix="$1" file="$2"
    local network values="" chunk_index=0 chunk_size=0 total=0 matcher

    while IFS= read -r network || [[ -n "$network" ]]; do
        [[ -n "$network" ]] || continue
        values+=" ${network}"
        chunk_size=$((chunk_size + 1))
        total=$((total + 1))
        if (( chunk_size >= 200 )); then
            chunk_index=$((chunk_index + 1))
            printf -v matcher '%s_%03d' "$prefix" "$chunk_index"
            printf '    @%s remote_ip%s\n' "$matcher" "$values"
            printf '    handle @%s {\n        import cpamp_public_static_v225\n    }\n' "$matcher"
            values=""
            chunk_size=0
        fi
    done < "$file"
    if (( chunk_size > 0 )); then
        chunk_index=$((chunk_index + 1))
        printf -v matcher '%s_%03d' "$prefix" "$chunk_index"
        printf '    @%s remote_ip%s\n' "$matcher" "$values"
        printf '    handle @%s {\n        import cpamp_public_static_v225\n    }\n' "$matcher"
    fi
    (( total > 0 ))
}

public_status_generate_caddy_file() {
    local output_file="$1" domain="$2" cn4_file="$3" cn6_file="$4" custom_file="$5"
    local extra_file tmp_dir network normalized write_rc

    [[ -s "$cn4_file" && -s "$cn6_file" ]] || return 1
    tmp_dir=$(mktemp -d /tmp/cpamp-public-caddy.XXXXXX) || return 1
    extra_file="${tmp_dir}/extra.txt"
    printf '127.0.0.1/32\n::1/128\n' > "$extra_file"
    if [[ -f "$custom_file" ]]; then
        while IFS= read -r network || [[ -n "$network" ]]; do
            network="${network%%#*}"
            network="${network//[[:space:]]/}"
            [[ -n "$network" ]] || continue
            normalized=$(public_status_normalize_ip_or_cidr "$network") || {
                error "额外白名单包含无效或过宽网段：${network}"
                rm -rf -- "$tmp_dir"
                return 1
            }
            printf '%s\n' "$normalized" >> "$extra_file"
        done < "$custom_file"
    fi
    sort -u -o "$extra_file" "$extra_file" || { rm -rf -- "$tmp_dir"; return 1; }

    {
        printf '# Managed by cpa-deploy.sh %s - Public Status\n' "$SCRIPT_VERSION"
        cat <<EOF
(cpamp_public_static_v225) {
    root * ${PUBLIC_STATUS_WEB_ROOT}
    encode zstd gzip
    header Cache-Control "no-cache"
    header {
        -Server
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "no-referrer"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        Content-Security-Policy "default-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'; object-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:"
    }
    file_server
}

${domain} {
EOF
        public_status_emit_remote_ip_routes allowed_cn4 "$cn4_file" || return 74
        public_status_emit_remote_ip_routes allowed_cn6 "$cn6_file" || return 75
        public_status_emit_remote_ip_routes allowed_extra "$extra_file" || return 76
        cat <<EOF

    handle {
        respond 404
    }

    log {
        output file ${PUBLIC_STATUS_STATUS_LOG} {
            roll_size 5MiB
            roll_keep 10
            roll_keep_for 720h
        }
        format json
    }
}
EOF
    } > "$output_file"
    write_rc=$?
    rm -rf -- "$tmp_dir"
    [[ "$write_rc" == "0" ]] || return 1
    chmod 0600 "$output_file" || return 1
    return 0
}

public_status_reload_caddy() {
    if caddy reload --config "$CADDY_CONFIG_FILE" --adapter caddyfile; then
        return 0
    fi
    if systemctl reload caddy; then
        return 0
    fi
    error "caddy reload 与 systemctl reload caddy 均失败。"
    return 1
}

public_status_apply_caddy_locked() {
    local domain candidate stage_main backup_dir had_main=0 had_site=0
    local restore_ok=1

    domain=$(public_status_domain)
    [[ -n "$domain" ]] || { error "未配置 Status 域名。"; return 1; }
    [[ -f "$CADDY_CONFIG_FILE" ]] \
        || { error "未找到 ${CADDY_CONFIG_FILE}，请先完成 CPA+Caddy 部署。"; return 1; }
    [[ -s "$PUBLIC_STATUS_CN4" && -s "$PUBLIC_STATUS_CN6" ]] \
        || { error "CN IPv4/IPv6 白名单不完整，拒绝开放 Status。"; return 1; }
    public_status_check_domain_collision "$domain" || return 1
    systemctl is-active --quiet caddy \
        || { error "caddy.service 当前未运行，拒绝修改在线配置。"; return 1; }

    install -d -m 0755 -o root -g root "$PUBLIC_STATUS_CADDY_DIR" \
        || return 1
    install -d -m 0750 -o caddy -g caddy "$CADDY_LOG_DIR" \
        || return 1
    candidate=$(mktemp /tmp/cpamp-public-site.XXXXXX) || return 1
    stage_main=$(mktemp "${CADDY_CONFIG_FILE}.public-new.XXXXXX") || {
        rm -f "$candidate"
        return 1
    }
    backup_dir=$(mktemp -d /tmp/cpamp-public-caddy-backup.XXXXXX) || {
        rm -f "$candidate" "$stage_main"
        return 1
    }

    public_status_generate_caddy_file "$candidate" "$domain" \
        "$PUBLIC_STATUS_CN4" "$PUBLIC_STATUS_CN6" "$PUBLIC_STATUS_CUSTOM_ALLOW" \
        || { rm -rf -- "$backup_dir"; rm -f "$candidate" "$stage_main"; return 1; }

    cp -a "$CADDY_CONFIG_FILE" "${backup_dir}/Caddyfile" || {
        rm -rf -- "$backup_dir"; rm -f "$candidate" "$stage_main"; return 1;
    }
    had_main=1
    cp -a "$CADDY_CONFIG_FILE" "$stage_main" || {
        rm -rf -- "$backup_dir"; rm -f "$candidate" "$stage_main"; return 1;
    }
    if ! grep -Fqx "$PUBLIC_STATUS_CADDY_IMPORT" "$stage_main"; then
        printf '\n%s\n' "$PUBLIC_STATUS_CADDY_IMPORT" >> "$stage_main" || {
            rm -rf -- "$backup_dir"; rm -f "$candidate" "$stage_main"; return 1;
        }
    fi
    if [[ -e "$PUBLIC_STATUS_CADDY_FILE" ]]; then
        had_site=1
        cp -a "$PUBLIC_STATUS_CADDY_FILE" "${backup_dir}/cpamp-public.caddy" || {
            rm -rf -- "$backup_dir"; rm -f "$candidate" "$stage_main"; return 1;
        }
    fi

    if ! install -m 0644 -o root -g root "$candidate" "$PUBLIC_STATUS_CADDY_FILE" \
        || ! caddy validate --config "$stage_main" --adapter caddyfile; then
        error "Public Status Caddy 候选配置验证失败，正在恢复文件。"
        if [[ "$had_site" == "1" ]]; then
            cp -a "${backup_dir}/cpamp-public.caddy" "$PUBLIC_STATUS_CADDY_FILE" || restore_ok=0
        else
            rm -f "$PUBLIC_STATUS_CADDY_FILE" || restore_ok=0
        fi
        rm -rf -- "$backup_dir"
        rm -f "$candidate" "$stage_main"
        [[ "$restore_ok" == "1" ]] || error "Caddy 配置文件恢复不完整。"
        return 1
    fi

    if ! chown root:root "$stage_main" \
        || ! chmod 0644 "$stage_main" \
        || ! mv -f "$stage_main" "$CADDY_CONFIG_FILE" \
        || ! public_status_reload_caddy; then
        error "应用 Public Status Caddy 配置失败，正在回滚。"
        [[ "$had_main" == "1" ]] \
            && cp -a "${backup_dir}/Caddyfile" "$CADDY_CONFIG_FILE" || restore_ok=0
        if [[ "$had_site" == "1" ]]; then
            cp -a "${backup_dir}/cpamp-public.caddy" "$PUBLIC_STATUS_CADDY_FILE" || restore_ok=0
        else
            rm -f "$PUBLIC_STATUS_CADDY_FILE" || restore_ok=0
        fi
        if ! caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
            || ! public_status_reload_caddy; then
            restore_ok=0
        fi
        rm -rf -- "$backup_dir"
        rm -f "$candidate" "$stage_main"
        [[ "$restore_ok" == "1" ]] || error "Caddy 回滚不完整，请立即执行 caddy validate 并检查 journalctl -u caddy。"
        return 1
    fi

    rm -rf -- "$backup_dir"
    rm -f "$candidate" "$stage_main"
    return 0
}

public_status_remove_caddy_locked() {
    local backup_file="" restore_ok=1

    [[ -f "$CADDY_CONFIG_FILE" ]] || return 0
    if [[ ! -e "$PUBLIC_STATUS_CADDY_FILE" ]]; then
        return 0
    fi
    backup_file=$(mktemp /tmp/cpamp-public-site-backup.XXXXXX) || return 1
    cp -a "$PUBLIC_STATUS_CADDY_FILE" "$backup_file" || { rm -f "$backup_file"; return 1; }
    rm -f "$PUBLIC_STATUS_CADDY_FILE" || { rm -f "$backup_file"; return 1; }

    if ! caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
        || ! public_status_reload_caddy; then
        error "移除 Status 站点后 Caddy 校验或 reload 失败，正在恢复。"
        cp -a "$backup_file" "$PUBLIC_STATUS_CADDY_FILE" || restore_ok=0
        if ! caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
            || ! public_status_reload_caddy; then
            restore_ok=0
        fi
        rm -f "$backup_file"
        [[ "$restore_ok" == "1" ]] || error "Caddy 回滚不完整。"
        return 1
    fi
    rm -f "$backup_file"
    return 0
}

public_status_stage_units() {
    local target_dir="$1" interval="$2"

    mkdir -p "$target_dir" || return 1
    cat > "${target_dir}/${PUBLIC_STATUS_SERVICE}" <<EOF
[Unit]
Description=Generate sanitized static CPAMP public snapshot
After=cpamp.service
ConditionPathExists=${PUBLIC_STATUS_CONFIG}

[Service]
Type=oneshot
ExecStart=${INSTALL_PATH} public-status --snapshot-direct
TimeoutStartSec=240
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadWritePaths=${PUBLIC_STATUS_DIR} /run/lock
EOF

    cat > "${target_dir}/${PUBLIC_STATUS_TIMER}" <<EOF
[Unit]
Description=Refresh sanitized CPAMP public snapshot every ${interval} seconds

[Timer]
OnBootSec=25s
OnUnitActiveSec=${interval}s
AccuracySec=1s
Unit=${PUBLIC_STATUS_SERVICE}
Persistent=false

[Install]
WantedBy=timers.target
EOF

    cat > "${target_dir}/${PUBLIC_STATUS_CN_SERVICE}" <<EOF
[Unit]
Description=Update CN IP allowlist for CPAMP public status
After=network-online.target caddy.service
Wants=network-online.target
ConditionPathExists=${PUBLIC_STATUS_CONFIG}

[Service]
Type=oneshot
ExecStart=${INSTALL_PATH} public-status --update-cn-direct
TimeoutStartSec=180
Nice=15
IOSchedulingClass=idle
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadWritePaths=${PUBLIC_STATUS_CONFIG_DIR} ${PUBLIC_STATUS_DIR} /etc/caddy ${CADDY_LOG_DIR} /run/lock
EOF

    cat > "${target_dir}/${PUBLIC_STATUS_CN_TIMER}" <<EOF
[Unit]
Description=Daily CN IP allowlist update for CPAMP public status

[Timer]
OnCalendar=*-*-* 05:37:00
AccuracySec=5min
RandomizedDelaySec=30min
Persistent=true
Unit=${PUBLIC_STATUS_CN_SERVICE}

[Install]
WantedBy=timers.target
EOF

    local quota_interval
    quota_interval=$(public_status_quota_interval_minutes)
    cat > "${target_dir}/${PUBLIC_STATUS_QUOTA_SERVICE}" <<EOF
[Unit]
Description=Refresh GPT Team quota through local CPA management API
After=cpa.service cpamp.service network-online.target
Wants=network-online.target
ConditionPathExists=${PUBLIC_STATUS_CONFIG}

[Service]
Type=oneshot
ExecStart=${INSTALL_PATH} public-status --quota-refresh-direct
SuccessExitStatus=10
TimeoutStartSec=420
Nice=15
IOSchedulingClass=best-effort
IOSchedulingPriority=7
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadWritePaths=${PUBLIC_STATUS_DIR} /run/lock
EOF

    cat > "${target_dir}/${PUBLIC_STATUS_QUOTA_TIMER}" <<EOF
[Unit]
Description=Periodic GPT Team quota refresh (about every ${quota_interval} minutes)

[Timer]
OnActiveSec=${quota_interval}min
OnUnitInactiveSec=${quota_interval}min
AccuracySec=1min
RandomizedDelaySec=5min
Persistent=false
Unit=${PUBLIC_STATUS_QUOTA_SERVICE}

[Install]
WantedBy=timers.target
EOF

    chmod 0644 "${target_dir}/${PUBLIC_STATUS_SERVICE}" "${target_dir}/${PUBLIC_STATUS_TIMER}" \
        "${target_dir}/${PUBLIC_STATUS_CN_SERVICE}" "${target_dir}/${PUBLIC_STATUS_CN_TIMER}" \
        "${target_dir}/${PUBLIC_STATUS_QUOTA_SERVICE}" "${target_dir}/${PUBLIC_STATUS_QUOTA_TIMER}"
}

public_status_transaction_backup() {
    local backup_dir="$1" path relative
    local -a paths=(
        "$PUBLIC_STATUS_CONFIG_DIR"
        "$PUBLIC_STATUS_DIR"
        "$PUBLIC_STATUS_SERVICE_FILE"
        "$PUBLIC_STATUS_TIMER_FILE"
        "$PUBLIC_STATUS_CN_SERVICE_FILE"
        "$PUBLIC_STATUS_CN_TIMER_FILE"
        "$PUBLIC_STATUS_QUOTA_SERVICE_FILE"
        "$PUBLIC_STATUS_QUOTA_TIMER_FILE"
        "$PUBLIC_STATUS_CADDY_FILE"
        "$CADDY_CONFIG_FILE"
    )

    mkdir -p "${backup_dir}/root" || return 1
    : > "${backup_dir}/present"
    for path in "${paths[@]}"; do
        if [[ -e "$path" || -L "$path" ]]; then
            relative="${path#/}"
            printf '%s\n' "$path" >> "${backup_dir}/present"
            mkdir -p "${backup_dir}/root/$(dirname "$relative")" || return 1
            cp -a -- "$path" "${backup_dir}/root/${relative}" || return 1
        fi
    done
    for path in "$PUBLIC_STATUS_TIMER" "$PUBLIC_STATUS_CN_TIMER" "$PUBLIC_STATUS_QUOTA_TIMER"; do
        printf '%s\t%s\t%s\n' "$path" \
            "$(systemctl is-enabled "$path" 2>/dev/null || true)" \
            "$(systemctl is-active "$path" 2>/dev/null || true)" \
            >> "${backup_dir}/units.state"
    done
}

public_status_transaction_restore() {
    local backup_dir="$1" path relative unit enabled active restore_ok=1
    local -a paths=(
        "$PUBLIC_STATUS_CONFIG_DIR"
        "$PUBLIC_STATUS_DIR"
        "$PUBLIC_STATUS_SERVICE_FILE"
        "$PUBLIC_STATUS_TIMER_FILE"
        "$PUBLIC_STATUS_CN_SERVICE_FILE"
        "$PUBLIC_STATUS_CN_TIMER_FILE"
        "$PUBLIC_STATUS_QUOTA_SERVICE_FILE"
        "$PUBLIC_STATUS_QUOTA_TIMER_FILE"
        "$PUBLIC_STATUS_CADDY_FILE"
        "$CADDY_CONFIG_FILE"
    )

    systemctl disable --now "$PUBLIC_STATUS_TIMER" "$PUBLIC_STATUS_CN_TIMER" "$PUBLIC_STATUS_QUOTA_TIMER" \
        >/dev/null 2>&1 || true
    for path in "${paths[@]}"; do
        rm -rf -- "$path" || restore_ok=0
    done
    if [[ -f "${backup_dir}/present" ]]; then
        while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            relative="${path#/}"
            mkdir -p "$(dirname "$path")" || restore_ok=0
            cp -a -- "${backup_dir}/root/${relative}" "$path" || restore_ok=0
        done < "${backup_dir}/present"
    fi
    systemctl daemon-reload || restore_ok=0

    if [[ -f "${backup_dir}/units.state" ]]; then
        while IFS=$'\t' read -r unit enabled active; do
            [[ -n "$unit" ]] || continue
            if [[ "$enabled" == "enabled" ]]; then
                systemctl enable "$unit" >/dev/null 2>&1 || restore_ok=0
            else
                systemctl disable "$unit" >/dev/null 2>&1 || true
            fi
            if [[ "$active" == "active" ]]; then
                systemctl start "$unit" >/dev/null 2>&1 || restore_ok=0
            else
                systemctl stop "$unit" >/dev/null 2>&1 || true
            fi
        done < "${backup_dir}/units.state"
    fi

    if [[ -f "$CADDY_CONFIG_FILE" ]] && systemctl is-active --quiet caddy; then
        if ! caddy validate --config "$CADDY_CONFIG_FILE" --adapter caddyfile \
            || ! public_status_reload_caddy; then
            restore_ok=0
        fi
    fi
    [[ "$restore_ok" == "1" ]]
}

public_status_cpa_management_key() {
    local value=""
    value=$(cpamp_effective_env_value 'CPA_MANAGEMENT_KEY')
    [[ -n "$value" ]] || value=$(cpamp_effective_env_value 'CPA_SECRET')
    [[ -n "$value" ]] || value=$(existing_cpa_management_key)
    value="${value//$'\r'/}"
    value="${value//$'\n'/}"
    printf '%s\n' "$value"
}

public_status_quota_refresh() {
    local lock_fd tmp_dir key_file management_key db_path cpa_port helper_rc=0 rc=0

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || { error "未配置 Public Status。"; return 1; }
    [[ -x "$PUBLIC_STATUS_RICH_HELPER" ]] || { error "Rich Data helper 不存在。"; return 1; }
    systemctl is-active --quiet "$CPA_SERVICE" || { error "cpa.service 未运行，无法主动查询额度。"; return 1; }
    command -v python3 >/dev/null 2>&1 || { error "缺少 python3。"; return 1; }
    if ! background_capacity_available "GPT Team 主动额度刷新" "$BACKGROUND_MIN_AVAILABLE_MIB"; then
        info "已保留上一份成功额度数据，本轮不向 CPA 发起额外请求。"
        return 0
    fi

    install -d -m 0755 -o root -g root "$(dirname "$PUBLIC_STATUS_QUOTA_REFRESH_LOCK")" || return 1
    exec {lock_fd}>"$PUBLIC_STATUS_QUOTA_REFRESH_LOCK" || return 1
    if ! flock -n "$lock_fd"; then
        info "已有主动额度刷新任务正在运行，本次跳过。"
        exec {lock_fd}>&-
        return 0
    fi

    management_key=$(public_status_cpa_management_key)
    if [[ -z "$management_key" ]]; then
        error "未找到可用于本机 CPA Management API 的管理密钥。"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    fi
    db_path=$(cpamp_database_path)
    [[ -f "$db_path" ]] || {
        error "未找到 CPAMP SQLite：${db_path}"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    }
    cpa_port=$(configured_cpa_port)

    tmp_dir=$(mktemp -d /tmp/cpa-public-quota-refresh.XXXXXX) || {
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    }
    chmod 0700 "$tmp_dir" || true
    key_file="${tmp_dir}/management.key"
    if ! printf '%s\n' "$management_key" > "$key_file" || ! chmod 0600 "$key_file"; then
        rm -rf -- "$tmp_dir"
        flock -u "$lock_fd" >/dev/null 2>&1 || true
        exec {lock_fd}>&-
        return 1
    fi
    unset management_key

    flock -n "$BACKGROUND_HEAVY_LOCK" python3 "$PUBLIC_STATUS_RICH_HELPER" \
        --active-quota-refresh \
        --db-path "$db_path" \
        --quota-config "$PUBLIC_STATUS_QUOTA_CONFIG" \
        --private-dir "$PUBLIC_STATUS_DIR" \
        --cpa-origin "http://127.0.0.1:${cpa_port}" \
        --management-key-file "$key_file"
    helper_rc=$?
    rm -rf -- "$tmp_dir"

    case "$helper_rc" in
        0)
            info "GPT Team 主动额度刷新全部成功；公开 Dashboard 将使用主动/被动数据中较新的一份。"
            public_status_snapshot >/dev/null 2>&1 || true
            rc=0
            ;;
        10)
            info "本轮没有可刷新的 GPT Team 目标，未向 CPA 发起额度请求。"
            rc=10
            ;;
        11)
            warn "GPT Team 主动额度刷新部分成功；成功数据已保存，失败目标保留旧数据。"
            public_status_snapshot >/dev/null 2>&1 || true
            rc=11
            ;;
        12)
            error "GPT Team 主动额度刷新全部失败；已保留上一份成功额度与被动观测数据。"
            rc=12
            ;;
        *)
            error "GPT Team 主动额度刷新执行异常（退出码 ${helper_rc}）；已保留旧数据。"
            rc=1
            ;;
    esac

    flock -u "$lock_fd" >/dev/null 2>&1 || true
    exec {lock_fd}>&-
    return "$rc"
}

public_status_start_controlled_job() {
    local unit="${1:-}" unit_file start_rc status
    local before_invocation before_started before_active
    local after_invocation after_started result exec_code

    [[ -n "$unit" ]] || {
        error "缺少要启动的 Public Status systemd unit。"
        return 1
    }
    unit_file="/etc/systemd/system/${unit}"

    [[ -x "$INSTALL_PATH" ]] || install_self
    if [[ ! -f "$unit_file" ]]; then
        public_status_refresh_all_units || {
            error "无法安装 ${unit}，已拒绝在当前 shell 中直接运行重任务。"
            return 1
        }
    fi
    before_invocation=$(systemctl show "$unit" -p InvocationID --value 2>/dev/null || true)
    before_started=$(systemctl show "$unit" -p ExecMainStartTimestampMonotonic --value 2>/dev/null || true)
    before_active=$(systemctl show "$unit" -p ActiveState --value 2>/dev/null || true)
    case "$before_active" in
        active|activating|deactivating|reloading)
            warn "${unit} 已有任务正在运行，未重复启动。"
            return 1
            ;;
    esac
    systemctl start "$unit"
    start_rc=$?
    after_invocation=$(systemctl show "$unit" -p InvocationID --value 2>/dev/null || true)
    after_started=$(systemctl show "$unit" -p ExecMainStartTimestampMonotonic --value 2>/dev/null || true)
    if [[ -z "$after_invocation" && -z "$after_started" ]] \
        || [[ "$after_invocation" == "$before_invocation" \
            && "$after_started" == "$before_started" ]]; then
        error "${unit} 未产生可确认的本次 systemd invocation，拒绝使用历史退出状态。启动退出码=${start_rc}。"
        return 1
    fi

    result=$(systemctl show "$unit" -p Result --value 2>/dev/null || true)
    exec_code=$(systemctl show "$unit" -p ExecMainCode --value 2>/dev/null || true)
    status=$(systemctl show "$unit" -p ExecMainStatus --value 2>/dev/null || true)
    case "$status" in
        0|10)
            [[ "$start_rc" == "0" \
                && "$result" == "success" \
                && "$exec_code" == "1" ]] && return "$status"
            ;;
        11|12)
            [[ "$exec_code" == "1" \
                && ("$result" == "success" || "$result" == "exit-code") ]] \
                && return "$status"
            ;;
    esac
    error "${unit} 本次 invocation 未正常退出（systemctl start=${start_rc}, Result=${result:-unknown}, ExecMainCode=${exec_code:-unknown}, ExecMainStatus=${status:-unknown}）。"
    return 1
}

public_status_refresh_all_units() {
    local stage_dir backup_dir interval rc=0 unit source target
    local -a units=(
        "$PUBLIC_STATUS_SERVICE" "$PUBLIC_STATUS_TIMER"
        "$PUBLIC_STATUS_CN_SERVICE" "$PUBLIC_STATUS_CN_TIMER"
        "$PUBLIC_STATUS_QUOTA_SERVICE" "$PUBLIC_STATUS_QUOTA_TIMER"
    )

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || return 0
    interval=$(public_status_interval)
    stage_dir=$(mktemp -d /tmp/cpa-public-units.XXXXXX) || return 1
    backup_dir="${stage_dir}/backup"
    mkdir -p "$backup_dir" || { rm -rf -- "$stage_dir"; return 1; }
    public_status_stage_units "$stage_dir" "$interval" \
        || { rm -rf -- "$stage_dir"; return 1; }

    for unit in "${units[@]}"; do
        target="/etc/systemd/system/${unit}"
        [[ -f "$target" ]] && cp -a -- "$target" "${backup_dir}/${unit}" \
            || [[ ! -f "$target" ]] || { rc=1; break; }
    done
    if [[ "$rc" != "0" ]]; then
        rm -rf -- "$stage_dir"
        return 1
    fi
    if [[ "$rc" == "0" ]]; then
        for unit in "${units[@]}"; do
            source="${stage_dir}/${unit}"
            target="/etc/systemd/system/${unit}"
            install -m 0644 -o root -g root "$source" "$target" \
                || { rc=1; break; }
        done
    fi
    [[ "$rc" == "0" ]] && systemctl daemon-reload || rc=1

    if [[ "$rc" != "0" ]]; then
        for unit in "${units[@]}"; do
            target="/etc/systemd/system/${unit}"
            if [[ -f "${backup_dir}/${unit}" ]]; then
                cp -a -- "${backup_dir}/${unit}" "$target" || true
            else
                rm -f -- "$target"
            fi
        done
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    rm -rf -- "$stage_dir"
    return "$rc"
}

public_status_refresh_quota_units() {
    local stage_dir backup_service backup_timer had_service=0 had_timer=0
    local timer_enabled_before timer_active_before rc=0 interval

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || return 0
    interval=$(public_status_interval)
    stage_dir=$(mktemp -d /tmp/cpa-public-quota-units.XXXXXX) || return 1
    public_status_stage_units "$stage_dir" "$interval" || { rm -rf -- "$stage_dir"; return 1; }
    backup_service="${stage_dir}/service.before"
    backup_timer="${stage_dir}/timer.before"
    [[ -f "$PUBLIC_STATUS_QUOTA_SERVICE_FILE" ]] && { cp -a "$PUBLIC_STATUS_QUOTA_SERVICE_FILE" "$backup_service" || { rm -rf -- "$stage_dir"; return 1; }; had_service=1; }
    [[ -f "$PUBLIC_STATUS_QUOTA_TIMER_FILE" ]] && { cp -a "$PUBLIC_STATUS_QUOTA_TIMER_FILE" "$backup_timer" || { rm -rf -- "$stage_dir"; return 1; }; had_timer=1; }
    timer_enabled_before=$(systemctl is-enabled "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)
    timer_active_before=$(systemctl is-active "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)

    if ! install -m 0644 -o root -g root "${stage_dir}/${PUBLIC_STATUS_QUOTA_SERVICE}" "$PUBLIC_STATUS_QUOTA_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${stage_dir}/${PUBLIC_STATUS_QUOTA_TIMER}" "$PUBLIC_STATUS_QUOTA_TIMER_FILE" \
        || ! systemctl daemon-reload; then
        rc=1
    elif public_status_enabled && public_status_quota_refresh_enabled; then
        systemctl enable --now "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || rc=1
    else
        systemctl disable --now "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || true
    fi

    if [[ "$rc" != "0" ]]; then
        [[ "$had_service" == "1" ]] && cp -a "$backup_service" "$PUBLIC_STATUS_QUOTA_SERVICE_FILE" || rm -f "$PUBLIC_STATUS_QUOTA_SERVICE_FILE"
        [[ "$had_timer" == "1" ]] && cp -a "$backup_timer" "$PUBLIC_STATUS_QUOTA_TIMER_FILE" || rm -f "$PUBLIC_STATUS_QUOTA_TIMER_FILE"
        systemctl daemon-reload >/dev/null 2>&1 || true
        [[ "$timer_enabled_before" == "enabled" ]] && systemctl enable "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || systemctl disable "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || true
        [[ "$timer_active_before" == "active" ]] && systemctl start "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || systemctl stop "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || true
    fi
    rm -rf -- "$stage_dir"
    return "$rc"
}

public_status_enable_managed_timers() {
    systemctl enable --now "$PUBLIC_STATUS_TIMER" "$PUBLIC_STATUS_CN_TIMER" >/dev/null || return 1
    if public_status_quota_refresh_enabled; then
        systemctl enable --now "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null || return 1
    else
        systemctl disable --now "$PUBLIC_STATUS_QUOTA_TIMER" >/dev/null 2>&1 || true
    fi
    return 0
}

public_status_quota_list_configured() {
    local index=0 target enabled interval remark display
    local -a targets=()
    mapfile -t targets < <(public_status_quota_targets)
    enabled=0; public_status_quota_refresh_enabled && enabled=1
    interval=$(public_status_quota_interval_minutes)
    printf '\n%bGPT Team 额度账号配置%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    if (( ${#targets[@]} == 0 )); then
        printf '  手工账号:          未配置（仍会自动发现）\n'
    else
        for target in "${targets[@]}"; do
            index=$((index + 1))
            remark=$(public_status_quota_remark_for "$target")
            if [[ -n "$remark" ]]; then
                display="$remark"
            elif (( index == 1 )); then
                display='GPT Team 主账号'
            else
                display="GPT Team 账号 ${index}"
            fi
            printf '  %d. %s  [展示: %s]\n' "$index" "$target" "$display"
        done
    fi
    printf '  主动查询:          %s\n' "$([[ "$enabled" == "1" ]] && printf '已启用' || printf '已关闭')"
    printf '  查询间隔:          约 %s 分钟 + 0-5 分钟随机延迟\n' "$interval"
    printf '  自动发现:          已启用（本地 usage.sqlite，只识别有 Team 额度证据的账号）\n'
    printf '%s\n' '--------------------------------------------------'
}

public_status_quota_add_account() {
    local input normalized enabled interval target
    local -a targets=()
    mapfile -t targets < <(public_status_quota_targets)
    (( ${#targets[@]} < 8 )) || { warn "最多配置 8 个账号。"; return 1; }
    read -r -p '输入要添加的 GPT Team 账号邮箱: ' input || return 1
    normalized=$(public_status_normalize_quota_email "$input" 2>/dev/null || true)
    [[ -n "$normalized" ]] || { warn "邮箱格式无效。"; return 1; }
    for target in "${targets[@]}"; do
        [[ "${target,,}" == "${normalized,,}" ]] && { info "${normalized} 已在配置中。"; return 0; }
    done
    targets+=("$normalized")
    enabled=0; public_status_quota_refresh_enabled && enabled=1
    interval=$(public_status_quota_interval_minutes)
    public_status_write_quota_config "$enabled" "$interval" "${targets[@]}" || return 1
    info "已添加 ${normalized}；不会立即查询额度。下一次额度查询仅来自菜单手动刷新或既有定时任务。"
}

public_status_quota_remove_account() {
    local choice index=0 target enabled interval
    local -a targets=() kept=()
    mapfile -t targets < <(public_status_quota_targets)
    (( ${#targets[@]} > 0 )) || { info "当前没有手工配置的账号。"; return 0; }
    printf '\n手工配置账号：\n'
    for target in "${targets[@]}"; do
        index=$((index+1))
        printf '  %d. %s\n' "$index" "$target"
    done
    read -r -p "输入要删除的序号 [1-${#targets[@]}]: " choice || return 1
    [[ "$choice" =~ ^[0-9]+$ ]] && (( 10#$choice >= 1 && 10#$choice <= ${#targets[@]} )) || { warn "序号无效。"; return 1; }
    choice=$((10#$choice))
    for index in "${!targets[@]}"; do (( index + 1 == choice )) || kept+=("${targets[index]}"); done
    enabled=0; public_status_quota_refresh_enabled && enabled=1
    interval=$(public_status_quota_interval_minutes)
    public_status_write_quota_config "$enabled" "$interval" "${kept[@]}" || return 1
    public_status_write_quota_remark "${targets[choice-1]}" "" \
        || warn "账号已删除，但清理该账号的私有备注失败；请稍后重试设置/清除备注。"
    info "已删除 ${targets[choice-1]}；不会立即查询额度。下一次额度查询仅来自菜单手动刷新或既有定时任务。"
}

public_status_quota_set_remark() {
    local choice index=0 target current input normalized display
    local -a targets=()
    mapfile -t targets < <(public_status_quota_targets)
    (( ${#targets[@]} > 0 )) || { info "当前没有手工配置的账号；请先添加账号。"; return 0; }

    printf '\n手工配置账号：\n'
    for target in "${targets[@]}"; do
        index=$((index + 1))
        current=$(public_status_quota_remark_for "$target")
        if [[ -n "$current" ]]; then
            display="$current"
        elif (( index == 1 )); then
            display='GPT Team 主账号'
        else
            display="GPT Team 账号 ${index}"
        fi
        printf '  %d. %s  [当前展示: %s]\n' "$index" "$target" "$display"
    done

    read -r -p "输入要设置备注的账号序号 [1-${#targets[@]}]: " choice || return 1
    [[ "$choice" =~ ^[0-9]+$ ]] && (( 10#$choice >= 1 && 10#$choice <= ${#targets[@]} )) \
        || { warn "序号无效。"; return 1; }
    choice=$((10#$choice))
    target="${targets[choice-1]}"
    current=$(public_status_quota_remark_for "$target")

    if [[ -n "$current" ]]; then
        printf '  当前备注: %s\n' "$current"
    else
        printf '  当前备注: 未设置（使用默认称谓）\n'
    fi
    read -r -p '输入新的展示称谓（最多 48 字；直接回车清除备注）: ' input || return 1

    if [[ -z "${input//[[:space:]]/}" ]]; then
        public_status_write_quota_remark "$target" "" || { error "清除备注失败。"; return 1; }
        info "已清除 ${target} 的备注；Dashboard 将恢复默认称谓。"
    else
        normalized=$(public_status_normalize_quota_remark "$input" 2>/dev/null || true)
        [[ -n "$normalized" ]] || {
            warn "备注无效：最多 48 个字符，不能含控制字符、@，也不能形似 API Key/Token。"
            return 1
        }
        public_status_write_quota_remark "$target" "$normalized" \
            || { error "保存备注失败。"; return 1; }
        info "已把 ${target} 的 Dashboard 展示称谓设置为：${normalized}"
    fi

    info "备注只绑定逻辑账号邮箱，不绑定 codex-*.json 认证文件；下一轮本地快照会自动应用，不会主动查询上游额度。"
}

public_status_quota_refresh_settings() {
    local choice enabled interval input
    while true; do
        enabled=0; public_status_quota_refresh_enabled && enabled=1
        interval=$(public_status_quota_interval_minutes)
        printf '\n%b主动额度刷新设置%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  当前状态: %s\n' "$([[ "$enabled" == "1" ]] && printf '已启用' || printf '已关闭')"
        printf '  间隔:     约 %s 分钟 + 0-5 分钟随机延迟\n' "$interval"
        printf '  timer:    %s / %s\n' "$(systemctl is-enabled "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)" "$(systemctl is-active "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 启用主动查询\n  2. 关闭主动查询\n  3. 修改间隔（30-1440 分钟）\n  0. 返回\n'
        read -r -p '请选择 [0-3]: ' choice || return 0
        case "$choice" in
            1) enabled=1 ;;
            2) enabled=0 ;;
            3)
                read -r -p "输入查询间隔分钟数 [${interval}]: " input || return 1
                [[ -n "$input" ]] || input="$interval"
                [[ "$input" =~ ^[0-9]+$ ]] && (( 10#$input >= 30 && 10#$input <= 1440 )) || { warn "请输入 30-1440 的整数。"; continue; }
                interval=$((10#$input))
                ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项。"; continue ;;
        esac
        local -a targets=()
        mapfile -t targets < <(public_status_quota_targets)
        public_status_write_quota_config "$enabled" "$interval" "${targets[@]}" || return 1
        public_status_refresh_quota_units || { error "更新主动刷新 timer 失败。"; return 1; }
        info "主动额度刷新设置已更新。"
    done
}

public_status_quota_show_last_refresh() {
    local cache="$PUBLIC_STATUS_QUOTA_ACTIVE_CACHE"
    [[ -s "$cache" ]] || { info "尚无主动额度刷新记录。"; return 0; }
    printf '\n%b最近主动额度刷新结果%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    if [[ -x "$PUBLIC_STATUS_RICH_HELPER" ]] && command -v python3 >/dev/null 2>&1; then
        PYTHONDONTWRITEBYTECODE=1 python3 - "$PUBLIC_STATUS_RICH_HELPER" "$cache" "$PUBLIC_STATUS_QUOTA_CONFIG" <<'PYQREPORT' || warn "无法解析主动额度缓存。"
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

helper_path, cache_path, quota_config = sys.argv[1:4]
spec = importlib.util.spec_from_file_location("cpa_public_rich_report", helper_path)
if spec is None or spec.loader is None:
    raise SystemExit(1)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
try:
    data = json.loads(Path(cache_path).read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(1)
run = data.get("last_run") if isinstance(data, dict) else {}
run = run if isinstance(run, dict) else {}
started = module.integer(run.get("started_at_ms"))
if started > 0:
    started_text = datetime.fromtimestamp(started / 1000, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
else:
    started_text = "未知"
remarks = module.read_quota_remarks(Path(quota_config))
accounts = data.get("accounts") if isinstance(data, dict) else {}
accounts = accounts if isinstance(accounts, dict) else {}
logical = {}
for raw_entry in accounts.values():
    if not isinstance(raw_entry, dict):
        continue
    targets = module.quota_targets_from_identity(raw_entry.get("target"))
    target = targets[0] if targets else ""
    if not target:
        continue
    status = str(raw_entry.get("last_status") or "unknown")
    http_status = module.integer(raw_entry.get("last_http_status")) or None
    quota = raw_entry.get("quota") if isinstance(raw_entry.get("quota"), dict) else None
    score = (
        1 if status == "ok" else 0,
        module.quota_event_at(quota),
        module.integer(raw_entry.get("last_success_ms")),
        module.integer(raw_entry.get("last_attempt_ms")),
    )
    previous = logical.get(target)
    if previous is None or score > previous[0]:
        logical[target] = (score, status, http_status)
print(f"  开始:      {started_text}")
print(
    "  原始记录目标/成功/失败: "
    f"{module.integer(run.get('targets'))} / {module.integer(run.get('success'))} / {module.integer(run.get('failed'))}"
)
print(f"  逻辑账号（邮箱去重）: {len(logical)}")
print()
for target, (_, status, http_status) in logical.items():
    remark = remarks.get(target, "")
    label = f"{target} [{remark}]" if remark else target
    suffix = f" (HTTP {http_status})" if http_status else ""
    print(f"  {label} : {status}{suffix}")
PYQREPORT
    else
        jq -r '
          .last_run as $r |
          "  开始:      " + (($r.started_at_ms // 0) | if . > 0 then ((./1000)|strftime("%Y-%m-%d %H:%M:%S UTC")) else "未知" end),
          "  原始记录目标/成功/失败: " + (($r.targets // 0)|tostring) + " / " + (($r.success // 0)|tostring) + " / " + (($r.failed // 0)|tostring),
          "",
          (.accounts // {} | to_entries[]? | "  " + (.value.target // "(unknown)") + " : " + (.value.last_status // "unknown") + (if .value.last_http_status then " (HTTP " + (.value.last_http_status|tostring) + ")" else "" end))
        ' "$cache" 2>/dev/null || warn "无法解析主动额度缓存。"
    fi
    printf '%s\n' '--------------------------------------------------'
}

public_status_quota_menu() {
    local choice=""
    while true; do
        [[ -t 1 ]] && clear
        printf '\n%bGPT Team 额度账号管理%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 查看已配置账号\n'
        printf '  2. 添加账号\n'
        printf '  3. 删除账号\n'
        printf '  4. 为多账号设置备注\n'
        printf '  5. 立即主动刷新全部账号额度\n'
        printf '  6. 主动刷新设置 / 状态\n'
        printf '  7. 查看最近主动刷新结果\n'
        printf '  0. 返回\n'
        printf '%s\n' '--------------------------------------------------'
        printf '  说明: 以邮箱作为逻辑账号；codex-*.json 仅是认证文件别名，会合并去重。备注绑定逻辑账号。\n'
        printf '        主动额度查询只会由菜单 5 手动触发，或由独立 systemd timer 定时触发。\n'
        printf '%s\n' '--------------------------------------------------'
        read -r -p '请选择 [0-7]: ' choice || return 0
        case "$choice" in
            1) public_status_quota_list_configured; pause_menu ;;
            2) public_status_quota_add_account; pause_menu ;;
            3) public_status_quota_remove_account; pause_menu ;;
            4) public_status_quota_set_remark; pause_menu ;;
            5) public_status_command --quota-refresh; pause_menu ;;
            6) public_status_quota_refresh_settings ;;
            7) public_status_quota_show_last_refresh; pause_menu ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项，请重新输入。"; sleep 1 ;;
        esac
    done
}

public_status_probe_key_and_api() {
    local tmp_dir raw rc

    tmp_dir=$(mktemp -d /tmp/cpamp-public-probe.XXXXXX) || return 1
    chmod 0700 "$tmp_dir" || true
    raw="${tmp_dir}/raw.json"
    public_status_fetch_dashboard "$raw" "$tmp_dir"
    rc=$?
    rm -rf -- "$tmp_dir"
    return "$rc"
}

public_status_prompt_inputs() {
    local current_domain current_interval input normalized minimum_interval=5

    current_domain=$(public_status_domain)
    current_interval=$(public_status_interval)
    low_memory_profile_enabled && minimum_interval=30

    while true; do
        if [[ -n "$current_domain" ]]; then
            read -r -p "Status 独立域名 [${current_domain}]: " input || return 1
            [[ -n "$input" ]] || input="$current_domain"
        else
            read -r -p 'Status 独立域名（例如 status.example.com）: ' input || return 1
        fi
        normalized=$(public_status_normalize_domain "$input" 2>/dev/null || true)
        if [[ -z "$normalized" ]]; then
            warn "域名格式无效；必须是独立的公网域名，不能含协议、端口或路径。"
            continue
        fi
        if ! public_status_check_domain_collision "$normalized"; then
            continue
        fi
        PUBLIC_STATUS_INPUT_DOMAIN="$normalized"
        break
    done

    while true; do
        read -r -p "快照刷新间隔秒数 [${current_interval}]（${minimum_interval}-300）: " input || return 1
        [[ -n "$input" ]] || input="$current_interval"
        if [[ "$input" =~ ^[0-9]+$ ]] \
            && (( 10#$input >= minimum_interval && 10#$input <= 300 )); then
            PUBLIC_STATUS_INPUT_INTERVAL="$((10#$input))"
            break
        fi
        warn "请输入 ${minimum_interval}-300 的整数。"
    done
    return 0
}

public_status_maybe_add_ssh_ip() {
    local ssh_ip normalized answer="" tmp_file

    [[ -n "${SSH_CONNECTION:-}" ]] || return 0
    ssh_ip="${SSH_CONNECTION%% *}"
    normalized=$(public_status_normalize_ip_or_cidr "$ssh_ip" 2>/dev/null || true)
    [[ -n "$normalized" ]] || return 0
    grep -Fqx "$normalized" "$PUBLIC_STATUS_CUSTOM_ALLOW" 2>/dev/null && return 0

    printf '\n检测到当前 SSH 来源 IP：%s\n' "$ssh_ip"
    read -r -p '是否加入额外白名单，避免你在境外网络下无法查看 [Y/n]: ' answer || return 1
    [[ "$answer" =~ ^[Nn]$ ]] && return 0
    tmp_file=$(mktemp "${PUBLIC_STATUS_CUSTOM_ALLOW}.XXXXXX") || return 1
    {
        cat "$PUBLIC_STATUS_CUSTOM_ALLOW" 2>/dev/null || true
        printf '%s\n' "$normalized"
    } | sed '/^[[:space:]]*$/d' | sort -u > "$tmp_file"
    install -m 0600 -o root -g root "$tmp_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" || {
        rm -f "$tmp_file"
        return 1
    }
    rm -f "$tmp_file"
    info "已把 ${normalized} 加入额外白名单。"
}

public_status_install_or_enable() {
    local stage_dir backup_dir cn4_stage cn6_stage assets_stage units_stage
    local old_key_rc=0 rc=1 answer=""

    require_deployment
    public_status_ensure_dependencies || return 1
    install_self || return 1
    [[ -f "$CPAMP_BIN" ]] || { error "未安装 CPAMP。"; return 1; }
    systemctl is-active --quiet "$CPAMP_SERVICE" \
        || { error "cpamp.service 未运行，无法生成首份快照。"; return 1; }
    systemctl is-active --quiet caddy \
        || { error "caddy.service 未运行；Public Status 不会接管或新增其他监听端口。"; return 1; }
    [[ -f "$CADDY_CONFIG_FILE" ]] \
        || { error "未找到 ${CADDY_CONFIG_FILE}。"; return 1; }

    PUBLIC_STATUS_INPUT_DOMAIN=""
    PUBLIC_STATUS_INPUT_INTERVAL=""
    public_status_prompt_inputs || { warn "已取消 Public Status 配置。"; return 0; }

    info "正在验证本机 CPAMP Dashboard API 与 Admin Key..."
    public_status_probe_key_and_api
    old_key_rc=$?
    if [[ "$old_key_rc" != "0" ]]; then
        warn "${PUBLIC_STATUS_LAST_FETCH_ERROR:-无法读取 Dashboard API}"
        if [[ "$old_key_rc" == "2" || ! -s "$CPAMP_MAINT_ADMIN_KEY_FILE" ]]; then
            read -r -p '是否现在安全输入并验证当前 CPAMP Admin Key [Y/n]: ' answer || return 1
            if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                cpamp_maintenance_set_admin_key || return 1
                public_status_probe_key_and_api || {
                    error "更新 Admin Key 后仍无法读取 Dashboard API。"
                    return 1
                }
            else
                error "没有可验证的 Admin Key，拒绝开放 Status。"
                return 1
            fi
        else
            return 1
        fi
    fi

    stage_dir=$(mktemp -d /tmp/cpamp-public-install.XXXXXX) || return 1
    backup_dir="${stage_dir}/backup"
    cn4_stage="${stage_dir}/cn-ipv4.txt"
    cn6_stage="${stage_dir}/cn-ipv6.txt"
    assets_stage="${stage_dir}/www"
    units_stage="${stage_dir}/units"

    if ! public_status_download_cn_lists "$cn4_stage" "$cn6_stage"; then
        if [[ -s "$PUBLIC_STATUS_CN4" && -s "$PUBLIC_STATUS_CN6" ]] \
            && public_status_validate_cn_file 4 "$PUBLIC_STATUS_CN4" "${stage_dir}/cn4.existing" \
            && public_status_validate_cn_file 6 "$PUBLIC_STATUS_CN6" "${stage_dir}/cn6.existing"; then
            warn "CN 网段在线更新失败，继续使用本机上一份已验证列表。"
            cp "${stage_dir}/cn4.existing" "$cn4_stage" || { rm -rf -- "$stage_dir"; return 1; }
            cp "${stage_dir}/cn6.existing" "$cn6_stage" || { rm -rf -- "$stage_dir"; return 1; }
        else
            error "首次启用必须取得并验证完整的 CN IPv4/IPv6 列表；本次未开放 Status。"
            rm -rf -- "$stage_dir"
            return 1
        fi
    fi
    public_status_stage_assets "$assets_stage" "$PUBLIC_STATUS_INPUT_INTERVAL" \
        || { rm -rf -- "$stage_dir"; return 1; }
    public_status_stage_units "$units_stage" "$PUBLIC_STATUS_INPUT_INTERVAL" \
        || { rm -rf -- "$stage_dir"; return 1; }
    public_status_transaction_backup "$backup_dir" \
        || { rm -rf -- "$stage_dir"; return 1; }

    if ! public_status_write_config "$PUBLIC_STATUS_INPUT_DOMAIN" "$PUBLIC_STATUS_INPUT_INTERVAL" 1 \
        || ! public_status_ensure_custom_allowlist \
        || ! public_status_maybe_add_ssh_ip \
        || ! install -m 0600 -o root -g root "$cn4_stage" "$PUBLIC_STATUS_CN4" \
        || ! install -m 0600 -o root -g root "$cn6_stage" "$PUBLIC_STATUS_CN6" \
        || ! install -d -m 0755 -o root -g root "$PUBLIC_STATUS_DIR" "$PUBLIC_STATUS_WEB_ROOT" \
        || ! install -m 0644 -o root -g root "${assets_stage}/index.html" "${PUBLIC_STATUS_WEB_ROOT}/index.html" \
        || ! install -m 0644 -o root -g root "${assets_stage}/app.css" "${PUBLIC_STATUS_WEB_ROOT}/app.css" \
        || ! install -m 0644 -o root -g root "${assets_stage}/app.js" "${PUBLIC_STATUS_WEB_ROOT}/app.js" \
        || ! install -m 0644 -o root -g root "${assets_stage}/meta.json" "${PUBLIC_STATUS_WEB_ROOT}/meta.json" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_SERVICE}" "$PUBLIC_STATUS_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_TIMER}" "$PUBLIC_STATUS_TIMER_FILE" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_CN_SERVICE}" "$PUBLIC_STATUS_CN_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_CN_TIMER}" "$PUBLIC_STATUS_CN_TIMER_FILE" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_QUOTA_SERVICE}" "$PUBLIC_STATUS_QUOTA_SERVICE_FILE" \
        || ! install -m 0644 -o root -g root "${units_stage}/${PUBLIC_STATUS_QUOTA_TIMER}" "$PUBLIC_STATUS_QUOTA_TIMER_FILE" \
        || ! systemctl daemon-reload \
        || ! systemctl start "$PUBLIC_STATUS_SERVICE" \
        || ! public_status_with_lock public_status_apply_caddy_locked \
        || ! public_status_enable_managed_timers \
        || ! systemctl is-active --quiet "$PUBLIC_STATUS_TIMER" \
        || ! systemctl is-active --quiet "$PUBLIC_STATUS_CN_TIMER" \
        || ! systemctl is-active --quiet caddy \
        || ! jq -e '.schema_version == 1' "$PUBLIC_STATUS_SNAPSHOT" >/dev/null 2>&1; then
        error "Public Status 安装/启用未完整通过，正在恢复升级前状态..."
        if public_status_transaction_restore "$backup_dir"; then
            warn "已完整恢复 Public Status 与 Caddy 的升级前状态。"
        else
            error "自动回滚不完整，请检查 caddy 与 cpamp-public timers。"
        fi
        rm -rf -- "$stage_dir"
        return 1
    fi

    rm -rf -- "$stage_dir"
    info "Public Status 已启用：https://${PUBLIC_STATUS_INPUT_DOMAIN}"
    info "访问策略：CN IPv4/IPv6 + 额外白名单；非白名单返回 404。"
    info "未新增监听端口；仅复用现有 Caddy 80/443。"
    return 0
}

public_status_update_cn() {
    local tmp_dir new4 new6 old4 old6 metadata_tmp

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || { error "未配置 Public Status。"; return 1; }
    public_status_ensure_dependencies || return 1
    tmp_dir=$(mktemp -d /tmp/cpamp-public-cn-update.XXXXXX) || return 1
    new4="${tmp_dir}/cn4.new"
    new6="${tmp_dir}/cn6.new"
    old4="${tmp_dir}/cn4.old"
    old6="${tmp_dir}/cn6.old"

    if ! public_status_download_cn_lists "$new4" "$new6"; then
        public_status_record_error "CN IP 列表更新失败；继续使用旧列表"
        rm -rf -- "$tmp_dir"
        return 1
    fi
    cp -a "$PUBLIC_STATUS_CN4" "$old4" 2>/dev/null || : > "$old4"
    cp -a "$PUBLIC_STATUS_CN6" "$old6" 2>/dev/null || : > "$old6"

    if ! install -m 0600 -o root -g root "$new4" "$PUBLIC_STATUS_CN4" \
        || ! install -m 0600 -o root -g root "$new6" "$PUBLIC_STATUS_CN6" \
        || ! public_status_with_lock public_status_apply_caddy_locked; then
        error "新 CN 网段未能安全生效，正在恢复上一版。"
        [[ -s "$old4" ]] && install -m 0600 -o root -g root "$old4" "$PUBLIC_STATUS_CN4"
        [[ -s "$old6" ]] && install -m 0600 -o root -g root "$old6" "$PUBLIC_STATUS_CN6"
        rm -rf -- "$tmp_dir"
        return 1
    fi

    metadata_tmp=$(mktemp "${PUBLIC_STATUS_CN_METADATA}.XXXXXX") || {
        rm -rf -- "$tmp_dir"
        return 1
    }
    {
        printf 'updated_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'ipv4_count=%s\n' "$(wc -l < "$PUBLIC_STATUS_CN4" | tr -d '[:space:]')"
        printf 'ipv6_count=%s\n' "$(wc -l < "$PUBLIC_STATUS_CN6" | tr -d '[:space:]')"
        printf 'ipv4_sha256=%s\n' "$(sha256sum "$PUBLIC_STATUS_CN4" | awk '{print $1}')"
        printf 'ipv6_sha256=%s\n' "$(sha256sum "$PUBLIC_STATUS_CN6" | awk '{print $1}')"
    } > "$metadata_tmp"
    install -m 0600 -o root -g root "$metadata_tmp" "$PUBLIC_STATUS_CN_METADATA" || true
    rm -f "$metadata_tmp"
    rm -rf -- "$tmp_dir"
    info "CN IPv4/IPv6 白名单已验证、原子替换并通过 Caddy 校验。"
    return 0
}

public_status_add_allowlist() {
    local input normalized tmp_file backup_file

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || { error "请先安装/启用 Public Status。"; return 1; }
    public_status_ensure_dependencies || return 1
    public_status_ensure_custom_allowlist || return 1
    read -r -p '输入要加入的公网 IP 或 CIDR: ' input || return 1
    normalized=$(public_status_normalize_ip_or_cidr "$input" 2>/dev/null || true)
    [[ -n "$normalized" ]] || { warn "IP/CIDR 无效，或范围过宽（不允许 /0）。"; return 1; }
    if grep -Fqx "$normalized" "$PUBLIC_STATUS_CUSTOM_ALLOW"; then
        info "${normalized} 已在额外白名单中。"
        return 0
    fi

    tmp_file=$(mktemp "${PUBLIC_STATUS_CUSTOM_ALLOW}.XXXXXX") || return 1
    backup_file=$(mktemp /tmp/cpamp-public-custom-backup.XXXXXX) || {
        rm -f "$tmp_file"
        return 1
    }
    cp -a "$PUBLIC_STATUS_CUSTOM_ALLOW" "$backup_file" || {
        rm -f "$tmp_file" "$backup_file"
        return 1
    }
    {
        cat "$PUBLIC_STATUS_CUSTOM_ALLOW"
        printf '%s\n' "$normalized"
    } | sed '/^[[:space:]]*$/d' | sort -u > "$tmp_file"
    if ! install -m 0600 -o root -g root "$tmp_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" \
        || ! public_status_with_lock public_status_apply_caddy_locked; then
        cp -a "$backup_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" || true
        rm -f "$tmp_file" "$backup_file"
        error "白名单修改未能通过 Caddy 校验，已恢复原列表。"
        return 1
    fi
    rm -f "$tmp_file" "$backup_file"
    info "已加入额外白名单：${normalized}"
}

public_status_remove_allowlist() {
    local choice tmp_file backup_file index=0 entry
    local -a entries=()

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || { error "请先安装/启用 Public Status。"; return 1; }
    public_status_ensure_custom_allowlist || return 1
    mapfile -t entries < <(sed '/^[[:space:]]*$/d' "$PUBLIC_STATUS_CUSTOM_ALLOW")
    if (( ${#entries[@]} == 0 )); then
        info "当前没有额外白名单条目。"
        return 0
    fi
    printf '\n额外白名单：\n'
    for entry in "${entries[@]}"; do
        index=$((index + 1))
        printf '  %d. %s\n' "$index" "$entry"
    done
    read -r -p "输入要删除的序号 [1-${#entries[@]}]: " choice || return 1
    [[ "$choice" =~ ^[0-9]+$ ]] \
        && (( 10#$choice >= 1 && 10#$choice <= ${#entries[@]} )) \
        || { warn "序号无效。"; return 1; }
    choice=$((10#$choice))

    tmp_file=$(mktemp "${PUBLIC_STATUS_CUSTOM_ALLOW}.XXXXXX") || return 1
    backup_file=$(mktemp /tmp/cpamp-public-custom-backup.XXXXXX) || {
        rm -f "$tmp_file"
        return 1
    }
    cp -a "$PUBLIC_STATUS_CUSTOM_ALLOW" "$backup_file" || {
        rm -f "$tmp_file" "$backup_file"
        return 1
    }
    awk -v remove="$choice" 'NR != remove' "$PUBLIC_STATUS_CUSTOM_ALLOW" > "$tmp_file"
    if ! install -m 0600 -o root -g root "$tmp_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" \
        || ! public_status_with_lock public_status_apply_caddy_locked; then
        cp -a "$backup_file" "$PUBLIC_STATUS_CUSTOM_ALLOW" || true
        rm -f "$tmp_file" "$backup_file"
        error "白名单修改未能通过 Caddy 校验，已恢复原列表。"
        return 1
    fi
    info "已删除额外白名单：${entries[choice-1]}"
    rm -f "$tmp_file" "$backup_file"
}

public_status_disable() {
    local answer="" domain interval

    [[ -f "$PUBLIC_STATUS_CONFIG" ]] || { info "Public Status 尚未配置。"; return 0; }
    domain=$(public_status_domain)
    interval=$(public_status_interval)
    read -r -p "确认关闭 ${domain} 的公网 Status（保留配置与快照）[y/N]: " answer || return 0
    [[ "$answer" =~ ^[Yy]$ ]] || { warn "已取消。"; return 0; }

    if ! public_status_with_lock public_status_remove_caddy_locked; then
        error "Caddy 站点未能安全移除，未继续禁用 timer。"
        return 1
    fi
    systemctl disable --now "$PUBLIC_STATUS_TIMER" "$PUBLIC_STATUS_CN_TIMER" "$PUBLIC_STATUS_QUOTA_TIMER" \
        >/dev/null 2>&1 || true
    public_status_write_config "$domain" "$interval" 0 \
        || warn "站点已下线，但状态文件未能写入 enabled=0。"
    info "Public Status 已关闭；CN 列表、自定义白名单和最后快照均已保留。"
}

public_status_show_status() {
    local domain interval enabled snapshot_time snapshot_age now
    local count4=0 count6=0 custom_count=0 last_error="无"

    domain=$(public_status_domain)
    interval=$(public_status_interval)
    enabled=$(public_status_config_value PUBLIC_STATUS_ENABLED)
    [[ -s "$PUBLIC_STATUS_CN4" ]] && count4=$(wc -l < "$PUBLIC_STATUS_CN4" | tr -d '[:space:]')
    [[ -s "$PUBLIC_STATUS_CN6" ]] && count6=$(wc -l < "$PUBLIC_STATUS_CN6" | tr -d '[:space:]')
    [[ -s "$PUBLIC_STATUS_CUSTOM_ALLOW" ]] \
        && custom_count=$(sed '/^[[:space:]]*$/d' "$PUBLIC_STATUS_CUSTOM_ALLOW" | wc -l | tr -d '[:space:]')
    if [[ -s "$PUBLIC_STATUS_LAST_ERROR" ]]; then
        last_error=$(awk -F= '$1 == "message" {print substr($0, length($1) + 2); exit}' \
            "$PUBLIC_STATUS_LAST_ERROR" 2>/dev/null || true)
    fi
    if [[ -s "$PUBLIC_STATUS_SNAPSHOT" ]]; then
        snapshot_time=$(jq -r '.generated_at // "未知"' "$PUBLIC_STATUS_SNAPSHOT" 2>/dev/null || printf '未知')
        now=$(date +%s)
        snapshot_age=$((now - $(stat -c %Y "$PUBLIC_STATUS_SNAPSHOT" 2>/dev/null || printf '%s' "$now")))
    else
        snapshot_time="无"
        snapshot_age="-1"
    fi

    printf '\n%b公网只读 Dashboard 状态%b\n' "$BOLD" "$NC"
    printf '%s\n' '--------------------------------------------------'
    printf '  配置状态:          %s\n' "$([[ "$enabled" == "1" ]] && printf '已启用' || printf '未启用/已禁用')"
    printf '  Status 域名:       %s\n' "${domain:-未配置}"
    printf '  访问范围:          CN IPv4 + CN IPv6 + 额外白名单\n'
    printf '  CN IPv4 网段:      %s\n' "$count4"
    printf '  CN IPv6 网段:      %s\n' "$count6"
    printf '  额外白名单:        %s 条\n' "$custom_count"
    printf '  快照间隔:          %s 秒\n' "$interval"
    printf '  最后成功快照:      %s\n' "$snapshot_time"
    [[ "$snapshot_age" != "-1" ]] && printf '  快照文件年龄:      %s 秒\n' "$snapshot_age"
    printf '  Snapshot timer:    %s / %s\n' \
        "$(systemctl is-enabled "$PUBLIC_STATUS_TIMER" 2>/dev/null || true)" \
        "$(systemctl is-active "$PUBLIC_STATUS_TIMER" 2>/dev/null || true)"
    printf '  CN update timer:   %s / %s\n' \
        "$(systemctl is-enabled "$PUBLIC_STATUS_CN_TIMER" 2>/dev/null || true)" \
        "$(systemctl is-active "$PUBLIC_STATUS_CN_TIMER" 2>/dev/null || true)"
    printf '  Team quota timer:  %s / %s（约 %s 分钟）\n' \
        "$(systemctl is-enabled "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)" \
        "$(systemctl is-active "$PUBLIC_STATUS_QUOTA_TIMER" 2>/dev/null || true)" \
        "$(public_status_quota_interval_minutes)"
    printf '  Caddy 站点文件:    %s\n' "$([[ -f "$PUBLIC_STATUS_CADDY_FILE" ]] && printf '已安装' || printf '未安装')"
    printf '  最近错误:          %s\n' "${last_error:-无}"
    printf '  网络端口:          未新增端口，仅复用 Caddy 80/443\n'
    printf '%s\n' '--------------------------------------------------'
    if [[ -n "$domain" ]]; then
        printf '  地址: https://%s\n' "$domain"
    fi
    printf '  提醒: Status 域名应直接解析到本机；套 CDN/反代会改变 remote_ip 判断。\n\n'
}

public_status_self_test() {
    local tmp_dir raw clean domain ip caddy_site test_main rc=0

    command -v jq >/dev/null 2>&1 || { error "self-test 需要 jq。"; return 1; }
    command -v python3 >/dev/null 2>&1 || { error "self-test 需要 python3。"; return 1; }
    tmp_dir=$(mktemp -d /tmp/cpamp-public-selftest.XXXXXX) || return 1
    raw="${tmp_dir}/raw.json"
    clean="${tmp_dir}/clean.json"
    cat > "$raw" <<'EOF'
{
  "rolling_30m":{"total_calls":12,"total_tokens":3456,"rpm":2.0,"tpm":576.0,"api_key":"must-not-leak"},
  "today":{"total_calls":100,"success_calls":98,"failure_calls":2,"success_rate":0.98,"input_tokens":100000,"output_tokens":23456,"cached_tokens":0,"total_tokens":123456,"total_cost":1.25,"average_latency_ms":456},
  "top_models_today":[{"model":"safe-model","calls":77,"tokens":8888,"cost":0.5,"success_rate":0.99,"account_snapshot":{"email":"hidden@example.com"},"endpoint":"hidden"}],
  "traffic_timeline":[{"bucket_ms":1788523200000,"calls":5,"tokens":50,"success":4,"failure":1,"failure_rate":0.2,"failure_summary":"hidden"}],
  "recent_failures":[{"authorization":"Bearer hidden","response_body":"hidden"}]
}
EOF
    if ! public_status_sanitize_payload "$raw" "$clean" 'must-not-leak' \
        || grep -Fq 'must-not-leak' "$clean" \
        || grep -Eiq 'hidden@example|authorization|response_body|account_snapshot|endpoint|failure_summary' "$clean" \
        || ! jq -e '.today.requests == 100 and .top_models[0].model == "safe-model"' "$clean" >/dev/null; then
        error "脱敏故障注入测试失败。"
        rc=1
    fi

    if [[ ! -x "$PUBLIC_STATUS_RICH_HELPER" ]]; then
        error "Rich Data helper 不存在或不可执行。"
        rc=1
    elif ! PYTHONDONTWRITEBYTECODE=1 python3 - "$PUBLIC_STATUS_RICH_HELPER" <<'PY'
import importlib.util
import sys

path = sys.argv[1]
spec = importlib.util.spec_from_file_location("cpa_public_rich", path)
if spec is None or spec.loader is None:
    raise SystemExit("cannot load rich helper")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
rows = module.sanitize_calls({
    "events": {"items": [
        {"timestamp_ms": 1, "model": "gpt-5.6-sol", "reasoning_effort": "HIGH", "reasoning_tokens": 10, "total_tokens": 20, "failed": False},
        {"timestamp_ms": 2, "model": "gpt-5.6-sol", "reasoning_effort": "turbo", "reasoning_tokens": 10, "total_tokens": 20, "failed": False},
        {"timestamp_ms": 3, "model": "gpt-5.6-sol", "reasoning_tokens": 10, "total_tokens": 20, "failed": False},
    ]}
}, {})
assert rows[0].get("reasoning_effort") == "high"
assert "reasoning_effort" not in rows[1]
assert "reasoning_effort" not in rows[2]
quota = module.extract_quota_evidence({
    "response_headers": {
        "X-Codex-Plan-Type": ["team"],
        "X-Codex-Primary-Used-Percent": ["25"],
        "X-Codex-Primary-Window-Minutes": ["300"],
        "X-Codex-Primary-Reset-At": ["1788709680"],
        "X-Codex-Secondary-Used-Percent": ["40"],
        "X-Codex-Secondary-Window-Minutes": ["10080"],
        "X-Codex-Secondary-Reset-At": ["1789021920"],
        "Set-Cookie": ["must-not-leak"],
    }
}, 1788700000000)
assert quota.get("plan_type") == "team"
assert quota["primary"]["used_percent"] == 25
assert quota["primary"]["window_minutes"] == 300
assert quota["secondary"]["used_percent"] == 40
assert quota["secondary"]["window_minutes"] == 10080
wham = module.extract_quota_evidence({
    "plan_type": "team",
    "rate_limit": {
        "primary_window": {"used_percent": 25, "limit_window_seconds": 18000, "reset_after_seconds": 600},
        "secondary_window": {"used_percent": 40, "limit_window_seconds": 604800, "reset_after_seconds": 3600},
    },
}, 1788700010000)
active = module.quota_from_evidence(wham, 1788700010000, "GPT Team 主账号", module.QUOTA_ACTIVE_SOURCE_KIND)
assert active["available"] is True
assert active["windows"]["five_hour"]["window_minutes"] == 300
assert active["windows"]["seven_day"]["window_minutes"] == 10080
assert active["source"]["kind"] == "active_wham_usage"
assert module.quota_window_public({"used_percent": 50, "window_minutes": 60, "reset_at_ms": 1788709680000}, 1788700000000) is None
public_quota = module.unavailable_quota(1788700000000)
assert "QUOTA_TARGET_ACCOUNT" not in module.dump_bytes(public_quota).decode("utf-8")
assert module.summarize({})["requests"] is None
assert module.summarize({})["tokens"]["total"] is None
import sqlite3
import tempfile
from pathlib import Path
with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    p = td_path / "x.json"
    assert module.atomic_write_json_if_changed(p, {"generated_at_ms": 1, "items": [1]}, 0o644, ("generated_at_ms",)) is True
    assert module.atomic_write_json_if_changed(p, {"generated_at_ms": 2, "items": [1]}, 0o644, ("generated_at_ms",)) is False
    assert module.load_json(p)["generated_at_ms"] == 1

    quota_conf = td_path / "quota.conf"
    quota_conf.write_text(
        "QUOTA_TARGET_ACCOUNT=main@example.com\n"
        "QUOTA_TARGET_ACCOUNT=second@example.com\n",
        encoding="utf-8",
    )
    assert module.read_quota_targets(quota_conf) == ["main@example.com", "second@example.com"]
    (td_path / "quota-remarks.json").write_text(
        __import__("json").dumps({"main@example.com": "主力 Team", "second@example.com": "实验账号"}, ensure_ascii=False),
        encoding="utf-8",
    )
    remarks = module.read_quota_remarks(quota_conf)
    assert remarks == {"main@example.com": "主力 Team", "second@example.com": "实验账号"}
    assert module.quota_display_name(0, "main@example.com", remarks) == "主力 Team"
    assert module.quota_display_name(1, "second@example.com", remarks) == "实验账号"
    assert module.quota_display_name(2, "third@example.com", remarks) == "GPT Team 账号 3"
    assert module.quota_targets_from_identity("codex-aaaaaa-main@example.com-team.json") == ["main@example.com"]
    assert module.quota_targets_from_identity("codex-bbbbbb-second@example.com-team.json") == ["second@example.com"]
    auth_items = [
        {"name": "codex-aaaaaa-main@example.com-team.json", "auth_index": "old", "status": "error"},
        {"name": "codex-bbbbbb-main@example.com-team.json", "auth_index": "new", "status": "active"},
    ]
    preferred = module.find_auth_items_for_target(auth_items, "main@example.com", "codex-bbbbbb-main@example.com-team.json")
    assert [module.auth_item_index(item) for item in preferred][:2] == ["new", "old"]

    db = td_path / "usage.sqlite"
    conn = sqlite3.connect(db)
    conn.execute(
        "create table usage_events ("
        "id integer primary key, timestamp_ms integer, response_metadata_json text, "
        "header_quota_plan_type text, account_snapshot text, auth_label_snapshot text, "
        "auth_file_snapshot text, auth_account_id_snapshot text, raw_json text)"
    )
    metadata = {
        "response_headers": {
            "X-Codex-Plan-Type": ["team"],
            "X-Codex-Primary-Used-Percent": ["25"],
            "X-Codex-Primary-Window-Minutes": ["300"],
            "X-Codex-Primary-Reset-At": ["1788709680"],
            "X-Codex-Secondary-Used-Percent": ["40"],
            "X-Codex-Secondary-Window-Minutes": ["10080"],
            "X-Codex-Secondary-Reset-At": ["1789021920"],
        }
    }
    fixture_rows = (
        (1, "main@example.com", "", "codex-aaaaaa-main@example.com-team.json"),
        (2, "second@example.com", "", "codex-bbbbbb-second@example.com-team.json"),
        (3, "third@example.com", "third@example.com", ""),
    )
    for idx, account, account_snapshot, auth_file_snapshot in fixture_rows:
        conn.execute(
            "insert into usage_events values (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (idx, 1788700000000 + idx, __import__("json").dumps(metadata), "team", account_snapshot, "", auth_file_snapshot, "", ""),
        )
    conn.commit()
    conn.close()
    discovered = module.discover_team_quota_targets(db, 1788700005000)
    assert discovered == ["main@example.com", "second@example.com", "third@example.com"]
    quota_values = []
    configured = {"main@example.com", "second@example.com"}
    for idx, account in enumerate(discovered):
        label = module.quota_display_name(idx, account, {k: v for k, v in remarks.items() if k in configured})
        quota_values.append((label, module.build_account_quota(db, 1788700005000, account, label)))
    payload = module.build_multi_account_quota_payload(1788700005000, quota_values)
    assert payload["account_count"] == 3
    assert len(payload["accounts"]) == 3
    assert payload["accounts"][0]["account"]["display"] == "主力 Team"
    assert payload["accounts"][1]["account"]["display"] == "实验账号"
    assert payload["accounts"][2]["account"]["display"] == "GPT Team 账号 3"
    active_cache = {"accounts": {module.quota_target_hash("main@example.com"): {"target": "main@example.com", "quota": active}}}
    merged = module.choose_quota_value(quota_values[0][1], module.active_quota_from_cache(active_cache, "main@example.com"), "主力 Team")
    assert merged["source"]["kind"] == "active_wham_usage"
    legacy_alias = "codex-aaaaaa-main@example.com-team.json"
    legacy_cache = {"accounts": {module.quota_target_hash(legacy_alias): {"target": legacy_alias, "quota": active, "last_success_ms": 1788700010000}}}
    assert module.active_quota_from_cache(legacy_cache, "main@example.com")["source"]["kind"] == "active_wham_usage"
    payload_text = module.dump_bytes(payload).decode("utf-8")
    assert "main@example.com" not in payload_text
    assert "second@example.com" not in payload_text
    assert "third@example.com" not in payload_text
PY
    then
        error "Rich Data（Reasoning/Quota）数据层自测试失败。"
        rc=1
    fi

    domain=$(public_status_normalize_domain 'Status.Example.COM' 2>/dev/null || true)
    [[ "$domain" == "status.example.com" ]] || { error "域名规范化测试失败。"; rc=1; }
    if public_status_normalize_domain 'https://bad.example.com/path' >/dev/null 2>&1; then
        error "非法域名拒绝测试失败。"
        rc=1
    fi
    ip=$(public_status_normalize_ip_or_cidr '203.0.113.9' 2>/dev/null || true)
    [[ "$ip" == "203.0.113.9/32" ]] || { error "IP 规范化测试失败。"; rc=1; }
    if public_status_normalize_ip_or_cidr '0.0.0.0/0' >/dev/null 2>&1; then
        error "默认路由拒绝测试失败。"
        rc=1
    fi

    printf '192.0.2.0/24\n' > "${tmp_dir}/cn4"
    printf '2001:db8::/32\n' > "${tmp_dir}/cn6"
    printf '203.0.113.9/32\n' > "${tmp_dir}/custom"
    caddy_site="${tmp_dir}/site.caddy"
    if ! public_status_generate_caddy_file "$caddy_site" 'status.example.com' \
        "${tmp_dir}/cn4" "${tmp_dir}/cn6" "${tmp_dir}/custom"; then
        error "Caddy 站点生成测试失败。"
        rc=1
    elif ! grep -Fq 'encode zstd gzip' "$caddy_site" \
        || ! grep -Fq 'Cache-Control "no-cache"' "$caddy_site" \
        || grep -Fq 'no-store' "$caddy_site"; then
        error "Caddy 压缩/条件缓存策略自测试失败。"
        rc=1
    elif command -v caddy >/dev/null 2>&1; then
        test_main="${tmp_dir}/Caddyfile"
        printf 'import %s\n' "$caddy_site" > "$test_main"
        if ! caddy validate --config "$test_main" --adapter caddyfile >/dev/null 2>&1; then
            error "Caddy 语法验证测试失败。"
            rc=1
        fi
    else
        warn "本机没有 caddy，已跳过自测试中的 Caddy parser 检查。"
    fi

    if ! bash -n "${BASH_SOURCE[0]}"; then
        error "脚本 bash -n 自检失败。"
        rc=1
    fi
    rm -rf -- "$tmp_dir"
    if [[ "$rc" == "0" ]]; then
        info "Public Status self-test 全部通过。"
    fi
    return "$rc"
}

public_status_menu() {
    local choice=""

    while true; do
        [[ -t 1 ]] && clear
        printf '\n%b公网只读 Dashboard%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 安装 / 启用（CN + 额外白名单）\n'
        printf '  2. 查看状态\n'
        printf '  3. 添加额外白名单 IP/CIDR\n'
        printf '  4. 删除额外白名单 IP/CIDR\n'
        printf '  5. 立即更新 CN IPv4/IPv6 网段\n'
        printf '  6. 立即生成一份脱敏快照\n'
        printf '  7. 修改域名 / 快照间隔\n'
        printf '  8. 关闭公网 Status（保留配置与数据）\n'
        printf '  9. 运行安全自检\n'
        printf ' 10. GPT Team 额度账号管理\n'
        printf '  0. 返回主菜单\n'
        printf '%s\n' '--------------------------------------------------'
        printf '  说明: 不开放 8317/18317，不新增监听端口；Status 只由 Caddy 提供静态文件。\n'
        printf '%s\n' '--------------------------------------------------'
        if ! read -r -p '请选择 [0-10]: ' choice; then
            return 0
        fi
        case "$choice" in
            1) public_status_install_or_enable; pause_menu ;;
            2) public_status_show_status; pause_menu ;;
            3) public_status_add_allowlist; pause_menu ;;
            4) public_status_remove_allowlist; pause_menu ;;
            5) public_status_command --update-cn; pause_menu ;;
            6) public_status_command --snapshot; pause_menu ;;
            7) public_status_install_or_enable; pause_menu ;;
            8) public_status_disable; pause_menu ;;
            9) public_status_self_test; pause_menu ;;
            10) public_status_quota_menu ;;
            0|q|Q) return 0 ;;
            *) warn "无效选项，请重新输入。"; sleep 1 ;;
        esac
    done
}

public_status_command() {
    local action="${1:---menu}"

    case "$action" in
        --menu|menu) public_status_menu ;;
        --status|status) public_status_show_status ;;
        --snapshot|snapshot)
            if running_in_systemd_unit "$PUBLIC_STATUS_SERVICE"; then
                public_status_snapshot
            else
                public_status_start_controlled_job "$PUBLIC_STATUS_SERVICE"
            fi
            ;;
        --snapshot-direct)
            require_systemd_unit_invocation --snapshot-direct "$PUBLIC_STATUS_SERVICE" \
                || return 1
            public_status_snapshot
            ;;
        --update-cn|update-cn)
            if running_in_systemd_unit "$PUBLIC_STATUS_CN_SERVICE"; then
                public_status_update_cn
            else
                public_status_start_controlled_job "$PUBLIC_STATUS_CN_SERVICE"
            fi
            ;;
        --update-cn-direct)
            require_systemd_unit_invocation --update-cn-direct "$PUBLIC_STATUS_CN_SERVICE" \
                || return 1
            public_status_update_cn
            ;;
        --self-test|self-test) public_status_self_test ;;
        --quota-refresh|quota-refresh)
            if running_in_systemd_unit "$PUBLIC_STATUS_QUOTA_SERVICE"; then
                public_status_quota_refresh
            else
                public_status_start_controlled_job "$PUBLIC_STATUS_QUOTA_SERVICE"
            fi
            ;;
        --quota-refresh-direct)
            require_systemd_unit_invocation --quota-refresh-direct "$PUBLIC_STATUS_QUOTA_SERVICE" \
                || return 1
            public_status_quota_refresh
            ;;
        --quota-menu|quota-menu) public_status_quota_menu ;;
        --enable|enable|--install|install) public_status_install_or_enable ;;
        --disable|disable) public_status_disable ;;
        *)
            error "未知 Public Status 参数：${action}"
            printf '用法: cpa public-status [--status|--snapshot|--update-cn|--self-test|--quota-refresh|--quota-menu|--enable|--disable]\n'
            return 2
            ;;
    esac
}

cpamp_maintenance_menu() {
    local choice="" answer="" rc=0

    while true; do
        [[ -t 1 ]] && clear
        printf '\n%bCPAMP 数据库维护%b\n' "$BOLD" "$NC"
        printf '%s\n' '--------------------------------------------------'
        printf '  1. 查看数据库维护状态/诊断\n'
        printf '  2. 立即检查并执行维护（需要时才停机）\n'
        printf '  3. 检测并安排凌晨 04:00 自动维护\n'
        printf '  4. 查看凌晨维护任务\n'
        printf '  5. 取消凌晨维护任务\n'
        printf '  6. 设置/更新维护 Admin Key\n'
        printf '  7. 清除维护 Admin Key\n'
        printf '  0. 返回主菜单\n'
        printf '%s\n' '--------------------------------------------------'
        printf '  提示: 立即维护会先检查 required 状态；只有确实需要维护时才停止 CPAMP。\n'
        printf '        执行维护前会自动创建一致性数据备份，完成后恢复原服务状态。\n'
        printf '%s\n' '--------------------------------------------------'

        if ! read -r -p '请选择 [0-7]: ' choice; then
            return 0
        fi

        case "$choice" in
            1)
                cpamp_maintenance_diagnose
                pause_menu
                ;;
            2)
                printf '\n%b立即维护说明%b\n' "$YELLOW" "$NC"
                printf '  脚本会先读取 databaseMaintenance 状态。\n'
                printf '  required=false: 不停机、不执行维护。\n'
                printf '  required=true:  停止 CPAMP -> 备份 -> cleanup-derived -> 恢复 CPAMP。\n\n'
                read -r -p '确认现在检查并在需要时立即维护 [y/N]: ' answer || return 0
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    cpamp_maintenance_command --run-now || true
                else
                    warn '已取消立即维护。'
                fi
                pause_menu
                ;;
            3)
                check_and_schedule_cpamp_maintenance
                rc=$?
                if [[ "$rc" == "0" ]]; then
                    show_cpamp_maintenance_timer
                fi
                pause_menu
                ;;
            4)
                if [[ -f "$CPAMP_MAINT_PENDING" ]]; then
                    printf '\n待维护标记:\n'
                    sed 's/^/  /' "$CPAMP_MAINT_PENDING" 2>/dev/null || true
                    printf '\n定时任务:\n'
                    systemctl list-timers "$CPAMP_MAINT_TIMER" --all --no-pager 2>/dev/null \
                        || warn '无法读取维护 timer 状态。'
                else
                    info '当前没有待执行的凌晨 CPAMP 数据库维护任务。'
                    if systemctl is-active --quiet "$CPAMP_MAINT_TIMER" 2>/dev/null; then
                        warn '维护 timer 仍处于 active，但没有待维护标记；建议选择 5 清理该任务。'
                    fi
                fi
                pause_menu
                ;;
            5)
                if [[ ! -f "$CPAMP_MAINT_PENDING" ]] \
                    && ! systemctl is-active --quiet "$CPAMP_MAINT_TIMER" 2>/dev/null; then
                    info '当前没有需要取消的凌晨维护任务。'
                else
                    read -r -p '确认取消凌晨 CPAMP 数据库维护任务 [y/N]: ' answer || return 0
                    if [[ "$answer" =~ ^[Yy]$ ]]; then
                        clear_cpamp_maintenance_schedule
                        info '已取消凌晨 CPAMP 数据库维护任务；数据库数据未被修改。'
                    else
                        warn '已取消操作。'
                    fi
                fi
                pause_menu
                ;;
            6)
                cpamp_maintenance_set_admin_key || true
                pause_menu
                ;;
            7)
                read -r -p '确认删除维护脚本专用 Admin Key [y/N]: ' answer || return 0
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    cpamp_maintenance_clear_admin_key || true
                else
                    warn '已取消操作。'
                fi
                pause_menu
                ;;
            0|q|Q)
                return 0
                ;;
            *)
                warn '无效选项，请重新输入。'
                sleep 1
                ;;
        esac
    done
}

show_menu() {
    local choice=""

    while true; do
        [[ -t 1 ]] && clear
        printf '%b' "$CYAN"
        printf '%s\n' '=================================================='
        printf '              CPA 部署与运维菜单  v%s\n' "$SCRIPT_VERSION"
        printf '%s\n' '=================================================='
        cat <<'EOF'
  1. 部署/重装 CPA
  2. 当前工作状态
  3. 流量统计
  4. 更新 CPA + CPAMP 到最新版本
  5. 导出请求日志
  6. 日志存储清理
  7. Fail2Ban 安全管理
  8. CPAMP 数据库维护
  9. 公网只读 Dashboard
  10. 准入与并发管理
  0. 退出
==================================================
EOF
        printf '%b' "$NC"
        if ! read -r -p '请输入选项 [0-10]: ' choice; then
            printf '\n已退出。\n'
            return 0
        fi

        case "$choice" in
            1) admission_with_lock deployment_menu; pause_menu ;;
            2) show_status; pause_menu ;;
            3) show_traffic; pause_menu ;;
            4) admission_with_lock update_all_components 0; pause_menu ;;
            5) export_request_logs; pause_menu ;;
            6) log_cleanup_menu; pause_menu ;;
            7) fail2ban_management_menu; pause_menu ;;
            8) cpamp_maintenance_menu ;;
            9) public_status_menu ;;
            10) admission_menu ;;
            0|q|Q) printf '已退出。\n'; return 0 ;;
            *) warn "无效选项，请重新输入。"; sleep 1 ;;
        esac
    done
}

main() {
    local command="${1:-menu}"
    local yes=0

    case "$command" in
        help|-h|--help)
            usage
            return 0
            ;;
        version|--version)
            printf 'cpa management script v%s\n' "$SCRIPT_VERSION"
            return 0
            ;;
    esac

    become_root "$@"
    initialize_resource_profile
    case "$command" in
        menu|deploy|reinstall|status|resource-guard|resources|admission|update|install|--install)
            admission_load_settings || die "准入配置无效，请修正 ${ADMISSION_CONFIG} 后重试。"
            ;;
    esac

    case "$command" in
        menu)
            show_menu
            ;;
        deploy|reinstall)
            admission_with_lock deployment_menu
            ;;
        status)
            show_status
            ;;
        traffic|stats)
            show_traffic
            ;;
        export-logs|export)
            export_request_logs
            ;;
        log-cleanup|cleanup-logs)
            log_cleanup_menu
            ;;
        fail2ban|2ban)
            fail2ban_management_menu
            ;;
        cpamp-maintenance|cpamp-db-maintenance)
            cpamp_maintenance_command "${2:---check}"
            ;;
        prune-logs)
            if [[ "${2:-}" == "--scheduled" ]]; then
                run_scheduled_log_cleanup
            else
                prune_log_storage "${2:-}"
            fi
            ;;
        public-status)
            shift
            public_status_command "$@"
            ;;
        resource-guard|resources)
            resource_guard_command "${2:---status}"
            ;;
        admission)
            admission_command "${2:-menu}"
            ;;
        update)
            [[ "${2:-}" == "-y" || "${2:-}" == "--yes" ]] && yes=1
            admission_with_lock update_all_components "$yes"
            ;;
        install|--install)
            admission_with_lock install_self
            ;;
        *)
            error "未知命令: $command"
            usage
            return 2
            ;;
    esac
}

if [[ "${CPA_DEPLOY_LIBRARY_ONLY:-0}" != "1" ]]; then
    main "$@"
fi
