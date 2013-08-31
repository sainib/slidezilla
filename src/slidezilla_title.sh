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


addTitleProperties()
{

#prop_title_style=`grep title_style ${slide_prop} | awk -F'=' '{ print $2 }'`

if [ "$title_style" != "" ]; then
	property_count_in_file=`grep -ic ^${title_style}: $BINDIR/${slidezilla_title_property_filename}`

   if [ "$property_count_in_file" -gt 0 ]; then
	   add_properties_for_title=$title_style
   else
	   add_properties_for_title="SIMPLE"
   fi

else
	add_properties_for_title="SIMPLE"
fi

echo "" >> ${slide_prop}
echo "#-----Effect properties for title ${add_properties_for_title} " >> ${slide_prop}
grep -i ^${add_properties_for_title}: $BINDIR/${slidezilla_title_property_filename} | awk -F':' '{ print $2 }' >> ${slide_prop}

}

createTitle()
{

#check if we have images in the title directory.. 
title_szimg_count=`ls $TITLE/${video_extract_img_prefix}* | wc -l | awk '{ print $1 }'`

if [ "$title_szimg_count" -gt 0 ]; then
   #if so 
   #1. create the background and write text on it .. What do we need for this ? 
   applyMultComp="N"
   #1a Get teh height and width of the backgroudn
   title_box_height=$(( $video_extract_img_height * $background_height / 100  ))
   title_box_width=$(( $video_extract_img_width * $background_width / 100 ))
   title_box_height=`printf "%.f\n" $title_box_height`
   title_box_width=`printf "%.f\n" $title_box_width`
   lwr_bg_type=`echo $background_type | tr "[:upper:]" "[:lower:]"`

   case "$lwr_bg_type" in
   none)
   	convert -size ${title_box_width}x${title_box_height} canvas:none $TITLE/titlebg.${video_extract_img_format}
	;;
   solid) 
   	convert -size ${title_box_width}x${title_box_height} canvas:${background_color} $TITLE/titlebg.${video_extract_img_format}
	;;
   transperant_25) 
   		convert -size ${title_box_width}x${title_box_height} canvas:${background_color} $TITLE/tmpbg.${video_extract_img_format}
		# fx = 1 - (required_transperancy/100) so for 75% we need fx=0.25
	    convert  $TITLE/tmpbg.${video_extract_img_format} -alpha set -channel A  -fx '0.75'  $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}	    
		;;   
   transperant_50) 
   		convert -size ${title_box_width}x${title_box_height} canvas:${background_color} $TITLE/tmpbg.${video_extract_img_format}
	    convert  $TITLE/tmpbg.${video_extract_img_format} -alpha set -channel A  -fx '0.5'  $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}	    
	    ;;
   transperant_75) 
   		convert -size ${title_box_width}x${title_box_height} canvas:${background_color} $TITLE/tmpbg.${video_extract_img_format}
		# fx = 1 - (required_transperancy/100) so for 75% we need fx=0.25
	    convert  $TITLE/tmpbg.${video_extract_img_format} -alpha set -channel A  -fx '0.25' $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}	    
		;;   
   fadetoleft)
   		applyMultComp="Y"
   		convert -size ${title_box_height}x${title_box_width} gradient:${background_color}-none  $TITLE/tmpbg.${video_extract_img_format}
   		convert $TITLE/tmpbg.${video_extract_img_format} -rotate  90  $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}
   		;;
   fadetoright)
   		applyMultComp="Y"
   		convert -size ${title_box_height}x${title_box_width} gradient:${background_color}-none $TITLE/tmpbg.${video_extract_img_format}
   		convert $TITLE/tmpbg.${video_extract_img_format} -rotate  -90  $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}
   		;;   
   fadetotop) 
   		applyMultComp="Y"   
   		#convert -size ${title_box_width}x${title_box_height} gradient:${background_color}-none  -colorize 100%  $TITLE/tmpbg.${video_extract_img_format}
   		convert -size ${title_box_width}x${title_box_height} gradient:${background_color}-none  $TITLE/tmpbg.${video_extract_img_format}
   		convert $TITLE/tmpbg.${video_extract_img_format}  -rotate  -180  $TITLE/titlebg.${video_extract_img_format}
   		rm $TITLE/tmpbg.${video_extract_img_format}
   		;;
   fadetobottom) 
	applyMultComp="Y"
   	convert -size ${title_box_width}x${title_box_height} gradient:${background_color}-none $TITLE/titlebg.png ;;
   esac
	   
 #------- Next Step : Write the text now -------#
 
 
 
 ############################ NOT APPLYING ANY OF THIS ANYMORE , JUST FOR KEEPSAKE, DLETE AT SOMEPOINT ##########################
 #---Heres a little finding of a R&D I did : Roughly we can use this formula to make sure that the text will fit in well in 
 #---in the title box :-
 #--- 1: total height of the title box >= 2 + 1.2 * title_1 font + 2 + 1.2 * title_2 font + 2
 #--- Explanation :: 2 is the spacer, above text1 , between text1 and text 2 and after text 2
 #--- Little R&D showed that the height of the text (in most cases, but varies with font) = 1.2 times the point size of the font

 #--- SOOOO if the formula fails to test i.e. total height of the title box < 2 + 1.2 * title_1 font + 2 + 1.2 * title_2 font + 2
 #--- We need to do this 
 #--- Create title 1 with : ( title box height - 6 ) * 0.6 and no pointsize in the command so IM will fit best size possible
 #--- Create title 2 with : ( title box height - 6 ) * 0.4 and no pointsize in the command so IM will fit best size possible
 #imgh=$( echo $size \* 1.2 | bc )
