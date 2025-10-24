# Commands Reference / 命令参考

Complete reference for all Makefile commands.

完整的 Makefile 命令参考。

---

## 📚 Table of Contents / 目录

- [Setup & Configuration](#setup--configuration-设置和配置)
- [Installation](#installation-安装)
- [Upgrade](#upgrade-升级)
- [Backup](#backup-备份)
- [Uninstall](#uninstall-卸载)
- [Check & Test](#check--test-检查和测试)
- [Utilities](#utilities-工具)
- [Information](#information-信息查询)

---

## Setup & Configuration / 设置和配置

### `make setup [k3s|rke2]`

Initialize configuration files / 初始化配置文件

**Examples / 示例:**

```bash
# Auto-configure K3S cluster
make setup k3s

# Auto-configure RKE2 cluster
make setup rke2

# Manual configuration
make setup
```

**What it does / 功能:**
- Creates `inventory/hosts.ini` from example / 创建主机清单
- Creates `inventory/group_vars/all.yml` from example / 创建全局变量
- Auto-configures cluster_type and china_region / 自动配置集群类型和中国镜像

---

## Installation / 安装

### `make install`

Install RKE2/K3S cluster (standard installation) / 安装集群（标准模式）

```bash
make install
```

### `make install-china`

Install with China mirror acceleration / 中国大陆安装（启用镜像加速）

```bash
make install-china
```

### `make install-k3s`

Install K3S cluster / 安装 K3S 集群

```bash
make install-k3s
```

### `make install-rke2`

Install RKE2 cluster / 安装 RKE2 集群

```bash
make install-rke2
```

**Custom parameters / 自定义参数:**

```bash
# Use custom inventory
INVENTORY=inventory/prod.ini make install

# Add verbose output
EXTRA_ARGS='-vvv' make install

# Install specific version
EXTRA_ARGS='-e install_version=v1.28.5+rke2r1' make install
```

---

## Upgrade / 升级

### `make upgrade`

Upgrade cluster to new version (with confirmation) / 升级集群到新版本（需要确认）

```bash
make upgrade
```

**What it does / 功能:**
- Shows pre-upgrade warnings / 显示升级前警告
- Requires confirmation / 需要确认
- Performs rolling upgrade (Server nodes → Agent nodes) / 滚动升级
- Auto-creates backup before upgrade / 升级前自动备份

### `make upgrade-continue`

Continue interrupted upgrade (no confirmation needed) / 继续中断的升级（无需确认）

```bash
make upgrade-continue
```

**Use cases / 使用场景:**
- Network interruption during upgrade / 升级过程中网络中断
- Manual interruption (Ctrl+C) / 手动中断
- Ansible connection timeout / Ansible 连接超时

### `make upgrade-force`

Force re-upgrade all nodes (no confirmation) / 强制重新升级所有节点（无需确认）

```bash
make upgrade-force
```

**Warning / 警告:** This will re-upgrade ALL nodes, even if already upgraded / 将重新升级所有节点

---

## Backup / 备份

### `make backup`

Backup etcd data from all Server nodes / 备份所有 Server 节点的 etcd 数据

```bash
make backup
```

**Backup location / 备份位置:**
- RKE2: `/var/lib/rancher/rke2/server/db/snapshots/`
- K3S: `/var/lib/rancher/k3s/server/db/snapshots/`

### `make check-backup`

Check backup status / 检查备份状态

```bash
make check-backup
```

---

## Uninstall / 卸载

### `make uninstall`

Completely uninstall cluster (dangerous!) / 完全卸载集群（危险操作！）

```bash
make uninstall
# Type 'yes' to confirm
```

**What it removes / 删除内容:**
- Services and processes / 服务和进程
- Configuration files / 配置文件
- Data directories / 数据目录
- Network interfaces / 网络接口
- Binary files / 二进制文件
- Systemd service files / Systemd 服务文件
- CNI plugins / CNI 插件

### `make verify-uninstall`

Verify uninstall cleanup / 验证卸载清理结果

```bash
make verify-uninstall
```

### `make cleanup-systemd`

Clean up residual systemd service files / 清理残留的 systemd 服务文件

```bash
make cleanup-systemd
```

---

## Check & Test / 检查和测试

### `make check`

Check all node status (equivalent to: make ping status) / 检查所有节点状态

```bash
make check
```

### `make ping`

Test Ansible connectivity / 测试 Ansible 连接

```bash
make ping
```

### `make status`

Get cluster status (kubectl get nodes) / 获取集群状态

```bash
make status
```

### `make pods`

View all pods (kubectl get pods -A) / 查看所有 Pod

```bash
make pods
```

### `make test`

Dry-run test (check mode) / 干跑测试

```bash
make test
```

### `make lint`

Check YAML syntax / 检查 YAML 语法

```bash
make lint
```

### `make validate`

Validate inventory configuration / 验证 Inventory 配置

```bash
make validate
```

---

## Utilities / 工具

### `make clean`

Clean temporary files / 清理临时文件

```bash
make clean
```

**What it removes / 删除内容:**
- `*.retry` files
- `__pycache__` directories
- `*.log` files
- Token files in `/tmp/`

### `make reset`

Reset repository to initial state (deletes all local config) / 重置仓库到初始状态

```bash
make reset
# Type 'yes' to confirm
```

**Warning / 警告:** This will delete:
- `inventory/hosts.ini`
- `inventory/group_vars/all.yml`
- All temporary files

---

## Information / 信息查询

### `make info`

Display cluster information / 显示集群信息

```bash
make info
```

### `make version`

Display installed version / 显示已安装版本

```bash
make version
```

### `make logs`

View service logs / 查看服务日志

```bash
make logs
```

### `make help`

Display help information / 显示帮助信息

```bash
make help
```

---

## Advanced Usage / 高级用法

### Custom Inventory / 自定义 Inventory

```bash
# Use custom inventory file
INVENTORY=inventory/prod.ini make install

# Use custom directory
INVENTORY=~/k8s/hosts.ini make install
```

### Extra Arguments / 额外参数

```bash
# Verbose output (debug mode)
EXTRA_ARGS='-vvv' make install

# Limit to specific hosts
EXTRA_ARGS='--limit master1' make upgrade

# Use specific tags
EXTRA_ARGS='--tags install' make install

# Multiple arguments
EXTRA_ARGS='-vvv --check --diff' make test
```

### Combined Operations / 组合操作

```bash
# Setup and install in one go
make setup rke2 && make ping && make install

# Backup before upgrade
make backup && make upgrade

# Verify after installation
make install && make status && make pods
```

---

## Troubleshooting / 故障排查

### Connection Issues / 连接问题

```bash
# Test basic connectivity
make ping

# Test with verbose output
EXTRA_ARGS='-vvv' make ping

# Check inventory configuration
make validate
```

### Installation Failures / 安装失败

```bash
# Check YAML syntax
make lint

# Dry-run test
make test

# Install with debug output
EXTRA_ARGS='-vvv' make install
```

### Upgrade Issues / 升级问题

```bash
# If upgrade interrupted
make upgrade-continue

# Force re-upgrade
make upgrade-force

# Check service logs
make logs
```

---

## Best Practices / 最佳实践

1. **Always backup before upgrade / 升级前务必备份**
   ```bash
   make backup && make upgrade
   ```

2. **Test connectivity first / 先测试连接**
   ```bash
   make ping && make install
   ```

3. **Use dry-run for testing / 使用干跑测试**
   ```bash
   make test
   ```

4. **Verify after operations / 操作后验证**
   ```bash
   make install && make status
   ```

5. **Keep configuration in version control / 配置文件版本控制**
   ```bash
   git add inventory/
   git commit -m "Update cluster configuration"
   ```

---

## Quick Reference / 快速参考

| Command | Description | 命令 | 描述 |
|---------|-------------|------|------|
| `make setup [k3s\|rke2]` | Initialize config | 初始化配置 | 创建配置文件 |
| `make ping` | Test connection | 测试连接 | Ansible 连接测试 |
| `make install` | Install cluster | 安装集群 | 标准安装 |
| `make install-china` | China installation | 中国安装 | 启用镜像加速 |
| `make upgrade` | Upgrade cluster | 升级集群 | 需要确认 |
| `make upgrade-continue` | Continue upgrade | 继续升级 | 无需确认 |
| `make backup` | Backup etcd | 备份 etcd | 备份数据 |
| `make uninstall` | Uninstall cluster | 卸载集群 | 完全删除 |
| `make status` | Cluster status | 集群状态 | kubectl get nodes |
| `make pods` | View pods | 查看 Pod | kubectl get pods -A |
| `make logs` | View logs | 查看日志 | journalctl |
| `make clean` | Clean temp files | 清理文件 | 临时文件 |
| `make help` | Show help | 显示帮助 | 所有命令 |

---

**Last Updated:** 2025-10-22
**Role Name:** rancher_cluster (formerly rke_k3s)

