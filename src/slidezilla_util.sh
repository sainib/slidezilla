#!/bin/bash
#    slidezilla
#    Copyright (c) 2013 Biren Saini
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#

extractImgsFromVideo()
{
#Calculate the approximate number of frames from the video given the fps
expected_frame_count=`echo "scale=0; ( $video_duration_in_secs * $fps ) + 5"|bc`

#Determine the frameCountFormat
inFrameCountFormat="3"
if [ $expected_frame_count -gt 1000 ]; then
inFrameCountFormat="4"
fi
if [ $expected_frame_count -gt 10000 ]; then
inFrameCountFormat="5"
fi
if [ $expected_frame_count -gt 100000 ]; then
inFrameCountFormat="6"
fi

case "$inFrameCountFormat" in 
3)
`ffmpeg -i $media_path -s $video_extract_img_size -r ${fps} -f image2 $INPUT_FRAMES/${video_extract_img_prefix}-%03d.${video_extract_img_format}`
;;
4)
`ffmpeg -i $media_path -s $video_extract_img_size -r ${fps} -f image2 $INPUT_FRAMES/${video_extract_img_prefix}-%04d.${video_extract_img_format}`
;;
5)
`ffmpeg -i $media_path -s $video_extract_img_size -r ${fps} -f image2 $INPUT_FRAMES/${video_extract_img_prefix}-%05d.${video_extract_img_format}`
;;
6)
`ffmpeg -i $media_path -s $video_extract_img_size -r ${fps} -f image2 $INPUT_FRAMES/${video_extract_img_prefix}-%06d.${video_extract_img_format}`
;;
esac

}

getVideoDuration()
{

if [ ! -f "$1" ] ; then
	 echo "0"
fi

duration_hhmmss=`ffmpeg -i $1 2>&1 | grep Duration | awk -F',' '{ print $1 }' | awk '{print $2 }' | awk -F'.' '{print $1}' `

duration_hh=`echo $duration_hhmmss | awk -F':' '{ print $1 }'`
duration_mm=`echo $duration_hhmmss | awk -F':' '{ print $2 }'`	
duration_ss=`echo $duration_hhmmss | awk -F':' '{ print $3 }'`

duration_in_secs=`echo "( $duration_hh * 3600 ) + ( $duration_mm * 60 ) + $duration_ss"|bc`

echo $duration_in_secs

}


copyFilesToDirectory()
{

toDir="$1"
shift
for file in $@
do

cp $file $toDir

done

}



moveFilesToDirectory()
{

toDir="$1"
shift
for file in $@
do

mv $file $toDir

done

}


getImageHeight()
{
img_size=`getImageSize $1`
img_ht=`echo $img_size | awk -F'x' '{ print $2 }'`
echo $img_ht
}

getImageWidth()
{
img_size=`getImageSize $1`
img_wd=`echo $img_size | awk -F'x' '{ print $1 }'`
echo $img_wd
}


getImageSize()
{
if [ -f $1 ]; then
echo `identify -verbose $1 | grep Geometry | awk -F':' '{ print $2 }' | awk -F '+' '{ print $1 }'`
else
echo "0x0"
fi
}

#--------------------------------------------------------------------------------------------------#
# So this method will do the following 
# A - Determine the length of the video being created using the number of frames and fps
# B - From the input music file, create a music file with the length of the video (trim or append)
# C - Return the path of the file to the caller methods
#-------------------------------------------------------------------------------------------------#


mixMusic()
{

if [ ! -f ${audio_filename} ]; then
echo "Important Message: The audio file [${audio_filename}] does not exist. Fix the property file and try again!"
forcequit
fi

#Calculating the final video duration
finalFrameCount=`ls $VIDEODIR/${video_extract_img_prefix}* | wc -l | awk '{print $1}'`
finalVidDuration=`echo "scale=0; ( $finalFrameCount / $fps ) + 5"|bc`
audioFileDuration=`getVideoDuration ${audio_filename}`

if [ "$finalVidDuration" -le "$audioFileDuration" ]; then
audiofilename=`basename ${audio_filename}`
`cp ${audio_filename} $VIDEODIR/$audiofilename`

cutoff=$(( $audio_fade_trim * 2 ))
if [ $finalVidDuration -gt $cutoff ]; then
cutoff=$finalVidDuration
fi

`sox $VIDEODIR/$audiofilename $VIDEODIR/szaudio_${audiofilename} fade $audio_fade_trim $cutoff $audio_fade_trim`
else
audioFileCount=`echo "scale=0; ( $finalVidDuration / $audioFileDuration ) + 0.5"|bc`
`cp ${audio_filename} $VIDEODIR/$audiofilename`

new_audio_trim_length=$(( $audio_fade_trim / 2 ))
if [ $new_audio_trim_length -le 0 ]; then
new_audio_trim_length=1
fi

sox $VIDEODIR/$audiofilename $VIDEODIR/szaudio_${audiofilename} fade $new_audio_trim_length $audioFileDuration $new_audio_trim_length
f=1
cp $VIDEODIR/szaudio_${audiofilename} $VIDEODIR/szaudio_tmp_${audiofilename}
while [ $f -lt $audioFileCount ]
do
sox $VIDEODIR/szaudio_tmp_${audiofilename} $VIDEODIR/szaudio_${audiofilename} $VIDEODIR/szaudio_tmp_${audiofilename}  splice
done

rm $VIDEODIR/szaudio_${audiofilename}
mv $VIDEODIR/szaudio_tmp_${audiofilename} $VIDEODIR/szaudio_${audiofilename}

sox $VIDEODIR/szaudio_${audiofilename} $VIDEODIR/szaudio_tmp_${audiofilename} fade $audio_fade_trim $finalVidDuration $audio_fade_trim

rm $VIDEODIR/szaudio_${audiofilename}
mv $VIDEODIR/szaudio_tmp_${audiofilename} $VIDEODIR/szaudio_${audiofilename}

fi

rm $VIDEODIR/$audiofilename

echo $VIDEODIR/szaudio_${audiofilename}
#ffmpeg -i $VIDEODIR/szaudio_${audiofilename} -i $VIDEODIR/${outputfilename} $VIDEODIR/tmp_${outputfilename}
#mv $VIDEODIR/tmp_${outputfilename} $VIDEODIR/${outputfilename}

}