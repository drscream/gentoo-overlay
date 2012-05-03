# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

KEYWORDS="-* ~amd64 ~x86"

DESCRIPTION="Areca RaidCard CLI tools for amd64 and x86."
HOMEPAGE="http://www.areca.com.tw/support/main.htm"
SRC_URI="V${PV}-61107.zip"
LICENSE="areca"
SLOT="0"
IUSE=""
RESTRICT="fetch mirror strip"

S="${WORKDIR}/V${PV}-61107"

DEPEND="app-arch/unzip"
RDEPEND=""

pkg_nofetch() {
	einfo
	einfo "Please download ${SRC_URI} from:"
	einfo "${HOMEPAGE}"
	einfo "and put it into /usr/portage/distfiles/."
	einfo
}

src_unpack() {
	unzip "${DISTDIR}/${SRC_URI}" || die "unzip failed"
}

src_install() {
	if use amd64 ; then
		newsbin "x86_64/cli64" "${PN}"
	elif use x86 ; then
		newsbin "i386/cli32" "${PN}"
	else
		eerror "Invalid ARCH, there are no Areca tools for you!"
	fi
}
