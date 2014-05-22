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

# Using tmp files to find out when recording gets done
recording_jobs=$(ls /tmp/*.mp3|wc -l)

# first, wait till tmp file gets created
while [ $recording_jobs -eq 0 ]
do
  sleep 60
  recording_jobs=$(ls /tmp/*.mp3|wc -l)
done
# then, wait till tmp file gets deleted
while [ $recording_jobs -ne 0 ]
do
  sleep 60
  recording_jobs=$(ls /tmp/*.mp3|wc -l)
done

# File transfer
echo "Transfering files to Dropbox"
/bin/bash -l -c '/root/dropbox_uploader.sh upload /root/Music/Radiko/* /'

# Linode shutdown
echo "`date`: Shutting down linode instance"
/bin/bash -l -c 'linode delete ripdiko'

