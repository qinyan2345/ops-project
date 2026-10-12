# 高可用运维平台

基于 Docker Compose 编排的完整运维体系，涵盖负载均衡、数据库主从、缓存高可用、监控告警、日志收集、CI/CD 和配置管理。

## 架构

| 层次 | 组件 | 作用 |
|------|------|------|
| 入口 | Nginx | HTTPS、限流、反向代理 |
| 应用 | Flask + Gunicorn | 业务接口，读写分离 |
| 应用 | Gitea | 自托管代码仓库 |
| 数据 | MySQL 主从 | master 写、slave 读 |
| 数据 | Redis 主从 + Sentinel | 缓存高可用、自动故障转移 |
| 监控 | Prometheus + Grafana | 指标采集、可视化、告警 |
| 日志 | Loki + Promtail | 集中日志收集 |
| CI/CD | Gitea Webhook + Shell | 自动部署、健康检查、回滚 |
| 配置管理 | Ansible | 幂等部署 |

## 技术栈

Docker、Docker Compose、Nginx、Flask、Gunicorn、MySQL、Redis、Sentinel、Gitea、Prometheus、Grafana、Loki、Promtail、Ansible、Shell

## 快速开始

```bash
# 1. 克隆
git clone git@github.com:qinyan2345/ops-project.git
cd ops-project

# 2. 生成自签证书
cd nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key -out server.crt -subj "/CN=localhost"
cd ../..

# 3. 启动
docker-compose up -d

# 4. 验证
curl -k https://localhost/health
```


## 访问地址

| 服务 | 地址 |
|------|------|
| 应用 | https://localhost |
| Gitea | https://localhost/gitea/ |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |

## 遇到的问题

| 问题 | 解决 |
|------|------|
| Docker + UFW 冲突 | 禁用 UFW |
| Nginx upstream 解析失败 | 用 resolver 运行时解析 |
| MySQL 主从认证失败 | 改用 mysql_native_password |
| Redis Sentinel 解析失败 | 用固定 IP + IPAM 子网 |
| Gitea Webhook 被拒 | 配置 ALLOWED_HOST_LIST |
| 并发部署 IP 冲突 | deploy.sh 加 flock 锁 |
