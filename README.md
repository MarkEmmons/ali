1. Create the ISO
2. Create the VM

# Installing Arch on WSL

# Creating the VM

### Use to find the OSType
VBoxManage list ostypes | sls Arch

### Create and configure machine
VBoxManage createvm --name ArchLinux --ostype ArchLinux_64 --register
VBoxManage modifyvm ArchLinux --cpus 2 --memory 4096 --vram 20 --firmware efi
VBoxManage modifyvm ArchLinux --nic1 nat --bridgeadapter1 eth0 --natpf1 "SSH,tcp,,2222,,22"

### Create and attach storage
VBoxManage createhd --filename 'C:\Users\Mark\VirtualBox VMs\ArchLinux\ArchLinux.vdi' --size 8192 --variant Fixed
VBoxManage storagectl ArchLinux --name "SATA Controller" --add sata --bootable on
VBoxManage storageattach ArchLinux --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium 'C:\Users\Mark\VirtualBox VMs\ArchLinux\ArchLinux.vdi'

### Installing the guest OS
VBoxManage storagectl ArchLinux --name "IDE Controller" --add ide
VBoxManage storageattach ArchLinux --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium C:\Users\Mark\Documents\workspace\ALI\iso\out\archlinux-2022.08.31-x86_64.iso

### Create a shared folder
VBoxManage sharedfolder add ArchLinux --name "ALI" --hostpath C:\Users\Mark\Documents\workspace\ALI --readonly -automount

### Starting the Machine
VBoxManage startvm ArchLinux
ping archlinux.org
VBoxManage controlvm ArchLinux acpipowerbutton

### SSH into the Machine
VBoxManage modifyvm ArchLinux --vrde on
VBoxManage startvm ArchLinux --type headless
VBoxManage controlvm ArchLinux acpipowerbutton

ssh -p 2222 root@127.0.0.1 "ls /etc"