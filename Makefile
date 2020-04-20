ENVIRONMENT := dev stage prod
APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager grafana rabbitmq
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS_LOCAL := config up down
COMPOSE_COMMANDS_LOCAL_MON := configmon upmon downmon
COMPOSE_COMMANDS_LOCAL_MOND := configmond upmond downmond
COMPOSE_COMMANDS_LOCAL_GIT := configgit upgit downgit
COMPOSE_COMMANDS_DEV := configdev updev downdev
COMPOSE_COMMANDS_STAGE := configstage upstage downstage
COMPOSE_COMMANDS_PROD := configprod upprod downprod


# Путь до .env в переменну, если его нет, используем .env.example
ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')
# Получаем логин от докер хаба, он же имя проекта для сборки образов
PROJECTNAME := $(shell grep -Po "(?<=PROJECTNAME=)[a-z]+" $(ENV_FILE))
# Получаем имя проекта в GCP
GPROJECT := $(shell grep -Po "(?<=GPROJECT=).+" $(ENV_FILE))


allup: envup prepare build push standsup

# Создаем все GCP машины
envup: $(ENVIRONMENT)

dev:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-2 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port 3000/tcp --google-open-port 9090/tcp --google-open-port 9090/tcp --google-open-port 80/tcp --google-open-port 8000/tcp --google-open-port 8080/tcp --google-open-port 15692/tcp $@

stage:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port 9100/tcp --google-open-port 9216/tcp --google-open-port 9115/tcp --google-open-port 8080/tcp --google-open-port 8001/tcp --google-open-port 8000/tcp --google-open-port 15692/tcp --google-open-port 15672/tcp $@

prod:
	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 --google-project $(GPROJECT) --google-zone europe-north1-b \
	--google-open-port 9100/tcp --google-open-port 9216/tcp --google-open-port 9115/tcp --google-open-port 8080/tcp --google-open-port 8001/tcp --google-open-port 8000/tcp --google-open-port 15692/tcp --google-open-port 15672/tcp $@


# Подготавливаем конфиг prometheus перед сборкой образа, заменяем адреса dev и prod окружений на ip полученные через docker-machine
prepare:
	@mv ./monitoring/prometheus/prometheus.yml ./monitoring/prometheus/prometheus.yml.save
	@cp ./monitoring/prometheus/prometheus.yml.exemple ./monitoring/prometheus/prometheus.yml
	@sed -i 's/!STAGE.*:/$(shell docker-machine ip stage):/g' ./monitoring/prometheus/prometheus.yml
	@sed -i 's/!PROD.*:/$(shell docker-machine ip prod):/g' ./monitoring/prometheus/prometheus.yml
	@echo 'Конфиги подготовлены'



# Собираем образы локально
build: $(APP_IMAGES) $(MON_IMAGES)

$(APP_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./apps/$@

$(MON_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./monitoring/$@

# Востанавливаем конфиг prometheus на исходный для локального деплоя
	cp ./monitoring/prometheus/prometheus.yml.save ./monitoring/prometheus/prometheus.yml


push:
ifneq '$(strip $(DOCKER_HUB_PASSWORD))' ''
	@docker login -u $(PROJECTNAME) -p $(DOCKER_HUB_PASSWORD)
	$(foreach i,$(APP_IMAGES) $(MON_IMAGES),docker push $(PROJECTNAME)/$(i);)
else
	@echo 'Variable DOCKER_HUB_PASSWORD is not defined, cannot push images'
endif

	rm ./monitoring/prometheus/prometheus.yml.save


# Поднимаем локально весь стек разом
localup: up upmon upmond upgit

# Поднимаем стек локально
$(COMPOSE_COMMANDS_LOCAL):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml $(subst up,up -d,$@)
$(COMPOSE_COMMANDS_LOCAL_MON):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring.yml $(subst mon,,$(subst up,up -d,$@))
$(COMPOSE_COMMANDS_LOCAL_MOND):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring-dev.yml $(subst mond,,$(subst up,up -d,$@))
$(COMPOSE_COMMANDS_LOCAL_GIT):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-gitlab.yml $(subst git,,$(subst up,up -d,$@))


# Поднимаем стек на всех стендах разом
standsup: updev upstage upprod

# Поднимаем стек на dev
$(COMPOSE_COMMANDS_DEV):
	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-gitlab.yml -f ./docker/docker-compose-monitoring-dev.yml $(subst dev,,$(subst up,up -d,$@))

# Поднимаем стек на stage
$(COMPOSE_COMMANDS_STAGE):
	eval $$(docker-machine env stage) && echo 'Контекст переключен на stage' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml $(subst stage,,$(subst up,up -d,$@))

# Поднимаем стек на prod
$(COMPOSE_COMMANDS_PROD):
	eval $$(docker-machine env prod) && echo 'Контекст переключен на prod' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml $(subst prod,,$(subst up,up -d,$@))



# Поднимаем стек на всех стендах разом
standsdown:

	eval $$(docker-machine env dev) && echo 'Контекст переключен на dev' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml -f ./docker/docker-compose-gitlab.yml -f ./docker/docker-compose-monitoring-dev.yml down
	eval $$(docker-machine env stage) && echo 'Контекст переключен на stage' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml down
	eval $$(docker-machine env prod) && echo 'Контекст переключен на prod' && docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml -f ./docker/docker-compose-monitoring.yml down


# Удаляем все машины GCP
envdown:

	docker-machine rm -y $(ENVIRONMENT)


$(ENVIRONMENT) $(APP_IMAGES) $(MON_IMAGES) $(DOCKER_COMMANDS) $(COMPOSE_COMMANDS_DEV) $(COMPOSE_COMMANDS_STAGE) $(COMPOSE_COMMANDS_PROD) $(COMPOSE_COMMANDS_LOCAL) $(COMPOSE_COMMANDS_LOCAL_MON) $(COMPOSE_COMMANDS_LOCAL_MOND) $(COMPOSE_COMMANDS_LOCAL_GIT) : FORCE

FORCE:
