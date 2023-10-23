SHELL := $(shell which bash)
.PHONY: test

test:
	pushd test; \
	go mod init "bananalab-platform"; \
	go mod tidy; \
	go test -v -tags integration -timeout 3600s; \
	popd
