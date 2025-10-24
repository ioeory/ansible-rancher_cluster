# RKE2/K3S 安装部署指南

本文档提供详细的安装部署步骤和配置说明。

## 目录

- [前置准备](#前置准备)
- [快速安装](#快速安装)
- [配置说明](#配置说明)
- [部署场景](#部署场景)
- [高级配置](#高级配置)
- [验证和测试](#验证和测试)

## 前置准备

### 1. 环境要求

#### 硬件要求

| 节点类型 | CPU | 内存 | 磁盘 | 网络 |
|---------|-----|------|------|------|
| Server (最小) | 2 Core | 4 GB | 20 GB | 1 Gbps |
| Server (推荐) | 4 Core | 8 GB | 50 GB | 10 Gbps |
| Agent (最小) | 1 Core | 2 GB | 20 GB | 1 Gbps |
| Agent (推荐) | 2 Core | 4 GB | 50 GB | 10 Gbps |

#### 操作系统要求

✅ **支持的操作系统**

- Debian 12 及更高版本
- Ubuntu 22.04 LTS 及更高版本
- OpenAnolis 8 及更高版本
- CentOS Stream 8+
- RHEL 8+
- Rocky Linux 8+
- AlmaLinux 8+

✅ **支持的架构**

- x86_64 (amd64)
- aarch64 (arm64)

### 2. 安装 Ansible

#### 使用 pip 安装（推荐）

```bash
# 安装 Python3 和 pip
# Debian/Ubuntu
sudo apt update
sudo apt install -y python3 python3-pip

# RHEL/CentOS
sudo yum install -y python3 python3-pip

# 安装 Ansible 和依赖
pip3 install -r requirements.txt
```

#### 使用系统包管理器

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y ansible

# RHEL/CentOS
sudo yum install -y epel-release
sudo yum install -y ansible
```

#### 验证安装

```bash
ansible --version
# 输出应显示 2.14+ 版本
```

### 3. 配置 SSH 访问

#### 生成 SSH 密钥

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

#### 配置免密登录

```bash
# 方法 1: 使用 ssh-copy-id
ssh-copy-id root@<target-host>

# 方法 2: 手动复制
cat ~/.ssh/id_rsa.pub | ssh root@<target-host> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### 测试连接

```bash
ssh root@<target-host>
```

### 4. 准备目标主机

#### 确保系统更新

```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade -y

# RHEL/CentOS
sudo yum update -y
```

#### 禁用 SELinux（可选，RHEL/CentOS）

```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

## 快速安装

### 1. 获取项目

```bash
git clone <repository-url>
cd rke2-k3s-ansible
```

### 2. 初始化配置

```bash
make setup
```

这将创建以下配置文件：
- `inventory/hosts.ini` - 主机清单
- `inventory/group_vars/all.yml` - 全局变量

### 3. 配置 Inventory

编辑 `inventory/hosts.ini`:

```ini
[rke_servers]
master1 ansible_host=192.168.1.11 cluster_init=true

[all:vars]
ansible_user=root
cluster_type=rke2
```

### 4. 执行安装

```bash
# 标准安装
make install

# 中国大陆安装
make install-china
```

### 5. 验证安装

```bash
# 在 Server 节点执行
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get nodes
kubectl get pods -A
```

## 配置说明

### Inventory 配置

#### hosts.ini 结构

```ini
# Server 节点组
[rke_servers]
node1 ansible_host=IP cluster_init=true
node2 ansible_host=IP
node3 ansible_host=IP

# Agent 节点组
[rke_agents]
worker1 ansible_host=IP
worker2 ansible_host=IP

# 组变量
[rke_servers:vars]
node_role=server

[rke_agents:vars]
node_role=agent

# 全局变量
[all:vars]
ansible_user=root
cluster_type=rke2
```

### 变量配置

#### all.yml 核心变量

```yaml
# ============================================================================
# 集群基础配置
# ============================================================================

# 集群类型
cluster_type: "rke2"  # 选项: rke2, k3s

# 安装版本
install_version: "v1.28.5+rke2r1"  # 留空安装最新版

# ============================================================================
# 网络配置
# ============================================================================

# 负载均衡器地址 (HA 模式)
server_url: "https://192.168.1.100:9345"

# 集群 Token
cluster_token: "your-secret-token"

# TLS SAN 列表
tls_san:
  - "192.168.1.100"
  - "lb.example.com"
  - "k8s.example.com"

# ============================================================================
# 中国大陆配置
# ============================================================================

# 启用中国镜像源
china_region: true

# 启用镜像加速
enable_registry_mirrors: true
```

### 变量参数表

| 变量名 | 类型 | 默认值 | 说明 |
|-------|------|-------|------|
| `cluster_type` | string | rke2 | 集群类型 (rke2/k3s) |
| `node_role` | string | server | 节点角色 (server/agent) |
| `install_version` | string | "" | 安装版本，留空为最新 |
| `china_region` | boolean | false | 启用中国镜像源 |
| `cluster_init` | boolean | false | 是否为初始节点 |
| `server_url` | string | "" | Server URL (HA 模式) |
| `cluster_token` | string | "" | 集群 Token |
| `tls_san` | list | [] | TLS SAN 列表 |
| `enable_backup` | boolean | false | 启用自动备份 |
| `disable_swap` | boolean | true | 禁用 swap |

## 部署场景

### 场景 1: 单节点测试集群

**适用于**: 开发、测试环境

#### Inventory 配置

```ini
[rke_servers]
test-node ansible_host=192.168.1.10 cluster_init=true

[all:vars]
ansible_user=root
cluster_type=k3s
```

#### 部署命令

```bash
make install
```

### 场景 2: 高可用 (HA) 集群

**适用于**: 生产环境

#### 架构

```
          Load Balancer (192.168.1.100)
                    |
    +-----------+---+------------+
    |           |                |
Server1      Server2         Server3
(Master)     (Master)        (Master)
+ etcd       + etcd          + etcd
```

#### 前置条件

配置外部负载均衡器（HAProxy/Nginx/云 LB），监听端口：

**RKE2:**
- 6443 (API Server)
- 9345 (Server Join)

**K3S:**
- 6443 (API Server)

#### HAProxy 配置示例

```haproxy
# /etc/haproxy/haproxy.cfg

frontend k8s-api
    bind *:6443
    mode tcp
    default_backend k8s-api-backend

backend k8s-api-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master1 192.168.1.11:6443 check
    server master2 192.168.1.12:6443 check
    server master3 192.168.1.13:6443 check

# RKE2 专用
frontend rke2-join
    bind *:9345
    mode tcp
    default_backend rke2-join-backend

backend rke2-join-backend
    mode tcp
    balance roundrobin
    server master1 192.168.1.11:9345 check
    server master2 192.168.1.12:9345 check
    server master3 192.168.1.13:9345 check
```

#### Inventory 配置

```ini
[rke_servers]
master1 ansible_host=192.168.1.11 cluster_init=true
master2 ansible_host=192.168.1.12
master3 ansible_host=192.168.1.13

[all:vars]
ansible_user=root
cluster_type=rke2
server_url=https://192.168.1.100:9345
tls_san=['192.168.1.100', 'k8s.example.com']
cluster_token=my-secure-token
```

#### 部署步骤

```bash
# 1. 配置负载均衡器
# 2. 配置 Inventory
# 3. 部署集群
make install
```

### 场景 3: Server + Agent 混合集群

**适用于**: 生产环境，控制平面与工作负载分离

#### Inventory 配置

```ini
[rke_servers]
master1 ansible_host=192.168.1.11 cluster_init=true
master2 ansible_host=192.168.1.12
master3 ansible_host=192.168.1.13

[rke_agents]
worker1 ansible_host=192.168.1.21
worker2 ansible_host=192.168.1.22
worker3 ansible_host=192.168.1.23

[rke_servers:vars]
node_role=server
node_taints=['node-role.kubernetes.io/control-plane:NoSchedule']

[rke_agents:vars]
node_role=agent

[all:vars]
ansible_user=root
cluster_type=rke2
server_url=https://192.168.1.100:9345
cluster_token=my-secure-token
```

## 高级配置

### 1. 使用 Ansible Vault 加密敏感信息

#### 加密 Token

```bash
# 交互式加密
ansible-vault encrypt_string 'my-secret-token' --name 'cluster_token'

# 输出示例
cluster_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...encrypted content...
```

#### 使用加密变量

```yaml
# inventory/group_vars/all.yml
cluster_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...encrypted content...
```

#### 执行 Playbook 时提供密码

```bash
# 交互式输入
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --ask-vault-pass

# 使用密码文件
echo 'your-vault-password' > .vault_pass
chmod 600 .vault_pass
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --vault-password-file=.vault_pass
```

### 2. 自定义网络配置

```yaml
# inventory/group_vars/all.yml

# 自定义 CIDR
cluster_cidr: "10.52.0.0/16"
service_cidr: "10.53.0.0/16"
cluster_dns: "10.53.0.10"

# 选择 CNI
cni: "calico"  # RKE2: canal/calico/cilium, K3S: flannel/calico/cilium
```

### 3. 节点标签和污点

```yaml
# Server 节点专用于控制平面
node_labels:
  - "node-role.kubernetes.io/control-plane="
node_taints:
  - "node-role.kubernetes.io/control-plane:NoSchedule"

# Worker 节点标签
node_labels:
  - "workload-type=high-memory"
  - "environment=production"
```

### 4. K3S 禁用组件

```yaml
# K3S 可以禁用不需要的组件
disable_components:
  - "traefik"        # 使用自己的 Ingress Controller
  - "servicelb"      # 使用 MetalLB 或云 LB
  - "local-storage"  # 使用外部存储
```

### 5. RKE2 CIS 强化模式

```yaml
# 启用 CIS 1.6 安全配置文件
cis_profile: true

# 注意: CIS 模式会应用更严格的安全策略
```

### 6. 自动备份配置

```yaml
# 启用自动备份
enable_backup: true

# 备份保留数量
etcd_snapshot_retention: 10

# 备份计划 (cron 格式)
etcd_snapshot_schedule: "0 */6 * * *"  # 每 6 小时
```

## 验证和测试

### 1. 预检查

```bash
# 测试 Ansible 连接
make ping

# 干跑测试
make test
```

### 2. 安装后验证

```bash
# 检查节点状态
make status

# 查看所有 Pod
make pods

# 查看服务日志
make logs
```

### 3. 手动验证

```bash
# SSH 到 Server 节点
ssh root@<server-node>

# 设置 KUBECONFIG
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# 检查节点
kubectl get nodes -o wide

# 检查系统组件
kubectl get pods -n kube-system

# 检查 etcd 状态 (RKE2)
rke2 etcd-snapshot ls

# 检查版本
rke2 --version
# 或
k3s --version
```

### 4. 功能测试

```bash
# 部署测试应用
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# 检查部署
kubectl get pods,svc

# 访问测试
curl http://<node-ip>:<nodeport>

# 清理测试
kubectl delete deployment nginx
kubectl delete service nginx
```

## 故障排查

### 常见问题

#### 1. 预检查失败

```bash
# 查看详细错误
ansible-playbook -i inventory/hosts.ini playbooks/install.yml -vvv

# 跳过预检查（不推荐）
ansible-playbook -i inventory/hosts.ini playbooks/install.yml -e "skip_preflight=true"
```

#### 2. 安装超时

```bash
# 增加超时时间
# 在 all.yml 中设置
install_timeout: 3600  # 1 小时
```

#### 3. 节点无法加入

```bash
# 检查网络连通性
ping <server-node>

# 检查端口
nc -zv <server-node> 6443
nc -zv <server-node> 9345  # RKE2

# 检查防火墙
sudo firewall-cmd --list-all
```

#### 4. Token 错误

```bash
# 在初始 Server 节点查看 Token
cat /var/lib/rancher/rke2/server/node-token
# 或
cat /var/lib/rancher/k3s/server/node-token

# 更新 Inventory 中的 cluster_token
```

更多故障排查请参考 [故障排查指南](troubleshooting.md)

## 下一步

- [架构设计文档](architecture.md) - 了解技术架构
- [中国大陆部署](china-deployment.md) - 中国网络优化
- [故障排查指南](troubleshooting.md) - 解决常见问题

---

**文档版本**: 1.0.0  
**最后更新**: 2025-10-22
