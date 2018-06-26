# Project 2 Report
## Phase 1

* The global structures  -__SB__,__RD__, __fat__, `fat->f_table`,
`filedes`- receive their dynamically allocated memory here because mount
is the first function in fs.c that should be called. The mount function must
prepare the disk to be used as a file system to be used with the
`ECS150-FS` file system. In order to do this, it reads in the information
that is contained by the superblock on the disk into __SB__ and then it
verifies that each field of __SB__ is valid. After determining that each
field is valid, the FAT table is read in from the disk to `fat->f_table`
with a call to `read_in_FAT()`. We then call `read_in_RD()` in order to
read the root directory block into __RD__. After this, `FS_Mount` is set
to 1 to indicate that mount has successfully been called. This is important,
because there are functions that would be dangerous to call if mount had not
already succeeding been called. Because these functions free dynamically
allocated structs that are allocated only if mount is successfully returns.

* __umount()__ must update the metadata on the disk, close the disk, and
free the global data structures. First, `update_FAT()` is called in-order
to update the FAT blocks on the disk. Then `update_RD()` is called in
order to update the root directory. Updating the disk is how we provide
persistence of memory. Because it guarantees the files the user creates will
exist until the user explicitly deletes them. After the disk is updated,
`block_disk_close()` is called to safely close the filesystem. And, if it
successfully returns, the global metadata data structures are freed. Thus,
the disk is up-to-date and all allocated memory is cleaned up. So our
implementation of `fs_umount()` meets the project specifications.

* In order to implement `fs_info` so that it matches the reference output
format, we must output 5 of the fields in the superblock (`tNumBlocks`,
`nFAT_Blocks`, `rdb_Index`, `d_block_start`, `nDataBlocks`). We also
had to print current totals of free fat blocks as well as free root
directory blocks. The latter is handled by the `free_FAT_blocks()` and the
`free_RD_blocks()` functions respectively. It should also be noted that we
printed to `stdout` here instead of `stderr` because doing so allows the
output to be redirected to a file while `stderr` did not.

* Our root directory struct contains a char array field for the filename
with array length set to `FS_FILENAME_LEN` (in order to maximize
portability), a field of type `uint32_t` called __fSize__ which stores the
file size, and a `uint16_t` field called `f_index` which stores the first
FAT index of the file. These fields are declared in this order because this
corresponds to the order they exist in the root directory block on the disk.
We implement our representation of the root directory, __RD__, by
dynamically allocate an array of `FS_FILE_MAX_COUNT` Root_Dir type structs.

* Our superblock is the global struct __SB__ and its type is named
__sBlock__. The instructions state that the fields of the superblock on the
disk will be a char array of 8 bytes (the signature), then 4 numerical value
fields of size 2 bytes, followed by a numerical field of 1 byte (in that
order). In order to replicate this in our superblock, we made the first
field a char array of 8 bytes followed by 4 fields of type `uint16_t` and
then a field of type `uint8_t`.

* Our FAT table is a global struct array named fat and it is of a type we
called FAT. The fat table contains 2 bytes and the values are read as
unsigned integers. So we make the only field of FAT, `f_table`, a pointer
of type `uint16_t`. It will point to a `uint16_t` array with
__SB->nDataBlocks__ entries (`SB->nDataBlocks` = the amount of data
blocks). So, or FAT table is created as necessary.

* Our global struct `fs_filedes` is used as a file descriptor object. It
must hold the name of the file it points to as well as the offset of this
file in bytes in order to meet the API specifications. For this reason, we
gave it an integer type field called `fd_offset` and a char array field
called `fd_filename`. The char array contains `FS_FILENAME_LEN` indices in
order to maximize portability. Our file descriptor table is an array of
`fs_filedes` structs and it's pointed to by __filedes__. Also, it contains
`FS_OPEN_MAX_COUNT` entries. This creates the table with the correct
amount of entries, in a portable way.

* `FS_Mount` is an important global variable because it is used to
indicate whether `fs_mount()` has been successfully called. If
`FS_Mount` equals 1, `fs_mount()` has been successfully called. If it
equals 0 then `fs_mount()` has not been successfully called. If
`fs_mount()` has not been successfully called, the functions that use the
global structs, which are allocated in `fs_mount()`, access pointers to
unallocated memory. So it is dangerous to access them without knowing that
`fs_mount()` has been successfully called.

## Phase 2

