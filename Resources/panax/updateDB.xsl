<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:px="urn:panax" xmlns:set="http://exslt.org/sets" version="1.0" extension-element-prefixes="msxsl" exclude-result-prefixes="set">
  <xsl:output method="text" />
  <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:variable name="userId"/>
  <xsl:template name="set:distinct">
    <xsl:param name="nodes" select="/.." />
    <xsl:param name="distinct" select="/.." />
    <xsl:choose>
      <xsl:when test="$nodes">
        <xsl:call-template name="set:distinct">
          <xsl:with-param name="distinct" select="$distinct | $nodes[1][not(. = $distinct)]" />
          <xsl:with-param name="nodes" select="$nodes[position() &gt; 1]" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$distinct" mode="set:distinct" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="node()|@*" mode="set:distinct">
    <!-- <xsl:copy-of select="." /> -->
    <xsl:element name="distinct">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>
  <xsl:template name="replace">
    <xsl:param name="inputString" />
    <xsl:param name="searchText" />
    <xsl:param name="replaceBy" />
    <xsl:choose>
      <xsl:when test="contains($inputString, $searchText)">
        <xsl:value-of disable-output-escaping="yes" select="substring-before($inputString, $searchText)" />
        <xsl:value-of disable-output-escaping="yes" select="$replaceBy" />
        <xsl:call-template name="replace">
          <xsl:with-param name="inputString" select="substring-after($inputString, $searchText)" />
          <xsl:with-param name="searchText" select="$searchText" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$inputString='probando'">
            <xsl:text />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of disable-output-escaping="yes" select="$inputString" />
            <xsl:text />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="formatTableName">
    <xsl:param name="inputString" />
    <xsl:choose>
      <xsl:when test="contains($inputString, '.')">[<xsl:value-of disable-output-escaping="yes" select="substring-before($inputString, '.')" />].[<xsl:value-of disable-output-escaping="yes" select="substring-after($inputString, '.')" />]</xsl:when>
      <xsl:otherwise>[<xsl:value-of disable-output-escaping="yes" select="$inputString" />]
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*" mode="escape">
    <!-- Begin opening tag -->
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()" />
    <!-- Namespaces -->
    <xsl:for-each select="namespace::*[not(local-name(.)='xml')]">
      <xsl:text> xmlns</xsl:text>
      <xsl:if test="name() != ''">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="name()" />
      </xsl:if>
      <xsl:text>="</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>"</xsl:text>
    </xsl:for-each>
    <!-- Attributes -->
    <xsl:for-each select="@*">
      <xsl:value-of select="concat(' ',name())" />
      <xsl:text>="</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>"</xsl:text>
    </xsl:for-each>
    <!-- End opening tag -->
    <xsl:text>&gt;</xsl:text>
    <!-- Content (child elements, text nodes, and PIs) -->
    <xsl:apply-templates select="node()" mode="escape" />
    <!-- Closing tag -->
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()" />
    <xsl:text>&gt;</xsl:text>
  </xsl:template>
  <xsl:template match="text()" mode="escape">
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="." />
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="processing-instruction()" mode="escape">
    <xsl:text>&lt;?</xsl:text>
    <xsl:value-of select="name()" />
    <xsl:text />
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:text>?&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="escape-xml">
    <xsl:param name="text" />
    <xsl:if test="$text != ''">
      <xsl:variable name="head" select="substring($text, 1, 1)" />
      <xsl:variable name="tail" select="substring($text, 2)" />
      <xsl:choose>
        <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
        <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
        <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
        <xsl:when test="$head = '&quot;'">&amp;quot;</xsl:when>
        <xsl:when test="$head = &quot;'&quot;">&amp;apos;</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$head" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="$tail" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="/">
    <xsl:element name="query">
      --DECLARE @xmlResult XML; SELECT @xmlResult='&lt;results /&gt;'
      SET NOCOUNT ON
      DECLARE @tableName nvarchar(MAX), @ColumnName nvarchar(MAX), @identityTable nvarchar(MAX)
      DECLARE @currentNode xml, @result xml;
      DECLARE @ErrorMessage nvarchar(MAX)
      SET @result=@xmlResult;
      <xsl:apply-templates select="*" />
      --EXEC [$Tools].insertIntoXML @result OUTPUT, @XPath='/*', @XNew=@currentNode
      SELECT @xmlResult=@result
      --SELECT @xmlResult
    </xsl:element>
  </xsl:template>
  <xsl:template match="root">
    <xsl:apply-templates select="*" />
  </xsl:template>
  <xsl:template match="dataTable">
    <xsl:variable name="table" select="." />
    DECLARE @ID_<xsl:value-of select="generate-id(.)" /> int, @PK_Panax_<xsl:value-of select="generate-id(.)" /> nvarchar(MAX);
    EXEC [$Metadata].SetExtendedProperty '<xsl:call-template name="formatTableName">
      <xsl:with-param name="inputString" select="$table/@name" />
    </xsl:call-template>', NULL, 'currentUserId', <xsl:value-of select="$userId" />
    SELECT @identityTable=RTRIM(VIT.TABLE_SCHEMA)+'.'+RTRIM(VIT.TABLE_NAME) FROM [$Views].identityTable('<xsl:value-of disable-output-escaping="yes" select="$table/@name" />') VIT;
    IF @identityTable IS NOT NULL BEGIN EXEC [$Metadata].SetExtendedProperty @identityTable, NULL, 'currentUserId', <xsl:value-of select="$userId" />; END;
    <xsl:for-each select="*">
      <xsl:variable name="parentTable" select="$table/../ancestor-or-self::dataTable[1]" /><xsl:variable name="tableId">
        @ID_<xsl:value-of select="generate-id($table)" />
      </xsl:variable><xsl:variable name="tablePK">
        @PK_Panax_<xsl:value-of select="generate-id($table)" />
      </xsl:variable><xsl:variable name="parentTableId">
        @ID_<xsl:value-of select="generate-id($parentTable)" />
      </xsl:variable><xsl:variable name="parentTablePK">
        @PK_Panax_<xsl:value-of select="generate-id($parentTable)" />
      </xsl:variable>
      BEGIN TRY
      <xsl:choose>
        <xsl:when test="string($table/@primaryKey)='' and string($table/@identityKey)=''">RAISERROR ('No se puede guardar si no se define la identity key o la primary key', 16, 1); </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="local-name(.)='deleteRow'">
              DELETE <xsl:call-template name="formatTableName">
                <xsl:with-param name="inputString" select="$table/@name" />
              </xsl:call-template> WHERE <xsl:choose>
                <xsl:when test="string($table/@identityKey)!=''">
                  [<xsl:value-of select="$table/@identityKey" />]=<xsl:value-of select="@identityValue" />
                </xsl:when>
                <xsl:otherwise>
                  [<xsl:value-of select="$table/@primaryKey" />]=<xsl:choose>
                    <xsl:when test="starts-with(.,&quot;'&quot;)">
                      <xsl:value-of select="@primaryValue" />
                    </xsl:when>
                    <xsl:otherwise>
                      '<xsl:value-of select="@primaryValue" />'
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
              SELECT @currentNode='&lt;result dataTable="<xsl:value-of select="$table/@name" />" identityValue="'+RTRIM(ISNULL(CONVERT(nvarchar(30), <xsl:value-of select="$tableId" />), 'NULL'))+'" primaryValue="'+RTRIM(ISNULL(<xsl:value-of select="$tablePK" />, 'NULL'))+'" <xsl:for-each select="@*[not(name(.)='identityValue' or name(.)='primaryValue')]"> <xsl:value-of select="concat(' ', name(.))"/>="<xsl:value-of select="."/>"</xsl:for-each> status="success"/&gt;'
              EXEC [$Tools].insertIntoXML @result OUTPUT, @XPath='/*', @XNew=@currentNode
            </xsl:when>
            <xsl:when test="translate(@identityValue, $smallcase, $uppercase)='NULL' and translate(@primaryValue, $smallcase, $uppercase)='NULL'">
              <xsl:choose>
                <xsl:when test="dataField|dataTable">
                  INSERT INTO <xsl:call-template name="formatTableName">
                    <xsl:with-param name="inputString" select="$table/@name" />
                  </xsl:call-template> ( <xsl:if test="$table/@foreignKey!=''">
                    [<xsl:value-of select="$table/@foreignKey" />]<xsl:if test="dataField">,</xsl:if>
                  </xsl:if><xsl:for-each select="dataField">
                    <xsl:if test="position()&gt;1">,</xsl:if>[<xsl:value-of select="@name" />]
                  </xsl:for-each>) SELECT <xsl:if test="$table/@foreignKey!=''">
                    [<xsl:value-of select="$table/@foreignKey" />]=<xsl:value-of select="$parentTablePK" /><xsl:if test="dataField">,</xsl:if>
                  </xsl:if><xsl:for-each select="dataField">
                    <xsl:if test="position()&gt;1">,</xsl:if>[<xsl:value-of select="@name" />]=<xsl:choose>
                      <xsl:when test="value">
                        <xsl:for-each select="value">
                          <xsl:choose>
                            <xsl:when test="text()">
                              <xsl:value-of select="text()" />
                            </xsl:when>
                            <xsl:otherwise>NULL</xsl:otherwise>
                          </xsl:choose>
                        </xsl:for-each>
                      </xsl:when>
                      <xsl:when test="*">
                        '<xsl:apply-templates mode="escape" select="*" />'
                      </xsl:when>
                      <xsl:when test="text()">
                        <xsl:value-of select="text()" />
                      </xsl:when>
                      <xsl:otherwise>NULL</xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each><xsl:if test="string($table/@identityKey)!=''">
                    SELECT <xsl:value-of select="$tableId" />=COALESCE(SCOPE_IDENTITY(), @@IDENTITY);
                  </xsl:if><xsl:if test="string($table/@primaryKey)!=''">
                    SELECT <xsl:value-of select="$tablePK" />=[<xsl:value-of select="$table/@primaryKey" />] FROM <xsl:call-template name="formatTableName">
                      <xsl:with-param name="inputString" select="$table/@name" />
                    </xsl:call-template> WHERE <xsl:choose>
                      <xsl:when test="string($table/@identityKey)!=''">
                        [<xsl:value-of select="$table/@identityKey" />]=<xsl:value-of select="$tableId" />
                      </xsl:when>
                      <xsl:otherwise>
                        [<xsl:value-of select="$table/@primaryKey" />]=<xsl:value-of select="dataField[@name=$table/@primaryKey]/text()" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:if>;
                  SELECT @currentNode='&lt;result dataTable="<xsl:value-of select="$table/@name" />" identityValue="'+RTRIM(ISNULL(CONVERT(nvarchar(30), <xsl:value-of select="$tableId" />), 'NULL'))+'" primaryValue="'+RTRIM(ISNULL(<xsl:value-of select="$tablePK" />, 'NULL'))+'"<xsl:for-each select="@*[not(name(.)='identityValue' or name(.)='primaryValue')]"> <xsl:value-of select="concat(' ', name(.))"/>="<xsl:value-of select="."/>"</xsl:for-each> status="success"/&gt;'
                  EXEC [$Tools].insertIntoXML @result OUTPUT, @XPath='/*', @XNew=@currentNode
                  <xsl:apply-templates select="dataTable" />
                </xsl:when>
                <xsl:otherwise>
                  RAISERROR ('No se pudo insertar un nuevo registro porque faltan campos de llenar', 16, 1)
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="dataField">
                UPDATE <xsl:call-template name="formatTableName">
                  <xsl:with-param name="inputString" select="$table/@name" />
                </xsl:call-template> SET <xsl:if test="$table/@foreignKey!=''">
                  [<xsl:value-of select="$table/@foreignKey" />]=<xsl:value-of select="$parentTablePK" />,
                </xsl:if><xsl:for-each select="dataField">
                  <xsl:if test="position()&gt;1">,</xsl:if>[<xsl:value-of select="@name" />]=<xsl:apply-templates select="." mode="value" />
                </xsl:for-each> WHERE <!-- Descomentar si se quiere ejecutar el update solo si hay cambios (<xsl:for-each select="dataField">
                  <xsl:if test="position()&gt;1"> OR </xsl:if>(NOT([<xsl:value-of select="@name" />]=<xsl:apply-templates select="." mode="value" />) OR [<xsl:value-of select="@name" />] IS NOT NULL AND <xsl:apply-templates select="." mode="value" /> IS NULL OR [<xsl:value-of select="@name" />] IS NULL AND <xsl:apply-templates select="." mode="value" /> IS NOT NULL)
                </xsl:for-each>) AND--> <xsl:choose>
                  <xsl:when test="string($table/@identityKey)!=''">
                    [<xsl:value-of select="$table/@identityKey" />]=<xsl:value-of select="@identityValue" />
                  </xsl:when>
                  <xsl:otherwise>
                    [<xsl:value-of select="$table/@primaryKey" />]=<xsl:choose>
                      <xsl:when test="starts-with(.,&quot;'&quot;)">
                        <xsl:value-of select="@primaryValue" />
                      </xsl:when>
                      <xsl:otherwise>
                        '<xsl:value-of select="@primaryValue" />'
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if><xsl:text>; </xsl:text><xsl:if test="string($table/@identityKey)!=''">
                SELECT <xsl:value-of select="$tableId" />=COALESCE((SELECT [<xsl:value-of select="$table/@identityKey" />] FROM <xsl:call-template name="formatTableName">
                  <xsl:with-param name="inputString" select="$table/@name" />
                </xsl:call-template> WHERE [<xsl:value-of select="$table/@identityKey" />]=<xsl:value-of select="@identityValue" />), IDENT_CURRENT(@identityTable));
                <xsl:if test="string($table/@primaryKey)!=''">
                  SELECT <xsl:value-of select="$tablePK" />=[<xsl:value-of select="$table/@primaryKey" />] FROM <xsl:call-template name="formatTableName">
                    <xsl:with-param name="inputString" select="$table/@name" />
                  </xsl:call-template> WHERE [<xsl:value-of select="$table/@identityKey" />]=<xsl:value-of select="$tableId" />;
                </xsl:if>
              </xsl:if>
              SELECT @currentNode='&lt;result dataTable="<xsl:value-of select="$table/@name" />" identityValue="'+RTRIM(ISNULL(CONVERT(nvarchar(30), <xsl:value-of select="$tableId" />), 'NULL'))+'" primaryValue="'+RTRIM(ISNULL(<xsl:value-of select="$tablePK" />, 'NULL'))+'"<xsl:for-each select="@*[not(name(.)='identityValue' or name(.)='primaryValue')]"> <xsl:value-of select="concat(' ', name(.))"/>="<xsl:value-of select="."/>"</xsl:for-each> status="success"/&gt;'
              EXEC [$Tools].insertIntoXML @result OUTPUT, @XPath='/*', @XNew=@currentNode
              <xsl:apply-templates select="dataTable" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      END TRY
      BEGIN CATCH
      SELECT @columnName=[$RegEx].Replace(ERROR_MESSAGE(), '[\s\S]*?\bcolumn(a)?\b\s''(?&lt;columnName&gt;[\w_\.\:]+?)''[\s\S]*','${columnName}',1), @tableName=[$RegEx].Replace(ERROR_MESSAGE(), '[\s\S]*?\btabl[ea]?\b\s''(?&lt;columnName&gt;[\w_\.\:]+?)''[\s\S]*','${columnName}',1)
      SELECT @ErrorMessage=ERROR_MESSAGE()
      SELECT @ErrorMessage=COALESCE((SELECT NULLIF(RTRIM(CONVERT(NVARCHAR(MAX),EP.value)),'')
      FROM [$RegEx].Matches(REPLACE(ERROR_MESSAGE(),'''','"'), '"[^"]+?"',1)
      JOIN sys.all_objects AO ON type_desc LIKE '%constraint%' AND Type NOT IN ('D') AND PARSENAME(Match,1)=AO.Name
      JOIN sys.extended_properties EP ON EP.major_id=AO.object_id AND EP.name='MS_Description'),@ErrorMessage)
      SELECT @currentNode='&lt;result dataTable="<xsl:value-of select="$table/@name" />"<xsl:for-each select="@*[not(name(.)='identityValue' or name(.)='primaryValue')]"> <xsl:value-of select="concat(' ', name(.))"/>="<xsl:value-of select="."/>"</xsl:for-each> status="error" statusId="'+ltrim(str(error_number()))+'" '+/*ISNULL('referenceColumn="'+@columnName+'"','')+*/' statusMessage="'+[$String].HTMLEncode([$Tools].CustomErrorMessage(ERROR_NUMBER(), @ErrorMessage))+'"/&gt;'
      EXEC [$Tools].insertIntoXML @result OUTPUT, @XPath='/*', @XNew=@currentNode
      END CATCH;
    </xsl:for-each>
    IF @identityTable IS NOT NULL BEGIN EXEC [$Metadata].SetExtendedProperty @identityTable, NULL, 'currentUserId', NULL; END;
    EXEC [$Metadata].SetExtendedProperty '<xsl:call-template name="formatTableName">
      <xsl:with-param name="inputString" select="$table/@name" />
    </xsl:call-template>', NULL, 'currentUserId', NULL
  </xsl:template>
  <xsl:template mode="value" match="*">
    <xsl:choose>
      <xsl:when test="value">
        <xsl:for-each select="value">
          <xsl:choose>
            <xsl:when test="text()">
              <xsl:value-of select="text()" />
            </xsl:when>
            <xsl:otherwise>NULL</xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="*">
        '<xsl:apply-templates mode="escape" select="*" />'
      </xsl:when>
      <xsl:when test="text()">
        <xsl:value-of select="text()" />
      </xsl:when>
      <xsl:otherwise>NULL</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>