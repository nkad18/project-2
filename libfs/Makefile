# Target library
lib := libfs.a

all: $(lib)

MAKEFLAGS	+= -rR

ifneq ($(V),1)
Q = @
V = 0
endif

# Current Dir
CUR_PWD := $(shell pwd)

# Compiler, targets for compilation
CC	:= gcc
LIB	:= ar rcs
LIBN	:= libfs.a
LIBCL	:= fs.o disk.o
LIBTARG	:= fs.o disk.o

CFLAGS	:= -Wall -Werror

# Debug
ifneq ($(D),1)
CFLAGS	+= -O2
else
CFLAGS	+= -O0
CFLAGS	+= -g
endif

DEPFLAGS = -MMD -MF $(@:.o=.d)

objs := $(patsubst %.x,%.o,$(programs))

deps := $(patsubst %.o,%.d,$(objs))
-include $(deps)

$(LIBN): $(LIBCL)
	@echo "AR	$@"
	$(Q)$(LIB) $(LIBN) $(LIBTARG)

%.o: %.c
	@echo "CC	$@"
	$(Q)$(CC) $(CFLAGS) -c -o $@ $< $(DEPFLAGS)

clean:
	@echo "CLEAN	$(CUR_PWD)"
	$(Q)rm -rf $(objs) $(deps) $(LIBN) $(LIBCL)

