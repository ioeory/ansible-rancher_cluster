#!/bin/bash
# 检查 etcd 备份状态

set -e

CLUSTER_TYPE="${1:-k3s}"
BACKUP_DIR="/var/lib/rancher/${CLUSTER_TYPE}/server/db/snapshots"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 etcd 备份状态检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "集群类型: ${CLUSTER_TYPE}"
echo "备份目录: ${BACKUP_DIR}"
echo ""

# 检查目录是否存在
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "❌ 备份目录不存在: ${BACKUP_DIR}"
    echo ""
    echo "可能原因:"
    echo "  1. 当前节点是 Agent 节点（Agent 节点没有 etcd）"
    echo "  2. ${CLUSTER_TYPE} 服务未正确安装"
    echo "  3. etcd 未启用"
    exit 1
fi

echo "✓ 备份目录存在"
echo ""

# 检查目录内容
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 备份目录内容"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "${BACKUP_DIR}"
TOTAL_FILES=$(ls -la | wc -l)
echo "总文件数: $((TOTAL_FILES - 3))"  # 减去 ., .., 和标题行
echo ""

# 列出所有文件
if [ "$(ls -A)" ]; then
    echo "所有文件:"
    ls -lh
    echo ""
else
    echo "⚠️  目录为空，没有任何备份文件"
    echo ""
fi

# 检查符合模式的备份文件
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 符合 snapshot-* 模式的备份"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ls snapshot-* 1> /dev/null 2>&1; then
    SNAPSHOT_COUNT=$(ls snapshot-* | wc -l)
    echo "符合模式的备份数: ${SNAPSHOT_COUNT}"
    echo ""
    echo "备份列表（最新的在前）:"
    ls -lht snapshot-*
    echo ""
    
    # 显示最新备份
    LATEST_BACKUP=$(ls -t snapshot-* | head -n 1)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 最新备份详情"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "文件名: ${LATEST_BACKUP}"
    echo "文件大小: $(du -h ${LATEST_BACKUP} | cut -f1)"
    echo "创建时间: $(stat -c %y ${LATEST_BACKUP} 2>/dev/null || stat -f %Sm ${LATEST_BACKUP})"
    echo ""
else
    echo "❌ 没有找到符合 snapshot-* 模式的备份文件"
    echo ""
    echo "可能原因:"
    echo "  1. 备份命令执行失败（静默失败）"
    echo "  2. 备份文件名格式不正确"
    echo "  3. 备份被清理脚本错误删除"
    echo "  4. 这是首次安装，尚未执行过备份"
    echo ""
fi

# 检查服务状态
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 服务状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet ${CLUSTER_TYPE}; then
    echo "✓ ${CLUSTER_TYPE} 服务运行正常"
    echo ""
    
    # 尝试手动执行备份命令（仅测试，不实际执行）
    echo "测试备份命令:"
    echo "  ${CLUSTER_TYPE} etcd-snapshot save --name test-snapshot-\$(date +%Y%m%d-%H%M%S)"
    echo ""
else
    echo "❌ ${CLUSTER_TYPE} 服务未运行"
    systemctl status ${CLUSTER_TYPE} --no-pager -l
    echo ""
fi

# 检查磁盘空间
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 磁盘空间"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
df -h "${BACKUP_DIR}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 检查完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