############################ NOT APPLYING ANY OF THIS ANYMORE , JUST FOR KEEPSAKE, DLETE AT SOMEPOINT ##########################

############################ June 14, 2012 - Chage in approach ###################################
#--- While v0 integration testing, the program failed due to title height issue and required us to 
#--- adjust the parameters with the changed final output WxH which is not desirable. So to resolve 
#--- this we are just going to calulate the max size 1 and 2 that will fit in given height. The
#--- logic is this - which always assumes that font 1 (bigger) will be 1.5 times of font 2 (smaller)
#--- Step 1 : get the title box height based on the frame height and % 
#--- Step 2 : Add the scale values for font 1 and 2 
#--- Step 3 : Use the following formulae to calculate the font sizes
#--- font_size_1=`echo "scale=0; ( ($title_box_height - 6) / $total_scale ) * $font_size_1_scale "|bc`
#--- font_size_2=`echo "scale=0; ( ($title_box_height - 6) / $total_scale ) * $font_size_2_scale "|bc`
############################ June 14, 2012 - Chage in approach ###################################

#Lets calculate the maximum size that will fit in the given title height


total_scale=`echo "scale=1; ( $font_size_1_scale + $font_size_2_scale )"|bc`
font_size_1_tmp=`echo "scale=0; ( ( $title_box_height - 6 ) / ( $total_scale * 1.5 ) ) * $font_size_1_scale "|bc`
font_size_2_tmp=`echo "scale=0; ( ( $title_box_height - 6 ) / ( $total_scale * 1.5 ) ) * $font_size_2_scale "|bc`
font_size_1=`printf "%.f\n" $font_size_1_tmp`
font_size_2=`printf "%.f\n" $font_size_2_tmp`

 if [ "${title_text_1}" == "" ]; then
	 convert -background none  -fill ${font_color_1} \
		  -font ${font_type} -pointsize ${font_size_1}   label:"${title_text_2}"   $TITLE/t1.png 
 else
	 convert -background none  -fill ${font_color_1} \
		  -font ${font_type} -pointsize ${font_size_1}   label:"${title_text_1}"   $TITLE/t1.png 
 fi

 if [ "${title_text_2}" != "" ]; then
	 convert -background none  -fill ${font_color_2} \
		  -font ${font_type} -pointsize ${font_size_2}   label:"${title_text_2}"   $TITLE/t2.png		  
 fi

