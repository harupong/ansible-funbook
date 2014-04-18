#!/bin/bash

if [ -f my.lock ]; then
  date >> /root/my.lock
else
  touch my.lock
  date >> /root/my.lock
fi

/bin/bash -l -c "cd /root/ripdiko && ruby bin/ripdiko $1 >> /root/ripdiko_$1.log 2>&1"
/bin/bash -l -c "cp /root/ripdiko_*.log /root/Music/Radiko/"
