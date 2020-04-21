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
kibana:5601


Порты на dev:

grafana:3000
prometheus:9090
alertmanager:9093
gitlabci:80
ui:8000
cadvisor:8080
rabbitmq:15692(метрики), 15672(web морда)
kibana:5601

Поправить веб хук и имя канала(секция slack_configs:) для отправки сообщений в Slack:
monitoring/alertmanager/config.yml


Данный проект расчитан на запуск и работу в окружение GCP - Google Cloud Platform (https://cloud.google.com/)
Так же для запуска проекта на машине, с которой будет осуществляться подъем всего, (управляющая машина)
должны быть установлены docker, docker-compose, docker-machine


Т.к. сборка образов это достаточно ресурсозатратный процесс и к тому же требующий быстрого интернета,
весь процесс рекомендуется производить в контекте ранее созданной машины GCP уровнем не ниже n1-standard-1
Т.е. создаем машину n1-standard-1, например так:

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-1 --google-project $(ID ПРОЕКТА В GCP) --google-zone europe-north1-a docker-host

После чего переключить на нее конетекст - eval $(docker-machine env docker-host)

Подготовка:

1. На подготовленную (управляющую) свою Linux машину клонируем репозиторий: -git clone https://github.com/lebedevdg/project.git
2. В каталоге ./docker копируем файл .env.example в .env: cp .env.example .env
3. Заполняем переменные внутри .env файла согласно комментариям внутри файла
4. Дополнительно экспортируем в окружение системы переменную DOCKER_HUB_PASSWORD, она понадобится для автоматической выгрузки образов в докер хаб
export DOCKER_HUB_PASSWORD=пароль
5.

Порядок сборки:

Поднимаем все - make allup

Для достижения цели делается следующее:
1. Создаем окружения: make envup
Получить информацию по окружениям можно: make info

2. Подготавливаем конфиги, заменяя в шаблонах на ip стендов: make prepare
3. Собираем все нужные образы: make build
4. Пушим собранные образы в докер хаб: make push
5. Поднимаем сервисы на трех окружениях: dev, stage и prod: make standsup (или постендно: make updev upstage upprod)

После чего мы имеем 3 стенда в GCP:
 dev (служебная машина с гитлабом, прометеем, графаной, аллертменеджером и т.д),
 stage и prod стенды, содержащие только экспортеры и уже задеплоенные приложения и ожидающие возможного деплоя со стороны гитлаба

Сразу после применения make стенды готовы и работают, можно посмотреть как все устроено, зайдя в графану или кибану
Но для полноценной работы CI/CD требуется минимальная ручная донастройка GitLab:

# заходим в Gitlab по адресу http://<docker-host_external_IP> под пользователем root и паролем, который был задан ранее в ./docker/.env файле
# там в Admin Area идем в Settings, там выбираем Users->Features->Sign-Up->Sign-up restrictions, выключаем Sign-up enabled, делаем Save changes
# далее в Groups создаем новую Group, например, otus, а в ней новый blank Project, например, project

# в Project, который мы создали, в Settings -> Integrations -> Slack notifications добавляем Webhook
# из предварительно добавленного в нужный канал Slack приложения Incoming WebHooks

# в Project, который мы создали, в Settings -> CI / CD -> Variables добавляем переменные
# DOCKER_HUB_LOGIN и DOCKER_HUB_PASSWORD (для этой включить Masked)
# это нужно, соответственно, для загрузки собранных image на Docker Hub


# на нашей управляющей машине выполняем для dev машины (это та, на которой развернут GitLab CI)
docker-machine config dev
# видим пути к трем файлам: ca.pem, cert.pem, key.pem
# в Project, который мы создали, в Settings -> CI / CD -> Variables добавляем переменные
# DEV_DOCKER_HOST_CA_FILE, DEV_DOCKER_HOST_CERT_FILE, DEV_DOCKER_HOST_KEY_FILE
# со значениями, равными содержимому, соответственно, наших трех файлов: ca.pem, cert.pem, key.pem

# теперь то же самое для stage машины
docker-machine config stage
# заполняем соответственно переменные STAGE_DOCKER_HOST_CA_FILE, STAGE_DOCKER_HOST_CERT_FILE, STAGE_DOCKER_HOST_KEY_FILE
# также нам понадобится IP адрес машины
docker-machine ip stage
# его значение заносим в переменную STAGE_DOCKER_HOST_IP

# и, наконец, делаем все то же самое для prod машины
docker-machine config prod
# заполняем соответственно переменные PROD_DOCKER_HOST_CA_FILE, PROD_DOCKER_HOST_CERT_FILE, PROD_DOCKER_HOST_KEY_FILE
# получаем IP адрес машины
docker-machine ip prod
# его значение заносим в переменную PROD_DOCKER_HOST_IP


# в клоне нашего рабочего репозитория создаем какой-нибудь новый branch, например, testbranch
# потом добавляем в репозиторий remote на наш Gitlab
# и пушим в наш Gitlab
git checkout -b testbranch
git remote add gitlab http://<docker-host_external_IP>/<your_group>/<your_project>.git
git push gitlab testbranch

# проверяем в нашем Gitlab состояние запустившегося pipeline в Project, который мы создали, в CI / CD -> Pipelines
# проверяем также в нашем канале Slack, что туда приходят оповещения от нашего Gitlab

# затем заходим по адресу нашего environment http://<docker-host_external_IP>:8000
# и убеждаемся, что наше собранное и задеплоенное приложение работает корректно

# если добавить какой-нибудь тэг, то можно будет по кнопке задеплоить приложение на окружения stage и prod
git tag 1.2.3
git push gitlab testbranch --tags


Опускаем все: make alldown

Для достижения цели делается следующее:
1. Гасим приложения на всех стендах: make standsdown (или постендно: make downdev downstage downprod)
2. Удаляем все машины GCP: make envdown
