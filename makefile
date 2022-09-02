# Override BASEHOME when running from wsl:
#	make all BASEHOME="/mnt/c/Users/<username>"
BASEHOME = $(HOME)

VM_NAME := "ArchLinux"
VM_DIR   = "$(BASEHOME)/VirtualBox\ VMs"
ARCH_ISO = "./out/$(shell ls -Art out/ | tail -n 1)"

all: iso vdi

test:
	echo $(BASEHOME)
	echo $(VM_DIR)

clean:
	rm -rf ali-arch-iso/
	rm -rf out/

iso:
	./make/gen_iso.sh --basehome "$(BASEHOME)"

vdi:
	./make/create_vm.sh --iso "$(ARCH_ISO)" --vm-directory "$(VM_DIR)" --vm-name $(VM_NAME)