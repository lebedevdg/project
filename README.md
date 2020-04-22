## OTUS Project

### Участники проекта
- Сергей Толстинский 
- Денис Лебедев 
- Алексей Николаев

### Реализация
В основе проекта реализация деплоя бота Robot и вспомогательных приложений(RabbitMQ, mongodb etc)
- [x] Используются ресурсы Google Coud Platform
- [x] Реализована инфраструктура CI/CD с доставкой на три стенда dev, stage и prod
- [x] Настроена обратная связь с билдпроцессом (интеграция в Slack, отчеты о покрытии тестами Gitlab)
- [x] Реализована инфраструктура мониторинга, логирования и алертинга(slack, email). Мониторинг один на все три окружения, с переключаемыми дэшбордами
- [x] Проект полностью расположен в GitHub и готов к развертыванию "в одну команду"
- [x] Цели билд-процесса управляются "по кнопке" в GitLab
- [x] Описание, ссылки на установку необходимого ПО и документация к проекту находится в данном README


### Environments
dev, stage и прод

### Порты на stage и prod
- node-exporter:9100 
- mongodb-exporter:9216 
- blackbox-exporter:9115 
- cadvisor:8080 
- robot:8001 
- ui:8000 
- rabbitmq:15692(метрики), 
- rabbitmq:15672(web) 
- kibana:5601

### Порты на dev
- grafana:3000 
- prometheus:9090 
- alertmanager:9093 
- gitlabci:80
- ui:8000 
- cadvisor:8080 
- rabbitmq:15692(метрики), 
- rabbitmq:15672(web) 
- kibana:5601

