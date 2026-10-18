# 第三方项目与服务

本仓库提供部署编排脚本，不包含下列项目的二进制安装包、运行数据库、真实配置或账号凭据。脚本运行时会按需下载软件，下载后的组件仍受各自许可证及条款约束。

| 项目或服务 | 用途 | 官方来源 |
| --- | --- | --- |
| CLIProxyAPI | 被部署的网关组件 | [仓库](https://github.com/router-for-me/CLIProxyAPI) / [LICENSE](https://github.com/router-for-me/CLIProxyAPI/blob/main/LICENSE) |
| CPA-Manager-Plus | 管理与用量数据 | [仓库](https://github.com/seakee/CPA-Manager-Plus) / [LICENSE](https://github.com/seakee/CPA-Manager-Plus/blob/main/LICENSE) |
| Caddy | HTTPS 与反向代理 | [项目](https://github.com/caddyserver/caddy) / [安装文档](https://caddyserver.com/docs/install) |
| systemd | 服务、socket 代理、timer 和资源控制 | [项目](https://github.com/systemd/systemd) |
| Fail2Ban | 访问日志规则与封禁管理 | [项目](https://github.com/fail2ban/fail2ban) |
| IPdeny | CN IPv4/IPv6 地址段 | [数据来源](https://www.ipdeny.com/ipblocks/) |
| ipify / ifconfig.me | 完整部署时辅助探测公网 IP | [ipify](https://www.ipify.org/) / [ifconfig.me](https://ifconfig.me/) |
| GitHub Actions checkout | CI 检出当前提交 | [固定版本源码](https://github.com/actions/checkout/tree/11bd71901bbe5b1630ceea73d27597364c9af683) |

截至 2026-10-18 核对的 CLIProxyAPI 与 CPA-Manager-Plus 官方 LICENSE 文件均为 MIT；实际下载版本应以对应版本随附的许可为准。不得因本脚本使用 MIT 而删除上游版权或将其他依赖的许可证改为 MIT。重新分发上游二进制、容器镜像或大量源码时，需要单独整理对应的许可与通知文件。

脚本可选的账号额度刷新使用提供方相关接口，由上游管理 API 代为调用，不包含真实令牌；接口不保证长期稳定。本项目不授予第三方账号使用权，也不表示任何第三方服务提供方认可或背书。

发布者应确认原有单文件及内嵌前端资源的代码来源；当前发布包不能替代代码权属审查。
