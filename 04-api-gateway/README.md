# Section 4 — API Gateway & Security

## Mục tiêu học
- Hiểu tại sao cần lớp bảo vệ trước agent
- Implement API Key authentication
- Implement JWT authentication (nâng cao)
- Rate limiting và cost protection

---

## Ví dụ Basic — API Key Authentication

```
develop/
├── app.py              # Agent với API Key auth
├── test_auth.py        # Test script
└── requirements.txt
```

### Chạy thử
```bash
cd basic
pip install -r requirements.txt
AGENT_API_KEY=my-secret-key python app.py

# Test với key hợp lệ
curl -H "X-API-Key: my-secret-key" http://localhost:8000/ask \
     -X POST -H "Content-Type: application/json" \
     -d '{"question": "hello"}'

# Test không có key → 401
curl http://localhost:8000/ask -X POST \
     -H "Content-Type: application/json" \
     -d '{"question": "hello"}'
```

---

## Ví dụ Advanced — JWT + Rate Limiting + Cost Guard

```
production/
├── app.py              # Full security stack
├── auth.py             # JWT token logic
├── rate_limiter.py     # In-memory rate limiter
├── cost_guard.py       # Token budget và spending alerts
├── test_advanced.py    # Test suite
└── requirements.txt
```

### Chạy thử
```bash
cd advanced
pip install -r requirements.txt
python app.py

# Lấy JWT token
curl -X POST http://localhost:8000/auth/token \
     -H "Content-Type: application/json" \
     -d '{"username": "student", "password": "demo123"}'

# Dùng token
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/ask \
     -X POST -H "Content-Type: application/json" \
     -d '{"question": "what is docker?"}'

# Test rate limit: spam 20 requests liên tiếp
python test_advanced.py --test rate-limit
```

---

## Luồng bảo vệ

```
Request
  → Auth Check (401 nếu fail)
  → Rate Limit (429 nếu vượt quota)
  → Input Validation (422 nếu invalid)
  → Cost Check (402 nếu hết budget)
  → Agent (200 nếu mọi thứ OK)
```

---

## Câu hỏi thảo luận

1. Khi nào nên dùng API Key vs JWT vs OAuth2?
2. Rate limit nên đặt bao nhiêu request/phút cho một AI agent?
3. Nếu API key bị lộ, bạn phát hiện và xử lý như thế nào?

## Trả lời câu hỏi thảo luận 
1. Khi nào nên dùng API Key vs JWT vs OAuth2?

API Key phù hợp cho server-to-server communication, internal services, hoặc khi cần authentication đơn giản và nhanh. JWT tốt hơn khi cần stateless authentication với user context (user_id, roles, permissions) và có thể expire tự động, thích hợp cho web/mobile apps với nhiều users. OAuth2 dành cho trường hợp cần delegate access (ví dụ "Login with Google"), khi app cần truy cập resources của user từ third-party service, hoặc khi build public API cho developers bên ngoài integrate.

2. Rate limit nên đặt bao nhiêu request/phút cho một AI agent?

Phụ thuộc vào use case nhưng thường 10-20 requests/phút cho free tier, 60-100 requests/phút cho paid users là hợp lý. Cần tính đến response time của agent (thường 2-10 giây), chi phí LLM API (mỗi request có thể tốn $0.01-0.1), và khả năng xử lý của infrastructure. Nên implement tiered limits: free users 5-10 req/min, basic plan 30 req/min, premium 100+ req/min, và có burst allowance (cho phép vượt ngắn hạn nhưng throttle sau đó).

3. Nếu API key bị lộ, bạn phát hiện và xử lý như thế nào?

Ngay lập tức revoke key đó trong database và generate key mới cho user hợp lệ. Audit logs để xem key bị lộ đã được dùng như thế nào (IP addresses, requests made, data accessed). Notify user qua email về security incident và hướng dẫn rotate key. Implement monitoring để detect suspicious patterns (requests từ nhiều IPs khác nhau, traffic spike bất thường, geographic anomalies). Nếu có thiệt hại, assess impact và có thể cần reset toàn bộ keys trong hệ thống. Long-term thì nên thêm IP whitelisting, request signing, hoặc chuyển sang JWT với short expiration để giảm blast radius khi bị compromise.
