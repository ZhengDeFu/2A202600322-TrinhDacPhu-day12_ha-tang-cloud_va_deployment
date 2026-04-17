# Section 2 — Docker: Đóng Gói Agent Thành Container

## Mục tiêu học
- Hiểu container là gì và tại sao cần nó
- Viết Dockerfile đúng cách (single vs multi-stage)
- Dùng Docker Compose để chạy multi-service stack
- Tối ưu image size xuống dưới 500 MB

---

## Ví dụ Basic — Dockerfile Đơn Giản

```
develop/
├── app.py
├── Dockerfile          # Single-stage, dễ hiểu
├── .dockerignore
└── requirements.txt
```

### Chạy thử
```bash
# IMPORTANT: Build from project root!
cd ../..  # Go to project root

# Build image
docker build -f 02-docker/develop/Dockerfile -t agent-develop .

# Xem size
docker images agent-develop

# Chạy container
docker run -p 8000:8000 agent-develop

# Test
curl http://localhost:8000/health
```

---

## Ví dụ Advanced — Multi-Stage + Docker Compose

```
production/
├── app.py
├── Dockerfile              # Multi-stage build → image nhỏ hơn nhiều
├── docker-compose.yml      # Full stack: agent + vector store + redis
├── nginx/
│   └── nginx.conf          # Reverse proxy
├── .dockerignore
└── requirements.txt
```

### Chạy thử
```bash
# From project root
cd ../..  # if not already there

# Khởi động toàn bộ stack (1 lệnh!)
docker compose -f 02-docker/production/docker-compose.yml up

# Xem các service đang chạy
docker compose -f 02-docker/production/docker-compose.yml ps

# Test agent qua Nginx
curl http://localhost/health

# Dừng toàn bộ
docker compose -f 02-docker/production/docker-compose.yml down
```

### So sánh image size:

```bash
# Basic vs Advanced
docker images | grep agent
# agent-basic    ~  800 MB  ← python:3.11 base
# agent-advanced ~  160 MB  ← python:3.11-slim + multi-stage
```

---

## Lý thuyết: Tại Sao Multi-Stage?

```dockerfile
# Stage 1: Builder — có đầy đủ tools để compile deps
FROM python:3.11 AS builder   # 1 GB
RUN pip install ...            # thêm deps vào layer này

# Stage 2: Runtime — chỉ copy những gì cần chạy
FROM python:3.11-slim          # 150 MB ← bắt đầu từ image sạch
COPY --from=builder ...        # copy chỉ /site-packages
```

**Kết quả:** Final image chỉ có runtime, không có pip, không có build tools → nhỏ và an toàn hơn.

---

## Câu hỏi thảo luận

1. Tại sao `COPY requirements.txt .` rồi `RUN pip install` TRƯỚC khi `COPY . .`?
2. `.dockerignore` nên chứa những gì? Tại sao `venv/` và `.env` quan trọng?
3. Nếu agent cần đọc file từ disk, làm sao mount volume vào container?


## Trả lời câu hỏi thảo luận

1. Base image là gì?

Base image là image nền được dùng để tạo container.
Trong ví dụ này, base image thường là:

python:3.11   (basic version)
python:3.11-slim   (production version)

Nó chứa Python runtime và hệ điều hành cần thiết
để chạy ứng dụng.


2. Working directory là gì?

Working directory là thư mục bên trong container
nơi ứng dụng được chạy.

Ví dụ:

WORKDIR /app

Điều này có nghĩa tất cả file sẽ được copy vào /app
và các lệnh sau đó sẽ chạy trong thư mục này.


3. Tại sao COPY requirements.txt trước?

COPY requirements.txt trước giúp Docker cache layer
khi cài dependencies.

Nếu code thay đổi nhưng requirements.txt không đổi,
Docker sẽ không cần cài lại dependencies,
giúp build nhanh hơn nhiều.


4. CMD vs ENTRYPOINT khác nhau thế nào?

CMD:
- Lệnh mặc định khi container chạy
- Có thể override khi run container

ENTRYPOINT:
- Lệnh chính của container
- Khó override hơn
- Thường dùng cho executable container

Ví dụ:

CMD ["python", "app.py"]

ENTRYPOINT ["python"]

CMD ["app.py"]
