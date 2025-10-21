# RKE2/K3S Ansible Role Makefile
# 快速管理和操作工具

.PHONY: help install install-china upgrade backup uninstall check ping test clean

# 默认变量
INVENTORY ?= inventory/hosts.ini
PLAYBOOK_DIR = playbooks
EXTRA_ARGS ?=
ANSIBLE_ROLES_PATH ?= ./roles

# 颜色输出
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ============================================================================
# 帮助信息
# ============================================================================

help: ## 显示此帮助信息
	@echo "$(BLUE)RKE2/K3S Ansible Role 管理工具$(NC)"
	@echo ""
	@echo "$(GREEN)可用命令:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-18s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)使用示例:$(NC)"
	@echo "  make install                    # 安装集群"
	@echo "  make install-china              # 中国大陆安装"
	@echo "  make upgrade                    # 升级集群"
	@echo "  make backup                     # 备份 etcd"
	@echo "  make check                      # 检查连接"
	@echo ""
	@echo "$(GREEN)自定义参数:$(NC)"
	@echo "  INVENTORY=custom.ini make install"
	@echo "  EXTRA_ARGS='-vvv' make install"
	@echo ""

# ============================================================================
# 安装操作
# ============================================================================

install: ## 安装 RKE2/K3S 集群
	@echo "$(BLUE)开始安装集群...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install.yml $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 安装完成$(NC)"

install-china: ## 中国大陆安装 (启用镜像加速)
	@echo "$(BLUE)开始安装集群 (中国大陆模式)...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install.yml \
		-e "china_region=true" $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 安装完成$(NC)"

install-k3s: ## 安装 K3S 集群
	@echo "$(BLUE)开始安装 K3S 集群...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install.yml \
		-e "cluster_type=k3s" $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 安装完成$(NC)"

install-rke2: ## 安装 RKE2 集群
	@echo "$(BLUE)开始安装 RKE2 集群...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install.yml \
		-e "cluster_type=rke2" $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 安装完成$(NC)"

# ============================================================================
# 升级操作
# ============================================================================

upgrade: ## 升级集群到新版本
	@echo "$(BLUE)开始升级集群...$(NC)"
	@echo "$(YELLOW)警告: 升级操作将滚动重启所有节点$(NC)"
	@read -p "确认继续? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/upgrade.yml $(EXTRA_ARGS); \
		echo "$(GREEN)✓ 升级完成$(NC)"; \
	else \
		echo "$(YELLOW)已取消$(NC)"; \
	fi

upgrade-force: ## 强制升级 (无需确认)
	@echo "$(BLUE)开始升级集群...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/upgrade.yml $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 升级完成$(NC)"

# ============================================================================
# 备份操作
# ============================================================================

backup: ## 备份 etcd 数据
	@echo "$(BLUE)开始备份 etcd...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/backup.yml $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 备份完成$(NC)"

# ============================================================================
# 卸载操作
# ============================================================================

uninstall: ## 卸载集群 (危险操作!)
	@echo "$(RED)警告: 此操作将完全删除集群及所有数据!$(NC)"
	@read -p "确认卸载? 输入 'yes' 继续: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/uninstall.yml \
			-e "confirm_uninstall=yes" $(EXTRA_ARGS); \
		echo "$(GREEN)✓ 卸载完成$(NC)"; \
		echo "$(YELLOW)提示: 运行 'make verify-uninstall' 验证清理结果$(NC)"; \
	else \
		echo "$(YELLOW)已取消$(NC)"; \
	fi

verify-uninstall: ## 验证卸载是否完全清理
	@echo "$(BLUE)验证卸载清理结果...$(NC)"
	@if [ ! -f scripts/verify-uninstall.sh ]; then \
		echo "$(RED)错误: 验证脚本不存在$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)在所有节点上运行验证...$(NC)"
	@ansible -i $(INVENTORY) all -m script -a "scripts/verify-uninstall.sh" -b || \
		echo "$(RED)发现残留文件或进程，请检查日志$(NC)"

# ============================================================================
# 检查和测试
# ============================================================================

