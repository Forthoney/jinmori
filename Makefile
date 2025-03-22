RELEASE := bin/jinmori
DBG := bin/jinmori.dbg
TESTER := bin/testall

BUILD_FLAGS := 
DBG_FLAGS := -const 'Exn.keepHistory true'

SOURCE := src/*.sml src/*.mlb
TESTS := tests/*.sml tests/*.mlb

all: $(RELEASE) $(DBG) $(TESTER)

.PHONY: test

$(RELEASE): $(SOURCE)
	mlton $(BUILD_FLAGS) -output $@ src/jinmori.mlb

$(DBG): $(SOURCE)
	mlton $(BUILD_FLAGS) $(DBG_FLAGS) -output $@ src/jinmori.mlb

$(TESTER): $(SOURCE) $(TESTS)
	mlton $(MLTON_FLAGS) $(DBG_FLAGS) -output $@ tests/jinmori.tests.mlb

test: $(TESTER) $(DBG)
	$(TESTER)
	set +e
	tests/end2end/runner

install: $(RELEASE)
	@mkdir -p "$(HOME)/.jinmori" "$(HOME)/.jinmori/bin" "$(HOME)/.jinmori/pkgs"
	@cp "$(RELEASE)" "$(HOME)/.jinmori/bin"
	@echo "You may want to add '$(HOME)/.jinmori/bin' to your PATH"

clean:
	rm -f $(RELEASE) $(DBG) $(TESTER)
