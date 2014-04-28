#!/bin/bash

# mkdir so that command redirect below has a dir to point to
mkdir -p /root/Music/Radiko

# recording command loop. station as arguments
argv=("$@")
for i in `seq 1 $#`
do
  station=${argv[$i-1]}
  cd /root/ripdiko
  ruby bin/ripdiko $station >> /root/Music/Radiko/ripdiko_$station.log 2>&1 &
done

# wait till recording is done
recording_jobs=$(jobs|wc -l)
while [ $recording_jobs -ne 0 ]
do
  sleep 60
  recording_jobs=$(jobs|wc -l)
done

# File transfer
echo "Transfering files to Dropbox"
/bin/bash -l -c '/root/dropbox_uploader.sh upload /root/Music/Radiko/* /'

# Linode shutdown
echo "`date`: Shutting down linode instance"
/bin/bash -l -c 'linode delete ripdiko'

