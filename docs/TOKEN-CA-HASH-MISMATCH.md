# Token CA Hash 不匹配问题解决方案

## 问题描述

在部署 K3S/RKE2 集群时，非初始节点启动失败，错误信息：

```
failed to validate token: token CA hash does not match the Cluster CA certificate hash:
96dddafdc2c74c7332786246660ddcdb9c89d5997d6f58759122551ef65eaa76 !=
fc3284e362699278b5e9675b1a9c487c04e96cb35df7963c5f521f508244c4f5
```

### 症状

- ✅ 初始节点（cluster_init=true）运行正常
- ❌ 其他 Server 节点启动失败并不断重启
- ❌ Agent 节点启动失败
- 错误日志显示 token CA hash 不匹配

### 典型场景

1. 第一次部署集群，生成 Token A，保存到 `/tmp/k3s-token.txt`
2. 后来卸载并重新部署集群，生成新 Token B
3. 但本地文件 `/tmp/k3s-token.txt` 仍然是旧 Token A
4. 非初始节点读取本地旧 Token A，尝试加入使用 Token B 的集群
5. CA hash 不匹配，启动失败

## 问题根因

### 旧的 Token 获取逻辑（存在问题）

**优先级顺序：**
1. ✅ 从配置文件读取（如果已配置）
2. ⚠️ 从本地文件 `/tmp/{{ cluster_type }}-token.txt` 读取
3. ✅ 从初始 Server 节点实时获取

**问题：**
- 本地文件可能包含旧 token（来自之前的部署）
- 优先从本地文件读取，导致使用过期的 token
- 过期 token 的 CA hash 与当前集群的 CA 证书不匹配

### Token 结构

K3S/RKE2 的 token 格式：
```
K10<CA_HASH>::server:<RANDOM_TOKEN>
```

例如：
```
K10fc3284e362699278b5e9675b1a9c487c04e96cb35df7963c5f521f508244c4f5::server:bb9328723471f74ab7d29231bd6edd95
   └─────────────────── CA Hash ───────────────────┘         └──── Random Token ────┘
```

当集群重新初始化时：
- CA 证书会重新生成
- CA Hash 会改变
- Token 会改变
- 但本地缓存文件不会自动更新

## 解决方案

### 临时修复（当前集群）

如果当前集群已经遇到此问题：

**步骤 1：获取正确的 token**

```bash
# 从正在运行的初始节点获取
ansible -i inventory/hosts.ini node1 -b -m shell -a "cat /var/lib/rancher/k3s/server/node-token"
```

**步骤 2：停止失败的节点并清理数据**

```bash
# 停止服务并清理数据目录
ansible -i inventory/hosts.ini node2,node3,worker1 -b -m shell -a "systemctl stop k3s k3s-agent && rm -rf /var/lib/rancher/k3s/server"
```

**步骤 3：更新配置文件**

```bash
# 替换为正确的 token
ansible -i inventory/hosts.ini node2,node3,worker1 -b -m shell -a "sed -i 's|^token:.*|token: <正确的token>|' /etc/rancher/k3s/config.yaml"
```

**步骤 4：重启服务**

```bash
ansible -i inventory/hosts.ini node2,node3,worker1 -b -m shell -a "systemctl restart k3s k3s-agent"
```

### 永久修复（已实施）

修改了 Token 获取逻辑的**优先级顺序**：

**新的优先级（推荐）：**
1. ✅ 从配置文件读取（如果已配置）
2. ✅ **从初始 Server 节点实时获取（优先）**
3. ✅ 从本地文件读取（备用方案）
4. ✅ 获取成功后自动更新本地文件

#### 修改的文件

1. **`roles/rancher_cluster/tasks/install_server.yml`**
   - 优先从初始节点实时获取 token
   - 本地文件作为备用方案
   - 获取后更新本地文件

2. **`roles/rancher_cluster/tasks/install_agent.yml`**
   - 优先从 Server 节点实时获取 token
   - 本地文件作为备用方案
   - 获取后更新本地文件

#### 核心改进

```yaml
# 1. 优先从 Server 节点获取（实时、准确）
- name: 从初始 Server 节点获取 Token (非初始节点)
  slurp:
    src: "{{ token_file }}"
  delegate_to: "{{ groups['rke_servers'][0] }}"
  register: server_token_content
  when: cluster_token is not defined or cluster_token | length == 0
  ignore_errors: yes

# 2. 本地文件作为备用（离线场景）
- name: 从本地文件读取 Token (备用方案)
  set_fact:
    cluster_token: "{{ lookup('file', '/tmp/' + cluster_type + '-token.txt') | trim }}"
  when:
    - cluster_token is not defined or cluster_token | length == 0
    - local_token_file.stat.exists

# 3. 获取成功后更新本地缓存
- name: 更新本地 Token 文件
  copy:
    content: "{{ cluster_token }}"
    dest: "/tmp/{{ cluster_type }}-token.txt"
  delegate_to: localhost
  when:
    - cluster_token is defined
    - cluster_token | length > 0
```

### 优势

