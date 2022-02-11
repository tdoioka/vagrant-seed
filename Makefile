SHELL:=$(shell which bash)
MAKEFLAGS:=\
	--no-builtin-rules\
	--no-builtin-variables\
	--no-print-directory
################################################################
FILES:=Vagrantfile
COMMAND:=verify format format-unsafe
RUBOCOPFLAG?=--format simple
RUBOCOP:=rubocop $(RUBOCOPFLAG)
################################################################
.PHONY: $(COMMAND)
verify:
	$(RUBOCOP) $(FILES)
format:
	$(RUBOCOP) -a $(FILES)
format-unsafe:
	$(RUBOCOP) -A $(FILES)
