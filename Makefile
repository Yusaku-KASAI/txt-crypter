.PHONY: check check-web check-target check-docs

# One target per concern, so that CI can run each from only the files it reads.
check: check-web check-target check-docs

# Dependencies are installed when the lockfile is newer than what is installed.
vue/node_modules/.package-lock.json: vue/package-lock.json
	cd vue && npm ci

check-web: vue/node_modules/.package-lock.json
	cd vue && npm run build

check-target:
	shellcheck .devcontainer/*.sh
	python3 .devcontainer/check-vscode-settings.py

check-docs:
	python3 tools/check-docs.py

.PHONY: up
up:
	docker compose up -d

.PHONY: down
down:
	docker compose down

.PHONY: stop
stop:
	docker compose stop

.PHONY: init
init:
	docker compose build --no-cache
	mkdir vue/node_modules
	make up

.PHONY: destroy
destroy:
	docker compose down --rmi all --volumes --remove-orphans
	rm -rf vue/node_modules

.PHONY: reset
reset:
	make destroy
	make init

.PHONY: front-create
front-create:
	rm -rf vue
	mkdir -p vue
	docker build -t front-create-image . --no-cache
	@echo "$(pwd)"
	@echo "$(shell pwd)"
	docker run -d --name front-create-container -it --mount type=bind,source=$(shell pwd)/vue,target=/opt/app/vue -p 3000:3000 front-create-image
	docker exec -it front-create-container npm create vue . -- --default
	docker exec -it front-create-container npm install
	docker stop front-create-container
	docker rm front-create-container
	docker rmi front-create-image
