#!/bin/bash
# network reconnaissance script to gather information on a given IP address

RED=`tput setaf 196`
GREEN=`tput setaf 34`
YELLOW=`tput setaf 3`
NOCOLOR='\033[0m'

# check if nmap is installed
if [[ ! -x $NMAP ]]; then
	echo "This script requires Nmap"
	exit 1
fi

# check if ipcalc is installed
if ! command -v "ipcalc" > /dev/null; then
	echo "This script requires Ipcalc"
	exit 1
fi

# check for proper privileges
if [[ $EUID -ne 0 ]]; then
	echo "Run as root"
	exit 1
fi

# if illegal/no arguments passed, display usage info
if [ -z "$1" ] || [[ $# -ne 2 ]]; then
	echo "Usage: ./recon.sh <target IP address> <your IP address>"
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
nmap -p- -sV -Pn $1 | tail -n +4 | head -n -4 >> results

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
nmap -A $1 | tail -n +9 | head -n -4 >> results

echo -e "${GREEN}Calculating IP network information...${NOCOLOR}"

# code block to determine subnet range
network=$(ipcalc $1 | tail -n +5 | head -n -5)
IFS=' '
array=( $network )
SUBNET=${array[1]}

printf "\n${YELLOW}------ THIS NETWORK ------${NOCOLOR}\n\n" >> results
# use ipcalc & target ip address to find network information
ipcalc $1 >> results

printf "${YELLOW}------ MAC/IP ADDRESSES ------${NOCOLOR}" >> results

echo -e "${GREEN}Retrieving discovered MAC/IP addresses on network...${NOCOLOR}"

printf "Hosts found on network: \n\n" >> results
# scan subnet range for live hosts & their mac/ip addresses
nmap -sn ${SUBNET} | tail -n + 3 >> results

printf "\n" >> results
cat results
