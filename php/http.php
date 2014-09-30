<?
// send crazy CLIENT_IP header; example of how to spoof HTTP_CLIENT_IP
if (!$_GET['tester']){
   $fp = fsockopen("www.example.com", 80, $errno, $errstr, 30);
   if (!$fp) {
      echo "$errstr ($errno)<br />\n";
   }
   else{
      $out = "GET /~ndn/http.php?tester=1 HTTP/1.0\r\n";
      $out .= "Host: cops.teamgleim.com\r\n";
      $out .= "X_FORWARDED_FOR: 127.0.0.2\r\n";
      $out .= "Connection: Close\r\n\r\n";

      fwrite($fp, $out);
      $response = "";
      while (!feof($fp)) {
         $response .= fgets($fp, 128);
      }
      fclose($fp);
      echo $response;
   }
}
else{
   echo "<p>HTTP_CLIENT_IP: {$_SERVER['HTTP_CLIENT_IP']}</p>";
   echo "<p>REMOTE_ADDR: {$_SERVER['REMOTE_ADDR']}</p>";
   echo "<p>HTTP_X_FORWARDED_FOR: {$_SERVER['HTTP_X_FORWARDED_FOR']}</p>";
   echo "<p>HTTP_X_FORWARDED: {$_SERVER['HTTP_X_FORWARDED']}</p>";
}
?>
