MAIN_MODULES = json_repr json_query json_schema json_encoding
BSON_MODULES = json_repr_bson
ALL_MODULES = $(MAIN_MODULES) $(BSON_MODULES)
ALL = \
  src/ocplib_json_typed.cmxa \
  src/ocplib_json_typed.cmxs \
  src/ocplib_json_typed.cma \
  src/ocplib_json_repr_bson.cmxa \
  src/ocplib_json_repr_bson.cmxs \
  src/ocplib_json_repr_bson.cma

PACKAGES = ocplib-endian uri
SAFE_STRING = $(shell if ocamlc -safe-string 2> /dev/null ; then echo "-safe-string" ; fi)

ifeq ($(shell if ocamlfind query js_of_ocaml 2> /dev/null >&2 ; then echo "YES" ; fi),YES)
BROWSER_MODULES = json_repr_browser
ALL_MODULES += $(BROWSER_MODULES)
PACKAGES += js_of_ocaml
ALL += src/ocplib_json_repr_browser.cma
endif

ML = $(patsubst %, src/%.ml, $(1))
MLI = $(patsubst %, src/%.mli, $(1))
CMX = $(patsubst %, src/%.cmx, $(1))
CMO = $(patsubst %, src/%.cmo, $(1))
CMI = $(patsubst %, src/%.cmi, $(1))

OPTS = -bin-annot -g $(SAFE_STRING) -I src $(patsubst %, -package %, $(PACKAGES))

.PHONY: all clean doc test

all: $(ALL)

src/ocplib_json_typed.cmxa: $(call CMX, $(MAIN_MODULES))
	ocamlfind ocamlopt $(OPTS) $^ -a -o $@

src/ocplib_json_typed.cmxs: $(call CMX, $(MAIN_MODULES))
	ocamlfind ocamlopt $(OPTS) $^ -shared -o $@

src/ocplib_json_typed.cma: $(call CMO, $(MAIN_MODULES))
	ocamlfind ocamlc $(OPTS) $^ -a -o $@

src/ocplib_json_repr_bson.cmxa: $(call CMX, $(BSON_MODULES))
	ocamlfind ocamlopt $(OPTS) $^ -a -o $@

src/ocplib_json_repr_bson.cmxs: $(call CMX, $(BSON_MODULES))
	ocamlfind ocamlopt $(OPTS) $^ -shared -o $@

src/ocplib_json_repr_bson.cma: $(call CMO, $(BSON_MODULES))
	ocamlfind ocamlc $(OPTS) $^ -a -o $@

src/ocplib_json_repr_browser.cma: $(call CMO, $(BROWSER_MODULES))
	ocamlfind ocamlc $(OPTS) $^ -a -o $@

test/test.asm: src/ocplib_json_typed.cmxa test/test.ml
	ocamlfind ocamlopt $(OPTS) -package "ezjsonm" src/ocplib_json_typed.cmxa $^ -o $@ -linkpkg

%.cmx: %.ml
	ocamlfind ocamlopt $(OPTS) -c $<

%.cmo: %.ml
	ocamlfind ocamlc $(OPTS) -c $<

%.cmi: %.mli
	ocamlfind ocamlopt $(OPTS) -c $<

-include .depend

.depend: \
  $(call ML, $(ALL_MODULES)) \
  $(call MLI, $(ALL_MODULES)) \
  test/test.ml Makefile
	ocamlfind ocamldep -I src \
    $(patsubst %, -package %, $(PACKAGES)) \
    $(call ML, $(ALL_MODULES)) \
    $(call MLI, $(ALL_MODULES)) \
  > $@

doc: \
  $(call MLI, $(ALL_MODULES))
	-mkdir doc
	ocamlfind ocamldoc -I src -html -d doc \
    $(patsubst %, -package %, $(PACKAGES))\
    $(call MLI, $(ALL_MODULES))

clean:
	-rm -f */*.cm* */*.o */*.a */*.so */*.dylib */*.dll */*~ *~
	-rm -f test/test.asm
	-rm -rf doc

test: test/test.asm

install: all doc
	ocamlfind install ocplib-json-typed src/*
	mkdir -p $(shell ocamlfind printconf destdir)/../doc/ocplib-json-typed
	cp doc/* $(shell ocamlfind printconf destdir)/../doc/ocplib-json-typed

uninstall:
	ocamlfind remove ocplib-json-typed
	rm $(shell ocamlfind printconf destdir)/../doc/ocplib-json-typed/* -rf
