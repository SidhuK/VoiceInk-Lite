DEPS_DIR := $(HOME)/VoiceInk-Dependencies
WHISPER_CPP_DIR := $(DEPS_DIR)/whisper.cpp
FRAMEWORK_PATH := $(WHISPER_CPP_DIR)/build-apple/whisper.xcframework
DERIVED_DATA := $(CURDIR)/.local-build
APP_NAME := VoiceInk Lite
BUILT_APP := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
INSTALLED_APP := $(HOME)/Downloads/$(APP_NAME).app
CODESIGN_IDENTITY ?=

.PHONY: all check whisper setup build local run dev clean help

all: local

check:
	@command -v git >/dev/null 2>&1 || { echo "git is not installed"; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is not installed (need Xcode)"; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "swift is not installed"; exit 1; }

whisper:
	@mkdir -p $(DEPS_DIR)
	@if [ ! -d "$(FRAMEWORK_PATH)" ]; then \
		echo "Building whisper.xcframework in $(DEPS_DIR)..."; \
		if [ ! -d "$(WHISPER_CPP_DIR)" ]; then \
			git clone https://github.com/ggerganov/whisper.cpp.git $(WHISPER_CPP_DIR); \
		else \
			(cd $(WHISPER_CPP_DIR) && git pull); \
		fi; \
		cd $(WHISPER_CPP_DIR) && ./build-xcframework.sh; \
	else \
		echo "whisper.xcframework already built in $(DEPS_DIR)"; \
	fi

setup: check whisper

# Uses the only Apple Development identity when exactly one exists, otherwise ad-hoc.
# A stable identity keeps macOS permissions across rebuilds.
build: setup
	@SIGNING_IDENTITY="$(CODESIGN_IDENTITY)"; \
	if [ -z "$$SIGNING_IDENTITY" ]; then \
		IDENTITIES=$$(security find-identity -v -p codesigning 2>/dev/null | awk '/"Apple Development: / { print $$2 }'); \
		COUNT=$$(printf '%s\n' "$$IDENTITIES" | awk 'NF { count++ } END { print count + 0 }'); \
		if [ "$$COUNT" -eq 1 ]; then \
			SIGNING_IDENTITY=$$(printf '%s\n' "$$IDENTITIES" | awk 'NF { print; exit }'); \
		elif [ "$$COUNT" -gt 1 ]; then \
			echo "Multiple Apple Development identities found; set CODESIGN_IDENTITY to pick one. Using ad-hoc signing."; \
		fi; \
	fi; \
	if [ -n "$$SIGNING_IDENTITY" ] && [ "$$SIGNING_IDENTITY" != "-" ]; then \
		SIGNING_REQUIRED=YES; \
		echo "Signing with $$SIGNING_IDENTITY"; \
	else \
		SIGNING_IDENTITY="-"; \
		SIGNING_REQUIRED=NO; \
		echo "Using ad-hoc signing (permissions may need approval again after rebuilds)"; \
	fi; \
	xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Release \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGN_STYLE=Manual \
		CODE_SIGN_IDENTITY="$$SIGNING_IDENTITY" \
		PROVISIONING_PROFILE_SPECIFIER="" \
		CODE_SIGNING_REQUIRED="$$SIGNING_REQUIRED" \
		CODE_SIGNING_ALLOWED=YES \
		DEVELOPMENT_TEAM="" \
		COMPILATION_CACHE_ENABLE_CACHING=NO \
		COMPILER_INDEX_STORE_ENABLE=NO \
		-skipPackagePluginValidation \
		-skipMacroValidation \
		build

local: build
	@if [ ! -d "$(BUILT_APP)" ]; then echo "Build output not found at $(BUILT_APP)"; exit 1; fi
	@rm -rf "$(INSTALLED_APP)"
	@ditto "$(BUILT_APP)" "$(INSTALLED_APP)"
	@xattr -cr "$(INSTALLED_APP)"
	@echo "Installed to $(INSTALLED_APP)"

run:
	@if [ -d "$(INSTALLED_APP)" ]; then \
		open "$(INSTALLED_APP)"; \
	elif [ -d "$(BUILT_APP)" ]; then \
		open "$(BUILT_APP)"; \
	else \
		echo "$(APP_NAME).app not found. Build it with 'make local'."; \
		exit 1; \
	fi

dev: local run

clean:
	@rm -rf "$(DERIVED_DATA)"
	@echo "Removed $(DERIVED_DATA)"

help:
	@echo "Targets:"
	@echo "  local    Build Release and copy $(APP_NAME).app to ~/Downloads (default)"
	@echo "  dev      local, then launch the app"
	@echo "  build    Build Release into .local-build"
	@echo "  run      Launch the installed or built app"
	@echo "  whisper  Clone and build whisper.xcframework in ~/VoiceInk-Dependencies"
	@echo "  check    Check required tools"
	@echo "  clean    Remove .local-build"
	@echo ""
	@echo "  CODESIGN_IDENTITY=<SHA or name> picks a signing identity; '-' forces ad-hoc."
