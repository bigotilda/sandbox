<?
error_reporting( E_ALL | E_STRICT | E_NOTICE );
ini_set('display_errors',1);
?>
<form method="post" id="numberform" name="numberform">
  enter the integer: <input type="text" name="number" id="numberfield" name="numberfield"/>
</form>
<?
if (isset($_REQUEST['number']))
{
   $number = (int) $_REQUEST['number'];
   echo "Number: $number<hr width='25%' align='left'/>";
   echo "<table border='0'>";
   $symbols = array(10 => 'A', 11 => 'B', 12 => 'C', 13 => 'D', 14 => 'E', 15 => 'F', 16 => 'G', 17 => 'H', 18 => 'I',
                    19 => 'J', 20 => 'K', 21 => 'L', 22 => 'M', 23 => 'N', 24 => 'O', 25 => 'P', 26 => 'Q', 27 => 'R',
                    28 => 'S', 29 => 'T');
   for ($base = 30; $base >=2; $base--)
   {
      $number = (int) $_REQUEST['number'];
      $digits = array();
      $exp = 0;
      $digits[$exp] = $number % $base;
      while (($number = floor($number / $base)) >= 1)
      {
         $exp++;
         $digits[$exp] = $number % $base;
      }
      printDigits($digits, $base);
   }
   echo "</table>";
}

function printDigits($digits, $base)
{
   global $symbols;

   $out = "";
   foreach ($digits as $digit)
   {
      if (isset($symbols[$digit]))
         $out = $symbols[$digit] . $out;
      else
         $out = $digit . $out;
   }
   echo "<tr><td align='right'>Base $base:</td><td align='left'>$out</td></tr>";
}
?>
<script language="javascript" type="text/javascript">
document.numberform.numberfield.focus()
</script>
