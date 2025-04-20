BUILD_DIR ?= bin

RELEASE := $(BUILD_DIR)/jinmori
DBG := $(BUILD_DIR)/jinmori.dbg
TESTER := $(BUILD_DIR)/tester

BUILD_FLAGS :=
DBG_FLAGS := -const 'Exn.keepHistory true'

SOURCE := src/*.sml src/*.mlb
TESTS := tests/*.sml tests/*.mlb

all: $(RELEASE) $(DBG) $(TESTER)

.PHONY: test

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(RELEASE): $(SOURCE) $(BUILD_DIR)
	mlton -output $@ $(BUILD_FLAGS) src/jinmori.mlb

$(DBG): $(SOURCE) $(BUILD_DIR)
	mlton -output $@ $(BUILD_FLAGS) $(DBG_FLAGS) src/jinmori.mlb

$(TESTER): $(SOURCE) $(TESTS) $(BUILD_DIR)
	mlton -output $@ $(MLTON_FLAGS) $(DBG_FLAGS) tests/jinmori.tests.mlb

test: $(TESTER) $(DBG)
	$(TESTER)
	# tests/end2end/runner

install: $(RELEASE)
	@mkdir -p "$(HOME)/.jinmori" "$(HOME)/.jinmori/bin" "$(HOME)/.jinmori/pkgs"
	@cp "$(RELEASE)" "$(HOME)/.jinmori/bin"
	@echo "You may want to add '$(HOME)/.jinmori/bin' to your PATH if you haven't done so already"

clean:
	rm -f $(RELEASE) $(DBG) $(TESTER)
