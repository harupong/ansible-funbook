#!/bin/bash

# mkdir so that command redirect below has a dir to point to
mkdir /root/Music/Radiko

# recording command loop. station as arguments
argv=("$@")
for i in `seq 1 $#`
do
  station=${argv[$i-1]}
  echo $station
  /bin/bash -l -c "cd /root/ripdiko && RIPDIKO_SCRIPTS=/tmp/ RIPDIKO_OUTDIR=/tmp/ ruby bin/ripdiko {{item}}"
done

# Remove caches
echo "Removing unwanted files"
/bin/bash -l -c 'rm /root/Music/Radiko/*.mp3'
