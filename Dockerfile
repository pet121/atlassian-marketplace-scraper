# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=app.py \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Install system dependencies including Playwright requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    libnss3 \
    libnspr4 \
    libdbus-1-3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies and Playwright browsers
RUN pip install --no-cache-dir -r requirements.txt && \
    playwright install chromium --with-deps

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p \
    data/metadata/versions \
    data/metadata/checkpoints \
    data/metadata/descriptions \
    data/binaries \
    logs

# Expose Flask port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/', timeout=5)" || exit 1

# Default command runs the Flask web app
CMD ["python", "app.py"]
