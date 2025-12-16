WORKDIR=$(shell pwd)/workdir
REPRO_WORKDIR=$(shell pwd)/repro
IMAGE_VERSION ?= $(shell date +"%Y.%m.%d")
ARCHIVE_SNAPSHOT=$(shell date -d "$(awk -F. '{print $1"-"$2"-"$3}' <<< "$IMAGE_VERSION") -1 day" +"%Y/%m/%d")
SOURCE_DATE_EPOCH=$(shell date -u -d "$(echo "$ARCHIVE_SNAPSHOT")" +"%s")

.PHONY: build test clean

build: 
	scripts/build-image.sh $(WORKDIR) $(IMAGE_VERSION) $(ARCHIVE_SNAPSHOT) $(SOURCE_DATE_EPOCH)

repro:
	scripts/repro-image.sh $(WORKDIR) $(REPRO_WORKDIR) $(IMAGE_VERSION)

test:
	scripts/test-image.sh $(WORKDIR) $(IMAGE_VERSION)

clean:
	rm -rf $(WORKDIR) $(REPRO_WORKDIR)
