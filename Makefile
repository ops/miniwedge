#
# Makefile for miniwedge
#
# September 2020 ops
#

LIBRARY_BASE = miniwedge
LIBRARY_SUFFIX = lib
LIBRARY := $(LIBRARY_BASE).$(LIBRARY_SUFFIX)

AR := ar65
AS := ca65

target ?= vic20

# Additional assembler flags and options.
ASFLAGS += -t $(target) -g

# Set OBJECTS
LIB_OBJECTS := miniwedge.o

.PHONY: clean

$(LIBRARY): $(LIB_OBJECTS)
	$(AR) $(ARFLAGS) $@ $(LIB_OBJECTS)

clean:
	$(RM) $(LIB_OBJECTS)
	$(RM) $(LIBRARY)
	$(RM) *~
