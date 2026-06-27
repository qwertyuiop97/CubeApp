.PHONY: build run test clean

# Swift Package shortcuts (works once Package.swift is added)
build:
	swift build

run:
	swift run

test:
	swift test

clean:
	swift package clean
