<?
/* replace <module> root tag with <section> root tag */

$filelist = file('accounting.txt');
foreach($filelist as $index => $file)
  $filelist[$index] = rtrim($file);

///foreach($filelist as $file)
///  fixMultiLineFile(rtrim($file));

foreach($filelist as $file){
  $cmd = "cp " . str_replace('/testUGCDb/','/UGCDb/',$file) . " $file";
  echo "$cmd\n";
  ///system($cmd);
}

///foreach($filelist as $file)
///   fixEmptyFile($file);
///   system("ls -l $file");

// this function basically makes the file be empty
function fixEmptyFile($filename){
   $dest = fopen($filename,'w');
   fwrite($dest,'');
   fclose($dest);
}

// Read file line by line. If line is the doctype or the <module> root, update it, otherwise spit out line
function fixMultiLineFile($filename){
   $src = fopen($filename,'r');
   $dest = fopen($filename . '_fixed','w');
   $isDoctypeFixed = false;
   $isRootFixed = false;
   if ($src){
      while (!feof($src)){
         $line = fgets($src);
         if ($isDoctypeFixed && $isRootFixed){
            fwrite($dest,$line);
         }
         else{
            if (!$isDoctypeFixed && (strpos($line,'DOCTYPE module') !== false)){
               $newline = str_replace('DOCTYPE module','DOCTYPE section',$line);
               fwrite($dest,$newline);
               $isDoctypeFixed = true;
            }
            elseif (!$isRootFixed && (strpos($line,'<module') !== false)){
               $newline = str_replace('<module','<section',$line);
               fwrite($dest,$newline);
               fwrite($dest,"<module>\n");
               $isRootFixed = true;
               $isDoctypeFixed = true;
            }
            else{ fwrite($dest,$line); }
         }
      }
      fwrite($dest,'</section>');
      fclose($dest);
      fclose($src);
      rename($filename . '_fixed',$filename);
   }
}
?>