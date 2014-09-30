#!/bin/bash
cvs log $1 | grep -B 1 "\-\-\-\-\-" | grep -v "\-\-" | sort | uniq -c | sort -rg
