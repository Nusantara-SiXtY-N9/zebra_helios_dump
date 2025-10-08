#!/vendor/bin/sh

usb_config=`getprop persist.vendor.usb.config`
if [ 1 ]; then
    case "$usb_config" in
    *adb*)
        setprop persist.vendor.usb.config "diag,serial_cdev,rmnet,adb"
      ;;
     *)
       setprop persist.vendor.usb.config "diag,serial_cdev,rmnet"
      ;;
    esac

     usb_config=`getprop persist.vendor.usb.config`
     comp=`getprop sys.usb.config`
     if [ "$comp" != "$usb_config" ]; then
         log -p v -t "$0" "setting sys.usb.config"
         setprop sys.usb.config $usb_config
     fi
fi
setprop persist.sys.usb.config $(getprop persist.vendor.usb.config)
