#!/vendor/bin/sh
# Copyright (c) 2020 Zebra Technologies Corporation and/or its affiliates. All rights reserved.
#
# subsys_ssr.sh [subsystem name] [level]

show_usage() {
  echo subsys_ssr.sh [subsystem name] [restart level]
}

setprop persist.vendor.sys.modem_ssr 0

if [[ $# -gt 3 || $# -eq 0 ]]; then
  show_usage
  exit 1
fi

target_name=$1

if [ $# -eq 2 ]; then

  if [[ $2 != "system" && "$2" != "related" ]]; then
    echo "level should be system or related"
    exit 1
  fi
  target_lvl=$2
else
  target_lvl='RELATED'
fi

log -t subsys_ssr "doing $target_name SSR with level $target_lvl"

subs=`ls /sys/bus/msm_subsys/devices/`

for sub in $subs
do
  name=`cat /sys/bus/msm_subsys/devices/${sub}/name`
  if [ "$name" == "$target_name" ]; then
    lvl=`cat /sys/bus/msm_subsys/devices/${sub}/restart_level`
    if [ "$lvl" != "$target_lvl" ]; then
      echo $target_lvl > /sys/bus/msm_subsys/devices/${sub}/restart_level
    fi
    log -t subsys_ssr "restarting $name"
    echo 1 > /sys/module/subsystem_restart/parameters/restart_modem
    while true; do
      sleep 1
      state=`cat /sys/bus/msm_subsys/devices/${sub}/state`
      if [ "$state" == "ONLINE" ]; then
        break;
      fi
    done

    if [ "$lvl" != "$target_lvl" ]; then
      echo $lvl > /sys/bus/msm_subsys/devices/${sub}/restart_level
    fi
    exit 0
  fi
done

log -t subsys_ssr "restarted $name"

exit 1

