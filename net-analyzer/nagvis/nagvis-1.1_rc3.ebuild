# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
inherit eutils 

MY_PV=${PV/_rc/rc}
MY_P=${PN}-${MY_PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="NagVis is a visualization addon for the well known network
managment system Nagios."
HOMEPAGE="http://www.nagvis.org/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="apache2 gd mysql"

DEPEND="net-analyzer/nagios-core
		>=net-analyzer/ndoutils-1.4_beta4
		virtual/httpd-php"

pkg_setup() {
	ewarn "checking for use flags, may take a while"

	if ( ! built_with_use dev-lang/php apache2 ) ; then
		die "You MUST build dev-lang/php with the apache2 USE flag"
	fi

	if ( ! built_with_use dev-lang/php gd ) ; then
		die "You MUST build dev-lang/php with the gd USE flag"
	fi

	if ( ! built_with_use dev-lang/php mysql ) ; then
		die "You MUST build dev-lang/php with the mysql USE flag"
	fi
}

src_compile() {
	return
}

src_install() {
	for docfile in README INSTALL LICENCE
	do
		dodoc ${S}/${docfile}
		rm ${S}/${docfile}
	done
	
	dodir /usr/nagios/share
	grep -Rl "/usr/local" ${S}/* | xargs sed -i s:/usr/local:/usr:g
	mv "${S}" "${D}"/usr/nagios/share/nagvis
	chown -R apache:apache "${D}"/usr/nagios/share/nagvis
	chmod 664 "${D}"/usr/nagios/share/nagvis/nagvis/etc/config.ini.php.dist
	chmod 775 "${D}"/usr/nagios/share/nagvis/nagvis/images/maps
	chmod 664 "${D}"/usr/nagios/share/nagvis/nagvis/images/maps/*
	chmod 775 "${D}"/usr/nagios/share/nagvis/nagvis/etc/maps
	chmod 664 "${D}"/usr/nagios/share/nagvis/nagvis/etc/maps/*
}
pkg_postinst() {
	elog "Before running NagVis for the first time, you will need to set up"
	elog "/usr/nagios/share/nagvis/nagvis/etc/config.ini.php"
	elog "A sample is in"
	elog "/usr/nagios/share/nagvis/nagvis/etc/config.ini.php.dist"
}


