APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager grafana rabbitmq
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS := config up down
COMPOSE_COMMANDS_MON := configmon upmon downmon

ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')

PROJECTNAME := $(shell grep -Po "(?<=PROJECTNAME=)[a-z]+" $(ENV_FILE))

ifeq '$(strip $(PROJECTNAME))' ''
  $(warning Variable PROJECTNAME is not defined, using value 'user')
  PROJECTNAME := user
endif

build: $(APP_IMAGES) $(MON_IMAGES)

$(APP_IMAGES):
	cd ./apps/$@; sh docker_build.sh; cd -

$(MON_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./monitoring/$@

push:
ifneq '$(strip $(DOCKER_HUB_PASSWORD))' ''
	@docker login -u $(PROJECTNAME) -p $(DOCKER_HUB_PASSWORD)
	$(foreach i,$(APP_IMAGES) $(MON_IMAGES),docker push $(PROJECTNAME)/$(i);)
else
	@echo 'Variable DOCKER_HUB_PASSWORD is not defined, cannot push images'
endif

$(COMPOSE_COMMANDS):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose.yml $(subst up,up -d,$@)

$(COMPOSE_COMMANDS_MON):
	docker-compose --env-file $(ENV_FILE) -f ./docker/docker-compose-monitoring.yml $(subst mon,,$(subst up,up -d,$@))

$(APP_IMAGES) $(MON_IMAGES) $(DOCKER_COMMANDS) $(COMPOSE_COMMANDS) $(COMPOSE_COMMANDS_MON): FORCE

FORCE:
