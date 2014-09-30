<?php
error_reporting( E_ALL | E_NOTICE );
///
$start = microtime(true);
///

class Node{
   private $visited = false;
   private $name;
   private $edges = array();
   private $condEdges = array();
   
   public function __construct($name){
      $this->name = $name;
   }
   
   public function addEdge($node){
      $this->edges[] = $node;
   }
   
   public function addCondEdge($targetNode,$skipNode){
      $this->condEdges[] = array('target'=>$targetNode, 'skip'=>$skipNode);
   }
   
   public function visit(){
      $this->visited = true;
   }
   
   public function isVisited(){
      return $this->visited;
   }
   
   public function unVisit(){
      $this->visited = false;
   }
   
   public function walk($steps,$path=''){
      $this->visit();
      $path .= $this->name;
      // still walking
      if ($steps > 0){
         // first check conditional edges
         foreach ($this->condEdges as $condEdge){
            if ($condEdge['skip']->isVisited() and (!$condEdge['target']->isVisited()))
               $condEdge['target']->walk($steps-1,$path);
         }
         // now check normal edges
         foreach ($this->edges as $edgeNode){
            if (!$edgeNode->isVisited())
               $edgeNode->walk($steps-1,$path);
         }
      }
      // end of a path
      else{
         $GLOBALS['count']++;
         echo "#{$GLOBALS['count']}: path: $path<br/>";
      }
      // when done with the walk, clear visited
      $this->unVisit();
   }
}

// Setup the particular graph we are interested in (the Android 9-dot pattern)
// @TODO if this were in the future to be made into a general tool, this information could easily
// be ingested from a yaml/xml/json config file of an appropriate structure.
$node1 = new Node('1');
$node2 = new Node('2');
$node3 = new Node('3');
$node4 = new Node('4');
$node5 = new Node('5');
$node6 = new Node('6');
$node7 = new Node('7');
$node8 = new Node('8');
$node9 = new Node('9');

// node1 edges
$node1->addEdge($node2);
$node1->addCondEdge($node3, $node2);
$node1->addEdge($node4);
$node1->addEdge($node5);
$node1->addEdge($node6);
$node1->addCondEdge($node7, $node4);
$node1->addEdge($node8);
$node1->addCondEdge($node9, $node5);

// node2 edges
$node2->addEdge($node1);
$node2->addEdge($node3);
$node2->addEdge($node4);
$node2->addEdge($node5);
$node2->addEdge($node6);
$node2->addEdge($node7);
$node2->addCondEdge($node8,$node5);
$node2->addEdge($node9);

// node3 edges
$node3->addCondEdge($node1,$node2);
$node3->addEdge($node2);
$node3->addEdge($node4);
$node3->addEdge($node5);
$node3->addEdge($node6);
$node3->addCondEdge($node7, $node5);
$node3->addEdge($node8);
$node3->addCondEdge($node9, $node6);

// node4 edges
$node4->addEdge($node1);
$node4->addEdge($node2);
$node4->addEdge($node3);
$node4->addEdge($node5);
$node4->addCondEdge($node6,$node5);
$node4->addEdge($node7);
$node4->addEdge($node8);
$node4->addEdge($node9);

// node5 edges
$node5->addEdge($node1);
$node5->addEdge($node2);
$node5->addEdge($node3);
$node5->addEdge($node4);
$node5->addEdge($node6);
$node5->addEdge($node7);
$node5->addEdge($node8);
$node5->addEdge($node9);

// node6 edges
$node6->addEdge($node1);
$node6->addEdge($node2);
$node6->addEdge($node3);
$node6->addCondEdge($node4,$node5);
$node6->addEdge($node5);
$node6->addEdge($node7);
$node6->addEdge($node8);
$node6->addEdge($node9);

// node7 edges
$node7->addCondEdge($node1,$node4);
$node7->addEdge($node2);
$node7->addCondEdge($node3,$node5);
$node7->addEdge($node4);
$node7->addEdge($node5);
$node7->addEdge($node6);
$node7->addEdge($node8);
$node7->addCondEdge($node9,$node8);

// node8 edges
$node8->addEdge($node1);
$node8->addCondEdge($node2,$node5);
$node8->addEdge($node3);
$node8->addEdge($node4);
$node8->addEdge($node5);
$node8->addEdge($node6);
$node8->addEdge($node7);
$node8->addEdge($node9);

// node9 edges
$node9->addCondEdge($node1,$node5);
$node9->addEdge($node2);
$node9->addCondEdge($node3,$node6);
$node9->addEdge($node4);
$node9->addEdge($node5);
$node9->addEdge($node6);
$node9->addCondEdge($node7,$node8);
$node9->addEdge($node8);

$graph = array();
for ($i=1; $i<=9; $i++){
   $node = "node$i";
   $graph[] = $$node;
}

// start walkin' the graph
$GLOBALS['count'] = 0;

// this loops through all possible password lengths from 3 to 8
for ($i=3; $i<=8; $i++){
   foreach ($graph as $node){
      $node->walk($i);
      echo "<hr width=\"25%\" align=\"left\"/>\n";
   }
}

///
$runtime = microtime(true) - $start;
echo "<br/>total runtime: {$runtime}s<br/>";
///
?>
