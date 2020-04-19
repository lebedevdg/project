#.PHONY: servise dev prod
TEST :=
ENVIRONMENTS := servise dev prod
ENVIRONMENT_COMMANDS := stendsup stendsdown
APP_IMAGES := ui robot
MON_IMAGES := prometheus mongodb-exporter alertmanager telegraf grafana
DOCKER_COMMANDS := build push
COMPOSE_COMMANDS := config up down
COMPOSE_COMMANDS_MON := configmon upmon downmon

PROJECTNAME := $(shell grep -Po "(?<=PROJECTNAME=)[a-z]+" ./docker/.env)

ifeq '$(strip $(PROJECTNAME))' ''
  $(warning Variable PROJECTNAME is not defined, using value 'user')
  PROJECTNAME := noname
endif



#stendsup: dev

$(ENVIRONMENT_COMMANDS): $(ATEST)

	@echo '11111111111111111111111111 test сработка $@'
#STEND := $@

#define stend
#$@
#endef

$(ATEST):

#	@echo '11111111111111111111111111 test сработка $@'
#	stend := $@

#	stend = $(88 $@)

#ifeq '$@' 'stendsup'

#stend := up

#else

#stend := down

#endif

	@echo '44444444444444444444444444444444444 $(stend)'
	@echo '44444444444444444444444444444444444 $@'

$(ENVIRONMENTS):

ifeq '$(stend)' 'up'

	@echo '0000000000000000000000000000000первая сработка $(stend)'
	@echo 'первая сработка $@'
#	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
#	--google-machine-type n1-standard-1 --google-project docker3-273507 --google-zone europe-north1-b \
#	--google-open-port 9090/tcp --google-open-port 8080/tcp --google-open-port 3000/tcp --google-open-port 8000/tcp --google-open-port 15672/tcp $@

else

ifeq '$(strip $(stend))' 'up'
	@echo '0000000000000000000000000000000первая сработка $(stend)'
	@echo 'вторая сработка $@'
#	docker-machine rm -y $@
else
	@echo 'третья сработка $@'
	@echo '9999999999999999999999999999 $(stend)'
endif
endif


#$(ENVIRONMENTS)::
#	docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
#	--google-machine-type n1-standard-1 --google-project docker3-273507 --google-zone europe-north1-b \
#	--google-open-port 9090/tcp --google-open-port 8080/tcp --google-open-port 3000/tcp --google-open-port 8000/tcp --google-open-port 15672/tcp $@



#stendsdown: $(ENVIRONMENTS)
#$(ENVIRONMENTS)::
#	docker-machine rm -y $@















ENV_FILE := $(shell test -f ./docker/.env && echo './docker/.env' || echo './docker/.env.example')

build: $(APP_IMAGES) $(MON_IMAGES)

$(APP_IMAGES):
	docker build -t $(PROJECTNAME)/$@ ./apps/$@

$(MON_IMAGES):

	docker build -t $(PROJECTNAME)/$@ ./$@
## push:
# Загрузка образов на докер хаб
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


$(APP_IMAGES) $(MON_IMAGES) $(DOCKER_COMMANDS) $(COMPOSE_COMMANDS) $(COMPOSE_COMMANDS_MON) : FORCE

FORCE:
