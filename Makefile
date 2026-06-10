.PHONY: build run test probe bundle install clean

build:
	swift build

run: build
	swift run

test:
	swift test

probe: build
	$(shell swift build --show-bin-path)/Oolong --probe

bundle:
	bash scripts/bundle.sh

# 装到 /Applications 并打开
install: bundle
	rm -rf /Applications/Oolong.app
	cp -R dist/Oolong.app /Applications/
	open /Applications/Oolong.app

clean:
	swift package clean
	rm -rf dist
