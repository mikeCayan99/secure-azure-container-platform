FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN groupadd -r appgroup && useradd --no-log-init -r -g appgroup appuser

COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8080

CMD ["python", "app.py"]