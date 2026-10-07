#!/bin/bash
LOG_FILE=/var/log/check.log
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

check_cpu() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
    if [ "$CPU" -gt "$CPU_THRESHOLD" ]; then
        log "WARN: CPU 使用率 ${CPU}% 超过阈值"
    else
        log "OK: CPU 使用率 ${CPU}%"
    fi
}

check_mem() {
    MEM=$(free -m | awk 'NR==2{printf "%.0f", $3/$2 * 100}')
    if [ "$MEM" -gt "$MEM_THRESHOLD" ]; then
        log "WARN: 内存使用率 ${MEM}% 超过阈值"
    else
        log "OK: 内存使用率 ${MEM}%"
    fi
}

check_disk() {
    DISK=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ "$DISK" -gt "$DISK_THRESHOLD" ]; then
        log "WARN: 磁盘使用率 ${DISK}% 超过阈值"
    else
        log "OK: 磁盘使用率 ${DISK}%"
    fi
}

check_containers() {
    for name in nginx flask mysql redis; do
        STATUS=$(docker inspect -f '{{.State.Status}}' $name 2>/dev/null)
        if [ "$STATUS" != "running" ]; then
            log "ERROR: 容器 $name 状态异常: $STATUS"
        else
            log "OK: 容器 $name 运行中"
        fi
    done
}

log "===== 开始巡检 ====="
check_cpu
check_mem
check_disk
check_containers
log "===== 巡检结束 ====="
