# vegeta runner makefile

VEGETA_BIN := ./bin/vegeta
VG_VERSION := 8.1.1
VG_ARCH := amd64
VG_OS := linux
VG_BASE_URL := https://github.com/tsenart/vegeta/releases/download/cli%2F
VEGETA_URL := $(VG_BASE_URL)v$(VG_VERSION)/vegeta-$(VG_VERSION)-$(VG_OS)-$(VG_ARCH).tar.gz

VG_EXTRA_ARGS := '-keepalive -http2=f -header "Content-type:gzip"'

######################
# Setup
######################

.PHONY: setup install download

upgrade: download
download:
	@echo "#> Downloading vegeta"
	@test -d ./bin || mkdir -p ./bin
	@wget $(VEGETA_URL) -O $(VEGETA_BIN).tar.gz
	@tar xvfz $(VEGETA_BIN).tar.gz -C bin/ vegeta
	@chmod u+x $(VEGETA_BIN)
	test -x $(VEGETA_BIN) || (@echo "\nERROR - bin[$(VEGETA_BIN)] not found"; exit 1)
	@echo -e "\n\n#> Downloading vegeta"
	$(VEGETA_BIN) --version

setup: install
install:
	@if [ -f $(VEGETA_BIN) ]; then \
		echo "#> Vegeta is alread installed. Please use upgrade option"; \
	else \
		$(MAKE) download; \
	fi

clean:
	rm -rfv ./bin/*

######################
# Runner
######################
INPUT_PLAN := input/sample-plan.txt

run:
	@./runner.sh $(INPUT_PLAN) $(VG_EXTRA_ARGS)
