# Copyright (C) 2017 EDF SA
# Contact:
#       CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
#       1, Avenue du General de Gaulle
#       92140 Clamart
#
# Authors: CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
#
# This file is part of singularity-wrapper.
#
# singularity-wrapper is free software: you can redistribute in and/or
# modify it under the terms of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with puppet-hpc. If not, see
# <http://www.gnu.org/licenses/>.
BootStrap: debootstrap
OSVersion: stretch
MirrorURL: http://httpredir.debian.org/debian

%setup

# SSH wrapper calling singularity
cp sshwrapper ${SINGULARITY_ROOTFS}/usr/local/bin/ssh

# Copy SSL certificate if defined
if [ -f "ssl-cert.pem" ]
then
  mkdir -p "${SINGULARITY_ROOTFS}/etc/local-pki"
  chmod 755 "${SINGULARITY_ROOTFS}/etc/local-pki"
  cp "ssl-cert.pem" "${SINGULARITY_ROOTFS}/etc/local-pki/ssl-cert.pem"
  chmod 400 "${SINGULARITY_ROOTFS}/etc/local-pki/ssl-cert.pem"
else
  echo "ssl-cert.pem file missing" >&2
fi
if [ -f "ssl-cert.key" ]
then
  mkdir -p "${SINGULARITY_ROOTFS}/etc/local-pki"
  chmod 755 "${SINGULARITY_ROOTFS}/etc/local-pki"
  cp "ssl-cert.key" "${SINGULARITY_ROOTFS}/etc/local-pki/ssl-cert.key"
  chmod 400 "${SINGULARITY_ROOTFS}/etc/local-pki/ssl-cert.key"
else
  echo "ssl-cert.key file missing" >&2
fi


%post

## Generic Scibian Base System
# Add support for 32bits
dpkg --add-architecture i386

# Do not install recommends
echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/no-recommends

# Add scibian9 repos
echo "deb http://scibian.org/repo/scibian9 scibian9 main contrib non-free
deb http://scibian.org/repo/scibian9 stretch main contrib non-free
deb http://scibian.org/repo/scibian9 stretch-updates main contrib non-free" > /etc/apt/sources.list

# Update APT cache
apt-get update

# Make sure chroot is up-to-date
apt-get -y --force-yes upgrade && apt-get clean

# Install apt-transport-https
apt-get -y --force-yes install apt-transport-https && apt-get clean

# Install ssh
apt-get -y --force-yes install ssh && apt-get clean

# Disable StrictHostKeyChecking in SSH
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Deactivate ping command
[ -L /bin/ping ] || ln -s /bin/true /bin/ping

# Fix sshwrapper perms
chown root:root /usr/local/bin/ssh
chmod 755 /usr/local/bin/ssh


## Local Image customization
mkdir -p /scratch


## Generic OpenMPI

# OFED/RDMA
apt-get -y --force-yes install dapl2-utils ibverbs-utils libcxgb3-1 libdapl2 libibverbs1 libnes1 librdmacm1 rdmacm-utils libmlx4-1 libmlx5-1 libpsm-infinipath1 libfabric1

# OpenMPI
apt-get -y --force-yes install openmpi-bin && apt-get clean


## Generic NVIDIA Scibian

# Install NVIDIA libs
#    include libgl1-nvidia-glx to force its use instead of the glvnd version which is not compatible with
#    scibian-nvidia.
apt-get -y --force-yes install \
	scibian-nvidia \
	nvidia-smi \
	libgl1-nvidia-glx \
	nvidia-driver-libs-i386 \
	glx-alternative-nvidia \
	&& apt-get clean


## Generic Graphical Base

# Install Mesa libs
apt-get -y --force-yes install \
	mesa-utils \
	libgl1-mesa-dri:amd64 \
	libgl1-mesa-dri:i386 \
	libglew2.0:i386 \
	libglu1-mesa:i386 \
	glx-alternative-mesa \
	update-glx \
	&& apt-get clean

# Set default glx to mesa
#   If the user wishes to use glx provided by nvidia, she should use
#   "singularity --nv" anyway, and this command will override the
#   glx alternative with LD_LIBRARY_PATH.
update-glx --set glx /usr/lib/mesa-diverted


## Generic Applis repository
# Add repository
echo "deb http://scibian.org/repo/scibian9-applis-public s9-applis-public main contrib non-free" >> /etc/apt/sources.list

# Configure TLS cert, it should be bound if necessary
echo 'Acquire::https::SslCert "/etc/local-pki/ssl-cert.pem";
Acquire::https::SslKey "/etc/local-pki/ssl-cert.key";' >> /etc/apt/apt.conf.d/ssl

# Set permissions on local-pki certs
chown _apt /etc/local-pki/ssl-cert.pem
chown _apt /etc/local-pki/ssl-cert.key

# Update APT cache
apt-get update


## Local Application: {{ app_packages }}
apt-get -y --force-yes install {{ app_packages }} && apt-get clean


## Generic Cleanup
# Clean TLS/SSL certs
if [ -d /etc/local-pki ]
then
  rm -rf /etc/local-pki
fi
