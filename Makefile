ENVIRONMENT := dev stage prod
APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager grafana rabbitmq
LOG_IMAGES := fluentd
SERVICE_IMAGES := docker-compose
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS_LOCAL := config up down
COMPOSE_COMMANDS_LOCAL_MON := configmon upmon downmon
COMPOSE_COMMANDS_LOCAL_MOND := configmond upmond downmond
COMPOSE_COMMANDS_LOCAL_GIT := configgit upgit downgit
COMPOSE_COMMANDS_DEV := configdev updev downdev
COMPOSE_COMMANDS_STAGE := configstage upstage downstage
COMPOSE_COMMANDS_PROD := configprod upprod downprod
COMPOSE_COMMANDS_LOCAL_LOG := configlog uplog downlog

# Путь до файла .env в переменную, если его нет, используем .env.example
ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')

# Порты, которые открываются у машин GCP
RABBIT_UI_PUBLISHED_PORT = $(shell grep -Po "(?<=^RABBIT_UI_PUBLISHED_PORT=).+" $(ENV_FILE))
RABBIT_METRICS_PUBLISHED_PORT = $(shell grep -Po "(?<=^RABBIT_METRICS_PUBLISHED_PORT=).+" $(ENV_FILE))
ROBOT_PUBLISHED_PORT = $(shell grep -Po "(?<=^ROBOT_PUBLISHED_PORT=).+" $(ENV_FILE))
UI_PUBLISHED_PORT = $(shell grep -Po "(?<=^UI_PUBLISHED_PORT=).+" $(ENV_FILE))
PROMETHEUS_PUBLISHED_PORT = $(shell grep -Po "(?<=^PROMETHEUS_PUBLISHED_PORT=).+" $(ENV_FILE))
GRAFANA_PUBLISHED_PORT = $(shell grep -Po "(?<=^GRAFANA_PUBLISHED_PORT=).+" $(ENV_FILE))
ALERTMANAGER_PUBLISHED_PORT = $(shell grep -Po "(?<=^ALERTMANAGER_PUBLISHED_PORT=).+" $(ENV_FILE))
CADVISOR_PUBLISHED_PORT = $(shell grep -Po "(?<=^CADVISOR_PUBLISHED_PORT=).+" $(ENV_FILE))
KIBANA_PUBLISHED_PORT = $(shell grep -Po "(?<=^KIBANA_PUBLISHED_PORT=).+" $(ENV_FILE))
GITLAB_CI_PUBLISHED_PORT = $(shell grep -Po "(?<=^GITLAB_CI_PUBLISHED_PORT=).+" $(ENV_FILE))
MONGO_EXPORTER_PUBLISHED_PORT = $(shell grep -Po "(?<=^MONGO_EXPORTER_PUBLISHED_PORT=).+" $(ENV_FILE))
BLACKBOX_PUBLISHED_PORT = $(shell grep -Po "(?<=^BLACKBOX_PUBLISHED_PORT=).+" $(ENV_FILE))
NODE_EXPORTER_PUBLISHED_PORT = $(shell grep -Po "(?<=^NODE_EXPORTER_PUBLISHED_PORT=).+" $(ENV_FILE))

# Получаем логин от докер хаба, он же имя проекта для сборки образов
PROJECTNAME = $(shell grep -Po "(?<=^PROJECTNAME=).+" $(ENV_FILE))
# Получаем имя проекта в GCP
GPROJECT = $(shell grep -Po "(?<=^GPROJECT=).+" $(ENV_FILE))
# URL гитлаба
GITLAB_CI_URL = $(shell grep -Po "(?<=^GITLAB_CI_URL=).+" $(ENV_FILE))
# Токен гитлаба
GITLAB_CI_TOKEN = $(shell grep -Po "(?<=^GITLAB_CI_TOKEN=).+" $(ENV_FILE))
# Пароль от докер хаба
DOCKER_HUB_PASSWORD = $(shell grep -Po "(?<=^DOCKER_HUB_PASSWORD=).+" $(ENV_FILE))


# Поднимаем все разом
upall: upenv prepare build push upstands

# Разом гасим весь деплой и удаляем GCP машины
downall: downstands downenv


# Создаем все GCP машины
upenv: $(ENVIRONMENT)

# Удаляем все машины GCP
downenv:
	docker-machine rm -y $(ENVIRONMENT)

dev:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-2 --google-project $(GPROJECT) --google-zone europe-north1-b --google-disk-size 50 \
	--google-open-port $(GRAFANA_PUBLISHED_PORT)/tcp --google-open-port $(PROMETHEUS_PUBLISHED_PORT)/tcp --google-open-port $(GITLAB_CI_PUBLISHED_PORT)/tcp \
	--google-open-port $(UI_PUBLISHED_PORT)/tcp --google-open-port $(CADVISOR_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_UI_PUBLISHED_PORT)/tcp \
	--google-open-port $(KIBANA_PUBLISHED_PORT)/tcp --google-open-port $(ALERTMANAGER_PUBLISHED_PORT)/tcp $@

