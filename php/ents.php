<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
  </head>
  <body>
<?
// display the symbols/characters listed in the UGCDb/*.ent files as HTML entities
$aEntFiles = array('xhtml-lat1.ent',
                   'xhtml-special.ent',
                   'xhtml-symbol.ent');

foreach ($aEntFiles as $sEntFile){
   echo "<strong>$sEntFile:</strong><br/>\n";
   echo "<table>\n";
   $fh = fopen($sEntFile,'r');
   while (!feof($fh)) {
     $sLine = fgets($fh);
     if (preg_match("/&#[0-9]+;/",$sLine,$aMatches))
        echo "<tr><td>" . htmlentities($sLine) . "</td><td><span style=\"font-family:OpenSymbol;\">" . $aMatches[0] . "</span></td></tr>\n";
   }
   echo "</table>\n";
   fclose($fh);
}
?>
  </body>
</html>
