# CPA Deploy

面向 Debian / Ubuntu 的 CLIProxyAPI 与 CPA-Manager-Plus 部署、更新和日常运维工具。

**版本：2.44-oss.1 | Bash | MIT | 中文交互菜单**

本项目不是新的模型服务或 API 实现，而是围绕上游组件的运维工具。保留单文件分发方式，在一份脚本中管理网关、管理面板、HTTPS 入口、并发准入、资源限制和只读状态页。

> 此脚本需要 root 权限，会安装软件包并修改 systemd、Caddy、Fail2Ban 和 `/opt` 下的文件。首次使用请在可重建的 Linux 虚拟机中验证，备份现有配置与授权文件。不要直接在重要生产主机上试运行。

## 功能

| 能力 | 实现与边界 |
| --- | --- |
| 部署与重装 | 支持完整栈、仅 CPA、仅 CPAMP；针对已有配置保留数据并进行兼容处理 |
| 校验与更新 | 按 CPU 架构匹配上游 Release，校验 SHA-256，验证候选二进制，更新失败时尝试恢复 |
| HTTPS 入口 | 使用 Caddy；公开 API 入口屏蔽管理路径；管理面板默认仅监听回环地址 |
| 并发准入 | 普通入口、可选高并发入口及共享上限；通过 systemd socket/proxy 管理活动连接 |
| 资源保护 | 按内存档位生成 systemd 限额和 Go 内存限制，并检查实际生效值 |
| 数据库维护 | 检测 CPAMP 维护需求，支持定时或手动维护、维护前备份及服务恢复 |
| 只读状态页 | 本机认证取数，白名单生成静态 JSON；提供历史、调用、模型及账号配额视图 |
| 日常运维 | 流量统计、日志保留与导出、Fail2Ban 管理、状态诊断 |

并发上限是**活动代理连接数**，不是 QPS、模型任务数、账号额度、公平排队或整机总连接数。SHA-256 校验也不等于独立签名认证。更多设计说明见 [架构与边界](docs/ARCHITECTURE.md)。

## 运行条件

- Linux、systemd、apt；目标环境为 Debian 12+ / Ubuntu 22.04+。
- CPU：`x86_64/amd64` 或 `aarch64/arm64`。
- Bash 4.3+、Python 3.10+。部署过程会按需安装 curl、jq、OpenSSL、Python 等依赖。
- 资源保护依赖主机实际支持的 cgroup/systemd 功能，请通过状态命令确认，不要只看配置文件。
- 建议从 2 GiB 内存的测试主机起步，并按实际负载压测；低内存档位不代表任何容量保证。
- 完整部署需能访问上游 GitHub Release、系统软件源和 Caddy 软件源。
- HTTPS 域名需正确解析到服务器；按部署需求开放 TCP 80/443。不要把本机后端端口暴露到公网。

上述为目标条件，不是已完成的发行版或 CPU 兼容认证。离线测试不能代替真实 systemd 主机上的部署验收。

## 快速开始

从本仓库下载或克隆源码后，在仓库目录执行：

```bash
# 以下两条不需要 root，不会进行部署
bash ./cpa-deploy.sh version
bash ./cpa-deploy.sh help

# 进入部署菜单，按需选择完整栈或单个组件
sudo bash ./cpa-deploy.sh deploy
```

成功部署时脚本会安装 `/usr/local/bin/cpa`，后续使用：

```bash
sudo cpa
sudo cpa status
sudo cpa admission --status
sudo cpa resource-guard --status
```

已有环境仅升级管理脚本时，在完成备份后执行：

```bash
sudo bash ./cpa-deploy.sh install
```

`install` 不只是复制文件，也可能迁移准入配置、更新状态页 helper、资源单元和前端。`update` 更新的是 CPA/CPAMP 上游组件，不会自动从本仓库拉取新版管理脚本。

不要使用未经审查的 `curl | bash`。生产环境应固定已审核的仓库版本，并记录实际安装的上游版本。

## 密钥与管理

首次配置的密钥隐藏输入，留空使用安全随机生成值。确认部署后，先将本次输入写入 `/etc/cpa-deploy-credentials.conf`（root:root，0600），保存失败则不继续部署。它保留管理密钥被上游哈希前的原值；部署摘要只显示文件位置，不显示密钥。

在受信任的服务器终端，以 root 身份查看该文件并存入自己的密钥管理器。此文件含明文秘密，不能分享；它记录初始/最近输入，部署失败、手工修改或面板轮换后不保证等于当前生效值。完成安全保管后可自行删除此记录。其他相关位置：

