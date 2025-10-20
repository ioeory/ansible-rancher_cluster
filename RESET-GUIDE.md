# 仓库重置和清理指南

## 📋 概述

本项目提供两个清理命令，用于不同的清理场景：

| 命令 | 用途 | 删除内容 | 安全性 |
|------|------|---------|--------|
| `make clean` | 清理临时文件 | 日志、缓存、临时文件 | ✅ 安全 |
| `make reset` | 重置到初始状态 | 所有本地配置 + 临时文件 | ⚠️ 需确认 |

---

## 🧹 make clean - 清理临时文件

### 用途
清理安装和使用过程中产生的临时文件，但**保留**所有配置文件。

### 删除的文件
```
✓ *.retry           - Ansible 重试文件
✓ __pycache__/      - Python 缓存
✓ *.log             - 日志文件
✓ /tmp/*-token.txt  - 临时 Token 文件
```

### 保留的文件
```
✓ inventory/hosts.ini              - 您的节点配置
✓ inventory/group_vars/all.yml     - 您的集群配置
✓ 所有其他配置和数据
```

### 使用方法
```bash
make clean
```

### 输出示例
```
清理临时文件...
✓ 清理完成
```

### 使用场景
- ✅ 提交代码前清理
- ✅ 日常维护清理
- ✅ 释放磁盘空间
- ✅ 排查问题前清理

---

## 🔄 make reset - 重置到初始状态

### 用途
完全重置仓库到初始状态，删除**所有本地配置**，恢复到刚克隆时的状态。

### 删除的文件
```
⚠️ inventory/hosts.ini              - 您的节点配置（IP、SSH 信息）
⚠️ inventory/group_vars/all.yml     - 您的集群配置（Token、密码）
✓ *.retry                           - Ansible 重试文件
✓ __pycache__/                      - Python 缓存
✓ *.log                             - 日志文件
✓ /tmp/*-token.txt                  - 临时 Token 文件
```

### 保留的文件
```
✓ inventory/hosts.ini.example       - 示例配置（不受影响）
✓ inventory/group_vars/all.yml.example - 示例配置（不受影响）
✓ 所有源代码和文档
```

### 使用方法
```bash
make reset
```

### 交互式确认
```
========================================
  警告: 此操作将删除所有本地配置！
========================================

将删除以下文件:
  • inventory/hosts.ini
  • inventory/group_vars/all.yml
  • 所有临时文件和日志

确认重置? 输入 'yes' 继续: yes
```

### 输出示例
```
开始清理...
✓ 删除 inventory/hosts.ini
✓ 删除 inventory/group_vars/all.yml

========================================
  ✓ 仓库已重置到初始状态
========================================

下一步:
  1. 运行 make setup 重新初始化配置
  2. 或使用 git status 检查状态
```

### 使用场景
- ✅ 提交到 Git 仓库前清理
- ✅ 重新开始配置
- ✅ 切换到不同环境
- ✅ 演示或测试前重置
- ⚠️ **不适合**：日常维护（使用 `make clean` 代替）

---

## 🔄 完整的重置工作流

### 场景 1: 提交代码到 Git

```bash
# 1. 重置仓库（删除敏感配置）
make reset
# 输入 'yes' 确认

# 2. 检查 Git 状态
git status
# 应该显示 clean

# 3. 添加和提交
git add .
git commit -m "Your commit message"
git push origin main
```

### 场景 2: 切换环境配置

```bash
# 1. 备份当前配置（可选）
cp inventory/hosts.ini inventory/hosts.ini.prod.backup
cp inventory/group_vars/all.yml inventory/group_vars/all.yml.prod.backup

# 2. 重置
make reset
# 输入 'yes' 确认

# 3. 重新配置新环境
make setup
vim inventory/hosts.ini
vim inventory/group_vars/all.yml

# 4. 部署到新环境
make install
```

### 场景 3: 从头开始

```bash
# 1. 重置所有
make reset
# 输入 'yes' 确认

# 2. 重新初始化
make setup

# 3. 按照提示配置
vim inventory/hosts.ini
vim inventory/group_vars/all.yml

# 4. 开始部署
make install
```

---

## 💾 配置备份建议

在执行 `make reset` 前，建议备份重要配置：

### 手动备份
```bash
# 创建备份目录
mkdir -p ~/k8s-config-backups/$(date +%Y%m%d)

# 备份配置文件
cp inventory/hosts.ini ~/k8s-config-backups/$(date +%Y%m%d)/
cp inventory/group_vars/all.yml ~/k8s-config-backups/$(date +%Y%m%d)/

# 添加备份说明
echo "环境: 生产环境" > ~/k8s-config-backups/$(date +%Y%m%d)/README.txt
echo "日期: $(date)" >> ~/k8s-config-backups/$(date +%Y%m%d)/README.txt
```

