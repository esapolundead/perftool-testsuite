#
#	settings.sh of perf_report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_probe"

export MY_ARCH=`arch`

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	export PERFSUITE_RUN_DIR=`readlink -f $PERFSUITE_RUN_DIR`
	export CURRENT_TEST_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME"
	export MAKE_TARGET_DIR="$CURRENT_TEST_DIR/examples"
	test -d "$MAKE_TARGET_DIR" || mkdir -p "$MAKE_TARGET_DIR"
	export LOGS_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME/logs"
	test -d "$LOGS_DIR" || mkdir -p "$LOGS_DIR"
else
	# when $PERFSUITE_RUN_DIR is not set, logs will be placed here
	export CURRENT_TEST_DIR="."
	export LOGS_DIR="."
fi

check_kprobes_available()
{
	test -e /sys/kernel/debug/tracing/kprobe_events
}

check_uprobes_available()
{
	test -e /sys/kernel/debug/tracing/uprobe_events
}

clear_all_probes()
{
	echo 0 > /sys/kernel/debug/tracing/events/enable
	check_kprobes_available && echo > /sys/kernel/debug/tracing/kprobe_events
	check_uprobes_available && echo > /sys/kernel/debug/tracing/uprobe_events
}

# FIXME
check_perf_probe_option()
{ #option
	$PERF probe -h 2>&1 | egrep '[\t ]+'$1'[\t ]+' > /dev/null
}

#FIXME
check_kernel_debuginfo()
{
	eu-addr2line -k 0x`grep -m 1 vfs_read /proc/kallsyms | cut -f 1 -d" "` | grep vfs_read
}
