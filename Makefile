
SOURCES_HTML=$(wildcard src/html/*.html src/html/*/*.html)
SOURCES_CSS=$(wildcard src/css/*.css src/css/*/*.css)
SOURCES_JS=$(wildcard src/js/*.js src/js/*/*.js)
SOURCES_JSON=$(wildcard src/json/*.json src/json/*/*.json)
SOURCES_PY=$(wildcard src/py/*.py src/py/**/*.py) $(wildcard deps/extra/src/py/**/*.py)
UIJS_JS=$(wildcard deps/uijs/src/js/*.js deps/uijs/src/js/*/*.js)
UIJS_CSS=$(wildcard deps/uijs/src/css/*.css deps/uijs/src/css/*/*.css)

WATCH_PY=$(call rwildcard,src/py,.py) $(foreach D,$(wildcard deps/*/src/py),$(call rwildcard,$D,.py))

BUILD_WHL=$(wildcard build/*.whl)
RUN_HTML=$(SOURCES_HTML:src/html/%=run/lib/html/%)
RUN_JS=$(UIJS_JS:deps/uijs/src/js/%=run/lib/js/%) $(SOURCES_JS:src/js/%=run/lib/js/%)
RUN_JSON=$(SOURCES_JSON:src/json/%=run/lib/json/%)
RUN_CSS=$(UIJS_CSS:deps/uijs/src/css/%=run/lib/css/%) $(SOURCES_CSS:src/css/%=run/lib/css/%)
RUN_WHL=$(BUILD_WHL:build/%=run/lib/whl/%)
RUN_ALL=$(RUN_JS) $(RUN_CSS) $(RUN_HTML) $(RUN_JSON) $(RUN_WHL)

cmd-symlink=mkdir -p "$(dir $@)"; ln -sfr "$<" "$@"
rwildcard=$(wildcard $(subst SUF,$2,$(subst PRE,$(if $1,$1,.),PRE/*SUF PRE/*/*SUF PRE/*/*/*SUF PRE/*/*/*/*SUF PRE/*/*/*/*/*SUF PRE/*/*/*/*/*/*/*SUF PRE/*/*/*/*/*/*/*/*SUF PRE/*/*/*/*/*/*/*/*/*SUF PRE/*/*/*/*/*/*/*/*/*/*SUF)))

PYTHONPATH=$(abspath src/py):$(abspath deps/extra/src/py):$(abspath deps/sdf)

define cmd-download
	mkdir -p "$@.tmp"
	curl -L $1 -o "$@.zip"
	unzip "$@.zip" -d "$@.tmp"
	mv "$@.tmp/$2" "$@"
	rmdir "$@.tmp"
	unlink "$@.zip"
endef

.PHONY: run
run: $(RUN_ALL)
	@
	# env -C run PYTHONPATH="$(PYTHONPATH)" python -m http.server
	COMMAND="env -C run PYTHONPATH="$(PYTHONPATH)" python -m sdfed.server"
	if [ -z "$$(which entr 2> /dev/null)" ]; then
		echo "--- Running standalone: $$COMMAND"
		env $$COMMAND
	else
		echo "--- Running using entr: $$COMMAND"
		echo $(WATCH_PY) | xargs -n1 echo | entr -nr $$COMMAND
	fi

.PHONY: shell
shell:
	nix-shell replit.nix

.PHONY: clean
clean:
	@for path in run/lib/html run/lib/js/uijs; do
		if [ -e "$$path" ]; then
			unlink "$$path" fi
	done
	if [ -e run ]; then
		find run -type d -empty -delete
	fi

run/lib/whl/%.whl: build/%.whl
	@$(call cmd-symlink)

run/lib/%: src/%
	@$(call cmd-symlink)

run/lib/%: deps/uijs/src/%
	@$(call cmd-symlink)

deps/pyscript:
	@$(call cmd-download,https://github.com/pyscript/pyscript/archive/refs/heads/main.zip,pyscript-main)

deps/three:
	@$(call cmd-download,https://github.com/mrdoob/three.js/archive/master.zip,three.js-master)

print-%:
	@$(info $*=$($*))

.ONESHELL:

# EOF
