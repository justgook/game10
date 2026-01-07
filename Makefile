SHELL := bash
.ONESHELL:
.SECONDEXPANSION:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifdef V
Q=
WGET:=wget
else
Q=@
MAKEFLAGS += --no-print-directory
WGET:=wget -q --show-progress
endif


MKDIR_P ?= mkdir -p

.DEFAULT_GOAL := all

BUILD_DIR ?= build.nosync
ASSETS_DIR ?= assets

# https://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html
# https://www.tutorialspoint.com/unix_commands/xgettext.htm
# https://lokalise.com/blog/translating-apps-with-gettext-comprehensive-tutorial/

I18N_SRC := $(wildcard src/game/*.odin) $(wildcard src/game/*/*.odin) $(wildcard src/game/*/*/*.odin) $(wildcard src/game/*/*/*/*.odin) $(wildcard src/game/*/*/*/*/*.odin)

$(ASSETS_DIR)/locales/dialogues.pot: $(I18N_SRC)
	$(Q)echo "IMEPLEMNT dialogue extraction to template"


$(ASSETS_DIR)/locales/messages.pot: $(I18N_SRC)
	$(Q)$(MKDIR_P) $(@D)
	$(Q)xgettext -d messages --language=C -kT -kTn:1,2 -o $@ $? --from-code UTF-8

$(ASSETS_DIR)/locales/%/messages.po: $(ASSETS_DIR)/locales/messages.pot
	@if [ -f $@ ]; then \
		echo "Updating existing translation $@"; \
		msgmerge --backup=none --update $@ $<; \
	else \
		echo "Initializing new translation $@"; \
		$(MKDIR_P) $(@D);\
		msginit -l "$(call get_locale,$*)" -i $< -o $@ --no-translator; \
	fi

$(BUILD_DIR)/locales/%/messages.mo: $(ASSETS_DIR)/locales/%/messages.po
 # $(BUILD_DIR)/%.mo: $(ASSETS_DIR)%.po
	$(Q)echo "Creating $@"
	$(MKDIR_P) $(@D)
	msgfmt -o $@ $<

.PHONY: all
all: $(I18N_SRC)
	echo $?

.PHONY: develop
develop:
	odin run . -show-system-calls -- -run -hot -debug

LANG_MAP := es=es_ES.UTF-8 en=en_EN.UTF-8
get_locale = $(strip \
    $(or \
        $(patsubst $(1)=%,%,$(filter $(1)=%,$(LANG_MAP))), \
        $(1)_$(shell echo $(1) | tr 'a-z' 'A-Z').UTF-8 \
    ))
