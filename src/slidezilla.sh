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


#-------------------------- Starting the program ------------------------# 

name='slidezilla'
version='0.0.1'

echo "slidezilla $version"
echo "Licensed under the GNU GPL"
echo "Copyright (c) 2013 Biren Saini"
echo ""

#-------------------------- Change log, To do etc.. ------------------------# 



## TODO: (sorted by priority?)

# Short term TODO
#  Add slide effects (3) : Kenburn (Up, Left, Right, Down, Diagonal), Kenburn with style - 1
#  Add Transitions   (3) : Doorway,Swap      


# Mid Term TODO
#  Time loggig
#  Fix the logging so that it only prints according to current logging level..

#--Long term TODO
#  Add more slide effects and transitions - http://www.fmwconcepts.com/imagemagick/fxtransitions/index.php for ideas
#  Move the createTitle and createTransitions outside the last loop and code for mutlithreaded processing for each of these steps
#  - So when creating title, spawn a thread to create all titles for one slide and second thread for second slide etc..
#  - We should control the number of threads running
#  May be we should allow teh input control file to have global font parameter to override the default title font_type param
#  Detect input media type automatically.. 
# Instead of copying the file from title effect and transition to tmp_video, rename the files in their folder and mv szimg* to tmp_video
# Even better number the images in sequence at the output file level and not at slide level so we can just move the files..
# Explore using Spumux for writing subtitles..http://dvdauthor.sourceforge.net/doc/spumux.html

## known bugs:
####################


#-------------------------- Very High Level params.. ------------------------# 

echo $PATH
if [ $PATH == '' ]; then
export PATH=/opt/local/bin:/opt/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:
fi

 if [ -f "`which $0`" ]; then
	export BINDIR=`which $0`
 else
	cmdRunDir=`pwd`
	cd `dirname $0`
	export BINDIR=`pwd`
	cd $cmdRunDir
 fi

## set up bash variables  http://wiki.sourcemage.org/HOWTO-Locale_problems
#LC_ALL=C
#LANG="POSIX"

#-------------------------- Function changes() ------------------------# 
changes ()
{
echo 'Changes:
0.0.1
	First Version..

';
}

#-------------------------- Function help() ------------------------# 

help ()
{
echo ""
echo "`basename $0` Version $version "
echo 'http://website-tbd-mostlikely-github.com'
echo 'Copyright 2003-2011 Birender Saini <birender dot saini at gmail dot com>'
echo 	 
echo 'Description: 
	Creates a video slidshow from a bunch of images. Supports several effects
	like fadein/fadeout/crossfade/crop/kenburns and transitions..

Usage:
 slidezilla [-d for debug] [-o for overwrite] [-v verbose 0-2] [-nc for nocleanup]
 	[-t for multithread if possible] [-cf control file]
 
 The control file options overview is as below. For complete documentation, go to 
 the software home page.
	
Options: 
	TBD....

'
	echo '  '
}

#-------------------------- Function checkAudioFile() ------------------------# 

checkAudioFile(){

                # make sure the file exists and is the correct type!
                suffix=`echo "$1" | awk -F. '{print tolower($NF)}'`
                if [ "$suffix" == 'ogv' ] || [ "$suffix" == 'mp3' ] || [ "$suffix" == 'wav' ] || [ "$suffix" == 'm4a' ] || [ "$suffix" == 'aac' ] ; then
                	if [ ! -f "$1" ] ; then
                       	 echo "[slidezilla] ERROR: File $1 does not exist"
                         exit 1
                        fi
                        passed_audio[$m]="$1"
                        let m=$m+1
						commandline_audiofiles=$(( $commandline_audiofiles + 1 ))
                        shift;
                else
                       	 echo "[slidezilla] ERROR: File $1 is not an ogg, mp3, m4a, aac, or wav file."
                         exit 1
                fi


}

#-------------------------- Function myecho() ------------------------# 

myecho ()
{
	## use this version of echo to write to screen and to the logfile:
	if [ "$quiet" == 0 ] ; then
		echo "$*"
	fi
	echo "$*" >> "$outdir/$logfile"
}

