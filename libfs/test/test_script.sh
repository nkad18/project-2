#!/bin/sh

# Functions:
# compares outputs of reference program and our library
# the parameters are simply the test's name
cmp_output()
{
	echo "\nTest $testnum: $1 $2 $3 $4"
	echo "Comparison for test $testnum:"

	# put output files into variables
	REF_STDOUT=$(cat ref.stdout)
	REF_STDERR=$(cat ref.stderr)

	LIB_STDOUT=$(cat lib.stdout)
	LIB_STDERR=$(cat lib.stderr)

	# compare stdout
	if [ "$REF_STDOUT" != "$LIB_STDOUT" ]; then
		echo "Stdout outputs don't match..."
		diff -u ref.stdout lib.stdout
		echo "REF: $REF_STDOUT"
		echo "LIB: $LIB_STDOUT"
	else
		echo "Stdout outputs match!"
	fi

	# compare stderr
	if [ "$REF_STDERR" != "$LIB_STDERR" ]; then
		echo "Stderr outputs don't match..."
		diff -u ref.stderr lib.stderr
		echo "REF: $REF_STDERR"
		echo "LIB: $LIB_STDERR"
	else
		echo "Stderr outputs match!"
	fi

	# cleanup for next test
	testnum=$(($testnum+1))
	rm ref.stdout ref.stderr
	rm lib.stdout lib.stderr
}

# Start of script:

# make fresh virtual disk, separate ones for fs_ref.x and test_fs.x
./fs_make.x refdisk.fs 50
./fs_make.x libdisk.fs 50
# initialize variables
testnum=1

# Compare the info command

# get fs_info from reference lib
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr

# get fs_info from my lib
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr

# compare fs_ref.x to test_fs.x
cmp_output info

# ls the file system, should have nothing
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls empty

# Compare the add command: first create a file of length 5000
num=0
while [ $num -lt 1000 ]
do
	echo "test" >> test1
	num=$(($num+1))
done

./fs_ref.x add refdisk.fs test1 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test1 >lib.stdout 2>lib.stderr
cmp_output write test1 5,000 bytes

rm test1

# Add a small file
echo "asdf" > small
./fs_ref.x add refdisk.fs small >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs small >lib.stdout 2>lib.stderr
cmp_output write test1 5 bytes

# Test lseek function (lseek in test_fs reads half of the file, rounded up)
echo "Read file 'small' (3/5 bytes)\nContent of the file:\ndf" > ref.stdout
echo "" > ref.stderr
./test_fs.x lseek libdisk.fs small >lib.stdout 2>lib.stderr
cmp_output lseek small file

# add file which doesn't exist
./fs_ref.x add refdisk.fs test10 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test10 >lib.stdout 2>lib.stderr
cmp_output write nonexistent test10

# add test2: length 50000
num=0
while [ $num -lt 10000 ]
do
	echo "test" >> test2
	num=$(($num+1))
done

./fs_ref.x add refdisk.fs test2 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test2 >lib.stdout 2>lib.stderr

# compare fs_ref.x to test_fs.x
cmp_output write test2 50,000 bytes

rm test2

# ls the file system, should have the two files we just wrote
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls

# read the test2 we wrote
./fs_ref.x cat refdisk.fs test2 >ref.stdout 2>ref.stderr
./test_fs.x cat libdisk.fs test2 >lib.stdout 2>lib.stderr
cmp_output cat test2

# stat the test2
./fs_ref.x stat refdisk.fs test2 >ref.stdout 2>ref.stderr
./test_fs.x stat libdisk.fs test2 >lib.stdout 2>lib.stderr
cmp_output stat test2

# info after the two files were added
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr
cmp_output info after adds

# add file over size of the file system (it must be truncated to fit)
# the string is 23 characters (with end of line char)
# times 10000 is 230,000 bytes
# file system is 50 blocks * 4096 = 204,800 bytes
num=0
while [ $num -lt 10000 ]
do
	echo "test number 3 asdf asdf" >> test3
	num=$(($num+1))
done

./fs_ref.x add refdisk.fs test3 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test3 >lib.stdout 2>lib.stderr
cmp_output write test3 230,000 bytes
rm test3

# stat the test3
./fs_ref.x stat refdisk.fs test3 >ref.stdout 2>ref.stderr
./test_fs.x stat libdisk.fs test3 >lib.stdout 2>lib.stderr
cmp_output stat test3

# read the truncated test3 we wrote
./fs_ref.x cat refdisk.fs test3 >ref.stdout 2>ref.stderr
./test_fs.x cat libdisk.fs test3 >lib.stdout 2>lib.stderr
cmp_output cat test3

# add file with conflicting name
echo "test" > test1
./fs_ref.x add refdisk.fs test1 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test1 >lib.stdout 2>lib.stderr
cmp_output add test1 conflict

