FROM python:3.11-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PADDLE_PDX_CACHE_HOME=/cache/paddlex HF_HOME=/cache/huggingface
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY ocr-service/requirements.txt .
RUN python -m pip install --no-cache-dir paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ && python -m pip install --no-cache-dir -r requirements.txt
RUN useradd --create-home --uid 10001 ocr && mkdir -p /cache/paddlex /cache/huggingface && chown -R ocr:ocr /cache /app
COPY ocr-service/main.py ocr-service/adapter.py ocr-service/image_processing.py ocr-service/warmup.py ./
COPY docs/ocr-test/receipt-sample.png ./sample.png
USER ocr
EXPOSE 8002
CMD ["python","-m","uvicorn","main:app","--host","0.0.0.0","--port","8002","--workers","1","--no-access-log"]
