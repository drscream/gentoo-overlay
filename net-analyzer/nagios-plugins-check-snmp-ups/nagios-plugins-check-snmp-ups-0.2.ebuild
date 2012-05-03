# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: nagios-plugins-check-snmp-ups-0.2.ebuild 177 2011-05-09 12:59:19Z thomas.merkel $

inherit eutils

DESCRIPTION="Another nagios plugin that will check the ups status via snmp"
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
	doexe ${FILESDIR}/check_snmp_ups.pl
	chown root:nagios "${D}"/usr/$(get_libdir)/nagios/plugins/check_snmp_ups.pl
	chmod 750 "${D}"/usr/$(get_libdir)/nagios/plugins/check_snmp_ups.pl
}
