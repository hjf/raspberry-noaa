#!/bin/sh

## debug
# set -x

. ~/.noaa.conf

## sane checks
if [ ! -d ${NOAA_HOME} ]; then
        mkdir -p ${NOAA_HOME}
fi

if [ ! -d ${NOAA_OUTPUT} ]; then
        mkdir -p ${NOAA_OUTPUT}
fi

if [ ! -d ${NOAA_AUDIO}/audio/ ]; then
        mkdir -p ${NOAA_AUDIO}/audio/
fi

if [ ! -d ${NOAA_OUTPUT}/image/ ]; then
        mkdir -p ${NOAA_OUTPUT}/image/
fi

if [ ! -d ${NOAA_HOME}/map/ ]; then
        mkdir -p ${NOAA_HOME}/map/
fi

if [ ! -d ${NOAA_HOME}/predict/ ]; then
        mkdir -p ${NOAA_HOME}/predict/
fi

#if pgrep "rtl_fm" > /dev/null
#then
#        exit 1
#fi

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

# Close STDOUT file descriptor
exec 1<&-
# Close STDERR FD
exec 2<&-

LOGFILE=${NOAA_AUDIO}/${3}
# Open STDOUT as $LOG_FILE file for read and write.
exec 1<>${LOGFILE}.log
exec 2<>${LOGFILE}.err
PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python2 ${NOAA_HOME}/sun.py $PASS_START)
if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
        echo "SUN ELEV: ${SUN_ELEV} OK "
else
        echo "SUN ELEV: ${SUN_ELEV} too low "
                exit 0
fi


START_DATE=$(date '+%d-%m-%Y %H:%M')
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"
/usr/bin/pkill rtl_fm
sleep 10


if [ ! -d ${NOAA_OUTPUT}/image/${FOLDER_DATE} ]; then
        mkdir -p ${NOAA_OUTPUT}/image/${FOLDER_DATE}
fi

if [ ! -d ${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE} ]; then
        mkdir -p ${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}
fi

echo timeout ${6} /usr/bin/rtl_fm -M raw -f 137.9M -s 120k -g 8 -p 1 | sox -t raw -r 120k -c 2 -b 16 -e s - -t wav "/home/pi/${3}.wav" rate 96k
timeout ${6} /usr/bin/rtl_fm -M raw -f 137.9M -s 120k -g 8 -p 1 | sox -t raw -r 120k -c 2 -b 16 -e s - -t wav "/home/pi/${3}.wav" rate 96k
echo /usr/bin/meteor_demod -B -o "${NOAA_AUDIO}/${3}.qpsk" "/home/pi/${3}.wav"
/usr/bin/meteor_demod -B -o "${NOAA_AUDIO}/${3}.qpsk" "/home/pi/${3}.wav"
echo touch -r "/home/pi/${3}.wav" "${NOAA_AUDIO}/${3}.qpsk"
touch -r "/home/pi/${3}.wav" "${NOAA_AUDIO}/${3}.qpsk"
echo rm "/home/pi/${3}.wav"
#rm "/home/pi/${3}.wav"
echo /usr/bin/medet_arm "${NOAA_AUDIO}/${3}.qpsk" "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}" -cd
/usr/bin/medet_arm "${NOAA_AUDIO}/${3}.qpsk" "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}" -cd
echo rm "${NOAA_AUDIO}/${3}.qpsk"
rm "${NOAA_AUDIO}/${3}.qpsk"
echo /usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_122" -r 65 -g 65 -b 64 -d
/usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_122" -r 65 -g 65 -b 64 -d
echo /usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_122.bmp" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg
/usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_122.bmp" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg
echo rm "${NOAA_AUDIO}/${3}_122.bmp"
rm "${NOAA_AUDIO}/${3}_122.bmp"

echo /usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg "Meteor M2 False Color. MEL ${7}"
/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg "Meteor M2 False Color. MEL ${7}"

rm ${NOAA_AUDIO}/audio/*