logecho ()
{
	## use this version of echo to write to the logfile:
	echo "$*" >> "$outdir/$logfile"
}

myechon ()
{
	## use this version of echo to write to screen and to the logfile:
	echo -n "$*"
	echo -n "$*" >> "$outdir/$logfile"
}


#check_rm ()
#{
#	if [ -f "$1" ] ; then
#		rm "$1"
#	fi
#}

cleanup ()
{
if [ "$nocleanup" -eq 0 ] ; then
	## clean up temporary files
	myecho "[slidezilla] cleanup..."
	rm -f temp_slideshow_image.ppm ; rm -f temp.ppm
	rm -f temp_slideshow_image_scaled.ppm
	rm -f "$outdir/$tmptxtfile"
	# close pipe to ffmpeg/mpeg2enc  ( close file descriptor 9 )
        exec 9>&-  
        rm -f "$tmpdir/$yuvfifo"
        if [ "$yuvpid" -ne 0 ]; then
        	kill -TERM $yuvpid
        fi
	# Now try deleting tempdir:
	rm -rf "$tmpdir"
fi
}

forcequit () ## function gets run when we have some sort of forcequit...
{
	## clean up temporary files
	cleanup
	exit 1
}

trap 'forcequit' INT
trap 'forcequit' KILL
trap 'forcequit' TERM

## check for the necessary programs:
checkforprog ()
{
        it=`which $1 2> /dev/null`
        if [ -z "$it" ] ; then
                myecho "[slidezilla] ERROR: $1 not found! "
                myecho "[slidezilla] Check the dependencies and make sure everything is installed."
                exit 1
        fi
}

checkfor_oggdec ()
{
        it=`which oggdec 2> /dev/null`
        if [ -z "$it" ] ; then
		myecho ""
                myecho "[slidezilla] ERROR: oggdec not found! "
                myecho "[slidezilla] You need to download the vorbis-tools package"
		myecho "[slidezilla] in order to use .ogg audio files."
		myecho "[slidezilla] Debian/Ubuntu: sudo apt-get install vorbis-tools"
                exit 1
        fi
}

checkfor_lame ()
{
        it=`which lame 2> /dev/null`
        if [ -z "$it" ] ; then
                myecho "[slidezilla] ERROR: lame not found! "
                myecho "[slidezilla] You need to download the lame package"
		myecho "[slidezilla] in order to use .mp3 audio files."
		myecho "[slidezilla] Debian/Ubuntu: sudo apt-get install lame"
                exit 1
        fi
}

hms ()  # HMS
{
	## pass a number in thousandths of seconds and get back a 
	## time code of the form HR:MM:SS.XXX
	if [ -z "$1" ] ; then
		logecho "[slidezilla] Error in hms function: no input"	
		function_error=1
	else
		hours=$(( $1 / 3600000 )) ; [ $hours -eq 0 ] && hours="0" 
		it=$(( $1 - $hours * 3600000 ))
		minutes=$(( $it / 60000 )) ; [ $minutes -eq 0 ] && minutes="0" 
		it=$(( $it - $minutes * 60000 ))
		seconds=$(( $it / 1000 )) ; [ $seconds -eq 0 ] && seconds="0" 
		thousandths_out=$( printf %3.3d $(( $it - $seconds * 1000 )) );
		it="$hours:$minutes:$seconds.$thousandths_out"
		echo "${it}"
	fi
}

