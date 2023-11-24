COMPILER_OPTIONS=
SOURCES=$(wildcard *.pas)

all: blast clean

blast: $(SOURCES)
	fpc $(COMPILER_OPTIONS) blast.pas

clean:
	rm -f -- *.o
	rm -f -- *.ppu
