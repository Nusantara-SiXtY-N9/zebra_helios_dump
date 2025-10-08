#!/vendor/bin/sh
# Copyright (C) 2019-2021 Zebra Technologies Corporation and/or its affiliates. All rights reserved.

#for Atmel
TOUCH_PATH="/sys/bus/i2c/devices/4-004b"
TOUCH_PANEL_TYPE=`getprop ro.config.device.touch`
DEVICE_IDENTIFIER=`getprop ro.config.device.model`
#for Cypress
if [ "$TOUCH_PANEL_TYPE" -eq "512" ]; then
    TOUCH_PATH="/sys/bus/i2c/devices/4-0024"
fi
if [ "$TOUCH_PANEL_TYPE" -eq "16384" ]; then
    TOUCH_PATH="/sys/bus/i2c/devices/4-004a"
fi
TOUCH_MODE_FILE_PATH="$TOUCH_PATH/switch_cfg"
TOUCH_FW="$(cat $TOUCH_PATH/fw_version)"
ISFIRST_BOOT=`getprop persist.sys.reboot_count`
FIRST_BOOT_DEFAULTER=`getprop persist.sys.firstboot.tc_dafault.complete`
TOUCH_PANEL_TYPE=`getprop ro.config.device.touch`
DEVICE_MODEL=`getprop ro.config.device.model`

FOCALTECH_TOUCH_PATH="/sys/bus/i2c/devices/4-0038/fts_glove_mode"

check_valid_mode()
{
    mode_check=$1
    mode_info=$2

    if [ -z "$mode_check" ] || [ -z "$mode_info" ]; then
        echo "Warnning: Can not get mode_check or mode_info !!"
        return
    fi

    i=1
    unset v_prev
    while [ "$IS_VALID_TOUCH_MODE" == "false" ]; do
        v=$(echo "$mode_info" | cut -f$i -d"&")
        if [ -z "$v" ] || ([ -n "$v_prev" ] && [ "$v" == "$v_prev" ]); then
            break
        elif [ "$mode_check" == "$v" ]; then
            IS_VALID_TOUCH_MODE="true"
            break
        fi
        v_prev=$v
        let i++
    done
}

check_prop_touch_mode()
{
    mode_check=$1
    IS_VALID_TOUCH_MODE="false"

    check_valid_mode $mode_check `getprop ro.supported.touch_modes`
#    check_valid_mode $mode_check `getprop ro.valid_touch_mode_additional`
    if [ "$IS_VALID_TOUCH_MODE" != "true" ]; then
        echo "Err: Can not use the property for $mode_check !!"
        exit
    fi
}

set_prop_touch_mode()
{
    mode_set=$1

    check_prop_touch_mode $mode_set
    setprop persist.sys.touch_mode $mode_set
}

set_prop_fb_default()
{
    mode_set=$1
    setprop persist.sys.firstboot.tc_dafault.complete $mode_set
}


get_curr_touch_mode()
{
        cfg_mode="$(cat $TOUCH_CFG | cut -f5 -d" ")_"$(cat $TOUCH_CFG | cut -f9 -d" ")

        case $cfg_mode in
                Stylus_0) CURR_MODE="stylus_and_finger"; ;;
                Glove_0)  CURR_MODE="glove_and_finger"; ;;
                Finger_0) CURR_MODE="finger"; ;;
                Stylus_1) CURR_MODE="overlay_stylus_and_finger"; ;;
                Glove_1)  CURR_MODE="overlay_glove_and_finger"; ;;
        esac
        /vendor/bin/log -t $LOG_TAG -p i "current touch mode is "
        /vendor/bin/log -t $LOG_TAG -p i "$CURR_MODE"

}

switch_config_touch_mode_FOCALTECH()
{
    touch_mode=`getprop persist.sys.touch_mode`

    if [ "$touch_mode" = "finger" ]; then
        echo 0 > $FOCALTECH_TOUCH_PATH
    else
        echo 1 > $FOCALTECH_TOUCH_PATH
    fi
}

switch_config_touch_mode()
{
    touch_mode=`getprop persist.sys.touch_mode`
    check_prop_touch_mode $touch_mode
    if [ ! -w "$TOUCH_MODE_FILE_PATH" ]; then
        # TOUCH_MODE_FILE_PATH don't have write permission
        return
    fi

    if [ "$touch_mode" = "stylus_and_finger" ]; then
        echo stylus > $TOUCH_MODE_FILE_PATH
    elif [ "$touch_mode" = "glove_and_finger" ]; then
        echo glove > $TOUCH_MODE_FILE_PATH
    elif [ "$touch_mode" = "finger" ];then
        echo finger > $TOUCH_MODE_FILE_PATH
    elif [ "$touch_mode" = "overlay_stylus_and_finger" ];then
        echo overlay_stylus > $TOUCH_MODE_FILE_PATH
    elif [ "$touch_mode" = "overlay_glove_and_finger" ];then
        echo overlay_glove > $TOUCH_MODE_FILE_PATH
    fi
}

switch_config_touch_mode_Raven()
{
    touch_status=$(getprop persist.sys.touch_status)

    if test "$touch_status" = "update" ;then
        setprop persist.sys.touch_status loading
    else
        setprop persist.sys.touch_status null
        return
    fi

    touch_mode=$(getprop persist.sys.touch_mode)

    echo 1 > /sys/bus/i2c/devices/4-0024/manual_upgrade
    sleep 1
    echo 1 > /sys/bus/i2c/devices/4-0024/firmware/cyttsp5_fw_manual_upgrade/loading
    sleep 2

    if [ "$touch_mode" == "finger" ]; then
        cat /vendor/firmware/cypress_fw_v18_finger.bin > /sys/bus/i2c/devices/4-0024/firmware/cyttsp5_fw_manual_upgrade/data
    else
        cat /vendor/firmware/cypress_fw_v17_all.bin > /sys/bus/i2c/devices/4-0024/firmware/cyttsp5_fw_manual_upgrade/data
    fi

    STATUS=$?

    sleep 1
    echo 0 > /sys/bus/i2c/devices/4-0024/firmware/cyttsp5_fw_manual_upgrade/loading

    if [ $STATUS -ne 0 ]; then
        setprop persist.sys.touch_status error
    else
        sleep 10
        setprop persist.sys.touch_status success
    fi
}

