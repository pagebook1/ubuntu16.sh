#!/bin/sh
#code sudo wget https://raw.githubusercontent.com/pagebook1/ubuntu16.sh/main/script.sh && chmod +x script.sh && bash ./script.sh
echo Enter License Key: 
read license
if [ $license == 'kevinbeetle' ]
then
echo   SERVER SCRIPT INSTALLING 
else
    echo Invalid License Key.
    exit
fi
sudo wget https://raw.githubusercontent.com/pagebook1/ubuntu16.sh/main/ubuntu16.sh && chmod +x ubuntu16.sh && bash ./ubuntu16.sh
