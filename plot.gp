set terminal png medium transparent
set key top left
set ylabel "MPI Message Bandwidth (MBytes/s)"
set xlabel "Message length (bytes)"
set grid

set logscale x 2
set xrange [0.5:8388608]

set yrange [0:600]
set output 'mpi-bandwidth-virt.png'
plot 'results-sausage.dat' using 1:4 with linespoints lw 2 lc rgb "#428212" t "Sausage", \
     'results-ral.dat' using 1:4 with linespoints lw 2 lc rgb "#18006F" t "RAL", \
     'results-cam.dat' using 1:4 with linespoints lw 2 lc rgb "#6BB9B7" t "Cambridge"

set yrange [0:12000]
set output 'mpi-bandwidth-all.png'
plot 'results-sausage.dat' using 1:4 with linespoints lw 2 lc rgb "#428212" t "Sausage", \
     'results-ral.dat' using 1:4 with linespoints lw 2 lc rgb "#18006F" t "RAL", \
     'results-cam.dat' using 1:4 with linespoints lw 2 lc rgb "#6BB9B7" t "Cambridge", \
     'results-alaska-lln.dat' using 1:4 with linespoints lw 2 lc rgb "#83151C" t "Alaska IB", \
     'results-alaska-bdn.dat' using 1:4 with linespoints lw 2 lc rgb "#AF1624" t "Alaska 25G"

