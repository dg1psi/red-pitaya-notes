#! /bin/sh

# CALL and GRID should be specified to enable uploads
CALL=
GRID=

JOBS=4
NICE=10

DIR=`readlink -f $0`
DIR=`dirname $DIR`

RECORDER=$DIR/write-c2-files
CONFIG=write-c2-files.cfg

DECODER=$DIR/ft8d-master/ft8d
ALLMEPT=ALL_FT8.TXT

SLEEP=$DIR/sleep-to-59

date

test $DIR/$CONFIG -ot $CONFIG || cp $DIR/$CONFIG $CONFIG

echo "Sleeping ..."

$SLEEP

sleep 1

date
TIMESTAMP=`date --utc +'%y%m%d_%H%M%S'`

echo "Recording ..."

killall -q $RECORDER
$RECORDER $CONFIG

echo "Decoding ..."

for file in ft8_*_$TIMESTAMP.c2
do
  while [ `pgrep $DECODER | wc -l` -ge $JOBS ]
  do
    sleep 1
  done
  nice -n $NICE $DECODER $file > $ALLMEPT &
done

wait

rm -f ft8_*_$TIMESTAMP.c2

test -n "$CALL" -a -n "$GRID" -a -s $ALLMEPT || exit

echo "Uploading ..."

# sort by highest SNR, then print unique date/time/band/call combinations,
# and then sort them by date/time/frequency
sort -nr -k 4,4 $ALLMEPT | awk '!seen[$1"_"$2"_"int($6)"_"$7] {print} {++seen[$1"_"$2"_"int($6)"_"$7]}' | sort -n -k 1,1 -k 2,2 -k 6,6 -o $ALLMEPT

rm -f $ALLMEPT
