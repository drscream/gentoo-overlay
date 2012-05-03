# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

SLOT="0"
DESCRIPTION="allow program to run at most a specified amount of time"
HOMEPAGE="http://mathias-kettner.de/waitmax.html"
SRC_URI="http://mathias-kettner.de/download/${P}.tar.gz"
LICENSE="|| ( GPL-2 less )"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

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

