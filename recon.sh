#!/bin/bash
# reconnaissance script to gather information on a given IP address

RED='\033[0;35m'
NOCOLOR='\033[0m'

# check if nmap is installed
if [[ ! -x $NMAP ]]; then
	echo "This script requires Nmap"
	exit 1
fi

if [[ $EUID -ne 0 ]]; then
	echo "Run as root"
	exit 1
fi

# if no arguments passed, display usage info
if [ -z "$1" ]
then
	echo "Usage: ./recon.sh <IP address>"
	exit 1
fi

echo -e "${RED}
 _ __ ___  ___ ___  _ __  
| '__/ _ \/ __/ _ \| '_ \ 
| | |  __/ (_| (_) | | | |
|_|  \___|\___\___/|_| |_|
${NOCOLOR}                                                      "

# create new file to store results, overwritten with subsequent scans
printf "\n------ NMAP ------\n\n" > results

echo "Running Nmap scan..."

# run nmap w/ the ip address provided and send results to file
nmap -p- -Pn $1 | tail -n +3 | head -n -1 >> results

# do while loop to iterate thru results file
while read line
do
	# if open port is found
	if [[ $line == *open* ]] && [[ $line == *http* ]]
	then
		echo "Running Gobuster..."
		gobuster dir -u $1 -w /usr/share/wordlists/dirb/common.txt -qz > temp1

	echo "Running WhatWeb..."
	whatweb $1 -v > temp2 # run whatweb using the ip address
	fi
done < results

# check if temp files exist, & append output to main results file
if [ -e temp1 ]
then
	printf "\n------ DIRS ------\n\n" >> results
	cat temp1 >> results
	rm temp1
fi

if [ -e temp2 ]
then
	printf "\n------ WEB ------\n\n" >> results
	cat temp2 >> results
	rm temp2
fi

echo "------ OS ------" >> results
printf "\n" >> results

echo "Fingerprinting OS..."

nmap -O -p- $1 | tail -n +9 | head -n -4 >> results

cat results
