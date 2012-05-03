# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="password management program"
HOMEPAGE="http://pwman.sourceforge.net/"
SRC_URI="http://prdownloads.sourceforge.net/pwman/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${P}.tar.gz
	cd "${S}"
}

src_compile() {
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
}
