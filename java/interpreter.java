/**
 * This is an OLD partially redacted sample file whose original inspiration was
 * provided by another author Thierry Manfe (sp?) but was subsequently heavily
 * modified and added to by me to be able to work as a formula interpreter for
 * spreadsheet simulation I was working on at the time.
 *
 * The proprietary version of this code has been updated many times since, but 
 * I am still choosing to snip out various bits and pieces and just show some 
 * of the more interesting functions:
 *   - The definition of the context free grammar for the language.
 *   - The tokenization of the above.
 *   - The computation of values from the tokens (the datastructure is not quite
 *     an abstract syntax tree (AST), but it is similar in philosophy.
 */

/*** SNIP ***/

import java.text.ParseException;
import java.util.Vector;
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

public class Interpreter {

   /**
    * Set this variable to true to get
    * some debugging traces.
    */
   static final boolean DEBUG = false;

   class InterpreterEvent extends Throwable {
      public InterpreterEvent() { super(); }
      public InterpreterEvent(String s) { super(s); }
   }

   /**
    * A syntax error terminates the evaluation
    * of the formula immediately
    */
   class SyntaxError extends InterpreterEvent {
      public SyntaxError() { super(); }
      public SyntaxError(String s) { super(s); }
   }

   class SyntagmaMismatch extends InterpreterEvent {
      public SyntagmaMismatch() { super(); }
   }
   
   /*
    * For errors when a numeric value is expected, but something else (text) is given.
    */
   class NonNumberError extends InterpreterEvent {
          public NonNumberError() { super(); }
   }

   class EndFormula extends InterpreterEvent {
      public EndFormula() { super(); }
   }

   class EndFormulaComma extends EndFormula {
      public EndFormulaComma() { super(); }
   }

   class EndFormulaNormal extends EndFormula {
      public EndFormulaNormal() { super(); }
   }

   class CircularReferenceError extends InterpreterEvent {
      public CircularReferenceError() { super(); }
   }

   // constants used in parsing/interpreting of formulas
   static final String FORMULA      = "FORMULA";
   static final String TERM         = "TERM";
   static final String FUNCTION     = "FUNCTION";
   static final String FNAME        = "FNAME";
   static final String PARAMS       = "PARAMS";
   static final String CELLID       = "CELLID";
   static final String NUMBER       = "NUMBER";
   static final String OPENPAR      = "(";
   static final String CLOSEPAR     = ")";
   static final String RANGE        = ":";
   static final String COMMA        = ",";
   static final String OPERATOR     = "OPERATOR";
   static final String UNARY_OP     = "UNARY_OP";

   // operator list
   static final String EXPONENT     = "^";
   static final String MULTIPLY     = "*";
   static final String DIVIDE       = "/";
   static final String ADD          = "+";
   static final String SUBTRACT     = "-";
   static final String LT           = "<";
   static final String LTEQ         = "<=";
   static final String GT           = ">";
   static final String GTEQ         = ">=";
   static final String EQ           = "=";
   static final String AND          = "&";
   static final String OR           = "|";
   static final String POS          = "+";
   static final String NEG          = "-";

   // Truth values. These have two values each: the string displayed if by themselves (boolean value),
   // or their numerical value if part of a larger expression (numerical value)
   static final String BTRUE        = "TRUE";
   static final float  NTRUE        = 1;
   static final String BFALSE       = "FALSE";
   static final float  NFALSE       = 0;
   static final char[]   SEPARATORS     = {'^','+','-','/','*','(',')','<','>','=','&','|',':',','};
   static final String[] FNAMES         = {"ADD","SUM","PRODUCT","IF"};
   static final String[] OPERATORS      = {LTEQ,GTEQ,EXPONENT,MULTIPLY,DIVIDE,ADD,SUBTRACT,LT,GT,
                                           EQ,AND,OR};
   static final String[] UNARY_OPS      = {POS,NEG};
   static final String   SYNTAX_ERROR   = "Error";
   static final String   CIRC_REF_ERROR = "Circular Ref Err";
   static final String NON_NUMBER_ERROR = "";

/*** SNIP ***/

   private String             _formula;

   private int     _depth;
   private boolean _userEdit;

/*** SNIP ***/

   private String       _leaf;
   private StringBuffer _buffer;
   private List         _tokens = new ArrayList();
   private Stack        _parStack = new Stack();
   private int          _parCount;

   public Interpreter(AbstractTableModel data) {
      _data = data;
   }

   /**
    * This method actually interprets the
    * formula and returns the computed value.
    *
    * Following is the grammar description. Expressions
    * between brackets are optional. A list of items
    * between braces represents any single item from that list.
    *
    *     FORMULA = TERM
    *     FORMULA = UN_OP TERM
    *     FORMULA = TERM BIN_OP FORMULA
    *     FORMULA = UN_OP TERM BIN_OP FORMULA
    *
    *     TERM = FUNCTION
    *     TERM = ( FORMULA )
    *     TERM = CELLID
    *     TERM = NUMBER
    *
    *     FUNCTION = FNAME( CELLID : CELLID )
    *     FUNCTION = FNAME( PARAMS )
    *
    *     FNAME = {"ADD","FV","IF","NPER","PMT","PRODUCT","PV","SUM"}
    *
    *     PARAMS = FORMULA
    *     PARAMS = FORMULA , PARAMS
    *
    *     UN_OP = {+,-}
    *
    *     BIN_OP = {EXP_OP,MULT_OP,ADD_OP,COMP_OP,LOGIC_OP}
    *
    *     EXP_OP   = ^
    *     MULT_OP  = {*,/}
    *     ADD_OP   = {+,-}
    *     COMP_OP  = {<,<=,>,>=,=}
    *     LOGIC_OP = {&,|}
    *
    *     NUMBER = {any properly formed number, TRUE, FALSE}
    *
    * @param  SheetCellModel The cell to update
    * @param  boolean        If true, the method has been called by
    *                        an edit of the cell by the user
    * @return boolean        Must return true for other cells to update theirselves
    */
   public boolean interpret(SheetCellModel cell, boolean userEdit) {

      if (DEBUG) {
         _depth=0;
         System.out.println("START");
      }

      _userEdit   = userEdit;
      initializeFormula(cell);

      //cell is empty
      if (_formula.length()==0) {
         cell.setValue(null);
         cell.setFormula(null);
      }

      //cell has a formula
      else if (_formula.charAt(0)=='=') {
         _cell = cell;
         _tokens.clear();
         _parStack.clear();
         _parCount = 0;

         if (_userEdit) {
            // Convert all characters to
            // uppercase characters.
            char[] upper = _formula.toCharArray();
            for (int ii = 0; ii < upper.length; ii++)
               upper[ii] = Character.toUpperCase(upper[ii]);

            _formula = new String(upper);
            cell.setFormula(_formula);
         }

         _formula = _formula.substring(1,_formula.length());
         _buffer  = new StringBuffer(_formula);

         // recursively tokenize the formula
         try {
            tokenize(FORMULA);
         }
         catch (CircularReferenceError cr){
            cell.setValue(CIRC_REF_ERROR);
            return true;
         }
         catch (NonNumberError nne) {
                cell.setValue(NON_NUMBER_ERROR);
                return true;
         }
         catch (InterpreterEvent evt) {
            cell.setValue(SYNTAX_ERROR);
            return true;
         }

         // check for any remaining tokens (close pars mainly) that have not been parsed. If there
         // are any, this is a syntax error (means there is a closing par with no open par).
         if (_formula.length() != 0){
            cell.setValue(SYNTAX_ERROR);
            return true;
         }

         // compute the value of the formula, which is now represented as a list of tokens
         String value = null;
         try{
            if (DEBUG) System.out.println("Start Computing");
            value = rcompute(_tokens);
            cell.setValue(value);
         }
         catch (SyntaxError e){
            cell.setValue(SYNTAX_ERROR);
         }
      }

      //cell has a non-formula value
      else {
         cell.setValue(cell.getFormula());
         cell.setFormula(null);
      }
      return true;
   }

