#!/bin/bash
# 清理残留的 systemd 服务文件
# 用途：删除 /usr/local/lib/systemd/system/ 中残留的 RKE2/K3S 服务文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  清理残留的 systemd 服务文件${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# systemd 服务文件路径
SYSTEMD_DIRS=(
    "/etc/systemd/system"
    "/usr/lib/systemd/system"
    "/usr/local/lib/systemd/system"
)

# 服务名称
SERVICES=(
    "rke2-server.service"
    "rke2-agent.service"
    "k3s.service"
    "k3s-agent.service"
)

CLEANED=0

for dir in "${SYSTEMD_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    
    echo -e "${BLUE}检查目录: $dir${NC}"
    
    for service in "${SERVICES[@]}"; do
        SERVICE_FILE="$dir/$service"
        if [ -f "$SERVICE_FILE" ]; then
            echo -e "${YELLOW}  发现服务文件: $SERVICE_FILE${NC}"
            
            # 停止并禁用服务（如果还在运行）
            SERVICE_NAME="${service%.service}"
            if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "    停止服务: $SERVICE_NAME"
                systemctl stop "$SERVICE_NAME" 2>/dev/null || true
            fi
            
            if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "    禁用服务: $SERVICE_NAME"
                systemctl disable "$SERVICE_NAME" 2>/dev/null || true
            fi
            
            # 删除服务文件
            rm -f "$SERVICE_FILE"
            echo -e "${GREEN}    ✓ 已删除: $SERVICE_FILE${NC}"
            CLEANED=$((CLEANED + 1))
        fi
    done
done

# 重新加载 systemd
if [ $CLEANED -gt 0 ]; then
    echo ""
    echo -e "${BLUE}重新加载 systemd...${NC}"
    systemctl daemon-reload
    echo -e "${GREEN}✓ systemd 已重新加载${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
if [ $CLEANED -eq 0 ]; then
    echo -e "${GREEN}✓ 未发现残留的服务文件${NC}"
else
    echo -e "${GREEN}✓ 已清理 $CLEANED 个服务文件${NC}"
fi
echo -e "${BLUE}========================================${NC}"

exit 0

