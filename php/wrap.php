<?
$fd = fopen($argv[1],'r');
$nCharsPerLine = $argv[2];
if ($fd){
   while (!feof($fd)){
      $nCharCount = 1;
      $sLine = fgets($fd);
      $nStrLen = strlen($sLine);
      while ($nCharCount <= $nStrLen){
         echo $sLine[$nCharCount-1];
         if ($nCharCount % $nCharsPerLine == 0)
            echo "\n";
         $nCharCount++;
      }
   }
}


?>