stage prod:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 --google-project $(GPROJECT) --google-zone europe-north1-b --google-disk-size 20 \
	--google-open-port $(NODE_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(MONGO_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(BLACKBOX_PUBLISHED_PORT)/tcp \
	--google-open-port $(CADVISOR_PUBLISHED_PORT)/tcp --google-open-port $(ROBOT_PUBLISHED_PORT)/tcp --google-open-port $(UI_PUBLISHED_PORT)/tcp \
	--google-open-port $(RABBIT_METRICS_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_UI_PUBLISHED_PORT)/tcp --google-open-port $(KIBANA_PUBLISHED_PORT)/tcp $@


# Подготавливаем конфиг prometheus перед сборкой образа, заменяем адреса stage и prod окружений на IP, полученные через docker-machine
prepare:
	cp -f ./monitoring/prometheus/prometheus.yml.template ./monitoring/prometheus/prometheus.yml && \
	sed -i 's/!STAGE.*:/$(shell docker-machine ip stage):/g' ./monitoring/prometheus/prometheus.yml && \
	sed -i 's/!PROD.*:/$(shell docker-machine ip prod):/g' ./monitoring/prometheus/prometheus.yml && \
	sed -i 's/GITLAB_CI_URL.*/GITLAB_CI_URL=http:\/\/$(shell docker-machine ip dev)/g' ./docker/.env
	@echo 'Конфиги подготовлены'


# Собираем образы в текущем docker окружении
build: $(APP_IMAGES) $(MON_IMAGES) $(LOG_IMAGES) $(SERVICE_IMAGES)

$(APP_IMAGES):
	cd ./apps/$@; sh docker_build.sh $(PROJECTNAME); cd -

$(MON_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./monitoring/$@

$(LOG_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./logging/$@

$(SERVICE_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./gitlab-ci/$@

push:
ifneq '$(strip $(DOCKER_HUB_PASSWORD))' ''
	@docker login -u $(PROJECTNAME) -p $(DOCKER_HUB_PASSWORD)
	$(foreach i,$(APP_IMAGES) $(MON_IMAGES) $(LOG_IMAGES) $(SERVICE_IMAGES),docker push $(PROJECTNAME)/$(i);)
else
	@echo 'Variable DOCKER_HUB_PASSWORD is not defined, cannot push images'
endif


# Поднимаем на текущем docker окружении весь стек разом
uplocal: up upmon upmond upgit uplog

# Гасим на текущем docker окружении весь стек разом
downlocal: down downmon downmond downgit downlog

# Поднимаем / гасим стек на текущем docker окружении
$(COMPOSE_COMMANDS_LOCAL):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml $(subst up,up -d,$@)

$(COMPOSE_COMMANDS_LOCAL_MON):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring.yml $(subst mon,,$(subst up,up -d,$@))

$(COMPOSE_COMMANDS_LOCAL_MOND):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring-dev.yml $(subst mond,,$(subst up,up -d,$@))

$(COMPOSE_COMMANDS_LOCAL_GIT):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-gitlab.yml $(subst git,,$(subst up,up -d,$@))

$(COMPOSE_COMMANDS_LOCAL_LOG):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-logging.yml $(subst log,,$(subst up,up -d,$@))


# Поднимаем стек на всех стендах разом
upstands: updev upstage upprod

# Гасим стек на всех стендах разом
downstands: downdev downstage downprod

# Поднимаем / гасим стек на dev
$(COMPOSE_COMMANDS_DEV):
	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-gitlab.yml \
	-f ./docker/docker-compose-monitoring-dev.yml -f ./docker/docker-compose-logging.yml $(subst dev,,$(subst up,up -d,$@))

# Поднимаем / гасим стек на stage
$(COMPOSE_COMMANDS_STAGE):
	eval $$(docker-machine env stage) && echo 'Контекст переключен на stage' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml $(subst stage,,$(subst up,up -d,$@))

# Поднимаем / гасим стек на prod
$(COMPOSE_COMMANDS_PROD):
	eval $$(docker-machine env prod) && echo 'Контекст переключен на prod' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml $(subst prod,,$(subst up,up -d,$@))


# Получить информацияю для настройки гитлаба для подключения к docker engine стендов
info:
	@echo '' && $(foreach i,$(ENVIRONMENT),docker-machine env $(i) && echo '';)


# Поднять runner на текущем docker окружении и зарегистрировать runner в гитлаб
uprunnerlocal:
	./gitlab-ci/set_up_runner.sh up gitlab-runner $(GITLAB_CI_URL) $(GITLAB_CI_TOKEN)

# Разрегистрировать runner в гитлаб и удалить runner на текущем docker окружении
downrunnerlocal:
	./gitlab-ci/set_up_runner.sh down gitlab-runner

# Поднять runner на dev и зарегистрировать runner в гитлаб
uprunner:
	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && ./gitlab-ci/set_up_runner.sh up gitlab-runner $(GITLAB_CI_URL) $(GITLAB_CI_TOKEN)


	docker-machine rm -f -y $(ENVIRONMENT)
# Разрегистрировать runner на dev и удалить runner из гитлаб
downrunner:
	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && ./gitlab-ci/set_up_runner.sh down gitlab-runner


$(ENVIRONMENT) $(APP_IMAGES) $(MON_IMAGES) $(LOG_IMAGES) $(SERVICE_IMAGES) $(DOCKER_COMMANDS): FORCE
$(COMPOSE_COMMANDS_DEV) $(COMPOSE_COMMANDS_STAGE) $(COMPOSE_COMMANDS_PROD): FORCE
$(COMPOSE_COMMANDS_LOCAL) $(COMPOSE_COMMANDS_LOCAL_MON) $(COMPOSE_COMMANDS_LOCAL_MOND) $(COMPOSE_COMMANDS_LOCAL_GIT) $(COMPOSE_COMMANDS_LOCAL_LOG): FORCE
downenv prepare push info uprunnerlocal downrunnerlocal uprunner downrunner: FORCE

FORCE:
