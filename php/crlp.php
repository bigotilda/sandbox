<?
/**************************************************************************
 * This file parses and displays various results from the change-req-log.xml.
 * The location of the file is hard-coded for now, but some sort of input for
 * the location can easily be added if so desired.
 *
 * Author: NDN 2006.05.15
 **************************************************************************/
?>
<html>
  <head><title>change-req-log.xml Parser</title></head>
  <body>
    <h3>change-req-log.xml Parser</h3>
    <p>
      <i>Select the fields to narrow down the query, then hit "Submit Query". Results will be shown
      below.</i>
    </p>
<?
$LOG_PATH = '../change-req-log.xml';

// verify file exists
if (!file_exists($LOG_PATH)){
   echo "<h3>File does not exist: $LOG_PATH</h3></body></html>";
   exit();
}

// load contents of $LOG_PATH into PHP simple XML object
if ($log = simplexml_load_file($LOG_PATH)){
   // create HTML form for choosing what to view
   $fields = array();
   $dateFields = array();
   foreach ($log->xpath("//change-request") as $request){
      foreach ($request->children() as $name => $child){
         $name = str_replace('-','_',$name);
         if (strpos($name,'date') !== false){
            if (!in_array($name,$dateFields))
               $dateFields[] = $name;
            continue;
         }
         if (!in_array($name,$fields))
            $fields[] = $name;
      }
   }
   sort($fields);
   echo "<form method=\"post\">\n";
   echo "  <table border=\"0\" cellspacing=\"3\">\n";
   echo "    <tr><td colspan=\"2\"><strong><u>Field</u></strong></td></tr>\n";
   for ($i = 0; $i < sizeof($fields); $i++){
      echo "    <tr>\n";
      echo "      <td>" . $fields[$i] . "</td>\n";
      echo "      <td><i>contains:</i> <input type=\"text\" name=\"txt[]\"" .
           (($_REQUEST['txt'] && $_REQUEST['txt'][$i])?" value=\"{$_REQUEST['txt'][$i]}\"":"") . "/></td>\n";
      echo "    </tr>\n";
   }
   if (sizeof($dateFields)){
      echo "    <tr><td colspan=\"2\"><strong><u>Date Ranges</u></strong></td></tr>\n";
      foreach($dateFields as $dateField){
        echo "    <tr>\n";
        echo "      <td>$dateField</td>\n";
        echo "      <td><i>From:</i> <input type=\"text\" name=\"{$dateField}FromYear\" size=\"4\" maxLength=\"4\"" .
             ($_REQUEST["{$dateField}FromYear"]?" value=\"".$_REQUEST["{$dateField}FromYear"]."\"":"") . "/> / " .
             "<input type=\"text\" name=\"{$dateField}FromMonth\" size=\"2\" maxLength=\"2\"" .
             ($_REQUEST["{$dateField}FromMonth"]?" value=\"".$_REQUEST["{$dateField}FromMonth"]."\"":"") . "/> / " .
             "<input type=\"text\" name=\"{$dateField}FromDay\" size=\"2\" maxLength=\"2\"" .
             ($_REQUEST["{$dateField}FromDay"]?" value=\"".$_REQUEST["{$dateField}FromDay"]."\"":"") . "/> " .
             "<i>To:</i> <input type=\"text\" name=\"{$dateField}ToYear\" size=\"4\" maxLength=\"4\"" .
             ($_REQUEST["{$dateField}ToYear"]?" value=\"".$_REQUEST["{$dateField}ToYear"]."\"":"") . "/> / " .
             "<input type=\"text\" name=\"{$dateField}ToMonth\" size=\"2\" maxLength=\"2\"" .
             ($_REQUEST["{$dateField}ToMonth"]?" value=\"".$_REQUEST["{$dateField}ToMonth"]."\"":"") . "/> / " .
             "<input type=\"text\" name=\"{$dateField}ToDay\" size=\"2\" maxLength=\"2\"" .
             ($_REQUEST["{$dateField}ToDay"]?" value=\"".$_REQUEST["{$dateField}ToDay"]."\"":"") . "/> " .
             "<font size=\"-1.5\"><i>(YYYY / MM / DD)</i></font></td>\n";
        echo "    </tr>\n";
      }
   }
   echo "    <tr><td colspan=\"2\"><input type=\"submit\" name=\"submit\"/></td></tr>\n";
   echo "  </table>\n";
   echo "</form>\n";

   // if submitted, do the requested search and display results
   if ($_REQUEST['submit']){
      $xpathArray = array();
      if (is_array($_REQUEST['txt'])){
         for ($i = 0; $i < sizeof($_REQUEST['txt']); $i++){
           if (trim($_REQUEST['txt'][$i]))
              $xpathArray[] = $fields[$i] . 
                              "[contains(translate(.,'" . strtoupper(trim($_REQUEST['txt'][$i])) . 
                              "','" . strtolower(trim($_REQUEST['txt'][$i])) . "'),'" . 
                              strtolower(trim($_REQUEST['txt'][$i])) . "')]";
         }
      }
      $xpathStr = "//change-request";
      if (sizeof($xpathArray))
         $xpathStr .= "[" . implode(' and ',$xpathArray) . "]";
      $results = $log->xpath($xpathStr);
      echo "<i>" . sizeof($results) . " result(s) found:</i>";
      foreach ($results as $request){
         // check for date range
         if (inDateRange($request))
            displayRequest($request);
      }
   }
}
else{
   echo "<h3>File could not be parsed: $LOG_PATH</h3>";
   exit();
}

