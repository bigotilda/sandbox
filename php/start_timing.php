<?
/* Used to start timing a block of code. Include this file before the block to be timed,
   and include stop_timing.php after the block. Note that both this file and stop_timing.php should
   be in the same scope, so the variables can be shared. */

$sTimingArray = '_timing';
while (isset($$sTimingArray))
{
   $sTimingArray = '_timing' . rand(0,1000);
}
${$sTimingArray}['testStartLoc'] = trim(basename($_SERVER['PHP_SELF']) . ':' . $_nLine . ' ' .
                                        __CLASS__ . (__METHOD__?': '.__METHOD__:'') . ' ' .
                                        __FUNCTION__);
${$sTimingArray}['testTimeStamp'] = date('Y-m-d H:i:s');
${$sTimingArray}['start'] = microtime(true);
?>