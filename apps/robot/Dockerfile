FROM python:3.6.0-alpine

WORKDIR /app

COPY . ./

RUN apk --no-cache --update add build-base=0.4-r1 && \
    pip install -r requirements.txt && \
    apk del build-base

ENV MONGO mongo
ENV MONGO_PORT 27017
ENV RMQ_HOST rabbit
ENV RMQ_QUEUE urls
ENV RMQ_USERNAME guest
ENV RMQ_PASSWORD guest
ENV CHECK_INTERVAL 10
#ENV EXCLUDE_URLS .*github.com

#ENTRYPOINT ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]
ENTRYPOINT ["python", "-u", "crawler/crawler.py"]
