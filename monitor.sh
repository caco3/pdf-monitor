#!/bin/bash

echo "Starting to monitor the upload folder..."

inotifywait -m -r -e create --format '%w%f' ./uploaded | while read -r file; do
    if [ -d "$file" ] ; then
        echo "New folder detected: '$file'"
        # Nothing to do
    else
        FILE_EXTENSION="${file##*.}"
        echo "New file detected: '$file' (File extension: $FILE_EXTENSION)"

        # Check for completed write
        SIZE_BEFORE=`stat -c %s "$file"`
        while [[ true ]]; do
            sleep 1
            SIZE_NOW=`stat -c %s "$file"`            
            if [[ $SIZE_NOW -ne $SIZE_BEFORE ]]; then
                echo "File still growing ($SIZE_BEFORE -> $SIZE_NOW bytes)"
                SIZE_BEFORE=$SIZE_NOW
                echo "Checking again in 10s..."
                sleep 10
                continue
            fi
            
            if [[ $SIZE_NOW -lt 100 ]]; then
                echo "File is empty!"
                break
            fi
            
            echo "file seems to got written completely"
            echo "Waiting another 5s to be sure..."
            sleep 10

            FILE_TYPE=`file -b "$file" | awk '{print $1}'`
            echo "file type: $FILE_TYPE"
            
            if [[ "$FILE_TYPE" = "PDF" ]]; then
                # Move it outside of the watched folder
                mv "$file" ./processed/
                BASENAME=`basename "$file"`
                echo "Moved file from '$file' to './processed/$BASENAME'" 
                file=./processed/$BASENAME
                
                # Process the file            
                CREATION_DATE=`date +%Y-%m-%d_%H-%M-%S`
                FILE_NEW="./processed/$CREATION_DATE.pdf"
                echo "Compressing '$file' and saving as $FILE_NEW"
#                 gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$FILE_NEW $file
                gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$FILE_NEW $file
                
                # Rename old file and keep it as backup
                BACKUP_FILE="${FILE_NEW/.pdf/_original.pdf}" 
                mv $file $BACKUP_FILE
            else # Its not a PDF 
                echo "Not processing file '$file', its not a PDF!"
            fi
            
            echo ""
            echo "----------------------------------"
            break
        done
    fi
done
