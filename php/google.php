<?
$digits = array(16,23,61,7,7,7,13,13,13,19,19,21,27,56,56,73,77,97,11,37,41);
$answers = array(917,134,1569,1649,1431,1622,233,2094,1072,915,1922,2437,2714,2491,1886,2812,426,1673,94,2139,2569,496,2249,1553,1580);

fullCompute($digits);

function fullCompute($digits){
   global $answers;
   $length = sizeof($digits);
   for ($i=0; $i<$length; $i++){
      $currIndices = array();
      $currIndices['i'] = $i;
      for ($j=0; $j<$length; $j++){
         if (in_array($j,$currIndices))
            continue;
         else
            $currIndices['j'] = $j;
         for ($k=0; $k<$length; $k++){
            if (in_array($k,$currIndices))
               continue;
            else
               $currIndices['k'] = $k;
            for ($l=0; $l<$length; $l++){
               if (in_array($l,$currIndices))
                  continue;
               else
                  $currIndices['l'] = $l;
               for ($m=0; $m<$length; $m++){
                  if (in_array($m,$currIndices))
                     continue;
                  $res = compute($digits[$i],$digits[$j],$digits[$k],$digits[$l],$digits[$m]);
                  if (in_array($res,$answers)){
                     echo "$res = {$digits[$i]} * {$digits[$j]} + {$digits[$k]} - {$digits[$l]} + {$digits[$m]}<br>"; 
                     $answers = array_diff($answers,array($res));
                  }
               }
            }
         }
      }
   }
   echo "<h3>These could not be calculated:</h3>";
   foreach ($answers as $answer)
      echo "$answer<br>";
}

function getIndexCombos($level,$digits){
   for ($i=0; $i<sizeof($digits); $i++)
      $res[] = array($i);
   for ($i=2; $i<=$level; $i++){
      foreach ($digits as $digitIndex => $digit){
         foreach ($res as $resultEntry){
            if (!in_array($digitIndex,$resultEntry))
               $newres[] = array_merge(array($digitIndex),$resultEntry);
         }
      }
      $res = $newres;
      unset($newres);
   }
   return $res; 
}

function compute($a,$b,$c,$d,$e){
   return $a*$b+$c-$d+$e;
}
?>
