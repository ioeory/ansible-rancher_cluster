# RKE2 vs K3S 对比指南

## 快速选择指南

```
┌──────────────────┬─────────────────────────────────────────────┐
│ 使用场景         │ 推荐选择                                    │
├──────────────────┼─────────────────────────────────────────────┤
│ 生产环境         │ RKE2 ✅                                     │
│ 合规要求         │ RKE2 ✅ (FIPS 140-2, CIS)                  │
│ 企业级应用       │ RKE2 ✅                                     │
│ 边缘计算         │ K3S ✅                                      │
│ IoT 设备         │ K3S ✅                                      │
│ 开发测试         │ K3S ✅                                      │
│ 低资源环境       │ K3S ✅ (< 512MB 内存)                      │
│ 快速原型         │ K3S ✅                                      │
└──────────────────┴─────────────────────────────────────────────┘
```

## 核心差异对比

### 1. 架构和设计

| 特性 | RKE2 | K3S |
|------|------|-----|
| 定位 | 企业级 Kubernetes 发行版 | 轻量级 Kubernetes 发行版 |
| 设计目标 | 生产就绪、安全合规 | 简单、轻量、快速部署 |
| 维护方 | SUSE (Rancher) | SUSE (Rancher) |
| 二进制文件 | 多个组件分离 | 单个二进制文件 |
| 安装大小 | ~2GB | ~60MB |
| 内存占用 | 1-2GB | < 512MB |

### 2. 端口配置 ⚠️ **重要区别**

| 用途 | RKE2 | K3S |
|------|------|-----|
| **Server Join 端口** | **9345** | **6443** (复用 API) |
| Kubernetes API | 6443 | 6443 |
| Kubelet | 10250 | 10250 |
| etcd | 2379-2380 | 2379-2380 |

**配置示例：**

```yaml
# RKE2 配置
cluster_type: rke2
server_url: https://192.168.1.10:9345  # 注意端口 9345

# K3S 配置
cluster_type: k3s
server_url: https://192.168.1.10:6443  # 注意端口 6443
```

### 3. 安全特性

| 特性 | RKE2 | K3S |
|------|------|-----|
| FIPS 140-2 认证 | ✅ 支持 | ❌ 不支持 |
| CIS 基准强化 | ✅ 内置 | ⚠️ 需手动配置 |
| SELinux 支持 | ✅ 完整支持 | ⚠️ 基础支持 |
| Secrets 加密 | ✅ 默认启用 | ⚠️ 可选启用 |
| Pod Security Policies | ✅ 预配置 | ⚠️ 需手动配置 |
| 审计日志 | ✅ 默认启用 | ⚠️ 需手动配置 |

### 4. 组件和功能

| 组件 | RKE2 | K3S |
|------|------|-----|
| 容器运行时 | containerd | containerd |
| 默认 CNI | Canal (Calico + Flannel) | Flannel |
| Ingress Controller | Nginx | Traefik |
| LoadBalancer | ❌ 需外部 | ServiceLB (内置) |
| Metrics Server | ✅ 包含 | ✅ 包含 |
| CoreDNS | ✅ 包含 | ✅ 包含 |
| Helm Controller | ❌ 不包含 | ✅ 包含 |
| Local Path Provisioner | ❌ 不包含 | ✅ 包含 |

### 5. 性能和资源

| 指标 | RKE2 | K3S |
|------|------|-----|
| **最小内存要求 (Server)** | 2GB | 512MB |
| **最小内存要求 (Agent)** | 1GB | 256MB |
| **最小磁盘空间** | 20GB | 5GB |
| **启动时间** | 2-3 分钟 | 30-60 秒 |
| **CPU 占用 (空闲)** | 中等 | 低 |

### 6. 服务和进程

| 服务 | RKE2 Server | RKE2 Agent | K3S Server | K3S Agent |
|------|-------------|------------|------------|-----------|
| 服务名称 | `rke2-server` | `rke2-agent` | `k3s` | `k3s-agent` |
| systemd 单元 | `rke2-server.service` | `rke2-agent.service` | `k3s.service` | `k3s-agent.service` |
| 二进制路径 | `/usr/local/bin/rke2` | `/usr/local/bin/rke2` | `/usr/local/bin/k3s` | `/usr/local/bin/k3s` |
| 配置目录 | `/etc/rancher/rke2` | `/etc/rancher/rke2` | `/etc/rancher/k3s` | `/etc/rancher/k3s` |
| 数据目录 | `/var/lib/rancher/rke2` | `/var/lib/rancher/rke2` | `/var/lib/rancher/k3s` | `/var/lib/rancher/k3s` |

### 7. 部署和管理

| 操作 | RKE2 | K3S |
|------|------|-----|
| 安装方式 | 安装脚本 | 安装脚本 |
| 安装时间 | 2-3 分钟 | 30-60 秒 |
| 升级方式 | 滚动升级 | 滚动升级 |
| 卸载脚本 | `/usr/local/bin/rke2-uninstall.sh` | `/usr/local/bin/k3s-uninstall.sh` (Server)<br>`/usr/local/bin/k3s-agent-uninstall.sh` (Agent) |
| 配置文件 | `/etc/rancher/rke2/config.yaml` | `/etc/rancher/k3s/config.yaml` |

## 使用示例

### RKE2 部署示例

```yaml
# inventory/hosts.ini
[rke_servers]
node1 ansible_host=192.168.1.10 cluster_init=true
node2 ansible_host=192.168.1.11
node3 ansible_host=192.168.1.12

[rke_agents]
worker1 ansible_host=192.168.1.20

[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
cluster_type=rke2                         # RKE2
server_url=https://192.168.1.10:9345      # 端口 9345
china_region=true
```

