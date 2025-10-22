# 🚀 RKE2/K3S 集群快速部署指南

## 📋 前置准备

### 1. 系统要求

**控制机器（运行 Ansible 的机器）**：
- Python 3.8+
- Ansible 2.14+
- SSH 客户端

**目标节点**：
- Debian 12+ / Ubuntu 22.04+ / Open Anolis 8+
- 最小 2GB 内存（Server），1GB 内存（Agent）
- 最小 20GB 磁盘空间
- 支持架构：amd64, arm64

### 2. 网络要求

- 控制机器可以 SSH 访问所有目标节点
- 目标节点之间网络互通
- 如果在中国大陆，建议启用镜像加速

---

## 🎯 五步快速部署

### 步骤 1: 初始化配置 ⚙️

```bash
make setup
```

执行后会看到详细的配置指导，包括：
- ✅ 必需配置项（节点 IP、SSH 凭据）
- ✅ 基础配置（集群类型、版本、中国区加速）
- ✅ 高级配置（网络、存储、安全）
- ✅ 快速配置示例
- ✅ 下一步操作指引

---

### 步骤 2: 编辑节点配置 📝

#### **方式 A: 使用 `hosts.ini` (推荐)**

编辑 `inventory/hosts.ini`：

```ini
[rke_servers]
node1 ansible_host=192.168.2.41 cluster_init=true
node2 ansible_host=192.168.2.42
node3 ansible_host=192.168.2.43

[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa

# 基础配置
cluster_type=k3s              # 或 rke2
china_region=true             # 中国区镜像加速
install_version=              # 留空安装最新版
cluster_token=MySecretToken   # 集群密钥
server_url=https://192.168.2.41:6443
```

#### **方式 B: 使用 `all.yml` (更灵活)**

编辑 `inventory/group_vars/all.yml`，可配置更多选项。

---

### 步骤 3: 测试连接 🔌

```bash
# 测试 SSH 连接
make ping

# 检查 YAML 语法
make lint
```

**预期输出**：
```
node1 | SUCCESS => { "ping": "pong" }
node2 | SUCCESS => { "ping": "pong" }
node3 | SUCCESS => { "ping": "pong" }
```

---

### 步骤 4: 部署集群 🚀

```bash
# 自动选择（根据配置文件）
make install

# 或强制指定类型
make install-k3s      # 安装 K3S
make install-rke2     # 安装 RKE2
```

**部署时间**：5-10 分钟（取决于网络速度）

---

### 步骤 5: 验证集群 ✅

```bash
# 查看节点状态
make status

# 查看所有 Pods
make pods

# 查看版本信息
make version
```

**预期输出**：
```
NAME      STATUS   ROLES                       AGE   VERSION
node1     Ready    control-plane,etcd,master   5m    v1.33.5+k3s1
node2     Ready    control-plane,etcd,master   4m    v1.33.5+k3s1
node3     Ready    control-plane,etcd,master   4m    v1.33.5+k3s1
```

---

## 🎨 常用场景配置

### 场景 1: 标准 RKE2 HA 集群（生产环境，中国区）

```ini
cluster_type=rke2
china_region=true
install_version=
server_url=https://192.168.2.41:9345

[rke_servers]
node1 ansible_host=192.168.2.41 cluster_init=true
node2 ansible_host=192.168.2.42
node3 ansible_host=192.168.2.43
```

**特点**：
- ✅ 生产级稳定性
- ✅ 完整的 HA 支持
- ✅ 中国区加速
- ⚠️ 资源占用较高

---

### 场景 2: K3S 轻量级集群（边缘计算/IoT）

```ini
cluster_type=k3s
china_region=false
install_version=v1.33.5+k3s1
server_url=https://192.168.2.41:6443

[rke_servers]
node1 ansible_host=192.168.2.41 cluster_init=true
node2 ansible_host=192.168.2.42
node3 ansible_host=192.168.2.43
```

**特点**：
- ✅ 轻量级（~50MB 内存）
- ✅ 快速启动
- ✅ 适合资源受限环境
- ⚠️ 功能相对简化

---

### 场景 3: 单节点开发环境

```ini
cluster_type=k3s
china_region=true
server_url=https://192.168.2.41:6443

[rke_servers]
node1 ansible_host=192.168.2.41 cluster_init=true

# 只配置一个节点，快速测试
```

**特点**：
- ✅ 最快部署（1-2 分钟）
- ✅ 最少资源
- ⚠️ 无高可用

---

