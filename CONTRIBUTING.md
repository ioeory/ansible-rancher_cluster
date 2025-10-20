# 贡献指南

感谢您对本项目的关注！我们欢迎所有形式的贡献。

## 如何贡献

### 报告 Bug

如果您发现 Bug，请在 GitHub Issues 中创建新 Issue，并提供：

1. **清晰的标题**
2. **详细的描述**
3. **重现步骤**
4. **预期行为**
5. **实际行为**
6. **环境信息**：
   - OS 版本
   - Ansible 版本
   - RKE2/K3S 版本
   - 相关日志

### 提出功能请求

在 Issues 中描述：

1. **功能描述**
2. **使用场景**
3. **为什么需要这个功能**
4. **可能的实现方案**

### 提交代码

#### 1. Fork 项目

```bash
# Fork 到你的账号
# 克隆你的 Fork
git clone https://github.com/your-username/rke2-k3s-ansible.git
cd rke2-k3s-ansible

# 添加上游仓库
git remote add upstream https://github.com/original-org/rke2-k3s-ansible.git
```

#### 2. 创建分支

```bash
# 更新主分支
git checkout main
git pull upstream main

# 创建特性分支
git checkout -b feature/amazing-feature
```

#### 3. 开发和测试

```bash
# 编写代码
# ...

# 测试
make lint
make test

# 提交
git add .
git commit -m "Add amazing feature"
```

#### 4. 提交 Pull Request

```bash
# 推送到你的 Fork
git push origin feature/amazing-feature

# 在 GitHub 上创建 Pull Request
```

## 代码规范

### Ansible 最佳实践

1. **使用有意义的任务名称**
   ```yaml
   - name: 安装必需软件包 (Debian/Ubuntu)
     apt:
       name: [curl, wget]
   ```

2. **添加适当的标签**
   ```yaml
   tags:
     - install
     - server
   ```

3. **使用变量而不是硬编码**
   ```yaml
   # Good
   path: "{{ config_dir }}/config.yaml"
   
   # Bad
   path: /etc/rancher/rke2/config.yaml
   ```

4. **添加条件判断**
   ```yaml
   when: ansible_os_family == "Debian"
   ```

### YAML 格式

```yaml
# 使用 2 空格缩进
---
- name: 任务名称
  module:
    param1: value1
    param2: value2
  when: condition
  tags:
    - tag1
```

### 文档规范

1. **README 更新**：新功能需要更新 README
2. **文档注释**：关键配置添加注释
3. **示例代码**：提供使用示例
4. **中英文**：重要文档提供中英文版本

## Pull Request 规范

### PR 标题

使用清晰的标题，说明改动内容：

- `feat: 添加 K3S 离线安装支持`
- `fix: 修复中国镜像源配置问题`
- `docs: 更新安装指南`
- `refactor: 重构预检查逻辑`
- `test: 添加升级测试用例`

### PR 描述模板

```markdown
## 改动说明
<!-- 描述这个 PR 做了什么 -->

## 改动类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 代码重构
- [ ] 测试

## 测试
<!-- 如何测试这些改动？ -->

## 相关 Issue
<!-- 关联的 Issue 编号，例如: Fixes #123 -->

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 已添加必要的文档
- [ ] 已通过所有测试
- [ ] 已更新 CHANGELOG
```

## 测试指南

### 本地测试

```bash
# 语法检查
make lint

# 配置验证
make validate

# 干跑测试
make test

# 实际部署测试（使用测试环境）
INVENTORY=inventory/test.ini make install
```

### 测试环境

建议使用以下工具创建测试环境：

- **Vagrant**: 本地虚拟机
- **Docker**: 容器测试
- **云平台**: AWS/GCP/Azure 测试实例

### 测试检查清单

- [ ] 单节点安装
- [ ] HA 集群安装
- [ ] Server + Agent 混合模式
- [ ] 升级测试
- [ ] 备份和恢复
- [ ] 卸载测试
- [ ] 中国镜像源测试
- [ ] 多操作系统测试
- [ ] 多架构测试 (amd64/arm64)

## 版本发布

### 语义化版本

遵循 [Semantic Versioning](https://semver.org/)：

- **MAJOR**: 不兼容的 API 改动
- **MINOR**: 向后兼容的功能新增
- **PATCH**: 向后兼容的 Bug 修复

### 发布流程

1. 更新 `CHANGELOG.md`
2. 更新版本号
3. 创建 Git Tag
4. 发布 Release Notes

## 社区

### 交流渠道

- GitHub Issues: Bug 报告和功能请求
- GitHub Discussions: 一般讨论
- Slack: 实时交流（如有）

### 行为准则

- 尊重所有贡献者
- 建设性的反馈
- 友好和包容
- 专业的态度

## 问题？

如有任何问题，欢迎：

1. 查看现有 Issues
2. 阅读文档
3. 提出新 Issue
4. 发送邮件: devops@example.com

---

再次感谢您的贡献！ 🎉