check: ping status ## 检查所有节点状态

ping: ## 测试 Ansible 连接
	@echo "$(BLUE)测试主机连接...$(NC)"
	ansible -i $(INVENTORY) all -m ping

status: ## 获取集群状态
	@echo "$(BLUE)获取集群状态...$(NC)"
	@CLUSTER_TYPE=$$(grep "^cluster_type=" $(INVENTORY) | head -1 | cut -d'=' -f2 || echo "rke2"); \
	if [ "$$CLUSTER_TYPE" = "k3s" ]; then \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell \
			-a "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && /usr/local/bin/kubectl get nodes -o wide" -b 2>/dev/null || \
			echo "$(YELLOW)无法获取状态$(NC)"; \
	else \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell \
			-a "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml && /var/lib/rancher/rke2/bin/kubectl get nodes -o wide" -b 2>/dev/null || \
			echo "$(YELLOW)无法获取状态$(NC)"; \
	fi

pods: ## 查看所有 Pod
	@echo "$(BLUE)查看所有 Pod...$(NC)"
	@CLUSTER_TYPE=$$(grep "^cluster_type=" $(INVENTORY) | head -1 | cut -d'=' -f2 || echo "rke2"); \
	if [ "$$CLUSTER_TYPE" = "k3s" ]; then \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell \
			-a "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && /usr/local/bin/kubectl get pods -A" -b 2>/dev/null; \
	else \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell \
			-a "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml && /var/lib/rancher/rke2/bin/kubectl get pods -A" -b 2>/dev/null; \
	fi

test: ## 干跑测试 (不实际执行)
	@echo "$(BLUE)执行干跑测试...$(NC)"
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/install.yml --check $(EXTRA_ARGS)
	@echo "$(GREEN)✓ 测试完成$(NC)"

# ============================================================================
# 工具命令
# ============================================================================

