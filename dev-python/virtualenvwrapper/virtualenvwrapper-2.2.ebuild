# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit distutils

DESCRIPTION="Enhancements to virtualenv"
HOMEPAGE="http://www.doughellmann.com/projects/virtualenvwrapper/"
SRC_URI="http://www.doughellmann.com/downloads/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc"

LANGS="en es"

for X in ${LANGS} ; do
	IUSE="${IUSE} linguas_${X}"
done

DEPEND="dev-python/virtualenv"
RDEPEND="${DEPEND}"

src_install() {
	distutils_src_install

	if use doc; then
		for lang in ${LINGUAS}; do
			insinto /usr/share/doc/${PF}/${lang}
			doins -r docs/html/${lang}/* || die
		done
	fi
}
