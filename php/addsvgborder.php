<?
$usage = "For each SVG image listed as an argument, this script adds a border to that SVG.\n" .
         "usage: php addsvgborder.php [list of SVG images]\n";
/**
 * I'm not going to bother with XML parsing, I'm just going to check the beginning of the trimmed line. Note
 * that this means that I'm assuming the <svg> tag is the first thing on its line.
 * todo: finish!!!! just line by line it, inserting the root 
 **/
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
