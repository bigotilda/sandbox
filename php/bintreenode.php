<?php
error_reporting( E_ALL | E_NOTICE );
///
$start = microtime(true);
///

class BinTreeNode{
   private $value;
   private $left;
   private $right;
   
   public function __construct($value){
      $this->value = $value;
      $this->left = null;
      $this->right = null;
   }
   
   private function addLeft(&$bintreenode){
      $this->left = $bintreenode;
   }
   
   private function addRight(&$bintreenode){
      $this->right = $bintreenode;
   }
   
   public function add($value){
      if ($value <= $this->value){
         if (is_null($this->left))
            $this->addLeft(new BinTreeNode($value));
         else
            $this->left->add($value);
      }
      else{
         if (is_null($this->right))
            $this->addRight(new BinTreeNode($value));
         else
            $this->right->add($value);
      }
   }
   
   public function visit(){
      return $this->value;
   }
   
   public function getLeft(){
      return $this->left;
   }
   
   public function getRight(){
      return $this->right;
   }
   
   public function preorder(){
      //echo $this->visit() . "<br/>";
      $this->visit();
      if (!is_null($this->left))
        $this->left->preorder();
      if (!is_null($this->right))
        $this->right->preorder();
   }
   
   public function inorder(){
      if (!is_null($this->left))
        $this->left->inorder();
      //echo $this->visit() . "<br/>";
      $this->visit();
      if (!is_null($this->right))
        $this->right->inorder();
   }
   
   public function postorder(){
      if (!is_null($this->left))
        $this->left->postorder();
      if (!is_null($this->right))
        $this->right->postorder();
      //echo $this->visit() . "<br/>";
      $this->visit();
   }
}

function preorder($bintreenode){
   if (!is_null($bintreenode)){
      //echo $bintreenode->visit() . "<br/>";
      $bintreenode->visit();
      preorder($bintreenode->getLeft());
      preorder($bintreenode->getRight());
   }
}

function inorder($bintreenode){
   if (!is_null($bintreenode)){
      inorder($bintreenode->getLeft());
      //echo $bintreenode->visit() . "<br/>";
      $bintreenode->visit();
      inorder($bintreenode->getRight());
   }
}

function postorder($bintreenode){
   if (!is_null($bintreenode)){
      postorder($bintreenode->getLeft());
      postorder($bintreenode->getRight());
      //echo $bintreenode->visit() . "<br/>";
      $bintreenode->visit();
   }
}

for ($n=0; $n<1000; $n++){
   $val = rand(1,20);
   //echo "adding $val...<br/>";
   $root = new BinTreeNode($val);
   for ($i=1; $i<=7; $i++){
      $val = rand(1,20);
      //echo "adding $val...<br/>";
      $root->add($val);
   }
   /*preorder($root);
   inorder($root);
   postorder($root);*/
   $root->preorder();
   $root->inorder();
   $root->postorder();
}
/*echo "<hr/>";
preorder($root);
echo "<hr/>";
inorder($root);
echo "<hr/>";
postorder($root);
echo "<hr/>";
echo "<hr/>";
$root->preorder();
echo "<hr/>";
$root->inorder();
echo "<hr/>";
$root->postorder();*/


///
$runtime = microtime(true) - $start;
echo "<br/>total runtime: {$runtime}s<br/>";
///
?>
