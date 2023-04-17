#!/bin/bash

YEAR=$1
MONTH=$2
DAY=$3
CALLFILENAME=$4
MIXMON_FORMAT=$5
SPOOLDIR="/var/spool/asterisk/monitor"
INOUTSTEREODIR="/var/www/html/stereo/"


MP3FILENAME=${CALLFILENAME}.mp3
WAVFALINEAME=${CALLFILENAME}.wav


WAVFILE=${SPOOLDIR}/${YEAR}/${MONTH}/${DAY}/${CALLFILENAME}.${MIXMON_FORMAT}
INWAV=${SPOOLDIR}/${YEAR}/${MONTH}/${DAY}/${CALLFILENAME}.wav-in.${MIXMON_FORMAT}
OUTWAV=${SPOOLDIR}/${YEAR}/${MONTH}/${DAY}/${CALLFILENAME}.wav-out.${MIXMON_FORMAT}

# 5 секунд после hangup
sleep 5

# cлияние двух файлов в формате стерео и с разделением каналов
sox -M ${INWAV} ${OUTWAV} ${WAVFILE}

# проверяем наличие файла записи
/usr/bin/test ! -e ${WAVFILE} && exit 21

MP3FILE=echo ${WAVFILE} | /bin/sed 's/.wav/.mp3/g'

# конвертируем wav в mp3
/usr/bin/lame --quiet --preset standard -h -v ${WAVFILE} ${MP3FILE}

# обновляем данные в базе
mysql -uroot --execute='UPDATE asteriskcdrdb.cdr SET recordingfile="'$MP3FILENAME'" WHERE recordingfile="'$WAVFALINEAME'";';

# выставляем нужные права на файл
/usr/bin/chown --reference=${WAVFILE} ${MP3FILE}
/usr/bin/chmod --reference=${WAVFILE} ${MP3FILE}
/usr/bin/touch --reference=${WAVFILE} ${MP3FILE}

# удаляем ненужный файл
/usr/bin/test -e ${MP3FILE} && /usr/bin/rm -f ${WAVFILE}

# переносим записи с разлененных каналов
/usr/bin/mv ${INWAV} ${INOUTSTEREODIR}
/usr/bin/mv ${OUTWAV} ${INOUTSTEREODIR}
