<?
/**************************************************************************
 * This file should be run as a cron job on the server. It clears out
 * old mysql dump files from the $DUMP_DIR directory on the server.These files
 * are created whenever a database table is about to be altered by a database
 * write operation.
 *
 * Author: NDN 2005.01.12
 **************************************************************************/

$DUMP_DIR     = "/tmp/dumps";
$CLEAN_UP_AGE = 60 * 60 * 24 * 14; // 14 days in seconds

// remove files in $DUMP_DIR that are older than $CLEAN_UP_AGE
$toRemove = array();
if ($handle = opendir($DUMP_DIR)){
   while (false !== ($file = readdir($handle))) {
       if ($file != "." && $file != ".."){
         if ((time() - filemtime("$DUMP_DIR/$file")) > $CLEAN_UP_AGE)
            $toRemove[] = $file;
       }
   }
   closedir($handle);
}
foreach ($toRemove as $rm)
   unlink("$DUMP_DIR/$rm");
?>
