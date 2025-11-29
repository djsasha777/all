FROM python:3.10-alpine3.14

ENV REPO=""
ENV BRANCH=""
ENV FILEPATH=""
ENV TOKEN=""
ENV EXTERNAL=""

WORKDIR /app
COPY watcher/main.py /app/main.py
COPY watcher/requirements.txt /app/

EXPOSE 8088

RUN apk add --no-cache git

# Обновить pip и установить зависимости
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

CMD ["python", "/app/main.py"]
