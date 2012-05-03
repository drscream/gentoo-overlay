# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit eutils

DESCRIPTION="Nagios plugin to check multible postfix mailqueues"
HOMEPAGE=""
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=""
RDEPEND=""

src_unpack() {
	: NOP
}

src_compile() {
	: NOP
}

pkg_setup() {
	enewgroup nagios
	enewuser nagios -1 /bin/bash /var/nagios/home nagios
}

src_install() {
	dodir /usr/$(get_libdir)/nagios/plugins
	exeinto /usr/$(get_libdir)/nagios/plugins
	doexe ${FILESDIR}/check_postfix_mailq
	chown root:nagios "${D}"/usr/$(get_libdir)/nagios/plugins/check_postfix_mailq
	chmod 750 "${D}"/usr/$(get_libdir)/nagios/plugins/check_postfix_mailq
}
