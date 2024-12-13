.PHONY: lint 
lint:
	wsl --fix ./...
	golangci-lint run --fix