# systemd 服务文件清理指南

## 问题描述

在卸载 RKE2/K3S 集群后，可能会发现残留的 systemd 服务单元文件在 `/usr/local/lib/systemd/system/` 目录中。这些文件虽然服务已停止，但仍然存在于系统中。

### 典型表现

```bash
$ systemctl list-unit-files | grep rke2
rke2-server.service    disabled
rke2-agent.service     disabled
```

服务文件位置：
```
/usr/local/lib/systemd/system/rke2-server.service
/usr/local/lib/systemd/system/rke2-agent.service
```

## 原因分析

RKE2 的官方安装脚本将 systemd 服务文件安装到 `/usr/local/lib/systemd/system/`，而不是常规的 `/etc/systemd/system/` 或 `/usr/lib/systemd/system/`。

之前的卸载脚本没有包含这个路径，导致服务文件残留。

## 解决方案

### 方案 1：使用 Makefile 命令（推荐）

清理所有节点上的残留服务文件：

```bash
cd /mnt/d/Nextcloud/Documents/doocom/CICD/Ranche\ Kubernetes
make cleanup-systemd
```

这将：
1. 停止并禁用所有 RKE2/K3S 服务
2. 删除所有路径中的服务文件（包括 `/usr/local/lib/systemd/system/`）
3. 重新加载 systemd
4. 显示清理结果

### 方案 2：使用 Ansible Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/cleanup-systemd.yml
```

### 方案 3：使用清理脚本（单节点）

在需要清理的节点上执行：

```bash
# 复制脚本到目标节点
scp scripts/cleanup-systemd-services.sh user@node:/tmp/

# 在目标节点执行
ssh user@node
sudo bash /tmp/cleanup-systemd-services.sh
```

### 方案 4：手动清理

在每个节点上手动执行：

```bash
# 停止并禁用服务
sudo systemctl stop rke2-server rke2-agent k3s k3s-agent 2>/dev/null || true
sudo systemctl disable rke2-server rke2-agent k3s k3s-agent 2>/dev/null || true

# 删除服务文件
sudo rm -f /etc/systemd/system/rke2-*.service
sudo rm -f /etc/systemd/system/k3s*.service
sudo rm -f /usr/lib/systemd/system/rke2-*.service
sudo rm -f /usr/lib/systemd/system/k3s*.service
sudo rm -f /usr/local/lib/systemd/system/rke2-*.service
sudo rm -f /usr/local/lib/systemd/system/k3s*.service

# 重新加载 systemd
sudo systemctl daemon-reload
```

## 验证清理结果

清理完成后，运行验证脚本：

```bash
make verify-uninstall
```

预期输出：

```
========================================
✓ 验证通过！系统已完全清理
========================================
```

或者手动验证：

```bash
# 检查服务文件是否还存在
ansible -i inventory/hosts.ini all -b -m shell -a "systemctl list-unit-files | grep -E '(rke2|k3s)' || echo '无残留服务'"

# 检查文件系统
ansible -i inventory/hosts.ini all -b -m shell -a "find /etc/systemd /usr/lib/systemd /usr/local/lib/systemd -name '*rke2*' -o -name '*k3s*' 2>/dev/null || echo '无残留文件'"
```

## systemd 服务文件路径对比

不同发行版和安装方式可能使用不同的路径：

| 路径 | 用途 | 优先级 |
|------|------|--------|
| `/etc/systemd/system/` | 管理员自定义服务 | 最高 |
| `/run/systemd/system/` | 运行时临时服务 | 中 |
| `/usr/lib/systemd/system/` | 系统包管理器服务 | 低 |
| `/usr/local/lib/systemd/system/` | 本地安装服务（RKE2 默认） | 低 |

RKE2 选择 `/usr/local/lib/systemd/system/` 是因为：
- 不与系统包管理器冲突
- 适合非包管理器安装的软件
- 遵循 FHS（文件系统层次标准）

## 已修复的问题

### 修复内容

1. **更新卸载 playbook** (`playbooks/uninstall.yml`)
   - 添加 `/usr/local/lib/systemd/system/` 路径
   - 现在清理所有三个 systemd 路径

2. **创建专用清理 playbook** (`playbooks/cleanup-systemd.yml`)
   - 独立的清理工具
   - 可单独运行，不需要完整卸载

3. **添加 Makefile 命令** (`make cleanup-systemd`)
   - 快捷命令
   - 自动处理所有节点

4. **创建清理脚本** (`scripts/cleanup-systemd-services.sh`)
   - 可在单个节点上独立运行
   - 不依赖 Ansible

### 后续部署

修复后，以后的卸载操作将自动清理所有路径的服务文件。

## 工作流程

### 完整的卸载和验证流程

```bash
# 1. 卸载集群
make uninstall

# 2. (可选) 清理残留的 systemd 服务文件
make cleanup-systemd

# 3. 验证清理结果
make verify-uninstall

# 4. (如果验证通过) 重新部署
make install
```

### 故障排查流程

如果 `make verify-uninstall` 仍然报错：

```bash
# 1. 查看详细错误
make verify-uninstall EXTRA_ARGS='-vvv'

# 2. 清理 systemd 服务文件
make cleanup-systemd

# 3. 重启节点（可选，确保彻底清理）
ansible -i inventory/hosts.ini all -b -m reboot

# 4. 重新验证
make verify-uninstall
```

## 参考文档

- [systemd 文档](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
- [FHS 文件系统层次标准](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [RKE2 安装文档](https://docs.rke2.io/install/methods/)
- [K3S 安装文档](https://docs.k3s.io/installation)

