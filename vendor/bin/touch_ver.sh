#!/vendor/bin/sh
# Copyright (C) 2018 ZIH Corp and/or its affiliates. All rights reserved.

filepath=/persist/touch_ver
new_config_ver=$(hbtp_daemon tool sendCommand version | tail -n 13 | head -n 1 | cut -d : -f2 | cut -c 2-)

if [ -f "$filepath" ]; then
	config_ver=$(cat $filepath)
fi

if [ -z "$config_ver" ] || [ "$new_config_ver" != "$config_ver" ]; then
	echo "Create a touch version"
	echo "$new_config_ver" > $filepath
	chown system:system $filepath
fi
