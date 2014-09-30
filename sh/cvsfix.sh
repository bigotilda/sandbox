find . -type d -name "CVS" | sort | php -R"echo dirname(\$argn).\"\n\";" | xargs cvs -q status | grep -i locally
