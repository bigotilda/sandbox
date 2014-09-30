<?
if (!$argv[1] || $argv[1][0] != '/'){
   echo "Please enter a target directory, using an absolute path!\n\n";
   exit();
}
echo "lower-casing files at " . $argv[1] . "...\n";
$path = $argv[1];
chdir($path);
if ($handle = opendir($path)){ 
   /* This is the correct way to loop over the directory. */
   while (false !== ($file = readdir($handle))) { 
       if ($file != "." && $file != ".."){
          echo "switching $file to " . strtolower($file) . "\n";
          system("cp $file ".strtolower($file));
       }
   }
   closedir($handle); 
}