   /*
    * Checks for syntax errors in formula and tokenizes it for computation later.
    * syntagma is the grammatical term looked for.
    */
   private void tokenize(String syntagma) throws InterpreterEvent {
      int localDepth;
      if (DEBUG) {
         _depth++;
         localDepth = _depth;
         System.out.println("********** Depth: "+_depth);
      }

      if (syntagma.equals(FORMULA)) {

         if (DEBUG) System.out.println("Looking for a FORMULA");

         try { tokenize(TERM); }
         catch (EndFormulaComma err)  { throw new SyntaxError(); }
         catch (SyntagmaMismatch evt) { 
            if (DEBUG) _depth = localDepth;
            try {
               tokenize(UNARY_OP);
               tokenize(TERM);
            }
            catch (SyntagmaMismatch evt2) { throw new SyntaxError(); }
         }

         try {
            tokenize(OPERATOR);
            try {
               tokenize(FORMULA);
            }
            catch (EndFormulaNormal err) { throw new SyntaxError(); }
            catch (SyntagmaMismatch evt) { throw new SyntaxError(); }
         }
         catch (SyntagmaMismatch evt1) { throw new SyntaxError(); }
         catch (EndFormulaNormal end2) { if (DEBUG) _depth = localDepth; }

         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(TERM)) {

         if (DEBUG) System.out.println("Looking for a TERM");

         try { tokenize(FUNCTION); }
         catch (SyntagmaMismatch evt){
            if (DEBUG) _depth = localDepth;
            try {
               tokenize(OPENPAR);
               tokenize(FORMULA);
               tokenize(CLOSEPAR);
            }
            catch (SyntagmaMismatch evt1) {
               if (DEBUG) _depth = localDepth;
               try { tokenize(CELLID); }
               catch (SyntagmaMismatch ev) {
                  if (DEBUG) _depth = localDepth;
                  tokenize(NUMBER);
               }
            }
         }
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(FUNCTION)) {
         if (DEBUG) System.out.println("Looking for a FUNCTION");

         // A function must have a function name, followed by an open parenthesis
         tokenize(FNAME);
         tokenize(OPENPAR);

         // The function's parameter list can be either a range of cells, or a comma-separated list
         // of expressions (formulas)
         boolean foundRange = false;
         try{
            tokenize(CELLID);
            try{ tokenize(RANGE); }
            catch (InterpreterEvent evt){
               // Need to pop the tokenized CELLID from above off the tokens list so that PARAMS
               // tokenization will work
               popToken(true);
               throw new SyntagmaMismatch();
            }
            try { tokenize(CELLID); }
            catch (EndFormula evt){ throw new SyntaxError(); }
            catch (SyntagmaMismatch evt) { throw new SyntaxError(); }
            foundRange = true;
         }
         catch (SyntagmaMismatch evt){
            if (DEBUG) _depth = localDepth;
            tokenize(PARAMS);
         }

         // A function must have a closing parenthesis after the range or param list
         tokenize(CLOSEPAR);

         // If a range was found, we need to replace the range with a comma separated list of
         // the cellIDs that the range includes, and check each of these implicit cellIDs for
         // circular references.
         if (foundRange){
            if (DEBUG) System.out.println("Found a range. Replacing with parameter values.");
            replaceRange();
         }

         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(PARAMS)){
         if (DEBUG) System.out.println("Looking for PARAMS");

         // PARAMS represents a list of parameters to a function. Each of these parameters can be
         // a FORMULA on their own, each being separated by a comma. Each function must have at
         // least one parameter.
         try { tokenize(FORMULA); }
         catch (EndFormulaComma end) {}
         try{
            tokenize(COMMA);
            try{ tokenize(PARAMS); }
            catch (EndFormula err)       { throw new SyntaxError(); }
            catch (SyntagmaMismatch evt) { throw new SyntaxError(); }
         }
         catch (EndFormula evt){ if (DEBUG) _depth = localDepth; }

         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(RANGE)){
         if (DEBUG) System.out.println("Looking for a RANGE");
         readCharLeaf(RANGE);
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(COMMA)){
         if (DEBUG) System.out.println("Looking for a COMMA");
         readCharLeaf(COMMA);
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(FNAME)){
         if (DEBUG) System.out.println("Looking for a Function Name");

         //a function name is a string of characters matching any of the strings in FNAMES[]
         readLeaf();
         boolean valid = false;
         for (int ii=0; ii<FNAMES.length; ii++){
            if (_leaf.equals(FNAMES[ii])){
               valid = true;
               break;
            }
         }
         if (valid){
            updateFormula();
            addToken(new Token(Token.FUNCTION,_leaf));
         }
         else
            throw new SyntagmaMismatch();

         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(NUMBER)) {

         if (DEBUG) System.out.println("Looking for a NUMBER");

         readLeaf();
         try { Double value = NumberUtilities.parse(_leaf); }
         catch (NumberFormatException ex) {
            // check if _leaf is a boolean
            if (!(_leaf.equals(BTRUE) || _leaf.equals(BFALSE)))
               throw new SyntagmaMismatch();
         }
         catch (ParseException ex) {
                if (!(_leaf.equals(BTRUE) || _leaf.equals(BFALSE)))
                throw new SyntagmaMismatch();
         }

         updateFormula();
         addToken(new Token(Token.NUMBER,_leaf));

         if (DEBUG) { _depth--; }
         return;
      }

      if (syntagma.equals(CELLID)) {

/*** SNIP ***/

         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(UNARY_OP)) {
         if (DEBUG) System.out.println("Looking for Unary Operator");
         readUnaryOp();
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(OPERATOR)) {
         if (DEBUG) System.out.println("Looking for OPERATOR");
         readOperator();
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(OPENPAR)) {
         if (DEBUG) System.out.println("Looking for an OPENPAR");
         readCharLeaf(OPENPAR);
         if (DEBUG) _depth--;
         return;
      }

      if (syntagma.equals(CLOSEPAR)) {
         if (DEBUG) System.out.println("Looking for a CLOSEPAR");
         readCharLeaf(CLOSEPAR);
         if (DEBUG) _depth--;
         return;
      }

      // Should never be reached
      throw new SyntaxError();
   }

/*** SNIP ***/

