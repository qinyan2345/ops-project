# 基于 Docker Compose 的 Web 应用部署与自动化运维平台

在一台 2核4G 虚拟机上，用 Docker Compose 编排 Nginx + Flask + MySQL + Redis 四层架构，集成监控告警、自动备份和健康巡检，实现从部署到运维的完整链路。


## 架构

```
用户
 │
 ▼
Nginx (HTTPS + 跳转 + 限流)
 │
 ▼
Flask 应用 (MySQL 查询 + Redis 缓存)
 │
 ├── MySQL (持久化存储)
 └── Redis (缓存，60s 过期)

监控: Prometheus + Grafana + Node Exporter
```


## 技术栈

| 组件 | 技术 | 作用 |
|------|------|------|
| 反向代理 | Nginx | HTTPS、跳转、限流、反代 |
| 应用 | Flask + Python | 提供 API 和页面 |
| 数据库 | MySQL 8.0 | 持久化存储 |
| 缓存 | Redis 6 | 缓存热点数据，减轻数据库压力 |
| 监控 | Prometheus + Grafana | 指标采集、可视化、告警 |
| 容器 | Docker + Docker Compose | 编排 7 个服务 |
| 脚本 | Shell | 备份、巡检 |

## 功能特性

- **一键部署**：`docker-compose up -d` 启动全部 7 个服务
- **HTTPS**：自签证书 + HTTP 自动跳转
- **限流**：Nginx limit_req，每 IP 10r/s，突发 20
- **缓存**：Redis 缓存用户查询，命中率 90%+
- **自动备份**：每天凌晨 2 点备份 MySQL，保留 7 天
- **健康巡检**：每 5 分钟检查 CPU/内存/磁盘/容器状态
- **监控告警**：CPU>80%、内存>85%、磁盘>85% 触发告警

## 快速开始

### 环境要求

- Ubuntu 22.04
- Docker 20+
- Docker Compose v2+

### 部署步骤

```bash
# 1. 克隆项目
git clone git@github.com:qinyan2345/ops-project.git
cd ops-project

# 2. 生成自签证书
cd nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key -out server.crt \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=Test/CN=localhost"
cd ../..

# 3. 启动所有服务
docker-compose up -d

# 4. 验证
docker-compose ps
curl -k https://localhost/health
