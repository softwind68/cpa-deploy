# 参与贡献

本项目保留单文件部署方式，优先提交小范围、可回滚、可离线验证的修改。不要在同一个 PR 中混合大规模格式调整与部署逻辑变更。

## 提交前

```bash
bash -n cpa-deploy.sh
bash -n tests/smoke.sh
python3 -B tools/scan_release.py
python3 -B -m unittest discover -s tests -v
bash tests/smoke.sh
```

源码使用 UTF-8 无 BOM、LF 换行。Bash 中的内嵌 Python、HTML、CSS 和 JavaScript 都是可执行交付内容，修改时必须同时检查对应语法及数据接口。

## 测试数据

邮箱使用 `example.com`、`example.net` 或 `example.org`；IPv4 使用文档示例网段；账号文件名前缀使用虚构十六进制值。不要从自己的机器复制授权文件、真实账号或数据库作为夹具。

密钥扫描测试请动态拼接合成令牌，避免将完整令牌形状写入仓库并触发发布检查。不要为了让检查通过而添加真实秘密白名单。

## 风险较高的修改

修改服务单元、文件权限、端口、数据库维护、准入配置或更新流程时，需要在可重建的 systemd Linux 虚拟机中验证成功与失败路径，包括中断、回滚及原停止状态恢复。离线测试通过不代表这些路径已经验收。

修改状态 JSON 时，使用允许字段列表，加入禁止字段或秘密注入测试。新字段默认视为私有，不要直接透传上游对象。

## PR 说明

说明变更目的、影响范围、测试环境、实际执行的测试与未覆盖事项。截图和输出必须脱敏。安全漏洞按 SECURITY.md 私下报告。
