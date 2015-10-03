#!/bin/sh
CONF=/etc/config/qpkg.conf
CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"

QPKG_NAME="SickRage"
QPKG_ROOT=$(${CMD_GETCFG} ${QPKG_NAME} Install_Path -f ${CONF})
PYTHON_DIR="/usr/bin"
#PATH="${QPKG_ROOT}/bin:${QPKG_ROOT}/env/bin:${PYTHON_DIR}/bin:/usr/local/bin:/bin:/usr/bin:/usr/syno/bin"
PYTHON="${PYTHON_DIR}/python2.7"
SICKRAGE="${QPKG_ROOT}/SickBeard.py"
QPKG_DATA=${QPKG_ROOT}/.sickbeard
QPKG_CONF=${QPKG_DATA}/config.ini
WEBUI_PORT=$(${CMD_GETCFG} General web_port -f ${QPKG_CONF})
if [ -z ${WEBUI_PORT} ] ; then WEBUI_PORT="8086" ; ${CMD_SETCFG} General web_port -f ${QPKG_CONF} ; fi # Default to port 8086
QPKG_PID=${QPKG_ROOT}/sickbeard-${WEBUI_PORT}.pid

start_daemon() {
  ${PYTHON} ${SICKRAGE} --daemon --pidfile=${QPKG_PID} --port=${WEBUI_PORT} --datadir=${QPKG_DATA} --config=${QPKG_CONF}
}

stop_daemon() {
  kill $(cat ${QPKG_PID})
  wait_for_status 1 20
  if [ -f ${QPKG_PID} ] ; then rm -f ${QPKG_PID} ; fi
}

daemon_status() {
  if [ -f ${QPKG_PID} ] && [ -d /proc/$(cat ${QPKG_PID} 2>/dev/null) ]; then
    return 0
  fi
  return 1
}

wait_for_status() {
  counter=$2
  while [ ${counter} -gt 0 ]; do
    daemon_status
    [ $? -eq $1 ] && break
    let counter=counter-1
    sleep 1
  done
}

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi

    if daemon_status; then
      echo "${QPKG_NAME} is already running"
    else
      #echo "Checking if ${QPKG_NAME} is linked to SABnzbdPlus"
      ${QPKG_ROOT}/link_to_SAB.sh
      echo "Starting ${QPKG_NAME} ..."
      start_daemon
    fi
    ;;

  stop)
    if daemon_status; then
      echo "Stopping ${QPKG_NAME} ..."
      stop_daemon
    else
      echo "${QPKG_NAME} is not running"
    fi
    ;;

  status)
    if daemon_status; then
      echo "${QPKG_NAME} is running"
      exit 0
    else
      echo "${QPKG_NAME} is not running"
      exit 1
    fi
    ;;

  relink)
    ${CMD_SETCFG} core linked_to_sabnzbd 0 -f ${QPKG_CONF}
    echo "relinking ${QPKG_NAME} to SABnzbdPlus"
    ${QPKG_ROOT}/link_to_SAB.sh
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
