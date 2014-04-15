#!/bin/bash

# Functions

function initiate_linode() {
  echo "==============================================="
  date
  echo "start launching and provisioning linode-ripdiko"

  echo "`date`:linode-cli create"
  linode create ripdiko --password $LINODE_PASSWORD

  echo "`date`:wait till linode gets running. linode status is:"
  status=""

  while [ "$status" != "running" ]
  do
    sleep 20
    status=`linode list --json | jq -r '.ripdiko.status'`
    echo $status
  done

  echo "`date`:obtaining IP Address of linode"
  linode list --json | jq -r '.ripdiko.ips[0]' > ~/.ansible.inventory
  cat ~/.ansible.inventory

  echo "`date`:run ansible-playbook(takes a while...)"
  ansible-playbook -i ~/.ansible.inventory ~/ansible-funbook/ripdiko.yml
}

function check_ansible_results() {
echo "`date`:check if ansible-playbook went well"
tail ~/ansible-funbook/linode_ripdiko.log |grep unreachable=0 |grep failed=0 #grep returns exit code 1 if ansible error
ansible_result=$?

if [ $ansible_result -ne 0 ]; then
  delete_linode
  sleep 300 #wait 5 minutes before re-launching linode
elif [ $ansible_result -eq 0 ]; then 
  DONE=YES
fi
}

function delete_linode() {
  echo "`date`:ansible failed, deleting linode"
  linode delete ripdiko

    linode_deleted=""
    while [ "$linode_deleted" != "No Linodes to list." ]
    do
      sleep 20
      linode_deleted=`linode list --json | jq -r '.[].message'`
      echo $linode_deleted
    done

  echo "`date`:linode deleted"
}

# LOGIC

DONE=NO
i=0

while [ $DONE  = NO ]
do
  initiate_linode
  check_ansible_results
  i=`expr $i + 1`

  if [ $i -eq 10 ]; then
    echo "`date`:tried relaunching 10 times and still failing. abort the process"
    break
  fi
done

echo "`date`:linode provisioned!!"
