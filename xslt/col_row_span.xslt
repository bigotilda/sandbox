<?xml version="1.0" encoding="UTF-8"?>

<!-- This is a portion of an XSLT from a proprietary project that attempts to properly deal with rowspan and colspan values
     in table cells. There may certainly be better ways to do this, but I had fun figuring this out on my own. -->

<!--
 These namespaces are designed to provide universally unique names for elements and attributes
 They also provide extension functions, such as <redirect>, which are used for processing
-->
<xsl:stylesheet version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:xalan="http://xml.apache.org/xslt"
  xmlns:user="http://cops.gleim.com/it/products/udb"
  xmlns:java="http://xml.apache.org/xslt/java"
  xmlns:mysql="http://cops.gleim.com/it/products/udb/mysql"
  xmlns:redirect="org.apache.xalan.xslt.extensions.Redirect"
  xmlns:math="http://www.w3.org/1998/Math/MathML"
  extension-element-prefixes="user mysql redirect">

  <!-- SNIP -->
  <!-- . --> 
  <!-- . -->
  <!-- . -->
  <!-- /SNIP -->

  <!-- Maximum number of cells in a table that we can process here. Experimentation on 2013.05.08 lead to this value -->
  <xsl:variable name="MAX_TABLE_CELLS" select="704"/>
  
  <!-- Returns the logical column position for $node, taking rowspans and colspans into account.
       Calls rget-cell-location() with the proper initial values and context node; also verifies that the node is the
       correct type (listed in $cell-element-list), and that the proper containing table is searched. Returns the
       logical normalized column that this node would start in (counting columns numerically from left to right, starting at 1). -->
  <xsl:template name="get-col-num">
    <xsl:param name="node"/>

    <xsl:if test="contains($cell-element-list,concat(local-name($node),','))">
      <xsl:variable name="cell-location">
        <!-- we need to start with the first cell node of the table/foil/answer-header that contains $node -->
        <xsl:for-each select="$node/parent::*[contains($row-element-list,concat(local-name(),','))]/parent::*/
                              child::*[contains($row-element-list,concat(local-name(),','))][1]/
                              child::*[contains($cell-element-list,concat(local-name(),','))][1]">
          <xsl:call-template name="rget-cell-location">
            <xsl:with-param name="stop-node-id" select="generate-id($node)"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="substring-before(substring-after($cell-location,','),')')"/>
    </xsl:if>
  </xsl:template>

  <!-- Recursively builds a normalized representation of the current table (normalized means expanding the rowspan
       and colspan values out, figuring out what logical cell locations are taken up by which nodes), and returns
       the normalized, logical cell location that the node represented by $stop-node-id would START in, meaning that if
       the node would span multiple columns, rows, or both, the cell location returned is the leftmost, topmost logical
       location in the span. The location is returned as a string in the format "([row],[col])" where [row] is the
       numerical row number, and [col] is the numerical column number, both counting up from 1 from the top and left, 
       respectively. The searching stops once it figures out the logical location for the specified node, and returns the
       corresponding cell location (or topmost and leftmost cell if a span is involved).
       
       The context node during the first execution should be the first node (topmost, leftmost) of the table that
       contains the target $stop-node-id node. The rest of the table is then recursively processed, moving the context
       node along during the recursion until it finds the cell location for the target node. You must start the search
       with the first node of the containing table because in order to determine the normalized table in all situations,
       the normalized table must be built cell-by-cell incrementally, starting from the first column of the first row.
       This ensures that all rowspans and colspans of previously processed nodes are properly accounted for by the time
       you get to a specific location.

       Additionally, if in validation mode, if the table is detected as being invalid or malformed, meaning that there
       are too many or too few nodes for a given row (based on rowspan/colspan and the number of columns in the table),
       the process will stop at either the first invalid node detected, or at the cell location of the target node,
       whichever is found first, and will return the corresponding cell location. If it's an invalid node, the location
       is followed by an '*' (e.g. "(1,3)*" would indicate an invalid cell was found at row 1, column 3). Therefore to
       validate an entire table, the node in the last column of the last row should be the target node.

       $nNormRow: the current logical row we are working with (outside callers should not set this)
       $nNormCol: the current logical column we are working with (outside callers should not set this)
       $sCells: string representing the list of already-determined logical locations that have been taken up by
                the nodes that have already been processed (outside callers should not set this)
       $stop-node-id: the unique id of the node whose logical column we are searching for (target node), as generated by
                      the generate-id() function (provided by caller)
       $bValidate: (optional) flag indicating if validation should take place, meaning the code will check for each
                   node being in a valid logical cell location and will check for missing nodes as well. If this is set,
                   the template will return either the target cell location, or the first invalid cell location it finds,
                   whichever comes first (from left to right, top to bottom). An invalid cell location is signified by
                   a cell location in the normal format followed by '*'.
       $nTotalCols: (optional) the total number of logical columns this table/answer-header has, meaning the number of
                    <col> elements in the <colgroup> child of this table/answer-header (provided by caller). This only 
                    needs to be set when $bValidate is true. This column count is used to validate the table and return
                    an error condition when a misplaced cell is found (or when a cell is detected as missing). -->
  <xsl:template name="rget-cell-location">
    <xsl:param name="nNormRow" select="1"/>
    <xsl:param name="nNormCol" select="1"/>
    <xsl:param name="sCells" select="''"/>
    <xsl:param name="stop-node-id"/>
    <xsl:param name="bValidate" select="false()"/>
    <xsl:param name="nTotalCols" select="0"/>

    <xsl:variable name="sCell" select="concat('(', $nNormRow, ',', $nNormCol, ')')"/>

    <xsl:choose>
      <!-- TODO: rewrite to be more iterative and less recursive (if possible) to address below problem with large
                 tables. -->
      <!-- If tables are very large, this algorithm will run out of stack space because it will end up recursing too 
           deeply for Java, and it spits out a stackOverFlow error and dies. If the number of cells in this table
           is greater than $MAX_TABLE_CELLS, then spit out a warning (if validating) and do a naive cell-location
           computation that does not take rowspan/colspan into account. Only do this check when first entering this
           template (we don't want to run this check each time the template calls itself recursively), which is when
           $sCells is still blank. -->
      <xsl:when test="$sCells = '' and
                      count(ancestor::table[1]/descendant::*[contains($cell-element-list,concat(local-name(),','))]) &gt; $MAX_TABLE_CELLS">
        <!-- only print WARNING if we're validating, because otherwise we'll print out this warning for each cell that 
             is processed by processNodes*.xslt -->
        <xsl:if test="$bValidate">
          <xsl:message>[WARNING] TABLE is too large to validate properly (&gt; <xsl:value-of select="$MAX_TABLE_CELLS"/> cells)!</xsl:message>
        </xsl:if>
        <!-- Naive method of determing row/col location is just count preceding-sibling rows and preceding-sibling cells of the
             target node. This will not properly handle any @rowspan/@colspan attributes. -->
        <xsl:for-each select="ancestor::table[1]/descendant::*[generate-id() = $stop-node-id][1]">
          <xsl:variable name="row" select="count(parent::*/preceding-sibling::*[contains($row-element-list,concat(local-name(),','))]) + 1"/>
          <xsl:variable name="col" select="count(preceding-sibling::*[contains($cell-element-list,concat(local-name,','))]) + 1"/>
          <xsl:value-of select="concat('(', $row, ',', $col, ')')"/>
        </xsl:for-each>
      </xsl:when>
      
    
      <!-- if this normalized cell location has already been used via a previous row/col span, just try again on
           the next logical cell location in the row, keeping the same context node -->
      <xsl:when test="contains($sCells, $sCell)">
        <xsl:call-template name="rget-cell-location">
          <xsl:with-param name="nNormRow" select="$nNormRow"/>
          <xsl:with-param name="nNormCol" select="$nNormCol + 1"/>
          <xsl:with-param name="sCells" select="$sCells"/>
          <xsl:with-param name="stop-node-id" select="$stop-node-id"/>
          <xsl:with-param name="bValidate" select="$bValidate"/>
          <xsl:with-param name="nTotalCols" select="$nTotalCols"/>
        </xsl:call-template>
      </xsl:when>

      <!-- Now we're at a new, unassigned cell location. If we're validating and this location is invalid, return
           the location along with invalid flag ('*' character appended to cell location).
              -otherwise-
           if this is the target node whose column we are searching for, just return the normalized current cell 
           location
              -otherwise-
           this cell is valid, but is not for the target node, so add it to the list, and add in any extra span cells
           taken up by this node via @rowspan/@colspan, if applicable, then move to the next node -->
      <xsl:otherwise>

        <!-- If we're validating and we're at the last node in a row, count the cells that have been assigned
             to this row. If the count does not equal the number of table columns, then we know we have an invalid
             cell location. -->
        <xsl:variable name="nCellsInRow">
          <xsl:if test="$bValidate and not(following-sibling::*[contains($cell-element-list,concat(local-name(),','))])">
            <xsl:variable name="nAlreadyAssignedCells">
              <xsl:call-template name="rget-row-cell-count">
                <xsl:with-param name="nRow" select="$nNormRow"/>
                <xsl:with-param name="sCells" select="$sCells"/>
              </xsl:call-template>
            </xsl:variable>
            <!-- count is 1 (for the current node), plus any colspan values of current node, plus any already assigned
                 cells in this row -->
            <xsl:choose>
              <xsl:when test="@colspan">
                <xsl:value-of select="1 + (@colspan - 1) + number($nAlreadyAssignedCells)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="1 + number($nAlreadyAssignedCells)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:variable>

        <xsl:choose>
          <!-- $nCellsInRow will be set if we're validating and on the last node in the row. If the number of cells
               assigned for this row do not equal the total table columns, this is an invalid location. -->
          <xsl:when test="number($nCellsInRow) and
                          number($nCellsInRow) != $nTotalCols">
            <xsl:value-of select="concat($sCell,'*')"/>
          </xsl:when>

          <!-- we've reached the location where the target node would be placed in the normalized table, so 
               return this cell location -->
          <xsl:when test="generate-id() = $stop-node-id">
            <xsl:value-of select="$sCell"/>
          </xsl:when>

          <!-- we need to continue generating the normalized table cells, since we haven't gotten to the target node
               yet -->
          <xsl:otherwise>
            <!-- this variable contains this cell location and any additional span cell locations specified by this
                 node -->
            <xsl:variable name="sSpanCells">
              <xsl:choose>
                <xsl:when test="(@rowspan > 1) and (@colspan > 1)">
                  <xsl:call-template name="rgen-span-cells">
                    <xsl:with-param name="nCurrRow" select="$nNormRow"/>
                    <xsl:with-param name="nRowSpan" select="@rowspan"/>
                    <xsl:with-param name="nCurrCol" select="$nNormCol"/>
                    <xsl:with-param name="nColSpan" select="@colspan"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="@rowspan > 1">
                  <xsl:call-template name="rgen-span-cells">
                    <xsl:with-param name="nCurrRow" select="$nNormRow"/>
                    <xsl:with-param name="nRowSpan" select="@rowspan"/>
                    <xsl:with-param name="nCurrCol" select="$nNormCol"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="@colspan > 1">
                  <xsl:call-template name="rgen-span-cells">
                    <xsl:with-param name="nCurrRow" select="$nNormRow"/>
                    <xsl:with-param name="nCurrCol" select="$nNormCol"/>
                    <xsl:with-param name="nColSpan" select="@colspan"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$sCell"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <!-- Either move on to the next sibling node, or the next row of the input table. We should not ever move
                 past the end of the table, since at some point the $stop-node-id will have been matched. -->
            <xsl:choose>
              <!-- there are some more nodes in this row -->
              <xsl:when test="following-sibling::*[contains($cell-element-list,concat(local-name(),','))]">
                <xsl:variable name="nNewNormCol">
                  <xsl:choose>
                    <xsl:when test="@colspan > 1"><xsl:value-of select="$nNormCol + @colspan"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="$nNormCol + 1"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:for-each select="following-sibling::*[contains($cell-element-list,concat(local-name(),','))][1]">
                  <xsl:call-template name="rget-cell-location">
                    <xsl:with-param name="nNormRow" select="$nNormRow"/>
                    <xsl:with-param name="nNormCol" select="$nNewNormCol"/>
                    <xsl:with-param name="sCells" select="concat($sCells,string($sSpanCells))"/>
                    <xsl:with-param name="stop-node-id" select="$stop-node-id"/>
                    <xsl:with-param name="bValidate" select="$bValidate"/>
                    <xsl:with-param name="nTotalCols" select="$nTotalCols"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:when>
              <!-- there are some more rows in the table -->
              <xsl:when test="parent::*[contains($row-element-list,concat(local-name(),','))]/
                              following-sibling::*[contains($row-element-list,concat(local-name(),','))]/
                              *[contains($cell-element-list,concat(local-name(),','))]">
                <xsl:for-each select="parent::*[contains($row-element-list,concat(local-name(),','))]/
                                      following-sibling::*[contains($row-element-list,concat(local-name(),','))][1]/
                                      *[contains($cell-element-list,concat(local-name(),','))][1]">
                  <xsl:call-template name="rget-cell-location">
                    <xsl:with-param name="nNormRow" select="$nNormRow + 1"/>
                    <xsl:with-param name="nNormCol" select="1"/>
                    <xsl:with-param name="sCells" select="concat($sCells,string($sSpanCells))"/>
                    <xsl:with-param name="stop-node-id" select="$stop-node-id"/>
                    <xsl:with-param name="bValidate" select="$bValidate"/>
                    <xsl:with-param name="nTotalCols" select="$nTotalCols"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:when>
              <!-- Have a default value here just in case we some how go through the table without matching
                   $stop-node-id. Just return the current cell location. -->
              <xsl:otherwise>
                <xsl:value-of select="$sCell"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Recursively builds a normalized representation of the current node's logical cell and any cells that would be
       taken up by the node's @rowspan and @colspan values. This is a helper function for rget-cell-location() -->
  <xsl:template name="rgen-span-cells">
    <xsl:param name="nCurrRow"/>
    <xsl:param name="nCurrCol"/>
    <xsl:param name="nRowSpan" select="1"/>
    <xsl:param name="nColSpan" select="1"/>

    <!-- this is the current node's starting cell location (and only cell location if no spans are set) -->
    <xsl:value-of select="concat('(', $nCurrRow, ',', $nCurrCol, ')')"/>

    <!-- process span values, if any -->
    <xsl:choose>
      <!-- if both @rowspan and @colspan are set and are greater than 1, we need a square area, so first go through
           the rest of the columns on this row (by setting rowspan to 1 so that only this row is processed), then
           increment the row counter and start again at the first column of the next row. This gets us a square area. -->
      <xsl:when test="$nRowSpan > 1 and $nColSpan > 1">
        <xsl:call-template name="rgen-span-cells">
          <xsl:with-param name="nCurrRow" select="$nCurrRow"/>
          <xsl:with-param name="nCurrCol" select="$nCurrCol + 1"/>
          <xsl:with-param name="nRowSpan" select="1"/>
          <xsl:with-param name="nColSpan" select="$nColSpan - 1"/>
        </xsl:call-template>
        <xsl:call-template name="rgen-span-cells">
          <xsl:with-param name="nCurrRow" select="$nCurrRow + 1"/>
          <xsl:with-param name="nCurrCol" select="$nCurrCol"/>
          <xsl:with-param name="nRowSpan" select="$nRowSpan - 1"/>
          <xsl:with-param name="nColSpan" select="$nColSpan"/>
        </xsl:call-template>
      </xsl:when>
      <!-- if only @rowspan is greater than 1, then keep the same column and just move on to the next row -->
      <xsl:when test="$nRowSpan > 1">
        <xsl:call-template name="rgen-span-cells">
          <xsl:with-param name="nCurrRow" select="$nCurrRow + 1"/>
          <xsl:with-param name="nCurrCol" select="$nCurrCol"/>
          <xsl:with-param name="nRowSpan" select="$nRowSpan - 1"/>
          <xsl:with-param name="nColSpan" select="$nColSpan"/>
        </xsl:call-template>
      </xsl:when>
      <!-- if only @colspan is greater than 1, then continue processing the next column of this same row -->
      <xsl:when test="$nColSpan > 1">
        <xsl:call-template name="rgen-span-cells">
          <xsl:with-param name="nCurrRow" select="$nCurrRow"/>
          <xsl:with-param name="nCurrCol" select="$nCurrCol + 1"/>
          <xsl:with-param name="nRowSpan" select="$nRowSpan"/>
          <xsl:with-param name="nColSpan" select="$nColSpan - 1"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- returns the number of cells that have been assigned to the specified $nRow at this point, by finding the
       number of cell locations in the location list ($sCells) that have $nRow as the row -->
  <xsl:template name="rget-row-cell-count">
    <xsl:param name="nRow"/>
    <xsl:param name="sCells"/>

    <xsl:variable name="sRow" select="concat('(', $nRow, ',')"/>

    <xsl:choose>
      <xsl:when test="contains($sCells,$sRow)">
        <xsl:variable name="substring-cell-count">
          <xsl:call-template name="rget-row-cell-count">
            <xsl:with-param name="nRow" select="$nRow"/>
            <xsl:with-param name="sCells" select="substring-after($sCells,$sRow)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="1 + number($substring-cell-count)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="0"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
