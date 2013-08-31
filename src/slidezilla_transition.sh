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

addTransitionProperties()
{

if [ "$transition_style" != "" ]; then
	property_count_in_file=`grep -ic ^${transition_style}: $BINDIR/${slidezilla_transition_property_filename}`

   if [ "$property_count_in_file" -gt 0 ]; then
	   add_properties_for_transition=$transition_style
   else
	   add_properties_for_transition="SIMPLE"
   fi

else
	add_properties_for_transition="SIMPLE"
fi

echo "" >> ${slide_prop}
echo "#-----Effect properties for transition ${add_properties_for_transition} " >> ${slide_prop}
grep -i ^${add_properties_for_transition}: $BINDIR/${slidezilla_transition_property_filename} | awk -F':' '{ print $2 }' >> ${slide_prop}

}

#----------------------- PREPARE 4 TRANSITION -------------------------

prepareForTransition()
{

allFrames=`find ${SLIDEHOME}/* -name ${video_extract_img_prefix}* | grep -v input_frames`
for frameImgName in $allFrames
do
echo "`basename $frameImgName`:$frameImgName" >> ${SLIDEHOME}/tmpFrameFile.txt
done

sort -t':' -k1 ${SLIDEHOME}/tmpFrameFile.txt >> ${SLIDEHOME}/tmpFrameFile_sorted.txt

previousSlideToSrcFile=`head -1 ${SLIDEHOME}/tmpFrameFile_sorted.txt | awk -F':' '{ print $2 }'`
thisSlideFromSrcFile=`tail -1 ${SLIDEHOME}/tmpFrameFile_sorted.txt | awk -F':' '{ print $2 }'`

cp $thisSlideFromSrcFile ${SLIDEHOME}/transition/from.${video_extract_img_format}

if [ "$prevSlideTransition" != "" ]; then
	cp $previousSlideToSrcFile ${prevSlideTransition}/to.${video_extract_img_format}
fi

prevSlideTransition="${SLIDEHOME}/transition"

#cleanup..
rm ${SLIDEHOME}/tmpFrameFile.txt
rm ${SLIDEHOME}/tmpFrameFile_sorted.txt

}

#----------------------- CREATE TRANSITION -------------------------

createTransition()
{

#Find out the number of files we will be creating by using fps * transition time + 2 
tran_file_count=$(( $fps * $transition_duration + 2 ))
#Find out the starting number to be used for naming the images by reading the number of files in SLIDES/n directory - input_frames
last_img_name_count=`find ${SLIDEHOME}/* -name szimg* | grep -v input_frames | wc -l | awk '{ print $1 }'`
#Use case to determine the transition effect we need to apply..


#IF TRANSITION IS NOT SPECIFIED THEN WE WILL JUST HAVE NO TRANISITION
if [ $transition_style == "" ]; then
transition_style="NONE"
fi

upr_tran_style=`echo $transition_style | tr "[:lower:]" "[:upper:]"`
   case "$upr_tran_style" in
   
   SIMPLE)
   	   trnx_simple
   ;;
   DISSOLVE)
	   trnx_dissolve
   ;;
   BLEND)
   		trnx_blend
   ;;
   DISTORT_N_DISSOLVE)
	   	trnx_distort_dissolve
   ;;
   MOVELEFT)
	   	moveLeft
	;;
   MOVERIGHT)
	   	moveRight
	;;
   MOVEUP)
	   	moveUp
	;;
   MOVEDOWN)
	   	moveDown
	;;
	MOVELEFTACC)
		moveLeftAcc
	;;
	FADEBLACK)
	fadeBlack
	;;
	FADEWHITE)
		fadeWhite
	;;	
	SWAP)
		swapFrames
	;;
   esac


}

#----------------------- SIMPLE TRANSITION -------------------------

trnx_simple()
{

i=1
mid_point=`echo $tran_file_count / 2 | bc`
mid_point=`printf "%.f\n" $mid_point`
last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $i -le $tran_file_count ]
do
img_name=`printf "szimg-%03d" $last_img_name_count`

if [[ $i -gt $mid_point ]]; then
	cp $TRANSITION/to.${video_extract_img_format} $TRANSITION/${img_name}.${video_extract_img_format} 
else
	cp $TRANSITION/from.${video_extract_img_format} $TRANSITION/${img_name}.${video_extract_img_format} 
fi

i=$(( $i + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))
done

}

