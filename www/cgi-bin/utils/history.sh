#!/bin/sh

DATE=`date "+%Y%m%d-%H%M%S"`
PWD=`pwd`
FILENAME_SIZE="${PWD}/history/size_${DATE}.txt"
FILENAME_TOTAL="${PWD}/history/total_${DATE}.txt"

PROG_SIZE="${PWD}/size.pl";
PROG_TOTAL="${PWD}/total.pl";

`
