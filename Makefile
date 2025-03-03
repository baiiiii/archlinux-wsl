WORKDIR=$(shell pwd)/workdir
IMAGE_VERSION=$(shell date +"%Y.%m.%d")

.PHONY: build clean

build: 
	./make-image.sh $(WORKDIR) $(IMAGE_VERSION)
clean:
	rm -rf $(WORKDIR)
