# RKE2 集群部署成功总结

## 🎉 部署完成

**部署时间**: 2025-10-21  
**集群类型**: RKE2 v1.33.5  
**部署模式**: 高可用（3节点 etcd 集群）  
**网络环境**: 中国大陆（已启用镜像加速）

---

## 📊 集群信息

### 节点列表

| 主机名 | IP 地址 | 角色 | 状态 | 版本 |
|--------|---------|------|------|------|
| rancher-test-1 | 192.168.2.41 | control-plane, etcd, master | Ready | v1.33.5+rke2r1 |
| rancher-test-2 | 192.168.2.42 | control-plane, etcd, master | Ready | v1.33.5+rke2r1 |
| rancher-test-3 | 192.168.2.43 | control-plane, etcd, master | Ready | v1.33.5+rke2r1 |

### 系统组件

✅ **etcd**: 3 个实例（每个节点一个）  
✅ **API Server**: 3 个实例  
✅ **Controller Manager**: 3 个实例  
✅ **Scheduler**: 3 个实例  
✅ **CNI**: Canal (Calico + Flannel)  
✅ **Ingress**: NGINX Ingress Controller  
✅ **DNS**: CoreDNS (带自动扩缩容)  
✅ **Metrics**: Metrics Server  

### 集群 Token

```
K101dfe391913957ee6a5df6badd8bc25f13e06693bd7a3dc93554d1803fd8fca15::server:646eca6ba82104350f204fff573c1e37
```

**⚠️ 重要**: 请妥善保管此 Token，用于添加新节点到集群。

---

## 🔧 使用指南

### 1. SSH 连接到节点

```bash
# 连接到第一个节点
ssh -i ~/id_ed25519-ansible ioe@192.168.2.41

# 连接到其他节点
ssh -i ~/id_ed25519-ansible ioe@192.168.2.42
ssh -i ~/id_ed25519-ansible ioe@192.168.2.43
```

### 2. 使用 kubectl

#### 方法 1: 在节点上直接使用

```bash
# SSH 到任意 Server 节点
ssh -i ~/id_ed25519-ansible ioe@192.168.2.41

# 设置环境变量
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# 使用 kubectl（注意路径）
sudo /var/lib/rancher/rke2/bin/kubectl get nodes
sudo /var/lib/rancher/rke2/bin/kubectl get pods -A
```

#### 方法 2: 复制 kubeconfig 到本地

```bash
# 复制 kubeconfig 到本地
scp -i ~/id_ed25519-ansible ioe@192.168.2.41:/etc/rancher/rke2/rke2.yaml ~/.kube/config-rke2

# 修改 server 地址（将 127.0.0.1 改为实际 IP）
sed -i 's/127.0.0.1/192.168.2.41/g' ~/.kube/config-rke2

# 设置权限
chmod 600 ~/.kube/config-rke2

# 使用
export KUBECONFIG=~/.kube/config-rke2
kubectl get nodes
```

### 3. 常用命令

```bash
# 查看节点状态
kubectl get nodes -o wide

# 查看所有 Pod
kubectl get pods -A

# 查看系统组件
kubectl get pods -n kube-system

# 查看集群信息
kubectl cluster-info

# 创建测试 Deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# 查看服务
kubectl get svc

# 查看日志
kubectl logs -n kube-system <pod-name>
```

---

## 🔐 安全建议

### 1. 保护 kubeconfig

```bash
# 设置正确的权限
chmod 600 /etc/rancher/rke2/rke2.yaml

# 不要将 kubeconfig 提交到版本控制
```

### 2. 定期备份 etcd

```bash
# 手动备份
cd "/mnt/c/Users/ioe/Nextcloud/Documents/doocom/CICD/Ranche Kubernetes"
make backup

# 或在节点上执行
ssh -i ~/id_ed25519-ansible ioe@192.168.2.41
sudo rke2 etcd-snapshot save --name manual-backup-$(date +%Y%m%d)
```

### 3. 启用自动备份

编辑配置文件并重新部署：

```yaml
# inventory/group_vars/all.yml
enable_backup: true
etcd_snapshot_schedule: "0 */6 * * *"  # 每 6 小时
etcd_snapshot_retention: 10  # 保留 10 个备份
```

---

## 📈 集群管理

### 添加 Agent 节点

1. 编辑 inventory 配置：

```ini
# inventory/hosts.ini

[rke_k3s_agents]
worker1 ansible_host=192.168.2.51
worker2 ansible_host=192.168.2.52

[rke_k3s_agents:vars]
node_role=agent
```

2. 执行安装：

```bash
make install
```

### 升级集群

1. 编辑版本号：

```yaml
# inventory/group_vars/all.yml
install_version: "v1.34.0+rke2r1"  # 新版本
```

2. 执行升级：

```bash
make upgrade
```

### 检查集群状态

```bash
# 使用 Makefile
make status
make pods

# 或直接使用 Ansible
ansible -i inventory/hosts.ini all -m ping
```

---

## 🐛 故障排查

### 节点状态 NotReady

```bash
# 检查节点详情
kubectl describe node <node-name>

# 检查 kubelet 日志
ssh -i ~/id_ed25519-ansible ioe@192.168.2.41
sudo journalctl -u rke2-server -n 100
```

### Pod 无法启动

```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n <namespace>

# 查看 Pod 日志
kubectl logs <pod-name> -n <namespace>

# 查看事件
kubectl get events -A --sort-by='.lastTimestamp'
```

### 网络问题

```bash
# 检查 Canal Pod
kubectl get pods -n kube-system | grep canal

# 检查 CNI 配置
ls -la /etc/cni/net.d/
cat /etc/rancher/rke2/registries.yaml
```

---

## 📚 相关文档

- [README.md](README.md) - 项目主文档
- [docs/installation-guide.md](docs/installation-guide.md) - 详细安装指南
- [docs/architecture.md](docs/architecture.md) - 架构说明
- [docs/china-deployment.md](docs/china-deployment.md) - 中国部署指南
- [docs/troubleshooting.md](docs/troubleshooting.md) - 故障排查

---

## 🎯 下一步

### 1. 配置存储

```bash
# 使用 Longhorn（推荐）
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml

# 或使用 Local Path Provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### 2. 配置 Ingress

```bash
# RKE2 已默认安装 NGINX Ingress Controller
kubectl get pods -n kube-system | grep ingress

# 创建测试 Ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF
```

### 3. 安装监控

```bash
# 使用 Prometheus Operator
kubectl create namespace monitoring
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
```

### 4. 配置 GitOps (ArgoCD)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## ✅ 检查清单

- [x] 3 个 Server 节点成功部署
- [x] 所有节点状态 Ready
- [x] etcd 集群健康（3 个实例）
- [x] 系统组件运行正常
- [x] CNI 网络配置完成
- [x] 镜像加速配置生效
- [x] kubectl 访问正常

---

**部署成功！🎉**

集群已就绪，可以开始部署应用程序。

如有问题，请参考：
- 故障排查文档：[docs/troubleshooting.md](docs/troubleshooting.md)
- GitHub Issues
- 或联系运维团队
