#!/bin/bash

#
#	test_basic of perf annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf annotate command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF annotate --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-ANNOTATE" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "perf\-annotate \- Read perf.data .* display annotated code" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "input" "dsos" "symbol" "force" "verbose" "dump-raw-trace" "vmlinux" "modules" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "print-line" "full-paths" "stdio" "tui" "cpu" "source" "symfs" "disassembler-style" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "objdump" "skip-missing" "group" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# annotate...
( cd $CURRENT_TEST_DIR ; $CMD_PERF annotate --stdio > $LOGS_DIR/basic_annotate.log 2> $LOGS_DIR/basic_annotate.err )
PERF_EXIT_CODE=$?

# check the annotate output; default option means both source and assembly
REGEX_HEADER="Percent.*Source code.*Disassembly\sof"
REGEX_LINE="$RE_NUMBER\s+:\s+$RE_NUMBER_HEX\s*:.*"
REGEX_SECTION__TEXT="Disassembly of section \.text:"
# check for the basic structure
../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < $LOGS_DIR/basic_annotate.log
CHECK_EXIT_CODE=$?
# check for the source code presence
../common/check_all_patterns_found.pl "main" "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < $LOGS_DIR/basic_annotate.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution - annotate"
(( TEST_RESULT += $? ))


### dso filter

# '--dso SOME_DSO' limits the annotation to SOME_DSO only
( cd $CURRENT_TEST_DIR ; $CMD_PERF annotate --stdio --dso load > $LOGS_DIR/basic_dso.log 2> $LOGS_DIR/basic_dso.err )
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < $LOGS_DIR/basic_dso.log
CHECK_EXIT_CODE=$?
# check for the source code presence
../common/check_all_patterns_found.pl "main\s*\(" "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < $LOGS_DIR/basic_dso.log
(( CHECK_EXIT_CODE += $? ))
# check whether the '--dso' option cuts the output to one dso only
test `grep -c "Disassembly" $LOGS_DIR/basic_dso.log` -ge 2 # FIXME wrong
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "dso filter"
(( TEST_RESULT += $? ))


### no-source

# '--no-source' should show only the assembly code
( cd $CURRENT_TEST_DIR ; $CMD_PERF annotate --stdio --no-source --dso load > $LOGS_DIR/basic_nosource.log 2> $LOGS_DIR/basic_nosource.err )
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_HEADER load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < $LOGS_DIR/basic_nosource.log
CHECK_EXIT_CODE=$?
# the C source should not be there
../common/check_no_patterns_found.pl "from = atol" "from = 20L;" "for\s*\(i = 1L; j; \+\+i\)" "return 0;" < $LOGS_DIR/basic_nosource.log
(( CHECK_EXIT_CODE += $? ))
# check whether the '--dso' option cuts the output to one dso only
test `grep -c "Disassembly" $LOGS_DIR/basic_nosource.log` -ge 2 # FIXME wrong
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "no-source"
(( TEST_RESULT += $? ))


### full-paths

# '-P' should print full paths of DSOs
( cd $CURRENT_TEST_DIR ; $CMD_PERF annotate --stdio --dso load -P > $LOGS_DIR/basic_fullpaths.log 2> $LOGS_DIR/basic_fullpaths.err )
PERF_EXIT_CODE=$?

FULLPATH=`readlink -f $CURRENT_TEST_DIR/examples`
../common/check_all_patterns_found.pl "$REGEX_HEADER $FULLPATH/load" "$REGEX_LINE" "$REGEX_SECTION__TEXT" < $LOGS_DIR/basic_fullpaths.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "full-paths"
(( TEST_RESULT += $? ))


### print-line

# '--print-line' should print inline the source lines
( cd $CURRENT_TEST_DIR ; $CMD_PERF annotate --stdio --dso load -P --print-line > $LOGS_DIR/basic_printline.log 2> $LOGS_DIR/basic_printline.err )
PERF_EXIT_CODE=$?

FULLPATH="`pwd`/examples"
../common/check_all_patterns_found.pl "$FULLPATH/load\.c:$RE_NUMBER\s+$REGEX_LINE" "$REGEX_SECTION__TEXT" < $LOGS_DIR/basic_printline.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "print-line"
(( TEST_RESULT += $? ))


### redirected input

# '-i dir/perf.data' should point to some other perf.data file
mv $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/
$CMD_PERF annotate --stdio --dso load -i $CURRENT_TEST_DIR/examples/perf.data > $LOGS_DIR/basic_input.log 2> $LOGS_DIR/basic_input.err
PERF_EXIT_CODE=$?

# the output should be the same as before
diff -q $LOGS_DIR/basic_input.log $LOGS_DIR/basic_dso.log
CHECK_EXIT_CODE=$?
diff -q $LOGS_DIR/basic_input.err $LOGS_DIR/basic_dso.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "redirected input"
(( TEST_RESULT += $? ))


### execution without perf.data

# check for error message
! $CMD_PERF annotate > $LOGS_DIR/basic_nodata.log 2> $LOGS_DIR/basic_nodata.err
PERF_EXIT_CODE=$?

REGEX_NO_DATA="failed to open perf.data: No such file or directory"
../common/check_all_lines_matched.pl "$REGEX_NO_DATA" < $LOGS_DIR/basic_nodata.err
CHECK_EXIT_CODE=$?
test ! -s $LOGS_DIR/basic_nodata.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "execution without data"
(( TEST_RESULT += $? ))
mv $CURRENT_TEST_DIR/examples/perf.data $CURRENT_TEST_DIR/


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
