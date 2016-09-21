#
#	settings.sh of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_stat"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`cat /proc/cpuinfo | grep -P "processor\s" | wc -l`

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	export PERFSUITE_RUN_DIR=`readlink -f $PERFSUITE_RUN_DIR`
	export CURRENT_TEST_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME"
	test -d "$CURRENT_TEST_DIR" || mkdir -p "$CURRENT_TEST_DIR"
	export LOGS_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME/logs"
	test -d "$LOGS_DIR" || mkdir -p "$LOGS_DIR"
else
	# when $PERFSUITE_RUN_DIR is not set, logs will be placed here
	export CURRENT_TEST_DIR="."
	export LOGS_DIR="."
fi


# The following functions detect whether the machine should support/test
# various microarchitecture specific features.

should_support_intel_uncore()
{
	# return values:
	# 0 = expected to support uncore
	# 1 = not expected to support uncore

	# virtual machines do not support uncore
	detect_baremetal || return 1

	# non-Intel CPUs do not support uncore
	detect_intel || return 1

	# only some models should support uncore
	# (taken from the arch/x86/kernel/cpu/perf_event_intel_uncore.c source file)
	UNCORE_COMPATIBLE="26 30 37 44    42 58 60 69 70 61 71   46 47   45   62   63   79 86   87   94"
	CURRENT_FAMILY=`head -n 25 /proc/cpuinfo | grep 'cpu family' | perl -pe 's/[^:]+:\s*//g'`
	CURRENT_MODEL=`head -n 25 /proc/cpuinfo | grep -v 'name' | grep 'model' | perl -pe 's/[^:]+:\s*//g'`
	test $CURRENT_FAMILY -eq 6 || return 1
	AUX=${UNCORE_COMPATIBLE/$CURRENT_MODEL/}
	! test "$UNCORE_COMPATIBLE" = "$AUX"
}


should_support_intel_rapl()
{
	# return values:
	# 0 = expected to support RAPL
	# 1 = not expected to support RAPL

	# virtual machines do not support RAPL
	detect_baremetal || return 1

	# non-Intel CPUs do not support RAPL
	detect_intel || return 1

	# only some models should support RAPL
	# (taken from the arch/x86/kernel/cpu/perf_event_intel_rapl.c source file)
	RAPL_COMPATIBLE="42 58  63 79  60 69 61 71  45 62  87"
	CURRENT_FAMILY=`head -n 25 /proc/cpuinfo | grep 'cpu family' | perl -pe 's/[^:]+:\s*//g'`
	CURRENT_MODEL=`head -n 25 /proc/cpuinfo | grep -v 'name' | grep 'model' | perl -pe 's/[^:]+:\s*//g'`
	test $CURRENT_FAMILY -eq 6 || return 1
	AUX=${RAPL_COMPATIBLE/$CURRENT_MODEL/}
	! test "$RAPL_COMPATIBLE" = "$AUX"
}
