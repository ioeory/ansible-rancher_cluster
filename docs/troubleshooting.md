# 故障排查指南

本文档提供常见问题的诊断和解决方案。

## 目录

- [诊断工具](#诊断工具)
- [安装问题](#安装问题)
- [网络问题](#网络问题)
- [集群问题](#集群问题)
- [性能问题](#性能问题)
- [升级问题](#升级问题)
- [日志查看](#日志查看)

## 诊断工具

### 基础诊断命令

```bash
# 检查服务状态
systemctl status rke2-server
systemctl status rke2-agent
systemctl status k3s

# 查看服务日志
journalctl -u rke2-server -f
journalctl -u rke2-agent -f
journalctl -u k3s -f

# 检查节点状态
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get nodes -o wide

# 检查系统 Pod
kubectl get pods -n kube-system

# 检查组件健康
kubectl get componentstatuses

# 查看集群信息
kubectl cluster-info
```

### Makefile 快捷命令

```bash
# 检查连接
make ping

# 查看集群状态
make status

# 查看所有 Pod
make pods

# 查看日志
make logs

# 查看版本
make version
```

## 安装问题

### 问题 1: Ansible 连接失败

**症状**:
```
fatal: [node1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**诊断**:
```bash
# 测试 SSH 连接
ssh root@<target-host>

# 检查 SSH 密钥
ssh-add -l

# 测试 Ansible ping
ansible -i inventory/hosts.ini all -m ping
```

**解决方案**:

```bash
# 方法 1: 配置 SSH 密钥
ssh-keygen -t rsa -b 4096
ssh-copy-id root@<target-host>

# 方法 2: 使用密码认证
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --ask-pass

# 方法 3: 检查 known_hosts
ssh-keygen -R <target-host>
```

### 问题 2: 预检查失败 - 操作系统不支持

**症状**:
```
FAILED! => {"assertion": false, "msg": "不支持的操作系统: CentOS 7"}
```

**解决方案**:

系统要求：
- Debian 12+
- Ubuntu 22.04+
- CentOS/RHEL 8+
- OpenAnolis 8+

升级操作系统或使用支持的版本。

### 问题 3: 内存不足

**症状**:
```
FAILED! => {"assertion": false, "msg": "内存不足，至少需要 2GB"}
```

**解决方案**:

```bash
# 检查内存
free -h

# Server 节点最少 4GB
# Agent 节点最少 2GB

# 增加内存或调整虚拟机配置
```

### 问题 4: 磁盘空间不足

**症状**:
```
FAILED! => {"assertion": false, "msg": "磁盘空间不足"}
```

**解决方案**:

```bash
# 检查磁盘空间
df -h

# 清理不必要的文件
apt clean
yum clean all

# 清理 Docker 镜像（如果有旧的 Docker）
docker system prune -a

# 最少需要 20GB 可用空间
```

### 问题 5: 端口被占用

**症状**:
```
Warning: 端口 6443 已被占用 (Kubernetes API Server)
```

**诊断**:
```bash
# 检查端口占用
netstat -tulnp | grep 6443
lsof -i :6443

# 查看占用进程
ps aux | grep <PID>
```

**解决方案**:

```bash
# 停止占用进程
systemctl stop <service-name>
# 或
kill <PID>

# 如果是旧的 K8s 集群，先卸载
make uninstall
```

### 问题 6: 安装脚本下载超时

**症状**:
```
FAILED! => {"msg": "Request failed", "status_code": -1}
```

**解决方案**:

```bash
# 方法 1: 启用中国镜像源
# 在 inventory/group_vars/all.yml 中设置
china_region: true

# 方法 2: 增加重试次数
download_retries: 5

# 方法 3: 增加超时时间
install_timeout: 3600

# 方法 4: 手动下载
wget https://rancher-mirror.rancher.cn/rke2/install.sh
```

## 网络问题

### 问题 1: 节点无法加入集群

**症状**:
```
Error: failed to connect to server: connection refused
```

**诊断**:
```bash
# 检查 Server 节点 API 是否可访问
curl -k https://<server-ip>:6443

# 检查网络连通性
ping <server-ip>
telnet <server-ip> 6443
nc -zv <server-ip> 6443 9345

# 检查防火墙
systemctl status firewalld
ufw status
```

**解决方案**:

```bash
# 方法 1: 配置防火墙规则
# Debian/Ubuntu
ufw allow 6443/tcp
ufw allow 9345/tcp  # RKE2
ufw allow 10250/tcp
ufw allow 2379:2380/tcp

# RHEL/CentOS
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=9345/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --reload

# 方法 2: 临时禁用防火墙（测试用）
systemctl stop firewalld
ufw disable

# 方法 3: 自动配置防火墙
# 在 all.yml 中设置
configure_firewall: true
```

### 问题 2: Token 错误

**症状**:
```
Error: invalid token
```

**解决方案**:

```bash
# 在首个 Server 节点查看 Token
cat /var/lib/rancher/rke2/server/node-token
# 或
cat /var/lib/rancher/k3s/server/node-token

# 或查看保存的 Token
cat /tmp/rke2-token.txt

# 更新 Inventory 配置
# inventory/group_vars/all.yml
cluster_token: "<正确的-token>"

# 使用 ansible-vault 加密
ansible-vault encrypt_string '<token>' --name 'cluster_token'
```

### 问题 3: 镜像拉取失败

**症状**:
```
Failed to pull image "docker.io/rancher/pause:3.6": rpc error: code = Unknown
```

**诊断**:
```bash
# 检查镜像源配置
cat /etc/rancher/rke2/registries.yaml

# 测试镜像源连通性
curl -I https://dockerhub.mirrors.sjtug.sjtu.edu.cn

# 手动拉取测试
ctr --namespace k8s.io images pull docker.io/library/nginx:latest
```

**解决方案**:

```bash
# 方法 1: 启用镜像加速（中国大陆）
china_region: true
enable_registry_mirrors: true

# 方法 2: 手动配置镜像源
cat > /etc/rancher/rke2/registries.yaml <<EOF
mirrors:
  docker.io:
    endpoint:
      - "https://dockerhub.mirrors.sjtug.sjtu.edu.cn"
      - "https://docker.m.daocloud.io"
EOF

# 重启服务
systemctl restart rke2-server

# 方法 3: 使用代理
# 在 /etc/systemd/system/rke2-server.service.d/override.conf
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8"

systemctl daemon-reload
systemctl restart rke2-server
```

### 问题 4: DNS 解析失败

**症状**:
```
dial tcp: lookup example.com: no such host
```

**解决方案**:

```bash
# 检查 DNS 配置
cat /etc/resolv.conf

# 配置可靠的 DNS
cat > /etc/resolv.conf <<EOF
nameserver 223.5.5.5
nameserver 119.29.29.29
nameserver 8.8.8.8
EOF

# 测试 DNS
nslookup google.com
dig google.com

# 永久配置（systemd-resolved）
cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=223.5.5.5 119.29.29.29
FallbackDNS=8.8.8.8
EOF

systemctl restart systemd-resolved
```

## 集群问题

### 问题 1: 节点 NotReady

**症状**:
```
NAME     STATUS     ROLES    AGE   VERSION
node1    NotReady   master   5m    v1.28.5
```

**诊断**:
```bash
# 查看节点详情
kubectl describe node <node-name>

# 检查 kubelet 日志
journalctl -u rke2-server -n 100
journalctl -u rke2-agent -n 100

# 检查 CNI
kubectl get pods -n kube-system | grep -E 'canal|flannel|calico'
```

**解决方案**:

```bash
# 检查 CNI Pod 状态
kubectl get pods -n kube-system -o wide

# 重启 CNI Pod
kubectl delete pod -n kube-system <cni-pod-name>

# 重启节点服务
systemctl restart rke2-server
systemctl restart rke2-agent

# 检查内核模块
lsmod | grep br_netfilter
lsmod | grep overlay

# 加载模块
modprobe br_netfilter
modprobe overlay
```

### 问题 2: etcd 集群不健康

**症状**:
```
Error: etcd cluster is unhealthy
```

**诊断**:
```bash
# 检查 etcd 成员
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl get endpoints -n kube-system etcd

# RKE2 etcd 命令
rke2 etcd-snapshot ls
rke2 etcd-snapshot save

# 查看 etcd 日志
journalctl -u rke2-server | grep etcd
```

**解决方案**:

```bash
# 方法 1: 重启 etcd 成员
systemctl restart rke2-server

# 方法 2: 从备份恢复
rke2 server --cluster-reset --cluster-reset-restore-path=<snapshot-file>

# 方法 3: 重建 etcd 成员
# 查看成员列表
# 移除故障成员
# 添加新成员
```

### 问题 3: Pod 一直处于 Pending 状态

**症状**:
```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7854ff8877-xxxxx   0/1     Pending   0          5m
```

**诊断**:
```bash
# 查看 Pod 详情
kubectl describe pod <pod-name>

# 查看事件
kubectl get events --sort-by='.lastTimestamp'

# 检查节点资源
kubectl top nodes
kubectl describe nodes
```

**常见原因和解决方案**:

1. **资源不足**
```bash
# 检查节点资源
kubectl describe nodes | grep -A 5 "Allocated resources"

# 增加节点或删除不需要的 Pod
kubectl delete pod <pod-name>
```

2. **节点选择器不匹配**
```bash
# 检查 Pod 的 nodeSelector
kubectl get pod <pod-name> -o yaml | grep -A 5 nodeSelector

# 添加标签到节点
kubectl label nodes <node-name> key=value
```

3. **污点和容忍度**
```bash
# 检查节点污点
kubectl describe node <node-name> | grep Taints

# 删除污点
kubectl taint nodes <node-name> key:NoSchedule-
```

### 问题 4: Service 无法访问

**症状**:
```
curl: (7) Failed to connect to service-ip port 80: Connection refused
```

**诊断**:
```bash
# 检查 Service
kubectl get svc
kubectl describe svc <service-name>

# 检查 Endpoints
kubectl get endpoints <service-name>

# 检查 Pod
kubectl get pods -o wide
kubectl logs <pod-name>

# 测试 Pod IP
curl <pod-ip>:<port>
```

**解决方案**:

```bash
# 检查 Service 选择器
kubectl get svc <service-name> -o yaml | grep selector

# 检查 Pod 标签
kubectl get pods --show-labels

# 确保标签匹配
kubectl label pods <pod-name> key=value

# 检查 kube-proxy
kubectl get pods -n kube-system | grep proxy
kubectl logs -n kube-system <kube-proxy-pod>
```

## 性能问题

### 问题 1: API Server 响应慢

**诊断**:
```bash
# 检查 API Server 日志
journalctl -u rke2-server | grep apiserver

# 检查资源使用
top
htop
kubectl top nodes
```

**解决方案**:

```bash
# 增加 API Server 资源限制
# 编辑配置文件添加参数
kube_apiserver_args:
  - "max-requests-inflight=800"
  - "max-mutating-requests-inflight=400"

# 优化 etcd
# 使用 SSD 存储
# 增加 etcd 内存
```

### 问题 2: 节点负载高

**诊断**:
```bash
# 检查系统负载
uptime
top
htop

# 检查磁盘 IO
iostat -x 1
iotop

# 检查网络
iftop
nethogs
```

**解决方案**:

```bash
# 限制 Pod 资源
kubectl set resources deployment/<name> --limits=cpu=500m,memory=512Mi

# 配置资源配额
kubectl create quota <name> --hard=cpu=10,memory=20Gi

# 添加更多节点分散负载
```

## 升级问题

### 问题 1: 升级失败

**症状**:
```
FAILED! => {"msg": "Upgrade failed"}
```

**解决方案**:

```bash
# 检查升级前备份
ls /var/lib/rancher/rke2/server/db/snapshots/

# 从备份恢复
systemctl stop rke2-server
rke2 server --cluster-reset --cluster-reset-restore-path=<snapshot-file>
systemctl start rke2-server

# 手动升级
INSTALL_RKE2_VERSION=v1.28.5+rke2r1 sh install.sh
systemctl restart rke2-server
```

### 问题 2: 升级后节点 NotReady

**诊断和解决**:

参考 [节点 NotReady](#问题-1-节点-notready) 部分

## 日志查看

### 系统日志

```bash
# RKE2 Server
journalctl -u rke2-server -f
journalctl -u rke2-server -n 100 --no-pager
journalctl -u rke2-server --since "1 hour ago"

# RKE2 Agent
journalctl -u rke2-agent -f

# K3S
journalctl -u k3s -f

# 查看特定时间段
journalctl -u rke2-server --since "2025-01-05 10:00" --until "2025-01-05 11:00"

# 导出日志
journalctl -u rke2-server > /tmp/rke2-server.log
```

### Kubernetes 日志

```bash
# Pod 日志
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous  # 查看之前容器的日志
kubectl logs -f <pod-name>  # 实时查看

# 系统组件日志
kubectl logs -n kube-system <pod-name>

# 所有容器日志
kubectl logs <pod-name> --all-containers=true

# 查看事件
kubectl get events -A --sort-by='.lastTimestamp'
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### 调试工具

```bash
# 进入容器
kubectl exec -it <pod-name> -- /bin/bash

# 多容器 Pod
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# 端口转发
kubectl port-forward <pod-name> 8080:80

# 复制文件
kubectl cp <pod-name>:/path/to/file /local/path
kubectl cp /local/path <pod-name>:/path/to/file

# 临时调试 Pod
kubectl run debug --image=busybox -it --rm -- sh
kubectl run debug --image=nicolaka/netshoot -it --rm -- bash
```

## 获取帮助

### 社区支持

- RKE2 GitHub: https://github.com/rancher/rke2/issues
- K3S GitHub: https://github.com/k3s-io/k3s/issues
- Rancher Forums: https://forums.rancher.com/
- Rancher Slack: https://slack.rancher.io/

### 收集诊断信息

创建 Issue 时，请提供以下信息：

```bash
# 1. 版本信息
rke2 --version
kubectl version

# 2. 系统信息
uname -a
cat /etc/os-release

# 3. 节点状态
kubectl get nodes -o wide

# 4. Pod 状态
kubectl get pods -A -o wide

# 5. 服务日志
journalctl -u rke2-server -n 200 --no-pager > rke2-server.log

# 6. 描述详细信息
kubectl describe node <node-name> > node-describe.txt
kubectl describe pod <pod-name> > pod-describe.txt

# 打包诊断信息
tar czf diagnostic-$(date +%Y%m%d-%H%M%S).tar.gz *.log *.txt
```

---

**文档版本**: 1.0.0  
**最后更新**: 2025-01-05
