<xsl:stylesheet xmlns="" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" version="1.0" extension-element-prefixes="msxsl">
  <xsl:strip-space elements="*" />
  
  <xsl:key name="renderField" match="Table/*/Field[not(@autoGenerateField='false' or @controlType='hiddenField' or @mode='hidden' or @Column_Name=../../@identityKey)]" use="generate-id(.)" />
  
  <xsl:key name="fieldbound" match="Table/*/Field[@Column_Name=ancestor::Table[1]//@binding]" use="generate-id(.)" />
  <xsl:key name="ForeignTable" match="ForeignTable" use="generate-id(.)" />
  <xsl:key name="ForeignKeys" match="ForeignKeys/ForeignKey[string(@mode)='inline' or string(@mode)='inherit' or @scaffold='true' and string(@mode)!='none' or (not(string(@mode)='none') and not(@scaffold='false') and (not(following-sibling::* or preceding-sibling::*) or @mode or (ancestor::ForeignTable[1]/@defaultForeignKey=@Column_Name and not(@mode) and (following-sibling::* or preceding-sibling::*)) ))][1]" use="generate-id(ancestor::ForeignTable[1])" />
  <!--<xsl:key name="DataRelatedAttribute" match="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')']" use="generate-id(.)" />-->
  <xsl:key name="parentMode" match="*" use="concat(generate-id(.),':',ancestor-or-self::*[@mode!='inherit'][1]/@mode)" />
  <xsl:key name="mode" match="*[@mode!='inherit']" use="generate-id(//*[generate-id(current())=generate-id(ancestor-or-self::*[@mode!='inherit'][1])])" />
  <xsl:key name="sortableColumns" match="Table/*/Field[not(@mode='none' or @Column_Name=../../@identityKey or ../../../@dataType='junctionTable' and @Column_Name=../../PrimaryKeys/PrimaryKey/@Column_Name)][@sortOrder or not(@sortOrder) and (not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey') or position()=1 and count(following-sibling::*[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey' or @Column_Name=../../@identityKey)])=0)]" use="generate-id(../..)" />
  <xsl:key name="allFields" match="Table/*/Field" use="generate-id(../..)" />
  <xsl:key name="allFields" match="Table/*/Field" use="generate-id(.)" />
  <xsl:key name="availableFields" match="Table/*/Field[string(@mode)!='none' and not(@Column_Name=ancestor::Field[1]/@foreignReference)][@mode or not(@mode) and not(@isNullable=1 and (ancestor-or-self::Table[1][@controlType='gridView'][not(../@dataType='junctionTable')] or ancestor-or-self::Table[@mode][1]/@mode='filters') or ((@dataType='foreignTable' or @dataType='junctionTable') and ancestor-or-self::Table[1][@controlType='gridView' or @mode='filters']) )]" use="generate-id(../..)" />
  <xsl:key name="availableFields" match="Table/*/Field[string(@mode)!='none' and not(@Column_Name=ancestor::Field[1]/@foreignReference)][@mode or not(@mode) and not(@isNullable=1 and (ancestor-or-self::Table[1][@controlType='gridView'][not(../@dataType='junctionTable')] or ancestor-or-self::Table[@mode][1]/@mode='filters') or ((@dataType='foreignTable' or @dataType='junctionTable') and ancestor-or-self::Table[1][@controlType='gridView' or @mode='filters' or @mode='fieldselector' or @mode='help']) )]" use="generate-id()" />
  <xsl:key name="primaryKey" match="Table/*/Field[@dataType!='foreignTable' and @dataType!='junctionTable'][@Column_Name=../../PrimaryKeys/PrimaryKey/@Column_Name]" use="generate-id(.)" />
  <xsl:key name="primaryReference" match="Field[@dataType='foreignTable' or @dataType='junctionTable'][@foreignReference=Table/*/Field[@dataType!='foreignTable' and @dataType!='junctionTable']/@Column_Name]" use="generate-id(Table/*/Field[@Column_Name=ancestor::Field[1]/@foreignReference])" />
  <xsl:key name="foreignReference" match="Table/*/Field[@Column_Name=ancestor::Field[1]/@foreignReference]" use="generate-id(.)" />
  <xsl:key name="RequestedTable" match="/root/Tables" use="generate-id(.)" />
  <xsl:variable name="inputParameters" />
  <xsl:variable name="fieldDefaults" />
  <xsl:variable name="version" />
  <xsl:variable name="filters" />
  <xsl:variable name="sorters" />
  <xsl:variable name="queryMode"></xsl:variable>
  <xsl:variable name="fullPath" />
  <xsl:variable name="columnList" />

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
          <xsl:with-param name="replaceBy" select="$replaceBy" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$inputString = ''">
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
  <xsl:template name="escape-apos">
    <xsl:param name="string" />
    <xsl:choose>
      <xsl:when test="contains($string, &quot;'&quot;)">
        <xsl:value-of select="substring-before($string, &quot;'&quot;)" />
        <xsl:text>''</xsl:text>
        <xsl:call-template name="escape-apos">
          <xsl:with-param name="string" select="substring-after($string, &quot;'&quot;)" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="/">
    <xsl:for-each select="//Table[key('RequestedTable', generate-id(.))][1]">
		<xsl:variable name="baseTable" select="."/>
      <query>
        <xsl:value-of select="$fieldDefaults" />
		  --DECLARE @@UserId nvarchar(255), @lang nvarchar(15), @pageSize int, @pageIndex int, @getData bit, @getStructure bit, @filters nvarchar(MAX), @parameters nvarchar(MAX), @TableSchema nvarchar(MAX), @TableName nvarchar(MAX);
		  --SELECT @@UserId=-1, @pageSize=1, @pageIndex=1, @getData=1, @getStructure=1, @filters='', @parameters='', @TableSchema='<xsl:value-of select="@Table_Schema" />', @TableName='<xsl:value-of select="@Table_Name" />';
		  --		  DECLARE @resourcesLocation nvarchar(MAX);
		  --		  SELECT @resourcesLocation=[$Application].getGlobalizationResourcesLocation()+@TableSchema+'\'+@TableName+'\headers'+ISNULL('.'+RTRIM(@lang),'')+'.resx'
		  --		  DECLARE @resx XML; EXEC [$FSO].getResourcesFile @FilePath=@resourcesLocation, @resx=@resx OUTPUT
		  --		  IF @resx IS NULL BEGIN
		  --		  SELECT @resourcesLocation=[$Application].getGlobalizationResourcesLocation()+@TableSchema+'\'+@TableName+'\headers.resx'
		  --		  EXEC [$FSO].getResourcesFile @FilePath=@resourcesLocation, @resx=@resx OUTPUT
		  --		  END

		  <xsl:variable name="tableSchema" select="//Table[key('RequestedTable', generate-id(.))]/descendant-or-self::Table/@Table_Schema" /><xsl:if test="@parameters">

			  DECLARE <xsl:value-of select="@parameters" />;
        </xsl:if><xsl:if test="current()/Parameters/*">
          DECLARE <xsl:for-each select="current()/Parameters/*">
            <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
            <xsl:if test="position()&gt;1">,</xsl:if>
            <xsl:value-of select="@parameterName" />
            <xsl:value-of select="concat(' ', @dataType)" />
            <xsl:if test="@length">
              (<xsl:choose>
                <xsl:when test="number(@length)=-1">MAX</xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@length" />
                </xsl:otherwise>
              </xsl:choose>)
            </xsl:if>
          </xsl:for-each>;
        </xsl:if>
		  DECLARE @@Privileges TABLE(/*[$Id] int, */[$UserId] nvarchar(255), [$UserName] nvarchar(255), [$ProfileId] nvarchar(255), [$Profile] nvarchar(255), [$ProfilePriority] tinyint, [$SchemaName] nvarchar(255), [$CatalogName] nvarchar(255), [$C] tinyint, [$R] tinyint, [$U] tinyint, [$D] tinyint, [$S] tinyint )

		  INSERT INTO @@Privileges
		  SELECT /*[$Id], */[$UserId], [$UserName], [$ProfileId], [$Profile], [$ProfilePriority], [$SchemaName], [$CatalogName]
		  , [$C]=ISNULL(MAX(CONVERT(tinyint,[$A])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$R]=ISNULL(MAX(CONVERT(tinyint,[$D])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$U]=ISNULL(MAX(CONVERT(tinyint,[$C])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$D]=ISNULL(MAX(CONVERT(tinyint,[$B])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$S]=ISNULL(MAX(CONVERT(tinyint,[$E])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  FROM [$Security].UserPrivileges [#Privileges]
		  WHERE [#Privileges].[$UserId]=@@UserId

		  /*#parameters#*/
		  ;WITH XMLNAMESPACES ('urn:panax' AS px, 'urn:session' AS session, 'http://www.panaxit.com/custom' AS custom, 'http://www.panaxit.com/debug' AS debug, 'urn:extjs' AS extjs ),
		  [#Privileges](/*[$Id], */[$UserId], [$UserName], [$ProfileId], [$Profile], [$ProfilePriority], [$SchemaName], [$CatalogName], [$C], [$R], [$U], [$D], [$S]) AS (
		  SELECT /*[$Id], */[$UserId], [$UserName], [$ProfileId], [$Profile], [$ProfilePriority], [$SchemaName], [$CatalogName]
		  , [$C]--=ISNULL(MAX(CONVERT(tinyint,[$A])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$R]--=ISNULL(MAX(CONVERT(tinyint,[$D])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$U]--=ISNULL(MAX(CONVERT(tinyint,[$C])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$D]--=ISNULL(MAX(CONVERT(tinyint,[$B])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  , [$S]--=ISNULL(MAX(CONVERT(tinyint,[$E])) OVER(PARTITION BY [$UserName], [$SchemaName], [$CatalogName]),0)
		  FROM @@Privileges [#Privileges]
		  WHERE [#Privileges].[$UserId]=@@UserId
		  )
		  <xsl:apply-templates mode="node" select=".">
			<xsl:with-param name="baseTable" select="$baseTable"/>
		</xsl:apply-templates>
      </query>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template mode="node" match="Table">
	<xsl:param name="baseTable"/>
    <xsl:param name="table" select="ancestor-or-self::Table[1]" />
    <xsl:param name="unBindPrimaryTable" select="false()" />
    <xsl:param name="scope" select="'all'" />
    <xsl:variable name="pageSize">
      <xsl:choose>
        <xsl:when test="key('RequestedTable', generate-id(current())) and @pageSize">
          COALESCE(@pageSize,<xsl:value-of select="@pageSize" />)
        </xsl:when>
        <xsl:when test="key('RequestedTable', generate-id(current()))">ISNULL(@pageSize,0)</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--<xsl:variable name="pIndex"><xsl:choose><xsl:when test='key("RequestedTable", generate-id(current())) and string($pageIndex)!=""'><xsl:value-of select="$pageIndex"/></xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose></xsl:variable>-->
    SELECT
    [@xml:lang]=RTRIM(COALESCE(NULLIF(@lang,''), NULLIF('<xsl:value-of select="@xml:lang"/>',''), 'es'))
    ,[@session:IdUser]=@@UserId
    ,[@session:profileId]=(SELECT DISTINCT '['+RTRIM([$ProfileId])+']' FROM @@Privileges SP WHERE SP.[$UserId]=@@UserId FOR XML PATH(''))
	,[@dbId]=DB_NAME() --Aquí podría traer un alias
    ,[@fullPath]='<xsl:value-of select="$fullPath" />'
    ,[@version]='<xsl:value-of select="$version" />'
    ,[@pageSize]=<xsl:value-of select="$pageSize" />
    ,[@pageIndex]=<xsl:choose>
      <xsl:when test="key('RequestedTable', generate-id(current()))">COALESCE(@pageIndex,1)</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates mode="Attributes" select="../@foreignReference" />
    ,[@totalRecords]=CASE WHEN @getData=0 <xsl:if test="not(key('RequestedTable', generate-id(current())))"> OR 1=1 </xsl:if>THEN NULL WHEN <xsl:value-of select="$pageSize" />=0 THEN xmlData.value('count(/px:data/px:dataRow[@rowNumber&gt;0])' ,'int') ELSE <xsl:choose>
      <xsl:when test="key('RequestedTable', generate-id(current())) and @mode!='insert' and @mode!='filters' and not(@mode='fieldselector' or @mode='help' or @mode='search' or @mode='print')">
        (SELECT COUNT(1) FROM (SELECT [$mode]=<xsl:choose>
          <xsl:when test="string($table/*/@mode)!=''">
            <xsl:apply-templates select="$table/*/@mode" mode="Property.Value" />
          </xsl:when>
          <xsl:otherwise>'inherit'</xsl:otherwise>
        </xsl:choose><xsl:call-template name="queryDefinition">
			<xsl:with-param name="baseTable" select="$baseTable"/>
			<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
        </xsl:call-template>) [#primaryTable] WHERE not([$mode]='none') )
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose> END
    <xsl:apply-templates mode="Attributes" select="@*[(name(.)!='columnDefinition' and name(.)!='pageSize' and name(.)!='pageIndex' and name(.)!='displayText' and name(.)!='parameters' and name(.)!='mode') and name(.)!='filters' and name(.)!='headerText' and name(.)!='disableInsert' and name(.)!='disableUpdate' and name(.)!='disableDelete' and name(.)!='xml:lang']" />
    ,[@headerText]=<xsl:choose>
      <xsl:when test="@headerText"><xsl:apply-templates select="@headerText" mode="Property.Value" /></xsl:when>
      <xsl:otherwise>CASE WHEN '<xsl:value-of select="@Table_Schema" />'='dbo' THEN '' ELSE [$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Table_Schema" />', '_', ' ', 1))+' - ' END + [$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Table_Name" />', '_', ' ', 1))
      </xsl:otherwise>
    </xsl:choose>
    ,[@filters]=@filters
    ,[@parameters]=@parameters
    , [@mode]=ISNULL(<xsl:apply-templates select="@mode" mode="Property.Value" />+LEFT(NULLIF(([$Privileges].[$R]
    ),0),0), 'deny')
    <xsl:if test="$scope!='data'">
      <xsl:variable name="orderedTree">
        <fields>
          <xsl:apply-templates select="*[local-name(.)='Fields' or local-name(.)='Record']/Field[1]" mode="tree">
            <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
          </xsl:apply-templates>
        </fields>
      </xsl:variable>
      <xsl:variable name="tree">
        <fields>
          <xsl:apply-templates select="msxsl:node-set($orderedTree)/*/*[1]" mode="groups"/>
        </fields>
      </xsl:variable>
      <xsl:if test="key('RequestedTable', generate-id(current()))">/*#Fields--*/</xsl:if>, (
      SELECT [DUMMY/@Start]=NULL<xsl:apply-templates select="msxsl:node-set($tree)/*/*" mode="layout">
		  <xsl:with-param name="baseTable" select="$baseTable"/>
		  <xsl:with-param name="fields" select="Fields|Record" />
        <xsl:with-param name="scope" select="'fields'" />
      </xsl:apply-templates> WHERE @getStructure=1 or @getData=1 FOR XML PATH(''), TYPE
      )<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Fields#*//*#Layout--*/</xsl:if>, (
      SELECT [DUMMY/@Start]=NULL<xsl:apply-templates select="msxsl:node-set($tree)/*/*" mode="layout">
		  <xsl:with-param name="baseTable" select="$baseTable"/>
		  <xsl:with-param name="fields" select="Fields|Record" />
        <xsl:with-param name="scope" select="'layout'" />
      </xsl:apply-templates> WHERE @getStructure=1 FOR XML PATH(''), TYPE
      )<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Layout#*/</xsl:if>
    </xsl:if><xsl:if test="$scope!='fields'">
      <!--  or (../@dataType='junctionTable') -->
      , xmlData AS '*'
      FROM
    (
    SELECT <xsl:if test="key('RequestedTable', generate-id(current()))">/*#Data--*/</xsl:if>* FROM (
    SELECT [@rowNumber]=ROW_NUMBER() OVER (ORDER BY <xsl:if test="key('RequestedTable', generate-id(current()))">/*#sorters#*/</xsl:if><xsl:call-template name="sortColumns" />), <xsl:apply-templates select="Fields|Record" mode="columns">
		<xsl:with-param name="baseTable" select="$baseTable"/>
		<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
      </xsl:apply-templates><xsl:if test="1=1 or not(ancestor-or-self::*/@controlType='gridView')">
        <xsl:apply-templates select="Fields|Record" mode="foreignTables">
			<xsl:with-param name="baseTable" select="$baseTable"/>
			<xsl:with-param name="scope" select="'data'" />
        </xsl:apply-templates>
      </xsl:if>
		FROM
		(
		<xsl:variable name="getPhantomRecord" select="not(../@dataType='junctionTable') and ($baseTable[@mode='insert' or @mode='filters' or @mode='fieldselector' or @mode='help']) or ../@dataType='foreignTable' and ../@relationshipType='hasOne'"/>
		<xsl:variable name="getTableRecords" select="not($getPhantomRecord) or ../@dataType='foreignTable' and ../@relationshipType='hasOne'"/>
		/*baseTable/@mode: <xsl:value-of select="$baseTable/@mode"/>||getPhantomRecord:<xsl:value-of select="$getPhantomRecord"/>||getTableRecords:<xsl:value-of select="$getTableRecords"/>*/
		<xsl:if test="$getPhantomRecord">
        SELECT <xsl:apply-templates select="Fields|Record" mode="columnValues">
			<xsl:with-param name="baseTable" select="$baseTable"/>
			<xsl:with-param name="mode" select="'phantom'"/>
        <xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
        </xsl:apply-templates>
        WHERE EXISTS(SELECT 1 FROM @@Privileges [#Privileges] WHERE /*[#Privileges].[$UserId]=@@UserId AND */[#Privileges].[$SchemaName]='<xsl:value-of select="@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="@Table_Name" />' AND [#Privileges].[$R]=1) <!--<xsl:if test="not(@mode='insert' or @mode='filters' or @mode='fieldselector' or @mode='help')">-->
			<xsl:if test="$getTableRecords=true()">
				AND NOT EXISTS(SELECT 1 <xsl:call-template name="queryDefinition">
					<xsl:with-param name="baseTable" select="$baseTable"/>
					<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
					<xsl:with-param name="mode" select="'recordCount'" />
				</xsl:call-template>)
			/*../@dataType (<xsl:value-of select="../@dataType"/>) and ../@relationshipType (<xsl:value-of select="../@relationshipType"/>)*/
			</xsl:if>
		</xsl:if>
		<xsl:if test="$getTableRecords=true() and $getPhantomRecord=true()">
			UNION ALL
		</xsl:if>
		<xsl:if test="$getTableRecords=true()">
			SELECT <xsl:apply-templates select="Fields|Record" mode="columnValues">
				<xsl:with-param name="baseTable" select="$baseTable"/>
				<xsl:with-param name="mode" select="'edit'" />
				<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
			</xsl:apply-templates><xsl:call-template name="queryDefinition">
				<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
			</xsl:call-template>
		</xsl:if>
		) [#primaryTable] WHERE not([@mode]='none')
		) [#primaryTable] WHERE @getData=1 and (<xsl:if test="@mode='insert' or @mode='filters' or @mode='fieldselector' or @mode='help'">[@rowNumber] IS NULL OR </xsl:if><xsl:value-of select="$pageSize" />=0 OR [@rowNumber] BETWEEN (<xsl:value-of select="$pageSize" />*(@pageIndex-1))+1 AND <xsl:value-of select="$pageSize" />*@pageIndex)
      ORDER BY [@rowNumber] FOR XML PATH('px:dataRow'), ROOT('px:data'), TYPE<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Data#*/</xsl:if>
      ) [#primaryTable](xmlData) CROSS JOIN (SELECT TOP 1 [$C], [$R], [$U], [$D], [$S] FROM @@Privileges [#Privileges] WHERE <xsl:choose>
      <xsl:when test="ancestor-or-self::Field[1]/@dataType='junctionTable'">
        [#Privileges].[$SchemaName]='<xsl:value-of select="ancestor-or-self::Field[1]/../../@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="ancestor-or-self::Field[1]/../../@Table_Name" />'
      </xsl:when>
      <xsl:otherwise>
        [#Privileges].[$SchemaName]='<xsl:value-of select="@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="@Table_Name" />'
      </xsl:otherwise>
    </xsl:choose> AND [#Privileges].[$R]=1) [$Privileges] /**/
    </xsl:if>
    FOR XML PATH('<xsl:value-of select="@Table_Name" />'), TYPE
  </xsl:template>
  <xsl:template name="viewDefinition">
    <xsl:param name="table" select="ancestor-or-self::Table[1]" />
    <xsl:choose>
      <xsl:when test="$table[@Base_Type='FUNCTION']">
        <xsl:choose>
          <xsl:when test="@Underlying_Table">
            <xsl:value-of select="$table/@Underlying_Table" />
          </xsl:when>
          <xsl:otherwise>
            [<xsl:value-of select="@Table_Schema" />].[<xsl:value-of select="$table/@Table_Name" />]
          </xsl:otherwise>
        </xsl:choose>(<xsl:for-each select="$table/Parameters/*">
          <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
          <xsl:if test="position()&gt;1">,</xsl:if>
          <xsl:choose>
            <xsl:when test="contains($inputParameters, concat(@parameterName, '='))">
              <xsl:value-of select="@parameterName" />
            </xsl:when>
            <xsl:otherwise>DEFAULT</xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>)
      </xsl:when>
      <xsl:otherwise>
        [<xsl:value-of select="@Table_Schema" />].[<xsl:value-of select="$table/@Table_Name" />]
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="Attributes" mode="Attributes" match="@*">
    <xsl:param name="mode" select="'attribute'" />
    <xsl:param name="Column_Name" />
    <xsl:param name="supressFirstComma" select="false()" />
    <xsl:param name="defaultIfDynamic" select="false()" />
    <xsl:param name="escape" select="false()" />
    <xsl:param name="withValue" select="true()" />
    <xsl:param name="value">
      <xsl:apply-templates select="." mode="Property.Value">
        <xsl:with-param name="escape" select="$escape" />
        <xsl:with-param name="defaultIfDynamic" select="$defaultIfDynamic" />
      </xsl:apply-templates>
    </xsl:param>
    <xsl:if test="position()=1 and not($supressFirstComma=true()) or position()&gt;1">,</xsl:if>[<xsl:if test="$Column_Name"><xsl:value-of select="$Column_Name" />/</xsl:if><xsl:if test="$mode='attribute'">@</xsl:if><xsl:value-of select="name(.)" />]<xsl:choose><xsl:when test="$withValue=false()" /><xsl:otherwise>=<xsl:value-of select="$value" /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="Attributes" match="@moveBefore|@moveAfter|@ordinalPosition|@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer|@fieldContainerEnd|@controlTypeHint" />

<xsl:template mode="Attributes" match="@*[ancestor::*[@mode='filters' or @mode='fieldselector' or @mode='help']][(name()='supportsInsert' or name()='supportsUpdate' or name()='supportsDelete' or name()='isNullable' or name()='length')]"></xsl:template>

<xsl:template mode="Attributes" match="@*[ancestor::*[@mode='fieldselector' or @mode='help']][(name()='relationshipType' or name()='foreignSchema' or name()='foreignTable' or name()='foreignReference')]"></xsl:template>

<xsl:template mode="Attributes" match="Table/@supportsInsert|Table/@supportsUpdate|Table/@supportsDelete">
    <xsl:param name="mode" select="'attribute'" />
    <xsl:param name="Column_Name" select="@Column_Name" />
    <xsl:param name="supressFirstComma" select="false()" />
    <xsl:param name="defaultIfDynamic" select="false()" />
    <xsl:variable name="attachedAttribute">disable<xsl:call-template name="replace">
        <xsl:with-param name="inputString" select="name(.)" />
        <xsl:with-param name="searchText" select="'supports'" />
        <xsl:with-param name="replaceBy" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="Attributes">
      <xsl:with-param name="mode" select="$mode" />
      <xsl:with-param name="Column_Name" select="$Column_Name" />
      <xsl:with-param name="supressFirstComma" select="$supressFirstComma" />
      <xsl:with-param name="defaultIfDynamic" select="$defaultIfDynamic" />
    </xsl:call-template>
    <xsl:if test="not($Column_Name)">,[@<xsl:value-of select="$attachedAttribute"/>]=ABS([$Privileges].[<xsl:apply-templates mode="support.bind" select="."/>]-1)*COALESCE(<xsl:choose><xsl:when test="../@*[name(.)=$attachedAttribute]"><xsl:apply-templates select="../@*[name(.)=$attachedAttribute]" mode="Property.Value"><xsl:with-param name="defaultIfDynamic" select="$defaultIfDynamic"/></xsl:apply-templates></xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose>,1)</xsl:if>
  </xsl:template>

  <xsl:template mode="Property.Value" match="*[not(@*)]">NULL</xsl:template>
  
  <xsl:template mode="Property.Value" match="@*"><xsl:apply-templates select="." mode="Property.ValueFormat" /></xsl:template>
  
  <xsl:template mode="Property.Value" match="@description[key('parentMode',concat(generate-id(..),':readonly'))]">NULL</xsl:template>
  <xsl:template mode="support.bind" match="@supportsInsert">$C</xsl:template>
  <xsl:template mode="support.bind" match="@supportsDelete">$D</xsl:template>
  <xsl:template mode="support.bind" match="@supportsUpdate">$U</xsl:template>
  

  <xsl:template mode="Property.Value" match="@pageSize|@pageIndex|@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')']">
  <!--DataRelatedAttribute-->
    <xsl:param name="escape" select="false()" />/*-value-*/
    <xsl:choose>
      <xsl:when test="$escape">
        '<xsl:call-template name="escape-apos">
          <xsl:with-param name="string"><xsl:value-of select="." /></xsl:with-param>
        </xsl:call-template>'
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="." />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template mode="Property.Value" match="@*[substring(., 1, 10)='CASE WHEN '][contains(., '[$')]">
    <xsl:variable name="table" select="ancestor-or-self::*[@Table_Name][@Table_Schema][1]" />
    (SELECT TOP 1 returnValue=<xsl:value-of select="." /> FROM @@Privileges [#Privileges] WHERE /*[#Privileges].[$UserId]=@@UserId AND */[#Privileges].[$SchemaName]='<xsl:value-of select="$table/@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="$table/@Table_Name" />' AND [#Privileges].[$R]=1 )<!-- disable-output-escaping="yes" -->
  </xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field/@headerText">
    '<xsl:value-of select="." /><xsl:if test="../@Column_Name=../preceding-sibling::*/@Column_Name or ../@Column_Name=../following-sibling::*/@Column_Name">
		<xsl:text> (</xsl:text>
		<xsl:value-of select="../@foreignReference" />
		<xsl:text>)</xsl:text>
    </xsl:if>'
  </xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field/@controlType">
    <xsl:param name="defaultIfDynamic" select="false()" />/*<xsl:value-of select="$defaultIfDynamic" />*/<xsl:choose>
      <xsl:when test="$defaultIfDynamic=false() and .!='default'">
        <xsl:apply-templates select="." mode="Property.ValueFormat" />
      </xsl:when>
      <xsl:when test="$defaultIfDynamic=false() and @formula">'formula'</xsl:when>
      <xsl:otherwise>'default'</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template mode="Property.Value" match="Table[@mode='filters']//@mode">'filters'</xsl:template>
  <xsl:template mode="Property.Value" match="Table[@mode='fieldselector' or @mode='help']/*//@mode">'inherit'</xsl:template>
  <xsl:template mode="Property.Value" match="@mode">
    <xsl:param name="defaultIfDynamic" select="false()" />
    <xsl:choose>
      <xsl:when test="$defaultIfDynamic=true() and substring(., 1, 10)='CASE WHEN '">'inherit'</xsl:when>
      <xsl:when test="key('foreignReference', generate-id()) or contains($fieldDefaults, concat('@#', ../@Column_Name, '='))">'none'</xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="Property.ValueFormat" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>  
  <xsl:template mode="Property.Value" match="@fieldSet">
    <xsl:choose>
      <xsl:when test="string(.)!=''">
        '<xsl:call-template name="translateTemplate">
          <xsl:with-param name="template" select="string(ancestor-or-self::*[@fieldSet][1]/@fieldSet)" />
        </xsl:call-template>'
      </xsl:when>
      <xsl:otherwise>''</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field[not(@dataType='identity')][ancestor::*[@mode='fieldselector' or @mode='help']]/@dataType">'bit'</xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@mode='filters']]">'default'</xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@mode='fieldselector']]">'checkbox'</xsl:template>
  <xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@mode='help']]">'label'</xsl:template>
  <xsl:template mode="Property.ValueFormat" match="@*">'<xsl:call-template name="escape-apos">
      <xsl:with-param name="string">
        <xsl:value-of select="." />
      </xsl:with-param>
    </xsl:call-template>'
  </xsl:template>  
  <xsl:template match="Field" mode="text">
    ISNULL(RTRIM([<xsl:value-of select="@Column_Name" />]),'')
  </xsl:template>
  <xsl:template match="Field" mode="value">
    RTRIM([<xsl:value-of select="@Column_Name" />])
  </xsl:template>
  <xsl:template match="Field[@dataType='text' or @dataType='ntext']" mode="text">
    ISNULL(RTRIM(CONVERT(nvarchar(MAX),[<xsl:value-of select="@Column_Name" />])),'')
  </xsl:template>
  <xsl:template match="Field[@dataType='text' or @dataType='ntext']" mode="value">
    RTRIM(CONVERT(nvarchar(MAX),[<xsl:value-of select="@Column_Name" />]))
  </xsl:template>
  <xsl:template match="Field[@dataType='varbinary']" mode="text">
    CASE WHEN NOT [<xsl:value-of select="@Column_Name" />] IS NULL THEN '*********************' ELSE '' END
  </xsl:template>
  <xsl:template match="Field[@dataType='varbinary']" mode="value">'*********************'</xsl:template>
  <xsl:template match="Field[@dataType='char' or @dataType='nchar' or @dataType='nvarchar' or @dataType='varchar' or @dataType='int' or @dataType='tinyint' or @dataType='float' or @dataType='real' or @dataType='numeric' or @dataType='decimal' or @dataType='bit']" mode="text">
    ISNULL(RTRIM([<xsl:value-of select="@Column_Name" />]), '')
  </xsl:template>
  <xsl:template match="Field[@dataType='char' or @dataType='nchar' or @dataType='nvarchar' or @dataType='varchar' or @dataType='int' or @dataType='tinyint' or @dataType='float' or @dataType='real' or @dataType='numeric' or @dataType='decimal' or @dataType='bit']" mode="value">
    RTRIM([<xsl:value-of select="@Column_Name" />])
  </xsl:template>
  <xsl:template match="Field[@dataType='foreignKey']" mode="node">
	  <xsl:param name="baseTable"/>
	  ( SELECT TOP 1 * FROM <xsl:apply-templates mode="node" select="ForeignTable[1]">
		  <xsl:with-param name="baseTable" select="$baseTable"/>
	  </xsl:apply-templates> FOR XML AUTO, TYPE )
  </xsl:template>
  <xsl:template match="Field[@dataType='foreignKey']" mode="text">
	  <xsl:param name="baseTable"/>
	  <xsl:param name="prefix" />
    ISNULL(STUFF(CONVERT(nvarchar(MAX), <xsl:apply-templates mode="node" select=".">
		<xsl:with-param name="baseTable" select="$baseTable"/>
	</xsl:apply-templates>.query('for $item in //*[@text] order by count($item/*) ascending, empty($item/@sortOrder) ascending, number($item/@sortOrder) ascending return concat(''//'',data($item/@text))')),1,2,''),'')
  </xsl:template>
  <xsl:template match="Field[@dataType='foreignKey']" mode="value">
    [<xsl:value-of select="@Column_Name" />]
  </xsl:template>
  <xsl:template match="Field[@dataType='junctionTable']/Table/*/Field[@isPrimaryKey=1 and @dataType='foreignKey']" mode="text">
    <xsl:param name="prefix" />
    [@linkedText]
  </xsl:template>
  <xsl:template match="Field[@dataType='junctionTable' or @dataType='foreignTable']" mode="text">
    'Ver...'
  </xsl:template>
  <xsl:template match="Field[@dataType='junctionTable' or @dataType='foreignTable']" mode="value">
    NULL
  </xsl:template>
  <xsl:template match="Field[@format='money']" mode="text">
    CASE WHEN [<xsl:value-of select="@Column_Name" />]&lt;0 THEN '($'+LTRIM(CONVERT(nchar(14), -[<xsl:value-of select="@Column_Name" />], 1))+')' ELSE '$'+PARSENAME(CONVERT(nvarchar(MAX), CONVERT(money, [<xsl:value-of select="@Column_Name" />]), 1),2)+'.'+PARSENAME(CONVERT(decimal(20,<xsl:choose>
      <xsl:when test="@decimalPositions">
        <xsl:value-of select="@decimalPositions" />
      </xsl:when>
      <xsl:otherwise>3</xsl:otherwise>
    </xsl:choose>),[<xsl:value-of select="@Column_Name" />]) % 1,1) END
  </xsl:template>
  <xsl:template match="Field[@format='money']" mode="value">
    CONVERT(decimal(20,<xsl:choose>
      <xsl:when test="@decimalPositions">
        <xsl:value-of select="@decimalPositions" />
      </xsl:when>
      <xsl:otherwise>3</xsl:otherwise>
    </xsl:choose>),[<xsl:value-of select="@Column_Name" />])
  </xsl:template>
  <xsl:template match="Field[@dataType='money' or @dataType='smallmoney']" mode="text">
    CASE WHEN [<xsl:value-of select="@Column_Name" />]&lt;0 THEN '($'+LTRIM(CONVERT(nchar(14), -[<xsl:value-of select="@Column_Name" />], 1))+')' ELSE '$'+PARSENAME(CONVERT(nvarchar(MAX), CONVERT(money, [<xsl:value-of select="@Column_Name" />]), 1),2)+'.'+PARSENAME(CONVERT(decimal(20,<xsl:choose>
      <xsl:when test="@decimalPositions">
        <xsl:value-of select="@decimalPositions" />
      </xsl:when>
      <xsl:otherwise>3</xsl:otherwise>
    </xsl:choose>),[<xsl:value-of select="@Column_Name" />]) % 1,1) END
  </xsl:template>
  <xsl:template match="Field[@dataType='money' or @dataType='smallmoney']" mode="value">
    /*ISNULL(*/[<xsl:value-of select="@Column_Name" />]/*, '')*/
  </xsl:template>
  <xsl:template match="Field[@dataType='date' or @dataType='datetime' or @dataType='smalldatetime']" mode="text">ISNULL(RTRIM(CONVERT(nchar(25), [<xsl:value-of select="@Column_Name" />], 103)),'') /*+' '+ [$Date].Time([<xsl:value-of select="@Column_Name" />])*/
  </xsl:template>
  <xsl:template match="Field[@dataType='date' or @dataType='datetime' or @dataType='smalldatetime']" mode="value">
    RTRIM(CONVERT(nchar(25), convert(datetime,[<xsl:value-of select="@Column_Name" />]), 120))<!-- , [<xsl:value-of select="@Column_Name"/>/@YYYYMMDD]=CONVERT(VARCHAR(8), [<xsl:value-of select="@Column_Name"/>], 112) -->
  </xsl:template>
  <xsl:template match="Field[@dataType='time']" mode="text">
    [$Date].Time([<xsl:value-of select="@Column_Name" />])
  </xsl:template>
  <xsl:template match="Field[@dataType='time']" mode="value">
	[$Date].Time([<xsl:value-of select="@Column_Name" />])<!--RTRIM(DATEPART(HOUR,[<xsl:value-of select="@Column_Name" />]))+':'+RTRIM(DATEPART(MINUTE,[<xsl:value-of select="@Column_Name" />]))-->
  </xsl:template>
  <xsl:template match="Table/*/Field[@dataType='time']" mode="value">
	[$Date].Time([<xsl:value-of select="@Column_Name" />])<!--RTRIM(DATEPART(HOUR,[<xsl:value-of select="@Column_Name" />]))+':'+RTRIM(DATEPART(MINUTE,[<xsl:value-of select="@Column_Name" />]))-->
  </xsl:template>
  <xsl:template match="PrimaryKeys" mode="dataValue"><xsl:for-each select="PrimaryKey">
      <xsl:if test="position()&gt;1">' '+</xsl:if>RTRIM([<xsl:value-of select="@Column_Name" />])</xsl:for-each></xsl:template>
  <xsl:template match="@primaryKey" mode="dataValue">RTRIM([<xsl:value-of select="." />])</xsl:template>
  <xsl:template mode="node" match="Field[@dataType='xml']" />
  
  
  
  
  <xsl:template mode="node" match="*/ForeignTable">
	<xsl:param name="baseTable"/>
	<xsl:param name="table" select="key('ForeignTable',generate-id(ancestor-or-self::ForeignTable[1]))" />
    <xsl:param name="mode" />
    <xsl:param name="scope" />
	<xsl:param name="loadData" />
    <xsl:variable name="foreignKeys" select="key('ForeignKeys', generate-id(.))" />
    <xsl:variable name="selfReferenced" select="@Table_Name=ancestor::ForeignTable[1]/@Table_Name" />
    <xsl:if test="$selfReferenced">
      /*self:<xsl:value-of select="ancestor::ForeignTable[1]/@Table_Name" />::<xsl:value-of select="@Table_Name" />: <xsl:value-of select="$selfReferenced" />*/
    </xsl:if>
    <xsl:if test="string($mode)='data'">
      <xsl:apply-templates mode="node" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))">
		  <xsl:with-param name="baseTable" select="$baseTable"/>
		  <xsl:with-param name="mode" select="$mode"/>
		  <xsl:with-param name="loadData" select="$loadData" />
		  <xsl:with-param name="scope" select="$scope" />
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="not($selfReferenced)">
      (
      SELECT <xsl:choose>
        <xsl:when test="name(..)='Field'">
          [fieldId]='<xsl:value-of select="generate-id(.)" />', [fieldName]='<xsl:value-of select="../@Column_Name" />',
        </xsl:when>
        <xsl:when test="../@binding">
          <xsl:variable name="binding" select="../@binding" />[fieldId]='<xsl:value-of select="generate-id(ancestor::Table[1]/*[local-name(.)='Fields' or local-name(.)='Record']/*[@Column_Name=$binding])" />'
          ,[fieldName]='<xsl:value-of select="$binding" />',
        </xsl:when>
      </xsl:choose>sortOrder, text=ISNULL(text, '- -'), value, foreignValue<xsl:if test="not(string($mode)='data')">
        , foreignKey=<xsl:choose>
          <xsl:when test="$foreignKeys">
            '<xsl:value-of select="$foreignKeys/@Column_Name" />'
          </xsl:when>
          <xsl:otherwise>NULL</xsl:otherwise>
        </xsl:choose><xsl:if test="@Table_Name=key('ForeignTable',generate-id($foreignKeys/ForeignTable))/@Table_Name">, referencesItself='true'</xsl:if>, dataText='RTRIM(<xsl:call-template name="escape-apos">
          <xsl:with-param name="string">
            <xsl:value-of select="@text" />
          </xsl:with-param>
        </xsl:call-template>)', dataValue='<xsl:apply-templates select="@primaryKey" mode="dataValue" />' <xsl:apply-templates select="../@binding" mode="Attributes">
          <xsl:with-param name="mode" select="'elements'" />
        </xsl:apply-templates>,
        primaryKey='<xsl:value-of select="@primaryKey" />'<xsl:if test="../@mode[substring(string(.), 1, 10)!='CASE WHEN ']">
          <xsl:apply-templates select="../@mode" mode="Attributes">
            <xsl:with-param name="mode" select="'elements'" />
          </xsl:apply-templates>
        </xsl:if>, headerText=<xsl:choose>
          <xsl:when test="@headerText">
            '<xsl:value-of select="@headerText" />'
          </xsl:when>
          <xsl:otherwise>
            [$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Table_Name" />', '_', ' ', 1))
          </xsl:otherwise>
        </xsl:choose><xsl:apply-templates mode="Attributes" select="@*[not(substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')')][not(name(.)='primaryKey' or name(.)='text' or name(.)='displayText' or name(.)='headerText' or name(.)='mode')]">
          <xsl:with-param name="mode" select="'elements'" />
        </xsl:apply-templates>
      </xsl:if><xsl:choose>
        <xsl:when test="string($mode)='data'">
          <xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
            <xsl:with-param name="mode" select="'elements'" />
            <xsl:with-param name="withValue" select="false()" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
            <xsl:with-param name="mode" select="'elements'" />
            <xsl:with-param name="escape" select="true()" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose><xsl:if test="string($mode)!='data' and not(@disableInsert)">
        <!--,[disableInsert]=[$Privileges].[$C]-1-->
      </xsl:if>
      FROM
      (	SELECT sortOrder=0, text=NULL, value=NULL, foreignValue=<xsl:choose>
        <xsl:when test="string($mode)!='fields' and $foreignKeys/@defaultValue">
          CASE WHEN [#primaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />] IS NULL THEN <xsl:value-of select="$foreignKeys/@defaultValue" /> ELSE NULL END
        </xsl:when>
        <xsl:otherwise>NULL</xsl:otherwise>
      </xsl:choose><xsl:if test="string($mode)='data'">
        <xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
          <xsl:with-param name="mode" select="'elements'" />
          <xsl:with-param name="value">NULL</xsl:with-param>
        </xsl:apply-templates>
      </xsl:if><xsl:if test="1=0 or string($mode)!='fields'">
        <xsl:if test="string($scope)!='fields' and not(ancestor::ForeignTable[1])">
          WHERE (SELECT COUNT(1) FROM [<xsl:value-of select="@Table_Schema" />].[<xsl:value-of select="@Table_Name" />])=0 OR [#primaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />] IS NULL
        </xsl:if> UNION ALL
        SELECT sortOrder=ROW_NUMBER() OVER (ORDER BY <xsl:choose>
          <xsl:when test="@orderBy">
            <xsl:value-of select="@orderBy" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="not(@displayText!='')">
                <xsl:value-of select="@text" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@displayText" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>), text=RTRIM(<xsl:choose>
          <xsl:when test="not(@displayText!='')">
            <xsl:value-of select="@text" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@displayText" />
          </xsl:otherwise>
        </xsl:choose>), value=<xsl:apply-templates select="@primaryKey" mode="dataValue" />, foreignvalue=<xsl:choose>
          <xsl:when test="$foreignKeys">
            RTRIM([<xsl:value-of select="$foreignKeys/@Column_Name" />])
          </xsl:when>
          <xsl:otherwise>NULL</xsl:otherwise>
        </xsl:choose><xsl:if test="string($mode)='data'">
          <xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
            <xsl:with-param name="mode" select="'elements'" />
          </xsl:apply-templates>
        </xsl:if> FROM [<xsl:value-of select="@Table_Schema" />].[<xsl:value-of select="@Table_Name" />] [$Table]/*scope: <xsl:value-of select="$scope" />*/<xsl:if test="string($scope)!='fields'">
          <xsl:if test="not(ancestor::ForeignTable[1])">
            WHERE (<xsl:if test="string($mode)='data'">
              (<xsl:choose>
                <xsl:when test="string(@filters)!=''">
                  EXISTS(SELECT 1 FROM @@Privileges [#Privileges] WHERE /*[#Privileges].[$UserId]=@@UserId AND */(<xsl:value-of select="@filters" />))
                </xsl:when>
                <xsl:otherwise>1=<xsl:choose>
                  <xsl:when test="string($loadData)!='true'">0/*<xsl:value-of select="$loadData"/>*/</xsl:when>
                  <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose></xsl:otherwise>
              </xsl:choose>) OR
            </xsl:if> [#primaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />]=/*[<xsl:value-of select="@Table_Name" />]*/[$Table].[<xsl:value-of select="@primaryKey" />])
          </xsl:if>
        </xsl:if>
      </xsl:if>
      ) [<xsl:value-of select="@Table_Name" />] <!--CROSS JOIN (SELECT TOP 1 [$C], [$R], [$U], [$D], [$S] FROM [#Privileges] WHERE /*[#Privileges].[$UserId]=@@UserId AND */[#Privileges].[$SchemaName]='<xsl:value-of select="@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="@Table_Name" />' AND [#Privileges].[$R]=1) [$Privileges]-->
      ) [<xsl:value-of select="@Table_Name" /><xsl:if test="ancestor::ForeignTable[@Table_Name=current()/@Table_Name]">
        _<xsl:value-of select="count(ancestor::ForeignTable[@Table_Name=current()/@Table_Name])" />
      </xsl:if>]
    </xsl:if> 
    <xsl:choose>
      <xsl:when test="string($mode)='data' and $foreignKeys">
        <xsl:variable name="fkNode" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))" />
        <xsl:variable name="fkName">
          <xsl:value-of select="$fkNode/@Table_Name" />
          <xsl:if test="$fkNode[@Table_Name=current()/@Table_Name]">
            _<xsl:value-of select="count($fkNode[@Table_Name=current()/@Table_Name]/ancestor::ForeignTable[@Table_Name=current()/@Table_Name])" />
          </xsl:if>
        </xsl:variable>
        <xsl:if test="not($fkNode[@Table_Name=current()/@Table_Name])">
          ON [<xsl:value-of select="$fkName" />].value=[<xsl:value-of select="ancestor-or-self::ForeignTable[1]/@Table_Name" />].foreignValue OR [<xsl:value-of select="$fkName" />].value IS NULL AND [<xsl:value-of select="key('ForeignTable',generate-id(ancestor-or-self::ForeignTable[1]))/@Table_Name" />].foreignValue IS NULL
        </xsl:if>
      </xsl:when>
      <xsl:when test="not(string($mode)='data') and ancestor::ForeignTable[1]">
        <xsl:if test="not($selfReferenced)">
          ON [<xsl:value-of select="@Table_Name" /><xsl:if test="ancestor::ForeignTable[@Table_Name=current()/@Table_Name]">
            _<xsl:value-of select="count(ancestor::ForeignTable[@Table_Name=current()/@Table_Name])" />
          </xsl:if>].value=[<xsl:value-of select="ancestor::ForeignTable[1]/@Table_Name" />].foreignValue OR [<xsl:value-of select="@Table_Name" /><xsl:if test="ancestor::ForeignTable[@Table_Name=current()/@Table_Name]">
            _<xsl:value-of select="count(ancestor::ForeignTable[@Table_Name=current()/@Table_Name])" />
          </xsl:if>].value IS NULL AND [<xsl:value-of select="ancestor::ForeignTable[1]/@Table_Name" />].foreignValue IS NULL
        </xsl:if>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="not(string($mode)='data') and $foreignKeys">
        <xsl:if test="not(@Table_Name=key('ForeignTable',generate-id($foreignKeys/ForeignTable))/@Table_Name)">LEFT OUTER JOIN/*ft1*/ </xsl:if>
        <xsl:apply-templates mode="node" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))">
			<xsl:with-param name="baseTable" select="$baseTable"/>
          <xsl:with-param name="scope" select="$scope" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="string($mode)='data' and ancestor::ForeignTable[1]">
        <xsl:if test="not($selfReferenced)">LEFT OUTER JOIN/*ft2*/</xsl:if>
      </xsl:when>
      <xsl:when test="string($mode)='data' and not(ancestor::ForeignTable[1]) and not(@orderBy)">
        ORDER BY <xsl:apply-templates select="." mode="foreignTable.sortOrder" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="foreignTable.sortOrder" match="ForeignTable">
    <xsl:apply-templates mode="foreignTable.sortOrder" select="key('ForeignKeys', generate-id(.))/ForeignTable" />
    <xsl:if test="not(ancestor::ForeignTable[1][@Table_Name=current()/@Table_Name])">
      [<xsl:value-of select="@Table_Name" /><xsl:if test="ancestor::ForeignTable[@Table_Name=current()/@Table_Name]">
        _<xsl:value-of select="count(ancestor::ForeignTable[@Table_Name=current()/@Table_Name])" />
      </xsl:if>].sortOrder<xsl:if test="name(..)='ForeignKey'">,</xsl:if>
    </xsl:if>
  </xsl:template>
  <xsl:template name="sortColumns">
    <xsl:param name="testColumn" />
    <xsl:param name="table" select="ancestor-or-self::Table[1]" />
    <xsl:choose>
      <xsl:when test="$table/../@dataType='junctionTable'">
      [@linkedOrder],[@linkedText]<xsl:if test="key('sortableColumns', generate-id(.))">,</xsl:if>
    </xsl:when>
      <xsl:when test="count(key('sortableColumns', generate-id(.)))=0">
      [@identity]
      <!--<xsl:for-each select="*[name(.)='Fields' or name(.)='Record']/*[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey' or @Column_Name=$table/@identityKey)]">
        <xsl:sort select="number(boolean(@sortOrder))" order="descending" />
        <xsl:sort select="@sortOrder" data-type="number" order="ascending" />
        <xsl:sort select="@isIdentity" data-type="number" order="ascending" />
        <xsl:sort select="@isNullable" data-type="number" order="ascending" />
        <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
        <xsl:if test="position()=1">
          [<xsl:value-of select="@Column_Name"/>]
        </xsl:if>
      </xsl:for-each>-->
    </xsl:when>
    </xsl:choose>
    <xsl:for-each select="key('sortableColumns', generate-id(.))">
      <xsl:sort select="number(boolean(@sortOrder))" order="descending" />
      <xsl:sort select="@sortOrder" data-type="number" order="ascending" />
      <xsl:sort select="@isIdentity" data-type="number" order="ascending" />
      <xsl:sort select="@isNullable" data-type="number" order="ascending" />
      <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
      <xsl:if test="@sortOrder or position()=1">
        <xsl:choose>
          <xsl:when test="string($testColumn)=string(@Column_Name)">1</xsl:when>
          <xsl:when test="string($testColumn)!=''">0</xsl:when>
          <xsl:otherwise>
            <xsl:if test="position()&gt;1">,</xsl:if>
            <xsl:choose>
              <xsl:when test="@isIdentity=1">[@identity]</xsl:when>
              <xsl:otherwise>
                [<xsl:value-of select="@Column_Name" />]
              </xsl:otherwise>
            </xsl:choose>
            <!-- </xsl:when><xsl:otherwise>[$Tools].OrderByString([<xsl:value-of select="@Column_Name"/>])</xsl:otherwise></xsl:choose> -->
            <xsl:if test="@sortDirection">
              <xsl:value-of select="concat(' ', @sortDirection)" />
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="Table/Fields|Table/Record" mode="columns">
	  <xsl:param name="baseTable"/>
    <xsl:param name="unBindPrimaryTable" select="false()" />
    /*level: columns*/
    [@identity]
    ,[@primaryValue]
    ,[@referenceValue]
    ,[@mode]
    <xsl:for-each select="key('availableFields', generate-id(..))[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='identity')][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
      <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />/*field <xsl:value-of select="@Column_Name" />: <xsl:value-of select="@dataType" />*/
      <xsl:variable name="fieldName">
        <xsl:value-of select="@Column_Name" />
      </xsl:variable>
      ,[<xsl:value-of select="$fieldName" />/@fieldId]='<xsl:value-of select="generate-id(.)" />'
      ,[<xsl:value-of select="$fieldName" />/@value]=<xsl:choose>
        <xsl:when test="@dataType='foreignKey'" />
        <xsl:otherwise />
      </xsl:choose>RTRIM(ISNULL(<xsl:apply-templates select="." mode="value" />,''))
      <xsl:if test="not(ancestor::*[@mode='fieldselector' or @mode='help'])">
      ,[<xsl:value-of select="$fieldName" />/@text]=<xsl:apply-templates select="." mode="text" /><xsl:if test="@dataType='foreignKey' and not(key('fieldbound', generate-id())) and (1=1 or ForeignTable[@Name=ForeignKeys/ForeignKey[string(@scaffold)!='false' and string(@mode)!='none']/ForeignTable/@Name] or ((@loadData='true')))">
		  <xsl:if test="not(ancestor::*[@dataType='junctionTable']) and (@loadData='true' or ForeignTable/@Table_Name=ForeignTable/ForeignKeys/ForeignKey[@scaffold='true']/ForeignTable/@Table_Name)"><!--<xsl:if test="@loadData='true' and ../../@controlType='formView' and not(../../../@dataType='junctionTable')">--><!-- incluir el schema o cambiar por el object_id -->
          ,[<xsl:value-of select="$fieldName" />/px:data]=( SELECT * FROM <xsl:apply-templates mode="node" select="key('ForeignTable', generate-id(ForeignTable[1]))">
			  <xsl:with-param name="baseTable" select="$baseTable"/>
			  <xsl:with-param name="mode">data</xsl:with-param>
			  <xsl:with-param name="loadData">true</xsl:with-param>
          </xsl:apply-templates> FOR XML AUTO, TYPE )
        </xsl:if>
        ,[<xsl:value-of select="$fieldName" />]=<xsl:apply-templates mode="node" select=".">
			<xsl:with-param name="baseTable" select="$baseTable"/>
		</xsl:apply-templates>
      </xsl:if>
       </xsl:if>
    </xsl:for-each>
    /*fin level: columns*/
  </xsl:template>
  <xsl:template match="Table/Fields|Table/Record" mode="columnValues">
	  <xsl:param name="baseTable"/>
	  <xsl:param name="mode" />
    <xsl:param name="unBindPrimaryTable" />
    /*1st level: <xsl:value-of select="$mode" />*/
    [@identity]=<xsl:choose>
      <xsl:when test="$mode='phantom' or $baseTable/@mode='insert' or $baseTable/@mode='filters' or $baseTable/@mode='fieldselector' or $baseTable/@mode='help'">NULL</xsl:when>
      <xsl:when test="../@identityKey">
        [$Table].[<xsl:value-of select="../@identityKey" />]
      </xsl:when>
      <xsl:otherwise>NULL</xsl:otherwise>
    </xsl:choose>
    ,[@primaryValue]=<xsl:choose>
      <xsl:when test="$mode='phantom' or $baseTable/@mode='insert' or $baseTable/@mode='filters' or $baseTable/@mode='fieldselector' or $baseTable/@mode='help'">NULL</xsl:when>
      <xsl:when test="../PrimaryKeys">
        <xsl:for-each select="../PrimaryKeys/PrimaryKey">
          <xsl:if test="position()&gt;1">+' '+</xsl:if>RTRIM([$Table].[<xsl:value-of select="@Column_Name" />])
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>NULL</xsl:otherwise>
    </xsl:choose>
    ,[@referenceValue]=<xsl:choose>
      <xsl:when test="key('RequestedTable', generate-id(current())) and ancestor-or-self::Field[1]">[#primaryTable].[@primaryValue]</xsl:when>
      <xsl:otherwise>NULL</xsl:otherwise>
    </xsl:choose>
    ,[@mode]=<xsl:choose>
      <xsl:when test="$baseTable/@mode='insert' or $baseTable/@mode='filters' or $baseTable/@mode='fieldselector' or $baseTable/@mode='help'">
        '<xsl:value-of select="$baseTable/@mode" />'
      </xsl:when>
      <xsl:when test="string(@mode)!=''">
        <xsl:apply-templates select="@mode" mode="Property.Value" />
      </xsl:when>
      <xsl:otherwise>'inherit'</xsl:otherwise>
    </xsl:choose><xsl:for-each select="@*[not(name(.)='mode')][not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='foreignKey')][not(contains(.,'.value(') or contains(.,'.query(') or contains(.,'[$Field].'))]">
      ,[@<xsl:value-of select="name(.)" />]=<xsl:apply-templates select="current()" mode="Property.Value" />
    </xsl:for-each><xsl:for-each select="key('availableFields', generate-id(..))[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='identity')][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
      <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" /><xsl:if test="../../../@dataType='junctionTable' and @isPrimaryKey=1 and ForeignTable/@text and count(preceding-sibling::*[@isPrimaryKey=1])&lt;=1">
		  ,[@linkedText]=[$Linked].[$displayText]<!--<xsl:choose>
		  <xsl:when test="string($baseTable/@mode)!='edit'">NULL</xsl:when>
		  <xsl:otherwise>[$Linked].[$displayText]</xsl:otherwise>
	  </xsl:choose>--></xsl:if><xsl:if test="../../../@dataType='junctionTable' and @isPrimaryKey=1 and count(preceding-sibling::*[@isPrimaryKey=1])&lt;=1">
        ,[@linkedOrder]=<xsl:choose>
          <xsl:when test="ForeignTable/@orderBy">
            ROW_NUMBER() OVER(ORDER BY <xsl:value-of select="ForeignTable/@orderBy" />)
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      ,[<xsl:value-of select="@Column_Name" />]=<xsl:choose>
        <xsl:when test="$baseTable/@mode='insert' and $mode='phantom'">
          <xsl:choose>
            <xsl:when test="@defaultValue">
              <xsl:apply-templates select="@defaultValue" mode="Property.Value" />
            </xsl:when>
            <xsl:otherwise>NULL</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$unBindPrimaryTable and key('primaryReference', generate-id())/@dataType='junctionTable'">NULL</xsl:when>
            <xsl:when test="key('primaryReference', generate-id())/@dataType='junctionTable' and key('foreignReference', generate-id())">[#primaryTable].[@primaryValue]</xsl:when>
            <xsl:when test="ancestor::Table[1]/../@dataType='junctionTable' and key('primaryKey', generate-id())[not(key('foreignReference', generate-id(.)))]">
              [$Linked].[<xsl:value-of select="ForeignTable/@primaryKey" />]
            </xsl:when>
            <xsl:when test="$baseTable/@mode='fieldselector' or $baseTable/@mode='help'">NULL</xsl:when>
			  <xsl:when test="@dataType='junctionTable' or @dataType='foreignTable' or key('mode', generate-id(.))/@mode='insert' or $baseTable/@mode='filters'">NULL</xsl:when>
			  <xsl:when test="$mode='phantom'">NULL</xsl:when>
			  <xsl:otherwise>
              [$Table].[<xsl:value-of select="@Column_Name" />]
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="Table/Fields|Table/Record" mode="foreignTables">
	<xsl:param name="baseTable"/>
    <xsl:param name="scope" />
    <xsl:for-each select="key('availableFields', generate-id(..))[@dataType='foreignTable' or @dataType='junctionTable'][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
		<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
		<xsl:variable name="repeatedColumns">
			<xsl:value-of select="count(preceding-sibling::*[@Column_Name=current()/@Column_Name])"/>
		</xsl:variable>
		<xsl:variable name="fieldName">
			<xsl:value-of select="@Column_Name" />
			<xsl:if test="$repeatedColumns&gt;0"><xsl:value-of select="$repeatedColumns"/></xsl:if>
		</xsl:variable>
      ,[<xsl:value-of select="$fieldName" />/@fieldId]='<xsl:value-of select="generate-id(.)" />'<xsl:if test="@mode[substring(string(.), 1, 10)!='CASE WHEN ']">
        ,[<xsl:value-of select="$fieldName" />/@mode]=[@mode]
      </xsl:if><xsl:apply-templates mode="Attributes" select="ancestor-or-self::*[@fieldSet][1]/@fieldSet|@*[substring(string(.), 1, 10)='CASE WHEN ']">
        <xsl:with-param name="Column_Name" select="@Column_Name" />
      </xsl:apply-templates><xsl:choose>
        <xsl:when test="(@dataType='foreignTable' or @dataType='junctionTable') and (ancestor-or-self::*[@mode!='inherit'][1]/@mode!='none' or (@controlType='inlineTable' or @controlType='embeddedTable')) and *">
          ,[<xsl:value-of select="$fieldName" />]=( <xsl:apply-templates mode="node" select="*">
			  <xsl:with-param name="baseTable" select="$baseTable"/>
            <xsl:with-param name="scope" select="$scope" />
          </xsl:apply-templates>)
        </xsl:when>
        <xsl:when test="(@dataType='foreignTable' or @dataType='junctionTable')">
          , [<xsl:value-of select="$fieldName" />]=CONVERT(xml, NULL)
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <xsl:template mode="groupName" match="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer">/px:<xsl:value-of select="name(.)" /></xsl:template>
  <xsl:template mode="groupAttributes" match="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet">
    ,[px:<xsl:value-of select="name(.)" />/@name='<xsl:value-of select="." />'
  </xsl:template>
  <xsl:template match="@fieldContainer" mode="container.attributes">
    <!-- Sólo para cabezas de grupo -->
    <xsl:param name="prefix" />
    <xsl:variable name="container" select="." />
	<xsl:variable name="headerText" select="../@*[starts-with(local-name(.), concat(local-name($container),'.headerText'))]" />  
	  <xsl:if test="not($headerText)">
		,[<xsl:value-of select="$prefix" />/@headerText]=@resx.value('(root/data[@name=''../<xsl:value-of select="local-name($container)" />("<xsl:value-of select="." />")'']/value)[1]','nvarchar(255)')
	  </xsl:if>
	<xsl:for-each select="$headerText|../@*[starts-with(local-name(.), concat(local-name($container),'.'))]">
      ,[<xsl:value-of select="$prefix" />/@<xsl:call-template name="replace">
        <xsl:with-param name="inputString" select="name(.)" />
        <xsl:with-param name="searchText" select="concat(name($container),'.')" />
        <xsl:with-param name="replaceBy" />
      </xsl:call-template>]='<xsl:value-of select="." />'
	</xsl:for-each>
  </xsl:template>



  <xsl:template match="Table/*[local-name(.)='Fields' or local-name(.)='Record']/Field" mode="tree">
    <xsl:param name="caller" />
    <xsl:param name="trigger" />
    <xsl:param name="continueNextSibling" select="true()"  />
    <xsl:variable name="currentField" select="."/>
    <xsl:apply-templates mode="tree" select="key('allFields', generate-id(../..))[not(key('foreignReference', generate-id()))][@moveBefore=$currentField/@Column_Name][not(@moveAfter)]">
      <xsl:with-param name="caller" select="current()" />
      <xsl:with-param name="trigger" select="concat(@Column_Name,'/moveBefore')" />
      <xsl:with-param name="continueNextSibling" select="false()" />
    </xsl:apply-templates>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="fieldId">
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
    </xsl:copy>
    <xsl:apply-templates mode="tree" select="../*[@moveAfter=$currentField/@Column_Name or $currentField/@fieldContainer and not($currentField/@fieldContainer=$currentField/preceding-sibling::*/@fieldContainer) and @fieldContainer=$currentField/@fieldContainer and generate-id()!=generate-id($currentField)]">
      <xsl:with-param name="caller" select="current()" />
      <xsl:with-param name="trigger" select="concat(@Column_Name,'/moveAfter')" />
      <xsl:with-param name="continueNextSibling" select="false()" />
    </xsl:apply-templates>
    <xsl:apply-templates mode="tree" select="self::*[$continueNextSibling][not(@moveBefore or @moveAfter or @fieldContainer and string(@fieldContainer)=string(preceding-sibling::*/@fieldContainer))]/following-sibling::*[key('allFields', generate-id(.))][not(key('foreignReference', generate-id()))][not(@moveBefore or @moveAfter)][not(@fieldContainer) or @fieldContainer and not(@fieldContainer=preceding-sibling::*[key('allFields', generate-id(.))]/@fieldContainer)][1]">
      <xsl:with-param name="caller" select="current()" />
      <xsl:with-param name="trigger" select="concat(@Column_Name,'/following-sibling')" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*" mode="groups">
    <xsl:param name="paramGroupTabPanel" />
    <xsl:param name="paramSubGroupTabPanel" />
    <xsl:param name="paramPortlet" />
    <xsl:param name="paramTabPanel" />
    <xsl:param name="paramTab" />
    <xsl:param name="paramFieldSet" />
    <xsl:param name="paramFieldContainer" />

    <xsl:variable name="lastNode" select="preceding-sibling::*[1]" />
    <xsl:variable name="lastNodeGroups">
      <xsl:element name="groups">
        <xsl:choose>
          <xsl:when test="$lastNode/@groupTabPanel">
            <xsl:copy-of select="$lastNode/@groupTabPanel" />
          </xsl:when>
          <xsl:when test="$paramGroupTabPanel">
            <xsl:copy-of select="$paramGroupTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@subGroupTabPanel">
            <xsl:copy-of select="$lastNode/@subGroupTabPanel" />
          </xsl:when>
          <xsl:when test="$paramSubGroupTabPanel">
            <xsl:copy-of select="$paramSubGroupTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@portlet!=''">
            <xsl:copy-of select="$lastNode/@portlet" />
          </xsl:when>
          <xsl:when test="$paramPortlet!=''">
            <xsl:copy-of select="$paramPortlet" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@tabPanel">
            <xsl:copy-of select="$lastNode/@tabPanel" />
          </xsl:when>
          <xsl:when test="$paramTabPanel">
            <xsl:copy-of select="$paramTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@tab">
            <xsl:copy-of select="$lastNode/@tab" />
          </xsl:when>
          <xsl:when test="$paramTab">
            <xsl:copy-of select="$paramTab" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@fieldSet">
            <xsl:copy-of select="$lastNode/@fieldSet" />
          </xsl:when>
          <xsl:when test="$paramFieldSet">
            <xsl:copy-of select="$paramFieldSet" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$lastNode/@fieldContainer">
            <xsl:copy-of select="$lastNode/@fieldContainer" />
          </xsl:when>
          <xsl:when test="$paramFieldContainer">
            <xsl:copy-of select="$paramFieldContainer" />
          </xsl:when>
        </xsl:choose>
      </xsl:element>
    </xsl:variable>
    <xsl:variable name="changeGroupTabPanel" select="(string(msxsl:node-set($lastNodeGroups)/*/@groupTabPanel)!=@groupTabPanel or  string(msxsl:node-set($lastNodeGroups)/*/@groupTabPanel)!=$paramGroupTabPanel )" />
    <xsl:variable name="changeSubGroupTabPanel" select="($changeGroupTabPanel or string(msxsl:node-set($lastNodeGroups)/*/@subGroupTabPanel)!=@subGroupTabPanel or  string(msxsl:node-set($lastNodeGroups)/*/@subGroupTabPanel)!=$paramSubGroupTabPanel )" />
    <xsl:variable name="changePortlet" select="($changeSubGroupTabPanel or string(msxsl:node-set($lastNodeGroups)/*/@portlet)!=@portlet or  string(msxsl:node-set($lastNodeGroups)/*/@portlet)!=$paramPortlet )" />
    <xsl:variable name="changeTabPanel" select="($changePortlet or string(msxsl:node-set($lastNodeGroups)/*/@tabPanel)!=@tabPanel or  string(msxsl:node-set($lastNodeGroups)/*/@tabPanel)!=$paramTabPanel )" />
    <xsl:variable name="changeTab" select="($changeTabPanel or string(msxsl:node-set($lastNodeGroups)/*/@tab)!=@tab or  string(msxsl:node-set($lastNodeGroups)/*/@tab)!=$paramTab )" />
    <xsl:variable name="changeFieldSet" select="($changeTab or string(msxsl:node-set($lastNodeGroups)/*/@fieldSet)!=@fieldSet or  string(msxsl:node-set($lastNodeGroups)/*/@fieldSet)!=$paramFieldSet )" />
    <xsl:variable name="changeFieldContainer" select="($changeFieldSet or string(msxsl:node-set($lastNodeGroups)/*/@fieldContainer)!=@fieldContainer or  string(msxsl:node-set($lastNodeGroups)/*/@fieldContainer)!=$paramFieldContainer )" />
    <xsl:variable name="groups">
      <xsl:element name="groups">
        <xsl:choose>
          <xsl:when test="@groupTabPanel=''" />
          <xsl:when test="$changeGroupTabPanel or @groupTabPanel">
            <xsl:copy-of select="@groupTabPanel" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@groupTabPanel">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@groupTabPanel" />
          </xsl:when>
          <xsl:when test="$paramGroupTabPanel">
            <xsl:copy-of select="$paramGroupTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@subGroupTabPanel=''" />
          <xsl:when test="$changeSubGroupTabPanel or @subGroupTabPanel">
            <xsl:copy-of select="@subGroupTabPanel" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@subGroupTabPanel">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@subGroupTabPanel" />
          </xsl:when>
          <xsl:when test="$paramSubGroupTabPanel">
            <xsl:copy-of select="$paramSubGroupTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@portlet=''" />
          <xsl:when test="$changePortlet or @portlet">
            <xsl:copy-of select="@portlet" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@portlet!=''">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@portlet" />
          </xsl:when>
          <xsl:when test="$paramPortlet!=''">
            <xsl:copy-of select="$paramPortlet" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@tabPanel=''" />
          <xsl:when test="$changeTabPanel or @tabPanel">
            <xsl:copy-of select="@tabPanel" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@tabPanel">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@tabPanel" />
          </xsl:when>
          <xsl:when test="$paramTabPanel">
            <xsl:copy-of select="$paramTabPanel" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@tab=''" />
          <xsl:when test="$changeTab or @tab">
            <xsl:copy-of select="@tab" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@tab">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@tab" />
          </xsl:when>
          <xsl:when test="$paramTab">
            <xsl:copy-of select="$paramTab" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@fieldSet=''" />
          <xsl:when test="$changeFieldSet or @fieldSet">
            <xsl:copy-of select="@fieldSet" />
          </xsl:when>
          <xsl:when test="msxsl:node-set($lastNodeGroups)/*/@fieldSet">
            <xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@fieldSet" />
          </xsl:when>
          <xsl:when test="$paramFieldSet">
            <xsl:copy-of select="$paramFieldSet" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="@fieldContainer=''" />
          <xsl:when test="$changeFieldContainer or @fieldContainer">
            <xsl:copy-of select="@fieldContainer" />
          </xsl:when>
          <!--<xsl:when test="msxsl:node-set($lastNodeGroups)/*/@fieldContainer"><xsl:copy-of select="msxsl:node-set($lastNodeGroups)/*/@fieldContainer"/></xsl:when><xsl:when test="$paramFieldContainer"><xsl:copy-of select="$paramFieldContainer"/></xsl:when>-->
        </xsl:choose>
      </xsl:element>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*[not(local-name(.)='groupTabPanel' or local-name(.)='subGroupTabPanel' or local-name(.)='portlet' or local-name(.)='tabPanel' or local-name(.)='tab' or local-name(.)='fieldSet' or local-name(.)='fieldContainer')]"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@groupTabPanel"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@subGroupTabPanel"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@portlet"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@tabPanel"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@tab"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@fieldSet"/>
      <xsl:copy-of select="msxsl:node-set($groups)/*/@fieldContainer"/>
      <xsl:if test="$changeGroupTabPanel">
        <xsl:attribute name="changeGroupTabPanel">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changeSubGroupTabPanel">
        <xsl:attribute name="changeSubGroupTabPanel">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changePortlet">
        <xsl:attribute name="changePortlet">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changeTabPanel">
        <xsl:attribute name="changeTabPanel">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changeTab">
        <xsl:attribute name="changeTab">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changeFieldSet">
        <xsl:attribute name="changeFieldSet">1</xsl:attribute>
      </xsl:if>
      <xsl:if test="$changeFieldContainer">
        <xsl:attribute name="changeFieldContainer">1</xsl:attribute>
      </xsl:if>
    </xsl:copy>
    <xsl:apply-templates select="following-sibling::*[1]" mode="groups">
      <xsl:with-param name="paramGroupTabPanel" select="msxsl:node-set($groups)/*/@groupTabPanel" />
      <xsl:with-param name="paramSubGroupTabPanel" select="msxsl:node-set($groups)/*/@subGroupTabPanel" />
      <xsl:with-param name="paramPortlet" select="msxsl:node-set($groups)/*/@portlet" />
      <xsl:with-param name="paramTabPanel" select="msxsl:node-set($groups)/*/@tabPanel" />
      <xsl:with-param name="paramTab" select="msxsl:node-set($groups)/*/@tab" />
      <xsl:with-param name="paramFieldSet" select="msxsl:node-set($groups)/*/@fieldSet" />
      <xsl:with-param name="paramFieldContainer" select="msxsl:node-set($groups)/*/@fieldContainer" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*" mode="layout">
	  <xsl:param name="baseTable"/>
    <xsl:param name="scope" select="'fields'" />
    <xsl:param name="currentField" select="." />
    <xsl:param name="fields" />
    <xsl:variable name="field" select="$fields/Field[generate-id()=$currentField/@fieldId]" />

    <xsl:variable name="fieldName">
      <xsl:choose>
        <xsl:when test="$scope='fields'">
          <xsl:value-of select="@Column_Name" />
        </xsl:when>
        <xsl:otherwise>px:field</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ignoreField" select="boolean($scope!='fields' and not($field[key('renderField', generate-id())]))" />
    /*, <xsl:value-of select="position()"/> (<xsl:value-of select="$field/@Column_Name"/> :: <xsl:value-of select="@fieldId"/>/<xsl:value-of select="generate-id($field)"/>): { ignoreField: <xsl:value-of select="$ignoreField"/>, <xsl:for-each select="@*">, 
      <xsl:value-of select="name(.)"/>: <xsl:value-of select="."/>
    </xsl:for-each>}*/
    
    <xsl:if test="$field[key('availableFields', generate-id())][not(key('foreignReference', generate-id()))][not($ignoreField)][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
      <xsl:variable name="prefix">px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')"><xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer" />
        </xsl:if>
      </xsl:variable>
      <xsl:if test="@changeGroupTabPanel and @groupTabPanel">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields'" />/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')"><xsl:apply-templates mode="groupName" select="@groupTabPanel" />
          </xsl:if>/@name]='<xsl:value-of select="@groupTabPanel" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changeSubGroupTabPanel and @subGroupTabPanel">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          <xsl:apply-templates mode="groupName" select="@groupTabPanel" />
        </xsl:if>/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
            <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel" />
          </xsl:if>/@name]='<xsl:value-of select="@subGroupTabPanel" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changePortlet and @portlet">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel" />
        </xsl:if>/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
            <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet" />
          </xsl:if>/@name]='<xsl:value-of select="@portlet" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changeTabPanel and @tabPanel">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet" />
        </xsl:if>/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
            <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel" />
          </xsl:if>/@name]='<xsl:value-of select="@tabPanel" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changeTab and @tab">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel" />
        </xsl:if>/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
            <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab" />
          </xsl:if>/@name]='<xsl:value-of select="@tab" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changeFieldSet and @fieldSet">
        ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab" />
        </xsl:if>/DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
            <xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet" />
          </xsl:if>/@name]='<xsl:value-of select="@fieldSet" />'
        </xsl:if>
      </xsl:if>
      <xsl:if test="@changeFieldContainer and @fieldContainer">
        <xsl:variable name="pathPrefix">px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')"><xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet" /></xsl:if>
        </xsl:variable>
        <xsl:variable name="fullPathPrefix">px:<xsl:value-of select="$scope" /><xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')"><xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer" /></xsl:if></xsl:variable>

        ,[<xsl:value-of select="$pathPrefix" />/DUMMY]=NULL
        <xsl:if test="$scope!='fields' and not($field/ancestor::*/@mode='filters')">
          ,[<xsl:value-of select="$fullPathPrefix" />/@name]='<xsl:value-of select="@fieldContainer" />'
          <xsl:apply-templates select="@fieldContainer" mode="container.attributes">
            <xsl:with-param name="prefix" select="$fullPathPrefix" />
          </xsl:apply-templates>
        </xsl:if>
      </xsl:if>
      <xsl:variable name="id_name">
        <xsl:choose>
          <xsl:when test="$scope='layout'">fieldId</xsl:when>
          <xsl:otherwise>fieldId</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="field_name">
        <xsl:choose>
          <xsl:when test="$scope='layout'">fieldName</xsl:when>
          <xsl:otherwise>fieldName</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      ,[<xsl:value-of select="concat($prefix,'/',$fieldName)" />/@<xsl:value-of select="$id_name" />]='<xsl:value-of select="@fieldId" />'
      ,[<xsl:value-of select="concat($prefix,'/',$fieldName)" />/@<xsl:value-of select="$field_name" />]='<xsl:value-of select="@Column_Name" />'
      <xsl:if test="$scope='fields'">
        <xsl:apply-templates mode="Attributes" select="$field/@*[not(name(.)='mode') or name(.)='mode' and substring(string(.), 1, 10)!='CASE WHEN ']">
          <xsl:with-param name="Column_Name" select="concat($prefix,'/',$fieldName)" />
          <xsl:with-param name="escape" select="true()" />
        </xsl:apply-templates>
        <xsl:for-each select="$field">
          <xsl:choose>
            <xsl:when test="not(ancestor::*[@mode='fieldselector' or @mode='help']) and @dataType='foreignKey'">
              , [<xsl:value-of select="concat($prefix,'/',$fieldName)" />]=( SELECT TOP 1 * FROM <xsl:apply-templates mode="node" select="ForeignTable[1]">
				  <xsl:with-param name="baseTable" select="$baseTable"/>
                <xsl:with-param name="mode">fields</xsl:with-param>
                <xsl:with-param name="scope" select="$scope" />
              </xsl:apply-templates> FOR XML AUTO, TYPE )
              <xsl:if test="@controlType='radiogroup'">
               , [<xsl:value-of select="concat($prefix,'/',$fieldName)" />/px:data]=( SELECT * FROM <xsl:apply-templates mode="node" select="key('ForeignTable', generate-id(ForeignTable[1]))">
				   <xsl:with-param name="baseTable" select="$baseTable"/>
                  <xsl:with-param name="mode">data</xsl:with-param>
                  <xsl:with-param name="scope" select="$scope" />
                </xsl:apply-templates> FOR XML AUTO, TYPE )
              </xsl:if>
            </xsl:when>
            <xsl:when test="not(ancestor::*[@mode='fieldselector' or @mode='help']) and ((@dataType='foreignTable' or @dataType='junctionTable') and (ancestor-or-self::*[@mode!='inherit'][1]/@mode!='none' or (@controlType='inlineTable' or @controlType='embeddedTable')) and *)">
              , [<xsl:value-of select="concat($prefix,'/',$fieldName)" />]=( <xsl:apply-templates mode="node" select="*">
				  <xsl:with-param name="baseTable" select="$baseTable"/>
				  <xsl:with-param name="unBindPrimaryTable" select="true()" />
                <xsl:with-param name="scope" select="$scope" />
              </xsl:apply-templates>)
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:if>
      ,[<xsl:value-of select="$prefix" />/DUMMY]=NULL
    </xsl:if>
  </xsl:template>
  
  
  
  
  
  
  
  <xsl:template name="queryDefinition">
    <xsl:param name="mode" />
    <xsl:param name="unBindPrimaryTable" select="false()" />
    FROM <xsl:call-template name="viewDefinition" /> [$Table] <xsl:choose>
      <xsl:when test="ancestor-or-self::Field[1]/@dataType='junctionTable'">
        RIGHT OUTER JOIN <xsl:for-each select="*[local-name(.)='Fields' or local-name(.)='Record']">
			<xsl:variable name="pk" select="Field[key('primaryKey',generate-id())][not(key('foreignReference', generate-id()))]"/>
          (SELECT [$displayText]=<xsl:value-of select="$pk/ForeignTable/@text" />, * FROM [<xsl:value-of select="$pk/ForeignTable/@Table_Schema" />].[<xsl:value-of select="$pk/ForeignTable/@Table_Name" />]) [$Linked] ON <xsl:for-each select="Field[key('primaryKey',generate-id())][not(key('foreignReference', generate-id()))]">
			  <xsl:if test="position()&gt;1"> AND </xsl:if>[$Linked].[<xsl:value-of select="ForeignTable/@primaryKey" />]=[$Table].[<xsl:value-of select="@Column_Name" />]
		  </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise> WHERE 1=1 </xsl:otherwise>
    </xsl:choose><xsl:choose>
      <xsl:when test="not(key('RequestedTable', generate-id(current()))) and ancestor-or-self::Field[1] and not($unBindPrimaryTable)">
        AND ([$Table].[<xsl:value-of select="ancestor-or-self::Field[1]/@foreignReference" />]=[#primaryTable].[@primaryValue]<xsl:if test="ancestor-or-self::Field[1]/@dataType='junctionTable'">
          OR [#primaryTable].[@primaryValue] IS NULL AND [$Table].[<xsl:value-of select="ancestor-or-self::Field[1]/@foreignReference" />] IS NULL
        </xsl:if>)/*<xsl:value-of select="$unBindPrimaryTable" />*/
      </xsl:when>
      <xsl:otherwise />
    </xsl:choose><xsl:choose>
      <xsl:when test="ancestor-or-self::Field[1]/@dataType='junctionTable'"> WHERE 1=1 </xsl:when>
      <xsl:otherwise />
    </xsl:choose> AND EXISTS(SELECT 1 FROM @@Privileges [#Privileges] WHERE /*[#Privileges].[$UserId]=@@UserId AND */<xsl:choose>
      <xsl:when test="ancestor-or-self::Field[1]/@dataType='junctionTable'">
        [#Privileges].[$SchemaName]='<xsl:value-of select="ancestor-or-self::Field[1]/../../@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="ancestor-or-self::Field[1]/../../@Table_Name" />'
      </xsl:when>
      <xsl:otherwise>
        [#Privileges].[$SchemaName]='<xsl:value-of select="@Table_Schema" />' AND [#Privileges].[$CatalogName]='<xsl:value-of select="@Table_Name" />'
      </xsl:otherwise>
    </xsl:choose> AND [#Privileges].[$R]=1 <xsl:if test="string(@filters)!='' and not(@filtersBehavior='replace' and $filters!='')">
      AND (<xsl:value-of select="@filters" />)
    </xsl:if><xsl:if test="key('RequestedTable', generate-id(current()))">/*#filters#*/</xsl:if>)
  </xsl:template>

  <xsl:template name="translateTemplate">
    <xsl:param name="template" />
    <xsl:param name="nodes" />
    <xsl:choose>
      <xsl:when test="contains($template, '\[')">
        <xsl:value-of select="substring-before($template, '\[')" />[<xsl:call-template name="translateTemplate">
          <xsl:with-param name="template" select="substring-after($template, '\[')" />
          <xsl:with-param name="nodes" select="$nodes" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($template, '[')">
        <xsl:variable name="token">
          <xsl:value-of select="substring-before(substring-after($template, '['), ']')" />
        </xsl:variable>
        <xsl:value-of select="substring-before($template, '[')" />'+

        ISNULL(RTRIM(CONVERT(nvarchar(MAX),[<xsl:value-of select="$token" />])),'')+'<xsl:call-template name="translateTemplate">
          <xsl:with-param name="template" select="substring-after(substring-after($template, '['), ']')" />
          <xsl:with-param name="nodes" select="$nodes" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$template = ''">
            <xsl:text />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of disable-output-escaping="yes" select="$template" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="translateTemplateValues">
    <xsl:param name="template" />
    <xsl:param name="nodes" />
    <xsl:call-template name="translateTemplate">
      <xsl:with-param name="template">
        <xsl:call-template name="prepareTranslateTemplateValues">
          <xsl:with-param name="template" select="$template" />
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="nodes" select="$nodes" />
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="prepareTranslateTemplateValues">
    <xsl:param name="template" />
    <xsl:param name="nodes" />
    <xsl:call-template name="translateTemplate">
      <xsl:with-param name="template" />
      <xsl:with-param name="nodes" select="$nodes" />
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="contains($template, '\[')">
        <xsl:value-of select="substring-before($template, '\[')" />\[<xsl:call-template name="prepareTranslateTemplateValues">
          <xsl:with-param name="template" select="substring-after($template, '\[')" />
          <xsl:with-param name="nodes" select="$nodes" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($template, '[')">
        <xsl:variable name="token">
          <xsl:value-of select="substring-before(substring-after($template, '['), ']')" />
        </xsl:variable>
        <xsl:value-of select="substring-before($template, '[')" />\[[<xsl:value-of select="$token" />]]<xsl:call-template name="prepareTranslateTemplateValues">
          <xsl:with-param name="template" select="substring-after(substring-after($template, '['), ']')" />
          <xsl:with-param name="nodes" select="$nodes" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$template = ''">
            <xsl:text />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of disable-output-escaping="yes" select="$template" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>