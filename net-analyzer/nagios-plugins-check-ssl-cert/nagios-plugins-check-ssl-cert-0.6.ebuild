# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: nagios-plugins-check-ssl-cert-0.6.ebuild 146 2011-06-12 09:53:00Z thomas.merkel $

inherit eutils

DESCRIPTION="a nagios plugin which checks for expiring ssl certificates on disk."
HOMEPAGE=""
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=""
RDEPEND="dev-libs/openssl
	sys-apps/sed"

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
	dodir /usr/$(get_libdir)/nagios/plugins/
	exeinto /usr/$(get_libdir)/nagios/plugins/
	doexe ${FILESDIR}/check_ssl_cert.sh
	chown root:nagios "${D}"/usr/$(get_libdir)/nagios/plugins/check_ssl_cert.sh
	chmod 750 "${D}"/usr/$(get_libdir)/nagios/plugins/check_ssl_cert.sh
}
