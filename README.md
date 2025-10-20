# RKE2/K3S Ansible Role

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-2.14%2B-green.svg)](https://www.ansible.com/)
[![RKE2](https://img.shields.io/badge/RKE2-Latest-orange.svg)](https://docs.rke2.io/)
[![K3S](https://img.shields.io/badge/K3S-Latest-blue.svg)](https://k3s.io/)

专业的生产级 Ansible Role，用于自动化部署和管理 RKE2 和 K3S Kubernetes 集群。

## ✨ 特性

- 🔄 **统一管理**: 单一 Role 同时支持 RKE2 和 K3S
- 🏗️ **高可用架构**: 支持多 Master 节点 HA 集群部署
- 🇨🇳 **中国优化**: 针对中国大陆网络环境优化，支持镜像加速
- 🔐 **安全最佳实践**: Token 加密、TLS 配置、CIS 强化模式
- 📦 **多系统支持**: Debian 12+、Ubuntu 22.04+、OpenAnolis 8+
- 🏭 **架构兼容**: AMD64 和 ARM64 双架构支持
- 🔧 **灵活配置**: 丰富的参数化配置选项
- 🔄 **生命周期管理**: 安装、升级、备份、卸载全流程支持
- 🚀 **快速部署**: Makefile 快捷命令，3 分钟完成安装

## 📋 目录

- [快速开始](#-快速开始)
- [系统要求](#-系统要求)
- [安装](#-安装)
- [使用指南](#-使用指南)
- [配置说明](#-配置说明)
- [高可用部署](#-高可用部署)
- [中国大陆部署](#-中国大陆部署)
- [Makefile 命令](#-makefile-命令)
- [文档](#-文档)
- [故障排查](#-故障排查)
- [贡献](#-贡献)
- [许可证](#-许可证)

## 🚀 快速开始

> 💡 **新手推荐**: 完整的快速部署指南请查看 [QUICK-START-GUIDE.md](QUICK-START-GUIDE.md)

### 三步部署集群

```bash
# 1. 克隆项目
git clone <repository-url>
cd rke2-k3s-ansible

# 2. 初始化配置（带完整配置指导）
make setup
# ✨ 执行后会显示详细的配置说明，包括：
#    - 必需配置项（节点 IP、SSH 凭据）
#    - 基础配置（集群类型、版本、中国区加速）
#    - 高级配置（网络、存储、安全）
#    - 快速配置示例
#    - 下一步操作指引

# 编辑配置文件
vim inventory/hosts.ini
vim inventory/group_vars/all.yml

# 测试连接（可选）
make ping

# 3. 安装集群
make install

# 中国大陆用户
make install-china
```

### 验证部署

```bash
# 在 Server 节点执行
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get nodes
kubectl get pods -A
```

## 📊 系统要求

### 硬件要求

| 组件 | 最小配置 | 推荐配置 |
|------|---------|---------|
| **Server 节点** | 2C4G / 20GB | 4C8G / 50GB |
| **Agent 节点** | 1C2G / 20GB | 2C4G / 50GB |

### 操作系统支持

| 操作系统 | 版本 | 架构 |
|---------|------|------|
| Debian | 12+ | amd64, arm64 |
| Ubuntu | 22.04+ | amd64, arm64 |
| OpenAnolis | 8+ | amd64, arm64 |
| CentOS / RHEL | 8+ | amd64, arm64 |

### 网络要求

#### RKE2 端口

| 端口 | 协议 | 用途 | 节点类型 |
|------|------|------|---------|
| 6443 | TCP | Kubernetes API | Server |
| 9345 | TCP | Server Join | Server |
| 10250 | TCP | Kubelet | All |
| 2379-2380 | TCP | etcd | Server |

#### K3S 端口

| 端口 | 协议 | 用途 | 节点类型 |
|------|------|------|---------|
| 6443 | TCP | Kubernetes API | Server |
| 10250 | TCP | Kubelet | All |
| 2379-2380 | TCP | etcd | Server |

## 📦 安装

### 1. 安装 Ansible

```bash
# 使用 pip
pip3 install -r requirements.txt

# 或使用系统包管理器
# Debian/Ubuntu
sudo apt install ansible

# RHEL/CentOS
sudo yum install ansible
```

### 2. 配置 SSH 免密登录

```bash
# 生成密钥对
ssh-keygen -t rsa -b 4096

# 复制公钥到目标主机
ssh-copy-id root@<target-host>
```

### 3. 配置 Inventory

```bash
# 复制示例配置
cp inventory/hosts.ini.example inventory/hosts.ini
cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml

# 编辑配置文件
vim inventory/hosts.ini
vim inventory/group_vars/all.yml
```

## 🔧 使用指南

### 基本安装

#### 安装 RKE2 集群

```bash
# 编辑 inventory/group_vars/all.yml
cluster_type: rke2

# 执行安装
make install-rke2
```

#### 安装 K3S 集群

```bash
# 编辑 inventory/group_vars/all.yml
cluster_type: k3s

# 执行安装
make install-k3s
```

### 高可用集群部署

参考 [高可用部署指南](docs/installation-guide.md#高可用-ha-集群)

### 升级集群

```bash
# 编辑 all.yml 设置新版本
install_version: v1.28.5+rke2r1

# 执行升级（自动备份 + 滚动升级）
make upgrade
```

### 备份 etcd

```bash
# 手动备份
make backup

# 配置自动备份
# 在 all.yml 中设置
enable_backup: true
etcd_snapshot_schedule: "0 */12 * * *"  # 每 12 小时
```

### 卸载集群

```bash
# 完全卸载（危险操作！）
make uninstall
```

## ⚙️ 配置说明

### 核心配置参数

```yaml
# 集群类型
cluster_type: "rke2"  # 或 "k3s"

# 节点角色
node_role: "server"  # 或 "agent"

# 集群初始化（仅第一个 server）
cluster_init: true

# HA 模式负载均衡器
server_url: "https://lb.example.com:9345"

# 集群 Token（建议使用 ansible-vault 加密）
cluster_token: "your-secret-token"

# TLS SAN
tls_san:
  - "lb.example.com"
  - "192.168.1.100"
```

### 中国大陆配置

```yaml
# 启用中国镜像源
china_region: true

# 自动配置镜像加速
enable_registry_mirrors: true
```

### 安全配置

```yaml
# Secrets 加密
secrets_encryption: true

# CIS 强化模式（仅 RKE2）
cis_profile: true

# 使用 Ansible Vault 加密敏感信息
ansible-vault encrypt_string 'my-token' --name 'cluster_token'
```

完整配置说明请查看 [安装部署指南](docs/installation-guide.md)

## 🏗️ 高可用部署

### 架构图

```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │  (HAProxy/Nginx)│
                    │  192.168.1.100  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
       ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
       │ Server1 │     │ Server2 │     │ Server3 │
       │  Master │◄───►│  Master │◄───►│  Master │
       │  + etcd │     │  + etcd │     │  + etcd │
       └─────────┘     └─────────┘     └─────────┘
            │                │                │
       ┌────┴────────────────┴────────────────┴────┐
       │                                            │
  ┌────▼────┐                                 ┌────▼────┐
  │ Agent1  │                                 │ Agent2  │
  │ Worker  │                                 │ Worker  │
  └─────────┘                                 └─────────┘
```

### HA 配置示例

```ini
# inventory/hosts.ini
[rke_k3s_servers]
master1 ansible_host=192.168.1.11 cluster_init=true
master2 ansible_host=192.168.1.12
master3 ansible_host=192.168.1.13

[rke_k3s_agents]
worker1 ansible_host=192.168.1.21
worker2 ansible_host=192.168.1.22

[all:vars]
server_url=https://192.168.1.100:9345
tls_san=['192.168.1.100', 'k8s.example.com']
```

负载均衡器配置请查看 [架构文档](docs/architecture.md#负载均衡器配置)

## 🇨🇳 中国大陆部署

### 网络优化

本项目针对中国大陆网络环境进行了特殊优化：

- ✅ 使用 rancher.cn 镜像源加速安装
- ✅ 配置容器镜像加速（Docker Hub、GCR、Quay 等）
- ✅ 支持离线安装包（可选）

### 快速部署

```bash
# 方法 1: 使用 Makefile
make install-china

# 方法 2: 使用 ansible-playbook
ansible-playbook -i inventory/hosts.ini playbooks/install.yml \
  -e "china_region=true"
```

### 镜像加速配置

自动配置以下镜像源加速：

```yaml
registry_mirrors:
  docker.io:
    - https://dockerhub.mirrors.sjtug.sjtu.edu.cn
    - https://docker.m.daocloud.io
  registry.k8s.io:
    - https://k8s-gcr.m.daocloud.io
  ghcr.io:
    - https://ghcr.m.daocloud.io
```

详细说明请查看 [中国大陆部署指南](docs/china-deployment.md)

## 🛠️ Makefile 命令

```bash
make help              # 显示帮助信息
make setup             # 初始化配置文件

# 安装操作
make install           # 安装集群
make install-china     # 中国大陆安装
make install-rke2      # 安装 RKE2
make install-k3s       # 安装 K3S

# 升级操作
make upgrade           # 升级集群
make upgrade-force     # 强制升级（跳过确认）

# 备份操作
make backup            # 备份 etcd

# 卸载操作
make uninstall         # 卸载集群

# 检查和测试
make check             # 检查所有节点
make ping              # 测试连接
make status            # 获取集群状态
make pods              # 查看所有 Pod
make test              # 干跑测试

# 工具命令
make clean             # 清理临时文件
make lint              # 检查 YAML 语法
make validate          # 验证配置
make info              # 显示集群信息
make version           # 显示版本
make logs              # 查看日志
```

## 📚 文档

- [安装部署指南](docs/installation-guide.md) - 详细安装步骤和配置说明
- [架构设计文档](docs/architecture.md) - 架构设计和技术原理
- [中国大陆部署指南](docs/china-deployment.md) - 中国网络环境特殊配置
- [故障排查指南](docs/troubleshooting.md) - 常见问题和解决方案

## 🔍 故障排查

### 常见问题

#### 1. 安装脚本下载超时

```bash
# 启用中国镜像源
china_region: true
```

#### 2. 节点无法加入集群

```bash
# 检查防火墙和端口
make check

# 检查 token 是否正确
cat /tmp/rke2-token.txt
```

#### 3. 镜像拉取失败

```bash
# 启用镜像加速
enable_registry_mirrors: true
```

更多问题请查看 [故障排查指南](docs/troubleshooting.md)

## 🧪 测试

```bash
# 语法检查
make lint

# 配置验证
make validate

# 干跑测试
make test

# 实际部署测试（测试环境）
INVENTORY=inventory/test.ini make install
```

## 📝 最佳实践

### 1. 安全建议

- ✅ 使用 `ansible-vault` 加密敏感信息
- ✅ 配置防火墙规则
- ✅ 启用 Secrets 加密
- ✅ 定期备份 etcd
- ✅ 使用 TLS 证书

### 2. 高可用建议

- ✅ 至少 3 个 Server 节点（奇数）
- ✅ 使用外部负载均衡器
- ✅ 分布在不同故障域
- ✅ 配置自动备份

### 3. 性能优化

- ✅ 根据工作负载调整资源配额
- ✅ 使用本地存储或分布式存储
- ✅ 配置节点亲和性和污点
- ✅ 启用镜像加速

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [RKE2](https://docs.rke2.io/) - Rancher 政府版 Kubernetes 发行版
- [K3S](https://k3s.io/) - 轻量级 Kubernetes 发行版
- [Ansible](https://www.ansible.com/) - 自动化运维工具
- [Rancher China](https://rancher.cn/) - 中国镜像源支持

## 📧 联系方式

- 项目主页: [GitHub Repository](https://github.com/your-org/rke2-k3s-ansible)
- 问题反馈: [Issue Tracker](https://github.com/your-org/rke2-k3s-ansible/issues)
- 邮件: devops@example.com

---

**作者**: DevOps Team  
**版本**: 1.0.0  
**最后更新**: 2025-01-05