| 方面 | 旧逻辑 | 新逻辑 |
|------|--------|--------|
| Token 新鲜度 | ❌ 可能使用过期 token | ✅ 总是获取最新 token |
| 部署可靠性 | ❌ 重新部署易失败 | ✅ 重新部署始终成功 |
| 离线支持 | ✅ 支持 | ✅ 仍然支持（备用方案） |
| 缓存更新 | ❌ 不会更新 | ✅ 自动更新 |
| 调试难度 | ❌ 错误不明显 | ✅ 日志清晰 |

## 验证

### 1. 检查集群状态

```bash
# 查看所有节点状态
ansible -i inventory/hosts.ini node1 -b -m shell -a "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get nodes -o wide"
```

期望输出：所有节点状态为 `Ready`

### 2. 检查服务状态

```bash
# Server 节点
ansible -i inventory/hosts.ini rke_servers -b -m shell -a "systemctl status k3s --no-pager | head -15"

# Agent 节点
ansible -i inventory/hosts.ini rke_agents -b -m shell -a "systemctl status k3s-agent --no-pager | head -15"
```

期望输出：所有服务 `Active: active (running)`

### 3. 验证 Token 一致性

```bash
# 检查所有节点使用的 token
ansible -i inventory/hosts.ini all -b -m shell -a "grep '^token:' /etc/rancher/k3s/config.yaml || echo 'No token in config'"
```

期望输出：所有节点的 token 应该相同

### 4. 检查本地缓存

```bash
# 查看本地 token 文件
cat /tmp/k3s-token.txt

# 应该与初始节点的 token 一致
```

## 预防措施

### 1. 完全卸载后重新部署

确保卸载干净，避免残留数据：

```bash
# 完全卸载
make uninstall

# 验证清理
make verify-uninstall

# 清理本地缓存
rm -f /tmp/k3s-token.txt /tmp/rke2-token.txt

# 重新部署
make install
```

### 2. 使用版本控制

不要在配置文件中硬编码 token，让系统自动获取：

```yaml
# inventory/group_vars/all.yml
server_url: "https://192.168.1.166:6443"
cluster_token: ""  # 留空，自动获取
```

### 3. 监控部署日志

注意 token 获取状态的日志：

```
✓ 成功获取 cluster_token (from init server node)
```

或

```
✓ 成功获取 cluster_token (from local file)
```

### 4. 生产环境建议

对于生产环境：

1. **使用固定 token**：在配置文件中明确指定
2. **使用 ansible-vault 加密**：
   ```bash
   ansible-vault encrypt_string 'your-token' --name 'cluster_token'
   ```
3. **定期轮换**：按照安全策略定期更换 token
4. **文档记录**：记录 token 的生成时间和变更历史

## 相关文档

- [AUTO-TOKEN-GUIDE.md](AUTO-TOKEN-GUIDE.md) - Token 自动获取指南
- [SERVICE-NAMES.md](SERVICE-NAMES.md) - 服务名称说明
- [SYSTEMD-CLEANUP.md](SYSTEMD-CLEANUP.md) - systemd 清理指南

## 故障排查流程图

```
部署失败
    ↓
查看错误日志
    ↓
是否为 "token CA hash does not match"?
    ├─ 是 → 继续
    └─ 否 → 查看其他故障排查文档
    ↓
检查初始节点状态
    ├─ 未运行 → 先部署初始节点
    └─ 运行正常 → 继续
    ↓
获取正确 token
    ↓
停止失败节点服务
    ↓
清理数据目录
    ↓
更新配置文件 token
    ↓
重启服务
    ↓
验证集群状态
    ├─ 成功 → 完成
    └─ 失败 → 查看新的错误日志
```

## 常见问题

### Q1: 为什么会产生不同的 token？

A: 每次初始化集群时，K3S/RKE2 会生成新的 CA 证书和 token。如果：
- 卸载后重新部署
- 删除数据目录后重启
- 手动重新初始化集群

都会导致 token 改变。

### Q2: 本地 token 文件的作用是什么？

A: 本地 token 文件（`/tmp/k3s-token.txt`）作为：
1. **缓存**：避免每次都从 server 节点获取
2. **备份**：离线部署或 server 节点不可达时使用
3. **调试**：方便查看当前使用的 token

### Q3: 如何判断 token 是否过期？

A: Token 本身不会过期，但当：
- 集群重新初始化
- CA 证书重新生成
- token 的 CA hash 就会与集群不匹配

判断方法：比较 token 中的 CA hash 与集群 CA 证书的 hash。

### Q4: 能否手动指定 token？

A: 可以。在 `inventory/group_vars/all.yml` 中：

```yaml
cluster_token: "K10your-ca-hash::server:your-random-token"
```

但建议让系统自动管理，除非有特殊需求。

### Q5: 修复后需要重新部署整个集群吗？

A: 不需要。只需：
1. 保持初始节点运行
2. 停止失败的节点
3. 清理数据目录
4. 更新配置文件
5. 重启服务

## 总结

✅ **问题**：本地缓存的旧 token 导致 CA hash 不匹配  
✅ **根因**：Token 获取优先级不当  
✅ **修复**：优先从 server 节点实时获取，本地文件作为备用  
✅ **效果**：确保总是使用最新、正确的 token  
✅ **兼容**：仍然支持离线部署场景  

以后的部署将自动避免此问题！🎉

