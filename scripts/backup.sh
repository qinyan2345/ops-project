#!/bin/bash
BACKUP_DIR=/opt/backup/mysql
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p $BACKUP_DIR

echo "[$(date)] 开始备份 MySQL..."
docker exec mysql mysqldump -uroot -proot123 --all-databases --single-transaction | gzip > $BACKUP_DIR/mysql_$DATE.sql.gz

if [ $? -eq 0 ]; then
    SIZE=$(du -h $BACKUP_DIR/mysql_$DATE.sql.gz | cut -f1)
    echo "[$(date)] 备份成功: mysql_$DATE.sql.gz ($SIZE)"
else
    echo "[$(date)] 备份失败！" >&2
    exit 1
fi

find $BACKUP_DIR -name "*.sql.gz" -mtime +$KEEP_DAYS -delete
echo "[$(date)] 已清理 $KEEP_DAYS 天前的备份"
