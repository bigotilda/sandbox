#!/bin/bash

# This script switches images/ to image/ in the src attribute of all <img> tags.

FILE=$1

if [ x$FILE = x ]; then
   echo
   echo "You must specify an input file"
   echo
   exit 1
fi

# for now, just searching for src="images/" is sufficient, b/c no
# other tag except <img> uses a "src" attribute
sed -i -r "s/src=\"images\/([^\"]*?)\"/src=\"image\/\1\"/g" $FILE
