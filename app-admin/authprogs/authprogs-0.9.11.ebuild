# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

DESCRIPTION="ssh forced command authenticator (with parameter patch)"
HOMEPAGE="http://mirrors.gentoo.avira.com/avira-tt/projects/authprogs-0.9.11.html"
SRC_URI="http://mirrors.gentoo.avira.com/avira-tt/distfiles/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

RDEPEND="virtual/ssh"
DEPEND="${RDEPEND}"

src_compile() {
	cd ${S}
	emake || die
}

src_install() {
	dobin ${S}/authprogs
}
