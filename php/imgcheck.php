<?
$usage = "For each image in the specified image directory, this script prints out which files from\n" .
         "the specificed target directory contain a reference to that image.\n\n" .
         "usage: php imgcheck.php [image directory] [target directory]\n";
if (!$argv[1] || $argv[1][0] != '/'){
   echo "Please enter an image directory, using an absolute path!\n\n";
   echo $usage;
   exit();
}
if (!$argv[2] || $argv[2][0] != '/'){
   echo "Please enter a target file directory, using an absolute path!\n\n";
   echo $usage;
   exit();
}
$imgdir = $argv[1];
$filedir = $argv[2];
chdir($imgdir); // this may not be needed
if ($handle = opendir($imgdir)){ 
   /* This is the correct way to loop over the directory. */
   while (false !== ($file = readdir($handle))) { 
       if ($file != "." && $file != ".." && !is_dir($file)){
          $cmd = "grep -l \"image/$file\" $filedir*";
          $results = array();
          exec($cmd,$results);
          if (count($results) > 0){
             foreach ($results as $key => $value)
                $results[$key] = basename($value);
             echo "$file: " . implode(",",$results) . "\n";
          }
          else
             echo "$file: no entries\n";
       }
   }
   closedir($handle); 
}
?>