### 使用 Git 备份
```bash
# 创建一个私有仓库保存配置
mkdir -p ~/k8s-configs
cd ~/k8s-configs
git init

# 复制配置
cp /path/to/project/inventory/hosts.ini .
cp /path/to/project/inventory/group_vars/all.yml .

# 提交
git add .
git commit -m "Backup production config $(date +%Y%m%d)"

# 推送到私有仓库（可选）
git remote add origin <your-private-repo>
git push -u origin main
```

---

## 🔍 验证重置效果

### 检查文件是否删除
```bash
# 检查配置文件
ls inventory/hosts.ini
# 应该输出: No such file or directory

ls inventory/group_vars/all.yml
# 应该输出: No such file or directory
```

### 检查 Git 状态
```bash
git status
# 应该显示 clean 或只有您修改的文件
```

### 检查忽略的文件
```bash
git status --ignored
# 应该看不到被忽略的配置文件（因为它们已被删除）
```

---

## ⚠️ 注意事项

### 数据丢失警告
- ⚠️ `make reset` 会**永久删除**您的配置文件
- ⚠️ 删除的文件**无法恢复**（除非有备份）
- ⚠️ 请确保在执行前备份重要配置

### 不会删除的内容
- ✅ 示例配置文件（*.example）
- ✅ 所有源代码和 Ansible Roles
- ✅ 文档和 README
- ✅ Git 提交历史
- ✅ 已部署的集群（仍在远程节点上运行）

### 集群不受影响
- `make reset` 只清理**本地配置文件**
- 已部署的集群**继续运行**
- 如需卸载集群，使用 `make uninstall`

---

## 🔧 高级用法

### 强制重置（跳过确认）
如果需要在脚本中使用，可以这样：

```bash
echo "yes" | make reset
```

### 只删除特定文件
```bash
# 只删除 hosts.ini
rm -f inventory/hosts.ini

# 只删除 all.yml
rm -f inventory/group_vars/all.yml
```

### 清理后立即重新配置
```bash
# 一键重置并重新初始化
make reset && make setup
```

---

## 📊 命令对比表

| 特性 | `make clean` | `make reset` |
|------|-------------|-------------|
| 删除临时文件 | ✅ 是 | ✅ 是 |
| 删除日志文件 | ✅ 是 | ✅ 是 |
| 删除配置文件 | ❌ 否 | ✅ 是 |
| 需要确认 | ❌ 否 | ✅ 是 |
| 可逆性 | ✅ 完全可逆 | ⚠️ 不可逆 |
| 适合日常使用 | ✅ 是 | ❌ 否 |
| 提交前使用 | ✅ 可以 | ✅ 推荐 |

---

## 🎯 快速参考

### 日常清理
```bash
make clean
```

### 提交前清理
```bash
make reset        # 删除所有本地配置
git status        # 确认状态
git add .
git commit -m "..."
git push
```

### 重新开始
```bash
make reset        # 重置
make setup        # 重新初始化
vim inventory/... # 配置
make install      # 部署
```

---

## 📚 相关命令

| 命令 | 说明 |
|------|------|
| `make clean` | 清理临时文件 |
| `make reset` | 重置到初始状态 |
| `make setup` | 初始化配置 |
| `make uninstall` | 卸载集群 |
| `git status` | 查看 Git 状态 |
| `git clean -fdx` | Git 完全清理（谨慎使用！） |

---

## ❓ 常见问题

### Q: make reset 会删除集群吗？
**A:** 不会。`make reset` 只删除本地配置文件，已部署的集群继续运行。要卸载集群，使用 `make uninstall`。

### Q: 删除的配置能恢复吗？
**A:** 不能，除非您有备份。建议在重置前备份重要配置。

### Q: 我不小心执行了 make reset 怎么办？
**A:** 如果您有备份，恢复备份文件。如果没有，需要重新配置：
```bash
make setup
vim inventory/hosts.ini
vim inventory/group_vars/all.yml
```

### Q: 示例文件会被删除吗？
**A:** 不会。`*.example` 文件保留，可以随时参考。

### Q: make clean 和 git clean 有什么区别？
**A:** 
- `make clean` 只删除临时文件，保留配置
- `git clean -fdx` 删除所有未跟踪的文件（包括配置），非常危险

---

## 🔗 相关文档

- [README.md](README.md) - 项目主文档
- [QUICK-START-GUIDE.md](QUICK-START-GUIDE.md) - 快速开始指南
- [GIT-CLEANUP-SUMMARY.md](GIT-CLEANUP-SUMMARY.md) - Git 清理总结
- [.gitignore](.gitignore) - Git 忽略规则

---

**文档版本**: v1.0  
**最后更新**: 2025-10-20  
**维护者**: RKE2/K3S Ansible Automation Project

