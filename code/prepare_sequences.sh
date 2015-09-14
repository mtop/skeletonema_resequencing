#!/bin/bash
# Enable history expantion in order to save the comands to the log-file.
set -o history -o histexpand

# Files and directories
#SUB_DIR="150723_BC6T2NANXX"
file1=$(ls $SUB_DIR/*_1.fastq)
file2=$(ls $SUB_DIR/*_2.fastq)

# Options
# fastx_trimmer
	# First base to keep
	F=11

# cutadapt
	# Adaptors to trim
	A1="AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT"
	A2="GATCGGAAGAGCACACGTCTGAACTCCAGTCACATCACGATCTCGTATGCCGTCTTCTGCTTG"

	# quality threshold for the 3' trimming.
	Q=15	

	# Minimum number of bases overlaping with the adaptor sequence.
	O=10

	# Maximum error rate when identifying adaptors. 2> cutadapt.log
	E="0.1"	
	N=1
	M=50

# fastq_quality_filter
	K=20
	P=95

# Log-files
LOGFILE=${PWD##*/}.log
ERROR=${PWD##*/}.err
CU_LOG=${PWD##*/}.cutadapt.log
PAIR_LOG=${PWD##*/}.pairSeq.log
date >> $LOGFILE
printf "\n" >> $LOGFILE
# Log versions of programs used
echo "# Versions of software used:" >> $LOGFILE
echo $(fastx_trimmer -h) >> $LOGFILE
printf "\n" >> $LOGFILE
echo "cutadapt: " $(cutadapt --version) >> $LOGFILE
printf "\n" >> $LOGFILE

# Print some informative error meassages
err() {
    echo "$1 exited unexpectedly";
        exit 1;
	}

# Function for checking the exit code of a child process
ckeckExit() {
if [ "$1" == "0" ]; then
	printf "[Done] $2 `date`\n\n" >> $LOGFILE;
	else
		err "[Error] $2 returned non-0 exit code in $PWD" >> $LOGFILE;
		fi
		}

#for dir in /nobackup/data6/sylvie/Resequenced_Strains_Godhe_15_01/*
#do
#	cd $dir/*
#	echo $PWD
#    	fastqc *.fastq.gz
	# Gunzip the fastq files
	gunzip $file1 2> $ERROR
	gunzip $file2 2> $ERROR

	# Trim 5' end of reads
	printf "# fastx_trimmer\n" >> $LOGFILE
	printf "[ `date` ]\n" >> $LOGFILE
	fastx_trimmer -Q33 -i $file1 -f $F -o "$SUB_DIR/${file1%.fastq}.FXT.fastq" 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "fastx_trimmer on file 1"
	printf "[ `date` ]\n" >> $LOGFILE
	fastx_trimmer -Q33 -i $file2 -f $F -o "$SUB_DIR/${file2%.fastq}.FXT.fastq" 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "fastx_trimmer on file 2"
	
	# Remove adaptors
	printf "\n# cutadapt\n" >> $LOGFILE
	printf "[ `date` ]\n" >> $LOGFILE
	cutadapt -b $A1 -b $A2 -q $Q -O $O -e $E -n $N -m $M -o "$SUB_DIR/${file1%.fastq}.FXT.CA.fastq" "${file1%.fastq}.FXT.fastq" >> $CU_LOG 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "cutadapt on file 1"
	printf "[ `date` ]\n" >> $LOGFILE
	cutadapt -b $A1 -b $A2 -q $Q -O $O -e $E -n $N -m $M -o "$SUB_DIR/${file2%.fastq}.FXT.CA.fastq" "${file2%.fastq}.FXT.fastq" >> $CU_LOG 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "cutadapt on file 2"

	# Quality filtering
	printf "\n# fastq_quality_filter\n" >> $LOGFILE
	printf "[ `date` ]\n" >> $LOGFILE
	fastq_quality_filter -Q33 -q $K -p $P -i "${file1%.fastq}.FXT.CA.fastq" -o "$SUB_DIR/${file1%.fastq}.FXT.CA.FQF.fastq" 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "fastq_quality_filter on file 1"
	printf "[ `date` ]\n" >> $LOGFILE
	fastq_quality_filter -Q33 -q $K -p $P -i "${file2%.fastq}.FXT.CA.fastq" -o "$SUB_DIR/${file2%.fastq}.FXT.CA.FQF.fastq" 2>> $ERROR
		echo !! >> $LOGFILE
		ckeckExit $? "fastq_quality_filter on file 2"

	# Sort paired and singlet reads
	printf "\n# pairSeq.py\n" >> $LOGFILE
	printf "[ `date` ]\n" >> $LOGFILE
	pairSeq.py "${file1%.fastq}.FXT.CA.FQF.fastq" "${file2%.fastq}.FXT.CA.FQF.fastq" " " 2>> $ERROR >> $PAIR_LOG
		echo !! >> $LOGFILE
		ckeckExit $? "fastq_quality_filter on file 1"
	
	# Quality check
	fastqc "${file1%.fastq}.FXT.CA.FQF.fastq"
	fastqc "${file2%.fastq}.FXT.CA.FQF.fastq"

#done