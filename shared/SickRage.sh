#!/bin/sh
CONF=/etc/config/qpkg.conf
CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"

QPKG_NAME="SickRage"
QPKG_ROOT=$(${CMD_GETCFG} ${QPKG_NAME} Install_Path -f ${CONF})
PYTHON_DIR="/opt/bin"
#PATH="${QPKG_ROOT}/bin:${QPKG_ROOT}/env/bin:${PYTHON_DIR}/bin:/usr/local/bin:/bin:/usr/bin:/usr/syno/bin"
PYTHON="${PYTHON_DIR}/python2.6"

SICKRAGE="${QPKG_ROOT}/SickBeard.py"
#QPKG_DATA=${QPKG_ROOT}/.sickbeard
#QPKG_CONF=${QPKG_DATA}/settings.conf
#WEBUI_PORT=$(${CMD_GETCFG} core port -f ${QPKG_CONF})
#QPKG_PID=${QPKG_ROOT}/couchpotato-${WEBUI_PORT}.pid

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
    : ADD START ACTIONS HERE
    ;;

  stop)
    : ADD STOP ACTIONS HERE
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
