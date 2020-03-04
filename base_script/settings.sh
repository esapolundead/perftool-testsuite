#
#	settings.sh of perf_script test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_script"

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

should_support_syscall_translations()
{
	# return values
	# 0 = expected to support syscall translations
	# 1 = not expected to support syscall translations
	test -z "$PYTHON" && /usr/bin/env python -V &>/dev/null && export PYTHON="/usr/bin/env python"
	test -z "$PYTHON" && /usr/bin/env python3 -V &>/dev/null && export PYTHON="/usr/bin/env python3"
	test -z "$PYTHON" && /usr/bin/env python2 -V &>/dev/null && export PYTHON="/usr/bin/env python2"
	test -z "$PYTHON" && /usr/libexec/platform-python -V &>/dev/null && export PYTHON="/usr/libexec/platform-python"
	test -z "$PYTHON" && export PYTHON="python"
	$PYTHON -c "import audit" 2>/dev/null
}

detect_Qt_Python_bindings()
{
	# return values
	# 0 = PySide package is installed
	# 1 = PySide package is not installed
	test -z "$PYTHON" && /usr/bin/env python -V &>/dev/null && export PYTHON="/usr/bin/env python"
	test -z "$PYTHON" && /usr/bin/env python3 -V &>/dev/null && export PYTHON="/usr/bin/env python3"
	test -z "$PYTHON" && /usr/bin/env python2 -V &>/dev/null && export PYTHON="/usr/bin/env python2"
	test -z "$PYTHON" && /usr/libexec/platform-python -V &>/dev/null && export PYTHON="/usr/libexec/platform-python"
	test -z "$PYTHON" && export PYTHON="python"
	$PYTHON -c "import PySide" 2> /dev/null
}
