#!/bin/sh

test_description='dshbak functionality' 

. ${srcdir:-.}/test-lib.sh

dshbak_test() {
	echo -e "$1" | dshbak -c  > output
	cat output \
           | while read line ; do
	       test "$line" = "$2" && echo ok
	   done | grep -q ok || (cat output >&2 && /bin/false)
}

dshbak_test_notok()
{
	touch ok
	echo -e "$1" \
		| dshbak -c \
		| while read line ; do
		    test "$line" = "$2" && rm ok
		  done
	rm ok && :
}


test_expect_success 'dshbak -c does not coalesce different length output' '
	dshbak_test_notok "
foo1: bar
foo2: bar
foo1: baz" "foo[1-2]"
'
test_expect_success 'dshbak -c properly compresses multi-digit suffixes' '
	dshbak_test "
foo8: bar
foo9: bar
foo10: bar
foo11: bar" "foo[8-11]"
'

test_expect_success 'dshbak -c properly compresses prefix with embedded numerals' '
	dshbak_test "
foo1x8: bar
foo1x9: bar
foo1x10: bar
foo1x11: bar" "foo1x[8-11]"
'
test_expect_success 'dshbak -c does not strip leading zeros' '
	dshbak_test "
foo01: bar
foo03: bar
foo02: bar
foo00: bar" "foo[00-03]"
'
test_expect_success 'dshbak -c does not coalesce different zero padding' '
	dshbak_test "
foo0: bar
foo03: bar
foo01: bar
foo2: bar" "foo[0,01,2,03]"
'
test_expect_success 'dshbak -c properly coalesces zero padding of "00"' '
	dshbak_test "
foo1: bar
foo01: bar
foo02: bar
foo3: bar
foo5: bar
foo00: bar" "foo[00-02,1,3,5]"
'
test_expect_success 'dshbak -c can detect suffixes' '
	dshbak_test "
foo1s: bar
foo01s: bar
foo02s: bar
foo3s: bar
foo5s: bar
foo00s: bar" "foo[00-02,1,3,5]s"
'
test_expect_failure 'dshbak -c can detect suffix with numeral' '
	dshbak_test "
foo1s0: bar
foo01s0: bar
foo02s0: bar
foo3s0: bar
foo5s0: bar
foo00s0: bar" "foo[00-02,1,3,5]s0"
'

test_done