#----------------------- DISSOLVE TRANSITION -------------------------

trnx_dissolve()
{

i=0
f=1
arg_increment=`echo 100 / $tran_file_count | bc`
arg_increment=`printf "%.f\n" $arg_increment`

last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $tran_file_count ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

i=$(( $i + $arg_increment ))
j=$(( 100 - $i ))
ca="$i,${j}"

  convert $TRANSITION/from.${video_extract_img_format} $TRANSITION/to.${video_extract_img_format} -alpha on \
          -compose dissolve -define compose:args=$ca \
          -gravity South  -composite     $TRANSITION/${img_name}.${video_extract_img_format} 

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
  convert $TRANSITION/from.${video_extract_img_format} $TRANSITION/to.${video_extract_img_format} -alpha on \
          -compose dissolve -define compose:args="100,0" \
          -gravity South  -composite     $TRANSITION/${img_name}.${video_extract_img_format} 

}

#----------------------- BLEND TRANSITION -------------------------

trnx_blend()
{
i=0
f=1
arg_increment=`echo 100 / $tran_file_count | bc`
arg_increment=`printf "%.f\n" $arg_increment`

last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $tran_file_count ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

i=$(( $i + $arg_increment ))
j=$(( 100 - $i ))
ca="$i,${j}"

  convert $TRANSITION/from.${video_extract_img_format} $TRANSITION/to.${video_extract_img_format} -alpha on \
          -compose blend -define compose:args=$ca \
          -gravity South  -composite     $TRANSITION/${img_name}.${video_extract_img_format} 

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}


}



#----------------------- DISTORT DISSOLVE -------------------------

trnx_distort_dissolve()
{
i=100
f=1
arg_increment=`echo 100 / $tran_file_count | bc`
arg_increment=`printf "%.f\n" $arg_increment`

#Incerasing the i by arg_increment so the first image is 100%
i=$(( $i + $arg_increment ))

last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $tran_file_count ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

i=$(( $i - $arg_increment ))

  `convert -size ${video_extract_img_size} xc: +noise random -colorspace gray -threshold ${i}% ${TRANSITION}/tmp_random.png`
  `convert $TRANSITION/from.${video_extract_img_format} $TRANSITION/to.${video_extract_img_format} ${TRANSITION}/tmp_random.png -compose over -composite $TRANSITION/${img_name}.${video_extract_img_format}`
  `rm -rf ${TRANSITION}/tmp_random.png`

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}


}

#----------------------- MOVE LEFT -------------------------

moveLeft()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count
increment=`echo $video_extract_img_width / $total_frames | bc`
current_width=0
f=0
last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`
current_width=$(( $current_width + $increment ))
pos_x=$(( $video_extract_img_width - $current_width ))
pos_y=0

#convert 1.png -crop 0x0+${current_width}+${video_extract_img_height}  +repage  ${img_name}.png
convert $TRANSITION/to.${video_extract_img_format} -crop ${current_width}x${video_extract_img_height}+0+0 +repage  $TRANSITION/${img_name}_tmp.${video_extract_img_format}

composite -geometry +${pos_x}+${pos_y}  $TRANSITION/${img_name}_tmp.${video_extract_img_format} $TRANSITION/from.${video_extract_img_format} \
            $TRANSITION/${img_name}.${video_extract_img_format}
            
rm -rf $TRANSITION/${img_name}_tmp.${video_extract_img_format}

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}

}

#--------------------- Move Left with Acceleration

moveLeftAcc()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count

#sqrt of size / total frames = increment 
increment=`echo "scale=2;sqrt($video_extract_img_width) / $total_frames"|bc`

#start with 0 .. add increment, remove decimal , square and that gives width 
#do while calc-width -lt total width

current_width_ind=0
f=0
last_img_name_count=$(( $last_img_name_count + 1 ))
current_width=0
while [ "$current_width" -lt $video_extract_img_width ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`
current_width_ind=`echo "$current_width_ind + $increment" | bc`
cwit=`printf "%.f\n" $current_width_ind`
current_width=$(( $cwit * $cwit ))

pos_x=$(( $video_extract_img_width - $current_width ))
pos_y=0

#convert 1.png -crop 0x0+${current_width}+${video_extract_img_height}  +repage  ${img_name}.png
convert $TRANSITION/to.${video_extract_img_format} -crop ${current_width}x${video_extract_img_height}+0+0 +repage  $TRANSITION/${img_name}_tmp.${video_extract_img_format}