   /**
    * Returns true if a circular reference is detected among the specified cell's listenees, meaning
    * that the cell has its own value as one of its dependencies, which is not allowed.
    * @param checkCell The cell object whose dependencies will be checked for circular references.
    * @param currCell  The current cell object being compared against the check cell.
    */
   private boolean checkCircularReference(SheetCellModel checkCell, SheetCellModel currCell){
      Vector listenees = currCell.getListenees();
      if (listenees.contains(checkCell)){
         return true;
      }
      if (currCell != checkCell && checkCircularReference(currCell,currCell)) {
        return true;
      }

      //now check each of the listenees' listenees
      for (int ii=0; ii<listenees.size(); ii++){
         if (checkCircularReference(checkCell,(SheetCellModel) listenees.get(ii))){
            return true;
         }
      }
      return false;
   }

   /**
    * Read a single word on the left of the
    * unevaluated part of the formula and store
    * it into _leaf
    */
   private void readLeaf() throws EndFormula {
     if (_formula.length()==0){
        if(DEBUG) System.out.println("readLeaf(): End Of Formula");
        throw new EndFormulaNormal();
     }

     boolean searching = true;
     char []       buf = _formula.toCharArray();

     int ii = 0;

     // If we have a negative number, then the minus sign is the first character, and a digit is the
     // next character. Check if _formula starts with a negative number and if so, skip to the
     // third character and continue as normal below.
     if (buf.length >= 2)
        if (buf[0] == '-' && Character.isDigit(buf[1]))
           ii = 2;

     search: while (searching && ii<buf.length) {
        for (int jj=0; jj<SEPARATORS.length; jj++) {
           if (buf[ii] == SEPARATORS[jj]) {
              searching = false;
              _leaf     = _formula.substring(0,ii);
              continue search;
           }
        }
        ii++;
     }
     if (searching){
        _leaf = _formula;
     }

     if (DEBUG) System.out.println("readLeaf: " + _leaf);
     return;
   }

   // Reads any unary operator from the _formula string
   private void readUnaryOp() throws SyntagmaMismatch, EndFormula {
      if (_formula.length()==0){
         if (DEBUG) System.out.println("readUnaryOp(): End Of Formula");
         throw new EndFormulaNormal();
      }

      for (int ii=0; ii<UNARY_OPS.length; ii++){
         if (_formula.substring(0,1).equals(UNARY_OPS[ii])){
            _leaf = _formula.substring(0,1);
            updateFormula();
            addToken(new Token(Token.OPERATOR,_leaf,true));
            if (DEBUG) System.out.println("readUnaryOp: " + _leaf);
            return;
         }
      }

      // No operator matched. Check if end of formula has been reached.
      if (_formula.substring(0,1).equals(CLOSEPAR)){
         if (DEBUG) System.out.println("readUnaryOp(): End Of Formula by closepar");
         throw new EndFormulaNormal();
      }
      if (_formula.substring(0,1).equals(COMMA)){
         if (DEBUG) System.out.println("readUnaryOp(): End Of Formula by Comma");
         throw new EndFormulaComma();
      }
      throw new SyntagmaMismatch();
   }

   // Reads any binary operator string from the _formula
   private void readOperator() throws SyntagmaMismatch, EndFormula {
      if (_formula.length()==0){
         if (DEBUG) System.out.println("readOperator(): End Of Formula");
         throw new EndFormulaNormal();
      }

      // to handle the two-character operators, they are listed first in the OPERATORS array,
      // so it will match them first and avoid matching a < to <= in the _formula for example.
      for (int ii=0; ii<OPERATORS.length; ii++){
         if (_formula.length() >= OPERATORS[ii].length()){
            if (_formula.substring(0,OPERATORS[ii].length()).equals(OPERATORS[ii])){
               _leaf = _formula.substring(0,OPERATORS[ii].length());
               updateFormula();
               addToken(new Token(Token.OPERATOR,_leaf,false));
               if (DEBUG) System.out.println("readOperator: " + _leaf);
               return;
            }
         }
      }

      // No operator matched. Check if end of formula has been reached.
      if (_formula.substring(0,1).equals(CLOSEPAR)){
         if (DEBUG) System.out.println("readOperator(): End Of Formula by closepar");
         throw new EndFormulaNormal();
      }
      if (_formula.substring(0,1).equals(COMMA)){
         if (DEBUG) System.out.println("readOperator(): End Of Formula by Comma");
         throw new EndFormulaComma();
      }
      throw new SyntagmaMismatch();
   }

