# Copyright (C) 2021-2024 Zebra Technologies Corporation and/or its affiliates.All rights reserved.

DEBUG="yes"
MAX_LOG_FILE_SIZE=10000000 #10MB
SCRIPT_LIFE_SPAN=60
LOCK_FILE="/data/local/tmp/fusion_restart_wifi.lock"
LOG_FILE="/data/local/tmp/fusion_restart_wifi.log"

wifi_status="unknown"

log() {
	[[ "$DEBUG" == "yes" ]] || return
	echo -e "[$(date +%F_%T )] $*" >> $LOG_FILE
	echo -e "[$(date +%F_%T )] $*"
}

# Check the log file size and delete if it's above 10MB
clear_logs_if_necessary() {
	if [ "$DEBUG" == "yes" ] && [ -e "$LOG_FILE" ];
	then
		file_size=$(stat -c %s $LOG_FILE)
		log "Log file($LOG_FILE) size = $file_size bytes"
		[[ $file_size -gt $MAX_LOG_FILE_SIZE ]] && rm -f $LOG_FILE
	fi
}

check_for_delayed_execution() {
	old_pid=$1
	pid_from_lock_file=$(cat $LOCK_FILE | grep PID | cut -d'=' -f2)

	[[ "$old_pid" != "$pid_from_lock_file" ]] || {
		log "Unexpected failure!"
		# We can never be here.
		# TODO: Reset everything and continue to restart Wifi
		# status=1
		# return
	}

	birth_time=$(cat $LOCK_FILE | grep BIRTH | cut -d'=' -f2)
	current_time=$(date +%s)
	let age=$current_time-$birth_time
	if [ $age -gt $SCRIPT_LIFE_SPAN ];
	then
		log "Process($old_pid) age(${age}s) is beyond its lifespan(${SCRIPT_LIFE_SPAN}s), killing it."
		kill -9 $old_pid
		status=1
	else
		log "Process($old_pid) is running from past $age seconds."
		status=0
	fi
	return $status
}

check_for_duplicate_instances() {
	if [ -e "$LOCK_FILE" ];
	then
		# If we notice any unexpected filesystem permission errors to create/remove the lock file,
		# then confirm the duplicate instance by comparing the PID.
		log "LOCK_FILE exists, searching the process pool for a duplicate instance."
		for pid in $(pidof -o $$ -x $(basename $0)); do
			if [ $pid != $$ ]; then
				log "Process is already running with PID $pid"
				log "New Wifi Restart Request has been dropped..."
				exit 1
				# As of now, we will just prevent running the second instance before the first one completes.
				#
				# TODO: If the previous instance is taking abnormally more time
				# to finish, kill the previous instance and run the new instance.
				# check_for_delayed_execution $pid
				# status=$?
				# if [ "$status" == 0 ];
				# then
				#	 log "New Wifi Restart Request has been ignored..."
				#	 exit 1 # Don't let the new request continue because we are in the middle of normal execution.
				# fi
				# sleep 2 # Sleep for 2s and continue execution.
			fi
		done
		log "No duplicate instance found."
	fi
}

# Enable WiFi and wait for 6s
enable_wifi() {
	/system/bin/cmd wifi set-wifi-enabled enabled && /system/bin/sleep 6
}

# Disable WiFi and wait for 2s
disable_wifi() {
	/system/bin/cmd wifi set-wifi-enabled disabled && /system/bin/sleep 2
}

# Fetch the WiFi status
get_wifi_status() {
	wifi_status=$(cmd wifi status | head -n1 | cut -d' ' -f3)
}

# Retry the wifi operation mentioned in the 1st argument.
# 1st argument: String: { "WIFI_ENABLE", "WIFI_DISABLE"}
retry_wifi_operation() {
	wifi_operation="$1";
	local failure_retry_count=3

	while [ $failure_retry_count -gt 0 ] ;
	do
		log "Retrying $wifi_operation... $failure_retry_count";
		let failure_retry_count--;
		/system/bin/sleep 2 # (Optional) waiting before retrying immediately
		case "$wifi_operation" in
		"WIFI_ENABLE")
			enable_wifi
			get_wifi_status
			[[ "$wifi_status" != "unknown" ]] && [[ "$wifi_status" == "enabled" ]] && {
				log "Wifi was enabled with $failure_retry_count attempts left."
				return
			}
			;;
		"WIFI_DISABLE")
			disable_wifi
			get_wifi_status
			[[ "$wifi_status" != "unknown" ]] && [[ "$wifi_status" == "disabled" ]] && {
				echo "Wifi was disabled with $failure_retry_count attempts left."
				return
			}
			;;
		*)
			log "Invalid wifi operation was requested.";;
		esac
	done
	log "Giving up retry"
}


log "Wifi restart was requested at $(date)"
clear_logs_if_necessary

check_for_duplicate_instances

trap "{ rm -f '$LOCK_FILE'; log 'Goodbye..\n'; }" EXIT

# Create a lock file with PID and epoch time
echo "PID=$$" > $LOCK_FILE
echo "BIRTH=$(date +%s)" >> $LOCK_FILE
log "Created LOCK_FILE with content:\n$(cat $LOCK_FILE)\n"

# Disable the WiFi and check the status and retry if the operation was failed.
disable_wifi
get_wifi_status
if [ "$wifi_status" != "unknown" ] && [ "$wifi_status" == "enabled" ]; then
	log "Failed to shutdown wifi, retrying..."
	retry_wifi_operation "WIFI_DISABLE"
else
	log "WiFi is disabled successfully";
fi

# Enable the WiFi and check the status and retry if the operation was failed.
enable_wifi
get_wifi_status
if [ "$wifi_status" != "unknown" ] && [ "$wifi_status" == "disabled" ]; then
	log "Failed to enable wifi, retrying..."
	retry_wifi_operation "WIFI_ENABLE"
else
	log "WiFi is enabled successfully"
fi

# Remove the lock file.
rm -f $LOCK_FILE; sleep 0.1
[[ -e "$LOCK_FILE" ]] && log "Failed to remove the LOCK_FILE" || log "Removed LOCK_FILE"

