#!/bin/bash

if true ; then
	make clean
	for j in 10 70 80 90 95 99; do
		for i in 2 4 8 16; do
			make N=$i H=$j
		done
	done
fi

# lru programs return a hash that is identical
# if both did the same thing (which I do hope)
if true ; then
{
for j in 10 70 80 90 95 99; do
	for i in 2 4 8 16; do
		# Do that 10 times to mitigate for unreliable measurements
		t=0
		for k in {1..1}; do
			d=$(/usr/bin/time ./lru-matrix-$i-$j 2>&1 |\
				awk -Fu '/user/{print $1}')
			t=$(echo $t + $d | bc -l)
		done
		echo $t/10 | bc -l | xargs echo "Matrix $i $j " 

		t=0
		for k in {1..1}; do
			d=$(/usr/bin/time ./lru-baseline-$i-$j 2>&1 | \
				awk -Fu '/user/{print $1}')
			t=$(echo $t + $d | bc -l)
		done
		echo $t/10 | bc -l | xargs echo "Baseline $i $j "
	done
done
} > tmpfile
fi

rm -f runtimes.py
grep Matrix tmpfile   | paste -d '   \n' -s|head -1|awk '{print "w=["$2", "$6", "$10", "$14"]"}' >> runtimes.py
grep Matrix tmpfile   | paste -d '   \n' -s|awk '{print "m_"$3"=["$4", "$8", "$12", "$16"]"}' >> runtimes.py
grep Baseline tmpfile | paste -d '   \n' -s|awk '{print "b_"$3"=["$4", "$8", "$12", "$16"]"}' >> runtimes.py

python - << EOF
import matplotlib.pyplot as plt
import numpy as np
from runtimes import *

# Data for plotting

fig, ax = plt.subplots()
ax.plot(w, m_10, label="Matrix 10%", linestyle='--')
ax.plot(w, m_70, label="Matrix 70%", linestyle='--')
ax.plot(w, m_80, label="Matrix 80%", linestyle='--')
ax.plot(w, m_90, label="Matrix 90%", linestyle='--')
ax.plot(w, m_95, label="Matrix 95%", linestyle='--')
ax.plot(w, m_99, label="Matrix 99%", linestyle='--')
plt.gca().set_prop_cycle(None)
ax.plot(w, b_10, label="Baseline 10%")
ax.plot(w, b_70, label="Baseline 70%")
ax.plot(w, b_80, label="Baseline 80%")
ax.plot(w, b_90, label="Baseline 90%")
ax.plot(w, b_95, label="Baseline 95%")
ax.plot(w, b_99, label="Baseline 99%")

ax.set(xlabel='ways', ylabel='time (s)',
       title='lru matrix vs baseline')
ax.grid()
plt.legend()
fig.savefig("lru-compared.pdf")
EOF
