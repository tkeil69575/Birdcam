#!/bin/bash
# this script should run daily and look for a folder from the previous day
# in the folder it creates two lists, sorting the files into either sunrise
# or sunset lists. Then it creates a sunrise and sunset video based on the 
# files in the respective lists.
# original format of images = 2560x1920 Pixel (4:3)

# dependencies = ffmeg, w3m
# Note: if cpu does not support hw acceleration and/or is not an Intel cpu
# it will be necessary to change the ffmeg command line to libx264 or other
# supported software codecs 

make_vid=1 # 1 = create videos, 0 = do not create videos

lat=48.89816
lng=8.671611
yd1=$(date -d "yesterday" +"%Y-%m-%d")
yd2=$(date -d "yesterday" +"%Y%m%d")
folder1="/mnt/server/ftp/birdcam2/${yd2}/images"
folder2="/mnt/server/media/Videos/Home Movies/Birds/sunrise_sunset"

#result in UTC time, so need to convert to local time
api_call=$(w3m "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&date=$yd1")

#echo $api_call

sunrise=$(echo "$api_call" | grep -oP '(?<="sunrise":")[^"]*')
sunset=$(echo "$api_call" | grep -oP '(?<="sunset":")[^"]*')

#set sunrise/sunset to local time
sunrise_begin=$(date -d "$sunrise UTC - 60 minutes" +"%H:%M:%S")
sunrise_end=$(date -d "$sunrise UTC + 20 minutes" +"%H:%M:%S")

sunset_begin=$(date -d "$sunset UTC + 20 minutes"  +"%H:%M:%S")
sunset_end=$(date -d "$sunset UTC + 60 minutes"  +"%H:%M:%S")

#frames per second
fps=50

if [[ -f "${folder1}/files_sunrise.txt" || -f "${folder1}/files_sunset.txt" ]]; then

  echo "please delete file lists first"
  exit
  
else

  #create file list
  echo "Creating list of images for"
  echo "sunrise (${sunrise_begin} and ${sunrise_end}) and"
  echo "sunset (${sunset_begin} and ${sunset_end})"
    
  for file in `ls -tr $folder1/*.jpg`; do
  
    filedate=$(stat --format "%y" ${file})
    
    #format times for comparision in if statement
    filetime="${filedate:11:2}${filedate:14:2}${filedate:17:2}" 
    
    sunrise_begin1="${sunrise_begin:0:2}${sunrise_begin:3:2}${sunrise_begin:6:2}"
    sunrise_end1="${sunrise_end:0:2}${sunrise_end:3:2}${sunrise_end:6:2}"
    
    sunset_begin1="${sunset_begin:0:2}${sunset_begin:3:2}${sunset_begin:6:2}"
    sunset_end1="${sunset_end:0:2}${sunset_end:3:2}${sunset_end:6:2}"
        
    #add images to sunrise or sunset file list
    if [[ (${filetime} > ${sunrise_begin1}) && (${filetime} < ${sunrise_end1}) ]]; then
      #echo "${filetime} > ${sunrise_begin1}"
      echo file "'"${file}"'" >> ${folder1}/files_sunrise.txt
    elif [[ (${filetime} > ${sunset_begin1}) && (${filetime} < ${sunset_end1}) ]]; then 
      #echo "${filetime} > ${sunset_begin1}"
      echo file "'"${file}"'" >> ${folder1}/files_sunset.txt
    fi
  done
  
  echo "~~~~"
  sleep 5
  
  if [[ -f "${folder2}/sunrise_${yd1}.mp4" && -f "${folder2}/sunset_${yd1}.mp4" ]]; then
  
    echo "please delete videos first"
    exit
  
  else 
  
    if [[ ${make_vid} == 1 ]]; then
      #create sunrise video with vaapi hardware acceleration
      echo "creating video for sunrise"
      ffmpeg -f concat -safe 0 -threads 1 -i ${folder1}/files_sunrise.txt -an -framerate ${fps} -vaapi_device /dev/dri/renderD128 -vcodec h264_vaapi -vf format='nv12|vaapi,hwupload,scale_vaapi=iw/2:ih/2' "${folder2}/sunrise_${yd1}.mp4"
  
      echo "~~~~"
      sleep5
  
      #create sunset video with vaapi hardware acceleration
      echo "creating video for sunset"
      ffmpeg -f concat -safe 0 -threads 1 -i ${folder1}/files_sunset.txt -an -framerate ${fps} -vaapi_device /dev/dri/renderD128 -vcodec h264_vaapi -vf format='nv12|vaapi,hwupload,scale_vaapi=iw/2:ih/2' "${folder2}/sunset_${yd1}.mp4"
    fi
    
  fi

fi

if [[ -f "${folder2}/sunrise_${yd1}.mp4" &&  -f "${folder2}/sunset_${yd1}.mp4" ]]; then
  echo "deleting birdcam folder of the day..."
  #rm -R ${folder1}
fi