* In order to implement `fs_create()` we must first check if `FS_Mount`
equals 1 to make sure that fs_mount() has been called successfully. This is
essential because we will iterate through the root directory struct array
(__RD__) to find an open directory spot. But if mount isn't successfully
called __RD__ will not have been allocated yet, so iterating through __RD__
would be dangerous. After name validation, we must make sure that that
the root directory isn't already full. We do this with a call to
`free_RD_blocks()`. Then, we must call `file_exist(filename)` and
receive a -1 return value to ensure that filename does not already exist in
the directory. After ensuring this, we use `create_root()` to create a new
root directory entry. We use `new_file` to refer to this entry. We set its
file size (__fSize__) to 0 and we set its first index (`f_index`) to
`FAT_EOC`. In summary, we create a file and initialize its fields
correctly. This is only done if its name is valid and if there is space in
the root directory. So we've satisfied the API specifications for
`fs_create()`.

* In `fs_delete()` we must do the same string validation of filename that
we did in `fs_create()`. But a key difference here is that we will only
proceed if `file_exist(filename)` returns 0 instead of -1. This is because
we need a file to exist in order to delete it. We then compare filename to
the filenames in the file descriptor table. If there is a match we cannot
proceed with deleting the file because it is open in file descriptor(s). If
the file exists, we iterate through `fat->f_table`, starting at index
`f_index` and using the value stored in `f_index` as the next index to
access, we temporarily store the value located in the `f_index` index of
`fat->f_table` in temp, set the value of `f_index` entry to 0. Then we
set __f_index__ to temp and repeat until we reach a `FAT_EOC` index entry.
This ensures the linked list style of FAT table traversal. All of this is
done with a call to `delete_file()`. After removing its FAT entries, a
call to `delete_root()` deletes the root entry of the file (by setting its
name to ‘\0’). By doing all of this, we’ve deleted the file while still
adhering to the constraints with which the API allows us to do so.

* In order to make `fs_ls()` match the reference output we iterate through
the __RD__ table from 0 to `FS_FILE_MAX_COUNT` and for each entry whose
string is not equivalent to ‘\0’ we print the filename, file size, and the
first index of the files `fat->f_table` entry.

## Phase 3
* Our implementation of `fs_open()` generates up to `FS_OPEN_MAX_COUNT`
file descriptors which are just indexed structs that are associated with a
string (`fd_filename`) and also contain an offset (`fd_offset`) of the
file they point to. Each file descriptor is in a unique index in
the file descriptor array. And naturally, a file descriptor’s number is its
index in the file descriptor array. The file descriptor array is allocated
in the `fs_mount()` function, and one of the error checks that is done at
the beginning of `fs_open()` is to make sure `fs_mount()` has been
successfully called. So, while in open, we never have to worry about the
pointer to the file descriptor table being NULL. We finish by incrementing
`fd_total`, the running total amount of file descriptors.

* In order to use `fs_close()` to close a file descriptor, in this case
__fd__, we first iterate through the file descriptor table to make sure file
descriptor __fd__ exists. We do this by checking if the `fd_filename`
string pointed to by the file descriptor table entry, in index __fd__, is
not '\0', this means __fd__ is a valid file descriptor. If this is the case,
we set the first character of the fd entry’s `fd_filename` field to '\0'.
This means it's an empty entry. We then decrement `fd_total`, the running
total amount of file descriptors because there is now one less file
descriptor.

* To implemented `fs_stat()`, we first make sure that the inputted file
descriptor, __fd__, is valid. This means that __fd__ is an integer value
ranging from 0 to 31. We use the function call `fd_exists(fd)` to validate
that the file descriptor exists. If it exists, we access the filename that
it refers to. We then use a for-loop to iterate through the RD table in
search of the RD entry that has the sought after filename. When it's found,
we return its size, as specified in the instructions.

* In order to implement `fs_lseek()`, as specified, we first verify that
the file descriptor __fd__ exists. If it does, we collect the root directory
index that the file descriptor refers to with a call to
`return_rd(filedes[fd].fd_filename)`. We use this root directory index to
access the file in the RD table. Then, we compare the inputted offset to the
file’s size in order to make sure that the inputted offset is not larger
than the file’s size. At last, we use __fd__ to access the specified index
of the file descriptor table and change its offset to `offset`.

## Phase 4

