#!/bin/bash

# Function definitions
print_usage() {
	echo "Usage: $0 -a <Algorithm> -r <Replicates> -s <Start> -e <End> -i <Input> -o <Output>"
	echo -e "\t-a | --algortithm\t-\tthe name of the algortithm: 'GLM', 'CTA', or 'RF'"
	echo -e "\t-r | --replicates\t-\tthe number of replicates: '1', '10', or '50'"
	echo -e "\t-s | --start\t\t-\tthe start index of the species to stack"
	echo -e "\t-e | --end\t\t-\tthe end index of the species to stack (inclusive)"
	echo -e "\t-i | --input\t\t-\tinput directory"
	echo -e "\t-o | --output\t\t-\toutput directory"
	echo -e "\t-h | --help\t\t-\tprint this message"
}

# Process arguments

## Check that there is the correct number of arguments
if [[ $# -lt 12 ]]; then
	echo "Missing arguments"
	print_usage
	exit 1	
fi

while [[ "$1" != "" ]]; do
	case $1 in
		-a | --algorithm )
			shift
			case $1 in
				GLM | CTA | RF )
					ALGORITHM=$1
					;;
				* )
					echo "Invalid algorithm"
					print_usage
					exit 1
			esac
			;;
		-r | --replicates )
			shift
			case $1 in
				1 | 10 | 50 )
					REPLICANT=$1
					;;
				* )
					echo "Invalid replicates"
					print_usage
					exit 1
			esac
			;;
		-s | --start )
			shift
			if [[ $1 -lt 0 ]]; then
				echo "Invalid start index"
				print_usage
				exit 1
			fi
			START=$1
			;;
		-e | --end )
			shift
			if [[ $1 -lt $START ]]; then
				echo "Invalid end index"
				print_usage
				exit 1
			fi
			END=$1
			;;
		-i | --input )
			shift
			if [[ ! -e $1 || ! -d $1 ]]; then
				echo "Invalid input directory"
				print_usage
				exit 1
			fi
			INPUT=${1%/}
			;;
		-o | --output )
			shift
			if [[ ! -e $1 || ! -d $1 ]]; then
				echo "Invalid output directory"
				print_usage
				exit 1
			fi
			OUTPUT=${1%/}
			;;
		-h | --help )
			print_usage
			exit 0
			;;
		* )
			echo "Unrecognized argument: $1"
			print_usage
			exit 1
			;;
	esac
	shift
done

# Get array of SDM directories
SDM_DIRS=($INPUT/*)

# Aggregate rasters to stack
for (( i = $START; i <= $END; i++ )); do
	# Untar SDMs
	tar xzvC $OUTPUT -f ${SDM_DIRS[$i]}/*$ALGORITHM*
	# Grab relevant raster files
	cp -n $OUTPUT/$ALGORITHM/year/*-bg$REPLICANT-*.gr* $OUTPUT
	# Remove unncessary files (png, gri, etc...)
	rm -rf $OUTPUT/$ALGORITHM
done
