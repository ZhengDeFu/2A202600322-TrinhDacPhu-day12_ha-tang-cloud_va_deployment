# Section 1 — Từ Localhost Đến Production

## Mục tiêu học
- Hiểu tại sao "it works on my machine" là vấn đề
- Nhận ra sự khác biệt giữa dev và production environment
- Áp dụng 4 nguyên tắc 12-factor cơ bản

---

## Ví dụ Basic — Agent "Kiểu Localhost"

```
develop/
├── app.py          # ❌ Anti-patterns: hardcode secrets, no config, no health check
├── .env.example
└── requirements.txt
```

### Chạy thử
```bash
cd basic
pip install -r requirements.txt
python app.py
# Truy cập: http://localhost:8000
```

### Những vấn đề trong code này:
1. API key hardcode trong code
2. Không có health check endpoint
3. Debug mode bật cứng
4. Không xử lý SIGTERM gracefully
5. Config không đến từ environment

---

## Ví dụ Advanced — 12-Factor Compliant Agent

```
production/
├── app.py          # ✅ Clean: config from env, health check, graceful shutdown
├── config.py       # ✅ Centralized config management
├── .env.example    # ✅ Template — không commit .env thật
└── requirements.txt
```

### Chạy thử
```bash
cd advanced
pip install -r requirements.txt
cp .env.example .env
# Sửa .env nếu cần
python app.py
```

### So sánh với Basic:

| | Basic (❌) | Advanced (✅) |
|--|-----------|--------------|
| Config | Hardcode trong code | Đọc từ env vars |
| Secrets | `api_key = "sk-abc123"` | `os.getenv("OPENAI_API_KEY")` |
| Port | Cố định `8000` | Từ `PORT` env var |
| Health check | Không có | `GET /health` |
| Shutdown | Tắt đột ngột | Graceful — hoàn thành request hiện tại |
| Logging | `print()` | Structured JSON logging |

---

## Câu hỏi thảo luận

1. Điều gì xảy ra nếu bạn push code với API key hardcode lên GitHub public?
2. Tại sao stateless quan trọng khi scale?
3. 12-factor nói "dev/prod parity" — nghĩa là gì trong thực tế?


## Câu trả lời 

1. Hardcoded API key in source code
   → Security risk: nếu push lên GitHub public, hacker có thể lấy key và sử dụng API, gây mất tiền.

2. Fixed port (hardcoded port 8000)
   → Not flexible: cloud platforms thường set port qua environment variable.

3. Debug mode enabled permanently
   → Security risk: debug mode có thể leak internal information.

4. No health check endpoint
   → Monitoring systems không biết service còn sống hay không.

5. No graceful shutdown (SIGTERM handling)
   → Khi container stop, requests đang chạy có thể bị mất.

6. Configuration not loaded from environment variables
   → Không thể thay đổi config giữa dev và production.

7. Using print() instead of structured logging
   → Khó debug và monitor trong production.
