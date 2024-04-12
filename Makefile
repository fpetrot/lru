MV = mv
CC = gcc
N ?= 16
H ?= 90
CFLAGS = -O3
CFLAGS += -DWAYS=$(N) -DHR=$(H)
all : lru-matrix-$(N)-$(H) lru-baseline-$(N)-$(H)

lru-matrix-$(N)-$(H) : lru-matrix
	$(MV) $< $@

lru-baseline-$(N)-$(H) : lru-baseline
	$(MV) $< $@

lru-matrix : lru-matrix.c
lru-baseline : lru-baseline.c

clean:	
	rm -f lru-matrix-* lru-baseline-* lru-matrix lru-baseline
