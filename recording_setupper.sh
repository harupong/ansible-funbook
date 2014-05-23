#!/bin/bash

# mkdir so that command redirect below has a dir to point to
mkdir -p /root/Music/Radiko

# recording command loop. station as arguments
argv=("$@")
for i in `seq 1 $#`
do
  station=${argv[$i-1]}
  echo $station
  cd /root/ripdiko
  RIPDIKO_SCRIPTS=/tmp/ RIPDIKO_OUTDIR=/root/Music/ ruby bin/ripdiko $station &
done

# wait till recording is done
recording_jobs=$(jobs|wc -l)
while [ $recording_jobs -ne 0 ]
do
  sleep 60
  recording_jobs=$(jobs|wc -l)
done

# Remove caches
echo "Removing unwanted files"
/bin/bash -l -c 'rm /root/Music/Radiko/*.mp3'

