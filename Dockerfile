FROM python:3.12-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port 80 for Container Apps
EXPOSE 80

# Use gunicorn with proper workers for production
CMD ["gunicorn", "--bind=0.0.0.0:80", "--workers=2", "--threads=4", "--timeout=60", "--access-logfile=-", "--error-logfile=-", "--log-level=info", "app:app"]
