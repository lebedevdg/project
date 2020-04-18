APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager telegraf grafana
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS := config up down
COMPOSE_COMMANDS_MON := configmon upmon downmon

PROJECTNAME := $(shell grep -Po "(?<=PROJECTNAME=)[a-z]+" ./docker/.env)

ifeq '$(strip $(PROJECTNAME))' ''
  $(warning Variable PROJECTNAME is not defined, using value 'user')
  PROJECTNAME := error
endif

ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')

build: $(APP_IMAGES) $(MON_IMAGES)

$(APP_IMAGES):
#	cd ./apps/$@; bash docker_build.sh; cd -
	docker build -t $(PROJECTNAME)/$@ ./apps/$@

$(MON_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./$@

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
