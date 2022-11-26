# var
MODULE = $(notdir $(CURDIR))
module = $(shell echo $(MODULE) | tr A-Z a-z)
OS     = $(shell uname -o|tr / _)
NOW    = $(shell date +%d%m%y)
REL    = $(shell git rev-parse --short=4 HEAD)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

# cross-compile
APP     ?= $(MODULE)
HW      ?= qemu386
-include   hw/$(HW).mk
-include  cpu/$(CPU).mk
-include arch/$(ARCH).mk

# version
BR_VER = 2022.08.2

# dir
CWD  = $(CURDIR)
ROOT = $(CWD)/root
GZ   = $(HOME)/gz

# tool
CURL   = curl -L -o
CF     = clang-format

# package
BR    = buildroot-$(BR_VER)
BR_GZ = $(BR).tar.xz

# all
.PHONY: all
all: fw

.PHONY: fw
fw: $(BR)/README.md
	cd $(BR) ;\
	rm .config ; make allnoconfig ;\
	cat ../all/all.br      >> .config ;\
	cat ../arch/$(ARCH).br >> .config ;\
	cat ../cpu/$(CPU).br   >> .config ;\
	cat ../hw/$(HW).br     >> .config ;\
	cat ../app/$(APP).br   >> .config ;\
	echo 'BR2_TOOLCHAIN_BUILDROOT_VENDOR="$(APP)_$(HW)"' >> .config ;\
	echo 'BR2_DL_DIR="$(GZ)"'                            >> .config ;\
	echo 'BR2_TARGET_GENERIC_HOSTNAME = "$(APP)"'        >> .config ;\
	echo 'BR2_TARGET_GENERIC_ISSUE="$(APP) @ $(HW)"'     >> .config ;\
	echo 'BR2_ROOTFS_OVERLAY="$(ROOT)"'                  >> .config ;\
	make menuconfig ;\
	make

# rule
%/README.md: $(GZ)/%.tar.xz
	xzcat $< | tar x && touch $@

# doc
.PHONY: doxy doc
doc: doxy
	rsync -rv ~/mdoc/$(MODULE)/* doc/$(MODULE)/
	rsync -rv ~/mdoc/Buildroot/* doc/Buildroot/
	rsync -rv ~/mdoc/Linux/*     doc/Linux/
	git add doc

# install
install: gz src
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`

.PHONY: gz
gz: $(GZ)/$(BR_GZ)

.PHONY: src
src: $(BR)/README.md

$(GZ)/$(BR_GZ):
	$(CURL) $@ https://buildroot.org/downloads/$(BR_GZ)

# merge
MERGE  = Makefile README.md .clang-format .doxygen $(S) .gitignore
MERGE += apt.txt
MERGE += .vscode bin doc lib inc src tmp
MERGE += all app hw cpu arch

dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)
	$(MAKE) doc
#	$(MAKE) doxy ; git add -f docs

shadow:
	git push -v
	git checkout $@
	git pull -v

release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

ZIP = tmp/$(MODULE)_$(NOW)_$(REL)_$(BRANCH).zip
zip:
	git archive --format zip --output $(ZIP) HEAD
