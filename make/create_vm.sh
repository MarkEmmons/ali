#!/bin/bash

### Default Values - Can be overridden
CPUS=2
MEM=4096     # MB
VRAM=20      # MB
STORAGE=8192 # MB
HOSTPATH="$(dirname $0)/.."

# Get Parameters
while (($#)); do
	case $1 in
		-i|--iso)
			shift
			ARCH_ISO=$1
			shift
			;;
		-v|--vm-directory)
			shift
			VM_DIR=$1
			shift
			;;
		-n|--vm-name)
			shift
			VM_NAME=$1
			shift
			;;
		-h|--hostpath)
			shift
			HOSTPATH=$1
			shift
			;;
		-c|--cpus)
			shift
			CPUS=$1
			shift
			;;
		-m|--memory)
			shift
			MEM=$1
			shift
			;;
		-V|--vram)
			shift
			VRAM=$1
			shift
			;;
		-s|--storage)
			shift
			STORAGE=$1
			shift
			;;
	esac
done

VDI_FULL_NAME="$VM_DIR/$VM_NAME/$VM_NAME.vdi"

### Validate Parameters
[[ -z "${ARCH_ISO}" ]] && echo "You must specify a path to the Arch iso" && exit 1
[[ -z "${VM_DIR}" ]] && echo "You must specify a path to the Virtual Box vms" && exit 1
[[ -z "${VM_NAME}" ]] && echo "You must specify a name for the Virtual Box vm" && exit 1

if [ ! -f $ARCH_ISO ]; then

	1>&2 echo "The specified Arch iso, $ARCH_ISO, does not exist"
	exit 1
fi

if [ ! -d $VM_DIR ]; then

	1>&2 echo "The specified Virtual Box directory, $VM_DIR, does not exist"
	exit 1
fi

### Delete VM if it already exists
VBoxManage.exe showvminfo $VM_NAME > /dev/null 2>&1 && VBoxManage.exe unregistervm --delete $VM_NAME

### Create and configure machine
VBoxManage.exe createvm --name $VM_NAME --ostype ArchLinux_64 --register
VBoxManage.exe modifyvm $VM_NAME --cpus $CPUS --memory $MEM --vram $VRAM --firmware efi
VBoxManage.exe modifyvm $VM_NAME --nic1 nat --bridgeadapter1 eth0 --natpf1 "SSH,tcp,,2222,,22" --vrde on

### Create and attach storage
VBoxManage.exe createhd --filename "$VDI_FULL_NAME" --size $STORAGE --variant Fixed
VBoxManage.exe storagectl $VM_NAME --name "SATA Controller" --add sata --bootable on
VBoxManage.exe storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_FULL_NAME"

### Installing the guest OS
VBoxManage.exe storagectl $VM_NAME --name "IDE Controller" --add ide
VBoxManage.exe storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ARCH_ISO

### Create a shared folder
VBoxManage.exe sharedfolder add $VM_NAME --name "ALI" --hostpath $HOSTPATH --readonly -automount