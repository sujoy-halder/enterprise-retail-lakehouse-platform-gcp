FROM python:3.12-alpine@sha256:6d43704baacd1bfbe7c295d7f13079d5d8104ed33568873133f8fc69980419df

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src

WORKDIR /app

RUN addgroup -S app && adduser -S -G app -u 10001 app

COPY docker/etl-service/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY docker/etl-service/src /app/src
COPY spark /app/spark

USER app

EXPOSE 8080
CMD ["uvicorn", "retail_etl.main:app", "--host", "0.0.0.0", "--port", "8080"]
