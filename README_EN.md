# RKE2/K3S Ansible Role (Rancher Cluster)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-2.14%2B-green.svg)](https://www.ansible.com/)
[![RKE2](https://img.shields.io/badge/RKE2-Latest-orange.svg)](https://docs.rke2.io/)
[![K3S](https://img.shields.io/badge/K3S-Latest-blue.svg)](https://k3s.io/)
[![Role](https://img.shields.io/badge/Role-rancher__cluster-success.svg)](roles/rancher_cluster)

**Professional production-grade Ansible Role for automated deployment and management of RKE2 and K3S Kubernetes clusters.**

> 📢 **Recent Updates (2025-10-22)**  
> - ✅ Role refactored: `rke_k3s` → `rancher_cluster`  
> - ✅ Full internationalization: All task names translated to English  
> - ✅ Documentation reorganized: New bilingual commands reference  
> - ✅ Code optimization: Improved maintainability and professionalism

## ✨ Core Features

### 🎯 Cluster Management
- 🔄 **Unified Management**: Single role supports both RKE2 and K3S
- 🏗️ **High Availability**: Multi-master node HA cluster deployment
- 🔄 **Lifecycle Management**: Full support for install, upgrade, backup, and uninstall
- 🚀 **Quick Deployment**: Automated commands, complete installation in 3 minutes
- 🔧 **Flexible Configuration**: Rich parameterized configuration options

### 🌍 Internationalization & Localization
- 🌐 **Bilingual Support**: Complete Chinese/English bilingual documentation
- 🇨🇳 **China Optimized**: Mirror acceleration and network optimization for fast deployment
- 📚 **Professional Docs**: Detailed command reference, architecture guide, troubleshooting

### 🔐 Enterprise Features
- 🔒 **Security Best Practices**: Automatic token management, TLS configuration, CIS hardening
- 📦 **Multi-OS Support**: Debian 12+, Ubuntu 22.04+, OpenAnolis 8+, RHEL 8+
- 🏭 **Architecture Compatible**: AMD64 and ARM64 dual architecture support
- 🎛️ **Smart Upgrade**: Rolling upgrade, resume from interruption, force reinstall

### 💡 Latest Improvements (v2.0)
- ✅ **Role Renamed**: `rancher_cluster` for clearer naming
- ✅ **Code Internationalization**: All task names in English
- ✅ **Documentation Enhanced**: New commands reference manual
- ✅ **Structure Optimized**: Better file organization and maintainability

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Usage Guide](#-usage-guide)
- [Configuration](#-configuration)
- [High Availability Deployment](#-high-availability-deployment)
- [China Deployment](#-china-deployment)
- [Makefile Commands](#-makefile-commands)
- [Documentation](#-documentation)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Quick Start

> 💡 **Recommended for Beginners**: See complete quick deployment guide at [QUICK-START-GUIDE.md](docs/QUICK-START-GUIDE.md)
> 
> 🇨🇳 **中文版本**: [README.md](README.md)

### Three-Step Cluster Deployment

```bash
# 1. Clone the project
git clone <repository-url>
cd rke2-k3s-ansible

# 2. Initialize configuration (with complete guidance)
make setup
# ✨ This will display detailed configuration instructions including:
#    - Required settings (node IPs, SSH credentials)
#    - Basic configuration (cluster type, version, China acceleration)
#    - Advanced configuration (network, storage, security)
#    - Quick configuration examples
#    - Next step guidance

# Edit configuration files
vim inventory/hosts.ini
vim inventory/group_vars/all.yml

# Test connection (optional)
make ping

# 3. Install cluster
make install

# For China mainland users
make install-china
```

### Verify Deployment

```bash
# Execute on Server node
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get nodes
kubectl get pods -A
```

## 📊 System Requirements

### Hardware Requirements

| Component | Minimum | Recommended |
|----------|---------|-------------|
| **Server Node** | 2C4G / 20GB | 4C8G / 50GB |
| **Agent Node** | 1C2G / 20GB | 2C4G / 50GB |

### Operating System Support

| OS | Version | Architecture |
|----|---------|--------------|
| Debian | 12+ | amd64, arm64 |
| Ubuntu | 22.04+ | amd64, arm64 |
| OpenAnolis | 8+ | amd64, arm64 |
| CentOS / RHEL | 8+ | amd64, arm64 |

### Network Requirements

#### RKE2 Ports

**Server Nodes:**
- `9345`: Kubernetes API (HA mode)
- `6443`: Kubernetes API  
- `10250`: Kubelet metrics
- `2379-2380`: etcd client/peer
- `8472`: VXLAN (Flannel)

**Agent Nodes:**
- `10250`: Kubelet metrics
- `8472`: VXLAN

#### K3S Ports

**Server Nodes:**
- `6443`: Kubernetes API
- `10250`: Kubelet metrics  
- `2379-2380`: etcd
- `8472`: VXLAN

**Agent Nodes:**
- `10250`: Kubelet metrics
- `8472`: VXLAN

## 🛠️ Installation

### Prerequisites

```bash
# Install Ansible (control node)
pip3 install ansible

# Configure SSH key authentication
ssh-copy-id user@node-ip
```

### Step-by-Step Installation

#### 1. Clone Repository

```bash
git clone https://github.com/your-org/rke2-k3s-ansible.git
cd rke2-k3s-ansible
```

#### 2. Initialize Configuration

```bash
# Create configuration files
make setup

# Or specify cluster type
make setup k3s    # Initialize for K3S
make setup rke2   # Initialize for RKE2
```

#### 3. Configure Inventory

Edit `inventory/hosts.ini`:

```ini
[rke_servers]
master1 ansible_host=192.168.1.10 cluster_init=true
master2 ansible_host=192.168.1.11
master3 ansible_host=192.168.1.12

[rke_agents]
worker1 ansible_host=192.168.1.20
worker2 ansible_host=192.168.1.21

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
cluster_type=rke2
install_version=v1.28.5+rke2r1
```

#### 4. Configure Global Variables

Edit `inventory/group_vars/all.yml`:

```yaml
# Cluster configuration
cluster_type: "rke2"  # or "k3s"
install_version: "v1.28.5+rke2r1"

# China region optimization
china_region: true
enable_registry_mirrors: true

# High availability
server_url: "https://lb.example.com:9345"
tls_san:
  - "lb.example.com"
  - "192.168.1.100"

# Security
cluster_token: "{{ vault_cluster_token }}"

# Backup
enable_backup: true
etcd_snapshot_retention: 5
```

#### 5. Install Cluster

```bash
# Standard installation
make install

# China accelerated installation
make install-china

# With additional parameters
make install EXTRA_ARGS="--tags=install"
```

## 📖 Usage Guide

### Basic Commands

```bash
# Test connectivity
make ping

# Install cluster
make install

# Upgrade cluster
make upgrade

# Backup etcd
make backup

# Uninstall cluster
make uninstall

# View cluster status
make status

# View pods
make pods

# View version
make version

# View logs
make logs
```

### Advanced Operations

#### Manual Step-by-Step Installation

```bash
# 1. Install initial server node
ansible-playbook -i inventory/hosts.ini playbooks/install.yml \
  --limit "master1"

# 2. Install other server nodes
ansible-playbook -i inventory/hosts.ini playbooks/install.yml \
  --limit "master2,master3"

# 3. Install agent nodes
ansible-playbook -i inventory/hosts.ini playbooks/install.yml \
  --limit "rke_agents"
```

#### Upgrade to Specific Version

```bash
# Specify version in group_vars/all.yml
install_version: "v1.29.0+rke2r1"

# Execute upgrade
make upgrade
```

#### Backup and Restore

```bash
# Manual backup
make backup

# Automated backup (configured in variables)
enable_backup: true
backup_schedule: "0 2 * * *"  # Daily at 2 AM

# Restore
rke2 server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/rke2/server/db/snapshots/snapshot.db
```

## ⚙️ Configuration

### Core Configuration Items

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `cluster_type` | Cluster type | `rke2` | `rke2` or `k3s` |
| `install_version` | Install version | latest | `v1.28.5+rke2r1` |
| `node_role` | Node role | - | `server` or `agent` |
| `cluster_init` | Initialize cluster | `false` | `true` |
| `server_url` | API Server address | - | `https://lb:9345` |
| `cluster_token` | Cluster token | auto | `K10xxx...` |

### Network Configuration

```yaml
# CNI plugin
cni: "canal"  # canal, calico, cilium

# Service CIDR
service_cidr: "10.43.0.0/16"

# Cluster DNS
cluster_dns: "10.43.0.10"

# Cluster domain
cluster_domain: "cluster.local"
```

### Storage Configuration

```yaml
# Default storage class
default_storage_class: "local-path"

# Local path provisioner
local_path_provisioner_path: "/opt/local-path-provisioner"
```

### Security Configuration

```yaml
# CIS hardening
cis_hardened: false

# Pod Security Standards
pod_security_standard: "restricted"

# Secrets encryption
secrets_encryption: true

# Audit log
audit_log_enabled: true
```

## 🏗️ High Availability Deployment

### Architecture

```
┌─────────────────────────────────────────────┐
│          Load Balancer (VIP)                │
│         192.168.1.100:9345                  │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┬─────────────┐
       │                │             │
   ┌───▼───┐       ┌───▼───┐     ┌───▼───┐
   │Server1│       │Server2│     │Server3│
   │ etcd  │◄─────►│ etcd  │◄───►│ etcd  │
   └───┬───┘       └───┬───┘     └───┬───┘
       │               │             │
   ┌───▼───────────────▼─────────────▼───┐
   │          Agent Nodes Pool            │
   │  worker1  worker2  worker3  worker4  │
   └──────────────────────────────────────┘
```

### Configuration Example

```yaml
# 1. Configure load balancer
server_url: "https://192.168.1.100:9345"

# 2. Configure TLS SAN
tls_san:
  - "192.168.1.100"
  - "lb.example.com"
  - "192.168.1.10"
  - "192.168.1.11"  
  - "192.168.1.12"

# 3. Configure etcd
etcd_expose_metrics: true
etcd_snapshot_schedule: "0 */12 * * *"
etcd_snapshot_retention: 5
```

## 🇨🇳 China Deployment

### Quick Configuration

```bash
# 1. Use setup command with automatic configuration
make setup rke2  # Automatically enables China region

# 2. Or manually configure
vim inventory/group_vars/all.yml
```

```yaml
# Enable China region
china_region: true

# Enable registry mirrors
enable_registry_mirrors: true

# Custom mirrors
registry_mirrors:
  docker.io:
    - "https://dockerproxy.com"
    - "https://docker.mirrors.ustc.edu.cn"
  registry.k8s.io:
    - "https://registry.aliyuncs.com/google_containers"
```

### Verification

```bash
# Check mirror configuration
cat /etc/rancher/rke2/registries.yaml

# Test mirror connectivity
curl -I https://rancher-mirror.rancher.cn
```

For more details see [China Deployment Guide](docs/china-deployment.md)

## 📦 Makefile Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `make setup` | Initialize configuration | `make setup [k3s\|rke2]` |
| `make ping` | Test connectivity | `make ping` |
| `make install` | Install cluster | `make install` |
| `make upgrade` | Upgrade cluster | `make upgrade` |
| `make backup` | Backup etcd | `make backup` |
| `make uninstall` | Uninstall cluster | `make uninstall` |
| `make status` | View cluster status | `make status` |
| `make pods` | View all pods | `make pods` |
| `make version` | View version info | `make version` |
| `make logs` | View service logs | `make logs` |
| `make clean` | Clean local files | `make clean` |
| `make reset` | Reset configuration | `make reset` |

## 📚 Documentation

- [Commands Reference](docs/COMMANDS-REFERENCE.md) - Complete Makefile commands reference
- [Quick Start Guide](docs/QUICK-START-GUIDE.md) - Complete quick deployment guide
- [Installation Guide](docs/installation-guide.md) - Detailed installation steps
- [Architecture Guide](docs/architecture.md) - System architecture explanation
- [China Deployment](docs/china-deployment.md) - China region deployment guide
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions
- [RKE2 vs K3S](docs/RKE2-VS-K3S.md) - Comparison and selection guide

## 🔧 Troubleshooting

### Common Issues

#### 1. Network connectivity issues

```bash
# Enable China mirror source
china_region: true
```

#### 2. Nodes cannot join cluster

```bash
# Check firewall and ports
make check

# Check if token is correct
cat /tmp/rke2-token.txt
```

#### 3. Image pull failures

```bash
# Enable mirror acceleration
enable_registry_mirrors: true
```

For more issues see [Troubleshooting Guide](docs/troubleshooting.md)

## 🧪 Testing

```bash
# Syntax check
make lint

# Configuration validation
make validate

# Dry run test
make test

# Actual deployment test (test environment)
INVENTORY=inventory/test.ini make install
```

## 📝 Best Practices

### 1. Security Recommendations

- ✅ Use `ansible-vault` to encrypt sensitive information
- ✅ Configure firewall rules
- ✅ Enable Secrets encryption
- ✅ Regular etcd backups
- ✅ Use TLS certificates

### 2. High Availability Recommendations

- ✅ At least 3 Server nodes (odd number)
- ✅ Use external load balancer
- ✅ Distribute across different failure domains
- ✅ Configure automatic backups

### 3. Performance Optimization

- ✅ Adjust resource quotas based on workload
- ✅ Use local or distributed storage
- ✅ Configure node affinity and taints
- ✅ Enable mirror acceleration

## 🤝 Contributing

Contributions are welcome - code, issue reports, or suggestions!

1. Fork this project
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Submit Pull Request

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [RKE2](https://docs.rke2.io/) - Rancher Government Kubernetes Distribution
- [K3S](https://k3s.io/) - Lightweight Kubernetes Distribution
- [Ansible](https://www.ansible.com/) - Automation tool
- [Rancher China](https://rancher.cn/) - China mirror source support

## 📧 Contact

- Project Homepage: [GitHub Repository](https://github.com/ioeory/ansible-rancher_cluster)
- Issue Tracker: [Issue Tracker](https://github.com/ioeory/ansible-rancher_cluster/issues)
- Email: ioeory@gmail.com