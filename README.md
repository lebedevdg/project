# project
OTUS Project

Порты на stage и prod:

node-exporter:9100
mongodb-exporter:9216
blackbox-exporter:9115
cadvisor:8080
robot:8001
ui:8000
rabbitmq:15692(метрики), 15672(web морда)


Порты на dev:

grafana:3000
prometheus:9090
alertmanager:9093
gitlabci:80
ui:8000
cadvisor:8080
rabbitmq:15692(метрики), 15672(web морда)

Поправить веб хук для отправки сообщений в слаку



Порядок сборки:

Поднимаем все - make allup

Для достижения цели, деается следующее:
1. Создаем окружения - make envup
2. Подготавливаем конфиги заменяя в них шаблоны на ip стендов - make prepare
3. Собираем образы локально - make build
4. Пушим образы в докер хаб - make push
5. Поднимаем сервисы на трех окружениях: dev, stage и prod - make standsup (или постендно - make updev upstage upprod)

Опаскаем все - make alldown

Для достижения цели делается следюущее:
1. После всего, гасим приложения на всех стендах - make standsdown (или постендно - make downdev downstage downprod)
2. Удаляем все машины GCP - make envdown