#### fs_read()
* We tried to think of the most generic solution possible. The function is
structured into a do..while() loop which handles one block per iteration.
The function iterates until it reaches the final block of the file, or it
runs out of bytes for the read. The startoffset and endoffset variables
handle where within the block to read from; intuitively, the read amount
must be endoffset - startoffset. The logic for their values is as follows:

##### Start Offset
* The start offset denotes where to begin the read from. For the first block,
the start offset is equal to the file's offset within the block (file offset
% block size). For other blocks, we always start from the beginning, so
start offset equals 0.

##### End Offset
* The end offset is the part of the block where we cut off the read. It is
equal to the block size for all middle blocks. For the last block in the
read (The FAT table is FAT_EOC for this block, or the bytes remaining to be
read are less thanthe block size), the function checks if the file has
enough bytes to read. If itdoes, we read the amount of bytes remaining in
count. Else, we read to the end of the file.

##### Bounce Buffer
* The bounce buffer is only necessary for the first and last blocks being
read,because the reads in the middle blocks are always the entirety of the
block.The function continues reading blocks until it reaches the end of
chain or it reads up to the parameter count bytes. After finishing, the
function increments the offset of the file descriptor by the amount of
bytes which were read.

##### Total
* After setting all of the above variables, the function reads the block
from start offset to end offset. To prepare for the next block, the
function decreases the remaining bytes by the amount of bytes read and
increases the location of the buffer by the amount of bytes read. The
function proceeds to the next block in the FAT table's chain. In this way,
the loop handles all of the functionality by adjusting which parts of the
block should be read according to the current read.

#### fs_write()
* This function is very similar to fsread, except the logic within the loop
varies slightly. The first and last block must have the data outside of the
write location preserved; this also requires a bounce buffer, which we read
the block into and write from the file's offset. At the end of the loop, if
the write extends past the file's last data block, we extend the file with
the file_extend function.

##### file_extend()
* The file_extend function extends the data blocks of a file, updating the
FAT's chain to contain the newest data blocks. It returns the amount of
data blocks allocated, up to the request amount. Note that if no more data
blocks are available, this function will cease attempting to add more
blocks and return how many blocks were added.

* After returning the number of extended blocks from the file extend
function, fswrite checks if the file has enough data blocks to complete the
write. If it does not, fswrite updates the bytes remaining to fill up the
extended blocks.

##### Initialization
* Because files created in fscreate do not have data blocks allocated, the
first fswrite call must allocate a first data block for these files (which
is checked at the beginning of the function). If the file system runs out
of data blocks and a file attempts a write, fswrite simply returns 0 bytes
as the write amount.

#### Edge Cases
##### fs_read():

1: File offset is not a multiple of block size (only a problem in the first
block)
2: Read exceeds the the file size (read to end of file)
3: Read ends at less than the entire block
4: Generic read (middle blocks, read entire block)

##### fs_write():

1: File needs to be initialized
2: File descriptor is out of bounds
3: File descriptor is not open
4: Write exceeds the file size (file must be extended)
5: Disk runs out of space for write (write as much as possible)
6: File offset is not a multiple of block size
7: Write ends at less than the entire block
8: Generic write (middle blocks, write entire block)

By handling these edge cases, we guarantee the functionality specified by
the API.

## Testing
* We created a test script from the professor's instructions in the
discussion section. The script creates two separate file system disks, one
for the reference program and one for our library's program; the script
runs the same commands on each respective disk, then compares the outputs.

* We targeted edge cases for all of the available commands in the given
program test_fs.c:

##### add
* We tested 'add' with a file that fits in one block, is empty, is longer
than the available size in the file system,is perfectly fitted to the file
system, when the file system is full, and when there is only one data block.

* In each of these cases, the reference file system defines different
behavior and thus we must have separate test cases for each. For rm we
remove files which were added to ensure the function works as intended. We
also tested removing empty files, and removing a file which does not exist.
We run info at the beginning and at points where we allocate or deallocate
largefiles. We run ls at intermittent points in the tester to ensure that
the files which are added/deleted are correctly changed. We run stat on each
of the files which are added above, to ensure that their statistics align
with the reference program. We run cat to ensure it works, and also on an
empty file. We made sure to test the output when'cat'ing a file which was
added when the file system had no more available room.

* Additionally, we realized that the implementation of testfs.c does not
test the library's lseek function, so we wrote testlseek.c which tests lseek
and error cases not handled by testfs.c.