### Описание
Данный проект расчитан на запуск и работу в окружении GCP - Google Cloud Platform (https://cloud.google.com/). Так же для запуска проекта на машине, с которой будет осуществляться развертывание всех окружений(управляющая машина), должны быть установлены docker, docker-compose, docker-machine.

##### Документация по установке
Google Cloud SDK
https://cloud.google.com/sdk/docs/

Docker
https://docs.docker.com/engine/install/

Docker-compose:
https://docs.docker.com/compose/install/

Docker-machine
https://docs.docker.com/machine/install-machine/


Т.к. сборка образов это достаточно ресурсозатратный процесс и к тому же требующий быстрого интернета, весь процесс рекомендуется производить в контекте ранее созданной машины GCP уровнем не ниже n1-standard-1 

Т.е. создаем машину n1-standard-1, например так:

`docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-project $(ID ПРОЕКТА В GCP) --google-zone europe-north1-a docker-host`

После чего переключить на нее контекст

`eval $(docker-machine env docker-host)`

### Подготовка
На подготовленную (управляющую) Linux машину клонируем репозиторий:

`git clone https://github.com/lebedevdg/project.git`

В каталоге ./docker копируем файл .env.example в .env:

`cp .env.example .env`

Заполняем переменные внутри .env файла согласно комментариям внутри файла Дополнительно экспортируем в окружение системы переменную `DOCKER_HUB_PASSWORD`, она понадобится для автоматической выгрузки образов в докер хаб.

`export DOCKER_HUB_PASSWORD=пароль `

Поправить веб хук и имя канала(секция slack_configs:) для отправки сообщений в Slack: monitoring/alertmanager/config.yml

### Порядок сборки

Поднимаем всё в GCP

`make allup`

При этом скрипт 
создает окружения: 

`make envup` 

Получает информацию по окружениям: 

`make info`

Подготавливает конфиги, заменяя в шаблонах на ip стендов: 

`make prepare`

Собирает все нужные образы: 

`make build`

Пушит собранные образы в докер хаб: 

`make push`

Поднимает сервисы на трех окружениях dev, stage и prod: 

`make standsup `

(или постендно: `make updev upstage upprod`)

После чего мы имеем 3 стенда в GCP: 
dev (служебная машина с гитлабом, прометеем, графаной, аллертменеджером и т.д), stage и prod стенды, содержащие только экспортеры и уже задеплоенные приложения и ожидающие возможного деплоя со стороны гитлаба

Сразу после применения make стенды готовы и работают, можно посмотреть как все устроено, зайдя в графану или кибану, но для полноценной работы CI/CD требуется минимальная ручная донастройка GitLab.

### Настройка пайплайнов в GitLab

##### Первичная настройка

Заходим в Gitlab по адресу http://<docker-host_external_IP> под пользователем root и паролем, который был задан ранее в ./docker/.env файле.

В Admin Area идем в Settings, там выбираем Users->Features->Sign-Up->Sign-up restrictions, выключаем Sign-up enabled и делаем Save changes.

Далее в Groups создаем новую Group, например, otus, а в ней новый blank Project, например, project.

В Project, который мы создали, в Settings -> Integrations -> Slack notifications добавляем Webhook из предварительно добавленного в нужный канал Slack приложения Incoming WebHooks.

##### Добавление переменных в проект GitLab

Также в проекте в Settings -> CI / CD -> Variables добавляем переменные `DOCKER_HUB_LOGIN` и `DOCKER_HUB_PASSWORD` (для этой включить Masked) это нужно, соответственно, для загрузки собранных image на Docker Hub на нашей управляющей машине. 

Выполняем для dev машины (это та, на которой развернут GitLab CI) 

`docker-machine config dev`

видим пути к трем файлам: ca.pem, cert.pem, key.pem 

Добавляем переменные `DEV_DOCKER_HOST_CA_FILE`, `DEV_DOCKER_HOST_CERT_FILE`, `DEV_DOCKER_HOST_KEY_FILE` со значениями, равными содержимому, соответственно, наших трех файлов: ca.pem, cert.pem, key.pem. 

Теперь то же самое делаем для stage машины: 

`docker-machine config stage`

Заполняем соответственно переменные `STAGE_DOCKER_HOST_CA_FILE`, `STAGE_DOCKER_HOST_CERT_FILE`, `STAGE_DOCKER_HOST_KEY_FILE`, также нам понадобится IP адрес машины: 

`docker-machine ip stage`

Его значение заносим в переменную `STAGE_DOCKER_HOST_IP` и, наконец, делаем все то же самое для prod машины:

`docker-machine config prod`

Заполняем соответственно переменные `PROD_DOCKER_HOST_CA_FILE`, `PROD_DOCKER_HOST_CERT_FILE`, `PROD_DOCKER_HOST_KEY_FILE`,
получаем IP адрес машины: 

`docker-machine ip prod`

его значение заносим в переменную `PROD_DOCKER_HOST_IP`

После этого проводим регистрацию раннера с помощью команды: 
`./gitlab-ci/set_up_runner.sh up gitlab-runner http://<IP_prod> A1b2C3d4E5f6G7h8I9j0`

В клоне нашего рабочего репозитория создаем какой-нибудь новый branch, например, testbranch, потом добавляем в репозиторий remote на наш Gitlab и пушим в Gitlab:
`git checkout -b testbranch `
`git remote add gitlab` `http://<dockerhost_external_IP>/<your_group>/<your_project>.git 
git push gitlab testbranch`

Проверяем в Gitlab состояние запустившегося pipeline в Project, который мы создали, в CI / CD -> Pipelines.
Проверяем также в нашем канале Slack, что туда приходят оповещения от Gitlab, затем заходим по адресу нашего environment http://<docker-host_external_IP>:8000 и убеждаемся, что собранное и задеплоенное приложение работает корректно.
Если добавить какой-нибудь тэг, то можно будет по кнопке задеплоить приложение на окружения stage и prod:

`git tag 1.2.3 git push gitlab testbranch --tags`

Опускаем все:

`make alldown`

При этом скрипт:
Гасит приложения на всех стендах: 

`make standsdown`
(или постендно: `make downdev downstage downprod`) 

Удаляет все машины GCP: 

`make envdown`

&copy;Dreamteam 
