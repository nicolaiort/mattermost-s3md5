IMAGE_NAME=ghcr.io/odit-services/mattermost
IMAGE_NAME_INTERNAL=registry.odit.services/library/mattermost
VERSION=latest

build: 
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME_INTERNAL):$(VERSION) --push .