WORKDIR=$(shell pwd)/workdir
REPRO_WORKDIR=$(shell pwd)/repro
IMAGE_VERSION ?= $(shell date +"%Y.%m.%d")

.PHONY: build test clean

build: 
	scripts/build-image.sh $(WORKDIR) $(IMAGE_VERSION)

repro:
	scripts/repro-image.sh $(WORKDIR) $(REPRO_WORKDIR) $(IMAGE_VERSION)

test:
	scripts/test-image.sh $(WORKDIR) $(IMAGE_VERSION)

clean:
	rm -rf $(WORKDIR) $(REPRO_WORKDIR)
