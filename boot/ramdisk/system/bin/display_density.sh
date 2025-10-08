#! /system/bin/sh
# Copyright (c) 2021 Zebra Technologies Corporation and/or its affiliates. All rights reserved.

if [ -f /sys/class/drm/card0-DSI-1/modes ]; then
    echo "detect" > /sys/class/drm/card0-DSI-1/status
    mode_file=/sys/class/drm/card0-DSI-1/modes
    while read line; do
        fb_width=${line%%x*};
        break;
    done < $mode_file
elif [ -f /sys/class/graphics/fb0/virtual_size ]; then
    res=`cat /sys/class/graphics/fb0/virtual_size` 2> /dev/null
    fb_width=${res%,*}
fi

#put default density based on width
if [ -z $fb_width ]; then
     if [ $is_dp_mode -eq 1 ]; then
         return;
     fi
     setprop vendor.display.lcd_density 320
 else
     if [ $fb_width -ge 1600 ]; then
        setprop vendor.display.lcd_density 640
     elif [ $fb_width -ge 1440 ]; then
        setprop vendor.display.lcd_density 560
     elif [ $fb_width -ge 1080 ]; then
        setprop vendor.display.lcd_density 480
     elif [ $fb_width -ge 720 ]; then
        setprop vendor.display.lcd_density 320 #for 720X1280 resolution
     elif [ $fb_width -ge 480 ]; then
         setprop vendor.display.lcd_density 240 #for 480X854 QRD resolution
     else
         setprop vendor.display.lcd_density 160
     fi
fi