// Displays the information for the request. We assume all requests will contain at least <from>,
// <developer>, <date>, and <comp-date>.
function displayRequest(&$request){
   echo "<br/><strong>Request:\n";
   echo "<table border=\"1\" cellspacing=\"0\" bgcolor=\"#C0C0C0\">\n";
   echo "  <tr>\n";
   echo "    <td><strong>From: </strong>" . $request->from . "</td>\n";
   echo "    <td><strong>Developer: </strong>" . $request->developer . "</td>\n";
   echo "    <td><strong>Date: </strong>" . $request->date . "</td>\n";
   $compDate = "comp-date";
   echo "    <td><strong>Completion Date: </strong>" . $request->$compDate . "</td>\n";
   echo "  </tr>\n";
   $children = $request->children();
   foreach ($children as $field => $value){
      if (!($field == "from" || $field == "developer" || $field == "date" || $field == "comp-date")){
         echo "  <tr><td><strong>$field</strong></td><td colspan=\"3\">" .
              htmlspecialchars($value) . "</td></tr>\n";
      }
   }
   echo "</table>\n";
}

// returns true if the request (A SimpleXMLElement object) falls within the specified date range(s), if any
function inDateRange(&$request){
   global $dateFields;
   foreach ($dateFields as $dateField){
      $fromYearField = "{$dateField}FromYear";
      $toYearField = "{$dateField}ToYear";
      if (!($_REQUEST[$fromYearField] || $_REQUEST[$toYearField]))
         continue;
      else{
         $fromYear = "0000"; // YYYY as string
         $fromMonth = "00";  // MM as string
         $fromDay =  "00";   // DD as string
         if ($_REQUEST[$fromYearField]){
            $fromYear = str_pad((int) $_REQUEST[$fromYearField],4,"0",STR_PAD_LEFT);
            if ($_REQUEST["{$dateField}FromMonth"])
               $fromMonth = str_pad((int) $_REQUEST["{$dateField}FromMonth"],2,"0",STR_PAD_LEFT);
            if ($_REQUEST["{$dateField}FromDay"])
               $fromDay = str_pad((int) $_REQUEST["{$dateField}FromDay"],2,"0",STR_PAD_LEFT);
         }
         $toYear = "9999"; // YYYY as string
         $toMonth = "99";  // MM as string
         $toDay =  "99";   // DD as string
         if ($_REQUEST[$toYearField]){
            $toYear = str_pad(((int) $_REQUEST[$toYearField]?$_REQUEST[$toYearField]:"9999"),4,"0",STR_PAD_LEFT);
            if ($_REQUEST["{$dateField}ToMonth"])
               $toMonth = str_pad(((int) $_REQUEST["{$dateField}ToMonth"]?$_REQUEST["{$dateField}ToMonth"]:"99"),
                                  2,
                                  "0",
                                  STR_PAD_LEFT);
            if ($_REQUEST["{$dateField}ToDay"])
               $toDay = str_pad(((int) $_REQUEST["{$dateField}ToDay"]?$_REQUEST["{$dateField}ToDay"]:"99"),
                                2,
                                "0",
                                STR_PAD_LEFT);
         }
         $xmlField = str_replace('_','-',$dateField);
         if (!((string) $request->$xmlField >= "$fromYear.$fromMonth.$fromDay" &&
               (string) $request->$xmlField <= "$toYear.$toMonth.$toDay"))
            return false;
      }
   }
   return true;
}
?>
  </body>
</html>
