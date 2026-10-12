#!/bin/bash

# 加锁，防止并发部署
exec 200>/tmp/deploy.lock
flock -n 200 || { echo "[$(date)] 另一个部署正在进行，跳过"; exit 1; }

cd /home/qinyan/ops-project

echo "[$(date)] 开始部署..."

# 拉取最新代码
git pull gitea main

# 记录旧版本镜像 ID（用于回滚）
OLD_IMAGE=$(docker inspect --format='{{.Image}}' flask 2>/dev/null || echo "none")

# 重新构建并启动
docker-compose up -d --build flask

# 等待容器启动
sleep 5

# 健康检查
if curl -k -s --max-time 5 https://192.168.133.100/health | grep -q "OK"; then
    echo "[$(date)] 部署成功，服务正常"
else
    echo "[$(date)] 健康检查失败，开始回滚..."
    if [ "$OLD_IMAGE" != "none" ]; then
        docker stop flask && docker rm flask
        docker run -d --name flask --network ops-project_app-net \
            --env MYSQL_HOST=mysql --env REDIS_HOST=redis-master \
            "$OLD_IMAGE"
        echo "[$(date)] 已回滚到旧版本"
    fi
    exit 1
fi

echo "[$(date)] 部署完成"
