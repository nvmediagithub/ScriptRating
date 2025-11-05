.PHONY: help clean get analyze format build run test build-apk build-ios

help: ## Show this help message
	@echo 'Flutter Development Commands:'
	@echo ''
	@echo 'Development:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Clean Flutter project
	flutter clean

get: ## Get dependencies
	flutter pub get

analyze: ## Analyze code
	flutter analyze

format: ## Format code
	dart format .

build: ## Build for current platform
	flutter build

run: ## Run in development mode
	flutter run

test: ## Run tests
	flutter test

build-apk: ## Build Android APK
	flutter build apk --release

build-ios: ## Build iOS app
	flutter build ios --release

build-runner: ## Run build runner for code generation
	flutter pub run build_runner build --delete-conflicting-outputs

watch: ## Watch for changes and rebuild
	flutter pub run build_runner watch