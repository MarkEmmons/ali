#!/bin/bash

BASEHOME=$HOME

# Get Parameters
while (($#)); do
	case $1 in
		-b|--basehome)
			shift
			BASEHOME=$1
			shift
			;;
	esac
done

# Validate path
if [ ! -d $BASEHOME ]; then

	1>&2 echo "The specified basehome directory, $BASEHOME, does not exist"
	exit 1
fi

STAGING_DIR="ali-arch-iso"
WORKING_DIR="/tmp/archiso-tmp"

ETC="$STAGING_DIR/airootfs/etc"
ROOT="$STAGING_DIR/airootfs/root"

[[ -d $STAGING_DIR ]] && rm -rf $STAGING_DIR
mkdir -p $STAGING_DIR

[[ -d $WORKING_DIR ]] && sudo rm -rf $WORKING_DIR
mkdir -p $WORKING_DIR

[[ -d out ]] && rm -rf out
mkdir -p out

# Stage Iso
cp -r /usr/share/archiso/configs/releng/* $STAGING_DIR

# Add ansible
sed -i "$ a ansible" $STAGING_DIR/packages.x86_64

# Generate ssh keys
rm $BASEHOME/.ssh/{al_id_rsa,al_id_rsa.pub}
ssh-keygen -q -t rsa -N '' -f $BASEHOME/.ssh/al_id_rsa

# Add ssh keys to iso
mkdir -p $ROOT/.ssh
chmod 700 $ROOT/.ssh
cat $BASEHOME/.ssh/al_id_rsa.pub >> $ROOT/.ssh/authorized_keys
chmod 600 $ROOT/.ssh/authorized_keys

# Modify sshd_config
sed 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /etc/ssh/ssh_host_rsa_key|' -i $ETC/ssh/sshd_config
sed 's|#PasswordAuthentication yes|PasswordAuthentication no|' -i $ETC/ssh/sshd_config

# Generate the iso
sudo mkarchiso -v -w $WORKING_DIR $STAGING_DIR
chmod a+rw out/