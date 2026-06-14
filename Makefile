LOCALSEND_REPO = https://github.com/0w0mewo/localsend-cli.git
LOCALSEND_VERSION ?= main
OUTDIR = bin/tg5040

.PHONY: all fetch build package clean

all: fetch build

fetch:
	@if [ ! -d localsend-cli ]; then \
	  git clone --depth 1 --branch $(LOCALSEND_VERSION) $(LOCALSEND_REPO) localsend-cli; \
	fi

build: fetch
	mkdir -p $(OUTDIR)
	cd localsend-cli && \
	  CGO_ENABLED=0 GOOS=linux GOARCH=arm64 \
	  go build -ldflags="-s -w" -o ../$(OUTDIR)/localsend .
	@echo "Built: $(OUTDIR)/localsend ($$(file $(OUTDIR)/localsend))"

package: build
	mkdir -p dist
	zip -r dist/LocalSend.pak.zip \
	  launch.sh \
	  pak.json \
	  bin/tg5040/localsend
	@echo "Package: dist/LocalSend.pak.zip"

clean:
	rm -rf localsend-cli $(OUTDIR)/localsend dist
