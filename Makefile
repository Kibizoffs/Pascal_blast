COMPILER_OPTIONS= -gv
SOURCES=$(wildcard *.pas)

all: blast clean

blast: $(SOURCES)
	-fpc $(COMPILER_OPTIONS) blast.pas

clean:
	rm -f *.o *.ppu

distclean: clean
	rm -f blast