   // Reads a specified character from the _formula
   private void readCharLeaf(String c) throws SyntagmaMismatch, EndFormula {
     if (_formula.length()==0) {
        if(DEBUG) System.out.println("readCharLeaf(): End Of Formula");
        throw new EndFormulaNormal();
     }
     if (_formula.substring(0,1).equals(c)) {
        _leaf = _formula.substring(0,1);
        updateFormula();

        //only four characters are currently read using readCharLeaf()
        if (_leaf.equals(OPENPAR))
           addToken(new Token(Token.OPENPAR,_leaf));
        else if (_leaf.equals(CLOSEPAR))
           addToken(new Token(Token.CLOSEPAR,_leaf));
        else if (_leaf.equals(RANGE))
           addToken(new Token(Token.RANGE,_leaf));
        else
           addToken(new Token(Token.COMMA,_leaf));
     }
     else {
        // The end of a formula is reached when it is looking for another
        // operator and instead finds either a close parenthesis (ending a parenthesized expression)
        // or a comma (ending an expression (formula) in a parameter list)
        if (_formula.substring(0,1).equals(CLOSEPAR)){
           if (DEBUG) System.out.println("readCharLear(): End Of Formula by closepar");
           throw new EndFormulaNormal();
        }
        if (_formula.substring(0,1).equals(COMMA)){
           if (DEBUG) System.out.println("readCharLeaf(): End Of Formula by Comma");
           throw new EndFormulaComma();
        }
        throw new SyntagmaMismatch();
     }

     if (DEBUG) System.out.println("readCharLeaf: " + _leaf);
     return;
   }

   // Remove _leaf from _formula
   private void updateFormula() {
      _buffer  = _buffer.delete(0, _leaf.length());
      _formula = _buffer.toString().trim();
      if (DEBUG) System.out.println("_formula: " + _formula);
   }

   // adds a token to the token list
   private void addToken(Token token) {
      // if token is a parenthesis, keep track of matching parentheses
      if (token.type == Token.OPENPAR){
         _parCount++;
         _parStack.push(new Integer(_parCount));
         token.setParID(_parCount);
      }
      else if (token.type == Token.CLOSEPAR){
         token.setParID(((Integer) _parStack.pop()).intValue());
      }
      _tokens.add(token);

      if (DEBUG) System.out.println("_tokens: " + printTokens(_tokens));
   }

/*** SNIP ***/

   // Pops the most recent token off of the list, and puts the token's value back in the front of
   // _formula, which essentially undoes the last successful tokenize operation.
   private Token popToken(boolean updateFormula){
      Token token;
      try{ token = (Token) _tokens.remove(_tokens.size()-1); }
      catch (IndexOutOfBoundsException e) { return null; }
      if (updateFormula){
         _formula = token.value + _formula;
         _buffer.insert(0,token.value);
      }
      
      // Check if we need to update the parentheses stack (currently only closing parentheses are 
      // popped off, and only by replaceRange())
      if (token.type == Token.CLOSEPAR){
         _parStack.push(new Integer(_parCount));
      }

      if (DEBUG){
         System.out.println("pop token: " + token.toString());
         System.out.println("_tokens: " + printTokens(_tokens));
         System.out.println("_formula: " + _formula);
      }
      return token;
   }

