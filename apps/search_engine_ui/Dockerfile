FROM python:3.6.0-alpine
WORKDIR /app
COPY . /app

RUN apk --no-cache --update add build-base=0.4-r1 && \
    pip install -r /app/requirements.txt && \
    apk del build-base
