IMAGE_NAME=ghcr.io/odit-services/mattermost
IMAGE_NAME_INTERNAL=registry.odit.services/library/mattermost
VERSION=latest

init:
	git remote add upstream https://github.com/mattermost/mattermost.git
	git fetch upstream

update:
	git fetch upstream
	git switch origin/tags/$(TAG) -c upstream-tag-$(TAG)
	git checkout master
	git merge upstream-tag-$(TAG)

build-amd: 
	docker buildx build --platform linux/amd64 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME_INTERNAL):$(VERSION) --push .
build-arm: 
	docker buildx build --platform linux/arm64 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME_INTERNAL):$(VERSION) --push .
build: 
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME_INTERNAL):$(VERSION) --push .