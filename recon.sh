#!/bin/bash
# reconnaissance script to gather information on a given IP address

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
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
	echo "Usage: ./recon.sh <target IP address>"
	exit 1
fi

echo -e "${RED}
 _ __ ___  ___ ___  _ __  
| '__/ _ \/ __/ _ \| '_ \ 
| | |  __/ (_| (_) | | | |
|_|  \___|\___\___/|_| |_|
${NOCOLOR}                                                      "

printf "Hello, $2\n\n\n"

# create new file to store results, overwritten with subsequent scans
printf "\n\n${YELLOW}------ NMAP ------${NOCOLOR}\n\n" > results

echo -e "${GREEN}Running Nmap scan on target...${NOCOLOR}"

printf "Open ports found on target machine: \n\n" >> results
# run nmap w/ the ip address provided and send results to file
nmap -p- -Pn $1 | tail -n +4 | head -n -1 >> results

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

echo -e "${YELLOW}------ OS ------${NOCOLOR}" >> results
printf "\n" >> results

echo -e "${GREEN}Fingerprinting OS...${NOCOLOR}"

# enable OS detection w/ nmap
nmap -O -p- $1 | tail -n +9 | head -n -4 >> results

printf "${YELLOW}------ MAC/IP ADDRESSES ------${NOCOLOR}" >> results

echo -e "${GREEN}Retrieving discovered MAC/IP addresses on network...${NOCOLOR}"

printf "Hosts found on network: \n\n" >> results
# scan network for live hosts & their ip/mac addresses
nmap -sn 192.168.1.0/24 | tail -n + 3 >> results

printf "\n" >> results
cat results
