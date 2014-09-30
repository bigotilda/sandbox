<?
$sString1 = getContentString($argv[1]);
$sString2 = getContentString($argv[2]);

$p = 0;
similar_text($sString1,$sString2,$p);
echo 100-round($p,2) . "\n";

function getContentString($sFile){
  $tempXML = simplexml_load_file($sFile);
  $aText = $tempXML->xpath("//text()[normalize-space(.) != '']");
  $sStr = '';
  foreach ($aText as $sLine){
    $sStr .= trim($sLine) . " ";
  }
  return $sStr;
}
?>
