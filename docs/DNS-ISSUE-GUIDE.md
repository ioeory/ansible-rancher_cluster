# RKE2/K3S DNS 问题解决指南

## 📋 问题描述

在安装 RKE2/K3S 集群后，某些节点的 `/etc/resolv.conf` 可能会被修改，导致 DNS 解析异常。

常见现象：
```bash
# 安装前
$ cat /etc/resolv.conf
nameserver 8.8.8.8
nameserver 114.114.114.114

# 安装后
$ cat /etc/resolv.conf
nameserver 10.167.0.10  # 或 10.43.0.10
```

## 🔍 原因分析

### 1. **RKE2/K3S 本身不会修改主机 DNS**

RKE2/K3S 不会直接修改主机的 `/etc/resolv.conf`。集群内的 DNS 地址（如 10.43.0.10 或 10.167.0.10）仅用于 Pod 内部。

### 2. **systemd-resolved 干预**

最常见的原因是 `systemd-resolved` 服务：

```bash
# 检查 systemd-resolved 状态
$ systemctl status systemd-resolved

# 检查 /etc/resolv.conf 是否为符号链接
$ ls -la /etc/resolv.conf
lrwxrwxrwx 1 root root 39 /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
```

**工作原理：**
- `systemd-resolved` 会创建 `/etc/resolv.conf` 符号链接指向 `/run/systemd/resolve/stub-resolv.conf`
- 该文件包含 `nameserver 127.0.0.53`（本地 stub resolver）
- `systemd-resolved` 监听网络变化，可能会根据 DHCP 或其他来源更新 DNS

### 3. **NetworkManager 影响**

NetworkManager 也可能修改 DNS 配置：

```bash
# 检查 NetworkManager 状态
$ systemctl status NetworkManager
```

### 4. **DHCP 客户端**

如果使用 DHCP 获取 IP，DHCP 客户端可能会从 DHCP 服务器获取 DNS 配置并覆盖 `/etc/resolv.conf`。

### 5. **为什么是 10.167.0.10？**

这个地址通常表示：
- 自定义了 `service_cidr: "10.167.0.0/16"`
- 集群 DNS 服务（CoreDNS）的 Service IP 是该网段的第10个IP
- **但这个 IP 不应该出现在主机的 /etc/resolv.conf 中**

## 🛠️ 解决方案

### 方案 1: 禁用 systemd-resolved（推荐）

在 `inventory/group_vars/all.yml` 中配置：

```yaml
# DNS 配置
disable_systemd_resolved: true
static_dns_servers:
  - "8.8.8.8"          # Google DNS
  - "114.114.114.114"  # 中国大陆 DNS
  - "223.5.5.5"        # 阿里云 DNS
```

**效果：**
- 停止并禁用 `systemd-resolved` 服务
- 创建静态 `/etc/resolv.conf` 文件
- 不再被自动修改

**适用场景：**
- 生产环境
- 需要固定 DNS 配置
- 不依赖 systemd-resolved 的其他功能

### 方案 2: 配置 systemd-resolved 不干预

在 `inventory/group_vars/all.yml` 中配置：

```yaml
# DNS 配置
configure_systemd_resolved: true
static_dns_servers:
  - "8.8.8.8"
  - "114.114.114.114"
```

**效果：**
- 保持 `systemd-resolved` 运行
- 配置其不修改 `/etc/resolv.conf`
- 创建静态 `/etc/resolv.conf` 文件

**适用场景：**
- 其他服务依赖 systemd-resolved
- 需要 mDNS/LLMNR 等功能
- 希望保持系统服务完整性

### 方案 3: 设置 resolv.conf 为不可变

在 `inventory/group_vars/all.yml` 中配置：

```yaml
# DNS 配置
static_dns_servers:
  - "8.8.8.8"
  - "114.114.114.114"
immutable_resolv_conf: true  # 设置为不可变
```

**效果：**
- 使用 `chattr +i /etc/resolv.conf` 设置不可变属性
- 任何进程（包括 root）都无法修改该文件
- 需要手动 `chattr -i` 才能修改

**注意：**
- 维护时需要记得移除不可变属性
- 可能影响某些正常的系统管理操作

```bash
# 移除不可变属性
chattr -i /etc/resolv.conf

# 重新设置不可变属性
chattr +i /etc/resolv.conf
```

### 方案 4: 配置 NetworkManager 不管理 DNS

如果使用 NetworkManager，创建配置文件：

```bash
cat > /etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=none
systemd-resolved=false
EOF

# 重启 NetworkManager
systemctl restart NetworkManager
```

## 📝 完整配置示例

### 示例 1: 生产环境（禁用 systemd-resolved）

```yaml
# inventory/group_vars/all.yml

# DNS 配置
disable_systemd_resolved: true
preserve_dns_config: true        # 备份原配置
static_dns_servers:
  - "8.8.8.8"
  - "8.8.4.4"
  - "114.114.114.114"
dns_search_domains:
  - "example.com"
immutable_resolv_conf: false     # 不设置不可变
```

### 示例 2: 开发环境（配置 systemd-resolved）

