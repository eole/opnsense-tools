#!/bin/sh

# Copyright (c) 2015-2017 Franco Fichtner <franco@opnsense.org>
# Copyright (c) 2004-2009 Scott Ullrich <sullrich@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

set -e

SELF=nano

. ./common.sh

check_image ${SELF} ${@}

NANOSIZE="3G"

if [ -n "${1}" ]; then
	NANOSIZE=${1}
fi

NANOIMG="${IMAGESDIR}/${PRODUCT_RELEASE}-nano-${PRODUCT_ARCH}.img"
NANOSIZE=$(echo ${NANOSIZE} | tr '[:upper:]' '[:lower:]')
NANOLABEL="${PRODUCT_NAME}_Nano"

sh ./clean.sh ${SELF}

setup_stage ${STAGEDIR}
setup_base ${STAGEDIR}
setup_kernel ${STAGEDIR}
setup_packages ${STAGEDIR}
setup_extras ${STAGEDIR} ${SELF}
setup_entropy ${STAGEDIR}

cat > ${STAGEDIR}/etc/fstab << EOF
# Device		Mountpoint	FStype	Options		Dump	Pass#
/dev/ufs/${NANOLABEL}	/		ufs	rw		1	1
EOF

makefs -t ffs -s ${NANOSIZE} -B little \
    -o label=${NANOLABEL} ${NANOIMG} ${STAGEDIR}

DEV=$(mdconfig -a -t vnode -f ${NANOIMG} -x 63 -y 255)
gpart create -s BSD ${DEV}
gpart bootcode -b ${STAGEDIR}/boot/boot ${DEV}
gpart add -t -a 4k freebsd-ufs ${DEV}
mdconfig -d -u ${DEV}
