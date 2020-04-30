SRCFILES = debug/*.ml* tests/*.ml* cli/*.ml lib/*.ml lib/*.mli

CINAPSFILES = lib/*.cinaps tests/*.cinaps

OCAMLFORMAT = ocamlformat \
	--inplace \
	$(SRCFILES) \
	$(CINAPSFILES)

OCPINDENT = ocp-indent \
	--inplace \
	$(SRCFILES) \
	$(CINAPSFILES)

.PHONY: all
all :
	dune build @all

.PHONY: lib
lib :
	dune build lib

.PHONY: test
test :
	OCAMLRUNPARAM=b dune exec ./tests/main.exe

.PHONY: covtest
covtest :
	BISECT_ENABLE=yes OCAMLRUNPARAM=b dune exec ./tests/main.exe
	bisect-ppx-report html

.PHONY: debug
debug :
	dune exec ./debug/main.exe

.PHONY: cli
cli :
	dune exec ./cli/daypc.exe

.PHONY: doc
doc :
	dune build @doc

.PHONY: format
format :
	$(OCAMLFORMAT)
	$(OCPINDENT)

.PHONY: cinaps
cinaps :
	cinaps -i $(SRCFILES)
	$(OCAMLFORMAT)
	$(OCPINDENT)

.PHONY : clean
clean:
	dune clean