```yaml
# inventory/group_vars/all.yml

# DNS 配置
disable_systemd_resolved: false
configure_systemd_resolved: true  # 配置但不禁用
preserve_dns_config: true
static_dns_servers:
  - "8.8.8.8"
  - "114.114.114.114"
immutable_resolv_conf: false
```

### 示例 3: 高安全环境（不可变 DNS）

```yaml
# inventory/group_vars/all.yml

# DNS 配置
disable_systemd_resolved: true
preserve_dns_config: true
static_dns_servers:
  - "10.0.0.53"  # 内网 DNS
  - "10.0.1.53"
immutable_resolv_conf: true  # 设置不可变
```

## 🔧 手动修复步骤

如果已经安装了集群，DNS 被修改，可以手动修复：

### 步骤 1: 检查当前状态

```bash
# 检查 resolv.conf
cat /etc/resolv.conf

# 检查是否为符号链接
ls -la /etc/resolv.conf

# 检查 systemd-resolved 状态
systemctl status systemd-resolved
```

### 步骤 2: 禁用 systemd-resolved

```bash
# 停止并禁用服务
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# 删除符号链接
rm -f /etc/resolv.conf
```

### 步骤 3: 创建静态 DNS 配置

```bash
# 创建新的 resolv.conf
cat > /etc/resolv.conf <<EOF
# 静态 DNS 配置
nameserver 8.8.8.8
nameserver 114.114.114.114
options timeout:2 attempts:3 rotate
EOF

# 设置为不可变（可选）
chattr +i /etc/resolv.conf
```

### 步骤 4: 验证

```bash
# 测试 DNS 解析
nslookup google.com
dig google.com

# 检查文件属性
lsattr /etc/resolv.conf
```

## 📊 方案对比

| 方案 | 优点 | 缺点 | 推荐场景 |
|------|------|------|----------|
| **禁用 systemd-resolved** | 简单直接，DNS 完全可控 | 失去 systemd-resolved 功能 | 生产环境，固定 DNS |
| **配置 systemd-resolved** | 保留服务功能，兼容性好 | 配置稍复杂 | 需要 systemd-resolved 功能 |
| **设置不可变** | 最强保护，任何进程都无法修改 | 维护不便 | 高安全要求环境 |
| **配置 NetworkManager** | 保留网络管理功能 | 可能与其他配置冲突 | 桌面环境 |

## 🔍 故障排查

### 问题 1: DNS 配置后仍被修改

**检查：**
```bash
# 查看谁在修改 resolv.conf
auditctl -w /etc/resolv.conf -p wa

# 查看审计日志
ausearch -f /etc/resolv.conf
```

**可能原因：**
- DHCP 客户端（dhclient, dhcpcd）
- NetworkManager
- 云平台代理（如 cloud-init）

### 问题 2: 集群 DNS 不工作

**注意：** 修改主机 DNS 不影响 Pod 内的 DNS。

**检查集群 DNS：**
```bash
# 在 master 节点
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml  # 或 k3s.yaml

# 检查 CoreDNS
kubectl get pods -n kube-system | grep dns

# 检查 DNS Service
kubectl get svc -n kube-system | grep dns

# 测试 DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

### 问题 3: 无法访问外网

**检查：**
```bash
# 测试 DNS 解析
nslookup google.com

# 测试网络连接
ping 8.8.8.8
ping google.com

# 检查路由
ip route
```

## 📚 相关资源

- [systemd-resolved 官方文档](https://www.freedesktop.org/software/systemd/man/systemd-resolved.service.html)
- [Kubernetes DNS 规范](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [RKE2 网络配置](https://docs.rke2.io/networking/basic_network_options)
- [K3S 网络配置](https://docs.k3s.io/networking)

## 💡 最佳实践

1. **生产环境推荐：**
   - 禁用 `systemd-resolved`
   - 使用静态 DNS 配置
   - 配置企业内部 DNS 服务器

2. **开发/测试环境：**
   - 配置 `systemd-resolved` 不干预
   - 使用公共 DNS（如 8.8.8.8）

3. **监控 DNS 配置：**
   ```bash
   # 定期检查
   watch -n 60 'cat /etc/resolv.conf'
   
   # 或使用监控工具
   inotifywait -m /etc/resolv.conf
   ```

4. **文档化配置：**
   - 记录 DNS 服务器地址
   - 记录修改原因和时间
   - 团队共享配置说明

## 🚀 快速修复命令

```bash
# 一键禁用 systemd-resolved 并配置静态 DNS
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 114.114.114.114
options timeout:2 attempts:3 rotate
EOF
sudo chattr +i /etc/resolv.conf

echo "DNS 配置已修复并设置为不可变"
```

## ⚠️ 注意事项

1. **备份重要：** 修改前务必备份 `/etc/resolv.conf`
2. **测试验证：** 修改后测试 DNS 解析是否正常
3. **团队沟通：** 修改 DNS 配置需通知团队成员
4. **监控告警：** 建议配置 DNS 变更监控和告警
5. **文档更新：** 记录所有 DNS 相关的配置变更