   /**
    * Recursively computes the value of a list of tokens, using specified operator precedence
    * levels.
    * @param tokenList A List of Token objects representing the formula to be computed
    */
   private String rcompute(List tokenList) throws SyntaxError {
      String strTokenList;   // the string version of the token list (for debugging)
      String res;            // the result of the current tokenList
      int listSize;          // the size of the current list of tokens
      Token first;           // the first token in the list
      Token second;          // the second token in the list (used for functions)
      Token last;            // the last token in the list
      int opIndex;           // the index of the operator in the token list to be computed
      Token currToken;       // the current token while looking for the lowest precedence operator
      byte minPrecedence;    // the lowest precedence operator found in the token list
      int parCount;          // counts nested levels of parenthesized expressions

      if (DEBUG){
         strTokenList = printTokens(tokenList);
         System.out.println("Computing: " + strTokenList);
      }

      listSize = tokenList.size();

      // if we are down to a single token, just return that token's value
      if (listSize == 1){
         Token token = (Token) tokenList.get(0);
         switch (token.type){
            case Token.NUMBER: return token.value;
            case Token.CELLID: return token.cellVal;
            default:           throw new SyntaxError();
         }
      }

      // if the list is a parenthesized expression, compute the contents of the expression
      first = (Token) tokenList.get(0);
      last  = (Token) tokenList.get(listSize-1);
      if (first.parMatches(last)){
         res = rcompute(tokenList.subList(1,listSize-1));
         if (DEBUG) System.out.println("Result of " + strTokenList + ": " + res);
         return res;
      }

      // if the list is down to just a function call, evaluate the function
      second = (Token) tokenList.get(1);
      if (first.type == Token.FUNCTION && second.parMatches(last)){
         FuncEvaluator evaluator = new FuncEvaluator(first.value);
         res = evaluator.eval(tokenList.subList(2,listSize-1));
         if (DEBUG) System.out.println("Result of " + strTokenList + ": " + res);
         return res;
      }

      // Look for lowest precedence operator from right to left that is not inside parentheses. Then
      // rcompute the left operand, rcompute the right operand, and run the operator on the results.
      // This implements operator precedence. For operators with the same precedence, they are computed
      // left to right. Parethesized expressions are computed earlier also.
      minPrecedence = Token.MAX_PRECEDENCE + 1;
      opIndex = -1;
      parCount = 0;
      for (int ii=(listSize-1); ii>=0; ii--){
         currToken = (Token) tokenList.get(ii);

         // keep track of parentheses levels. Only look for operators in the top level (parCount = 0)
         if (currToken.type == Token.CLOSEPAR)
            parCount++;
         else if (currToken.type == Token.OPENPAR)
            parCount--;
         if (parCount > 0)
            continue;

         if (currToken.type == Token.OPERATOR){

            // if we have found a lowest-precedence operator (all of which are binary), compute the 
            // operands, compute the expression, and return
            if (currToken.precedence == Token.MIN_PRECEDENCE){
               res = computeBinOp(currToken.value,
                                  rcompute(tokenList.subList(0,ii)),
                                  rcompute(tokenList.subList(ii+1,listSize)));
               if (DEBUG) System.out.println("Result of " + strTokenList + ": " + res);
               return res;
            }

            // keep track of the smallest precedence operator and its location in the list
            if (currToken.precedence < minPrecedence){
               minPrecedence = currToken.precedence;
               opIndex = ii;
            }
         }
      } // end for

      // the operator at opIndex is the last lowest-precedence operator. Compute its operands and
      // then compute the expression and return
      currToken = (Token) tokenList.get(opIndex);
      if (currToken.isUnary)
         res = computeUnaryOp(currToken.value,rcompute(tokenList.subList(opIndex+1,listSize)));
      else
         res = computeBinOp(currToken.value,
                            rcompute(tokenList.subList(0,opIndex)),
                            rcompute(tokenList.subList(opIndex+1,listSize)));
      if (DEBUG) System.out.println("Result of " + strTokenList + ": " + res);
      return res;
   }

   // computes the value of a unary expression given the operator and the right operand as strings.
   private String computeUnaryOp(String op, String strRight) throws SyntaxError {
      double  right;            // numeric value of right operand

      // convert from strings to proper types
      if (strRight.equals(BTRUE))
         right = NTRUE;
      else if (strRight.equals(BFALSE))
         right = NFALSE;
      else
         try{
            right = Double.parseDouble(strRight);
         }
         catch (NumberFormatException e) { throw new SyntaxError(); }

      // perform the operation
      if (op.equals(POS)) return NumberUtilities.format(right);
      if (op.equals(NEG)) return NumberUtilities.format(-right);

      // shouldn't get to here
      return null;
   }

