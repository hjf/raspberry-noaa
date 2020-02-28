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
#                exit 0
fi


START_DATE=$(date '+%d-%m-%Y %H:%M')
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"
/usr/bin/pkill rtl_fm
sleep 5


if [ ! -d ${NOAA_OUTPUT}/image/${FOLDER_DATE} ]; then
        mkdir -p ${NOAA_OUTPUT}/image/${FOLDER_DATE}
fi

if [ ! -d ${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE} ]; then
        mkdir -p ${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}
fi
echo /usr/bin/killall rtl_fm
/usr/bin/killall -q rtl_fm
sleep 5

rm -f /tmp/meteor_iq

echo mkfifo /tmp/meteor_iq
mkfifo /tmp/meteor_iq
echo /usr/bin/meteor_demod -B -s 144k /tmp/meteor_iq -o "${NOAA_AUDIO}/${3}.qpsk" 
nice -n 10 /usr/bin/meteor_demod -B -R 1000 -b 80 -s 144k /tmp/meteor_iq -o "${NOAA_AUDIO}/${3}.qpsk" &
echo timeout ${6} /usr/bin/rtl_fm -M raw -s 144k -f "${2}"M -E dc -g "${RECEIVE_GAIN}" /tmp/meteor_iq
#timeout ${6} /usr/bin/rtl_fm -M raw -s 144k -f "${2}"M -E dc -g "${RECEIVE_GAIN}" /tmp/meteor_iq
timeout ${6} /usr/bin/rtl_fm -M raw -s 144k -f "${2}"M -g 25 -E dc /tmp/meteor_iq
sleep 5
echo rm -f /tmp/meteor_iq
rm -f /tmp/meteor_iq

echo /usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_AUDIO}/${3}.qpsk" "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}" -cd
/usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_AUDIO}/${3}.qpsk" "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}" -cd -na
echo rm "${NOAA_AUDIO}/${3}.qpsk"
rm "${NOAA_AUDIO}/${3}.qpsk"
echo /usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_122" -r 65 -g 65 -b 64 -d
/usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_122" -r 65 -g 65 -b 64 -d -na
echo /usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_122" -r 65 -g 65 -b 64 -d
/usr/bin/nice -n 10 /usr/bin/medet_arm "${NOAA_OUTPUT}/meteor_raw/${FOLDER_DATE}/${3}.dec" "${NOAA_AUDIO}/${3}_IR" -r 68 -g 68 -b 68 -d -na
echo /home/pi/meteor_rectify/rectify.py "${NOAA_AUDIO}/${3}_122.bmp"
/home/pi/meteor_rectify/rectify.py "${NOAA_AUDIO}/${3}_122.bmp"
echo /home/pi/meteor_rectify/rectify.py "${NOAA_AUDIO}/${3}_IR.bmp"
/home/pi/meteor_rectify/rectify.py "${NOAA_AUDIO}/${3}_IR.bmp"
echo /usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_122-rectified.png" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}_122".jpg
/usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_122-rectified.png" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}_122".jpg
echo /usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_IR-rectified.png" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}_IR".jpg
/usr/bin/convert -quality 90 -format jpg "${NOAA_AUDIO}/${3}_IR-rectified.png" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg
echo rm "${NOAA_AUDIO}/${3}_122.bmp"
rm "${NOAA_AUDIO}/${3}_122.bmp"
echo rm "${NOAA_AUDIO}/${3}_122-rectified.png"
rm "${NOAA_AUDIO}/${3}_122-rectified.png"

echo rm "${NOAA_AUDIO}/${3}_IR.bmp"
rm "${NOAA_AUDIO}/${3}_IR.bmp"
echo rm "${NOAA_AUDIO}/${3}_IR-rectified.png"
rm "${NOAA_AUDIO}/${3}_IR-rectified.png"

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
echo /usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg "Meteor M2 False Color. MEL ${7}"
/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}_122".jpg "Meteor M2 False Color. MEL ${7}"
else
echo /usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}_IR".jpg "Meteor M2 IR MEL ${7}"
/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}".jpg "Meteor M2 False Color. MEL ${7}"

fi


#rm ${NOAA_AUDIO}/audio/*
