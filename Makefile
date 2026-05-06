.PHONY: build run clean

build:
	swift build -c release

run: build
	.build/release/swift-committer

clean:
	swift package clean
