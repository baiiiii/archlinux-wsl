BUILDDIR ?= $(shell pwd)/build
OUTPUTDIR ?= $(shell pwd)/output
IMAGE_VERSION ?= $(shell date +"%Y.%m.%d")

.PHONY: build clean

build: 
	./make-image.sh $(BUILDDIR) $(OUTPUTDIR) $(IMAGE_VERSION)
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)
	rm -f pacman.conf
