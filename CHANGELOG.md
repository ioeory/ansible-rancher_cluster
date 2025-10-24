# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-22

### Added

#### 核心功能
- 统一的 Ansible Role 支持 RKE2 和 K3S 部署
- 完整的高可用 (HA) 集群支持
- Server + Agent 混合模式部署
- 自动化升级和滚动更新
- etcd 自动备份和恢复
- 完整的卸载功能

#### 中国大陆优化
- rancher.cn 镜像源自动切换
- Containerd 镜像加速配置
- 多个国内镜像源备份
- 离线安装包支持

#### 操作系统支持
- Debian 12+
- Ubuntu 22.04+
- OpenAnolis 8+
- CentOS Stream 8+
- RHEL 8+
- Rocky Linux 8+
- AlmaLinux 8+

#### 架构支持
- AMD64 (x86_64)
- ARM64 (aarch64)

#### 安全特性
- Ansible Vault 敏感信息加密
- TLS SAN 配置
- RKE2 CIS 强化模式支持
- Secrets 加密选项
- Token 安全管理

#### 系统优化
- 自动禁用 swap
- 内核模块自动加载
- sysctl 参数优化
- 防火墙规则自动配置（可选）

#### 管理工具
- Makefile 快捷命令
- 预检查任务（OS、资源、网络）
- 详细的日志输出
- 服务状态监控

#### 文档
- 完整的 README 主文档
- 详细的安装部署指南
- 架构设计文档
- 中国大陆部署指南
- 故障排查指南
- API 参考文档（变量说明）

#### 示例配置
- 单节点测试集群
- 高可用 3 节点集群
- Server + Agent 混合集群
- 中国大陆环境配置

### Features

- **灵活配置**: 100+ 可配置参数
- **生产就绪**: 经过测试的生产级部署方案
- **易于使用**: 3 步完成集群部署
- **完整文档**: 详尽的中英文文档
- **社区支持**: 开源项目，欢迎贡献

### Technical Details

- Ansible 2.14+ 支持
- Python 3.8+ 兼容
- Systemd 服务管理
- Jinja2 模板引擎
- YAML 配置文件

## [Unreleased]

### Planned Features

- [ ] Helm Chart 支持
- [ ] Monitoring Stack (Prometheus + Grafana)
- [ ] Logging Stack (ELK/Loki)
- [ ] Ingress Controller 自动配置
- [ ] Cert-Manager 集成
- [ ] MetalLB LoadBalancer 支持
- [ ] Longhorn 存储支持
- [ ] ArgoCD GitOps 集成
- [ ] Terraform 模块
- [ ] Vagrant 测试环境
- [ ] CI/CD Pipeline 示例
- [ ] Multi-cluster 管理
- [ ] Rancher Server 集成

### Known Issues

- SELinux enforcing 模式可能需要额外配置
- 某些云平台的安全组需要手动配置
- ARM64 架构的离线包较大

---

## Release Notes Format

### Added
新增功能

### Changed
功能变更

### Deprecated
即将废弃的功能

### Removed
已删除的功能

### Fixed
Bug 修复

### Security
安全更新
