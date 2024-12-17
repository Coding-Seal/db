.PHONY: lint 
lint:
	wsl --fix ./...
	golangci-lint run --fix

.PHONY: run
run:
	go run cmd/*