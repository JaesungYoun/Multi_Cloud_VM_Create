#! /bin/bash

sudo su

echo '1q2w3e4r!' | passwd --stdin root

cd ..
cd ..
cd tmp
ifconfig > result.txt