checkforautocrop ()
{
	if [ "$autocrop" -eq 1 ] ; then
		# figure out whether to autocrop the image or not
	        image_width=`imagewidth "$1"`
	        image_height=`imageheight "$1"`
	        ratio="$(( 100* $image_width / $image_height ))"
	        out_ratio="$(( 100* $dvd_width / $dvd_height ))"
		do_autocrop_w=0 ; do_autocrop_h=0
		out_ratio_plus=$(( $out_ratio + 30 ))
		out_ratio_minus=$(( $out_ratio - 30 ))
		if [ "$ratio" -gt $out_ratio_minus ] && [ $ratio -lt $out_ratio_plus ]; then
			## if ratio is +/- 30 from output ratio 
			if [ "$ratio" -lt "$(( $out_ratio ))" ] ; then
				do_autocrop_h=1 # image too wide, crop height
			elif [ "$ratio" -gt "$(( $out_ratio ))" ] ; then
				do_autocrop_w=1 # image too tall, crop width
			fi
		fi
		[ $debug -ge 3 ] && myecho "[slidezilla:checkforautocrop] image_width=$image_width image_height=$image_height ratio=$ratio out_ratio=$out_ratio"
		[ $debug -ge 3 ] && myecho "[slidezilla:checkforautocrop] do_autocrop_w=$do_autocrop_w  do_autocrop_h=$do_autocrop_h"
	else
		do_autocrop_h=0 ; do_autocrop_w=0
	fi
}


checkRequiredProgram()
{
p=`echo $1 | awk -F'-' '{ print $1 }'`
pn=`echo $1 | awk -F'-' '{ print $2 }'`


it="`which $p`"
if [ -z "$it" ] ; then # no convert
               echo "[slidezilla] ERROR:  Required program $pn is missing."
               echo "[slidezilla]         You need to download and install $pn."
	 		   needed_program_missing=1
	 		   exit 1
fi

}


#-------------------------- Main Starts here ------------------------# 

if [ $# -lt 1 ]; then
	echo "ERROR: Too few arguments"
	help
	exit 1
fi

#---Initialize the default and system params-----#

. $BINDIR/slidezilla_init.sh

# slidezilla [-d for debug] [-o for overwrite] [-v verbose 0-2] [-nc for nocleanup]
# 	[-t for multithread if possible] [-q no console messages] [-cf control file] path_to_control_file.xml

theargs="$@"
nocleanup=0
for arg in $theargs
do
	case "$arg" in
	## config variables:
	-d) shift; set -vx ; nocleanup=1  ; commandline_debug="1"  ;;
	-o) shift; commandline_overwrite="1" ;;
	-v) shift; commandline_verbose="$1" ; shift ;;
	-nc) shift; nocleanup=1 ;;
	-cf) shift; input_cfile="$1"; shift
                if [ ! -f "$input_cfile" ] ; then
                echo "ERROR: Input file $input_cfile does not exist."
                exit 1
                fi ;;
	-t) shift; multithreaded_processing=1 ;;  # use multi-threaded mode 
	-h) help ; exit 0 ; shift ;;
	-\?) help ; exit 0 ; shift ;;
	-help) help ; exit 0 ; shift ;;
	-q) quiet=1 ; shift ;;
	--help) help ; exit 0 ; shift ;;
	-v) echo "$version" ; exit 0 ; shift ;;
	-version) echo "$version" ; exit 0 ; shift ;;
	esac
done

if [ "$input_cfile" == "" ]; then
                echo "[slidezilla] ERROR: Input control file is missing. Exiting.."
                help
                exit 1
fi


#-------------------------- Validations of the needed programs ------------------------# 

for aProg in $required_programs
do
checkRequiredProgram $aProg
done

#-------------------------- Set VideoHome ------------------------# 
cf_videohome=`grep global:outdir $input_cfile | awk -F'=' '{print $2}' | awk -F'#' '{ print $1 }' | tr -d \[:blank:\]`
if [ "$cf_videohome" == "" ]; then
	cmdRunDir=`pwd`
	cd `dirname $input_cfile`
	export VIDEOHOME=`pwd`
	cd $cmdRunDir
else
 if [ -f $cf_videohome ]; then
	 export VIDEOHOME=$cf_videohome
 else
	 echo "ERROR: Output directory specified in the $input_cfile does not exist. Change and try again.."
	 exit 1
 fi	
fi

#-------------------------- Create required directories ------------------------# 

