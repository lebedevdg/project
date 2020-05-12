## OTUS Project

### Содержание
+ [Участники проекта](#1)
+ [О чем этот проект](#2)
+ [Roadmap проекта](#3)
+ [Environments](#4)
+ [Порты на stage и prod](#5)
+ [Порты на dev](#6)
+ [Описание](#7)
+ [Подготовка к развертыванию](#8)
+ [Порядок сборки](#9)
+ [Настройка пайплайнов в GitLab](#10)
+ [Список функций Makefile](#11)

### Участники проекта
<a name="1"></a>
- [Сергей Толстинский ](https://github.com/sergetol "Сергей Толстинский ")
- [Денис Лебедев](https://github.com/lebedevdg "Денис Лебедев") 
- [Алексей Николаев](https://github.com/nightdiverru "Алексей Николаев")

### О чем этот проект
<a name="2"></a>
Реализован деплой бота [Robot](https://github.com/express42/search_engine_crawler "Robot") , [UI](https://github.com/express42/search_engine_ui "UI") для него и вспомогательных приложений (RabbitMQ, mongodb etc), а также систем мониторинга, алертинга и логирования в облако GCP. Сборка и тестирование в Gitlab pipelines


### Roadmap проекта
<a name="3"></a>
- [x] Используются ресурсы Google Coud Platform
- [x] Создание репозитория, добавление участников, инициализация коммита, создание Readme, changelog, precommit и прочее
- [x] Клонирование репозитория с кодом приложения Robot
- [x] Подготовка докер файлов и тестовые сборки
- [x] Оптимизация докер файлов
- [x] Тестовый деплой инфраструктуры на одной машине с сопряжением компонентов.
- [x] Создание Makefile для сборки и деплоя приложений и окружения
- [x] Настройка мониторинга
- [x] Настройка аллертинга и ChatOps
- [x] Внесение изменений в Makefile для сборки и поднятия мониторинга
- [x] Внедрение GitLab
- [x] Внесение изменений в Makefile для сборки и поднятия гитлаба
- [x] Цели билд-процесса управляются "по кнопке" в GitLab
- [x] Внесение изменений в Makefile для создания машин в облаке
- [x] Разработка инфраструктуры логирования
- [x] Внесение изменений в Makefile для сборки и деплоя логирования
- [x] Различные улучшательства и оптимизации
- [x] Разработка документации
- [x] Описание, ссылки на установку необходимого ПО и документация к проекту находится в данном README
- [ ] Исправление замечаний по работе, прочие оптимизации


### Environments
<a name="4"></a>
dev, stage и прод

### Порты на stage и prod
<a name="5"></a>
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
<a name="6"></a>
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
<a name="7"></a>
Данный проект расчитан на запуск и работу в окружении GCP - Google Cloud Platform (https://cloud.google.com/). Так же для запуска проекта на машине, с которой будет осуществляться развертывание всех окружений(управляющая машина), должны быть установлены docker, docker-compose, docker-machine.

Т.к. сборка образов это достаточно ресурсозатратный процесс и к тому же требующий быстрого интернета, весь процесс рекомендуется производить в контекте ранее созданной машины GCP уровнем не ниже n1-standard-1 

Т.е. создаем машину n1-standard-1, например так:

`docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-project $(ID ПРОЕКТА В GCP) --google-zone europe-north1-a docker-host`

После чего переключить на нее контекст

`eval $(docker-machine env docker-host)`

[![Схема развертывания](https://i.ibb.co/jg2hQ9n/Deploy-Diagram.png "Схема развертывания")](https://i.ibb.co/jg2hQ9n/Deploy-Diagram.png "Схема развертывания")

### Подготовка к развертыванию
<a name="8"></a>

##### Документация по установке ПО
Google Cloud SDK
https://cloud.google.com/sdk/docs/

Docker
https://docs.docker.com/engine/install/

Docker-compose:
https://docs.docker.com/compose/install/

Docker-machine
https://docs.docker.com/machine/install-machine/

На подготовленную (управляющую) Linux машину клонируем репозиторий:

`git clone https://github.com/lebedevdg/project.git`

В каталоге ./docker копируем файл .env.example в .env:

`cp .env.example .env`

Заполняем переменные внутри .env файла согласно комментариям внутри файла Дополнительно экспортируем в окружение системы переменную `DOCKER_HUB_PASSWORD`, она понадобится для автоматической выгрузки образов в докер хаб.

`export DOCKER_HUB_PASSWORD=пароль `

Поправить веб хук и имя канала(секция slack_configs:) для отправки сообщений в Slack: monitoring/alertmanager/config.yml


### Порядок сборки
<a name="9"></a>
Поднимаем всё в GCP

`make upall`

Описание команды см в: [Список функций Makefile](#11)

После чего мы имеем 3 стенда в GCP: 
dev (служебная машина с гитлабом, прометеем, графаной, аллертменеджером и т.д), stage и prod стенды, содержащие только экспортеры и уже задеплоенные приложения и ожидающие возможного деплоя со стороны гитлаба

Сразу после применения make стенды готовы и работают, можно посмотреть как все устроено, зайдя в графану или кибану, но для полноценной работы CI/CD требуется минимальная ручная донастройка GitLab.


### Настройка пайплайнов в GitLab
<a name="10"></a>
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
`make uprunner`

В клоне нашего рабочего репозитория создаем какой-нибудь новый branch, например, testbranch, потом добавляем в репозиторий remote на наш Gitlab и пушим в Gitlab:
`git checkout -b testbranch `  
`git remote add gitlab http://<dockerhost_external_IP>/<your_group>/<your_project>.git   `
`git push gitlab testbranch`  

Проверяем в Gitlab состояние запустившегося pipeline в Project, который мы создали, в CI / CD -> Pipelines.
Проверяем также в нашем канале Slack, что туда приходят оповещения от Gitlab, затем заходим по адресу нашего environment http://<docker-host_external_IP>:8000 и убеждаемся, что собранное и задеплоенное приложение работает корректно.
Если добавить какой-нибудь тэг, то можно будет по кнопке задеплоить приложение на окружения stage и prod:

`git tag 1.2.3`  
`git push gitlab testbranch --tags`

Опускаем все:

`make downall`

Описание команды см в: [Список функций Makefile](#11)

### Список функций Makefile
<a name="11"></a>
#### Поднять все сразу  

`make upall`  

 команда включает в себя:
 +  создать GCP машины  
   ` make upenv`
   
     включает в себя:
     *  создать через docker-machine GCP машину dev (n1-standard-2, 50Gb disk)  
 `make dev`
     *  создать через docker-machine GCP машину dev (n1-standard-1, 20Gb disk)  
 `make stage`
     *  cоздать через docker-machine GCP машину dev (n1-standard-1, 20Gb disk)  
 `make prod`

+  подготовить конфиг prometheus перед сборкой образа, заменить IP адреса stage и prod окружений  
`make prepare`

+  собрать все образы в текущем docker окружении  
 `make build`
 
    включает в себя:
  *  собрать образ ui  
 `make ui`
  *  собрать образ robot  
 `make robot`
  *  собрать образ prometheus  
 `make prometheus`
  *  собрать образ mongodb-exporter  
`make mongodb-exporter`
  *  собрать образ alertmanager  
`make alertmanager`
 *  собрать образ grafana  
`make grafana`
 *  собрать образ rabbitmq  
 `make rabbitmq`
  *  собрать образ fluentd  
`make fluentd`
 *  собрать образ на основе docker с установленным docker-compose (используется в гитлаб)  
`make docker-compose`

+  запушить все собранные образы в докер хаб  
 `make push`
 
+  поднять стек на всех стендах разом  
` make upstands`

    включает в себя:
   *  на dev поднять стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, prometheus, grafana, alertmanager, gitlab, elasticsearch, kibana  
`make updev`
   *  на stage поднять стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, elasticsearch, kibana  
` make upstage`
   *  на prod поднять стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, elasticsearch, kibana  
   `make upprod`

#### Погасить весь деплой и удалить GCP машины  

`make downall`

 включает в себя:
 
+   погасить стек на всех стендах разом  
  `make downstands`
  
    включает в себя:
   *  на dev погасить стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, prometheus, grafana, alertmanager, gitlab, elasticsearch, kibana  
   `     make downdev`
  *  на stage погасить стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, elasticsearch, kibana  
   `make downstage`
  *  на prod погасить стек с mongo, rabbit, robot, ui, fluentd, node-exporter, mongodb-exporter, blackbox-exporter, cadvisor, elasticsearch, kibana  
   `make downprod`
 *  удалить GCP машины dev, stage и prod  
   ` make downenv`

#### Получить информацию для настройки гитлаба для подключения к docker engine стендов  

`make info`

#### Поднять runner на dev и зарегистрировать runner в гитлаб  

`make uprunner`

#### Разрегистрировать runner на dev и удалить runner из гитлаб  

`make downrunner`


#### Поднять на текущем docker окружении весь стек разом  

`make uplocal`

включает в себя:

+  поднять стек с mongo, rabbit, robot, ui, fluentd  
    `make up`
+  поднять стек с node-exporter, mongodb-exporter, blackbox-exporter, cadvisor  
    `make upmon`
+  поднять стек с prometheus, grafana, alertmanager  
    `make upmond`
+  поднять стек с gitlab  
    `make upgit`
+  поднять стек с elasticsearch, kibana  
    `make uplog`

#### Погасить на текущем docker окружении весь стек разом  

`make downlocal`

включает в себя:

+  погасить стек с mongo, rabbit, robot, ui, fluentd  
 `   make down`
+  погасить стек с node-exporter, mongodb-exporter, blackbox-exporter, cadvisor  
   ` make downmon`
+  погасить стек с prometheus, grafana, alertmanager  
   ` make downmond`
+  погасить стек с gitlab  
`    make downgit`
+  погасить стек с elasticsearch, kibana  
`    make downlog`

#### Поднять runner на текущем docker окружении и зарегистрировать runner в гитлаб  

`make uprunnerlocal`

#### Разрегистрировать runner в гитлаб и удалить runner на текущем docker окружении  

`make downrunnerlocal`


&copy;Dreamteam 
