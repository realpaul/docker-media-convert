#!/bin/bash
#set -ex
OIFS="$IFS"
IFS=$'\n'
ORIGIN_PATH=/data/origin
DESTINATION_PATH=/data/destination
# ORIGIN_PATH_ESCAPED=`echo ${ORIGIN_PATH//\//\\\/}`
# DESTINATION_PATH_ESCAPED=`echo ${DESTINATION_PATH//\//\\\/}`
if [ ! -d $ORIGIN_PATH ]; then
	echo "Original path does not exist."
	exit 1
fi
if [ ! -d $PNG_COMPRESSION ]; then
	echo "Destination path does not exist."
	exit 1
fi
rm $ORIGIN_PATH/done

function handle_media() {
	ORIGINAL_DIR=$1
	DESTINATION_DIR=`echo ${ORIGINAL_DIR/"$ORIGIN_PATH"/"$DESTINATION_PATH"}`
	for filename in `find "$ORIGINAL_DIR" -maxdepth 1 -type f \( -name "*.jpg" -or -name "*.JPG" -or -name "*.jpeg" -or -name "*.png" -or -name "*.PNG" -or -name "*.bmp" -or -name "*.BMP" -or -name "*.heic" -or -name "*.HEIC" \)`; do
		filename=$(basename "$filename")
		if [[ $filename == .* ]]; then
			continue
		fi
		extension="${filename##*.}"
		only_filename="${filename%.*}"
		mkdir -p "$DESTINATION_DIR"
		if [ "$extension" == "HEIC" -o "$extension" == "heic" -o "$extension" == "BMP" -o "$extension" == "bmp" ]; then
			extension2="jpg"
		else
			extension2=$extension
		fi
		echo " -- Shrinking image $ORIGINAL_DIR/$filename"
		if_potrait=`convert "$ORIGINAL_DIR/$filename" -format "%[fx:(w/h>1)?0:1]" info:`
		if [ $if_potrait -eq 1 ]; then
			if [ "$extension" == "HEIC" -o "$extension" == "heic" ]; then
				# regular 2160x
				convert -rotate -90 -quality 85 -resize "2160x" "$ORIGINAL_DIR/${only_filename}.${extension}" "$DESTINATION_DIR/${only_filename}.${extension2}"
			else
				# regular 2160x
				convert -quality 85 -resize "2160x>" "$ORIGINAL_DIR/${only_filename}.${extension}" "$DESTINATION_DIR/${only_filename}.${extension2}"
			fi
		else
			# regular x2160
			convert -quality 85 -resize "x2160>" "$ORIGINAL_DIR/${only_filename}.${extension}" "$DESTINATION_DIR/${only_filename}.${extension2}"
		fi
		exiftool -all= -TagsFromFile "$ORIGINAL_DIR/${only_filename}.${extension}" -exif:all "$DESTINATION_DIR/${only_filename}.${extension2}"
		rm "$DESTINATION_DIR/${only_filename}.${extension2}"_original
		# jhead -autorot "$DESTINATION_DIR/${only_filename}.${extension2}"
		jhead -ft "$DESTINATION_DIR/${only_filename}.${extension2}"
		# png compression
		if [ ! -z $PNG_COMPRESSION ]; then
			convert -strip -interlace Plane -gaussian-blur 0.05 -quality 85 -resize x600 "$ORIGINAL_DIR/$filename" "$DESTINATION_DIR/$filename"
		fi
		# watermark
		if test -f "/data/watermark_logo.png"; then
    	convert "$DESTINATION_DIR/$filename" "/data/watermark.png" -gravity northwest -geometry +10+10 -composite "$DESTINATION_DIR/$filename"
		fi
		if [ ! -z $REMOVE_ORIGIN ]; then
			rm "$ORIGINAL_DIR/$filename"
		fi
		if [ -f $ORIGIN_PATH/done ]; then
			echo "Teminated by signal."
			rm -rf $ORIGIN_PATH/done
			exit 0
		fi
	done
	for filename in `find "$ORIGINAL_DIR" -maxdepth 1 -type f \( -name "*.mp4" -or -name "*.MP4" -or -name "*.mov" -or -name "*.MOV" -or -name "*.mpg" -or -name "*.MPG" -or -name "*.rm" -or -name "*.rmvb" -or -name "*.wmv" -or -name "*.flv" -or -name "*.MTS" -or -name "*.mts" -or -name "*.avi" -or -name "*.AVI" -or -name "*.mod" -or -name "*.MOD" -or -name "*.m4v" -or -name "*.M4V" -or -name "*.vob" -or -name "*.VOB" -or -name "*.mkv" -or -name "*.MKV" \)`; do
		filename=$(basename "$filename")
		if [[ $filename == .* ]]; then
			continue
		fi
		extension="${filename##*.}"
		only_filename="${filename%.*}"
		mkdir -p "$DESTINATION_DIR"
		echo " -- Shrinking video $ORIGINAL_DIR/$filename"
		# Regular
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -c:v libx265 -preset fast -crf 26 -c:a aac -b:a 128k -tag:v hvc1 "$DESTINATION_DIR/$only_filename.mp4"
		ffmpeg -y -i "$ORIGINAL_DIR/$filename" -vf scale=h=1080:force_original_aspect_ratio=decrease -c:v libx265 -preset fast -crf 26 -c:a aac -b:a 128k -tag:v hvc1 "$DESTINATION_DIR/$only_filename.mp4"
		# Hardware acceleration
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -c:v hevc_videotoolbox -b:v 6000k -c:a aac -b:a 128k -tag:v hvc1 "$DESTINATION_DIR/$only_filename.mp4"
		# Ultrafast
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -vf scale=h=720:force_original_aspect_ratio=decrease -c:v libx265 -preset ultrafast -crf 28 -c:a aac -b:a 128k -tag:v hvc1 "$DESTINATION_DIR/$only_filename.mp4"
		# H.264
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k "$DESTINATION_DIR/$only_filename.mp4"
		# AV1
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -vf scale=h=1080:force_original_aspect_ratio=decrease -c:v libaom-av1 -crf 26 -b:v 0 -strict experimental -cpu-used 4 "$DESTINATION_DIR/$only_filename.mkv"

		# Add EXIF info
		exiftool -TagsFromFile "$ORIGINAL_DIR/${only_filename}.${extension}" -CreateDate -ModifyDate -MediaCreateDate -MediaModifyDate -TrackCreateDate -TrackModifyDate -FileModifyDate "$DESTINATION_DIR/${only_filename}.mp4"
		# exiftool -TagsFromFile "$ORIGINAL_DIR/${only_filename}.${extension}" -all:all "$DESTINATION_DIR/${only_filename}.mp4"
		rm "$DESTINATION_DIR/${only_filename}.mp4"_original
		if [ ! -z $REMOVE_ORIGIN ]; then
			rm "$ORIGINAL_DIR/$filename"
		fi
		if [ -f $ORIGIN_PATH/done ]; then
			echo "Teminated by signal."
			rm -rf $ORIGIN_PATH/done
			exit 0
		fi
	done
	for filename in `find "$ORIGINAL_DIR" -maxdepth 1 -type f \( -name "*.mp3" -or -name "*.MP3" -or -name "*.wav" -or -name "*.WAV" -or -name "*.m4a" -or -name "*.M4A" -or -name "*.flac" -or -name "*.FLAC" \)`; do
		filename=$(basename "$filename")
		if [[ $filename == .* ]]; then
			continue
		fi
		extension="${filename##*.}"
		only_filename="${filename%.*}"
		mkdir -p "$DESTINATION_DIR"
		echo " -- Shrinking audio $ORIGINAL_DIR/$filename"
		# Regular
		ffmpeg -y -i "$ORIGINAL_DIR/$filename" -codec:a libmp3lame -q:a 4 "$DESTINATION_DIR/$only_filename.mp3"
		# Voice
		# ffmpeg -y -i "$ORIGINAL_DIR/$filename" -codec:a libmp3lame -q:a 7 "$DESTINATION_DIR/$only_filename.mp3"
		if [ ! -z $REMOVE_ORIGIN ]; then
			rm "$ORIGINAL_DIR/$filename"
		fi
		if [ -f $ORIGIN_PATH/done ]; then
			echo "Teminated by signal."
			rm -rf $ORIGIN_PATH/done
			exit 0
		fi
	done
	for subdir in `find $ORIGINAL_DIR -maxdepth 1 -type d`; do
	  if [[ $subdir = $ORIGINAL_DIR ]]; then
		  continue
	  elif [[ $subdir = *"@eaDir"* ]]; then
		  continue
	  fi
    echo "Subdir $subdir"
		handle_media "$subdir"
		# if [ ! -z $REMOVE_ORIGIN ]; then
		# 	rm -r "$subdir"
		# fi
	done
}

handle_media $ORIGIN_PATH