```bash
# 部署命令
make setup rke2
# 编辑配置文件后
make install
```

### K3S 部署示例

```yaml
# inventory/hosts.ini
[rke_servers]
node1 ansible_host=192.168.1.10 cluster_init=true
node2 ansible_host=192.168.1.11
node3 ansible_host=192.168.1.12

[rke_agents]
worker1 ansible_host=192.168.1.20

[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
cluster_type=k3s                          # K3S
server_url=https://192.168.1.10:6443      # 端口 6443
china_region=true
```

```bash
# 部署命令
make setup k3s
# 编辑配置文件后
make install
```

## 常见使用场景

### 场景 1：企业生产环境

**推荐：RKE2**

```yaml
cluster_type: rke2
cis_profile: true          # CIS 安全强化
secrets_encryption: true   # Secrets 加密
enable_backup: true        # 自动备份
etcd_snapshot_retention: 30
```

**理由：**
- 需要安全合规认证 (FIPS, CIS)
- 需要稳定可靠的生产级支持
- 有足够的资源 (内存 2GB+)

### 场景 2：边缘计算节点

**推荐：K3S**

```yaml
cluster_type: k3s
disable_components:
  - traefik              # 禁用不需要的组件
  - servicelb
```

**理由：**
- 资源受限 (内存 < 1GB)
- 需要快速启动
- 边缘设备场景

### 场景 3：开发测试环境

**推荐：K3S**

```yaml
cluster_type: k3s
install_version: v1.33.5+k3s1
```

**理由：**
- 快速部署和销毁
- 低资源占用
- 开发测试足够

### 场景 4：混合云 / 多集群

**推荐：根据节点类型选择**

```yaml
# 数据中心节点 (RKE2)
cluster_type: rke2
server_url: https://dc.example.com:9345

# 边缘节点 (K3S)
cluster_type: k3s
server_url: https://edge.example.com:6443
```

## 迁移指南

### 从 K3S 迁移到 RKE2

**不支持直接迁移！** 需要重新部署：

1. 备份 K3S 集群数据和应用
2. 部署新的 RKE2 集群
3. 迁移应用到 RKE2 集群
4. 验证后下线 K3S 集群

**关键步骤：**

```bash
# 1. 备份 K3S
make backup

# 2. 导出应用配置
kubectl get all --all-namespaces -o yaml > k3s-backup.yaml

# 3. 卸载 K3S
make uninstall

# 4. 部署 RKE2
make setup rke2
# 编辑配置，修改 cluster_type=rke2 和 server_url 端口
make install

# 5. 恢复应用
kubectl apply -f k3s-backup.yaml
```

### 从 RKE2 降级到 K3S

**同样不支持直接迁移！** 需要重新部署（参考上述步骤）。

## 决策树

```
开始
  ↓
是否需要安全合规认证 (FIPS/CIS)?
  ├─ 是 → RKE2
  └─ 否 → 继续
      ↓
是否是生产环境?
  ├─ 是 → RKE2 (推荐)
  └─ 否 → 继续
      ↓
节点资源是否充足 (内存 > 2GB)?
  ├─ 是 → RKE2 或 K3S (根据需求)
  └─ 否 → K3S
      ↓
是否是边缘计算 / IoT 场景?
  ├─ 是 → K3S
  └─ 否 → K3S (开发测试)
```

## 常见问题

### Q1: 可以在同一个集群中混用 RKE2 和 K3S 吗？

**A:** 不可以。一个集群只能选择一种类型（RKE2 或 K3S）。

### Q2: RKE2 和 K3S 可以使用相同的 kubectl 命令吗？

**A:** 可以。两者都是完整的 Kubernetes 发行版，kubectl 命令完全兼容。

### Q3: 端口配置错误会怎样？

**A:** 会导致节点加入集群失败。常见错误：

```bash
# ❌ 错误：K3S 使用 RKE2 端口
cluster_type: k3s
server_url: https://192.168.1.10:9345  # 错误！

# ✅ 正确：K3S 使用 6443
cluster_type: k3s
server_url: https://192.168.1.10:6443  # 正确
```

### Q4: 如何验证集群类型？

```bash
# 查看服务
systemctl list-units --type=service | grep -E '(rke2|k3s)'

# RKE2 会显示：
# rke2-server.service  或  rke2-agent.service

# K3S 会显示：
# k3s.service  或  k3s-agent.service
```

### Q5: 性能差异大吗？

**A:** 对于大多数应用场景，性能差异不大。主要差异在：
- 启动时间：K3S 更快
- 内存占用：K3S 更低
- 功能完整性：RKE2 更全面

## 总结

| 选择 | 适合场景 | 关键特性 |
|------|---------|---------|
| **RKE2** | 生产环境、合规场景、企业应用 | FIPS 认证、CIS 强化、完整审计 |
| **K3S** | 边缘计算、IoT、开发测试 | 轻量级、快速部署、低资源占用 |

**端口配置记忆口诀：**
- RKE2 = **9345** (独特)
- K3S = **6443** (标准 Kubernetes)

**快速命令：**
```bash
# 部署 RKE2
make setup rke2 && make install

# 部署 K3S
make setup k3s && make install
```

## 参考资源

- [RKE2 官方文档](https://docs.rke2.io/)
- [K3S 官方文档](https://docs.k3s.io/)
- [SUSE Rancher 文档](https://ranchermanager.docs.rancher.com/)
- [本项目文档](../README.md)

