#!/bin/bash

# This script lower-cases all src attributes of an <img> tag.

FILE=$1

if [ x$FILE = x ]; then
   echo
   echo "You must specify an input file"
   echo
   exit 1
fi

# for now, just searching for src="*" and lower-casing the * is sufficient, b/c no
# other tag except <img> uses a "src" attribute
sed -i -r "s/src=\"([^\"]*?)\"/src=\"\L\1\"/g" $FILE
