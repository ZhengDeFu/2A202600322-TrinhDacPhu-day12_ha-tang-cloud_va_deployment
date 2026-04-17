# ============================================================
# Production Dockerfile — Multi-stage, non-root, Railway-ready
# ============================================================

# =========================
# Stage 1 — Builder
# =========================
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build dependencies (nếu có psycopg2, etc.)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install packages globally (QUAN TRỌNG — không dùng --user)
RUN pip install --no-cache-dir -r requirements.txt


# =========================
# Stage 2 — Runtime
# =========================
FROM python:3.11-slim AS runtime

# Create non-root user
RUN groupadd -r agent && useradd -r -g agent -d /app agent

WORKDIR /app

# Copy installed packages từ builder
COPY --from=builder /usr/local /usr/local

# Copy application code
COPY app/ ./app/
COPY utils/ ./utils/

# Fix permissions
RUN chown -R agent:agent /app

# Switch to non-root user
USER agent

# Environment variables
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Railway uses dynamic port
EXPOSE 8000

# Healthcheck (optional nhưng tốt)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# 🚀 Start FastAPI (PORT fix chuẩn Railway)
CMD sh -c "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"