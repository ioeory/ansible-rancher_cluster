# 快速开始指南

3 分钟快速部署 RKE2/K3S 集群！

## 🚀 极速部署

### 单节点测试集群

```bash
# 1. 初始化配置
make setup

# 2. 编辑主机清单
cat > inventory/hosts.ini <<EOF
[rke_servers]
test-node ansible_host=192.168.1.10 cluster_init=true

[all:vars]
ansible_user=root
cluster_type=rke2
EOF

# 3. 执行安装
make install

# 4. 验证（在目标节点执行）
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get nodes
```

### 高可用集群

```bash
# 1. 配置主机清单
cat > inventory/hosts.ini <<EOF
[rke_servers]
master1 ansible_host=192.168.1.11 cluster_init=true
master2 ansible_host=192.168.1.12
master3 ansible_host=192.168.1.13

[rke_agents]
worker1 ansible_host=192.168.1.21
worker2 ansible_host=192.168.1.22

[all:vars]
ansible_user=root
cluster_type=rke2
server_url=https://192.168.1.100:9345
tls_san=['192.168.1.100', 'k8s.example.com']
EOF

# 2. 编辑变量（可选）
vim inventory/group_vars/all.yml

# 3. 安装
make install
```

### 中国大陆部署

```bash
# 一键安装（自动启用镜像加速）
make install-china
```

## 📋 前置条件

### 控制节点（执行 Ansible 的机器）

```bash
# 安装 Ansible
pip3 install -r requirements.txt

# 配置 SSH 免密
ssh-copy-id root@<target-host>
```

### 目标节点要求

- **操作系统**: Debian 12+ / Ubuntu 22.04+ / RHEL 8+
- **架构**: AMD64 或 ARM64
- **内存**: Server 4GB+ / Agent 2GB+
- **磁盘**: 20GB+

## 🔧 常用命令

```bash
# 检查连接
make check

# 查看集群状态
make status

# 备份 etcd
make backup

# 升级集群
make upgrade

# 卸载
make uninstall
```

## 📚 下一步

- [完整安装指南](docs/installation-guide.md)
- [架构设计](docs/architecture.md)
- [中国部署指南](docs/china-deployment.md)
- [故障排查](docs/troubleshooting.md)

## ❓ 常见问题

**Q: 如何切换到 K3S？**
```bash
# 在 inventory/group_vars/all.yml 中设置
cluster_type: k3s

# 或使用 Makefile
make install-k3s
```

**Q: 镜像拉取慢？**
```bash
# 启用中国镜像源
china_region: true
enable_registry_mirrors: true
```

**Q: 节点加入失败？**
```bash
# 检查防火墙和 Token
make check
cat /tmp/rke2-token.txt
```

## 🆘 获取帮助

- 📖 [完整文档](README.md)
- 🐛 [报告问题](https://github.com/your-org/rke2-k3s-ansible/issues)
- 💬 [讨论区](https://github.com/your-org/rke2-k3s-ansible/discussions)

---

**快速部署，生产就绪！** 🎉