rm test1

# check if the file has the correct value after attempting to write conflicting
# names
./fs_ref.x cat refdisk.fs test1 >ref.stdout 2>ref.stderr
./test_fs.x cat libdisk.fs test1 >lib.stdout 2>lib.stderr
cmp_output correct read after conflict

# remove one of the files (test1)
./fs_ref.x rm refdisk.fs test1 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test1 >lib.stdout 2>lib.stderr
cmp_output rm test1

# ls after the removal to see if the file was removed correctly
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls after rm

# info after conflict
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr
cmp_output info after conflict

# remove one of the files (test2)
./fs_ref.x rm refdisk.fs test2 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test2 >lib.stdout 2>lib.stderr
cmp_output rm test2

# remove one of the files (test3)
./fs_ref.x rm refdisk.fs test3 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test3 >lib.stdout 2>lib.stderr
cmp_output rm test3

# remove last of the files (test4)
./fs_ref.x rm refdisk.fs test4 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test4 >lib.stdout 2>lib.stderr
cmp_output rm test4

# add file which is perfectly fitted to the data block size
num=0
while [ $num -lt 6400 ]
do
	echo "test num four should be 32 bytes" >> test4
	num=$(($num+1))
done

./fs_ref.x add refdisk.fs test4 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test4 >lib.stdout 2>lib.stderr
cmp_output write test4 204,800 bytes

# attempt to write a file when the file system is full
cat test4 > test5
./fs_ref.x add refdisk.fs test5 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test5 >lib.stdout 2>lib.stderr
cmp_output write test5 fs full

rm test4
rm test5

# ls after write failure
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls after write failed

# read an empty file
./fs_ref.x cat refdisk.fs test5 >ref.stdout 2>ref.stderr
./test_fs.x cat libdisk.fs test5 >lib.stdout 2>lib.stderr
cmp_output read empty file

# stat the test11, should not exist
./fs_ref.x stat refdisk.fs test5 >ref.stdout 2>ref.stderr
./test_fs.x stat libdisk.fs test5 >lib.stdout 2>lib.stderr
cmp_output stat test5 empty file

# info after write failure
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr
cmp_output info after empty file

# rm empty file
./fs_ref.x rm refdisk.fs test5 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test5 >lib.stdout 2>lib.stderr
cmp_output rm test5 empty file

# info after rm empty file
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr
cmp_output info after rm empty

# add file with too many characters in the file name
echo "asdf" > thisfilenameistoolong
./fs_ref.x add refdisk.fs thisfilenameistoolong >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs thisfilenameistoolong >lib.stdout 2>lib.stderr
cmp_output write filename too long
rm thisfilenameistoolong

# add file with too many characters in the file name
echo "asdf" > thisfilenameperf
./fs_ref.x add refdisk.fs thisfilenameperf >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs thisfilenameperf >lib.stdout 2>lib.stderr
cmp_output write filename 16
rm thisfilenameperf

# add file with too many characters in the file name
echo "asdf" > thisisoneless1
./fs_ref.x add refdisk.fs thisisoneless1 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs thisisoneless1 >lib.stdout 2>lib.stderr
cmp_output write filename 15



rm thisisoneless1

# clean
rm refdisk.fs libdisk.fs

# Disk with one entry in fat table
./fs_make.x refdisk.fs 1
./fs_make.x libdisk.fs 1

# adding any file to fs with single data block should fail
echo "test" > test11
./fs_ref.x add refdisk.fs test11 >ref.stdout 2>ref.stderr
./test_fs.x add libdisk.fs test11 >lib.stdout 2>lib.stderr
cmp_output add, fat 1 block

rm test11

# ls after write failure
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls after write failed

# cat the test, should be empty
./fs_ref.x cat refdisk.fs test11 >ref.stdout 2>ref.stderr
./test_fs.x cat libdisk.fs test11 >lib.stdout 2>lib.stderr
cmp_output cat test11

# stat the test11, should be empty
./fs_ref.x stat refdisk.fs test11 >ref.stdout 2>ref.stderr
./test_fs.x stat libdisk.fs test11 >lib.stdout 2>lib.stderr
cmp_output stat test11

# info after empty file
./fs_ref.x info refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x info libdisk.fs >lib.stdout 2>lib.stderr
cmp_output info

# rm the empty file
./fs_ref.x rm refdisk.fs test11 >ref.stdout 2>ref.stderr
./test_fs.x rm libdisk.fs test11 >lib.stdout 2>lib.stderr
cmp_output rm test11 empty file

# ls after rm
./fs_ref.x ls refdisk.fs >ref.stdout 2>ref.stderr
./test_fs.x ls libdisk.fs >lib.stdout 2>lib.stderr
cmp_output ls after rm

# clean
rm refdisk.fs libdisk.fs
