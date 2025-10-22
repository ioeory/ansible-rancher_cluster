# K3S 和 RKE2 服务名称说明

## 服务名称对比

### K3S

| 节点类型 | 服务名称 | systemd 单元 |
|---------|---------|-------------|
| Server | `k3s` | `k3s.service` |
| Agent | `k3s-agent` | `k3s-agent.service` |

**配置目录：** `/etc/rancher/k3s/`  
**配置文件：** `/etc/rancher/k3s/config.yaml`  
**数据目录：** `/var/lib/rancher/k3s/`

### RKE2

| 节点类型 | 服务名称 | systemd 单元 |
|---------|---------|-------------|
| Server | `rke2-server` | `rke2-server.service` |
| Agent | `rke2-agent` | `rke2-agent.service` |

**配置目录：** `/etc/rancher/rke2/`  
**配置文件：** `/etc/rancher/rke2/config.yaml`  
**数据目录：** `/var/lib/rancher/rke2/`

## 服务管理命令

### K3S

```bash
# Server 节点
sudo systemctl status k3s
sudo systemctl start k3s
sudo systemctl stop k3s
sudo systemctl restart k3s
sudo journalctl -u k3s -f

# Agent 节点
sudo systemctl status k3s-agent
sudo systemctl start k3s-agent
sudo systemctl stop k3s-agent
sudo systemctl restart k3s-agent
sudo journalctl -u k3s-agent -f
```

### RKE2

```bash
# Server 节点
sudo systemctl status rke2-server
sudo systemctl start rke2-server
sudo systemctl stop rke2-server
sudo systemctl restart rke2-server
sudo journalctl -u rke2-server -f

# Agent 节点
sudo systemctl status rke2-agent
sudo systemctl start rke2-agent
sudo systemctl stop rke2-agent
sudo systemctl restart rke2-agent
sudo journalctl -u rke2-agent -f
```

## Ansible 变量配置

我们的 Ansible playbook 会根据集群类型和节点角色自动设置正确的服务名称：

```yaml
# roles/rke_k3s/vars/k3s.yml
service_name: "{{ 'k3s' if node_role == 'server' else 'k3s-agent' }}"

# roles/rke_k3s/vars/rke2.yml
service_name: "rke2-{{ node_role }}"
```

## 常见问题

### 错误：Could not find the requested service k3s: host

**原因：** Agent 节点使用了错误的服务名 `k3s` 而不是 `k3s-agent`

**解决方案：** 已在 `roles/rke_k3s/vars/k3s.yml` 中修复，确保根据 `node_role` 动态设置服务名称

### 如何判断节点类型

```bash
# 查看正在运行的服务
systemctl list-units --type=service | grep -E '(k3s|rke2)'

# K3S Server 节点会显示：
# k3s.service    loaded active running    Lightweight Kubernetes

# K3S Agent 节点会显示：
# k3s-agent.service    loaded active running    Lightweight Kubernetes

# RKE2 Server 节点会显示：
# rke2-server.service    loaded active running    Rancher Kubernetes Engine v2 (server)

# RKE2 Agent 节点会显示：
# rke2-agent.service    loaded active running    Rancher Kubernetes Engine v2 (agent)
```

## 卸载服务

### K3S

```bash
# Server 节点
/usr/local/bin/k3s-uninstall.sh

# Agent 节点
/usr/local/bin/k3s-agent-uninstall.sh
```

### RKE2

```bash
# Server 节点
/usr/local/bin/rke2-uninstall.sh

# Agent 节点（需手动删除）
/usr/local/bin/rke2-uninstall.sh
systemctl stop rke2-agent
systemctl disable rke2-agent
rm -rf /etc/rancher/rke2
rm -rf /var/lib/rancher/rke2
```

## API 端口

### K3S

| 组件 | 端口 | 说明 |
|-----|------|------|
| API Server | 6443 | Kubernetes API |
| Server Join | 6443 | 节点加入（复用 API 端口） |
| Kubelet | 10250 | Kubelet API |
| etcd | 2379-2380 | etcd 客户端和对等通信 |

### RKE2

| 组件 | 端口 | 说明 |
|-----|------|------|
| API Server | 6443 | Kubernetes API |
| Server Join | 9345 | 节点加入（独立端口） |
| Kubelet | 10250 | Kubelet API |
| etcd | 2379-2380 | etcd 客户端和对等通信 |

## 参考文档

- [K3S 官方文档](https://docs.k3s.io/)
- [RKE2 官方文档](https://docs.rke2.io/)

