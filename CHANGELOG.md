### e811d11 (improvements2) Add runner and service image
Причесан Makefile<br/>
Добавлено поднятие и удаление gitlab-runner<br/>
Добавлена сборка сервис образа с установленным docker-compose<br/>
Этот образ теперь используется в gitlab pipeline при деплое, что позволило значительно ускорить деплой

### c334997 - 0089a34 Readme
Причесывание ридми

### d765c7d Make
Очередное причесывание Makefile и компоуз файлов<br/>
Все порты в копоузах параметризированы и вынесены в env, параметризированы некоторые вещи в Makefile<br/>
Поправлен дашборд графаны

### c6cd772 - 4c09ac2 Minor bug fixes
Множество багофиксов по результатам тестирования

### f1344dc (improvements) Add deploy to stage and prod
В pipeline добавлена возможность деплоя по кнопке тэговых коммитов на stage и prod окружения

### 1c987b4 Make + bug fix
Обновление и расширение возможностей Makefile<br/>
Правка косяков, допиливание логирования и мониторинга<br/>
Тестовые прогоны на все 3 среды<br/>
Тестовый прогон из другого окружения через гитлаб

### 1c0786d (logging) Add logging to EFK
Добавлен сбор логов приложений в стек EFK

### 2053a16 Make
Обновлен Makefile<br/>
Теперь все поднимается и опускается с одной кнопки<br/>
Компоузы мониторинга разделены на 2 части, компоуз для дева (прометей, графана и аллерт) и компоуз с экспортерами, которые ставятся на stage и prod<br/>
Поправлены дашборды графаны

### 1cb4015 Monitoring and Alerting
Настроен мониторинг и алертинг<br/>
Конфиг прометея содержит по 3 экземпляра каждого экспортера, по одному на каждый из трех стендов - dev (service), stage и prod<br/>
Метрики всех компоненты попадают в прометей<br/>
Все dev экспортеры будет работать по алиасам контейнеров, т.к. находятся на той же сервисной (dev) машине<br/>
Остальные экспотеры будут использованы по внешним ip/портам докер машин<br/>
Настроен алертинг на 2 метрики - падение контейнера и превышение порога памяти в 500Мб<br/>
Алертинг приходит на почту и в слак канал<br/>
Настроены дашборды - дашборд общий с метриками нод и докера, дашборд приложений<br/>
Все дашборды имеют переключатель между стендами<br/>
Весь мониторинг поднимается автоматом без необходимости ручного конфигурирования

### 6bd0622 (gitlab-ci) GitLab CI
Добавлено развертывание GitLab CI<br/>
Написан .gitlab-ci.yml с запуском тестов, сборкой и пушем образов, деплоем на dev бранчевых веток

### 47f3aee (dev_app) Some improvements
Улучшены Dockerfile компонентов приложений, причесан компоуз

### 8434fd9 UI service
Создан Dockerfile для ui, сделан работающий Makefile, берущий имя проекта из .env,<br/>
допилен скрипт поднятия докер машины с открытием порта 8000 для приложения и порта для веб морды rabbit<br/>
Компоуз теперь поднимает полностью рабочий стек

### aeca023 Robot service
Создан Dockerfile для робота, создан образ, создан компоуз и с помощью него запущено приложение

### 3cd9cab Start project
Старт проекта, клонирование приложений, создание каталогов, прекоммита
