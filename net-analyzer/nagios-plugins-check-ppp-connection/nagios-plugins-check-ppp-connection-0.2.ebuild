# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: nagios-plugins-check-ppp-connection-0.2.ebuild 116 2009-03-12 17:15:08Z georg.weiss $

inherit eutils

DESCRIPTION="a nagios plugin which checks for connection cuts of the dsl line"
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
	doexe ${FILESDIR}/check_ppp_connection.sh
	chown root:nagios "${D}"/usr/$(get_libdir)/nagios/plugins/check_ppp_connection.sh
	chmod 750 "${D}"/usr/$(get_libdir)/nagios/plugins/check_ppp_connection.sh
}
