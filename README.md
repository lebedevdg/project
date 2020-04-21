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

Данный проект расчитан на запуск и работу в окружение GCP - Google Cloud Platform (https://cloud.google.com/).
Так же, для запуска проекта используется docker-machine. Вы уже должны быть зарегистрированны в GCP и иметь установленную и подключенную к GCP docker-machine.


Т.к. сборка образова, это достаточно ресурсозатратный процесс, к тому же требующий быстроего интерената
весь процесс рекомендуется производить в контекте ранее созданной машины GCP уровнем не ниже n1-standard-1.
Т.е. создаем машину n1-standard-1, например так:

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-2 --google-project $(ИМЯ ПРОКТА В GCP) --google-zone europe-north1-b docker-host

После чего переключить на нее конетекст - eval $(docker-machine env docker-host)

Подготовка:

1. На подготовленную Linux машину клонируем репозиторий -git clone git@github.com:lebedevdg/project.git
2. В каталоге ./docker копируем файл .env.example в .env - cp .env.example .env
3. Заполняем переменные внутри .env файла согласно комментариям внутри файла
4. Дополнительно экспортируем в окружение системы переменную DOCKER_HUB_PASSWORD, она понадобится для автоматической выгрузки образов в докер хаб
export DOCKER_HUB_PASSWORD=пароль
5.

Порядок сборки:

Поднимаем все - make allup

Для достижения цели, деается следующее:
1. Создаем окружения - make envup
Получить информацию по окружениям можно - make info

2. Подготавливаем конфиги заменяя в шаблоны на ip стендов - make prepare
3. Собираем образы - make build
4. Пушим образы в докер хаб - make push
5. Поднимаем сервисы на трех окружениях: dev, stage и prod - make standsup (или постендно - make updev upstage upprod)

После чего, мы имеем 3 стенда в GCP - dev (служебная машина с гитлабом, прометеем, графаной, аллертменеджером и т.д), stage и prod стенды содержащие только экспортеры и уже продеплоенные приложения
ожидающие деплоя со стороны гитлаба.

Сразу после применения make стенды готовы и работают, можно посмотреть как все устроено, зайдя в графану или кибану. Но для полноценной работы CI/CD требуется минимальная ручная донастройка.

Гитлаб требует ручной донастройки, необходимо заполнить переменные для подключения к docker engene ip адрес и пути к сертификатм по стендам
можно посмотреть с помощью комманды - make info









Опаскаем все - make alldown

Для достижения цели делается следюущее:
1. Гасим приложения на всех стендах - make standsdown (или постендно - make downdev downstage downprod)
2. Удаляем все машины GCP - make envdown
