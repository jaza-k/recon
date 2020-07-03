#!/bin/bash
# script to perform recon and gather information on a given IP address

# if no arguments passed, display usage info
if [ -z "$1" ]
then
	echo "Usage: ./recon.sh <IP address>"
	exit 1
fi

# create new file to store results, overwritten with subsequent scans
printf "\n------ NMAP ------\n\n" > results

echo "Running Nmap scan..."

# run nmap w/ the ip address provided and send results to file
nmap $1 | head -n -5 | tail -n +3 >> results

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

cat results
