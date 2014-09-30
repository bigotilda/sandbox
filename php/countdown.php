<?php
error_reporting( E_ALL | E_STRICT | E_NOTICE );

?>
<h3><?=$_GET['emp']?>'s time remaining till lunch...</h3>
<br/>
<span id="counter">Huh?</span> 

<script> 
<!-- 
// 
 var milisec=0;
 var seconds=<?=$_GET['time']?>;
 document.all.counter = 'wtf';

function display(){ 
 if (milisec<=0){ 
    milisec=9;
    seconds-=1; 
 } 
 if (seconds<=-1){ 
    milisec=0;
    seconds+=1; 
 } 
 else 
    milisec-=1;
    document.all.counter.innerHTML=seconds+"."+milisec;
    setTimeout("display()",100);
} 
display();
--> 
</script>
