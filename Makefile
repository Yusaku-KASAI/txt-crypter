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

# create vueする備忘録
# Makefile, docker-compose.yml, Dockerfile, .dockerignore, .gitignoreを用意
# .dockerignoreのvue/node_modulesをコメントアウトする
# make front-create
# create vueするときに手動確認あり
# プロジェクト名は.(カレントディレクトリ)を指定
# パッケージ名はpj名を指定
# make front-createの後、.dockerignoreでvue/node_modulesをアンコメント
# make reset
# vite.config.jsでサーバーオプションのhost:trueを指定
# 起動を確認したら、vite.configを確認して必要に応じてポート変更