   // computes the value of a binary expression given the operator and the left/right operands as strings.
   // all binary operations return the result in decimal format
   private String computeBinOp(String op, String strLeft, String strRight) throws SyntaxError {
      boolean boolLeft;         // the boolean value of the left argument (if applicable)
      boolean boolRight;        // the boolean value of the right argument (if applicable)
      double  left;             // numeric value of left operand
      double  right;            // numeric value of right operand

      // convert from strings to proper types
      if (strLeft.equals(BTRUE)){
         boolLeft = true;
         left = NTRUE;
      }
      else if (strLeft.equals(BFALSE)){
         boolLeft = false;
         left = NFALSE;
      }
      else{
         try{
            // use NumberUtilities to ensure currencies are handled properly
            left = NumberUtilities.parse(strLeft).doubleValue();
            boolLeft = (left != NFALSE);
         }
         catch (NumberFormatException e) { throw new SyntaxError(); }
         catch (ParseException e) { throw new SyntaxError(); }
      }
      if (strRight.equals(BTRUE)){
         boolRight = true;
         right = NTRUE;
      }
      else if (strRight.equals(BFALSE)){
         boolRight = false;
         right = NFALSE;
      }
      else{
         try{
            // use NumberUtilities to ensure currencies are handled properly
            right = NumberUtilities.parse(strRight).doubleValue();
            boolRight = (right != NFALSE);
         }
         catch (NumberFormatException e) { throw new SyntaxError(); }
         catch (ParseException e) { throw new SyntaxError(); }
      }

      // perform the operations
      // since the result is always in decimal format, use NumberUtilities.format
      if (op.equals(EXPONENT))  return NumberUtilities.format(Math.pow(left,right));
      if (op.equals(MULTIPLY))  return NumberUtilities.format(left * right);
      if (op.equals(DIVIDE)){
         try{
            return NumberUtilities.format(left / right);
         }
         catch (ArithmeticException e) { throw new SyntaxError(); }
      }
      if (op.equals(ADD))       return NumberUtilities.format(left + right);
      if (op.equals(SUBTRACT))  return NumberUtilities.format(left - right);
      if (op.equals(LT)){
         if (left < right) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(LTEQ)){
         if (left <= right) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(GT)){
         if (left > right) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(GTEQ)){
         if (left >= right) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(EQ)){
         if (left == right) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(AND)){
         if (boolLeft && boolRight) return BTRUE;
         else return BFALSE;
      }
      if (op.equals(OR)){
         if (boolLeft || boolRight) return BTRUE;
         else return BFALSE;
      }

      // shouldn't get to here
      return null;
   }

   // This class represents a token object. It contains information useful during the computation
   // of the cell's formula
   private class Token {
      // these represent the types of tokens there can be
      public static final byte NUMBER   = 1;
      public static final byte CELLID   = 2;
      public static final byte OPERATOR = 3;
      public static final byte FUNCTION = 4;
      public static final byte OPENPAR  = 5;
      public static final byte CLOSEPAR = 6;
      public static final byte RANGE    = 7;
      public static final byte COMMA    = 8;

      public byte   type;         // the type of the token
      public String value;        // the string value of the token

      /** the level of the precedence of this token (if type==operator). Lower value means lower
       *  precedence. The precedence levels are as follows:
       *  6 {+,- unary ops}
       *  5 {^}
       *  4 {*,/}
       *  3 {+,-}
       *  2 {<,<=,>,>=,=}
       *  1 {&,|}
       */
      public static final byte MIN_PRECEDENCE = 1;
      public static final byte MAX_PRECEDENCE = 6;

      // only used if type == OPERATOR
      public byte    precedence;
      public boolean isUnary;

/*** SNIP ***/

      // used if type == OPENPAR or type == CLOSEPAR
      public int    parID;       // matching pairs of parentheses will have the same parID

      // general constructor
      Token(byte type, String value){
         this.type = type;
         this.value = value;
      }

      // constructor called when creating an operator token
      Token(byte type, String value, boolean isUnary){
         this(type,value);

         // set the operator precedence
         if (isUnary){
            precedence = 6;
            this.isUnary = true;
         }
         else{
            this.isUnary = false;
            if (value.equals(AND) || value.equals(OR))
               precedence = 1;
            else if (value.startsWith(LT) || value.startsWith(GT) || value.startsWith(EQ))
               precedence = 2;
            else if (value.equals(ADD) || value.equals(SUBTRACT))
               precedence = 3;
            else if (value.equals(MULTIPLY) || value.equals(DIVIDE))
               precedence = 4;
            else
               precedence = 5;
         }
      }

      // constructor called when creating a cellID token
      Token(byte type, String value, String cellVal, int r, int c){
         this(type,value);
         this.cellVal = cellVal;
         cellRow = r;
         cellCol = c;
      }

/*** SNIP ***/

      // sets the parID, which identifies pairs of parentheses
      public void setParID(int parID){
         this.parID = parID;
      }

      // returns true if both this token and the specified one are parentheses and they are a
      // matching pair, false otherwise.
      public boolean parMatches(Token token){
         if (!(type == OPENPAR || type == CLOSEPAR) ||
             !(token.type == OPENPAR || token.type == CLOSEPAR))
            return false;
         if (parID == token.parID)
            return true;
         else
            return false;
      }
   }

