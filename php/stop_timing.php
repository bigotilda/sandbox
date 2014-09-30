<?
/* Used to stop timing a block of code and report results to a file. Include this file after the block
   to be timed, and include start_timing.php before the block. Note that both this file and start_timing.php
   should be in the same scope, so the variables can be shared. */
${$sTimingArray}['stop'] = microtime(true);
${$sTimingArray}['fh'] = fopen('/tmp/phptiming.txt','a');
fwrite(${$sTimingArray}['fh'],${$sTimingArray}['testStartLoc'].': start: '.${$sTimingArray}['start'].' stop: '.${$sTimingArray}['stop'].' elapsed time: ' . (${$sTimingArray}['stop'] - ${$sTimingArray}['start']) . "\n");
fclose(${$sTimingArray}['fh']);
unset($$sTimingArray);
?>
