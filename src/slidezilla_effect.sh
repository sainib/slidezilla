#!/bin/sh
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

addEffectProperties()
{

if [ "$effect_style" != "" ]; then
	property_count_in_file=`grep -ic ^${effect_style}: $BINDIR/${slidezilla_effect_property_filename}`

   if [ "$property_count_in_file" -gt 0 ]; then
	   add_properties_for_effect=$effect_style
   else
	   add_properties_for_effect="SIMPLE"
   fi

else
	add_properties_for_effect="SIMPLE"
fi

echo ""
echo "#-----Effect properties for effect ${add_properties_for_effect} " >> ${slide_prop}
grep -i ^${add_properties_for_effect}: $BINDIR/${slidezilla_effect_property_filename} | awk -F':' '{ print $2 }' >> ${slide_prop}

}

createSlideEffect(){

	echo "[slidezilla] Creating $duration seconds long $effect_style effect for media $media_path"
	
	upr_slide_name=`echo $effect_style | tr "[:lower:]" "[:upper:]"`
	
	case "$upr_slide_name" in
	SIMPLE) effect_simple 
	;;
	ZOOMIN_CENTER) zoomIn_Center 
	;;
	ZOOMIN_NORTH) zoomIn_North 
	;;
	ZOOMIN_SOUTH) zoomIn_South 
	;;
	ZOOMIN_EAST) zoomIn_East
	;;
	ZOOMIN_WEST) zoomIn_West
	;;
	ZOOMIN_NORTHEAST) zoomIn_NorthEast 
	;;
	ZOOMIN_SOUTHWEST) zoomIn_SouthWest 
	;;

	ZOOMOUT_CENTER) zoomOut_Center 
	;;
	ZOOMOUT_NORTH) zoomOut_North 
	;;
	ZOOMOUT_SOUTH) zoomOut_South 
	;;
	ZOOMOUT_EAST) zoomOut_East
	;;
	ZOOMOUT_WEST) zoomOut_West
	;;
	ZOOMOUT_NORTHEAST) zoomOut_NorthEast 
	;;
	ZOOMOUT_SOUTHWEST) zoomOut_SouthWest 
	;;
	KENBURN_TOP2BOT)
		kenburn_T2B
	;;
	KENBURN_BOT2TOP)
		kenburn_B2T
	;;
	KENBURN_RIGHT2LEFT)
		kenburn_R2L
	;;
	KENBURN_LEFT2RIGHT)
		kenburn_L2R
	;;	
	esac
	
	
}



effect_simple()
{

	#echo $slide_title_style
	#echo $slide_title_duration

#TODO identify -verbose 1.JPG | grep Geometry | awk '{ print $2 }' | awk -F'+' '{print $1}'
#Check the image size to decide if we need padding with background color to make the image of default SZ Image size..
#Articles to read - http://www.animemusicvideos.org/guides/avtechbeta/aspectratios.html
# http://www.transcoding.org/transcode?Calculating_Frame_Size_And_Aspect_Ratio
# http://howto-pages.org/ffmpeg/

convert $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $EFFECT/tmpimgfilename.${video_extract_img_format}
mv $EFFECT/tmpimgfilename.${video_extract_img_format} $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format}

number_of_img_copies=$(( ( $duration * $fps ) + 2 ))

i=2
while [ $i -le ${number_of_img_copies} ]
do
	img_name=`printf "szimg-%03d" $i`
	cp $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} $EFFECT/${img_name}.${video_extract_img_format}
	i=$(( $i + 1 ))
done

}


zoomIn()
{

video_height=${video_extract_img_height}
video_width=${video_extract_img_width}
zoom_speed=1

total_frames=$(( ( $duration * $fps ) + 2 ))

width_change=$(( $zoom_speed * 1 ))
height_change=`echo "scale=2; ($video_height * $zoom_speed ) / $video_width" | bc`

f=0
last_img_name_count=0
last_img_name_count=$(( $last_img_name_count + 1 ))

mv ${EFFECT}/${video_extract_img_prefix}-001.${video_extract_img_format} ${EFFECT}/from.${video_extract_img_format}

if [ "$1" != "" ]; then
grvati=$1
else
grvati="Center"
fi

new_height=$video_height
new_width=$video_width
new_actual_height=$video_height
new_actual_width=$video_width

while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/from.${video_extract_img_format} -resize ${new_width}x${new_height}  -gravity ${grvati} -crop ${video_extract_img_size}+0+0 +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

new_actual_height=`echo "scale=2;$new_actual_height + $height_change" | bc`
new_actual_width=`echo "scale=2;$new_actual_width + $width_change" | bc`
new_height=`printf "%.f\n" $new_actual_height`
new_width=`printf "%.f\n" $new_actual_width`

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

}


zoomIn_Center()
{
zoomIn center
}

zoomIn_North()
{
zoomIn north
}

zoomIn_South()
{
zoomIn south
}

zoomIn_East()
{
zoomIn east
}

zoomIn_West()
{
zoomIn west
}

zoomIn_NorthEast()
{
zoomIn northeast
}

zoomIn_SouthWest()
{
zoomIn southwest
}


zoomOut()
{

mv ${EFFECT}/${video_extract_img_prefix}-001.${video_extract_img_format} ${EFFECT}/from.${video_extract_img_format}
total_frames=$(( ( $duration * $fps ) + 2 ))
total_zoom=50

dec_increment=`echo "scale=1;$total_zoom / $total_frames" | bc`
current_zoom=$(( 100 + $total_zoom ))
dec_current_zoom=$current_zoom
f=0
last_img_name_count=0
last_img_name_count=$(( $last_img_name_count + 1 ))

if [ "$1" != "" ]; then
grvati=$1
else
grvati="Center"
fi


while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/from.${video_extract_img_format} -resize ${current_zoom}%  -gravity ${grvati} -crop ${video_extract_img_size}+0+0 +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

dec_current_zoom=`echo "scale=1;$dec_current_zoom - $dec_increment"|bc`
current_zoom=`printf "%.f\n" $dec_current_zoom`

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

}

