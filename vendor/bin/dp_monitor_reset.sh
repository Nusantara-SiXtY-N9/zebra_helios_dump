#!/vendor/bin/sh
# Copyright (C) 2022-2023 Zebra Technologies Corporation and/or its affiliates. All rights reserved.
gpiofolder=/sys/class/gpio
reset_prop=persist.vendor.monitor.reset
undock_prop=persist.vendor.monitor.undock
dock_prop=persist.vendor.monitor.dock
persist_prop_val=`getprop $reset_prop`
undock_prop_val=`getprop $undock_prop`
dock_prop_val=`getprop $dock_prop`
labels=null
dk5v_en=13
platform_label=3000000.pinctrl

cd $gpiofolder
for dir in gpiochip*
do
    [[ -d "$dir" ]]
    cd "$dir";
    labeltxt=$(cat label);
    if [[ "$labeltxt" = *$platform_label* ]];then
        echo $labeltxt;
        labels=/sys/class/gpio/$dir/label ;
        basefile=/sys/class/gpio/$dir/;
        echo $labels $basefile;
    fi
    cd ..;
done
if [ "$labels" = "null" ] ; then
 echo "no device found. Ending...."
 exit 1
fi

if [[ "$labeltxt" = *$platform_label* ]]; then
    basenum=$(cat $basefile/base)
    echo $basenum
    gpio_reset=$(($basenum + $dk5v_en))
    echo $gpio_reset
    dock_status=$(cat $gpiofolder/"gpio"$gpio_reset/value)
    echo "dock status"
    echo $dock_status

    if [ -f "$gpiofolder/"gpio"$gpio_reset/value" ]; then
        echo "file present"
        echo $gpiofolder
    else
        echo initing
        echo $gpio_reset > $gpiofolder/export
        echo out > $gpiofolder/"gpio"$gpio_reset/direction
    fi
else
    echo "Ignoring"
    exit
fi
if [ $dock_status == 1 ] && [ $undock_prop_val == 1 ]; then
    echo "simulating undock event"
    echo 0 > $gpiofolder/"gpio"$gpio_reset/value
    setprop $undock_prop 0

elif [ $dock_status == 0 ] && [ $dock_prop_val == 1 ]; then
    echo "simulating dock event"
    echo 1 > $gpiofolder/"gpio"$gpio_reset/value
    setprop $dock_prop 0
else
    echo "do nothing"
fi


