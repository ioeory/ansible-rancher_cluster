# 卸载功能改进说明

## 📋 问题描述

**原问题**：`make uninstall` 卸载集群后会遗留 `/etc/rancher` 和 `/var/lib/rancher` 父目录。

**影响**：
- 卸载不彻底，残留空目录
- 可能影响后续安装
- 不符合完全清理的预期

---

## ✨ 改进内容

### 1. 增强卸载清理范围

#### 新增清理项 ✅

**父目录清理**：
```yaml
- name: 删除 Rancher 父目录（完全清理）
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - "/etc/rancher"
    - "/var/lib/rancher"
```

**二进制文件清理**：
```yaml
- name: 删除卸载脚本和二进制文件
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - "/usr/local/bin/rke2-uninstall.sh"
    - "/usr/local/bin/k3s-uninstall.sh"
    - "/usr/local/bin/k3s-agent-uninstall.sh"
    - "/usr/local/bin/rke2"
    - "/usr/local/bin/k3s"
    - "/usr/bin/rke2"
    - "/usr/bin/k3s"
```

**Systemd 服务文件清理**：
```yaml
- name: 删除 systemd 服务文件
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - "/etc/systemd/system/rke2-server.service"
    - "/etc/systemd/system/rke2-agent.service"
    - "/etc/systemd/system/k3s.service"
    - "/etc/systemd/system/k3s-agent.service"
    - "/usr/lib/systemd/system/rke2-server.service"
    - "/usr/lib/systemd/system/rke2-agent.service"
    - "/usr/lib/systemd/system/k3s.service"
    - "/usr/lib/systemd/system/k3s-agent.service"
```

### 2. 新增卸载验证脚本

创建了 `scripts/verify-uninstall.sh`，用于验证卸载是否完全清理。

#### 验证项目

| 序号 | 检查项 | 说明 |
|------|--------|------|
| 1 | 残留进程 | 检查是否有 rke2/k3s 进程仍在运行 |
| 2 | 残留目录 | 检查 /etc/rancher、/var/lib/rancher 等目录 |
| 3 | 二进制文件 | 检查 rke2、k3s、kubectl 等文件 |
| 4 | Systemd 服务 | 检查服务是否已删除 |
| 5 | 网络接口 | 检查 cni0、flannel.1 等接口 |
| 6 | 挂载点 | 检查是否有残留的挂载点 |
| 7 | 卸载脚本 | 检查卸载脚本是否已删除 |

### 3. 新增 Makefile 命令

```makefile
verify-uninstall: ## 验证卸载是否完全清理
	@echo "验证卸载清理结果..."
	@ansible -i $(INVENTORY) all -m script \
		-a "scripts/verify-uninstall.sh" -b
```

---

## 🚀 使用方法

### 完整卸载流程

```bash
# 1. 卸载集群
make uninstall
# 输入 'yes' 确认

# 2. 验证清理结果（自动提示）
make verify-uninstall

# 3. 如果验证通过
# ✓ 验证通过！系统已完全清理

# 4. 如果发现问题
# ✗ 发现 N 个问题
# 建议重启系统: sudo reboot
```

### 单独验证

如果您已经运行过卸载，想单独验证：

```bash
make verify-uninstall
```

---

## 📊 改进对比

### 卸载前后对比

#### 改进前 ❌

```bash
# 卸载后检查
$ ls -la /etc/rancher/
drwxr-xr-x 2 root root 4096 ...  .    # 空目录残留
drwxr-xr-x 3 root root 4096 ...  ..

$ ls -la /var/lib/rancher/
drwxr-xr-x 2 root root 4096 ...  .    # 空目录残留
drwxr-xr-x 3 root root 4096 ...  ..

$ ls /usr/local/bin/ | grep -E '(rke2|k3s)'
rke2-uninstall.sh                      # 卸载脚本残留
```

#### 改进后 ✅

```bash
# 卸载后检查
$ ls -la /etc/rancher/
ls: cannot access '/etc/rancher/': No such file or directory  # ✓ 完全删除

$ ls -la /var/lib/rancher/
ls: cannot access '/var/lib/rancher/': No such file or directory  # ✓ 完全删除

$ ls /usr/local/bin/ | grep -E '(rke2|k3s)'
                                       # ✓ 完全删除
```

---

## 🔍 验证脚本示例输出

### 成功清理 ✅

```bash
$ make verify-uninstall

========================================
  RKE2/K3S 卸载验证脚本
========================================

[1/7] 检查残留进程...
  ✓ 无残留进程

[2/7] 检查残留目录...
  ✓ 已删除: /etc/rancher
  ✓ 已删除: /var/lib/rancher
  ✓ 已删除: /var/lib/kubelet
  ✓ 已删除: /etc/cni
  ✓ 已删除: /opt/cni
  ✓ 已删除: /var/lib/cni
  ✓ 已删除: /run/k8s

[3/7] 检查残留二进制文件...
  ✓ 已删除: /usr/local/bin/rke2
  ✓ 已删除: /usr/local/bin/k3s
  ✓ 已删除: /usr/bin/rke2
  ✓ 已删除: /usr/bin/k3s
  ✓ 已删除: /usr/local/bin/kubectl

[4/7] 检查 systemd 服务...
  ✓ 已删除: rke2-server
  ✓ 已删除: rke2-agent
  ✓ 已删除: k3s
  ✓ 已删除: k3s-agent

[5/7] 检查网络接口...
  ✓ 已删除: cni0
  ✓ 已删除: flannel.1
  ✓ 已删除: kube-ipvs0

[6/7] 检查挂载点...
  ✓ 无残留挂载点

[7/7] 检查卸载脚本...
  ✓ 已删除: /usr/local/bin/rke2-uninstall.sh
  ✓ 已删除: /usr/local/bin/k3s-uninstall.sh
  ✓ 已删除: /usr/local/bin/k3s-agent-uninstall.sh

========================================
✓ 验证通过！系统已完全清理
========================================
```