switch_config_touch_mode_synaptics()
{
    touch_mode=$(getprop persist.sys.touch_mode)

    IS_VALID_TOUCH_PATH="false"
    i=1

    IS_VALID_TOUCH_FW_PATH="false"
    j=1

    while [ "$IS_VALID_TOUCH_PATH" == "false" ]; do
        if [ -f "/sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$i/switch_cfg" ]; then
            IS_VALID_TOUCH_PATH="true"
            break
        fi
        let i++
    done

    if [ ! -w "/sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$i/switch_cfg" ]; then
        return
    fi

    if [ "$touch_mode" == "finger" ]; then
        echo 0 > /sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$i/switch_cfg
    elif [ "$touch_mode" == "stylus_and_finger" ]; then
        echo 1 > /sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$i/switch_cfg
    elif [ "$touch_mode" == "glove_and_finger" ]; then
        echo 2 > /sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$i/switch_cfg
    fi

    while [ "$IS_VALID_TOUCH_FW_PATH" == "false" ]; do
        if [ -f "/sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$j/config_id" ]; then
            IS_VALID_TOUCH_FW_PATH="true"
            synaptics_fw_version="$(cat /sys/devices/platform/soc/c178000.i2c/i2c-4/4-0020/input/input$j/config_id)"
            substr=$(echo $synaptics_fw_version | cut -c1-10)
            setprop persist.synaptics.fw.version $substr
            break
        fi
        let j++
    done
}

switch_config_touch_mode_eeti()
{
    touch_mode=$(getprop persist.sys.touch_mode)

    if [ "$touch_mode" == "finger" ]; then
        LD_LIBRARY_PATH=/system/lib eGloveSwitch -s 0
    elif [ "$touch_mode" == "glove_and_finger" ]; then
        LD_LIBRARY_PATH=/system/lib eGloveSwitch -s 1
    elif [ "$touch_mode" == "stylus_and_finger" ]; then
        LD_LIBRARY_PATH=/system/lib eGloveSwitch -s 2
        echo glove > $TOUCH_MODE_FILE_PATH
    fi
}
switch_config_touch_mode_cypress()
{
    touch_mode=$(getprop persist.sys.touch_mode)

    if [ "$touch_mode" = "stylus_and_finger" ]; then
        echo stylus > $TOUCH_MODE_FILE_PATH
    elif [ "$touch_mode" = "glove_and_finger" ]; then
        echo glove > $TOUCH_MODE_FILE_PATH
    fi
}


# Set default mode on system first boot
#if [ "$ISFIRST_BOOT" -eq "1" ]; then
#    if [ "$FIRST_BOOT_DEFAULTER" -eq "false" ]; then
#        case $TOUCH_PANEL_TYPE in
#            512|Cypress)
#                if [ "$DEVICE_IDENTIFIER" = "3310" ]; then
#                    # For Elektra device
#                    set_prop_touch_mode stylus_and_finger;
#                    set_prop_fb_default true;
#                elif [ "$DEVICE_IDENTIFIER" = "3350" ]; then
#                    # For DareDevil device
#                    set_prop_touch_mode stylus_and_finger;
#                    set_prop_fb_default true;
#                fi
#                return;
#                ;;
#            32768|EETI)
#                if [ "$DEVICE_IDENTIFIER" = "32768" ]; then
#                    # For DareDevil device
#                    set_prop_touch_mode stylus_and_finger;
#                    set_prop_fb_default true;
#                fi
#                return;
#                ;;
#        esac
#    fi
#fi

vendor_touch_mode=`getprop persist.vendor.sys.touch_mode`
if [ "$vendor_touch_mode" != "skip" ]; then
    setprop persist.sys.touch_mode $vendor_touch_mode
    setprop persist.vendor.sys.touch_mode skip
fi

# Touch panel is not supported. Only set the property
case $TOUCH_PANEL_TYPE in
    1024|ImproveTouch)
    # 1024 is for devices with Improved-Touch Displays
        set_prop_touch_mode overlay_glove_and_finger;
        return
        ;;
    512|Cypress)
    # 512 is for devices with Cypress Touch
        if [ "$DEVICE_MODEL" -eq "8300" ]; then
            switch_config_touch_mode_Raven
            return
        else
            switch_config_touch_mode_cypress
            return
        fi
        ;;
    2048|FOCALTECH_FT7311)
    # 2048 is for devices with FOCALTECH_FT7311 Touch
        switch_config_touch_mode_FOCALTECH
        return
        ;;
    2049|FOCALTECH_FT8006)
    # 2049 is for devices with FOCALTECH_FT8006 Touch
        switch_config_touch_mode_FOCALTECH
        return
        ;;
    32768|EETI)
    # 32768 is for devices with EETI Touch
        switch_config_touch_mode_eeti
        return
        ;;
    32770|EETI)
    # 32770 is for devices with EETI Touch
        switch_config_touch_mode_eeti
        return
        ;;
    65536|Synaptics)
    # 65536 is for devices with Synaptics Touch
        switch_config_touch_mode_synaptics
        return
        ;;
esac


if ["$TOUCH_PANEL_TYPE" -eq "512" ]; then
    switch_config_touch_mode_cypress
else
    switch_config_touch_mode
fi
