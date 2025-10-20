#!/bin/bash
# 集群部署脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "RKE2 高可用集群部署"
echo "=========================================="
echo ""
echo "目标节点："
echo "  - 192.168.2.41 (初始 Server)"
echo "  - 192.168.2.42 (Server)"
echo "  - 192.168.2.43 (Server)"
echo ""
echo "集群配置："
echo "  - 集群类型: RKE2"
echo "  - 模式: 高可用 (3 节点)"
echo "  - 中国镜像: 启用"
echo "  - SSH 用户: ioe"
echo "  - SSH 密钥: ~/id_ed25519-ansible"
echo ""
echo "=========================================="
echo ""

# 检查 SSH 密钥
if [ ! -f ~/id_ed25519-ansible ]; then
    echo "❌ 错误: SSH 密钥文件不存在: ~/id_ed25519-ansible"
    echo ""
    echo "请确保密钥文件存在，或者更新 inventory/hosts.ini 中的密钥路径"
    exit 1
fi

echo "✓ SSH 密钥文件存在"
echo ""

# 检查 Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ 错误: Ansible 未安装"
    echo ""
    echo "请先安装 Ansible:"
    echo "  pip3 install -r requirements.txt"
    exit 1
fi

echo "✓ Ansible 已安装"
echo ""

# 测试 SSH 连接
echo "测试 SSH 连接..."
echo ""

HOSTS=("192.168.2.41" "192.168.2.42" "192.168.2.43")
SSH_KEY=~/id_ed25519-ansible
SSH_USER=ioe

failed_hosts=()

for host in "${HOSTS[@]}"; do
    echo -n "  测试 $host ... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes "${SSH_USER}@${host}" "echo ok" &>/dev/null; then
        echo "✓"
    else
        echo "❌"
        failed_hosts+=("$host")
    fi
done

echo ""

if [ ${#failed_hosts[@]} -gt 0 ]; then
    echo "❌ 以下主机连接失败："
    for host in "${failed_hosts[@]}"; do
        echo "  - $host"
    done
    echo ""
    echo "请检查："
    echo "  1. SSH 密钥权限: chmod 600 ~/id_ed25519-ansible"
    echo "  2. 目标主机 SSH 服务是否运行"
    echo "  3. 网络连通性: ping $host"
    echo "  4. SSH 公钥是否已添加到目标主机"
    echo ""
    read -p "是否继续安装？(yes/no): " continue
    if [ "$continue" != "yes" ]; then
        echo "安装已取消"
        exit 1
    fi
fi

echo "✓ 所有主机连接正常"
echo ""

# 使用 Ansible ping 测试
echo "使用 Ansible 测试连接..."
if ansible -i inventory/hosts.ini all -m ping; then
    echo ""
    echo "✓ Ansible 连接测试成功"
else
    echo ""
    echo "❌ Ansible 连接测试失败"
    echo ""
    echo "请检查 inventory/hosts.ini 配置"
    exit 1
fi

echo ""
echo "=========================================="
echo "准备开始安装..."
echo "=========================================="
echo ""
echo "安装步骤："
echo "  1. 预检查系统环境"
echo "  2. 配置中国镜像源"
echo "  3. 安装第一个 Server 节点 (192.168.2.41)"
echo "  4. 安装第二个 Server 节点 (192.168.2.42)"
echo "  5. 安装第三个 Server 节点 (192.168.2.43)"
echo "  6. 验证集群状态"
echo ""
echo "预计耗时: 10-15 分钟"
echo ""

read -p "按 Enter 继续，Ctrl+C 取消..."

echo ""
echo "开始安装..."
echo ""

# 执行安装
if make install; then
    echo ""
    echo "=========================================="
    echo "✓ 安装完成！"
    echo "=========================================="
    echo ""
    echo "后续步骤："
    echo ""
    echo "1. SSH 到任意 Server 节点："
    echo "   ssh -i ~/id_ed25519-ansible ioe@192.168.2.41"
    echo ""
    echo "2. 配置 kubectl："
    echo "   export KUBECONFIG=/etc/rancher/rke2/rke2.yaml"
    echo ""
    echo "3. 查看节点状态："
    echo "   sudo kubectl get nodes -o wide"
    echo ""
    echo "4. 查看系统 Pod："
    echo "   sudo kubectl get pods -A"
    echo ""
    echo "5. 获取集群 Token（用于添加更多节点）："
    echo "   sudo cat /var/lib/rancher/rke2/server/node-token"
    echo ""
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "❌ 安装失败"
    echo "=========================================="
    echo ""
    echo "请检查错误信息并查看日志："
    echo "  cat ansible.log"
    echo ""
    echo "或使用 Makefile 命令查看状态："
    echo "  make logs"
    echo ""
    exit 1
fi
