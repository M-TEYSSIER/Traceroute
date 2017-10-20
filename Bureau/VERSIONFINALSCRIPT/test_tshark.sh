#!/bin/bash

clear
tshark -a duration:5 -Y icmp host $1 > test | ping $1 -c 3
moi="$(cat test | cut -c 4- | head -n 1 | cut -d " " -f 5)"
clear
echo Votre IP source est : $moi
rm test