#TODO - What do you want to do with other files..What to do for the log file..
#LOGDIR
CONFDIR=${VIDEOHOME}/conf
VIDEODIR=${VIDEOHOME}/tmpvideo

#SLIDEDIR=${VIDEOHOME}/tmpslides
#TITLEDIR=${VIDEOHOME}/tmptitle
#EFFECTDIR=${VIDEOHOME}/tmpeffect
#OUTPUTDIR
#INPUTDIR

if [ "$commandline_overwrite" -eq 0 ]; then
 if [ -f $CONFDIR ] || [ -f $VIDEODIR ] ; then
 	 echo "ERROR: Output directory contains data from previous run and overwrite is disabled..Check and try again"
	 exit 1
 fi
fi

#DONT DELETE VIDEOHOME - PLEASE
rm -rf $CONFDIR
rm -fr $VIDEODIR

mkdir -p $CONFDIR
mkdir -p $VIDEODIR

#Intentionally checking only for the last command's return code - its not a bug..
rc=$?

if [ $rc -gt 0 ]; then
 	 echo "ERROR: Output directory does not seem to be writable. Could not create required directories..Check and try again"
	 exit 1
fi

#-------------------------- Create Property files ------------------------# 

# 1 - Create global file 

echo "#!/bin/bash" > ${CONFDIR}/global_prop.sh
echo "" > ${CONFDIR}/global_prop.sh
echo "" > ${CONFDIR}/global_prop.sh
`grep ^global: $input_cfile |  grep -v =$ | awk -F':' '{print $2}' >> ${CONFDIR}/global_prop.sh`

# 2 - Create slides property files..
for slide in `grep ^slide $input_cfile | awk -F':' '{ print $1 }' | uniq -d`
do
	`grep ^${slide}: ${input_cfile} | awk -F':' '{ print $2 }' | awk -F'\t' '{ print $1 }' | grep -v =$ | grep -v ' =' | grep -v '= ' > ${CONFDIR}/${slide}_prop.sh` 
done


#-------------------------- Set remaining of the properties ------------------------# 
#TODO - like which ones ??


#-------------------------- START Video CREATION ----------------------# 

#--- Step 1 : Load Libraries and global properties ---#

. $CONFDIR/global_prop.sh
. $BINDIR/slidezilla_util.sh
. $BINDIR/slidezilla_effect.sh
. $BINDIR/slidezilla_transition.sh
. $BINDIR/slidezilla_title.sh

#--- Step 2 : Create and Set home for each slide, extract frames for videos and copy images into INPUT_FRAME folder ---#

