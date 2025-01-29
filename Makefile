BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output

.PHONY: build clean

build: 
	./make-image.sh $(BUILDDIR) $(OUTPUTDIR)
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)
	rm -f pacman.conf
