# 架构设计文档

本文档详细说明 RKE2/K3S Ansible Role 的架构设计和技术实现。

## 目录

- [概述](#概述)
- [RKE2 vs K3S 对比](#rke2-vs-k3s-对比)
- [架构设计](#架构设计)
- [网络架构](#网络架构)
- [高可用架构](#高可用架构)
- [组件说明](#组件说明)
- [端口矩阵](#端口矩阵)
- [安全架构](#安全架构)
- [存储架构](#存储架构)

## 概述

本项目实现了一个统一的 Ansible Role，用于自动化部署和管理两种 Kubernetes 发行版：

- **RKE2** (Rancher Kubernetes Engine 2): 企业级、安全加固的 Kubernetes 发行版
- **K3S**: 轻量级 Kubernetes 发行版，适合边缘计算和资源受限环境

### 设计原则

1. **统一接口**: 单一 Role 通过变量切换不同发行版
2. **生产就绪**: 支持高可用、自动备份、滚动升级
3. **安全第一**: TLS 加密、Token 管理、CIS 强化
4. **灵活配置**: 丰富的参数化配置选项
5. **中国优化**: 针对中国大陆网络环境特殊处理

## RKE2 vs K3S 对比

### 功能对比表

| 特性 | RKE2 | K3S | 说明 |
|------|------|-----|------|
| **定位** | 企业级 | 轻量级 | RKE2 面向企业，K3S 面向边缘 |
| **二进制大小** | ~200MB | ~50MB | K3S 更轻量 |
| **内存占用** | ~1GB | ~512MB | K3S 资源占用更少 |
| **CIS 强化** | ✅ | ❌ | RKE2 支持 CIS 1.6 配置文件 |
| **FIPS 140-2** | ✅ | ❌ | RKE2 支持 FIPS 加密模块 |
| **默认 CNI** | Canal | Flannel | RKE2 功能更丰富 |
| **内嵌组件** | 最少 | Traefik, ServiceLB | K3S 内置更多组件 |
| **etcd** | 外部或嵌入 | 嵌入式 | 两者都支持嵌入式 etcd |
| **适用场景** | 企业生产、监管环境 | 边缘计算、IoT、开发测试 |

### 技术差异表

| 项目 | RKE2 | K3S |
|------|------|-----|
| **配置路径** | `/etc/rancher/rke2/` | `/etc/rancher/k3s/` |
| **数据目录** | `/var/lib/rancher/rke2/` | `/var/lib/rancher/k3s/` |
| **Kubeconfig** | `/etc/rancher/rke2/rke2.yaml` | `/etc/rancher/k3s/k3s.yaml` |
| **服务名称** | `rke2-server` / `rke2-agent` | `k3s` |
| **Server Join 端口** | 9345 | 6443 |
| **安装脚本** | `https://get.rke2.io` | `https://get.k3s.io` |
| **卸载脚本** | `rke2-uninstall.sh` | `k3s-uninstall.sh` |

### 如何选择？

#### 选择 RKE2 如果：

- ✅ 需要符合政府或行业监管要求（FIPS、CIS）
- ✅ 企业生产环境
- ✅ 需要更强的安全保障
- ✅ 资源充足

#### 选择 K3S 如果：

- ✅ 边缘计算或 IoT 场景
- ✅ 资源受限环境（树莓派、单板计算机）
- ✅ 快速开发测试
- ✅ 需要快速启动和低资源占用

## 架构设计

### Role 架构

```
roles/rancher_cluster/
│
├── defaults/main.yml           # 默认变量（用户可覆盖）
│
├── vars/                       # 内部变量（不建议修改）
│   ├── rke2.yml               # RKE2 特定配置
│   ├── k3s.yml                # K3S 特定配置
│   └── china_mirrors.yml      # 中国镜像源配置
│
├── tasks/                      # 任务文件
│   ├── main.yml               # 主入口，加载变量和调度任务
│   ├── preflight.yml          # 预检查（OS、资源、网络）
│   ├── install_server.yml     # Server 节点安装
│   ├── install_agent.yml      # Agent 节点安装
│   ├── configure_china.yml    # 中国区配置
│   ├── upgrade.yml            # 升级任务
│   └── backup.yml             # 备份任务
│
├── templates/                  # Jinja2 模板
│   ├── config.yaml.j2         # 集群配置模板
│   └── registries.yaml.j2     # 镜像源配置模板
│
└── handlers/                   # 事件处理
    └── main.yml               # 服务重启处理
```

### 执行流程

```
用户执行 Playbook
      │
      ▼
┌─────────────┐
│ main.yml    │  加载集群类型变量 (rke2/k3s)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ preflight   │  预检查系统环境
└──────┬──────┘
       │
       ├──────► china_region=true ──► configure_china.yml
       │
       ▼
  node_role?
       │
       ├──► server ──► install_server.yml
       │                     │
       │                     ├─► cluster_init=true  (首个节点)
       │                     └─► cluster_init=false (HA 后续节点)
       │
       └──► agent  ──► install_agent.yml
```

## 网络架构

### 单节点架构

```
┌─────────────────────────────────────┐
│         Server Node                 │
│  ┌──────────────────────────────┐   │
│  │   Kubernetes Control Plane   │   │
│  │   - API Server (6443)        │   │
│  │   - Scheduler                │   │
│  │   - Controller Manager       │   │
│  │   - etcd (2379-2380)         │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │   Workload Components        │   │
│  │   - Kubelet (10250)          │   │
│  │   - Container Runtime        │   │
│  │   - CNI (Flannel/Canal)      │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Server + Agent 架构

```
┌──────────────────────┐    ┌──────────────────────┐
│   Server Nodes       │    │    Agent Nodes       │
│  ┌────────────────┐  │    │  ┌────────────────┐  │
│  │ Control Plane  │  │    │  │  Kubelet       │  │
│  │ + etcd         │◄─┼────┼─►│  + Runtime     │  │
│  └────────────────┘  │    │  └────────────────┘  │
│  ┌────────────────┐  │    │  ┌────────────────┐  │
│  │  API: 6443     │  │    │  │  Kubelet: 10250│  │
│  │  etcd: 2379-80 │  │    │  │  CNI: 8472     │  │
│  └────────────────┘  │    │  └────────────────┘  │
└──────────────────────┘    └──────────────────────┘
```

## 高可用架构

### HA 拓扑

```
                    ┌──────────────────────┐
                    │   Load Balancer      │
                    │   (HAProxy/Nginx)    │
                    │                      │
                    │   VIP: 192.168.1.100 │
                    │   Ports: 6443, 9345  │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼───────┐ ┌─────▼────────┐ ┌────▼─────────┐
    │   Server 1      │ │  Server 2    │ │  Server 3    │
    │   (Master)      │ │  (Master)    │ │  (Master)    │
    │                 │ │              │ │              │
    │  ┌───────────┐  │ │ ┌──────────┐ │ │ ┌──────────┐ │
    │  │ API       │  │ │ │ API      │ │ │ │ API      │ │
    │  │ Server    │  │ │ │ Server   │ │ │ │ Server   │ │
    │  └───────────┘  │ │ └──────────┘ │ │ └──────────┘ │
    │  ┌───────────┐  │ │ ┌──────────┐ │ │ ┌──────────┐ │
    │  │  etcd     │◄─┼─┼►│  etcd    │◄┼─┼►│  etcd    │ │
    │  │ (Raft)    │  │ │ │ (Raft)  │ │ │ │ (Raft)   │ │
    │  └───────────┘  │ │ └──────────┘ │ │ └──────────┘ │
    └─────────┬───────┘ └──────┬───────┘ └──────┬───────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼───────┐ ┌─────▼────────┐ ┌────▼─────────┐
    │   Agent 1       │ │  Agent 2     │ │  Agent N     │
    │   (Worker)      │ │  (Worker)    │ │  (Worker)    │
    └─────────────────┘ └──────────────┘ └──────────────┘
```

### HA 要求

#### etcd 集群

- **节点数量**: 奇数（3、5、7）
- **推荐配置**: 3 节点（可容忍 1 节点故障）
- **网络延迟**: < 10ms（理想情况）
- **磁盘**: SSD（etcd 对磁盘 IOPS 敏感）

#### 负载均衡器

**监听端口（RKE2）:**
- `6443`: Kubernetes API Server
- `9345`: RKE2 Server Join

**监听端口（K3S）:**
- `6443`: Kubernetes API Server (同时用于 Server Join)

**健康检查:**
```bash
# API Server 健康检查
curl -k https://localhost:6443/livez

# 或使用 TCP 检查
nc -zv localhost 6443
```

### 负载均衡器配置示例

#### HAProxy 配置

```haproxy
# /etc/haproxy/haproxy.cfg

global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Kubernetes API Server
frontend k8s-api
    bind *:6443
    mode tcp
    default_backend k8s-api-backend

backend k8s-api-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master1 192.168.1.11:6443 check inter 2000 rise 2 fall 3
    server master2 192.168.1.12:6443 check inter 2000 rise 2 fall 3
    server master3 192.168.1.13:6443 check inter 2000 rise 2 fall 3

# RKE2 Server Join Port
frontend rke2-join
    bind *:9345
    mode tcp
    default_backend rke2-join-backend

backend rke2-join-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master1 192.168.1.11:9345 check inter 2000 rise 2 fall 3
    server master2 192.168.1.12:9345 check inter 2000 rise 2 fall 3
    server master3 192.168.1.13:9345 check inter 2000 rise 2 fall 3

# 统计页面
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 5s
```

#### Nginx Stream 配置

```nginx
# /etc/nginx/nginx.conf

stream {
    upstream k8s_api {
        server 192.168.1.11:6443 max_fails=3 fail_timeout=10s;
        server 192.168.1.12:6443 max_fails=3 fail_timeout=10s;
        server 192.168.1.13:6443 max_fails=3 fail_timeout=10s;
    }

    upstream rke2_join {
        server 192.168.1.11:9345 max_fails=3 fail_timeout=10s;
        server 192.168.1.12:9345 max_fails=3 fail_timeout=10s;
        server 192.168.1.13:9345 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 6443;
        proxy_pass k8s_api;
        proxy_timeout 300s;
        proxy_connect_timeout 10s;
    }

    server {
        listen 9345;
        proxy_pass rke2_join;
        proxy_timeout 300s;
        proxy_connect_timeout 10s;
    }
}
```

## 组件说明

### RKE2 组件

```
RKE2 Server Node:
├── rke2-server (systemd 服务)
│   ├── containerd (容器运行时)
│   ├── kubelet
│   ├── kube-apiserver
│   ├── kube-controller-manager
│   ├── kube-scheduler
│   ├── kube-proxy
│   ├── etcd (嵌入式)
│   └── CNI (Canal/Calico/Cilium)
│
RKE2 Agent Node:
└── rke2-agent (systemd 服务)
    ├── containerd
    ├── kubelet
    └── kube-proxy
```

### K3S 组件

```
K3S Server Node:
├── k3s (systemd 服务)
│   ├── containerd (容器运行时)
│   ├── kubelet
│   ├── kube-apiserver
│   ├── kube-controller-manager
│   ├── kube-scheduler
│   ├── kube-proxy
│   ├── etcd (嵌入式)
│   ├── Flannel (默认 CNI)
│   ├── Traefik (Ingress Controller)
│   ├── ServiceLB (LoadBalancer)
│   └── Local Path Provisioner
│
K3S Agent Node:
└── k3s-agent (containerd + kubelet + kube-proxy)
```

## 端口矩阵

### RKE2 端口

#### Server 节点

| 端口 | 协议 | 方向 | 用途 | 必需 |
|------|------|------|------|------|
| 6443 | TCP | Inbound | Kubernetes API Server | ✅ |
| 9345 | TCP | Inbound | RKE2 Server Join | ✅ |
| 10250 | TCP | Inbound | Kubelet Metrics | ✅ |
| 2379 | TCP | Inbound | etcd Client | ✅ |
| 2380 | TCP | Inbound | etcd Peer | ✅ |
| 8472 | UDP | Bidirectional | VXLAN (Canal/Flannel) | CNI 相关 |
| 4789 | UDP | Bidirectional | VXLAN (Calico) | CNI 相关 |
| 5473 | TCP | Bidirectional | Calico BGP | CNI 相关 |
| 9099 | TCP | Inbound | Health Check | 可选 |
| 6444 | TCP | Inbound | RKE2 Agent Port | ✅ |

#### Agent 节点

| 端口 | 协议 | 方向 | 用途 | 必需 |
|------|------|------|------|------|
| 10250 | TCP | Inbound | Kubelet Metrics | ✅ |
| 8472 | UDP | Bidirectional | VXLAN (Canal/Flannel) | CNI 相关 |
| 4789 | UDP | Bidirectional | VXLAN (Calico) | CNI 相关 |
| 30000-32767 | TCP | Inbound | NodePort Services | 可选 |

### K3S 端口

#### Server 节点

| 端口 | 协议 | 方向 | 用途 | 必需 |
|------|------|------|------|------|
| 6443 | TCP | Inbound | Kubernetes API + Join | ✅ |
| 10250 | TCP | Inbound | Kubelet Metrics | ✅ |
| 2379 | TCP | Inbound | etcd Client | ✅ |
| 2380 | TCP | Inbound | etcd Peer | ✅ |
| 8472 | UDP | Bidirectional | VXLAN (Flannel) | ✅ |
| 10010 | TCP | Inbound | Health Check | 可选 |

#### Agent 节点

| 端口 | 协议 | 方向 | 用途 | 必需 |
|------|------|------|------|------|
| 10250 | TCP | Inbound | Kubelet Metrics | ✅ |
| 8472 | UDP | Bidirectional | VXLAN (Flannel) | ✅ |
| 30000-32767 | TCP | Inbound | NodePort Services | 可选 |

### 防火墙配置示例

#### firewalld (RHEL/CentOS)

```bash
# RKE2 Server
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=9345/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --reload

# RKE2 Agent
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --reload
```

#### ufw (Debian/Ubuntu)

```bash
# RKE2 Server
ufw allow 6443/tcp
ufw allow 9345/tcp
ufw allow 10250/tcp
ufw allow 2379:2380/tcp
ufw allow 8472/udp

# RKE2 Agent
ufw allow 10250/tcp
ufw allow 8472/udp
ufw allow 30000:32767/tcp
```

## 安全架构

### 1. TLS 证书

```
CA 证书层级:
├── cluster-ca (集群 CA)
│   ├── kube-apiserver-cert
│   ├── kubelet-client-cert
│   └── etcd-server-cert
│
├── client-ca (客户端 CA)
│   ├── admin-cert
│   └── controller-manager-cert
│
└── request-header-ca
    └── front-proxy-cert
```

### 2. 认证授权

```
认证方式:
├── X509 证书认证 (默认)
├── Service Account Tokens
└── Bootstrap Tokens

授权模式:
├── Node (节点授权)
├── RBAC (角色访问控制)
└── Webhook (可选)
```

### 3. 网络安全

```
网络策略:
├── CNI 网络隔离
├── NetworkPolicy 支持
└── Pod Security Policy / Pod Security Standards
```

## 存储架构

### etcd 存储

```
etcd 数据目录:
RKE2: /var/lib/rancher/rke2/server/db/etcd/
K3S:  /var/lib/rancher/k3s/server/db/etcd/

备份目录:
RKE2: /var/lib/rancher/rke2/server/db/snapshots/
K3S:  /var/lib/rancher/k3s/server/db/snapshots/
```

### 容器存储

```
Containerd 数据:
RKE2: /var/lib/rancher/rke2/agent/containerd/
K3S:  /var/lib/rancher/k3s/agent/containerd/

镜像存储:
RKE2: /var/lib/rancher/rke2/agent/containerd/io.containerd.content.v1.content/
K3S:  /var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content/
```

---

**文档版本**: 1.0.0  
**最后更新**: 2025-01-05
