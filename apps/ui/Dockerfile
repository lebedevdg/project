FROM python:3.6.0-alpine

WORKDIR /app
COPY . ./

RUN apk --no-cache --update add build-base=0.4-r1 && \
    pip install -r requirements.txt && \
    apk del build-base

ENV MONGO mongo
ENV MONGO_PORT 27017

WORKDIR /app/ui
ENV FLASK_APP ui.py

ENTRYPOINT ["gunicorn", "ui:app", "-b", "0.0.0.0"]
