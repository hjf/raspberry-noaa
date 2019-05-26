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

if pgrep "rtl_fm" > /dev/null
then
        exit 1
fi

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

START_DATE=$(date '+%d-%m-%Y %H:%M')
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"
/usr/bin/killall rtl_fm
sleep 10
rm -f ${NOAA_AUDIO}/meteor_iq
mkfifo ${NOAA_AUDIO}/meteor_iq
timeout ${6} /usr/bin/meteor_demod -s 140000 ${NOAA_AUDIO}/meteor_iq -B -o ${NOAA_AUDIO}/"${3}".s &
/usr/bin/rtl_fm -M raw -s 140000 -f ${2}M -E dc -g 10 -p 0 ${NOAA_AUDIO}/meteor_iq
rm ${NOAA_AUDIO}/meteor_iq

sleep 10

if [ ! -d ${NOAA_OUTPUT}/image/${FOLDER_DATE} ]; then
        mkdir -p ${NOAA_OUTPUT}/image/${FOLDER_DATE}
fi

/usr/bin/medet_arm ${NOAA_AUDIO}/"${3}".s ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}" -r 65 -g 65 -b 64

/usr/bin/convert -quality 90 -format jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".bmp -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg
/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg "Meteor M2 False Color"


#/usr/local/bin/wxmap -T "${1}" -H "${4}" -p 0 -l 0 -o "${PASS_START}" ${NOAA_HOME}/map/"${3}"-map.png
#for i in $ENHANCEMENTS; do
#        /usr/local/bin/wxtoimg -o -m ${NOAA_HOME}/map/"${3}"-map.png -e $i ${NOAA_AUDIO}/audio/"${3}".wav ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
#        /usr/bin/convert -quality 90 -format jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
#       /home/pi/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID}
#       /usr/bin/gdrive upload --parent 1gehY-0iYkNSkBU9RCDsSTexRaQ_ukN0A ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
#done

#if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
#        /usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg "MCIR Precip"
#       python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MSA-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVC-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVCT-precip.jpg
#else
#        /usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg "MCIR Precip"
#       python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR.jpg
#fi

rm ${NOAA_AUDIO}/audio/*