clean: ## 清理临时文件
	@echo "$(BLUE)清理临时文件...$(NC)"
	@find . -type f -name "*.retry" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.log" -delete 2>/dev/null || true
	@rm -f /tmp/*-token.txt 2>/dev/null || true
	@echo "$(GREEN)✓ 清理完成$(NC)"

reset: ## 重置仓库到初始状态（删除所有本地配置）
	@echo "$(RED)========================================$(NC)"
	@echo "$(RED)  警告: 此操作将删除所有本地配置！$(NC)"
	@echo "$(RED)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)将删除以下文件:$(NC)"
	@echo "  • inventory/hosts.ini"
	@echo "  • inventory/group_vars/all.yml"
	@echo "  • 所有临时文件和日志"
	@echo ""
	@read -p "确认重置? 输入 'yes' 继续: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(BLUE)开始清理...$(NC)"; \
		rm -f inventory/hosts.ini && echo "$(GREEN)✓ 删除 inventory/hosts.ini$(NC)"; \
		rm -f inventory/group_vars/all.yml && echo "$(GREEN)✓ 删除 inventory/group_vars/all.yml$(NC)"; \
		find . -type f -name "*.retry" -delete; \
		find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true; \
		find . -type f -name "*.log" -delete 2>/dev/null || true; \
		rm -f /tmp/*-token.txt 2>/dev/null || true; \
		echo ""; \
		echo "$(GREEN)========================================$(NC)"; \
		echo "$(GREEN)  ✓ 仓库已重置到初始状态$(NC)"; \
		echo "$(GREEN)========================================$(NC)"; \
		echo ""; \
		echo "$(YELLOW)下一步:$(NC)"; \
		echo "  1. 运行 $(GREEN)make setup$(NC) 重新初始化配置"; \
		echo "  2. 或使用 $(GREEN)git status$(NC) 检查状态"; \
	else \
		echo "$(YELLOW)已取消$(NC)"; \
	fi

setup: ## 初始化配置文件 (用法: make setup [k3s|rke2])
	@CLUSTER_TYPE=""; \
	if [ "$(filter k3s,$(MAKECMDGOALS))" = "k3s" ]; then \
		CLUSTER_TYPE="k3s"; \
	elif [ "$(filter rke2,$(MAKECMDGOALS))" = "rke2" ]; then \
		CLUSTER_TYPE="rke2"; \
	fi; \
	echo "$(BLUE)========================================$(NC)"; \
	if [ -n "$$CLUSTER_TYPE" ]; then \
		echo "$(BLUE)  $$(echo $$CLUSTER_TYPE | tr '[:lower:]' '[:upper:]') 集群配置初始化$(NC)"; \
	else \
		echo "$(BLUE)  RKE2/K3S 集群配置初始化$(NC)"; \
	fi; \
	echo "$(BLUE)========================================$(NC)"; \
	echo ""; \
	if [ ! -f inventory/hosts.ini ]; then \
		cp inventory/hosts.ini.example inventory/hosts.ini; \
		echo "$(GREEN)✓ 创建 inventory/hosts.ini$(NC)"; \
	else \
		echo "$(YELLOW)⚠ inventory/hosts.ini 已存在$(NC)"; \
	fi; \
	if [ ! -f inventory/group_vars/all.yml ]; then \
		cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml; \
		echo "$(GREEN)✓ 创建 inventory/group_vars/all.yml$(NC)"; \
	else \
		echo "$(YELLOW)⚠ inventory/group_vars/all.yml 已存在$(NC)"; \
	fi; \
	echo ""; \
	if [ -n "$$CLUSTER_TYPE" ]; then \
		echo "$(BLUE)自动配置 $$CLUSTER_TYPE 集群...$(NC)"; \
		echo ""; \
		if [ "$$CLUSTER_TYPE" = "k3s" ]; then \
			sed -i.bak 's/cluster_type=rke2/cluster_type=k3s/g' inventory/hosts.ini && rm -f inventory/hosts.ini.bak; \
			sed -i.bak 's/cluster_type: "rke2"/cluster_type: "k3s"/g' inventory/group_vars/all.yml && rm -f inventory/group_vars/all.yml.bak; \
			sed -i.bak 's|server_url: ""|server_url: "https://FIRST_NODE_IP:6443"|g' inventory/group_vars/all.yml && rm -f inventory/group_vars/all.yml.bak; \
			echo "$(GREEN)✓ 集群类型设置为: K3S$(NC)"; \
			echo "$(GREEN)✓ API Server 端口: 6443$(NC)"; \
		else \
			sed -i.bak 's/cluster_type=k3s/cluster_type=rke2/g' inventory/hosts.ini && rm -f inventory/hosts.ini.bak; \
			sed -i.bak 's/cluster_type: "k3s"/cluster_type: "rke2"/g' inventory/group_vars/all.yml && rm -f inventory/group_vars/all.yml.bak; \
			sed -i.bak 's|server_url: ""|server_url: "https://FIRST_NODE_IP:9345"|g' inventory/group_vars/all.yml && rm -f inventory/group_vars/all.yml.bak; \
			echo "$(GREEN)✓ 集群类型设置为: RKE2$(NC)"; \
			echo "$(GREEN)✓ API Server 端口: 9345$(NC)"; \
		fi; \
		sed -i.bak 's/china_region: false/china_region: true/g' inventory/group_vars/all.yml && rm -f inventory/group_vars/all.yml.bak; \
		echo "$(GREEN)✓ 中国镜像源: 已启用$(NC)"; \
		echo ""; \
	fi; \
	echo "$(GREEN)========================================$(NC)"; \
	echo "$(GREEN)  配置文件创建完成！$(NC)"; \
	echo "$(GREEN)========================================$(NC)"; \
	echo ""
	@echo "$(YELLOW)📝 下一步：请根据您的环境修改配置文件$(NC)"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)1️⃣  配置节点信息 (必需)$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  文件: $(YELLOW)inventory/hosts.ini$(NC)"
	@echo ""
	@echo "  $(YELLOW)必须修改:$(NC)"
	@echo "    • ansible_host          - 节点 IP 地址"
	@echo "    • ansible_user          - SSH 登录用户名"
	@echo "    • ansible_ssh_private_key_file - SSH 私钥路径"
	@echo ""
	@echo "  示例："
	@echo "    $(GREEN)[rke_k3s_servers]$(NC)"
	@echo "    $(GREEN)node1 ansible_host=192.168.1.10 cluster_init=true$(NC)"
	@echo "    $(GREEN)node2 ansible_host=192.168.1.11$(NC)"
	@echo "    $(GREEN)node3 ansible_host=192.168.1.12$(NC)"
	@echo ""
	@echo "    $(GREEN)[all:vars]$(NC)"
	@echo "    $(GREEN)ansible_user=root$(NC)"
	@echo "    $(GREEN)ansible_ssh_private_key_file=~/.ssh/id_rsa$(NC)"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)2️⃣  基础配置 (推荐)$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  文件: $(YELLOW)inventory/hosts.ini$(NC) 或 $(YELLOW)inventory/group_vars/all.yml$(NC)"
	@echo ""
	@echo "  • $(CYAN)cluster_type$(NC)    - 集群类型"
	@echo "      rke2  (默认，适合生产环境)"
	@echo "      k3s   (轻量级，适合边缘计算/开发环境)"
	@echo ""
	@echo "  • $(CYAN)install_version$(NC) - 安装版本 (留空安装最新稳定版)"
	@echo "      示例: v1.33.5+rke2r1"
	@echo "      示例: v1.33.5+k3s1"
	@echo ""
	@echo "  • $(CYAN)china_region$(NC)    - 中国大陆镜像加速"
	@echo "      true  (启用，大幅提升下载速度)"
	@echo "      false (禁用，使用官方源)"
	@echo ""
	@echo "  • $(CYAN)cluster_token$(NC)   - 集群共享密钥"
	@echo "      建议: 使用强密码或自动生成的 Token"
	@echo ""
	@echo "  • $(CYAN)server_url$(NC)      - API Server 地址 (HA 模式)"
	@echo "      RKE2: https://首节点IP:9345"
	@echo "      K3S:  https://首节点IP:6443"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)3️⃣  高级配置 (可选)$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  文件: $(YELLOW)inventory/group_vars/all.yml$(NC)"
	@echo ""
	@echo "  • 网络配置:"
	@echo "      cluster_cidr        - Pod 网络 CIDR"
	@echo "      service_cidr        - Service 网络 CIDR"
	@echo "      cluster_dns         - 集群 DNS 地址"
	@echo ""
	@echo "  • TLS 安全:"
	@echo "      tls_san             - API Server 证书 SAN 列表"
	@echo ""
	@echo "  • 存储配置:"
	@echo "      data_dir            - 数据目录路径"
	@echo "      backup_dir          - 备份目录路径"
	@echo ""
	@echo "  • 系统优化:"
	@echo "      disable_swap        - 禁用交换分区"
	@echo "      configure_sysctl    - 配置内核参数"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)4️⃣  快速配置示例$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  $(CYAN)🚀 一键配置 (推荐):$(NC)"
	@echo "    $(GREEN)make setup k3s$(NC)      # K3S 集群 (自动配置)"
	@echo "    $(GREEN)make setup rke2$(NC)     # RKE2 集群 (自动配置)"
	@echo "    $(GREEN)make setup$(NC)          # 手动选择类型"
	@echo ""
	@echo "  $(CYAN)场景 1: 标准 RKE2 HA 集群 (中国区)$(NC)"
	@echo "    $(GREEN)make setup rke2$(NC)"
	@echo "    # 自动设置: cluster_type=rke2, china_region=true, port=9345"
	@echo ""
	@echo "  $(CYAN)场景 2: K3S 轻量级集群$(NC)"
	@echo "    $(GREEN)make setup k3s$(NC)"
	@echo "    # 自动设置: cluster_type=k3s, china_region=true, port=6443"
	@echo ""
	@echo "  $(CYAN)场景 3: 开发测试环境 (单节点)$(NC)"
	@echo "    $(GREEN)make setup k3s$(NC)"
	@echo "    # 只配置一个 server 节点即可"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)5️⃣  下一步操作$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "  1. 编辑配置文件:"
	@echo "     $(GREEN)vim inventory/hosts.ini$(NC)"
	@echo "     $(GREEN)vim inventory/group_vars/all.yml$(NC)"
	@echo ""
	@echo "  2. 测试 SSH 连接:"
	@echo "     $(GREEN)make ping$(NC)"
	@echo ""
	@echo "  3. 检查配置语法:"
	@echo "     $(GREEN)make lint$(NC)"
	@echo ""
	@echo "  4. 开始安装集群:"
	@echo "     $(GREEN)make install$(NC)         # 根据配置自动选择"
	@echo "     $(GREEN)make install-rke2$(NC)    # 强制安装 RKE2"
	@echo "     $(GREEN)make install-k3s$(NC)     # 强制安装 K3S"
	@echo ""
	@echo "  5. 查看所有命令:"
	@echo "     $(GREEN)make help$(NC)"
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)  祝您部署顺利！ 🚀$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""

lint: ## 检查 YAML 语法
	@echo "$(BLUE)检查 YAML 语法...$(NC)"
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint roles/ playbooks/ inventory/ && echo "$(GREEN)✓ YAML 语法检查通过$(NC)"; \
	else \
		echo "$(YELLOW)警告: yamllint 未安装$(NC)"; \
		echo "$(YELLOW)安装方法: pip3 install yamllint$(NC)"; \
		echo "$(YELLOW)跳过 YAML 语法检查...$(NC)"; \
	fi

validate: ## 验证 Inventory 配置
	@echo "$(BLUE)验证 Inventory 配置...$(NC)"
	ansible-inventory -i $(INVENTORY) --list
	@echo "$(GREEN)✓ 验证通过$(NC)"

# ============================================================================
# 信息查询
# ============================================================================

info: ## 显示集群信息
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)RKE2/K3S 集群信息$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo "Inventory: $(INVENTORY)"
	@echo ""
	@echo "$(GREEN)Server 节点:$(NC)"
	@ansible -i $(INVENTORY) rke_k3s_servers --list-hosts 2>/dev/null || echo "  未配置"
	@echo ""
	@echo "$(GREEN)Agent 节点:$(NC)"
	@ansible -i $(INVENTORY) rke_k3s_agents --list-hosts 2>/dev/null || echo "  未配置"
	@echo "$(BLUE)========================================$(NC)"

version: ## 显示已安装版本
	@echo "$(BLUE)查询已安装版本...$(NC)"
	@CLUSTER_TYPE=$$(grep "^cluster_type=" $(INVENTORY) | head -1 | cut -d'=' -f2 || echo "rke2"); \
	if [ "$$CLUSTER_TYPE" = "k3s" ]; then \
		ansible -i $(INVENTORY) all -m shell -a "/usr/local/bin/k3s --version" -b 2>/dev/null; \
	else \
		ansible -i $(INVENTORY) all -m shell -a "/usr/local/bin/rke2 --version" -b 2>/dev/null; \
	fi

logs: ## 查看服务日志
	@echo "$(BLUE)查看服务日志...$(NC)"
	@echo "$(YELLOW)Server 节点日志:$(NC)"
	@CLUSTER_TYPE=$$(grep "^cluster_type=" $(INVENTORY) | head -1 | cut -d'=' -f2 || echo "rke2"); \
	if [ "$$CLUSTER_TYPE" = "k3s" ]; then \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell -a "journalctl -u k3s -n 50 --no-pager" -b 2>/dev/null || \
			echo "$(YELLOW)无法获取日志$(NC)"; \
	else \
		ansible -i $(INVENTORY) rke_k3s_servers[0] -m shell -a "journalctl -u rke2-server -n 50 --no-pager" -b 2>/dev/null || \
			echo "$(YELLOW)无法获取日志$(NC)"; \
	fi

# 占位符目标 (用于 setup 命令的参数)
k3s:
	@:
rke2:
	@:

# 默认目标
.DEFAULT_GOAL := help
