<?
// error/usage checking
$usage = "Lists the aggregate list of distinct XML tags and the attributes used in those tags in the\n" .
         "specified XML file, or in the group of XML files located in the directory (does not go into subdirs)\n" .
         "if a directory is specified.\n\n" .
         "usage: php xmltagreport.php PATH [FILTER]\n" .
         "   PATH: absolute path to xml file (/path_to_file/file.xml) or directory (/path_to_dir/)\n" .
         "   FILTER: regular expression that each file name must match in order to be included. The\n" .
         "           regular expression should be one that can be used in the preg_match() PHP function.\n";
if (!$argv[1] || $argv[1][0] != '/'){
   echo "Please specify a target XML file or target directory containing XML files, using an absolute path!\n\n";
   echo $usage;
   exit();
}
$sExt = substr($argv[1],-4);
if (strtolower($sExt) != '.xml' && substr($sExt,-1) != '/'){
   echo "Please enter either a single XML file (/path_to_file/file.xml), or a directory (/path_to_dir/), using\n" .
        "an absolute path.\n\n";
   echo $usage;
   exit();
}

// get the files to be included in the report
$aReportFiles = array();
if ($sExt == '.xml'){
   $aReportFiles[] = $argv[1];
}
else{
   $sPath = $argv[1];
   $aDirFiles = scandir($sPath);
   foreach ($aDirFiles as $sFile){
      if ( substr($sFile,-4) == '.xml' && 
           (!$argv[2] || preg_match($argv[2],$sFile)) )
         $aReportFiles[] = "$sPath$sFile";
   }
}

// read each file, taking note of the XML tags and attributes used in the file
$aXMLTags = array();
if (count($aReportFiles)){
   foreach ($aReportFiles as $sFile){
      $oXML = @simplexml_load_file($sFile);
      recordXMLMetaData($oXML);
   }
   
   // display results
   echo "\n";
   foreach ($aXMLTags as $sTagName => $aAtts){
      echo "$sTagName: " . implode(',',$aAtts) . "\n";
   }
}
else
   echo "no XML files matched!\n";

function recordXMLMetaData($oXML){
   global $aXMLTags;

   // record the tag if not encountered before
   $sTagName = $oXML->getName();
   if (!isset($aXMLTags[$sTagName]))
      $aXMLTags[$sTagName] = array();

   // record the attributes of this tag if not encountered before
   foreach ($oXML->attributes() as $sAttName => $sAttValue){
      if (!in_array($sAttName,$aXMLTags[$sTagName]))
         $aXMLTags[$sTagName][] = $sAttName;
   }

   // process the children tags
   foreach ($oXML->children() as $oChild){
      recordXMLMetaData($oChild);
   }
}
?>