### 发现问题 ⚠️

```bash
$ make verify-uninstall

========================================
  RKE2/K3S 卸载验证脚本
========================================

[1/7] 检查残留进程...
  ✗ 发现残留进程:
    root      1234  containerd --config /var/lib/rancher/...

[2/7] 检查残留目录...
  ✗ 目录仍存在: /etc/rancher
      drwxr-xr-x 2 root root 4096 ...  .
      drwxr-xr-x 3 root root 4096 ...  ..

...

========================================
✗ 发现 2 个问题
========================================

建议操作:
  1. 重启系统: sudo reboot
  2. 手动清理残留文件
  3. 重新运行卸载: make uninstall
```

---

## 🛡️ 安全性说明

### 确认机制

卸载操作保留了双重确认：

1. **Makefile 层面**：
   ```bash
   确认卸载? 输入 'yes' 继续:
   ```

2. **Playbook 层面**：
   ```yaml
   vars_prompt:
     - name: confirm_uninstall
       prompt: "确认卸载集群？所有数据将被删除！(yes/no)"
   ```

### 删除顺序

为了安全和彻底清理，采用以下顺序：

```
1. 停止服务
   ↓
2. 执行官方卸载脚本
   ↓
3. 删除特定子目录
   ↓
4. 删除父目录
   ↓
5. 清理网络和 iptables
   ↓
6. 删除二进制和脚本
   ↓
7. 清理 systemd
```

---

## 🔧 技术细节

### 修改的文件

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `playbooks/uninstall.yml` | 增强 | 添加父目录、二进制、服务清理 |
| `scripts/verify-uninstall.sh` | 新建 | 卸载验证脚本 |
| `Makefile` | 增强 | 添加 `verify-uninstall` 命令 |
| `UNINSTALL-IMPROVEMENTS.md` | 新建 | 本文档 |

### 关键代码片段

#### 父目录清理
```yaml
# playbooks/uninstall.yml
- name: 删除 Rancher 父目录（完全清理）
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - "/etc/rancher"
    - "/var/lib/rancher"
  ignore_errors: yes
```

#### 验证命令
```makefile
# Makefile
verify-uninstall: ## 验证卸载是否完全清理
	@ansible -i $(INVENTORY) all -m script \
		-a "scripts/verify-uninstall.sh" -b
```

---

## 📚 相关文档

- [README.md](README.md) - 项目主文档
- [QUICK-START-GUIDE.md](QUICK-START-GUIDE.md) - 快速开始
- [RESET-GUIDE.md](RESET-GUIDE.md) - 重置指南
- [playbooks/uninstall.yml](playbooks/uninstall.yml) - 卸载 Playbook

---

## 🎯 测试建议

### 测试场景

1. **完整卸载测试**：
   ```bash
   make install      # 安装集群
   make uninstall    # 卸载集群
   make verify-uninstall  # 验证清理
   ```

2. **重复安装测试**：
   ```bash
   make install      # 第一次安装
   make uninstall    # 卸载
   make install      # 重新安装（验证无残留影响）
   ```

3. **跨版本测试**：
   ```bash
   # 安装 RKE2
   make install-rke2
   make uninstall
   make verify-uninstall
   
   # 安装 K3S
   make install-k3s
   make uninstall
   make verify-uninstall
   ```

---

## ❓ 常见问题

### Q1: 为什么要删除父目录？

**A:** 完全清理系统，避免残留空目录：
- 干净的系统状态
- 避免后续安装时的潜在问题
- 符合用户的完全卸载预期

### Q2: 删除父目录会影响其他 Rancher 产品吗？

**A:** 理论上可能，但：
- 本项目专注于 RKE2/K3S
- 如果同时使用其他 Rancher 产品，建议谨慎使用
- 可以注释掉父目录删除任务

### Q3: 验证失败怎么办？

**A:** 建议步骤：
1. 重启系统：`sudo reboot`
2. 重新验证：`make verify-uninstall`
3. 手动清理残留：根据验证输出手动删除
4. 重新运行卸载：`make uninstall`

### Q4: 可以跳过验证吗？

**A:** 可以，验证是可选的：
```bash
make uninstall          # 只卸载，不验证
make verify-uninstall   # 随时可以单独验证
```

---

## 🚀 未来改进计划

- [ ] 支持部分卸载（只卸载 Agent 节点）
- [ ] 添加卸载日志收集
- [ ] 支持卸载前自动备份
- [ ] 支持卸载失败时的回滚
- [ ] 添加更多验证项（如内核模块）

---

**文档版本**: v1.0  
**最后更新**: 2025-10-21  
**相关 Issue**: 卸载后遗留 /etc/rancher 和 /var/lib/rancher 目录  
**维护者**: RKE2/K3S Ansible Automation Project

