FROM python:3.14-alpine@sha256:26730869004e2b9c4b9ad09cab8625e81d256d1ce97e72df5520e806b1709f92

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
