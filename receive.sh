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

if [ ! -d ${NOAA_AUDIO}/map/ ]; then
	mkdir -p ${NOAA_AUDIO}/map/
fi

if [ ! -d ${NOAA_AUDIO}/predict/ ]; then
	mkdir -p ${NOAA_AUDIO}/predict/
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

PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python2 ${NOAA_HOME}/sun.py $PASS_START)
echo /usr/bin/nice -n 20 /usr/local/bin/wxmap -T "${1}" -H "${4}" -M 0 -p 0 -l 0 -o "${PASS_START}" ${NOAA_AUDIO}/map/"${3}"-map.png 
/usr/bin/nice -n 20 /usr/local/bin/wxmap -T "${1}" -H "${4}" -M 0 -p 0 -l 0 -o "${PASS_START}" ${NOAA_AUDIO}/map/"${3}"-map.png &

# Redirect STDERR to STDOUT
#exec 2>&1
#RTL_DEVICE_INDEX=`/home/pi/whichrtl.sh ${RTL_DEVICE}`
#echo Device ${RTL_DEVICE} index ${RTL_DEVICE_INDEX}
START_DATE=$(date '+%d-%m-%Y %H:%M')
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"
#timeout "${6}" /usr/local/bin/rtl_fm  -d "${DEVICE}" -f "${2}"M -s 50k -g "${RECEIVE_GAIN}" -E wav -E deemp -F 9 - | /usr/bin/sox -t wav - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025
#echo timeout "${6}" /usr/local/bin/rtl_fm -f "${2}"M -s 50k -g 100 -E wav -E deemp -F 9 - 
#echo timeout "${6}" /usr/bin/rtl_fm -g 50  -d "${RTL_DEVICE}" -f "${2}"M -s 50k -E wav -E deemp -F 9 - \| /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 50000 - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025
#timeout "${6}" /usr/bin/rtl_fm -g 12  -d "${RTL_DEVICE}" -f "${2}"M -s 50k -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 50000 - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025
#/usr/sbin/uhubctl -l 1-1 -p 2 -a 0
#sleep 2
#/usr/sbin/uhubctl -l 1-1 -p 2 -a 1
#sleep 5
echo timeout "${6}" /usr/bin/rtl_fm  -g "${RECEIVE_GAIN}"  -f "${2}"M -s 50k -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 50000 - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025
timeout "${6}" /usr/bin/rtl_fm  -g "${RECEIVE_GAIN}"  -f "${2}"M -s 50k -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 50000 - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025
if [ ! -d ${NOAA_OUTPUT}/image/${FOLDER_DATE} ]; then
	mkdir -p ${NOAA_OUTPUT}/image/${FOLDER_DATE}
fi

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
	ENHANCEMENTS="MCIR-precip ZA MCIR MSA MSA-precip HVC-precip HVCT-precip HVC HVCT"
else
	ENHANCEMENTS="MCIR-precip ZA MCIR"
fi

for i in $ENHANCEMENTS; do
	/usr/bin/nice -n 15 /usr/local/bin/wxtoimg -o -m ${NOAA_AUDIO}/map/"${3}"-map.png -e $i ${NOAA_AUDIO}/audio/"${3}".wav ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
	/usr/bin/nice -n 15 /usr/bin/convert -quality 90 -format jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE} MEL ${7}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
	if [ "${i}" = "MCIR-precip" ]; then
		/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg "${1} MCIR Precip MEL: ${7}" &
	fi
#	/home/pi/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} 
#	/usr/bin/gdrive upload --parent 1gehY-0iYkNSkBU9RCDsSTexRaQ_ukN0A ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
done

#if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
#	/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg "MCIR Precip MEL: ${7}"
#	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MSA-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVC-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVCT-precip.jpg 
#else
#	/usr/bin/python3 ${NOAA_HOME}/tpost.py ${TELEGRAM_TOKEN} ${TELEGRAM_CHAT_ID} ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg "MCIR Precip MEL: ${7}"
#	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR.jpg 
#fi

#cp ${NOAA_AUDIO}/audio/"${3}".wav /home/pi/
rm ${NOAA_AUDIO}/audio/"${3}".wav
rm ${NOAA_AUDIO}/map/"${3}"-map.png
/usr/bin/rsync --remove-source-files  -avz -e ssh /var/www/html/ wximg@10.42.42.2:noaarecv/