   // This class encapsulates the process of evaluating a function based on a list of tokens
   // representing the parameters to the function. The type of function (ADD, PRODUCT, etc) is
   // specified when creating a new instance. This class calls rcompute() of the containing class
   // to complete the evaluation. The code here mainly handles properly splitting up the
   // parameter list and implementing each of the pre-defined functions available in the spreadsheet
   // tool.
   private class FuncEvaluator {
      // these function types should correspond to Interpreter's FNAMES member (value = 1 + index)
      // in other words, these should be listed in same order as FNAMES is listed.
      private static final byte ADD     = 1;
      private static final byte SUM     = 2;
      private static final byte PRODUCT = 3;
      private static final byte IF      = 4;

/*** SNIP ***/

      private byte function;  // the specific function this instance represents

      FuncEvaluator(String funcType){
         for (byte ii=0; ii<FNAMES.length; ii++){
            if (funcType.equals(FNAMES[ii])){
               function = (byte) (ii + 1);
               break;
            }
         }
      }

      // Evaluates the function with the given list of parameters (each element of the list is a
      // Token object).
      public String eval(List paramTokens) throws SyntaxError {
         List params = new ArrayList(); // this list holds sublists, each of which is a parameter
                                        // that needs to be computed before evaluating the function

         if (DEBUG) System.out.println("Evaluating " + function);

         // parse out the individual parameters from the tokens (separated by commas, being careful
         // to recognize other function calls within the parameter list)
         List currParam = new ArrayList(); // the current parameter being parsed from the token list
         int inPar = 0;                    // counts levels of nested parentheses within the parameter list
         for (int ii=0; ii<paramTokens.size(); ii++){
            Token token = (Token) paramTokens.get(ii);

            // at end of current parameter or found a comma within another function call
            if (token.type == Token.COMMA){
               if (inPar > 0)
                  currParam.add(token);
               else{
                  params.add(new ArrayList(currParam));
                  currParam.clear();
               }
            }
            // add token to current parameter (noting any parens)
            else{
               currParam.add(token);
               if (token.type == Token.OPENPAR)
                  inPar++;
               else if (token.type == Token.CLOSEPAR)
                  inPar--;
            }
         } // end for
         if (!currParam.isEmpty())
            params.add(new ArrayList(currParam));

         // now check for proper parameter list sizes based on the type of function
         if (!checkParamCount(params.size())) throw new SyntaxError();

         // compute the value of each of the parameters
         for (int ii=0; ii<params.size(); ii++){
            params.set(ii,rcompute((List) params.get(ii)));
         }

         // compute the function with the parameter values (located in params as strings)
         return computeFunction(params);
      }

      // computes this function with the specified parameters and returns the result as a string
      private String computeFunction(List params) throws SyntaxError {
         // translate String parameter values to floats
         double[] doubleParams = new double[params.size()];
         for (int ii=0; ii<params.size(); ii++){
            String strParam = (String) params.get(ii);
            if (strParam.equals(BTRUE))
               doubleParams[ii] = NTRUE;
            else if (strParam.equals(BFALSE))
               doubleParams[ii] = NFALSE;
            else
               try{
                  doubleParams[ii] = NumberUtilities.parse(strParam).doubleValue();
               }
               catch (NumberFormatException e) { throw new SyntaxError(); }
               catch (ParseException e) { throw new SyntaxError(); }
         }

         // compute the result of the function
         double res = 0;

/*** SNIP ***/

         boolean currency = false;  //used to determine if the result should be displayed as currency

         switch (function){
            case ADD:
               res = doubleParams[0] + doubleParams[1];
               break;

            case SUM:
               for (int ii=0; ii<doubleParams.length; ii++)
                  res += doubleParams[ii];
               break;

            case PRODUCT:
               res = doubleParams[0];
               for (int ii=1; ii<doubleParams.length; ii++)
                 res *= doubleParams[ii];
               break;

            case IF:
               // IF is a special case where we will simply return either the second or third
               // parameter in its original string form b/c they are not involved in a computation
               if (doubleParams[0] != NFALSE)
                  return (String) params.get(1);
               else
                  return (String) params.get(2);
/*** SNIP ***/

         }

         //return the value as a String
         String result = Double.toString(res);
         if (currency) {
                result = "$" + result;
         }
         return result;
      }

      // returns true if the given number of parameters is valid for this function, false otherwise
      private boolean checkParamCount(int paramCount){

/*** SNIP ***/

      }
   }
}
