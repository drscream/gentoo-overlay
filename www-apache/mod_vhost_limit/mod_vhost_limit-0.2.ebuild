# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit apache-module

DESCRIPTION="Restrict the number of simultaneous connections per vhost"
HOMEPAGE="http://apache.ivn.cl/#vhostlimit"
SRC_URI="http://apache.ivn.cl/files/source/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="dev-libs/apr"

RDEPEND="${DEPEND}"

APACHE2_MOD_CONF=10_${PN}
APACHE2_MOD_DEFINE="VHOST_LIMIT STATUS"
APXS2_S=${S}
APACHE2_MOD_FILE=${APXS2_S}/.libs/${PN}.so

need_apache2

src_compile() {
	local MYOPTS="-c mod_vhost_limit.c"
	cd "${APXS2_S}"
	${APXS} ${MYOPTS} || die "compile failed"
	MYOPTS="-c mod_vhost_limit.lo"
	${APXS} ${MYOPTS} || die "compile failed"
}
pkg_postinst() {
	apache-module_pkg_postinst
	einfo "ExtendedStatus \"On\" to enable extended status information"
	einfo "'MaxVhostClients' followed by non-negative integer"
}
