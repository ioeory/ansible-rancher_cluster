# 集群 Token 自动获取指南

## 功能说明

从现在开始，你不再需要手动配置 `cluster_token`。Ansible playbook 会自动从初始 Server 节点获取 token 并分发给其他节点。

## 工作原理

### 1. 初始 Server 节点（cluster_init=true）
- 自动生成 cluster token
- Token 保存到本地文件：`/tmp/k3s-token.txt` 或 `/tmp/rke2-token.txt`
- 供后续节点使用

### 2. 其他 Server 节点和 Agent 节点
Playbook 会按照以下优先级自动获取 token：

1. **使用配置文件中的 token**（如果已配置）
   - 从 `inventory/group_vars/all.yml` 中的 `cluster_token`
   - 或从 `inventory/hosts.ini` 中的配置

2. **从本地文件读取**
   - 检查是否存在 `/tmp/{{ cluster_type }}-token.txt`
   - 如果存在，直接读取使用

3. **从 Server 节点远程获取**
   - 如果本地文件不存在，自动连接到初始 Server 节点
   - 从 `/var/lib/rancher/k3s/server/node-token` 读取 token

## 使用方式

### 方式 1：一键部署（推荐）

**配置文件中留空 token：**

```yaml
# inventory/group_vars/all.yml
server_url: "https://192.168.1.166:6443"
cluster_token: ""  # 留空即可
```

**执行部署：**

```bash
# 一次性部署所有节点
ansible-playbook -i inventory/hosts.ini playbooks/install.yml

# 或使用脚本
./deploy-cluster.sh
```

Playbook 会自动：
1. 先安装 Server 节点（node1, node2, node3）
2. 获取 token 并保存到本地
3. 使用这个 token 安装 Agent 节点（worker1）

### 方式 2：分阶段部署

如果你希望更精细地控制部署过程：

**第一步：部署 Server 节点**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --limit rke_servers
```

**第二步：部署 Agent 节点**

```bash
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --limit rke_agents
```

Agent 节点会自动从 Server 节点或本地文件获取 token。

### 方式 3：手动指定 Token（传统方式）

如果你有特定的 token 需求：

```yaml
# inventory/group_vars/all.yml
server_url: "https://192.168.1.166:6443"
cluster_token: "K10a8f9c3e2b1d4e7f6a5c8b9e0d3f2a1::server:9c8b7a6e5d4c3b2a1f0e9d8c"
```

这样会跳过自动获取，直接使用配置的 token。

## Token 文件位置

### 本地缓存文件
- K3S: `/tmp/k3s-token.txt`
- RKE2: `/tmp/rke2-token.txt`

### Server 节点上的原始文件
- K3S: `/var/lib/rancher/k3s/server/node-token`
- RKE2: `/var/lib/rancher/rke2/server/node-token`

## 故障排查

### 错误：无法获取 cluster_token

**原因：**
- 初始 Server 节点尚未安装
- 本地 token 文件不存在
- 无法连接到 Server 节点

**解决方案：**

1. 确认 Server 节点已成功安装：
```bash
ansible -i inventory/hosts.ini rke_servers -m shell -a "systemctl status k3s"
```

2. 手动获取 token：
```bash
# 在 Server 节点上执行
sudo cat /var/lib/rancher/k3s/server/node-token

# 或使用 Ansible
ansible -i inventory/hosts.ini rke_servers[0] -b -m shell -a "cat /var/lib/rancher/k3s/server/node-token"
```

3. 将 token 保存到配置文件：
```yaml
cluster_token: "从上面获取的 token"
```

### 本地 token 文件过期

如果你重新安装了 Server 节点，需要删除旧的 token 文件：

```bash
rm /tmp/k3s-token.txt
# 或
rm /tmp/rke2-token.txt
```

然后重新运行 playbook。

## 安全建议

### 生产环境

对于生产环境，建议使用 `ansible-vault` 加密 token：

```bash
# 生成加密的 token
ansible-vault encrypt_string 'your-actual-token' --name 'cluster_token'
```

然后在配置文件中使用加密后的值：

```yaml
cluster_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...加密内容...
```

运行 playbook 时需要提供密码：

```bash
ansible-playbook -i inventory/hosts.ini playbooks/install.yml --ask-vault-pass
```

### 本地 token 文件权限

本地 token 文件会自动设置为 `600` 权限，确保只有你能读取。

## 示例

### 完整部署示例

```bash
# 1. 配置 inventory
cat > inventory/group_vars/all.yml <<EOF
cluster_type: "k3s"
server_url: "https://192.168.1.166:6443"
cluster_token: ""  # 留空自动获取
china_region: true
EOF

# 2. 一键部署
ansible-playbook -i inventory/hosts.ini playbooks/install.yml

# 3. 查看 token（可选）
cat /tmp/k3s-token.txt

# 4. 验证集群
ssh devops@192.168.1.166
sudo kubectl get nodes
```

## 总结

✅ **不再需要手动配置 cluster_token**  
✅ **支持一键部署和分阶段部署**  
✅ **自动处理 token 获取和分发**  
✅ **兼容传统手动配置方式**  

享受自动化带来的便利吧！🚀

