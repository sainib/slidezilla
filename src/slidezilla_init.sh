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

#-------------------------- Program Params  ------------------------# 

cpu_start_time=`date +%s`
required_programs="ffmpeg-FFMPEG convert-ImageMagick lame-Lame sox-SOX"
video_extract_img_size=2592x1944
video_extract_img_width=2592
video_extract_img_height=1944
video_extract_img_format=png
video_extract_img_prefix=szimg
video_extract_img_bgfill_color=black

decent_titlebox_space=15
last_transition_slide_color="black"
#Titles Property file name 
slidezilla_title_property_filename=slidezilla_titles.properties
slidezilla_effect_property_filename=slidezilla_effects.properties
slidezilla_transition_property_filename=slidezilla_transitions.properties

#-------------------------- Default Program Input Params ------------------------# 

##DEFAULT FOR SCRIPT INPUT PARAMETERS
commandline_debug=0
commandline_verbose=0 #0-2
commandline_nocleanup=0
commandline_overwrite=0
quiet=0

# set multithreading option if more than 1 processor core:
fd=`date +%m%d%y`
core_file=$BINDIR/.cores_${fd}
if [ ! -f $core_file ]; then
if [ `uname` == 'Darwin' ]; then
	cores="$( system_profiler | grep Cores | cut -d: -f 2 | tr -d \[:blank:\] )"
else
	cores="$( grep -i 'cpu cores' /proc/cpuinfo | head -n 1 | cut -d: -f 2 | tr -d \[:blank:\] )"
fi
else
    cores=`cat $core_file`
fi

rm -rf $BINDIR/.cores_*
echo $cores > $core_file


if [ -n "$cores" ] && [ "$cores" -ge 2 ] ; then
	multithreaded_processing=1
else
	multithreaded_processing=0
	cores=1
fi

#-------------------------- Default Global Level Params ------------------------# 
outputfilename='Slideshow_`date +"%m-%d-%y_%H_%M_%s"`'
#outdir=??
outputformat='mpeg2'
outputsize=1200x800
audio_start_at=0  #duration may be a number in seconds, or in hh:mm:ss[.xxx] form.
logo_size=80x53
logo_position=Top-Right
quality=3
fps=15
gop=300
autocrop=Y
kenburns_acceleration=2 # in seconds

#-------------------------- Future Params ------------------------# 
##DEFAULT FOR THE FUTURE ADJUSTABLE GLOBAL VALUES #TODO
pal=0  #Support NTSC in the beginning, when expanding into europe, we will look into the PAL
ac3=1  #will always be ac3 in the beginning .. we will look into mp2 if needed
widescreen=0
mpeg_encoder='ffmpeg' # or mpeg2enc. I find ffmpeg 2x faster than mpeg2enc
sharpen=''



#-------------------------- Setup Fonts ------------------------# 

font_dir="/usr/share/fonts/"
font_dir2="/usr/X11R6/lib/X11/fonts/"
font_dir3="/usr/local/share/fonts/"
default_fontname1='n019004l.pfb' # helvetica bold URW fonts
default_fontname2='helb____.ttf' # helvetica bold truetype


defaultSlideParams()
{

#-------------------------- Slide Level Params ------------------------# 
duration=5 #duration may be a number in seconds, or in hh:mm:ss[.xxx] form.
effect_style=SIMPLE
title_style=SIMPLE
title_duration=2
transition_style=NONE
transition_duration=2
title_text_1=""
title_text_2=""
}