composite -geometry +${pos_x}+${pos_y}  $TRANSITION/${img_name}_tmp.${video_extract_img_format} $TRANSITION/from.${video_extract_img_format} \
            $TRANSITION/${img_name}.${video_extract_img_format}
            
rm -rf $TRANSITION/${img_name}_tmp.${video_extract_img_format}

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}

}

#--------------------- Move Left with Deceleration TO BE COMPLETED...

moveLeftDec_TBD()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count

}

#---------------------- Move Right

moveRight()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count
increment=`echo $video_extract_img_width / $total_frames | bc`
current_width=0
f=0
last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`
current_width=$(( $current_width + $increment ))
top_x=$(( $video_extract_img_width - $current_width ))

pos_x=$current_width
pos_y=0

#convert 1.png -crop 0x0+${current_width}+${video_extract_img_height}  +repage  ${img_name}.png
convert $TRANSITION/to.${video_extract_img_format} -crop ${current_width}x${video_extract_img_height}+${top_x}+0 +repage  $TRANSITION/${img_name}_tmp.${video_extract_img_format}

composite -geometry +${pos_x}+${pos_y}  $TRANSITION/${img_name}_tmp.${video_extract_img_format} $TRANSITION/from.${video_extract_img_format} \
            $TRANSITION/${img_name}.${video_extract_img_format}
            
rm -rf $TRANSITION/${img_name}_tmp.${video_extract_img_format}


f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}



}


moveUp()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count
increment=`echo $video_extract_img_height / $total_frames | bc`
current_height=0
f=0
last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`
current_height=$(( $current_height + $increment ))
top_y=$(( $video_extract_img_height - $current_height ))

pos_x=0
pos_y=$top_y

#convert 1.png -crop 0x0+${current_width}+${video_extract_img_height}  +repage  ${img_name}.png
convert $TRANSITION/to.${video_extract_img_format} -crop ${video_extract_img_width}x${video_extract_img_height}+0+${top_y} +repage  $TRANSITION/${img_name}_tmp.${video_extract_img_format}

composite -geometry +${pos_x}+${pos_y}  $TRANSITION/${img_name}_tmp.${video_extract_img_format} $TRANSITION/from.${video_extract_img_format} \
            $TRANSITION/${img_name}.${video_extract_img_format}
            
rm -rf $TRANSITION/${img_name}_tmp.${video_extract_img_format}


f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}



}