i=0
#for slide_prop in `grep ^slide $input_cfile | awk -F':' '{ print $1 }' | sort | uniq -d`
for slide_prop in `ls $CONFDIR/slide* | sort -n -t'_' -k2`
do
	#------ Set the default params for the slide and then set the params provided by user to overwrite the default for given values-------#
	defaultSlideParams
	. ${slide_prop}

	#------ Set the video output file name for this slide----#
	#i=`echo ${slide_prop} | awk -F'_' '{ print $2 }'`
	SLIDEHOME=$VIDEOHOME/SLIDES/${slide_num}
	INPUT_FRAMES=$SLIDEHOME/input_frames
	EFFECT=$SLIDEHOME/effect
	TITLE=$SLIDEHOME/title
	TRANSITION=$SLIDEHOME/transition

	echo "" >> ${slide_prop}
	echo "SLIDEHOME=$SLIDEHOME" >> ${slide_prop}
	echo "INPUT_FRAMES=$INPUT_FRAMES" >> ${slide_prop}
	echo "EFFECT=$EFFECT" >> ${slide_prop}
	echo "TITLE=$TITLE" >> ${slide_prop}
	echo "TRANSITION=$TRANSITION" >> ${slide_prop}	
	
	
	#call to slidezilla_titles to read the title properties for this slide from slidezilla_titles.properties and add to the slide_prop
	addTitleProperties
	addEffectProperties
	addTransitionProperties

	mkdir -p $SLIDEHOME
	mkdir -p $INPUT_FRAMES
	mkdir -p $EFFECT
	mkdir -p $TITLE
	mkdir -p $TRANSITION

	if [ ! -f "$media_path" ] ; then
		 echo "[slidezilla] ERROR: Media File [$media_path] does not exist for slide# ${i}"
		 exit 1
	fi
	
	# I = Image
	if [ "$media_type" == "I" ]; then   
		img_name=`printf "${video_extract_img_prefix}-%03d" 1`
		img_filename=${img_name}.${video_extract_img_format}
		
		#convert $media_path -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $INPUT_FRAMES/${img_filename}
		convert $media_path -resize ${video_extract_img_size} $INPUT_FRAMES/${img_filename}
		#TODO Save perforamnce by eliminating unnecessary steps of creating files in INPUT_FRAMES and copy directly to effect
		
		##---------- For a single image it will be necesary to copy the image in effect only and then after the effect is 
		##---------- created, we copy the required number of images into title... even if its simple effect, we should just create 
		##---------- necessary number of copies of the image and then create title..
		
		cp $INPUT_FRAMES/${img_filename} $EFFECT/${img_filename}
		
	else
	
		`ffmpeg -i $media_path -vf "deshake" ${media_path}-tmp.mov`
		`rm -rf $media_path`
		`mv ${media_path}-tmp.mov $media_path`

		video_duration_in_secs=`getVideoDuration $media_path`
		
		extractImgsFromVideo

		if [ "$duration" == "" ] || [ "$duration" == "0" ] || [ "$duration" -ge $video_duration_in_secs ]; then
			copy_file_count=`ls $INPUT_FRAMES/${video_extract_img_prefix}* | wc -l | awk '{print $1}'`
		else
			copy_file_count=$(( ( $duration * $fps ) + 2 ))
		fi
		
		files_to_copy_toeffect=`ls $INPUT_FRAMES/${video_extract_img_prefix}* | sort | head -$copy_file_count`
		copyFilesToDirectory $EFFECT $files_to_copy_toeffect
		if [ "$title_text_1" != "" ] || [ "$title_text_2" != "" ]; then			
		 if [ "$title_duration" == "" ] || [ "$title_duration" == 0 ] || [ "$title_duration" -ge "$duration" ]; then
			 mv $EFFECT/${video_extract_img_prefix}* $TITLE/
		 else
			 move_file_count=$(( ( $title_duration * $fps ) + 2 ))
			 files_to_move_totitle=`ls $EFFECT/${video_extract_img_prefix}* | head -$move_file_count`
			 moveFilesToDirectory $TITLE $files_to_move_totitle
		 fi
		fi
	fi
	

done

#--- Step 3 : For each slide prop, create the effects if its image, then title and then transition  ---#

for slide_prop in `ls $CONFDIR/slide* | sort -n -t'_' -k2`
do
	#------ Set the default params for the slide and then set the params provided by user to overwrite the default for given values-------#
	defaultSlideParams
	. ${slide_prop}

	#------ Create slide now Slide = title frames + effect frame -------#
	#I = Image
	if [ "$media_type" == "I" ]; then
		createSlideEffect
	 if [ "$title_text_1" != "" ] || [ "$title_text_2" != "" ]; then	
		if [ "$title_duration" == 0 ] || [ "$title_duration" -ge "$duration" ]; then
			mv $EFFECT/${video_extract_img_prefix}* $TITLE/
		else
			move_file_count=$(( ( $title_duration * $fps ) + 2 ))
			files_to_move_totitle=`ls $EFFECT/${video_extract_img_prefix}* | head -$move_file_count`
			moveFilesToDirectory $TITLE $files_to_move_totitle
		fi
	 fi
	fi
	
	#Preparing for transition before creating title so that the strating frame does not have title on it .. 
	prepareForTransition
	createTitle
done

#End frame for transition for the last slide
convert -size ${video_extract_img_size} canvas:${last_transition_slide_color} ${prevSlideTransition}/to.${video_extract_img_format}

