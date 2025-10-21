#!/bin/bash
# 卸载后验证脚本
# 用途：检查系统上是否还有 RKE2/K3S 残留文件和进程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  RKE2/K3S 卸载验证脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查计数器
ISSUES_FOUND=0

# 1. 检查进程
echo -e "${BLUE}[1/7] 检查残留进程...${NC}"
if ps aux | grep -E '(rke2|k3s)' | grep -v grep >/dev/null 2>&1; then
    echo -e "${RED}  ✗ 发现残留进程:${NC}"
    ps aux | grep -E '(rke2|k3s)' | grep -v grep | sed 's/^/    /'
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}  ✓ 无残留进程${NC}"
fi

# 2. 检查目录
echo -e "${BLUE}[2/7] 检查残留目录...${NC}"
DIRS=(
    "/etc/rancher"
    "/var/lib/rancher"
    "/var/lib/kubelet"
    "/etc/cni"
    "/opt/cni"
    "/var/lib/cni"
    "/run/k8s"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${RED}  ✗ 目录仍存在: $dir${NC}"
        ls -la "$dir" 2>/dev/null | head -5 | sed 's/^/      /'
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}  ✓ 已删除: $dir${NC}"
    fi
done

# 3. 检查二进制文件
echo -e "${BLUE}[3/7] 检查残留二进制文件...${NC}"
BINARIES=(
    "/usr/local/bin/rke2"
    "/usr/local/bin/k3s"
    "/usr/bin/rke2"
    "/usr/bin/k3s"
    "/usr/local/bin/kubectl"
)

for bin in "${BINARIES[@]}"; do
    if [ -f "$bin" ]; then
        echo -e "${RED}  ✗ 二进制文件仍存在: $bin${NC}"
        ls -lh "$bin" | sed 's/^/      /'
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}  ✓ 已删除: $bin${NC}"
    fi
done

# 4. 检查 systemd 服务
echo -e "${BLUE}[4/7] 检查 systemd 服务...${NC}"
SERVICES=(
    "rke2-server"
    "rke2-agent"
    "k3s"
    "k3s-agent"
)

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        echo -e "${RED}  ✗ 服务仍存在: $service${NC}"
        systemctl status "$service" --no-pager | head -5 | sed 's/^/      /'
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}  ✓ 已删除: $service${NC}"
    fi
done

# 5. 检查网络接口
echo -e "${BLUE}[5/7] 检查网络接口...${NC}"
INTERFACES=(
    "cni0"
    "flannel.1"
    "kube-ipvs0"
)

for iface in "${INTERFACES[@]}"; do
    if ip link show "$iface" >/dev/null 2>&1; then
        echo -e "${RED}  ✗ 网络接口仍存在: $iface${NC}"
        ip link show "$iface" | sed 's/^/      /'
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}  ✓ 已删除: $iface${NC}"
    fi
done

# 6. 检查挂载点
echo -e "${BLUE}[6/7] 检查挂载点...${NC}"
if mount | grep -E '(rke2|k3s|kubelet)' >/dev/null 2>&1; then
    echo -e "${RED}  ✗ 发现残留挂载点:${NC}"
    mount | grep -E '(rke2|k3s|kubelet)' | sed 's/^/    /'
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}  ✓ 无残留挂载点${NC}"
fi

# 7. 检查卸载脚本
echo -e "${BLUE}[7/7] 检查卸载脚本...${NC}"
UNINSTALL_SCRIPTS=(
    "/usr/local/bin/rke2-uninstall.sh"
    "/usr/local/bin/k3s-uninstall.sh"
    "/usr/local/bin/k3s-agent-uninstall.sh"
)

for script in "${UNINSTALL_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo -e "${RED}  ✗ 卸载脚本仍存在: $script${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}  ✓ 已删除: $script${NC}"
    fi
done

# 总结
echo ""
echo -e "${BLUE}========================================${NC}"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ 验证通过！系统已完全清理${NC}"
    echo -e "${BLUE}========================================${NC}"
    exit 0
else
    echo -e "${RED}✗ 发现 $ISSUES_FOUND 个问题${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}建议操作:${NC}"
    echo -e "  1. 重启系统: ${GREEN}sudo reboot${NC}"
    echo -e "  2. 手动清理残留文件"
    echo -e "  3. 重新运行卸载: ${GREEN}make uninstall${NC}"
    exit 1
fi

