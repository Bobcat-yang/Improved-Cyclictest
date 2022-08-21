#!/bin/bash

# 1. Run cyclictest
cyclictest -l100000 -m -Sp90 -i200 -h400 -q >output 

# 2. Get maximum latency
max_l=`grep "Max Latencies" output | tr " " "\n" | sort -n | tail -1 | sed s/^0*//`

# 3. Get maximum jitter
max_j=`grep "Max Jitters" output | tr " " "\n" | sort -n | tail -1 | sed s/^0*//`

# 4. Grep data lines, remove empty lines and create a common field separator
grep -v -e "^#" -e "^$" output | tr " " "\t" >histogram 

# 5. Split the test data
split -l 400 histogram -d -a 1 his

# 6. Set the number of cores, for example
cores=4

# 7. Handle latency and jitter separately

# ******************************************************
# Latency

# (1) Create two-column data sets with latency classes and frequency values for each core, for example
for i in `seq 1 $cores`
do
  column=`expr $i + 1`
  cut -f1,$column his0 >latency$i
done

# (2) Create plot command header
echo -n -e "set title \"Latency plot\"\n\
set terminal png\n\
set xlabel \"Latency (us), max $max_l us\"\n\
set logscale y\n
set xrange [0:400]\n\
set yrange [0.8:*]\n\
set ylabel \"Number of latency samples\"\n\
set output \"latency.png\"\n\
plot " >plotcmd

# (3) Append plot command data references
for i in `seq 1 $cores`
do
  if test $i != 1
  then
    echo -n ", " >>plotcmd 
  fi
  cpuno=`expr $i - 1`
  if test $cpuno -lt 10
  then
    title=" CPU$cpuno"
   else
    title="CPU$cpuno"
  fi
  echo -n "\"latency$i\" using 1:2 title \"$title\" with histeps" >>plotcmd
done

# (4) Execute plot command
gnuplot -persist <plotcmd

# ******************************************************
# Jitter

# (1) Create two-column data sets with jitter classes and frequency values for each core, for example
for i in `seq 1 $cores`
do
  column=`expr $i + 1`
  cut -f1,$column his1>jitter$i
done

# (2) Create plot command header
echo -n -e "set title \"Jitter plot\"\n\
set terminal png\n\
set xlabel \"Jitter (us), max $max_j us\"\n\
set logscale y\n
set xrange [0:400]\n\
set yrange [0.8:*]\n\
set ylabel \"Number of jitter samples\"\n\
set output \"jitter.png\"\n\
plot " >plotcmd_j

# (3) Append plot command data references
for i in `seq 1 $cores`
do
  if test $i != 1
  then
    echo -n ", " >>plotcmd_j 
  fi
  cpuno=`expr $i - 1`
  if test $cpuno -lt 10
  then
    title=" CPU$cpuno"
   else
    title="CPU$cpuno"
  fi
  echo -n "\"jitter$i\" using 1:2 title \"$title\" with histeps" >>plotcmd_j
done

# (4) Execute plot command
gnuplot -persist <plotcmd_j

# 8. Program end
echo "Cyclictest finished !"


