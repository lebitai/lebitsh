#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以 root 权限运行" 1>&2
   exit 1
fi

echo "开始深度清理 Ubuntu 24.04 系统..."

# 更新软件包列表
apt update

# 升级所有已安装的软件包
apt upgrade -y

# 删除不再需要的软件包
apt autoremove -y

# 清理 APT 缓存
apt clean

# 清空回收站
rm -rf /home/*/.local/share/Trash/*/**
rm -rf /root/.local/share/Trash/*/**

# 删除旧的内核
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs apt -y purge

# 清理日志文件
journalctl --vacuum-time=3d

# 清理临时文件
rm -rf /tmp/*

# 清理缩略图缓存
rm -rf /home/*/.cache/thumbnails/*
rm -rf /root/.cache/thumbnails/*

# 清理软件包缓存
apt-get clean

# 清理 snap 包的旧版本
snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    snap remove "$snapname" --revision="$revision"
done

# 清理 Docker（如果已安装）
if command -v docker &> /dev/null; then
    docker system prune -af --volumes
fi

# 清理用户主目录下的缓存
find /home/* -type f \( -name '*.tmp' -o -name '*.temp' -o -name '*.swp' -o -name '*~' \) -delete

# 清理系统日志
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete
find /var/log -type f -name "*.old" -delete

echo "系统清理完成。"

# 显示磁盘使用情况
df -h
