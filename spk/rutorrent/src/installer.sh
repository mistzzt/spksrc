#!/bin/sh

# Package
PACKAGE="rutorrent"
DNAME="ruTorrent"

# Others
INSTALL_DIR="/usr/local/${PACKAGE}"
WEB_DIR="/var/services/web"
SSS="/var/packages/${PACKAGE}/scripts/start-stop-status"
PATH="${INSTALL_DIR}/bin:${INSTALL_DIR}/usr/bin:${PATH}"
USER="rutorrent"
GROUP="users"
APACHE_USER="nobody"
TMP_DIR="${SYNOPKG_PKGDEST}/../../@tmp"


preinst ()
{
    exit 0
}

postinst ()
{
    # Link
    ln -s ${SYNOPKG_PKGDEST} ${INSTALL_DIR}

    # Install busybox stuff
    ${INSTALL_DIR}/bin/busybox --install ${INSTALL_DIR}/bin

    # Install the web interface
    cp -R ${INSTALL_DIR}/share/${PACKAGE} ${WEB_DIR}

    # Create user
    adduser -h ${INSTALL_DIR}/var -g "${DNAME} User" -G ${GROUP} -s /bin/sh -S -D ${USER}

    # Configure files
    if [ "${SYNOPKG_PKG_STATUS}" == "INSTALL" ]; then
        TOP_DIR=`echo "${wizard_download_dir:=/volume1/downloads}" | cut -d "/" -f 2`

        sed -i -e "s|scgi_port = 5000;|scgi_port = 8050;|g" ${WEB_DIR}/${PACKAGE}/conf/config.php
        sed -i -e "s|topDirectory = '/';|topDirectory = '/${TOP_DIR}/';|g" ${WEB_DIR}/${PACKAGE}/conf/config.php

        echo "XSendFile On" > ${WEB_DIR}/${PACKAGE}/.htaccess

        sed -i -e "s|@download_dir@|${wizard_download_dir:=/volume1/downloads}|g" ${INSTALL_DIR}/var/.rtorrent.rc

        if [ -d "${wizard_watch_dir}" ]; then
            sed -i -e "s|@watch_dir@|${wizard_watch_dir}|g" ${INSTALL_DIR}/var/.rtorrent.rc
        else
            sed -i -e "/@watch_dir@/d" ${INSTALL_DIR}/var/.rtorrent.rc
        fi
    fi

    # Create session directory
    mkdir -p ${wizard_download_dir:=/volume1/downloads}/.rtorrent

    # Correct the files ownership
    chown -R ${USER}:root ${SYNOPKG_PKGDEST}
    chown -R ${USER}:root ${wizard_download_dir:=/volume1/downloads}/.rtorrent
    chown -R ${APACHE_USER} ${WEB_DIR}/${PACKAGE}

    exit 0
}

preuninst ()
{
    # Stop the package
    ${SSS} stop > /dev/null

    # Remove the user (if not upgrading)
    if [ "${SYNOPKG_PKG_STATUS}" != "UPGRADE" ]; then
        delgroup ${USER} ${GROUP}
        deluser ${USER}
    fi

    exit 0
}

postuninst ()
{
    # Remove link
    rm -f ${INSTALL_DIR}

    # Remove the web interface
    rm -fr ${WEB_DIR}/${PACKAGE}

    exit 0
}

preupgrade ()
{
    # Stop the package
    ${SSS} stop > /dev/null

    # Save the configuration file
    rm -fr ${TMP_DIR}/${PACKAGE}
    mkdir -p ${TMP_DIR}/${PACKAGE}
    mv ${WEB_DIR}/${PACKAGE}/conf/config.php ${TMP_DIR}/${PACKAGE}/
    mv ${WEB_DIR}/${PACKAGE}/.htaccess ${TMP_DIR}/${PACKAGE}/
    mv ${INSTALL_DIR}/var/.rtorrent.rc ${TMP_DIR}/${PACKAGE}/

    exit 0
}

postupgrade ()
{
    # Restore the configuration file
    mv ${TMP_DIR}/${PACKAGE}/config.php ${WEB_DIR}/${PACKAGE}/conf/
    mv ${TMP_DIR}/${PACKAGE}/.htaccess ${WEB_DIR}/${PACKAGE}/
    mv ${TMP_DIR}/${PACKAGE}/.rtorrent.rc ${INSTALL_DIR}/var/
    rm -fr ${TMP_DIR}/${PACKAGE}

    exit 0
}