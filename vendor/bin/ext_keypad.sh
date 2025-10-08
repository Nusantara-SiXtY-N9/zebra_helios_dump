#!/vendor/bin/sh
# Copyright (C) 2020 Zebra Technologies Corporation and/or its affiliates. All rights reserved.

detectedpath=/sys/bus/platform/drivers/wtioconnector/soc:wt-iomux/rightdetected
ext_keypad=3

if [ -f "$detectedpath" ]; then
    detectedid=$(cat $detectedpath)
fi

if [ "$detectedid" == "$ext_keypad" ]; then
    setprop ro.symbol.set_ext_keypad 1
fi