zoomOut_Center()
{
zoomOut center
}

zoomOut_North()
{
zoomOut north
}

zoomOut_South()
{
zoomOut south
}

zoomOut_East()
{
zoomOut east
}

zoomOut_West()
{
zoomOut west
}

zoomOut_NorthEast()
{
zoomOut northeast
}

zoomOut_SouthWest()
{
zoomOut southwest
}


kenburn_L2R()
{

kb_acc=3
total_frames=$(( ( $duration * $fps ) + 2 ))
move_axis_size=$video_extract_img_width
grvati="NorthWest"
last_img_name_count=0

convert $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $EFFECT/orig_slide_img.${video_extract_img_format}
rm $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format}

total_move_pixels=`echo "scale=0;$total_frames * $kb_acc"|bc`
percent_img_zoom_formove=`echo "scale=2; ( ( $total_move_pixels + $move_axis_size ) / $move_axis_size ) * 100 "|bc`
percent_img_zoom_formove=`printf "%.f\n" $percent_img_zoom_formove`


convert ${EFFECT}/orig_slide_img.${video_extract_img_format} -resize ${percent_img_zoom_formove}%  ${EFFECT}/orig_slide.${video_extract_img_format}
rm ${EFFECT}/orig_slide_img.${video_extract_img_format}

f=0
while [ $f -le $total_move_pixels ]
do

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/orig_slide.${video_extract_img_format}  -crop ${video_extract_img_size}+${f}+0 +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

f=$(( $f + $kb_acc ))

done

}


kenburn_R2L()
{

kb_acc=3
total_frames=$(( ( $duration * $fps ) + 2 ))
move_axis_size=$video_extract_img_width
last_img_name_count=0

convert $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $EFFECT/orig_slide_img.${video_extract_img_format}
rm $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format}

total_move_pixels=`echo "scale=0;$total_frames * $kb_acc"|bc`
percent_img_zoom_formove=`echo "scale=2; ( ( $total_move_pixels + $move_axis_size ) / $move_axis_size ) * 100 "|bc`
percent_img_zoom_formove=`printf "%.f\n" $percent_img_zoom_formove`


convert ${EFFECT}/orig_slide_img.${video_extract_img_format} -resize ${percent_img_zoom_formove}%  ${EFFECT}/orig_slide.${video_extract_img_format}
rm ${EFFECT}/orig_slide_img.${video_extract_img_format}

f=$total_move_pixels
while [ $f -gt 0 ]
do

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/orig_slide.${video_extract_img_format}  -crop ${video_extract_img_size}+${f}+0 +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

f=$(( $f - $kb_acc ))

done

}

kenburn_B2T()
{

kb_acc=3
total_frames=$(( ( $duration * $fps ) + 2 ))
move_axis_size=$video_extract_img_height
last_img_name_count=0

convert $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $EFFECT/orig_slide_img.${video_extract_img_format}
rm $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format}

total_move_pixels=`echo "scale=0;$total_frames * $kb_acc"|bc`
percent_img_zoom_formove=`echo "scale=2; ( ( $total_move_pixels + $move_axis_size ) / $move_axis_size ) * 100 "|bc`
percent_img_zoom_formove=`printf "%.f\n" $percent_img_zoom_formove`


convert ${EFFECT}/orig_slide_img.${video_extract_img_format} -resize ${percent_img_zoom_formove}%  ${EFFECT}/orig_slide.${video_extract_img_format}
rm ${EFFECT}/orig_slide_img.${video_extract_img_format}

f=$total_move_pixels
while [ $f -gt 0 ]
do

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/orig_slide.${video_extract_img_format}  -crop ${video_extract_img_size}+0+${f} +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

f=$(( $f - $kb_acc ))

done

}

kenburn_T2B()
{

kb_acc=3
total_frames=$(( ( $duration * $fps ) + 2 ))
move_axis_size=$video_extract_img_height
grvati="NorthWest"
last_img_name_count=0

convert $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format} -resize ${video_extract_img_size} -size ${video_extract_img_size} xc:${video_extract_img_bgfill_color} +swap -gravity center -composite $EFFECT/orig_slide_img.${video_extract_img_format}
rm $EFFECT/${video_extract_img_prefix}-001.${video_extract_img_format}

total_move_pixels=`echo "scale=0;$total_frames * $kb_acc"|bc`
percent_img_zoom_formove=`echo "scale=2; ( ( $total_move_pixels + $move_axis_size ) / $move_axis_size ) * 100 "|bc`
percent_img_zoom_formove=`printf "%.f\n" $percent_img_zoom_formove`


convert ${EFFECT}/orig_slide_img.${video_extract_img_format} -resize ${percent_img_zoom_formove}%  ${EFFECT}/orig_slide.${video_extract_img_format}
rm ${EFFECT}/orig_slide_img.${video_extract_img_format}

f=0
while [ $f -le $total_move_pixels ]
do

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert ${EFFECT}/orig_slide.${video_extract_img_format}  -crop ${video_extract_img_size}+0+${f} +repage  ${EFFECT}/${img_name}.${video_extract_img_format}

f=$(( $f + $kb_acc ))

done

}
