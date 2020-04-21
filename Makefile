ENVIRONMENT := dev stage prod
APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager grafana rabbitmq
LOG_IMAGES := fluentd
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS_LOCAL := config up down
COMPOSE_COMMANDS_LOCAL_MON := configmon upmon downmon
COMPOSE_COMMANDS_LOCAL_MOND := configmond upmond downmond
COMPOSE_COMMANDS_LOCAL_GIT := configgit upgit downgit
COMPOSE_COMMANDS_DEV := configdev updev downdev
COMPOSE_COMMANDS_STAGE := configstage upstage downstage
COMPOSE_COMMANDS_PROD := configprod upprod downprod
COMPOSE_COMMANDS_LOCAL_LOG := conflog uplog downlog


# Порты который открваются у машин GCP
RABBIT_UI_PUBLISHED_PORT := $(shell grep -Po "(?<=RABBIT_UI_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
RABBIT_METRICS_PUBLISHED_PORT := $(shell grep -Po "(?<=RABBIT_METRICS_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
ROBOT_PUBLISHED_PORT := $(shell grep -Po "(?<=ROBOT_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
UI_PUBLISHED_PORT := $(shell grep -Po "(?<=UI_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
PROMETHEUS_PUBLISHED_PORT := $(shell grep -Po "(?<=PROMETHEUS_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
GRAFANA_PUBLISHED_PORT := $(shell grep -Po "(?<=GRAFANA_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
ALERTMANAGER_PUBLISHED_PORT := $(shell grep -Po "(?<=ALERTMANAGER_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
CADVISOR_PUBLISHED_PORT := $(shell grep -Po "(?<=CADVISOR_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
KIBANA_PUBLISHED_PORT := $(shell grep -Po "(?<=KIBANA_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
GITLAB_CI_PUBLISHED_PORT := $(shell grep -Po "(?<=GITLAB_CI_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
MONGO_EXPORTER_PUBLISHED_PORT := $(shell grep -Po "(?<=MONGO_EXPORTER_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
BLACKBOX_PUBLISHED_PORT := $(shell grep -Po "(?<=BLACKBOX_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))
NODE_EXPORTER_PUBLISHED_PORT :=$ (shell grep -Po "(?<=NODE_EXPORTER_PUBLISHED_PORT=)[a-z]+" $(ENV_FILE))

# Путь до .env в переменну, если его нет, используем .env.example
ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')
# Получаем логин от докер хаба, он же имя проекта для сборки образов
PROJECTNAME := $(shell grep -Po "(?<=PROJECTNAME=)[a-z]+" $(ENV_FILE))
# Получаем имя проекта в GCP
GPROJECT := $(shell grep -Po "(?<=GPROJECT=).+" $(ENV_FILE))
# ip гитлаба
GITLAB_CI_URL = $(shell grep -Po "(?<=GITLAB_CI_URL=).+" $(ENV_FILE))
# Токен гитлаба
GITLAB_CI_TOKEN := $(shell grep -Po "(?<=GITLAB_CI_TOKEN=).+" $(ENV_FILE))
# Пароль от докер хаба
DOCKER_HUB_PASSWORD := $(shell grep -Po "(?<=DOCKER_HUB_PASSWORD=)[a-z]+" $(ENV_FILE))

# Поднимаем все разом
allup: envup prepare build push standsup

# Создаем все GCP машины
envup: $(ENVIRONMENT)

dev:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-2 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port $(GRAFANA_PUBLISHED_PORT)/tcp --google-open-port $(PROMETHEUS_PUBLISHED_PORT)/tcp --google-open-port $(GITLAB_CI_PUBLISHED_PORT)/tcp --google-open-port $(UI_PUBLISHED_PORT)/tcp --google-open-port $(CADVISOR_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_METRICS_PUBLISHED_PORT)/tcp --google-open-port $(KIBANA_PUBLISHED_PORT)/tcp --google-open-port $(ALERTMANAGER_PUBLISHED_PORT)/tcp $@

stage:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port $(NODE_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(MONGO_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(BLACKBOX_PUBLISHED_PORT)/tcp --google-open-port $(CADVISOR_PUBLISHED_PORT)/tcp --google-open-port $(ROBOT_PUBLISHED_PORT)/tcp --google-open-port $(UI_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_METRICS_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_UI_PUBLISHED_PORT)/tcp --google-open-port $(KIBANA_PUBLISHED_PORT)/tcp $@

prod:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port $(NODE_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(MONGO_EXPORTER_PUBLISHED_PORT)/tcp --google-open-port $(BLACKBOX_PUBLISHED_PORT)/tcp --google-open-port $(CADVISOR_PUBLISHED_PORT)/tcp --google-open-port $(ROBOT_PUBLISHED_PORT)/tcp --google-open-port $(UI_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_METRICS_PUBLISHED_PORT)/tcp --google-open-port $(RABBIT_UI_PUBLISHED_PORT)/tcp --google-open-port $(KIBANA_PUBLISHED_PORT)/tcp $@


# Подготавливаем конфиг prometheus перед сборкой образа, заменяем адреса dev и prod окружений на ip полученные через docker-machine
prepare:
	cp ./monitoring/prometheus/prometheus.yml.template ./monitoring/prometheus/prometheus.yml && \
	sed -i 's/!STAGE.*:/$(shell docker-machine ip stage):/g' ./monitoring/prometheus/prometheus.yml && sed -i 's/!PROD.*:/$(shell docker-machine ip prod):/g' ./monitoring/prometheus/prometheus.yml
	sed -i 's/GITLAB_CI_URL.*/GITLAB_CI_URL=http:\/\/$(shell docker-machine ip dev)/g' ./docker/.env
	@echo 'Конфиги подготовлены'


# Собираем образы локально
build: $(APP_IMAGES) $(MON_IMAGES) $(LOG_IMAGES)

$(APP_IMAGES):
	cd ./apps/$@; sh docker_build.sh; cd -

$(MON_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./monitoring/$@

$(LOG_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./logging/$@


push:
ifneq '$(strip $(DOCKER_HUB_PASSWORD))' ''
	@docker login -u $(PROJECTNAME) -p $(DOCKER_HUB_PASSWORD)
	$(foreach i,$(APP_IMAGES) $(MON_IMAGES) $(LOG_IMAGES),docker push $(PROJECTNAME)/$(i);)
else
	@echo 'Variable DOCKER_HUB_PASSWORD is not defined, cannot push images'
endif


# Поднимаем локально весь стек разом
localup: up upmon upmond upgit uplog

# Поднимаем стек локально
$(COMPOSE_COMMANDS_LOCAL):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml $(subst up,up -d,$@)
$(COMPOSE_COMMANDS_LOCAL_MON):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring.yml $(subst mon,,$(subst up,up -d,$@))
$(COMPOSE_COMMANDS_LOCAL_MOND):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring-dev.yml $(subst mond,,$(subst up,up -d,$@))
$(COMPOSE_COMMANDS_LOCAL_GIT):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-gitlab.yml $(subst git,,$(subst up,up -d,$@)) #&& ./gitlab-ci/set_up_runner.sh $(subst git,,$@)
$(COMPOSE_COMMANDS_LOCAL_LOG):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-logging.yml $(subst log,,$(subst up,up -d,$@))

# Поднимаем стек на всех стендах разом
standsup: updev upstage upprod

# Поднимаем стек на dev
$(COMPOSE_COMMANDS_DEV):
	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-gitlab.yml -f ./docker/docker-compose-monitoring-dev.yml -f ./docker/docker-compose-logging.yml $(subst dev,,$(subst up,up -d,$@)) #&& \
#	./gitlab-ci/set_up_runner.sh $(subst dev,,$@)


# Поднимаем стек на stage
$(COMPOSE_COMMANDS_STAGE):
	eval $$(docker-machine env stage) && echo 'Контекст переключен на stage' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml $(subst stage,,$(subst up,up -d,$@))

# Поднимаем стек на prod
$(COMPOSE_COMMANDS_PROD):
	eval $$(docker-machine env prod) && echo 'Контекст переключен на prod' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml $(subst prod,,$(subst up,up -d,$@))

# Получить информацияю по стендам для настройки гитлаба и подключения к веб мордам
info:
	@echo '' && $(foreach i,$(ENVIRONMENT),docker-machine env $(i) && echo '';)


# Разом гасим весь деплой и удаляем GCP машины
alldown: standsdown envdown

# Поднимаем стек на всех стендах разом
standsdown:

	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-gitlab.yml -f ./docker/docker-compose-monitoring-dev.yml -f ./docker/docker-compose-logging.yml down
	eval $$(docker-machine env stage) && echo 'Контекст переключен на stage' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml down
	eval $$(docker-machine env prod) && echo 'Контекст переключен на prod' && docker-compose --env-file $(ENV_FILE) \
	-f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-logging.yml down
# Удаляем все машины GCP
envdown:

	docker-machine rm -y $(ENVIRONMENT)


$(ENVIRONMENT) $(APP_IMAGES) $(MON_IMAGES) $(DOCKER_COMMANDS) $(COMPOSE_COMMANDS_DEV) $(COMPOSE_COMMANDS_STAGE) $(COMPOSE_COMMANDS_PROD) $(COMPOSE_COMMANDS_LOCAL) $(COMPOSE_COMMANDS_LOCAL_MON) $(COMPOSE_COMMANDS_LOCAL_MOND) $(COMPOSE_COMMANDS_LOCAL_GIT) : FORCE

FORCE:
