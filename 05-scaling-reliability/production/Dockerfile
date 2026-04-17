FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY 05-scaling-reliability/production/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY 05-scaling-reliability/production/app.py .
COPY 05-scaling-reliability/production/utils ./utils/

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