# So at this point we should have following - $TITLE/titlebg.png , $TITLE/t1.png and may be $TITLE/t2.png

#------- Find out where to place the images ------------

#video_extract_img_height
#video_extract_img_width
TITLEBOX_TOPLEFT_Y=`echo $video_extract_img_height \* $position_top / 100 |bc`
TITLEBOX_TOPLEFT_X=`echo $video_extract_img_width \* $position_left / 100 |bc`
TITLEBOX_TOPLEFT_Y=`printf "%.f\n" $TITLEBOX_TOPLEFT_Y`
TITLEBOX_TOPLEFT_X=`printf "%.f\n" $TITLEBOX_TOPLEFT_X`
#title_box_height=
title1_height=`getImageHeight $TITLE/t1.png`
title2_height=`getImageHeight $TITLE/t2.png`

titlebox_space=`echo $title_box_height - $title1_height - $title2_height | bc`
titlebox_space=`printf "%.f\n" $titlebox_space`

if [ $titlebox_space -gt $decent_titlebox_space ]; then
title1_top_padding=`echo $titlebox_space / 2 - 5|bc`
title1_top_padding=`printf "%.f\n" $title1_top_padding`
TITLE1_BOTTOMLEFT_Y=`echo $title1_height + $title1_top_padding|bc`
TITLE1_BOTTOMLEFT_X=`echo $title1_top_padding|bc`

	if [ "$title2_height" -gt 0 ]; then
		TITLE2_BOTTOMLEFT_Y=`echo $TITLE1_BOTTOMLEFT_Y + 10 + $title2_height|bc`
		TITLE2_BOTTOMLEFT_X=$TITLE1_BOTTOMLEFT_X
	fi
else
titles_gap=`echo $titlebox_space/3|bc`

TITLE1_BOTTOMLEFT_Y=`echo $title1_height + $titles_gap|bc`
TITLE1_BOTTOMLEFT_X=$titles_gap

	if [ "$title2_height" -gt 0 ]; then
		TITLE2_BOTTOMLEFT_Y=`echo $TITLE1_BOTTOMLEFT_Y + $titles_gap + $title2_height|bc`
		TITLE2_BOTTOMLEFT_X=$TITLE1_BOTTOMLEFT_X
	fi
fi


#TODO - We have to keep a half second gap for the title to fade in and fade out 
# Have a property to indicate whether we need fade in effect and also how long for fade in and out

#------ Write the text on top of titlebg now using the calculated gaps etc.. ------------#

convert $TITLE/titlebg.png -font ${font_type} -pointsize ${font_size_1} -fill ${font_color_1} \
	-draw "text $TITLE1_BOTTOMLEFT_X,$TITLE1_BOTTOMLEFT_Y ${title_text_1}" $TITLE/titlebg1.png

convert $TITLE/titlebg1.png -font ${font_type} -pointsize ${font_size_2} -fill ${font_color_2} \
	-draw "text $TITLE2_BOTTOMLEFT_X,$TITLE2_BOTTOMLEFT_Y ${title_text_2}" $TITLE/titlebg2.png	

#----------------- Some cleanup work -----------------------#
rm -rf 	$TITLE/titlebg.png
rm -rf 	$TITLE/titlebg1.png
rm -rf 	$TITLE/t1.png
rm -rf 	$TITLE/t2.png
mv $TITLE/titlebg2.png $TITLE/titlebg.png

   #For all images in title directory
   for frameImg in `ls $TITLE/${video_extract_img_prefix}*`
	do
	   #Mix the title box
		if [ $applyMultComp == "Y" ] && ( [ $background_color == "black" ] || [ $background_color == "#000000" ] ); then
		   convert $frameImg $TITLE/titlebg.png -geometry +${TITLEBOX_TOPLEFT_X}+${TITLEBOX_TOPLEFT_Y} -compose Multiply -composite $frameImg
		else
			composite -geometry +${TITLEBOX_TOPLEFT_X}+${TITLEBOX_TOPLEFT_Y}  $TITLE/titlebg.png $frameImg $frameImg
		fi
    done
   
fi
}