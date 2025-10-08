#!/vendor/bin/sh
# Copyright (C) 2018-2020 Zebra Technologies Corporation and/or its affiliates.All rights reserved.
filepath=/mnt/vendor/persist/wlan_mac.bin

if [ -f "$filepath" ]; then
    echo "There is wlan_mac.bin"
    macaddr=`cat /mnt/vendor/persist/wlan_mac.bin`
#    echo $macaddr
    substr=$(echo $macaddr | cut -c17-18):
    substr+=$(echo $macaddr | cut -c19-20):
    substr+=$(echo $macaddr | cut -c21-22):
    substr+=$(echo $macaddr | cut -c23-24):
    substr+=$(echo $macaddr | cut -c25-26):
    substr+=$(echo $macaddr | cut -c27-28)
    echo "Wifi MAC="$substr
else
    echo "There is no wlan_mac.bin, try to write one"
    bootwifimac=`getprop ro.boot.device.wifi_mac`
    if [ -n "$bootwifimac" ]; then
        echo "ro.boot.device.wifi_mac"=$bootwifimac
        echo "Intf0MacAddress="$bootwifimac > $filepath
        echo END >> $filepath

        substr0=$(echo $bootwifimac | cut -c1-2):
        substr0+=$(echo $bootwifimac | cut -c3-4):
        substr0+=$(echo $bootwifimac | cut -c5-6):
        substr0+=$(echo $bootwifimac | cut -c7-8):
        substr0+=$(echo $bootwifimac | cut -c9-10):
        substr0+=$(echo $bootwifimac | cut -c11-12)
        echo "Wifi MAC="$substr0
    else
        echo "No property ro.boot.device.wifi_mac"
    fi
fi