for slide_prop in `ls $CONFDIR/slide* | sort -n -t'_' -k2`
do
	#------ Set the default params for the slide and then set the params provided by user to overwrite the default for given values-------#
	defaultSlideParams
	. ${slide_prop}

	createTransition
done

#--- Step 4 : Find the total number of szimg* images in the VIDEOHOME  ---#
frameCount=`find $VIDEOHOME/* -name "${video_extract_img_prefix}*" -print | wc -l`

frameCountFormat="3"
if [ $frameCount -gt 1000 ]; then
frameCountFormat="4"
fi
if [ $frameCount -gt 10000 ]; then
frameCountFormat="5"
fi
if [ $frameCount -gt 100000 ]; then
frameCountFormat="6"
fi

#--- Step 5 : Copy all images into the temp_video folder   ---#

szimg_index=0
for slidenum in `ls $VIDEOHOME/SLIDES/ | sort -n` 
do 
	for slide_stage in title effect transition
	do
		for szimg_orig in `ls $VIDEOHOME/SLIDES/${slidenum}/${slide_stage}/szimg* | sort`
		do
			new_img_name=`printf "szimg-%0${frameCountFormat}d" $szimg_index`
			#TODO - The below convert statement should be kicked off as a separate thread & at the end of each directory processing
			# For e.g, when title files are created for slide 1, before moving on to slide 2, kick it off there. Add a method to util
			# that will call a standalone (new) script with & in that script, use a for loop to get all teh files in the directory
			# and then for each file , run this command..
			`convert ${szimg_orig} -background black -flatten +matte ${szimg_orig}`
			cp ${szimg_orig} $VIDEODIR/${new_img_name}.${video_extract_img_format}			
			szimg_index=$(( $szimg_index + 1 ))
		done
	done
done

#--- Step 5 : Mix music   ---#

musicFilePath=`mixMusic`
#cut the music file into appropriate size and also create teh fade effect and the mix with the video...
# mixMusic


#---- Step 5.5 - Perfect the frame count according to fps -------#

#--- Step 6 : Create Video using ffmpeg from all frames   ---#

case "$frameCountFormat" in 
3)
`ffmpeg -i $musicFilePath -f image2 -i $VIDEODIR/szimg-%03d.$video_extract_img_format -vcodec ${szvcodec} -acodec ${szacodec} -r ${fps} -s ${outputsize} -maxrate 500k -bufsize 1000k -threads 1 -pix_fmt yuv420p -q:v ${quality} $VIDEODIR/${outputfilename}`
;;
4)
`ffmpeg -i $musicFilePath -f image2 -i $VIDEODIR/szimg-%04d.$video_extract_img_format -vcodec ${szvcodec} -acodec ${szacodec} -r ${fps} -s ${outputsize} -maxrate 500k -bufsize 1000k -threads 1 -pix_fmt yuv420p -q:v ${quality} $VIDEODIR/${outputfilename}`
;;
5)
`ffmpeg -i $musicFilePath -f image2 -i $VIDEODIR/szimg-%05d.$video_extract_img_format -vcodec ${szvcodec} -acodec ${szacodec} -r ${fps} -s ${outputsize} -maxrate 500k -bufsize 1000k -threads 1 -pix_fmt yuv420p -q:v ${quality} $VIDEODIR/${outputfilename}`
;;
6)
`ffmpeg -i $musicFilePath -f image2 -i $VIDEODIR/szimg-%06d.$video_extract_img_format -vcodec ${szvcodec} -acodec ${szacodec} -r ${fps} -s ${outputsize} -maxrate 500k -bufsize 1000k -threads 1 -pix_fmt yuv420p -q:v ${quality} $VIDEODIR/${outputfilename}`
;;
esac


#----- Step 7 : Configure the movie to start right away on web video player
`qt-faststart $VIDEODIR/${outputfilename} $VIDEODIR/${outputfilename}.tmp`
`rm -f $VIDEODIR/${outputfilename}`
`mv $VIDEODIR/${outputfilename}.tmp $VIDEODIR/${outputfilename} `

exit 0