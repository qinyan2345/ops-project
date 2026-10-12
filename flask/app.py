from dbutils.pooled_db import PooledDB
from prometheus_flask_exporter import PrometheusMetrics
from flask import Flask, jsonify
import pymysql
import redis
import os

app = Flask(__name__)
metrics = PrometheusMetrics(app)
r = redis.Redis(host='redis-master', port=6379, decode_responses=True)

pool = PooledDB(
    creator=pymysql,
    maxconnections=10,
    mincached=2,
    host='mysql', user='root', password='root123', database='appdb'
)

pool_slave = PooledDB(
    creator=pymysql,
    maxconnections=10,
    mincached=2,
    host='mysql-slave', user='root', password='root123', database='appdb'
)

@app.route('/')
def index():
    return '''
    <!DOCTYPE html>
    <html>
    <head><title>运维平台 Demo</title>
    <style>
        body { font-family: Arial; max-width: 600px; margin: 50px auto; }
        h2 { color: #333; }
        a { display: block; margin: 10px 0; padding: 10px;
            background: #f0f0f0; text-decoration: none; color: #0066cc;
            border-radius: 5px; }
        a:hover { background: #e0e0e0; }
        .tag { color: #888; font-size: 12px; }
    </style></head>
    <body>
    <h2>运维平台 Demo v5</h2>
        <a href="/api/user/1">查询用户 1 (Alice)</a>
        <a href="/api/user/2">查询用户 2 (Bob)</a>
        <a href="/api/user/3">查询用户 3 (Charlie)</a>
        <a href="/api/user/999">查询不存在的用户 (测试 404)</a>
        <a href="/api/stats">缓存命中率统计</a>
        <a href="/health">健康检查 <span class="tag">(给程序用的)</span></a>
        <hr>
        <p class="tag">Grafana: <a href="http://192.168.133.100:3000">192.168.133.100:3000</a></p>
        <p class="tag">Prometheus: <a href="http://192.168.133.100:9090">192.168.133.100:9090</a></p>
    </body>
    </html>
    '''

@app.route('/health')
def health():
    return "OK"

@app.route('/api/user/<int:uid>')
def get_user(uid):
    key = f"user:{uid}"
    cached = r.get(key)
    if cached:
        r.incr("cache_hit")
        return jsonify({"source": "cache", "data": cached})
    conn = pool_slave.connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT name, email FROM users WHERE id=%s", (uid,))
            row = cur.fetchone()
    finally:
        conn.close()

    if not row:
        return jsonify({"error": "not found"}), 404
    data = f"{row[0]},{row[1]}"
    r.setex(key, 60, data)
    r.incr("cache_miss")
    return jsonify({"source": "db", "data": data})

@app.route('/api/stats')
def stats():
    hit = int(r.get("cache_hit") or 0)
    miss = int(r.get("cache_miss") or 0)
    total = hit + miss
    rate = f"{hit/total*100:.1f}%" if total else "0%"
    return jsonify({"hit": hit, "miss": miss, "hit_rate": rate})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
