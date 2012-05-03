# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: nagios-plugins-check-rdiff-0.1.ebuild 72 2008-09-11 08:27:19Z georg.weiss $

inherit eutils

DESCRIPTION="a nagios plugin which checks status of a rdiff-backup repository"
HOMEPAGE=""
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=""
RDEPEND="dev-lang/perl
app-backup/rdiff-backup"

src_unpack() {
	: NOP
}

src_compile() {
	: NOP
}

pkg_setup() {
	enewgroup nagios
	enewuser nagios -1 /bin/bash /home/nagios nagios
}

src_install() {
	dodir /usr/nagios/libexec/
	exeinto /usr/nagios/libexec/
	doexe ${FILESDIR}/check_rdiff
	chown root:nagios "${D}"/usr/nagios/libexec/check_rdiff
	chmod 750 "${D}"/usr/nagios/libexec/check_rdiff
}
