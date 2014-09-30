<?
// Attempt at receiving and forwarding OO file save requests (sent as URL via storeToURL() OO Basic function)
$fd = fopen("http_data","w");

// headers
$headers = apache_request_headers();
$headerData = "";
foreach ($headers as $header => $value) {
   $headerData .= "$header: $value\n";
}
fwrite($fd,$headerData);

// post raw data
$fin = fopen("php://input","r");
$data = "";
while (!feof($fin))
   $data .= fgets($fin);
fclose($fin);
fwrite($fd,$data);

fclose($fd);
?>