## 变更

说明修改内容及原因。

## 验证

- [ ] 已执行 `bash -n cpa-deploy.sh` 和 `bash -n tests/smoke.sh`
- [ ] 已执行 `python3 -B tools/scan_release.py`
- [ ] 已执行 `python3 -B -m unittest discover -s tests -v`
- [ ] 已执行 `bash tests/smoke.sh`
- [ ] 未加入密钥、账号、数据库、原始日志或真实部署配置
- [ ] 涉及服务、端口、回滚或权限时，已在隔离 Linux 虚拟机验证
