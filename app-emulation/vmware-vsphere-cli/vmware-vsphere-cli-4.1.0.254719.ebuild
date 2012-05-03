# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

EAPI="2"

inherit eutils perl-module versionator

MY_PV=$(replace_version_separator 3 '-' )
MY_PN="VMware-vSphere-CLI-${MY_PV}"

DESCRIPTION="VMware vSphere Command-Line Interface"
HOMEPAGE="http://www.vmware.com/"
SRC_URI=" x86? ( mirror://vmware/software/vmserver/${MY_PN}.i386.tar.gz )
		amd64? ( mirror://vmware/software/vmserver/${MY_PN}.x86_64.tar.gz ) "

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* ~x86 ~amd64"
RESTRICT="strip"

DEPEND="
	>=dev-lang/perl-5
	dev-libs/expat
	dev-libs/glib
	dev-libs/libxml2
	dev-libs/openssl
	dev-perl/Archive-Zip
	dev-perl/Class-MethodMaker
	dev-perl/Crypt-SSLeay
	dev-perl/Data-Dump
	dev-perl/Data-Dumper-Concise
	dev-perl/HTML-Parser
	dev-perl/SOAP-Lite
	dev-perl/URI
	dev-perl/Data-UUID
	dev-perl/XML-LibXML
	dev-perl/XML-NamespaceSupport
	dev-perl/XML-SAX
	dev-perl/libwww-perl
	dev-perl/libxml-perl
	perl-core/Compress-Raw-Zlib
	perl-core/IO-Compress
	perl-core/version
	sys-fs/e2fsprogs
	sys-libs/zlib"
#	!app-emulation/vmware-server
#	!app-emulation/vmware-vix
#	!app-emulation/vmware-workstation"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${PN}-distrib

pkg_setup() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi
}

src_prepare() {
	VMWARE_GROUP=${VMWARE_GROUP:-vmware}
	VMWARE_INSTALL_DIR=/opt/${PN//-//}

	shortname="vcli"
	product="vmware-vcli"
	config_dir="/etc/vmware-vcli"
	product_name="vSphere CLI"

	enewgroup ${VMWARE_GROUP}

	sed -i.bak -e "s:/sbin/lsmod:/bin/lsmod:" "${S}"/installer/services.sh || die "sed of services"

	# We won't want any perl scripts from VMware
	rm -f *.pl bin/*.pl
	rm -f etc/installer.sh

	epatch "${FILESDIR}"/makefile.patch

	perl-module_src_prepare || die
}

src_install() {
	# We loop through our directories and copy everything to our system.
	for x in apps bin
	do
		if [[ -e "${S}"/${x} ]]
		then
			dodir "${VMWARE_INSTALL_DIR}"/${x}
			cp -pPR "${S}"/${x}/* "${D}""${VMWARE_INSTALL_DIR}"/${x} || die "copying ${x}"
		fi
	done

	perl-module_src_install || die

	# init script
	if [[ -e "${FILESDIR}/${PN}.rc" ]]
	then
		newinitd "${FILESDIR}"/${PN}.rc ${product} || die "newinitd"
	fi

	# create the environment
	local envd="${T}/90vmware-cli"
	cat > "${envd}" <<-EOF
		PATH='${VMWARE_INSTALL_DIR}/bin'
		ROOTPATH='${VMWARE_INSTALL_DIR}/bin'
	EOF
	doenvd "${envd}"

	# Last, we check for any mime files.
	if [[ -e "${FILESDIR}/${PN}.xml" ]]
	then
		insinto /usr/share/mime/packages
		doins "${FILESDIR}"/${PN}.xml || die "mimetypes"
	fi

	if [[ -e doc/EULA ]]
	then
		insinto "${VMWARE_INSTALL_DIR}"/doc
		doins doc/EULA || die "copying EULA"
	fi

	doman man/*

	# create the configuration
	#dodir "${config_dir}"

}

pkg_postinst() {
	[[ -d "${config_dir}" ]] && chown -R root:${VMWARE_GROUP} ${config_dir}

	ewarn "In order to run ${product_name}, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
}
