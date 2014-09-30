<?
foobuzz($argv[1],0,$argv[2]);
function foobuzz($sList,$level,$target){
  $nLen = strlen($sList);
  if ($nLen == 1)
    return array($sList);

  $nSplit = ceil($nLen/2);
  $aSubList1 = foobuzz(substr($sList,0,$nSplit),$level+1,$target);
  $aSubList2 = foobuzz(substr($sList,$nSplit),$level+1,$target);
  
  $aResults = array();
  foreach($aSubList1 as $item1){
    foreach($aSubList2 as $item2){
      foreach (array('','+','-','*') as $op){
        $str = "$item1$op$item2";
        $aResults[] = $str;
        if (($level == 0) && eval("return $str;") == $target)
          echo "$str = $target\n";
      }
    }
  }
  return $aResults;
}
?>
