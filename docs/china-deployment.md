# 中国大陆部署指南

本文档专门针对中国大陆地区的网络环境，提供优化的部署方案和配置指南。

## 目录

- [背景说明](#背景说明)
- [快速部署](#快速部署)
- [镜像源配置](#镜像源配置)
- [网络优化](#网络优化)
- [离线安装](#离线安装)
- [常见问题](#常见问题)

## 背景说明

### 中国大陆网络挑战

在中国大陆部署 Kubernetes 集群时，常常面临以下网络问题：

1. **官方镜像源访问缓慢或不可达**
   - Docker Hub (docker.io)
   - Google Container Registry (gcr.io, registry.k8s.io)
   - GitHub Container Registry (ghcr.io)
   - Quay.io

2. **安装脚本下载失败**
   - https://get.rke2.io
   - https://get.k3s.io
   - GitHub Releases

3. **二进制文件下载超时**
   - RKE2/K3S 二进制包
   - CNI 插件
   - 容器镜像

### 解决方案

本项目提供以下优化措施：

- ✅ 使用 **Rancher 中国镜像源** (rancher.cn)
- ✅ 自动配置 **容器镜像加速**
- ✅ 支持 **离线安装包**（可选）
- ✅ 提供多个 **镜像源备份**

## 快速部署

### 方法 1: 使用 Makefile（推荐）

```bash
# 一键安装（自动启用中国镜像）
make install-china
```

### 方法 2: 使用 Ansible Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/install.yml \
  -e "china_region=true"
```

### 方法 3: 配置文件

编辑 `inventory/group_vars/all.yml`:

```yaml
# 启用中国大陆模式
china_region: true

# 启用镜像加速
enable_registry_mirrors: true
```

然后执行标准安装：

```bash
make install
```

## 镜像源配置

### 1. 安装脚本镜像源

启用 `china_region: true` 后，自动使用以下镜像源：

#### RKE2

```bash
# 官方源（国外）
https://get.rke2.io

# 中国镜像源（自动切换）
https://rancher-mirror.rancher.cn/rke2/install.sh
```

#### K3S

```bash
# 官方源（国外）
https://get.k3s.io

# 中国镜像源（自动切换）
https://rancher-mirror.rancher.cn/k3s/k3s-install.sh
```

### 2. 容器镜像加速

自动配置 Containerd 镜像源加速，配置文件位置：

- RKE2: `/etc/rancher/rke2/registries.yaml`
- K3S: `/etc/rancher/k3s/registries.yaml`

#### 默认镜像源配置

```yaml
mirrors:
  # Docker Hub 镜像
  docker.io:
    endpoint:
      - https://dockerhub.mirrors.sjtug.sjtu.edu.cn  # 上海交通大学
      - https://docker.m.daocloud.io                 # DaoCloud
      - https://docker.nju.edu.cn                    # 南京大学

  # Kubernetes 官方镜像
  registry.k8s.io:
    endpoint:
      - https://k8s-gcr.m.daocloud.io                # DaoCloud
      - https://registry.aliyuncs.com/google_containers  # 阿里云

  # Google Container Registry
  gcr.io:
    endpoint:
      - https://gcr.m.daocloud.io

  # GitHub Container Registry
  ghcr.io:
    endpoint:
      - https://ghcr.m.daocloud.io

  # Quay.io
  quay.io:
    endpoint:
      - https://quay.m.daocloud.io

  # Microsoft Container Registry
  mcr.microsoft.com:
    endpoint:
      - https://mcr.m.daocloud.io
```

### 3. 自定义镜像源

#### 使用阿里云镜像加速器

1. 登录阿里云容器镜像服务：https://cr.console.aliyun.com/
2. 获取专属加速器地址（例如：`https://xxxxx.mirror.aliyuncs.com`）
3. 修改配置文件 `roles/rke_k3s/vars/china_mirrors.yml`:

```yaml
registry_mirrors:
  docker.io:
    - "https://xxxxx.mirror.aliyuncs.com"  # 替换为你的加速器地址
    - "https://docker.m.daocloud.io"
```

#### 使用腾讯云镜像加速器

```yaml
registry_mirrors:
  docker.io:
    - "https://mirror.ccs.tencentyun.com"
```

### 4. 验证镜像加速

```bash
# 查看配置文件
cat /etc/rancher/rke2/registries.yaml

# 测试拉取镜像
ctr images pull docker.io/library/nginx:latest

# 查看拉取日志
journalctl -u rke2-server -f
```

## 网络优化

### 1. DNS 优化

#### 配置国内 DNS 服务器

```bash
# 编辑 /etc/resolv.conf
nameserver 223.5.5.5      # 阿里 DNS
nameserver 119.29.29.29   # 腾讯 DNS
nameserver 114.114.114.114 # 114 DNS
```

#### 永久配置（systemd-resolved）

```bash
# 编辑 /etc/systemd/resolved.conf
[Resolve]
DNS=223.5.5.5 119.29.29.29
FallbackDNS=114.114.114.114
```

### 2. 系统软件源优化

#### Debian/Ubuntu

```bash
# 备份原始源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 使用清华大学镜像源
# Debian 12
sudo tee /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Ubuntu 22.04
sudo tee /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF

# 更新
sudo apt update
```

#### RHEL/CentOS/Anolis

```bash
# 使用阿里云镜像源
# CentOS 8
sudo tee /etc/yum.repos.d/CentOS-Base.repo <<EOF
[BaseOS]
name=CentOS Stream 8 - BaseOS
baseurl=https://mirrors.aliyun.com/centos-stream/8-stream/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=https://mirrors.aliyun.com/centos-stream/RPM-GPG-KEY-CentOS-Official

[AppStream]
name=CentOS Stream 8 - AppStream
baseurl=https://mirrors.aliyun.com/centos-stream/8-stream/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=https://mirrors.aliyun.com/centos-stream/RPM-GPG-KEY-CentOS-Official
EOF

# 清理并更新缓存
sudo yum clean all
sudo yum makecache
```

### 3. 时间同步

```bash
# 使用国内 NTP 服务器
sudo timedatectl set-ntp false
sudo timedatectl set-ntp true

# 编辑 /etc/systemd/timesyncd.conf
[Time]
NTP=ntp.aliyun.com ntp.tencent.com cn.pool.ntp.org

# 重启服务
sudo systemctl restart systemd-timesyncd
sudo timedatectl status
```

## 离线安装

对于完全无法访问互联网的环境，可以使用离线安装包。

### 1. 准备离线安装包

在有互联网连接的机器上：

#### 下载 RKE2 离线包

```bash
# 设置版本
VERSION=v1.28.5+rke2r1

# 下载安装脚本
wget https://rancher-mirror.rancher.cn/rke2/install.sh

# 下载离线包（amd64）
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/rke2.linux-amd64.tar.gz
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/rke2-images.linux-amd64.tar.zst
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/sha256sum-amd64.txt

# ARM64 架构
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/rke2.linux-arm64.tar.gz
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/rke2-images.linux-arm64.tar.zst
wget https://rancher-mirror.rancher.cn/rke2/releases/download/${VERSION}/sha256sum-arm64.txt
```

#### 下载 K3S 离线包

```bash
# 设置版本
VERSION=v1.28.5+k3s1

# 下载安装脚本
wget https://rancher-mirror.rancher.cn/k3s/k3s-install.sh

# 下载二进制（amd64）
wget https://rancher-mirror.rancher.cn/k3s/${VERSION}/k3s
wget https://rancher-mirror.rancher.cn/k3s/${VERSION}/k3s-airgap-images-amd64.tar.zst

# ARM64 架构
wget https://rancher-mirror.rancher.cn/k3s/${VERSION}/k3s-arm64
wget https://rancher-mirror.rancher.cn/k3s/${VERSION}/k3s-airgap-images-arm64.tar.zst
```

### 2. 传输到目标服务器

```bash
# 打包
tar czf rke2-offline.tar.gz rke2*

# 传输到目标服务器
scp rke2-offline.tar.gz root@<target-host>:/root/

# 在目标服务器上解压
ssh root@<target-host>
cd /root
tar xzf rke2-offline.tar.gz
```

### 3. 离线安装

#### RKE2 离线安装

```bash
# 创建离线包目录
mkdir -p /var/lib/rancher/rke2/agent/images/

# 复制镜像包
cp rke2-images.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/

# 安装 RKE2
chmod +x install.sh
INSTALL_RKE2_VERSION=${VERSION} \
INSTALL_RKE2_TYPE=server \
INSTALL_RKE2_ARTIFACT_PATH=/root \
./install.sh

# 启动服务
systemctl enable --now rke2-server
```

#### K3S 离线安装

```bash
# 创建离线包目录
mkdir -p /var/lib/rancher/k3s/agent/images/

# 复制文件
cp k3s /usr/local/bin/
chmod +x /usr/local/bin/k3s
cp k3s-airgap-images-amd64.tar.zst /var/lib/rancher/k3s/agent/images/

# 安装 K3S
chmod +x k3s-install.sh
INSTALL_K3S_SKIP_DOWNLOAD=true \
INSTALL_K3S_EXEC="server" \
./k3s-install.sh

# 启动服务
systemctl enable --now k3s
```

### 4. 配置私有镜像仓库

对于完全离线环境，可以搭建私有镜像仓库：

```bash
# 部署 Harbor 或其他私有仓库
# ...

# 配置 registries.yaml
cat > /etc/rancher/rke2/registries.yaml <<EOF
mirrors:
  docker.io:
    endpoint:
      - "https://harbor.internal.com"
  registry.k8s.io:
    endpoint:
      - "https://harbor.internal.com"

configs:
  "harbor.internal.com":
    auth:
      username: admin
      password: Harbor12345
    tls:
      insecure_skip_verify: false
EOF
```

## 常见问题

### 1. 安装脚本下载超时

**问题**:
```
curl: (28) Connection timed out after 120001 milliseconds
```

**解决方案**:
```bash
# 方法 1: 启用中国镜像源
china_region: true

# 方法 2: 手动下载
wget https://rancher-mirror.rancher.cn/rke2/install.sh
chmod +x install.sh
./install.sh
```

### 2. 镜像拉取失败

**问题**:
```
Failed to pull image "docker.io/rancher/pause:3.6"
```

**解决方案**:
```bash
# 检查 registries.yaml 配置
cat /etc/rancher/rke2/registries.yaml

# 测试镜像源连通性
curl -I https://dockerhub.mirrors.sjtug.sjtu.edu.cn

# 手动拉取测试
ctr images pull --hosts-dir /etc/rancher/rke2/agent/etc/containerd/certs.d \
  docker.io/library/nginx:latest

# 重启服务
systemctl restart rke2-server
```

### 3. DNS 解析问题

**问题**:
```
dial tcp: lookup github.com: no such host
```

**解决方案**:
```bash
# 配置 DNS
echo "nameserver 223.5.5.5" > /etc/resolv.conf

# 测试 DNS
nslookup rancher.cn 223.5.5.5
```

### 4. 镜像加速不生效

**检查步骤**:

```bash
# 1. 验证配置文件存在
ls -la /etc/rancher/rke2/registries.yaml

# 2. 检查配置语法
cat /etc/rancher/rke2/registries.yaml

# 3. 查看日志
journalctl -u rke2-server -n 100 --no-pager

# 4. 重启服务
systemctl restart rke2-server

# 5. 测试拉取
ctr --namespace k8s.io images pull docker.io/library/nginx:latest
```

## 镜像源列表

### 推荐镜像源（按可靠性排序）

#### Docker Hub

1. **上海交通大学**
   - URL: https://dockerhub.mirrors.sjtug.sjtu.edu.cn
   - 速度: ⭐⭐⭐⭐⭐
   - 稳定性: ⭐⭐⭐⭐⭐

2. **DaoCloud**
   - URL: https://docker.m.daocloud.io
   - 速度: ⭐⭐⭐⭐
   - 稳定性: ⭐⭐⭐⭐⭐

3. **南京大学**
   - URL: https://docker.nju.edu.cn
   - 速度: ⭐⭐⭐⭐
   - 稳定性: ⭐⭐⭐⭐

4. **阿里云**（需注册）
   - URL: https://[your-id].mirror.aliyuncs.com
   - 速度: ⭐⭐⭐⭐⭐
   - 稳定性: ⭐⭐⭐⭐⭐

#### Kubernetes 镜像

1. **DaoCloud**
   - URL: https://k8s-gcr.m.daocloud.io
   - 推荐度: ⭐⭐⭐⭐⭐

2. **阿里云**
   - URL: https://registry.aliyuncs.com/google_containers
   - 推荐度: ⭐⭐⭐⭐⭐

## 性能优化建议

### 1. 选择合适的镜像源

- 优先选择地理位置接近的镜像源
- 配置多个备用镜像源
- 定期测试镜像源速度

### 2. 使用专属加速器

- 阿里云、腾讯云用户使用对应的加速器
- 配置企业内部镜像仓库

### 3. 缓存策略

- 配置本地 Harbor 作为缓存代理
- 预拉取常用镜像

## 相关资源

- [Rancher 中国官网](https://www.rancher.cn/)
- [DaoCloud 镜像站](https://github.com/DaoCloud/public-image-mirror)
- [阿里云容器镜像服务](https://cr.console.aliyun.com/)
- [上海交通大学镜像站](https://mirrors.sjtug.sjtu.edu.cn/)

---

**文档版本**: 1.0.0  
**最后更新**: 2025-01-05
