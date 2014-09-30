for a in `ls FILE_GLOB_PATTERN`; do ./QUERY $a | sed "s/<[^>]\+>//g" | wc -w ; echo "+"; done | tr -s "\n" " " | sed "s/+ $/\n/g" | bc;
