#!/bin/sh

CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"
CMD_MKDIR="/bin/mkdir"
PUBLIC_SHARE=$($CMD_GETCFG SHARE_DEF defPublic -d Public -f /etc/config/def_share.info)
MULTIMEDIA=$($CMD_GETCFG SHARE_DEF defMultimedia -d Multimedia -f /etc/config/def_share.info)

SYS_QPKG_DIR=$($CMD_GETCFG SickRage Install_Path -f /etc/config/qpkg.conf)
SAB_INSTALLED=$($CMD_GETCFG SABnzbdPlus Status -f /etc/config/qpkg.conf)
SAB_LINKED=$($CMD_GETCFG General linked_to_sabnzbd -f ${SYS_QPKG_DIR}/.sickrage/sabnzbd_link.ini)

# Exit if SickRage is already linked with SABnzbdPlus
if [ -n ${SAB_LINKED} ] && [ "${SAB_LINKED}" = "1" ] ; then 
  #echo "SickRage is already linked to SABnzbdPlus"
  exit 1
fi

# Determine BASE installation location according to smb.conf
BASE=
publicdir=`/sbin/getcfg $PUBLIC_SHARE path -f /etc/config/smb.conf`
if [ ! -z $publicdir ] && [ -d $publicdir ];then
  publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
  publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
  publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
  if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
    [ -d "/${publicdirp1}/${publicdirp2}/${PUBLIC_SHARE}" ] && BASE="/${publicdirp1}/${publicdirp2}"
  fi
fi
####

# Determine BASE installation location by checking where the Public folder is.
if [ -z $BASE ]; then
  for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/MD0_DATA; do
    [ -d $datadirtest/$PUBLIC_SHARE ] && BASE="/${publicdirp1}/${publicdirp2}"
  done
fi
if [ -z $BASE ] ; then
  echo "The Public share not found."
  /sbin/write_log "[$QPKG_NAME] The Public share not found." 1
  exit 1
fi
####

[ -d ${SYS_QPKG_DIR}/.sickrage ] || mkdir -p ${SYS_QPKG_DIR}/.sickrage && touch ${SYS_QPKG_DIR}/.sickrage/config.ini

if [ "$SAB_INSTALLED" == "complete" ] ; then 
  # Get values from SABnzbdPlus Configs
  SABnzbdPlus_Path=$($CMD_GETCFG SABnzbdPlus Install_Path -f /etc/config/qpkg.conf)
  if [ -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini ] ; then
    SABnzbdPlus_WEBUI_HTTPS=$($CMD_GETCFG misc enable_https -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    SABnzbdPlus_WEBUI_IP=$($CMD_GETCFG misc host -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    if [ "$SABnzbdPlus_WEBUI_HTTPS" = "0" ]; then
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc port -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
      $CMD_SETCFG SABnzbd sab_host http://${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT}/ -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    else
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc https_port -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
      #$CMD_SETCFG SABnzbd ssl 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
      $CMD_SETCFG SABnzbd sab_host https://${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT}/ -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    fi
    SABnzbdPlus_USER=$($CMD_GETCFG misc username -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    SABnzbdPlus_PASS=$($CMD_GETCFG misc password -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    SABnzbdPlus_APIKEY=$($CMD_GETCFG misc api_key -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)

    # Set SABnzbdPlus values in SickRage 
    #$CMD_SETCFG SABnzbd enabled 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG SABnzbd sab_username ${SABnzbdPlus_USER} -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG SABnzbd sab_password ${SABnzbdPlus_PASS} -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG SABnzbd sab_apikey ${SABnzbdPlus_APIKEY} -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG SABnzbd sab_category TV -f ${SYS_QPKG_DIR}/.sickrage/config.ini

    # Set Post Processing values based on SABnzbdPlus values
    [ -d ${BASE}/${MULTIMEDIA}/TV ] || $CMD_MKDIR -p ${BASE}/${MULTIMEDIA}/TV
    $CMD_SETCFG General enabled 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General tv_download_dir ${BASE}/${PUBLIC_SHARE}/Downloads/complete/TV -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General process_method move -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General process_automatically 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General create_missing_show_dirs 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General use_failed_downloads 0 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    #$CMD_SETCFG General delete_failed 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini

    # Set a few defaults, assuming connecting into SABnzbdPlus and not Torrent
    $CMD_SETCFG General launch_browser 0 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General use_nzbs 1 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General use_torrents 0 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General nzb_method sabnzbd -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    #$CMD_SETCFG blackhole enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    #$CMD_SETCFG kickasstorrents enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    #$CMD_SETCFG torrentz enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    #$CMD_SETCFG searcher preferred_method nzb -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Disable the SickRage Updater and setup Wizard
    $CMD_SETCFG General auto_update 0 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    $CMD_SETCFG General version_notify 0 -f ${SYS_QPKG_DIR}/.sickrage/config.ini
    
    #$CMD_SETCFG updater automatic 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    #$CMD_SETCFG core show_wizard 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Set SickRage as linked to SABnzbdPlus
    $CMD_SETCFG General linked_to_sabnzbd 1 -f ${SYS_QPKG_DIR}/.sickrage/sabnzbd_link.ini
  fi
fi

exit 0
