# Compiler settings
CC := $(CROSS_COMPILE)gcc
CFLAGS := -Wall -Wextra -Werror -g

# Target application
TARGET := writer

# Source files
SRCS := writer.c
OBJS := $(SRCS:.c=.o)

# Default target: Build the application
all: $(TARGET)

# Build the writer application
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# Compile .c files into .o files
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean target: Remove binaries and object files
clean:
	rm -f $(TARGET) $(OBJS)