moveDown()
{
#find the pixel size by fps * secnds ... that is the number of pixels to cover in one frame.. 
total_frames=$tran_file_count
increment=`echo $video_extract_img_height / $total_frames | bc`
current_height=0
f=0
last_img_name_count=$(( $last_img_name_count + 1 ))
while [ $f -lt $total_frames ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`
current_height=$(( $current_height + $increment ))
pos_x=0
pos_y=0

#convert 1.png -crop 0x0+${current_width}+${video_extract_img_height}  +repage  ${img_name}.png
convert $TRANSITION/to.${video_extract_img_format} -crop ${video_extract_img_width}x${current_height}+0+0 +repage  $TRANSITION/${img_name}_tmp.${video_extract_img_format}

composite -geometry +${pos_x}+${pos_y}  $TRANSITION/${img_name}_tmp.${video_extract_img_format} $TRANSITION/from.${video_extract_img_format} \
            $TRANSITION/${img_name}.${video_extract_img_format}
            
rm -rf $TRANSITION/${img_name}_tmp.${video_extract_img_format}


f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}
}

#----------------------- Fade to Black ----------------------------

causeFade()
{

i=0
f=1
total_frames=$tran_file_count
half_frame_count=$(( $total_frames / 2 ))
arg_increment=`echo "scale=0;100 / $half_frame_count"| bc`
arg_increment=`printf "%.f\n" $arg_increment`
last_img_name_count=$(( $last_img_name_count + 1 ))

convert -size ${video_extract_img_size} canvas:${1} ${TRANSITION}/bg.${video_extract_img_format}

while [ $f -lt $half_frame_count ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

i=$(( $i + $arg_increment ))
j=$(( 100 - $i ))
ca="$i,${j}"

  convert $TRANSITION/from.${video_extract_img_format} $TRANSITION/bg.${video_extract_img_format} -alpha on \
          -compose dissolve -define compose:args=$ca \
          -gravity South  -composite     $TRANSITION/${img_name}.${video_extract_img_format} 

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp  ${TRANSITION}/bg.${video_extract_img_format}   $TRANSITION/${img_name}.${video_extract_img_format} 
last_img_name_count=$(( $last_img_name_count + 1 ))
f=0
i=0

#---------- Second leg of the transition..
while [ $f -lt $half_frame_count ]
do

img_name=`printf "szimg-%03d" $last_img_name_count`

i=$(( $i + $arg_increment ))
j=$(( 100 - $i ))
ca="$i,${j}"

  convert $TRANSITION/bg.${video_extract_img_format} $TRANSITION/to.${video_extract_img_format} -alpha on \
          -compose dissolve -define compose:args=$ca \
          -gravity South  -composite     $TRANSITION/${img_name}.${video_extract_img_format} 

f=$(( $f + 1 ))
last_img_name_count=$(( $last_img_name_count + 1 ))

done

img_name=`printf "szimg-%03d" $last_img_name_count`
cp $TRANSITION/to.${video_extract_img_format}  $TRANSITION/${img_name}.${video_extract_img_format}

}


fadeWhite()
{

causeFade white

}

fadeBlack()
{

causeFade black

}


swapFrames()
{

border_thickness=40
#border_thickness_y=30
size_reduction_in_tran=80
pre_tran_frame_count=4
total_frames=$(( $tran_file_count / 2 ))

#------------------- Stage - 1 create four frames 

per_frame_border_thickness_increment=$(( $border_thickness / $pre_tran_frame_count ))
f=0
pre_tran_border_thickness=0
while [ $f -le $pre_tran_frame_count ]
do
pre_tran_border_thickness=$(( $pre_tran_border_thickness + $per_frame_border_thickness_increment ))
last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert $TRANSITION/from.png -bordercolor black -border ${pre_tran_border_thickness} \
-resize $video_extract_img_size \
-size $video_extract_img_size xc:black +swap \
-gravity Center -geometry +0+0 -composite \
${TRANSITION}/$img_name.${video_extract_img_format}
f=$(( $f + 1))
done

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert $TRANSITION/from.png -bordercolor black -border $border_thickness \
-resize $video_extract_img_size \
-size $video_extract_img_size xc:black +swap \
-gravity NorthEast -geometry +0+0 -composite \
${TRANSITION}/$img_name.${video_extract_img_format}


#-------------------- End Stage 1 
#create a cavas bg - 222 color ---------------------------------------------
convert -size $video_extract_img_size xc:black $TRANSITION/bg.${video_extract_img_format}

# new sizes for the image that has the reflection..---------------------------------------------
new_size_h=`echo "scale=0;$video_extract_img_height * 2 + 160"|bc`
new_size_w=$(( $video_extract_img_width + $border_thickness * 4 ))

#create images for the clear reflection..---------------------------------------------
convert $TRANSITION/from.png -bordercolor black -border ${border_thickness} -alpha on \
      \( +clone -flip  \) -append \
      -size ${new_size_w}x${new_size_h} xc:black +swap \
      -gravity North -geometry +0+0 -composite ${TRANSITION}/from_ref.png

convert $TRANSITION/to.png -bordercolor black -border ${border_thickness} -alpha on \
      \( +clone -flip  \) -append \
      -size ${new_size_w}x${new_size_h} xc:black +swap \
      -gravity North -geometry +0+0 -composite ${TRANSITION}/to_ref.png

#Create the gradient image that will create the reflection gradient ---------------------------------------------
grad_width=$(( $video_extract_img_width + $border_thickness * 2 ))
grad_height=$(( $video_extract_img_height + $border_thickness * 2 ))
convert -size ${grad_width}x${grad_height} gradient:none-black $TRANSITION/tmpbg.${video_extract_img_format}

#Final Input images with the gradient overlay ..---------------------------------------------
convert ${TRANSITION}/from_ref.${video_extract_img_format} $TRANSITION/tmpbg.${video_extract_img_format} -gravity South -compose Multiply -composite -resize ${video_extract_img_width}x${new_size_h} ${TRANSITION}/f.${video_extract_img_format}
convert ${TRANSITION}/to_ref.${video_extract_img_format} $TRANSITION/tmpbg.${video_extract_img_format} -gravity South -compose Multiply -composite -resize ${video_extract_img_width}x${new_size_h} ${TRANSITION}/t.${video_extract_img_format}

#Create the background to be used for generating frames.. To and From BGs will be diff ---------------------------------------------
#First Leg will have to image in the background..
final_size=$(( 100 - $size_reduction_in_tran ))
convert ${TRANSITION}/bg.${video_extract_img_format} \( ${TRANSITION}/t.${video_extract_img_format} -resize ${final_size}% \) \
	  -gravity NorthWest -geometry +0+0 -composite \
	 -size ${video_extract_img_size} +repage -flatten ${TRANSITION}/fl_bg.${video_extract_img_format}

convert ${TRANSITION}/bg.${video_extract_img_format} \( ${TRANSITION}/f.${video_extract_img_format} -resize ${final_size}% \) \
	  -gravity NorthEast -geometry +0+0 -composite \
	 -size ${video_extract_img_size} +repage -flatten ${TRANSITION}/sl_bg.${video_extract_img_format}

#reduce the size and cmposite with the canvas and reduce to the size 

dec_size_delta=`echo "scale=2;$size_reduction_in_tran / $total_frames"|bc`
dec_img_size=100
img_size=100
f=0
while [ $f -le $total_frames ]
do
last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`
newpos=$f

convert ${TRANSITION}/fl_bg.${video_extract_img_format} \( ${TRANSITION}/f.${video_extract_img_format} -resize ${img_size}% \) \
	  -gravity NorthEast -geometry +${newpos}+${newpos} -composite \
	 -size ${video_extract_img_size} +repage -flatten ${TRANSITION}/${img_name}.${video_extract_img_format}

dec_img_size=` echo "scale=1;$dec_img_size - $dec_size_delta"|bc`
img_size=`printf "%.f\n" $dec_img_size`
f=$(( $f + 1 ))
done


f=0
to_img_size=$(( 100 - $size_reduction_in_tran ))
dec_to_img_size=$to_img_size
while [ $f -le $total_frames ]
do
last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`
newpos_to=$(( $total_frames - $f ))

convert ${TRANSITION}/sl_bg.${video_extract_img_format} \( ${TRANSITION}/t.${video_extract_img_format} -resize ${to_img_size}% \) \
	  -gravity NorthWest -geometry +${newpos_to}+${newpos_to} -composite \
	 -size ${video_extract_img_size} +repage -flatten ${TRANSITION}/${img_name}.${video_extract_img_format}

dec_to_img_size=` echo "scale=1;$dec_to_img_size + $dec_size_delta"|bc`
to_img_size=`printf "%.f\n" $dec_to_img_size`
f=$(( $f + 1 ))

done



#------------------- Stage - 4 create four frames 

last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert $TRANSITION/to.png -bordercolor black -border $border_thickness \
-resize $video_extract_img_size \
-size $video_extract_img_size xc:black +swap \
-gravity NorthWest -geometry +0+0 -composite \
${TRANSITION}/$img_name.${video_extract_img_format}


f=0
pre_tran_border_thickness=$(( $border_thickness + $per_frame_border_thickness_increment ))
while [ $f -le $pre_tran_frame_count ]
do
pre_tran_border_thickness=$(( $pre_tran_border_thickness - $per_frame_border_thickness_increment ))
last_img_name_count=$(( $last_img_name_count + 1 ))
img_name=`printf "szimg-%03d" $last_img_name_count`

convert $TRANSITION/to.png -bordercolor black -border ${pre_tran_border_thickness} \
-resize $video_extract_img_size \
-size $video_extract_img_size xc:black +swap \
-gravity Center -geometry +0+0 -composite \
${TRANSITION}/$img_name.${video_extract_img_format}

f=$(( $f + 1))
done


#-------------------- End Stage 1 


}

#----------------------- TEMPLATE TRANSITION METHOD -------------------------

trnx_template()
{
i=0
while [ $i -le $tran_file_count ]
do
echo "Do something here"
i=$(( $i + 1 ))
done
}


#Cross Zoom
#Ripple
#Page Curl Right
#Page Curl Left
#Flim Strip next
#Spin In 
#Sping Out
#Circle Open
#Circle Close
#Cube
#Mosiac
#divide in windows and rotate windows
#Timewarner Ad type transition where there are three slides in swap like transition.. one facing viewer and two on the either side 
#Active frame minimizes to one of the four corners and the other 