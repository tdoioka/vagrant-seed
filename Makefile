SHELL:=$(shell which bash)
MAKEFLAGS:=\
	--no-builtin-rules\
	--no-builtin-variables\
	--no-print-directory
################################################################
FILES:=Vagrantfile
COMMAND:=verify format format-unsafe watch
RUBOCOPEXTRAFLUG?=
RUBOCOPFLAG?=--format simple $(RUBOCOPEXTRAFLUG)
RUBOCOP:=rubocop $(RUBOCOPFLAG)
################################################################
.PHONY: $(COMMAND)
verify:
	$(RUBOCOP) $(FILES)
format:
	$(RUBOCOP) -a $(FILES)
format-unsafe:
	$(RUBOCOP) -A $(FILES)
watch:
	watch -c $(MAKE) format RUBOCOPEXTRAFLUG=--color
