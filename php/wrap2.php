<?
$fd = fopen($argv[1],'r');
$nCharsPerLine = $argv[2];
if ($fd){
   $nCharCount = 1;
   while (false !== ($c = fgetc($fd))){
      echo $c;
      if ($c == "\n"){
         $nCharCount = 1;
      }
      elseif ($nCharCount % $nCharsPerLine == 0){
         echo "\n";
         $nCharCount = 1;
      }
      else{
         $nCharCount++;
      }
   }
}


?>