## 🛠️ 常用管理命令

### 集群操作

```bash
make install          # 安装集群
make upgrade          # 升级集群
make backup           # 备份 etcd
make uninstall        # 卸载集群
```

### 集群查询

```bash
make status           # 查看节点状态
make pods             # 查看所有 Pods
make version          # 查看版本信息
make logs             # 查看服务日志
```

### 开发工具

```bash
make ping             # 测试 SSH 连接
make lint             # 检查 YAML 语法
make clean            # 清理临时文件
make help             # 查看所有命令
```

---

## 🔧 常见问题

### 1. SSH 连接失败

**问题**：`Permission denied (publickey)`

**解决**：
```bash
# 检查 SSH 密钥权限
chmod 600 ~/.ssh/id_rsa

# 或使用密码认证
ansible_ssh_pass=your_password
```

---

### 2. 端口被占用

**问题**：`警告: 端口 6443 已被占用`

**解决**：
```bash
# 检查占用进程
sudo lsof -i :6443

# 如果是旧集群，先卸载
make uninstall
```

---

### 3. 镜像下载慢

**问题**：下载 Containerd 镜像超时

**解决**：
```ini
# 启用中国区加速
china_region=true
enable_registry_mirrors=true
```

---

### 4. Token 验证失败

**问题**：`token CA hash does not match`

**解决**：
```bash
# 重新生成 Token
cluster_token=$(openssl rand -hex 32)

# 或使用简单密码
cluster_token=MySecretPassword123
```

---

## 📚 进阶配置

### 自定义网络

```yaml
# inventory/group_vars/all.yml
cluster_cidr: "10.42.0.0/16"      # Pod 网络
service_cidr: "10.43.0.0/16"      # Service 网络
cluster_dns: "10.43.0.10"         # DNS 地址
```

### 自定义存储

```yaml
data_dir: "/data/rancher"         # 数据目录
backup_dir: "/backup/k8s"         # 备份目录
etcd_snapshot_schedule: "0 */12 * * *"  # 自动备份
```

### TLS 安全

```yaml
tls_san:
  - "192.168.2.41"
  - "192.168.2.42"
  - "192.168.2.43"
  - "cluster.example.com"
  - "api.k8s.local"
```

---

## 🎓 学习资源

### 官方文档

- **RKE2**: https://docs.rke2.io/
- **K3S**: https://docs.k3s.io/
- **Ansible**: https://docs.ansible.com/

### 项目文档

- `README.md` - 项目概述
- `docs/installation-guide.md` - 详细安装指南
- `docs/architecture.md` - 架构设计文档
- `docs/china-deployment.md` - 中国区部署指南
- `docs/troubleshooting.md` - 故障排查指南

---

## 💬 获取帮助

### 查看帮助

```bash
make help              # 查看所有命令
make setup             # 查看配置指导
```

### 常用链接

- **查看日志**: `make logs`
- **集群状态**: `make status`
- **Pod 状态**: `make pods`

---

## 🎯 快速命令速查表

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `make setup` | 初始化配置 | 首次使用 |
| `make ping` | 测试连接 | 部署前检查 |
| `make install` | 安装集群 | 执行部署 |
| `make status` | 节点状态 | 日常检查 |
| `make pods` | Pod 状态 | 故障排查 |
| `make backup` | 备份 etcd | 重要操作前 |
| `make upgrade` | 升级集群 | 版本更新 |
| `make uninstall` | 卸载集群 | 清理环境 |

---

## ✅ 部署检查清单

在执行 `make install` 前，确认以下项目：

- [ ] 已执行 `make setup` 初始化配置
- [ ] 已编辑 `inventory/hosts.ini` 配置节点信息
- [ ] 已配置正确的 SSH 凭据（用户名、密钥）
- [ ] 已设置 `cluster_type`（rke2 或 k3s）
- [ ] 如在中国大陆，已启用 `china_region=true`
- [ ] 已执行 `make ping` 测试连接成功
- [ ] 已执行 `make lint` 检查语法通过
- [ ] 确认目标节点满足系统要求
- [ ] 确认网络端口未被占用
- [ ] 已记录 `cluster_token` 备用

---

## 🎉 开始部署

一切准备就绪？执行以下命令开始部署：

```bash
make install
```

部署完成后，执行：

```bash
make status
make pods
```

验证集群状态。祝您部署顺利！🚀

---

**文档版本**: v1.0  
**最后更新**: 2025-10-20  
**维护者**: RKE2/K3S Ansible Automation Project

