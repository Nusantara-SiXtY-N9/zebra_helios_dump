#!/vendor/bin/sh

process_run=`ps -A | grep system_server | awk '{print $2}'`
echo "Process id" $process_run
kill -10 $process_run

process_run=`ps -A | grep -E  "com.android.settings$" | awk '{print $2}'`
echo "Process id" $process_run
kill -10 $process_run

process_run=`ps -A | grep -E  "com.android.internal.widget.ILockSettings$" | awk '{print $2}'`
echo "Process id" $process_run
kill -10 $process_run

process_run=`ps -A | grep -E  "com.android.systemui$" | awk '{print $2}'`
echo "Process id" $process_run
kill -10 $process_run
