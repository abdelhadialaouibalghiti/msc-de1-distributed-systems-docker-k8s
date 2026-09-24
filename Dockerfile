FROM python:3.11-slim

WORKDIR /app

RUN groupadd --system appuser && useradd --system --gid appuser appuser

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser app/*.py ./app/

USER appuser:appuser

EXPOSE 5000

CMD ["python", "-m", "flask", "--app", "app", "run", "--host=0.0.0.0", "--port=5000"]
