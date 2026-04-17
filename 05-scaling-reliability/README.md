# Section 5 — Scaling & Reliability

## Mục tiêu học
- Implement health checks và readiness probes
- Graceful shutdown để không mất requests
- Stateless design với Redis
- Load balancing với nhiều instances

---

## develop/ — Health Checks + Graceful Shutdown

**Exercise 5.1 & 5.2**: Health checks và graceful shutdown

```bash
cd develop
pip install -r requirements.txt
python app.py
```

### Test Health Checks
```bash
# Liveness probe
curl http://localhost:8000/health

# Readiness probe
curl http://localhost:8000/ready
```

### Test Graceful Shutdown
```bash
# Terminal 1: Chạy app
python app.py

# Terminal 2: Gửi request chậm
curl -X POST http://localhost:8000/ask?question="test"

# Terminal 3: Gửi SIGTERM
kill -SIGTERM <pid>

# Xem log: app sẽ đợi request hoàn thành trước khi tắt
```

---

## production/ — Stateless Design + Load Balancing

**Exercise 5.3, 5.4, 5.5**: Stateless với Redis + Load balancing

### Chạy với Docker Compose

```bash
cd production

# Start với 3 instances
docker compose up --build

# Hoặc scale động
docker compose up --build --scale agent=5
```

### Test Stateless Design

```bash
# Chạy test script
python test_stateless.py
```

Script này sẽ:
1. Tạo session mới
2. Gửi 5 requests liên tiếp
3. Mỗi request có thể đến instance khác nhau (xem `served_by`)
4. Verify rằng conversation history được preserve qua Redis

### Verify Load Balancing

```bash
# Gửi nhiều requests và xem distribution
for i in {1..10}; do
  curl -X POST http://localhost:8080/chat \
    -H "Content-Type: application/json" \
    -d '{"question": "test '$i'"}' | jq '.served_by'
done
```

Bạn sẽ thấy requests được phân phối đều qua các instances khác nhau.

### Kiểm tra Redis

```bash
# Connect vào Redis container
docker compose exec redis redis-cli

# Xem tất cả sessions
KEYS session:*

# Xem nội dung một session
GET session:<session-id>
```

---

## Kiến trúc

```
                    ┌─────────────┐
                    │   Nginx     │
                    │ Load Balancer│
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    ┌─────▼─────┐    ┌─────▼─────┐   ┌─────▼─────┐
    │ Agent 1   │    │ Agent 2   │   │ Agent 3   │
    │ (stateless)│    │ (stateless)│   │ (stateless)│
    └─────┬─────┘    └─────┬─────┘   └─────┬─────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
                    ┌──────▼──────┐
                    │    Redis    │
                    │  (sessions) │
                    └─────────────┘
```

---

## Checklist Exercises

### ✅ Exercise 5.1: Health & Readiness Checks (2 điểm)
- [ ] `/health` endpoint trả về status, uptime, checks
- [ ] `/ready` endpoint trả về 503 khi chưa sẵn sàng
- [ ] Health check bao gồm memory check

### ✅ Exercise 5.2: Graceful Shutdown (2 điểm)
- [ ] App handle SIGTERM signal
- [ ] Đợi in-flight requests hoàn thành
- [ ] Log shutdown process rõ ràng
- [ ] Timeout 30 giây cho graceful shutdown

### ✅ Exercise 5.3: Stateless Design (2 điểm)
- [ ] Không lưu state trong memory
- [ ] Session data lưu trong Redis
- [ ] Conversation history persist qua Redis
- [ ] TTL cho sessions (1 giờ)

### ✅ Exercise 5.4: Load Balanced Stack (1 điểm)
- [ ] Docker Compose với 3+ instances
- [ ] Nginx load balancer
- [ ] Health checks trong docker-compose
- [ ] Redis shared storage

### ✅ Exercise 5.5: Test Stateless (1 điểm)
- [ ] Test script gửi multi-turn conversation
- [ ] Verify requests đến instances khác nhau
- [ ] Verify history được preserve
- [ ] Log instance IDs rõ ràng

---

## Câu hỏi thảo luận

1. Tại sao cần phân biệt health check và readiness check?
2. Stateless có nghĩa là gì? Tại sao quan trọng khi scale?
3. Redis có thể trở thành bottleneck không? Giải pháp?

---

## Troubleshooting

### Redis connection failed
```bash
# Check Redis đang chạy
docker compose ps redis

# Check logs
docker compose logs redis

# Test connection
docker compose exec redis redis-cli ping
```

### Load balancing không hoạt động
```bash
# Check nginx logs
docker compose logs nginx

# Check agent instances
docker compose ps agent

# Test trực tiếp vào agent (bypass nginx)
docker compose exec agent curl http://localhost:8000/health
```

### Session không persist
```bash
# Verify Redis có data
docker compose exec redis redis-cli KEYS "session:*"

# Check app logs
docker compose logs agent | grep -i redis
```