- CPA 客户端密钥：`/opt/cpa/config.yaml` 的 `api-keys`。
- CPA 管理密钥：同一文件的 `remote-management.secret-key` 可能是哈希，不能将哈希作为原密钥使用；原值见私有初始记录。
- CPAMP 初始化管理密钥：`/opt/cpamp/.env`；在面板内修改后，此文件不一定代表当前有效值。
- 维护专用密钥：通过 `sudo cpa cpamp-maintenance --set-admin-key` 隐藏输入并验证。

授权账号、OAuth 文件、数据库、配置、原始日志和备份都属于运行数据，**不能提交到此仓库**。具体注意事项见 [SECURITY.md](SECURITY.md)。

CPAMP 默认使用 SSH 隧道访问，不需公开管理端口：

```bash
# 在自己的电脑上运行；替换下面的示例用户名与地址
ssh -L 18317:127.0.0.1:18317 user@server.example.com
```

随后访问 `http://127.0.0.1:18317/management.html`。

不填域名时完整部署可能使用明文 HTTP。该方式仅适用于受控测试网络；公网生产使用域名与 HTTPS。

## 常用命令

| 命令 | 用途 |
| --- | --- |
| `cpa deploy` | 部署或重装菜单 |
| `cpa status` / `cpa traffic` | 服务与流量状态 |
| `cpa update` | 交互确认后更新上游 CPA/CPAMP |
| `cpa export-logs` | 按时间范围导出日志 |
| `cpa log-cleanup` | 日志保留策略与清理 |
| `cpa fail2ban` | 封禁、白名单和触发条件 |
| `cpa admission` | 准入参数、入口域名与预设管理 |
| `cpa resource-guard --status` | 检查资源保护状态 |
| `cpa cpamp-maintenance --diagnose` | 维护诊断，不显示管理密钥 |
| `cpa public-status` | 状态页安装与管理菜单 |
| `cpa public-status --self-test` | 已安装环境的状态页自测 |

除 `help` / `version` 外，以上命令一般需要 root 权限。不要用内部 `--*-direct` 命令绕过受控 systemd 任务。

## 状态页与日志隐私

状态页是独立静态页面，不将 CPAMP 管理端直接反代到公网。默认使用 CN 地址段加自定义 IP 白名单限制访问。**地域/IP 白名单不是身份认证**；统计、费用、模型和人工备注仍可能属于业务隐私。需要更严格隔离时，在网络层或独立访问控制层加认证。

账号配额功能可在菜单配置，并包含自动发现和可选的主动刷新。它依赖上游及提供方接口，可能随其变更失效，也可能产生额外请求。只管理自己有权使用的账号，不需要时关闭主动刷新。

日志导出去除认证头、Cookie 和查询参数，但仍保留客户端 IP、Host、路径和 User-Agent；路径本身也可能包含敏感值。**导出包不是匿名数据，不能直接作为公开 Issue 附件。**

## 本地验证

离线检查需要 Bash、Python 3.10+、Node.js、jq 和 OpenSSL，不会部署服务或访问真实账号：

```bash
bash -n cpa-deploy.sh
bash -n tests/smoke.sh
python3 -B tools/scan_release.py
python3 -B -m unittest discover -s tests -v
bash tests/smoke.sh
```

测试覆盖发布文件隐私规则、嵌入 Python/JavaScript 语法、原有额度/SQLite 回归、密钥生成失败路径、提示及摘要不泄密、私有凭据记录、配置不执行、维护认证头和状态 JSON 白名单。

GitHub Actions 已配置 Ubuntu 22.04 / 24.04 离线检查。工作流是否通过，以实际 GitHub 运行结果为准。

## 目录

```text
cpa-deploy.sh                 单文件部署及运维入口
docs/ARCHITECTURE.md          结构、数据流与限制
docs/HIGHLIGHTS.md            项目亮点与适用范围
docs/RELEASING.md             发布与真实主机验收清单
tests/                       离线回归
tools/scan_release.py         发布树隐私/密钥模式检查
.github/                     CI 与问题模板
```

## 贡献与许可

提交前阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题请遵循 [SECURITY.md](SECURITY.md)，不要在公开 Issue 中发送密钥或利用细节。

本发行包使用 [MIT](LICENSE) 许可，适用于有权授权的本项目脚本、测试及文档。发布者仍需确认既有代码与内嵌资源的权属；外部组件保留各自许可，详见 [第三方说明](THIRD_PARTY_NOTICES.md)。本项目不代表上游或任何模型服务提供方。
