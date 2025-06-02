# server/Makefile
CC ?= gcc              # allows cross-compile override, e.g. make CC=aarch64-linux-gnu-gcc
CFLAGS ?= -Wall -Werror -pthread
TARGET = aesdsocket
SRCS   = aesdsocket.c

.PHONY: all default clean

all: $(TARGET)
default: all

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f $(TARGET)

