#!/vendor/bin/sh
# Copyright (c) 2020 Zebra Technologies Corporation and/or its affiliates. All rights reserved.
#
# secure_wakelock.sh [subsystem name] [level]

show_usage() {
  echo secure_wakelock.sh [wakelock mode]
}

if [[ $# -gt 3 || $# -eq 0 ]]; then
  show_usage
  exit 1
fi

target_mode=$1

if [ $# -eq 1 ]; then

  if [[ "$target_mode" != "acquire" && "$target_mode" != "release" ]]; then
    echo "mode should be acquire or release"
    exit 1
  fi
fi

log -t secure_wakelock "Doing secure_wake_lock $target_mode "

if [ "$target_mode" == "acquire" ]; then
  echo "secure_wake_lock" > /sys/power/wake_lock
  setprop sys.secure_lock acquire
  log -t secure_wakelock "secure_wake_lock acquired"
  echo "secure_wake_lock acquired"
  exit 0
fi

if [ "$target_mode" == "release" ]; then
  echo "secure_wake_lock" > /sys/power/wake_unlock
  setprop sys.secure_lock released
  log -t secure_wakelock "secure_wake_lock released"
  echo "secure_wake_lock released"
  exit 0
fi

exit 1
