#!/bin/sh
CONF=/etc/config/qpkg.conf
CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"
CMD_MKDIR="/bin/mkdir"

PUBLIC_SHARE=$($CMD_GETCFG SHARE_DEF defPublic -d Public -f /etc/config/def_share.info)
MULTIMEDIA=$($CMD_GETCFG SHARE_DEF defMultimedia -d Multimedia -f /etc/config/def_share.info)
QPKG_NAME="SickRage"
QPKG_ROOT=$(${CMD_GETCFG} ${QPKG_NAME} Install_Path -f ${CONF})
QPKG_DATA=${QPKG_ROOT}/.sickrage
QPKG_CONF=${QPKG_DATA}/config.ini
SAB_INSTALLED=$($CMD_GETCFG SABnzbdPlus Status -f ${CONF})
SAB_LINKED=$($CMD_GETCFG General linked_to_sabnzbd -f ${QPKG_DATA}/sabnzbd_link.ini)

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

[ -d ${QPKG_DATA} ] || mkdir -p ${QPKG_DATA} && touch ${QPKG_DATA}/sabnzbd_link.ini
[ -f ${QPKG_CONF} ] || touch ${QPKG_CONF}

if [ "$SAB_INSTALLED" == "complete" ] ; then 
  # Get values from SABnzbdPlus Configs
  SABnzbdPlus_Path=$($CMD_GETCFG SABnzbdPlus Install_Path -f ${CONF})
  SABnzbdPlus_CONF=${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini
  if [ -f ${SABnzbdPlus_CONF} ] ; then
    SABnzbdPlus_WEBUI_HTTPS=$($CMD_GETCFG misc enable_https -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_WEBUI_IP=$($CMD_GETCFG misc host -f ${SABnzbdPlus_CONF})
    if [ "$SABnzbdPlus_WEBUI_HTTPS" = "0" ]; then
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc port -f ${SABnzbdPlus_CONF})
      $CMD_SETCFG SABnzbd sab_host http://${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT}/ -f ${QPKG_CONF}
    else
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc https_port -f ${SABnzbdPlus_CONF})
      #$CMD_SETCFG SABnzbd ssl 1 -f ${QPKG_CONF}
      $CMD_SETCFG SABnzbd sab_host https://${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT}/ -f ${QPKG_CONF}
    fi
    SABnzbdPlus_USER=$($CMD_GETCFG misc username -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_PASS=$($CMD_GETCFG misc password -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_APIKEY=$($CMD_GETCFG misc api_key -f ${SABnzbdPlus_CONF})

    # Set SABnzbdPlus values in SickRage 
    #$CMD_SETCFG SABnzbd enabled 1 -f ${QPKG_CONF}
    $CMD_SETCFG SABnzbd sab_username ${SABnzbdPlus_USER} -f ${QPKG_CONF}
    $CMD_SETCFG SABnzbd sab_password ${SABnzbdPlus_PASS} -f ${QPKG_CONF}
    $CMD_SETCFG SABnzbd sab_apikey ${SABnzbdPlus_APIKEY} -f ${QPKG_CONF}
    $CMD_SETCFG SABnzbd sab_category TV -f ${QPKG_CONF}

    # Set Post Processing values based on SABnzbdPlus values
    [ -d ${BASE}/${MULTIMEDIA}/TV ] || $CMD_MKDIR -p ${BASE}/${MULTIMEDIA}/TV
    $CMD_SETCFG General enabled 1 -f ${QPKG_CONF}
    $CMD_SETCFG General tv_download_dir ${BASE}/${PUBLIC_SHARE}/Downloads/complete/TV -f ${QPKG_CONF}
    $CMD_SETCFG General process_method move -f ${QPKG_CONF}
    $CMD_SETCFG General process_automatically 1 -f ${QPKG_CONF}
    $CMD_SETCFG General create_missing_show_dirs 1 -f ${QPKG_CONF}
    $CMD_SETCFG General use_failed_downloads 0 -f ${QPKG_CONF}
    #$CMD_SETCFG General delete_failed 1 -f ${QPKG_CONF}

    # Set a few defaults, assuming connecting into SABnzbdPlus and not Torrent
    WEBUI_PORT=$(${CMD_GETCFG} General web_port -f ${QPKG_CONF})
    [ ${WEBUI_PORT} ] || ${CMD_SETCFG} General web_port 8086 -f ${QPKG_CONF} # Default to port 8086
    $CMD_SETCFG General launch_browser 0 -f ${QPKG_CONF}
    $CMD_SETCFG General use_nzbs 1 -f ${QPKG_CONF}
    $CMD_SETCFG General use_torrents 0 -f ${QPKG_CONF}
    $CMD_SETCFG General nzb_method sabnzbd -f ${QPKG_CONF}

    # Disable the SickRage Updater and setup Wizard
    $CMD_SETCFG General auto_update 0 -f ${QPKG_CONF}
    $CMD_SETCFG General version_notify 0 -f ${QPKG_CONF}

    # Set SickRage as linked to SABnzbdPlus
    $CMD_SETCFG General linked_to_sabnzbd 1 -f ${QPKG_DATA}/sabnzbd_link.ini
  fi
fi

exit 0
