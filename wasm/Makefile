.PHONY: deps
deps:
	dep ensure

build:
	GOARCH=wasm GOOS=js go build -o bin/lib.wasm main.go bow.go knn.go
