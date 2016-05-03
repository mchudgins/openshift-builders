IMAGE := golang-builder:latest

all: build

build: Dockerfile docker-entrypoint.sh
	sudo docker build -t $(IMAGE) .

push:
	sudo docker tag -f $(IMAGE) internal-registry.dstresearch.com/$(IMAGE)
	sudo docker push internal-registry.dstresearch.com/$(IMAGE)

clean:
	- sudo docker rmi $(IMAGE)


