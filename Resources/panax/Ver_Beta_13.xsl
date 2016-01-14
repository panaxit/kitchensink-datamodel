<xsl:stylesheet
  xmlns:px="http://www.panaxit.com"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" version="1.0"
xmlns:debug="http://www.panaxit.com/debug"
extension-element-prefixes="msxsl">
	<xsl:strip-space elements="*" />

	<xsl:key name="renderField" match="Table/*/Field[not(@autoGenerateField='false' or @controlType='hiddenField' or @Mode='hidden' or @Column_Name=../../@identityKey)]" use="generate-id(.)" />

	<xsl:key name="primaryKeys" match="//px:PrimaryKeys" use="generate-id(..)" />

	<xsl:key name="fieldbound" match="Table/*/Field[@Column_Name=ancestor::Table[1]//@binding]" use="generate-id(.)" />
	<xsl:key name="ForeignTable" match="ForeignTable" use="generate-id(.)" />
	<xsl:key name="ForeignKeys" match="ForeignKeys/ForeignKey[string(@Mode)='inline' or string(@Mode)='inherit' or @scaffold='true' and string(@Mode)!='none' or (not(string(@Mode)='none') and not(@scaffold='false') and (not(following-sibling::* or preceding-sibling::*) or @Mode or (ancestor::ForeignTable[1]/@defaultForeignKey=@Column_Name and not(@Mode) and (following-sibling::* or preceding-sibling::*)) ))][1]" use="generate-id(ancestor::ForeignTable[1])" />
	<!--<xsl:key name="DataRelatedAttribute" match="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')']" use="generate-id(.)" />-->
	<xsl:key name="parentMode" match="*" use="concat(generate-id(.),':',ancestor-or-self::*[@Mode!='inherit'][1]/@Mode)" />
	<xsl:key name="mode" match="*[@Mode!='inherit']" use="generate-id(//*[generate-id(current())=generate-id(ancestor-or-self::*[@Mode!='inherit'][1])])" />
	<xsl:key name="sortableColumns" match="Table/*/Field[not(@Mode='none' or @Column_Name=../../@identityKey or ../../../@DataType='junctionTable' and @Column_Name=../../PrimaryKeys/PrimaryKey/@Column_Name)][@sortOrder or not(@sortOrder) and (not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='foreignKey') or position()=1 and count(following-sibling::*[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='foreignKey' or @Column_Name=../../@identityKey)])=0)]" use="generate-id(../..)" />
	<xsl:key name="allFields" match="Table/Record/*" use="generate-id(../..)" />
	<xsl:key name="allFields" match="Table/Record/*" use="generate-id(.)" />
	<!--<xsl:key name="availableFields" match="Table/Record/Field[string(@Mode)!='none' and not(@Name=ancestor::Table[1]/Mappings/Map/@Map)][@Mode or not(@Mode) and not(@isNullable=1 and (ancestor-or-self::Table[1][@controlType='gridview'][not(../@DataType='junctionTable')] or ancestor-or-self::Table[@Mode][1]/@Mode='filters') or ((@DataType='foreignTable' or @DataType='junctionTable') and ancestor-or-self::Table[1][@controlType='gridview' or @Mode='filters']) )]" use="generate-id(../..)" />
  <xsl:key name="availableFields" match="Table/*/Field[string(@Mode)!='none' and not(@Column_Name=ancestor::Field[1]/@foreignReference)][@Mode or not(@Mode) and not(@isNullable=1 and (ancestor-or-self::Table[1][@controlType='gridview'][not(../@DataType='junctionTable')] or ancestor-or-self::Table[@Mode][1]/@Mode='filters') or ((@DataType='foreignTable' or @DataType='junctionTable') and ancestor-or-self::Table[1][@controlType='gridview' or @Mode='filters' or @Mode='fieldselector' or @Mode='help']) )]" use="generate-id()" />-->

	<xsl:key name="availableFields" match="Table/Record/*[string(@scaffold)!='false']" use="generate-id(../..)" />
	<xsl:key name="availableFields" match="Table/Record/*[string(@scaffold)!='false']" use="generate-id()" />


	<xsl:key name="primaryKey" match="Table/*/Field[@DataType!='foreignTable' and @DataType!='junctionTable'][@Column_Name=../../PrimaryKeys/PrimaryKey/@Column_Name]" use="generate-id(.)" />
	<xsl:key name="primaryReference" match="Field[@DataType='foreignTable' or @DataType='junctionTable'][@foreignReference=Table/*/Field[@DataType!='foreignTable' and @DataType!='junctionTable']/@Column_Name]" use="generate-id(Table/*/Field[@Column_Name=ancestor::Field[1]/@foreignReference])" />
	<xsl:key name="foreignReference" match="Table/*/Field[@Column_Name=ancestor::Field[1]/@foreignReference]" use="generate-id(.)" />
	<xsl:key name="RequestedTable" match="/root/Tables" use="generate-id(.)" />
	<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
	<xsl:variable name="inputParameters" />
	<xsl:variable name="fieldDefaults" />
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
			<query>
				<xsl:value-of select="$fieldDefaults" />
				--DECLARE @@UserId nvarchar(255), @lang nvarchar(15), @pageSize int, @pageIndex int, @getData bit, @getStructure bit, @filters nvarchar(MAX), @parameters nvarchar(MAX);
				--SELECT @@UserId=-1, @pageSize=1, @pageIndex=1, @getData=1, @getStructure=1, @filters='', @parameters='';
				----		  DECLARE @resourcesLocation nvarchar(MAX);
				----		  SELECT @resourcesLocation=[$Application].getGlobalizationResourcesLocation()+@TableSchema+'\'+@TableName+'\headers'+ISNULL('.'+RTRIM(@lang),'')+'.resx'
				--		  DECLARE @resx XML;
				----		  EXEC [$FSO].getResourcesFile @FilePath=@resourcesLocation, @resx=@resx OUTPUT
				----		  IF @resx IS NULL BEGIN
				----		  SELECT @resourcesLocation=[$Application].getGlobalizationResourcesLocation()+@TableSchema+'\'+@TableName+'\headers.resx'
				----		  EXEC [$FSO].getResourcesFile @FilePath=@resourcesLocation, @resx=@resx OUTPUT
				----		  END

				<xsl:variable name="tableSchema" select="//Table[key('RequestedTable', generate-id(.))]/descendant-or-self::Table/@Schema" /><xsl:if test="@parameters">
					DECLARE <xsl:value-of select="@parameters" />;
				</xsl:if><xsl:if test="current()/Parameters/*">
					DECLARE <xsl:for-each select="current()/Parameters/*">
						<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
						<xsl:if test="position()&gt;1">,</xsl:if>
						<xsl:value-of select="@parameterName" />
						<xsl:value-of select="concat(' ', @DataType)" />
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
				;WITH XMLNAMESPACES ('http://www.panaxit.com' AS px, 'http://www.panaxit.com/layout' AS layout, 'http://www.panaxit.com/session' AS session, 'http://www.panaxit.com/custom' AS custom, 'http://www.panaxit.com/debug' AS debug, 'http://www.panaxit.com/extjs' AS extjs ),
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
				<xsl:apply-templates mode="node" select="." />
			</query>
		</xsl:for-each>
	</xsl:template>

	<xsl:template mode="node" match="Table">
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
		attributes.*
		, [@totalRecords]=COALESCE([@recordCount], data.value('count(/px:data/px:dataRow[@rowNumber>0])' ,'int'))
		, primaryKeys AS '*'
		, routes AS '*'
		, fields AS '*'
		, layout AS '*'
		, data AS '*'
		FROM
		(
		SELECT TOP 1 [$C], [$R], [$U], [$D], [$S] FROM @@Privileges [$Privileges] WHERE [$Privileges].[$SchemaName]='<xsl:value-of select="@Schema" />' AND [$Privileges].[$CatalogName]='<xsl:value-of select="@Name" />' AND [$Privileges].[$R]=1
		) [$Privileges]
		CROSS APPLY
		(
		SELECT
		[@xml:lang]=RTRIM(COALESCE(NULLIF(@lang,''), NULLIF('<xsl:value-of select="@xml:lang"/>',''), 'es'))
		,[@session:userId]=@@UserId
		,[@session:profileId]=(SELECT DISTINCT '['+RTRIM([$ProfileId])+']' FROM @@Privileges SP WHERE SP.[$UserId]=@@UserId FOR XML PATH(''))
		,[@Mode]=ISNULL(<xsl:apply-templates mode="Property.Value" select="@Mode" />+LEFT(NULLIF(([$Privileges].[$R]),0),0), 'deny')
		,[@pageSize]=@pageSize
		,[@pageIndex]=<xsl:choose>
			<xsl:when test="key('RequestedTable', generate-id(current()))">COALESCE(@pageIndex,1)</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates mode="Attributes" select="../@foreignReference" />
		,[@recordCount]=CASE WHEN @getData=0 <xsl:if test="not(key('RequestedTable', generate-id(current())))"> OR 1=1 </xsl:if>THEN NULL WHEN <xsl:value-of select="$pageSize" />=0 THEN NULL ELSE <xsl:choose>
			<xsl:when test="key('RequestedTable', generate-id(current())) and @Mode!='new' and @Mode!='filters' and not(@Mode='fieldselector' or @Mode='help' or @Mode='search' or @Mode='print')">
				(SELECT COUNT(1) FROM (SELECT [$mode]=<xsl:choose>
					<xsl:when test="string($table/*/@Mode)!=''">
						<xsl:apply-templates mode="Property.Value" select="$table/*/@Mode" />
					</xsl:when>
					<xsl:otherwise>'inherit'</xsl:otherwise>
				</xsl:choose><xsl:call-template name="queryDefinition">
					<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
				</xsl:call-template>) [$PrimaryTable] WHERE not([$mode]='none') )
			</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose> END
		<xsl:apply-templates mode="Attributes" select="@*[(name(.)!='columnDefinition' and name(.)!='pageSize' and name(.)!='pageIndex' and name(.)!='displayText' and name(.)!='parameters' and name(.)!='mode') and name(.)!='filters' and name(.)!='headerText' and name(.)!='disableInsert' and name(.)!='disableUpdate' and name(.)!='disableDelete' and name(.)!='xml:lang']" />
		,[@headerText]=<xsl:choose>
			<xsl:when test="@headerText">
				<xsl:apply-templates mode="Property.Value" select="@headerText" />
			</xsl:when>
			<xsl:otherwise>
				CASE WHEN '<xsl:value-of select="@Schema" />'='dbo' THEN '' ELSE [$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Schema" />', '_', ' ', 1))+' - ' END + [$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Name" />', '_', ' ', 1))
			</xsl:otherwise>
		</xsl:choose>
		,[@filters]=@filters
		,[@parameters]=@parameters
		) [attributes]
		OUTER APPLY
		(
		SELECT
		<xsl:variable name="primaryKeys" select="px:PrimaryKeys/px:PrimaryKey"/>
		<xsl:choose>
			<xsl:when test="$primaryKeys">
				<xsl:for-each select="$primaryKeys[1]">
					<xsl:for-each select="@*">
						<xsl:if test="position()&gt;1">
							<xsl:text>,</xsl:text>
						</xsl:if>
						<xsl:text>[@</xsl:text><xsl:value-of select="name(.)"/>]
					</xsl:for-each>
				</xsl:for-each>
				FROM
				(
				<xsl:for-each select="$primaryKeys">
					<xsl:if test="position()&gt;1">
						UNION ALL
					</xsl:if>
					SELECT
					<xsl:for-each select="@*">
						<xsl:if test="position()&gt;1">
							<xsl:text>,</xsl:text>
						</xsl:if>
						<xsl:text>[@</xsl:text><xsl:value-of select="name(.)"/>]='<xsl:value-of select="."/>'
					</xsl:for-each>
				</xsl:for-each>
				) [<xsl:value-of select="name($primaryKeys/..)"/>]
			</xsl:when>
			<xsl:otherwise>
				NULL
			</xsl:otherwise>
		</xsl:choose>
		FOR XML PATH('<xsl:if test="$primaryKeys">
			<xsl:text>px:</xsl:text>
			<xsl:value-of select="name($primaryKeys)"/>
		</xsl:if>'), ROOT('px:primaryKeys'), TYPE
		) [primaryKeys](primaryKeys)
		OUTER APPLY
		(
		SELECT
		<xsl:variable name="routes" select="px:Routes/px:Route"/>
		<xsl:choose>
			<xsl:when test="$routes">
				<xsl:for-each select="$routes[1]">
					<xsl:for-each select="@*">
						<xsl:if test="position()&gt;1">
							<xsl:text>,</xsl:text>
						</xsl:if>
						<xsl:text>[@</xsl:text><xsl:value-of select="name(.)"/>]
					</xsl:for-each>
					<xsl:for-each select="*">
						,[px:<xsl:value-of select="local-name(.)"/>/@name]='<xsl:value-of select="@name"/>'
						,[px:<xsl:value-of select="local-name(.)"/>]=[@<xsl:value-of select="local-name(.)"/>.<xsl:value-of select="@name"/>]
						,NULL
					</xsl:for-each>
				</xsl:for-each>
				FROM
				(
				<xsl:for-each select="$routes">
					<xsl:if test="position()&gt;1">
						UNION ALL
					</xsl:if>
					SELECT
					<xsl:for-each select="@*">
						<xsl:if test="position()&gt;1">
							<xsl:text>,</xsl:text>
						</xsl:if>
						<xsl:text>[@</xsl:text><xsl:value-of select="name(.)"/>]='<xsl:value-of select="."/>'
					</xsl:for-each>
					<xsl:for-each select="*">
						<xsl:text>,</xsl:text>
						<xsl:apply-templates mode="copy.nodes" select="."/>
					</xsl:for-each>
					FROM @@Privileges WHERE [$SchemaName]='<xsl:value-of select="px:Param[@name='schemaName']"/>' AND [$CatalogName]='<xsl:value-of select="px:Param[@name='catalogName']"/>' AND [$<xsl:choose>
						<xsl:when test="@Method='edit'">U</xsl:when>
						<xsl:otherwise>C</xsl:otherwise>
					</xsl:choose>]=1
				</xsl:for-each>
				) [<xsl:value-of select="name($routes/..)"/>]
			</xsl:when>
			<xsl:otherwise>
				NULL
			</xsl:otherwise>
		</xsl:choose>
		FOR XML PATH('<xsl:if test="$routes">
			<xsl:text>px:</xsl:text>
			<xsl:value-of select="name($routes)"/>
		</xsl:if>'), ROOT('px:Routes'), TYPE
		) [routes](routes)
		<xsl:if test="$scope!='data'">
			<xsl:variable name="orderedTree">
				<fields>
					<xsl:apply-templates mode="tree" select="Record/*[1]">
						<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
					</xsl:apply-templates>
				</fields>
			</xsl:variable>
			<xsl:variable name="tree">
				<fields>
					<xsl:apply-templates mode="groups" select="msxsl:node-set($orderedTree)/*/*[1]"/>
				</fields>
			</xsl:variable>
			CROSS APPLY (
			SELECT [fields/@start]=NULL
			<xsl:if test="key('RequestedTable', generate-id(current()))">/*#Fields--*/</xsl:if><xsl:apply-templates mode="layout" select="msxsl:node-set($tree)/*/*">
				<xsl:with-param name="fields" select="Record" />
				<xsl:with-param name="scope" select="'fields'" />
			</xsl:apply-templates> WHERE @getStructure=1 or @getData=1
			<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Fields#*/</xsl:if> FOR XML PATH('px:Fields'), TYPE
			)fields(fields)
			CROSS APPLY (
			SELECT [layout/@start]=NULL
			<xsl:if test="key('RequestedTable', generate-id(current()))">/*#Layout--*/</xsl:if><xsl:apply-templates mode="layout" select="msxsl:node-set($tree)/*/*">
				<xsl:with-param name="fields" select="Record" />
				<xsl:with-param name="scope" select="'layout'" />
			</xsl:apply-templates> WHERE @getStructure=1
			<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Layout#*/</xsl:if> FOR XML PATH('layout:layout'), TYPE
			)layout(layout)
		</xsl:if>
		<xsl:if test="$scope!='fields'">
			<!--  or (../@DataType='junctionTable') -->
			CROSS APPLY (
			SELECT [data/@start]=NULL<xsl:if test="1=0">
				<xsl:if test="key('RequestedTable', generate-id(current()))">/*#Data--*/</xsl:if>        <xsl:apply-templates mode="columns" select="Record">
					<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
				</xsl:apply-templates>
				<!--<xsl:if test="key('RequestedTable', generate-id(current()))">
        ,[px:dataRow]=NULL
        ,[px:dataRow/px:foreignTable/@id]=987
        ,[px:dataRow/px:foreignTable]=[relationships].data
      </xsl:if>-->
				FROM
				(
				<xsl:choose>
					<xsl:when test="not(../@DataType='junctionTable') and (key('RequestedTable', generate-id(ancestor-or-self::*[@DataType='table']))/@Mode='new' or key('RequestedTable', generate-id(ancestor-or-self::*[@DataType='table']))/@Mode='filters' or key('RequestedTable', generate-id(ancestor-or-self::*[@DataType='table']))[@Mode='fieldselector' or @Mode='help'])">
						SELECT <xsl:apply-templates mode="columnValues" select="Record">
							<xsl:with-param name="mode">
								<xsl:value-of select="key('RequestedTable', generate-id(ancestor-or-self::*[@DataType='table']))/@Mode" />
							</xsl:with-param>
							<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
						</xsl:apply-templates>
						FROM (
						SELECT TOP 1 *, [$mode]=/*CASE WHEN [$Privileges].[$C]=1 THEN */'inherit'/* ELSE 'none' END*/
						FROM @@Privileges [$Privileges] WHERE [$Privileges].[$UserId]=@@UserId AND [$Privileges].[$R]=1 AND
						<xsl:choose>
							<xsl:when test="ancestor-or-self::Relationship[1]/@DataType='junctionTable'">
								[$Privileges].[$SchemaName]='<xsl:value-of select="ancestor-or-self::Relationship[1]/../../@Schema" />' AND [$Privileges].[$CatalogName]='<xsl:value-of select="ancestor-or-self::Relationship[1]/../../@Name" />'
							</xsl:when>
							<xsl:otherwise>
								[$Privileges].[$SchemaName]='<xsl:value-of select="@Schema" />' AND [$Privileges].[$CatalogName]='<xsl:value-of select="@Name" />'
							</xsl:otherwise>
						</xsl:choose>
						) [$Privileges]
						<xsl:if test="not(@Mode='new' or @Mode='filters' or @Mode='fieldselector' or @Mode='help')">
							WHERE NOT EXISTS(SELECT 1 <xsl:call-template name="queryDefinition">
								<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
								<xsl:with-param name="mode" select="'recordCount'" />
							</xsl:call-template>)
						</xsl:if>
						/*UNION ALL*/
					</xsl:when>
					<xsl:otherwise>
						SELECT <xsl:apply-templates mode="columnValues" select="Record">
							<xsl:with-param name="mode" select="'edit'" />
							<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
						</xsl:apply-templates><xsl:call-template name="queryDefinition">
							<xsl:with-param name="unBindPrimaryTable" select="$unBindPrimaryTable" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
				) [$PrimaryTable]
				<xsl:if test="1=1 or not(ancestor-or-self::*/@controlType='gridview')">
					<!--Relationships-->
					<xsl:apply-templates mode="relationships" select="Record">
						<xsl:with-param name="scope" select="'data'" />
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="key('RequestedTable', generate-id(current()))">
					WHERE @getData=1 and (<xsl:if test="@Mode='new' or @Mode='filters' or @Mode='fieldselector' or @Mode='help'">[@rowNumber] IS NULL OR </xsl:if><xsl:value-of select="$pageSize" />=0 OR [@rowNumber] BETWEEN (<xsl:value-of select="$pageSize" />*(@pageIndex-1))+1 AND <xsl:value-of select="$pageSize" />*@pageIndex)
					ORDER BY [@rowNumber]
				</xsl:if>
			</xsl:if> FOR XML PATH(''), ROOT('px:data'), TYPE<xsl:if test="key('RequestedTable', generate-id(current()))">/*--Data#*/</xsl:if>
			) [<xsl:value-of select="@Name" />](data)
		</xsl:if>
		FOR XML PATH('px:<xsl:value-of select="@controlType"/>'), TYPE
	</xsl:template>

	<xsl:template mode="copy.nodes" match="px:Routes/px:Route/px:Param">
		[@<xsl:value-of select="local-name(.)"/>.<xsl:value-of select="@name"/>]='<xsl:value-of select="."/><xsl:text>'</xsl:text>
	</xsl:template>

	<xsl:template mode="copy.nodes" match="px:Routes/px:Route/px:Param[@name='schemaName' or @name='catalogName']">
		[@<xsl:value-of select="local-name(.)"/>.<xsl:value-of select="@name"/><xsl:text>]=[$</xsl:text><xsl:value-of select="@name"/><xsl:text>]</xsl:text>
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
						[<xsl:value-of select="@Schema" />].[<xsl:value-of select="$table/@Name" />]
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
				[<xsl:value-of select="@Schema" />].[<xsl:value-of select="$table/@Name" />]
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
			<xsl:apply-templates mode="Property.Value" select=".">
				<xsl:with-param name="escape" select="$escape" />
				<xsl:with-param name="defaultIfDynamic" select="$defaultIfDynamic" />
			</xsl:apply-templates>
		</xsl:param>
		<xsl:if test="position()=1 and not($supressFirstComma=true()) or position()&gt;1">
			<xsl:text>,</xsl:text>
		</xsl:if>
		<xsl:text>[</xsl:text>
		<xsl:if test="$Column_Name">
			<xsl:value-of select="$Column_Name" />
			<xsl:text>/</xsl:text>
		</xsl:if>
		<xsl:if test="$mode='attribute'">
			<xsl:text>@</xsl:text>
		</xsl:if>
		<xsl:value-of select="name(.)" />
		<xsl:text>]</xsl:text>
		<xsl:choose>
			<xsl:when test="$withValue=false()" />
			<xsl:otherwise>
				<xsl:text>=</xsl:text>
				<xsl:value-of select="$value" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template mode="Attributes" match="@debug:*|@moveBefore|@moveAfter|@ordinalPosition|@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer|@fieldContainerEnd|@controlTypeHint|Table/@Mode" />

	<xsl:template mode="Attributes" match="@*[ancestor::*[@Mode='filters' or @Mode='fieldselector' or @Mode='help']][(name()='supportsInsert' or name()='supportsUpdate' or name()='supportsDelete' or name()='isNullable' or name()='length')]"></xsl:template>

	<xsl:template mode="Attributes" match="@*[ancestor::*[@Mode='fieldselector' or @Mode='help']][(name()='relationshipType' or name()='foreignSchema' or name()='foreignTable' or name()='foreignReference')]"></xsl:template>

	<xsl:template mode="Attributes" match="Table/@SupportsInsert|Table/@SupportsUpdate|Table/@SupportsDelete">
		<xsl:param name="mode" select="'attribute'" />
		<xsl:param name="Column_Name" select="@Column_Name" />
		<xsl:param name="supressFirstComma" select="false()" />
		<xsl:param name="defaultIfDynamic" select="false()" />
		<xsl:variable name="attachedAttribute">
			<xsl:text>disable</xsl:text>
			<xsl:call-template name="replace">
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
		<xsl:if test="not($Column_Name)">
			<xsl:text>,[@</xsl:text>
			<xsl:value-of select="$attachedAttribute"/>
			<xsl:text>]=ABS([$Privileges].[</xsl:text>
			<xsl:apply-templates mode="support.bind" select="."/>
			<xsl:text>]-1)*COALESCE(</xsl:text>
			<xsl:choose>
				<xsl:when test="../@*[name(.)=$attachedAttribute]">
					<xsl:apply-templates mode="Property.Value" select="../@*[name(.)=$attachedAttribute]">
						<xsl:with-param name="defaultIfDynamic" select="$defaultIfDynamic"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
			<xsl:text>,1)</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template mode="Property.Value" match="*[not(@*)]">NULL</xsl:template>

	<xsl:template mode="Property.Value" match="@*">
		<xsl:apply-templates mode="Property.ValueFormat" select="." />
	</xsl:template>

	<xsl:template mode="Property.Value" match="@description[key('parentMode',concat(generate-id(..),':readonly'))]">NULL</xsl:template>
	<xsl:template mode="support.bind" match="@SupportsInsert">$C</xsl:template>
	<xsl:template mode="support.bind" match="@SupportsDelete">$D</xsl:template>
	<xsl:template mode="support.bind" match="@SupportsUpdate">$U</xsl:template>


	<xsl:template mode="Property.Value" match="@pageSize|@pageIndex|@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')']">
		<!--DataRelatedAttribute-->
		<xsl:param name="escape" select="false()" />/*-value-*/
		<xsl:choose>
			<xsl:when test="$escape">
				'<xsl:call-template name="escape-apos">
					<xsl:with-param name="string">
						<xsl:value-of select="." />
					</xsl:with-param>
				</xsl:call-template>'
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template mode="Property.Value" match="@*[substring(., 1, 10)='CASE WHEN '][contains(., '[$')]">
		<xsl:variable name="table" select="ancestor-or-self::*[@Name][@Schema][1]" />
		(SELECT TOP 1 returnValue=<xsl:value-of select="." /> FROM @@Privileges [$Privileges] WHERE /*[$Privileges].[$UserId]=@@UserId AND */[$Privileges].[$SchemaName]='<xsl:value-of select="$table/@Schema" />' AND [$Privileges].[$CatalogName]='<xsl:value-of select="$table/@Name" />' AND [$Privileges].[$R]=1 )<!-- disable-output-escaping="yes" -->
	</xsl:template>
	<xsl:template mode="Property.Value" match="Table/*/Field/@headerText">
		'<xsl:value-of select="." /><xsl:if test="../@Column_Name=../preceding-sibling::*/@Column_Name or ../@Column_Name=../following-sibling::*/@Column_Name">
			(<xsl:value-of select="../@foreignReference" />)
		</xsl:if>'
	</xsl:template>
	<xsl:template mode="Property.Value" match="Table/*/Field/@controlType">
		<xsl:param name="defaultIfDynamic" select="false()" />/*<xsl:value-of select="$defaultIfDynamic" />*/<xsl:choose>
			<xsl:when test="$defaultIfDynamic=false() and .!='default'">
				<xsl:apply-templates mode="Property.ValueFormat" select="." />
			</xsl:when>
			<xsl:when test="$defaultIfDynamic=false() and @formula">'formula'</xsl:when>
			<xsl:otherwise>'default'</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template mode="Property.Value" match="Table[@Mode='filters']//@Mode">'filters'</xsl:template>
	<xsl:template mode="Property.Value" match="Table[@Mode='fieldselector' or @Mode='help']/*//@Mode">'inherit'</xsl:template>
	<xsl:template mode="Property.Value" match="@Mode">
		<xsl:param name="defaultIfDynamic" select="false()" />
		<xsl:choose>
			<xsl:when test="$defaultIfDynamic=true() and substring(., 1, 10)='CASE WHEN '">'inherit'</xsl:when>
			<xsl:when test="key('foreignReference', generate-id()) or contains($fieldDefaults, concat('@#', ../@Column_Name, '='))">'none'</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="Property.ValueFormat" select="." />
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
	<xsl:template mode="Property.Value" match="Table/*/Field[not(@DataType='identity')][ancestor::*[@Mode='fieldselector' or @Mode='help']]/@DataType">'bit'</xsl:template>
	<xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@Mode='filters']]">'default'</xsl:template>
	<xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@Mode='fieldselector']]">'checkbox'</xsl:template>
	<xsl:template mode="Property.Value" match="Table/*/Field/@controlType[ancestor::*[@Mode='help']]">'label'</xsl:template>
	<xsl:template mode="Property.ValueFormat" match="@*">
		<xsl:text>'</xsl:text>
		<xsl:call-template name="escape-apos">
			<xsl:with-param name="string">
				<xsl:value-of select="." />
			</xsl:with-param>
		</xsl:call-template>
		<xsl:text>'
		</xsl:text>
	</xsl:template>
	<xsl:template match="Field" mode="text">
		ISNULL(RTRIM([<xsl:value-of select="@Column_Name" />]),'')
	</xsl:template>
	<xsl:template match="Field" mode="value">
		RTRIM([<xsl:value-of select="@Column_Name" />])
	</xsl:template>
	<xsl:template match="Field[@DataType='text' or @DataType='ntext']" mode="text">
		ISNULL(RTRIM(CONVERT(nvarchar(MAX),[<xsl:value-of select="@Column_Name" />])),'')
	</xsl:template>
	<xsl:template match="Field[@DataType='text' or @DataType='ntext']" mode="value">
		RTRIM(CONVERT(nvarchar(MAX),[<xsl:value-of select="@Column_Name" />]))
	</xsl:template>
	<xsl:template match="Field[@DataType='varbinary']" mode="text">
		CASE WHEN NOT [<xsl:value-of select="@Column_Name" />] IS NULL THEN '*********************' ELSE '' END
	</xsl:template>
	<xsl:template match="Field[@DataType='varbinary']" mode="value">'*********************'</xsl:template>
	<xsl:template match="Field[@DataType='char' or @DataType='nchar' or @DataType='nvarchar' or @DataType='varchar' or @DataType='int' or @DataType='tinyint' or @DataType='float' or @DataType='real' or @DataType='numeric' or @DataType='decimal' or @DataType='bit']" mode="text">
		ISNULL(RTRIM([<xsl:value-of select="@Column_Name" />]), '')
	</xsl:template>
	<xsl:template match="Field[@DataType='char' or @DataType='nchar' or @DataType='nvarchar' or @DataType='varchar' or @DataType='int' or @DataType='tinyint' or @DataType='float' or @DataType='real' or @DataType='numeric' or @DataType='decimal' or @DataType='bit']" mode="value">
		RTRIM([<xsl:value-of select="@Column_Name" />])
	</xsl:template>
	<xsl:template match="Relationship[@DataType='foreignKey']" mode="node">
		<xsl:param name="path"/>
		<xsl:variable name="fieldName">
			<xsl:text>px:</xsl:text>
			<xsl:apply-templates mode="genericType" select="@DataType"/>
		</xsl:variable>
		<xsl:apply-templates mode="copy" select="*" >
			<xsl:with-param name="path" select="concat($path,$fieldName,'/')"/>
		</xsl:apply-templates>
		
		<xsl:if test="Relationship">
			<xsl:apply-templates mode="node" select="Relationship">
				<xsl:with-param name="path" select="concat($path,$fieldName,'/')"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<!--<xsl:template match="Relationship[@DataType='foreignKey']" mode="node">
		<xsl:text>( SELECT NULL</xsl:text>
		<xsl:apply-templates mode="copy" select="*" />
		<xsl:if test="Relationship">
			, <xsl:apply-templates mode="node" select="Relationship" />
		</xsl:if>
		FOR XML PATH(''), TYPE )
	</xsl:template> versión alterna-->
	<xsl:template match="Relationship[@DataType='foreignKey']" mode="text">
		<xsl:param name="prefix" />
		ISNULL(STUFF(CONVERT(nvarchar(MAX), <xsl:apply-templates mode="node" select="." />.query('for $item in //*[@text] order by count($item/*) ascending, empty($item/@sortOrder) ascending, number($item/@sortOrder) ascending return concat(''//'',data($item/@text))')),1,2,''),'')
	</xsl:template>
	<xsl:template match="Relationship[@DataType='foreignKey']" mode="value">
		[<xsl:value-of select="@Column_Name" />]
	</xsl:template>
	<xsl:template match="Field[@DataType='junctionTable']/Table/*/Field[@isPrimaryKey=1 and @DataType='foreignKey']" mode="text">
		<xsl:param name="prefix" />
		[@linkedText]
	</xsl:template>
	<xsl:template match="Field[@DataType='junctionTable' or @DataType='foreignTable']" mode="text">
		'Ver...'
	</xsl:template>
	<xsl:template match="Field[@DataType='junctionTable' or @DataType='foreignTable']" mode="value">
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
	<xsl:template match="Field[@DataType='money' or @DataType='smallmoney']" mode="text">
		CASE WHEN [<xsl:value-of select="@Column_Name" />]&lt;0 THEN '($'+LTRIM(CONVERT(nchar(14), -[<xsl:value-of select="@Column_Name" />], 1))+')' ELSE '$'+PARSENAME(CONVERT(nvarchar(MAX), CONVERT(money, [<xsl:value-of select="@Column_Name" />]), 1),2)+'.'+PARSENAME(CONVERT(decimal(20,<xsl:choose>
			<xsl:when test="@decimalPositions">
				<xsl:value-of select="@decimalPositions" />
			</xsl:when>
			<xsl:otherwise>3</xsl:otherwise>
		</xsl:choose>),[<xsl:value-of select="@Column_Name" />]) % 1,1) END
	</xsl:template>
	<xsl:template match="Field[@DataType='money' or @DataType='smallmoney']" mode="value">
		/*ISNULL(*/[<xsl:value-of select="@Column_Name" />]/*, '')*/
	</xsl:template>
	<xsl:template match="Field[@DataType='date' or @DataType='datetime' or @DataType='smalldatetime']" mode="text">
		ISNULL(RTRIM(CONVERT(nchar(25), [<xsl:value-of select="@Column_Name" />], 103)),'') /*+' '+ [$Date].Time([<xsl:value-of select="@Column_Name" />])*/
	</xsl:template>
	<xsl:template match="Field[@DataType='date' or @DataType='datetime' or @DataType='smalldatetime']" mode="value">
		RTRIM(CONVERT(nchar(25), convert(datetime,[<xsl:value-of select="@Column_Name" />]), 120))<!-- , [<xsl:value-of select="@Column_Name"/>/@YYYYMMDD]=CONVERT(VARCHAR(8), [<xsl:value-of select="@Column_Name"/>], 112) -->
	</xsl:template>
	<xsl:template match="Field[@DataType='time']" mode="text">
		[$Date].Time([<xsl:value-of select="@Column_Name" />])
	</xsl:template>
	<xsl:template match="Field[@DataType='time']" mode="value">
		RTRIM(DATEPART(HOUR,[<xsl:value-of select="@Column_Name" />]))+':'+RTRIM(DATEPART(MINUTE,[<xsl:value-of select="@Column_Name" />]))
	</xsl:template>
	<xsl:template match="Table/*/Field[@DataType='time']" mode="value">
		RTRIM(DATEPART(HOUR,[<xsl:value-of select="@Column_Name" />]))+':'+RTRIM(DATEPART(MINUTE,[<xsl:value-of select="@Column_Name" />]))
	</xsl:template>
	<xsl:template match="PrimaryKeys" mode="dataValue">
		<xsl:for-each select="PrimaryKey">
			<xsl:if test="position()&gt;1">' '+</xsl:if>RTRIM([<xsl:value-of select="@Column_Name" />])
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="@primaryKey" mode="dataValue">
		RTRIM([<xsl:value-of select="." />])
	</xsl:template>
	<xsl:template mode="node" match="Field[@DataType='xml']" />




	<xsl:template mode="node" match="*/ForeignTable">
		<xsl:param name="table" select="key('ForeignTable',generate-id(ancestor-or-self::ForeignTable[1]))" />
		<xsl:param name="mode" />
		<xsl:param name="scope" />
		<xsl:variable name="foreignKeys" select="key('ForeignKeys', generate-id(.))" />
		<xsl:variable name="selfReferenced" select="@Name=ancestor::ForeignTable[1]/@Name" />
		<xsl:if test="$selfReferenced">
			/*<xsl:value-of select="ancestor::ForeignTable[1]/@Name" />::<xsl:value-of select="@Name" />: <xsl:value-of select="$selfReferenced" />*/
		</xsl:if>
		<xsl:if test="string($mode)='data'">
			<xsl:apply-templates mode="node" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))">
				<xsl:with-param name="mode">
					<xsl:value-of select="$mode" />
				</xsl:with-param>
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
					<xsl:variable name="binding" select="../@binding" />[fieldId]='<xsl:value-of select="generate-id(ancestor::Table[1]/Record/*[@Name=$binding])" />'
					,[fieldName]='<xsl:value-of select="$binding" />',
				</xsl:when>
			</xsl:choose>sortOrder, text=ISNULL(text, '- -'), value, foreignValue<xsl:if test="not(string($mode)='data')">
				, foreignKey=<xsl:choose>
					<xsl:when test="$foreignKeys">
						'<xsl:value-of select="$foreignKeys/@Column_Name" />'
					</xsl:when>
					<xsl:otherwise>NULL</xsl:otherwise>
				</xsl:choose><xsl:if test="@Name=key('ForeignTable',generate-id($foreignKeys/ForeignTable))/@Name">, referencesItself='true'</xsl:if>, dataText='RTRIM(<xsl:call-template name="escape-apos">
					<xsl:with-param name="string">
						<xsl:value-of select="@text" />
					</xsl:with-param>
				</xsl:call-template>)', dataValue='<xsl:apply-templates mode="dataValue" select="@primaryKey" />' <xsl:apply-templates mode="Attributes" select="../@binding">
					<xsl:with-param name="mode" select="'elements'" />
				</xsl:apply-templates>,
				primaryKey='<xsl:value-of select="@primaryKey" />'<xsl:if test="../@Mode[substring(string(.), 1, 10)!='CASE WHEN ']">
					<xsl:apply-templates mode="Attributes" select="../@Mode">
						<xsl:with-param name="mode" select="'elements'" />
					</xsl:apply-templates>
				</xsl:if>, headerText=<xsl:choose>
					<xsl:when test="@headerText">
						'<xsl:value-of select="@headerText" />'
					</xsl:when>
					<xsl:otherwise>
						[$String].ToTitleCase([$RegEx].Replace('<xsl:value-of select="@Name" />', '_', ' ', 1))
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
					CASE WHEN [$PrimaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />] IS NULL THEN <xsl:value-of select="$foreignKeys/@defaultValue" /> ELSE NULL END
				</xsl:when>
				<xsl:otherwise>NULL</xsl:otherwise>
			</xsl:choose><xsl:if test="string($mode)='data'">
				<xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
					<xsl:with-param name="mode" select="'elements'" />
					<xsl:with-param name="value">NULL</xsl:with-param>
				</xsl:apply-templates>
			</xsl:if><xsl:if test="1=0 or string($mode)!='fields'">
				<xsl:if test="string($scope)!='fields' and not(ancestor::ForeignTable[1])">
					WHERE (SELECT COUNT(1) FROM [<xsl:value-of select="@Schema" />].[<xsl:value-of select="@Name" />])=0 OR [$PrimaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />] IS NULL
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
				</xsl:choose>), value=<xsl:apply-templates mode="dataValue" select="@primaryKey" />, foreignvalue=<xsl:choose>
					<xsl:when test="$foreignKeys">
						RTRIM([<xsl:value-of select="$foreignKeys/@Column_Name" />])
					</xsl:when>
					<xsl:otherwise>NULL</xsl:otherwise>
				</xsl:choose><xsl:if test="string($mode)='data'">
					<xsl:apply-templates mode="Attributes" select="@*[substring(., 1, 1)=&quot;'&quot; and name(.)!='filters' and name(.)!='fieldselector' and name(.)!='help' or substring(., 1, 1)='@' or starts-with(., 'ISNULL(') or starts-with(., 'RTRIM(') or substring(., 1, 10)='CASE WHEN ' or substring(., 1, 8)='CONVERT(' or substring(normalize-space(.), 1, 1)='(' and substring(., (string-length(.) - string-length(')')) + 1) = ')'][not(name(.)='text')]">
						<xsl:with-param name="mode" select="'elements'" />
					</xsl:apply-templates>
				</xsl:if> FROM [<xsl:value-of select="@Schema" />].[<xsl:value-of select="@Name" />] [$Table]/*scope: <xsl:value-of select="$scope" />*/<xsl:if test="string($scope)!='fields'">
					<xsl:if test="not(ancestor::ForeignTable[1])">
						WHERE (<xsl:if test="string($mode)='data'">
							(<xsl:choose>
								<xsl:when test="string(@filters)!=''">
									EXISTS(SELECT 1 FROM @@Privileges [$Privileges] WHERE /*[$Privileges].[$UserId]=@@UserId AND */(<xsl:value-of select="@filters" />))
								</xsl:when>
								<xsl:otherwise>1=1</xsl:otherwise>
							</xsl:choose>) OR
						</xsl:if> [$PrimaryTable].[<xsl:value-of select="ancestor-or-self::Field[1]/@Column_Name" />]=/*[<xsl:value-of select="@Name" />]*/[$Table].[<xsl:value-of select="@primaryKey" />])
					</xsl:if>
				</xsl:if>
			</xsl:if>
			) [<xsl:value-of select="@Name" />] <!--CROSS JOIN (SELECT TOP 1 [$C], [$R], [$U], [$D], [$S] FROM [$Privileges] WHERE /*[$Privileges].[$UserId]=@@UserId AND */[$Privileges].[$SchemaName]='<xsl:value-of select="@Schema" />' AND [$Privileges].[$CatalogName]='<xsl:value-of select="@Name" />' AND [$Privileges].[$R]=1) [$Privileges]-->
			) [<xsl:value-of select="@Name" /><xsl:if test="ancestor::ForeignTable[@Name=current()/@Name]">
				_<xsl:value-of select="count(ancestor::ForeignTable[@Name=current()/@Name])" />
			</xsl:if>]
		</xsl:if>
		<xsl:choose>
			<xsl:when test="string($mode)='data' and $foreignKeys">
				<xsl:variable name="fkNode" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))" />
				<xsl:variable name="fkName">
					<xsl:value-of select="$fkNode/@Name" />
					<xsl:if test="$fkNode[@Name=current()/@Name]">
						_<xsl:value-of select="count($fkNode[@Name=current()/@Name]/ancestor::ForeignTable[@Name=current()/@Name])" />
					</xsl:if>
				</xsl:variable>
				<xsl:if test="not($fkNode[@Name=current()/@Name])">
					ON [<xsl:value-of select="$fkName" />].value=[<xsl:value-of select="ancestor-or-self::ForeignTable[1]/@Name" />].foreignValue OR [<xsl:value-of select="$fkName" />].value IS NULL AND [<xsl:value-of select="key('ForeignTable',generate-id(ancestor-or-self::ForeignTable[1]))/@Name" />].foreignValue IS NULL
				</xsl:if>
			</xsl:when>
			<xsl:when test="not(string($mode)='data') and ancestor::ForeignTable[1]">
				<xsl:if test="not($selfReferenced)">
					ON [<xsl:value-of select="@Name" /><xsl:if test="ancestor::ForeignTable[@Name=current()/@Name]">
						_<xsl:value-of select="count(ancestor::ForeignTable[@Name=current()/@Name])" />
					</xsl:if>].value=[<xsl:value-of select="ancestor::ForeignTable[1]/@Name" />].foreignValue OR [<xsl:value-of select="@Name" /><xsl:if test="ancestor::ForeignTable[@Name=current()/@Name]">
						_<xsl:value-of select="count(ancestor::ForeignTable[@Name=current()/@Name])" />
					</xsl:if>].value IS NULL AND [<xsl:value-of select="ancestor::ForeignTable[1]/@Name" />].foreignValue IS NULL
				</xsl:if>
			</xsl:when>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="not(string($mode)='data') and $foreignKeys">
				<xsl:if test="not(@Name=key('ForeignTable',generate-id($foreignKeys/ForeignTable))/@Name)">LEFT OUTER JOIN </xsl:if>
				<xsl:apply-templates mode="node" select="key('ForeignTable',generate-id($foreignKeys/ForeignTable))">
					<xsl:with-param name="scope" select="$scope" />
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="string($mode)='data' and ancestor::ForeignTable[1]">
				<xsl:if test="not($selfReferenced)">LEFT OUTER JOIN</xsl:if>
			</xsl:when>
			<xsl:when test="string($mode)='data' and not(ancestor::ForeignTable[1]) and not(@orderBy)">
				ORDER BY <xsl:apply-templates mode="foreignTable.sortOrder" select="." />
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template mode="foreignTable.sortOrder" match="ForeignTable">
		<xsl:apply-templates mode="foreignTable.sortOrder" select="key('ForeignKeys', generate-id(.))/ForeignTable" />
		<xsl:if test="not(ancestor::ForeignTable[1][@Name=current()/@Name])">
			[<xsl:value-of select="@Name" /><xsl:if test="ancestor::ForeignTable[@Name=current()/@Name]">
				_<xsl:value-of select="count(ancestor::ForeignTable[@Name=current()/@Name])" />
			</xsl:if>].sortOrder<xsl:if test="name(..)='ForeignKey'">,</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template name="sortColumns">
		<xsl:param name="testColumn" />
		<xsl:param name="table" select="ancestor-or-self::Table[1]" />
		<xsl:if test="$table/../@DataType='junctionTable'">
			[$Linked].[@order],[$Linked].[@displayText]<xsl:if test="key('sortableColumns', generate-id(..))">,</xsl:if>
		</xsl:if>/*sortColumns*/
		<xsl:for-each select="key('sortableColumns', generate-id(..))">
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

	<xsl:template match="Table/Record" mode="columnValues">
		<xsl:param name="mode" />
		<xsl:param name="unBindPrimaryTable" />
		/*1st level: <xsl:value-of select="$mode" />*/
		[@rowNumber]=ROW_NUMBER() OVER (ORDER BY <xsl:if test="key('RequestedTable', generate-id(..))">/*#sorters#*/</xsl:if><xsl:call-template name="sortColumns" />)
		,[@identity]=<xsl:choose>
			<xsl:when test="$mode='new' or $mode='filters' or $mode='fieldselector' or $mode='help'">NULL</xsl:when>
			<xsl:when test="../@identityKey">
				[$Table].[<xsl:value-of select="../@identityKey" />]
			</xsl:when>
			<xsl:otherwise>NULL</xsl:otherwise>
		</xsl:choose>
		,[@primaryValue]=<xsl:choose>
			<xsl:when test="$mode='new' or $mode='filters' or $mode='fieldselector' or $mode='help'">NULL</xsl:when>
			<xsl:when test="../PrimaryKeys">
				<xsl:for-each select="../PrimaryKeys/PrimaryKey">
					<xsl:if test="position()&gt;1">+' '+</xsl:if>RTRIM([$Table].[<xsl:value-of select="@Column_Name" />])
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>NULL</xsl:otherwise>
		</xsl:choose>
		,[@referenceValue]=<xsl:choose>
			<xsl:when test="key('RequestedTable', generate-id(..)) and ancestor-or-self::Field[1]">[$PrimaryTable].[@primaryValue]</xsl:when>
			<xsl:otherwise>NULL</xsl:otherwise>
		</xsl:choose>
		,[@Mode]=[$Privileges].[$mode]<!--<xsl:choose>
      <xsl:when test="$mode='new' or $mode='filters' or $mode='fieldselector' or $mode='help'">
        '<xsl:value-of select="$mode" />'
      </xsl:when>
      <xsl:when test="string(@Mode)!=''">
        <xsl:apply-templates mode="Property.Value" select="@Mode" />
      </xsl:when>
      <xsl:otherwise>'inherit'</xsl:otherwise>
    </xsl:choose>-->
		/*Otros atributos por registro***/
		<xsl:for-each select="@*[not(name(.)='mode')][not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='foreignKey')][not(contains(.,'.value(') or contains(.,'.query(') or contains(.,'[$Field].'))]">
			,[@<xsl:value-of select="name(.)" />]=<xsl:apply-templates mode="Property.Value" select="current()" />
		</xsl:for-each>/***Otros atributos por registro*/
		/*Columnas de la tabla*/
		<xsl:for-each select="key('availableFields', generate-id(..))[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='identity')][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
			<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" /><xsl:if test="../../../@DataType='junctionTable' and @isPrimaryKey=1 and ForeignTable/@text">,[@linkedText]=[$Linked].[@displayText]</xsl:if><xsl:if test="../../../@DataType='junctionTable' and @isPrimaryKey=1">
				,[$Linked].[@order]
			</xsl:if>
			,[<xsl:value-of select="@Column_Name" />]=<xsl:choose>
				<xsl:when test="$mode='new'">
					<xsl:choose>
						<xsl:when test="@defaultValue">
							<xsl:apply-templates mode="Property.Value" select="@defaultValue" />
						</xsl:when>
						<xsl:otherwise>NULL</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$unBindPrimaryTable and key('primaryReference', generate-id())/@DataType='junctionTable'">NULL</xsl:when>
						<xsl:when test="key('primaryReference', generate-id())/@DataType='junctionTable' and key('foreignReference', generate-id())">[$PrimaryTable].[@primaryValue]</xsl:when>
						<xsl:when test="ancestor::Table[1]/../@DataType='junctionTable' and key('primaryKey', generate-id())[not(key('foreignReference', generate-id(.)))]">
							[$Linked].[<xsl:value-of select="ForeignTable/@primaryKey" />]
						</xsl:when>
						<xsl:when test="$mode='fieldselector' or $mode='help'">NULL</xsl:when>
						<xsl:when test="@DataType='junctionTable' or @DataType='foreignTable' or key('mode', generate-id(.))/@Mode='new' or $mode='filters'">NULL</xsl:when>
						<xsl:otherwise>
							[$Table].[<xsl:value-of select="@Column_Name" />]
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="Table/Record" mode="columns">
		<xsl:param name="unBindPrimaryTable" select="false()" />
		/*level: columns*/
		,[px:dataRow/@rowNumber]=[$PrimaryTable].[@rowNumber]
		,[px:dataRow/@identity]=[$PrimaryTable].[@identity]
		,[px:dataRow/@referenceValue]=[$PrimaryTable].[@referenceValue]
		<!--,[px:dataRow/@Mode]=CASE WHEN [attributes].[@Mode]='readonly' THEN NULL ELSE [$primaryTable].[@Mode] END
    ,[px:dataRow/@disableDelete]=[$primaryTable].[@disableDelete]-->
		<!--<xsl:for-each select="key('availableFields', generate-id(..))[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='identity')][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">-->
		<xsl:for-each select="key('availableFields', generate-id(..))[not(@DataType='identity')][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
			<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />/*field <xsl:value-of select="@Column_Name" />: <xsl:value-of select="@DataType" />*/
			<xsl:variable name="fieldName">
				<xsl:choose>
					<xsl:when test="@DataType='foreignTable' or @DataType='junctionTable' or @DataType='foreignKey'">px:relationship</xsl:when>
					<xsl:otherwise>px:field</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			,[px:dataRow]=NULL
			<xsl:choose>
				<xsl:when test="@DataType='foreignTable' or @DataType='junctionTable'">
					,[px:dataRow/<xsl:value-of select="$fieldName"/>]=[<xsl:value-of select="concat(*[1]/@Schema, '.', *[1]/@Name)"/>].data
				</xsl:when>
				<xsl:otherwise>
					,[px:dataRow/<xsl:value-of select="$fieldName"/>/@fieldId]='<xsl:value-of select="generate-id(.)" />'
					,[px:dataRow/<xsl:value-of select="$fieldName"/>/@value]=<xsl:choose>
						<xsl:when test="@DataType='foreignKey'" />
						<xsl:otherwise />
					</xsl:choose>RTRIM(ISNULL(<xsl:apply-templates mode="value" select="." />,''))
					<xsl:if test="not(ancestor::*[@Mode='fieldselector' or @Mode='help'])">
						,[px:dataRow/<xsl:value-of select="$fieldName"/>/@text]=<xsl:apply-templates mode="text" select="." /><xsl:if test="@DataType='foreignKey' and not(key('fieldbound', generate-id())) and (1=0 or not(@loadData='false'))">
							<xsl:if test="1=0 and ../../@controlType='formview' and not(../../../@DataType='junctionTable')">
								,[px:dataRow/<xsl:value-of select="$fieldName"/>/px:data]=( SELECT * FROM <xsl:apply-templates mode="node" select="key('ForeignTable', generate-id(ForeignTable[1]))">
									<xsl:with-param name="mode">data</xsl:with-param>
								</xsl:apply-templates> FOR XML AUTO, TYPE )
							</xsl:if>
							,[px:dataRow/<xsl:value-of select="$fieldName"/>]=<xsl:apply-templates mode="node" select="." />
						</xsl:if>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		/*fin level: columns*/
	</xsl:template>

	<xsl:template match="Table/Record" mode="relationships">
		<xsl:for-each select="key('availableFields', generate-id(..))[@DataType='foreignTable' or @DataType='junctionTable'][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
			<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
			OUTER APPLY (
			/*<xsl:value-of select="name(*)"/>*/<xsl:apply-templates mode="node" select="*"/>
			) [<xsl:value-of select="concat(*[1]/@Schema, '.', *[1]/@Name)"/>](data)
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="Table/Record" mode="foreignTables">
		<xsl:param name="scope" />
		<xsl:for-each select="key('availableFields', generate-id(..))[@DataType='foreignTable' or @DataType='junctionTable'][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
			<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
			<xsl:variable name="fieldName">
				<xsl:value-of select="@Name" />
			</xsl:variable>
			,[<xsl:value-of select="$fieldName" />/@fieldId]='<xsl:value-of select="generate-id(.)" />'<xsl:if test="@Mode[substring(string(.), 1, 10)!='CASE WHEN ']">
				,[<xsl:value-of select="$fieldName" />/@Mode]=[@Mode]
			</xsl:if><xsl:apply-templates mode="Attributes" select="ancestor-or-self::*[@fieldSet][1]/@fieldSet|@*[substring(string(.), 1, 10)='CASE WHEN ']">
				<xsl:with-param name="Column_Name" select="@Column_Name" />
			</xsl:apply-templates><xsl:choose>
				<xsl:when test="(@DataType='foreignTable' or @DataType='junctionTable') and (ancestor-or-self::*[@Mode!='inherit'][1]/@Mode!='none' or (@controlType='inlineTable' or @controlType='embeddedTable')) and *">
					,[<xsl:value-of select="$fieldName" />]=( <xsl:apply-templates mode="node" select="*">
						<xsl:with-param name="scope" select="$scope" />
					</xsl:apply-templates>)
				</xsl:when>
				<xsl:when test="(@DataType='foreignTable' or @DataType='junctionTable')">
					, [<xsl:value-of select="$fieldName" />]=CONVERT(xml, NULL)
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template mode="groupName" match="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer">
		<xsl:text>layout:</xsl:text>
		<xsl:value-of select="name(.)" />
		<xsl:text>/</xsl:text>
	</xsl:template>
	<xsl:template match="@fieldContainer" mode="container.attributes">
		<!-- Sólo para cabezas de grupo -->
		<xsl:param name="prefix" />
		<xsl:variable name="container" select="." />
		<xsl:for-each select="../@*[starts-with(local-name(.), concat(local-name($container),'.'))]">
			<xsl:text>,[</xsl:text>
			<xsl:value-of select="$prefix" />
			<xsl:text>@</xsl:text>
			<xsl:call-template name="replace">
				<xsl:with-param name="inputString" select="name(.)" />
				<xsl:with-param name="searchText" select="concat(name($container),'.')" />
				<xsl:with-param name="replaceBy" />
			</xsl:call-template>
			<xsl:text>]='</xsl:text>
			<xsl:value-of select="." />
			<xsl:text>'</xsl:text>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="Table/Record/*" mode="tree">
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
		<xsl:apply-templates mode="groups" select="following-sibling::*[1]">
			<xsl:with-param name="paramGroupTabPanel" select="msxsl:node-set($groups)/*/@groupTabPanel" />
			<xsl:with-param name="paramSubGroupTabPanel" select="msxsl:node-set($groups)/*/@subGroupTabPanel" />
			<xsl:with-param name="paramPortlet" select="msxsl:node-set($groups)/*/@portlet" />
			<xsl:with-param name="paramTabPanel" select="msxsl:node-set($groups)/*/@tabPanel" />
			<xsl:with-param name="paramTab" select="msxsl:node-set($groups)/*/@tab" />
			<xsl:with-param name="paramFieldSet" select="msxsl:node-set($groups)/*/@fieldSet" />
			<xsl:with-param name="paramFieldContainer" select="msxsl:node-set($groups)/*/@fieldContainer" />
		</xsl:apply-templates>
	</xsl:template>

	<!--#region Generic Types-->
	<xsl:template mode="genericType" match="@*">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='tinyint' or .='smallint' or .='int' or .='bigint']">integer</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='float' or .='numeric' or .='real']">decimal</xsl:template>
	<xsl:template mode="genericType" match="@DataType[contains(.,'time')]">time</xsl:template>
	<xsl:template mode="genericType" match="@DataType[contains(.,'datetime')]">datetime</xsl:template>
	<xsl:template mode="genericType" match="@DataType[contains(.,'money')]">money</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='bit']">boolean</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='nvarchar' or .='varchar' or .='nchar' or .='char' or .='text' or .='ntext' or .='sql_variant']">string</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='timestamp' or contains(.,'binary')]">binary</xsl:template>
	<xsl:template mode="genericType" match="*[@controlType='image' or @controlType='file' or @controlType='password']/@DataType">
		<xsl:value-of select="../@controlType"/>
	</xsl:template>
	<xsl:template mode="genericType" match="@DataType[.='foreignKey' or .='junctionTable' or .='foreignTable']">relationship</xsl:template>
	<!--#endregion Generic Types-->

	<xsl:template match="*" mode="layout">
		<xsl:param name="scope" select="'fields'" />
		<xsl:param name="currentField" select="." />
		<xsl:param name="fields" />
		<xsl:param name="field" select="$fields/*[generate-id()=$currentField/@fieldId]" />

		<xsl:variable name="fieldName">
			<xsl:choose>
				<xsl:when test="$scope='fields'">
					<xsl:text>px:</xsl:text>
					<xsl:apply-templates mode="genericType" select="@DataType"/>
				</xsl:when>
				<xsl:otherwise>layout:field</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="ignoreField" select="boolean($scope!='fields' and not($field[key('renderField', generate-id())]))" />

		/*, <xsl:value-of select="position()"/> (<xsl:value-of select="$field/@Column_Name"/> :: <xsl:value-of select="@fieldId"/>/<xsl:value-of select="generate-id($field)"/>): { ignoreField: <xsl:value-of select="$ignoreField"/>, <xsl:for-each select="@*">
			<xsl:text>,
			</xsl:text>
			<xsl:value-of select="name(.)"/>
			<xsl:text>: </xsl:text>
			<xsl:value-of select="."/>
		</xsl:for-each>}*/

		<xsl:if test="$field[key('availableFields', generate-id())][not(key('foreignReference', generate-id()))][not($ignoreField)][$columnList='' or not(key('RequestedTable', generate-id(../..))) or key('RequestedTable', generate-id(../..)) and @Column_Name=msxsl:node-set($columnList)/*/dataTable/dataRow/dataField[text()='1']/@name]">
			<xsl:variable name="prefix">
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer" />
				</xsl:if>
			</xsl:variable>
			<xsl:if test="@changeGroupTabPanel and @groupTabPanel">
				<xsl:text>,[</xsl:text><xsl:if test="$scope!='fields'" />DUMMY]=NULL<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@groupTabPanel" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changeSubGroupTabPanel and @subGroupTabPanel">
				<xsl:text>,[</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel" />
				</xsl:if>
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@subGroupTabPanel" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changePortlet and @portlet">
				<xsl:text>,[</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel" />
				</xsl:if>
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@portlet" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changeTabPanel and @tabPanel">
				<xsl:text>,[</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet" />
				</xsl:if>
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@tabPanel" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changeTab and @tab">
				<xsl:text>,[</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel" />
				</xsl:if>
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@tab" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changeFieldSet and @fieldSet">
				<xsl:text>,[</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab" />
				</xsl:if>
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text>
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet" />
					</xsl:if>
					<xsl:text>@name]='</xsl:text>
					<xsl:value-of select="@fieldSet" />
					<xsl:text>'</xsl:text>
				</xsl:if>
			</xsl:if>
			<xsl:if test="@changeFieldContainer and @fieldContainer">
				<xsl:variable name="pathPrefix">
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet" />
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="fullPathPrefix">
					<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
						<xsl:apply-templates mode="groupName" select="@groupTabPanel|@subGroupTabPanel|@portlet|@tabPanel|@tab|@fieldSet|@fieldContainer" />
					</xsl:if>
				</xsl:variable>

				<xsl:text>,[</xsl:text>
				<xsl:value-of select="$pathPrefix" />
				<xsl:text>DUMMY]=NULL</xsl:text>
				<xsl:if test="$scope!='fields' and not($field/ancestor::*/@Mode='filters')">
					<xsl:text>,[</xsl:text><xsl:value-of select="$fullPathPrefix" />
					<xsl:text>@name]='</xsl:text><xsl:value-of select="@fieldContainer" />'
					<xsl:apply-templates mode="container.attributes" select="@fieldContainer">
						<xsl:with-param name="prefix" select="$fullPathPrefix" />
					</xsl:apply-templates>
				</xsl:if>
			</xsl:if>
			<xsl:variable name="id_name">
				<xsl:choose>
					<xsl:when test="$scope='layout'">refId</xsl:when>
					<xsl:otherwise>fieldId</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="field_name">
				<xsl:choose>
					<xsl:when test="$scope='layout'">fieldName</xsl:when>
					<xsl:otherwise>fieldName</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:text>,
			[</xsl:text>
			<xsl:value-of select="concat($prefix,$fieldName,'/')" />
			<xsl:text>@</xsl:text>
			<xsl:value-of select="$id_name" />
			<xsl:text>]='</xsl:text>
			<xsl:value-of select="@fieldId" />
			<xsl:text>'</xsl:text>
			<xsl:text>
			,[</xsl:text>
			<xsl:value-of select="concat($prefix,$fieldName,'/')" />
			<xsl:text>@</xsl:text>
			<xsl:value-of select="$field_name" />
			<xsl:text>]='</xsl:text>
			<xsl:value-of select="@Name" />
			<xsl:text>'</xsl:text>
			<xsl:if test="$scope='fields'">
				<xsl:apply-templates mode="Attributes" select="$field/@*[not(name(.)='mode') or name(.)='mode' and substring(string(.), 1, 10)!='CASE WHEN ']">
					<xsl:with-param name="Column_Name" select="concat($prefix,$fieldName)" />
					<xsl:with-param name="escape" select="true()" />
				</xsl:apply-templates>
				<xsl:for-each select="$field">
					<xsl:choose>
						<xsl:when test="not(ancestor::*[@Mode='fieldselector' or @Mode='help']) and @DataType='foreignKey'">
							<xsl:apply-templates mode="node" select=".">
								<xsl:with-param name="path" select="$prefix"/>
							</xsl:apply-templates>
							<!--, [<xsl:value-of select="concat($prefix,$fieldName)" />]=<xsl:apply-templates mode="node" select="."/> Versión alterna-->
							<!--<xsl:if test="@controlType='radiogroup'">
								, [<xsl:value-of select="concat($prefix,$fieldName)" />/px:data]=( SELECT * FROM <xsl:apply-templates mode="node" select="key('ForeignTable', generate-id(ForeignTable[1]))">
									<xsl:with-param name="mode">data</xsl:with-param>
									<xsl:with-param name="scope" select="$scope" />
								</xsl:apply-templates> FOR XML AUTO, TYPE )
							</xsl:if>-->
						</xsl:when>
						<!--<xsl:when test="not(ancestor::*[@Mode='fieldselector' or @Mode='help']) and ((@DataType='foreignTable' or @DataType='junctionTable') and (ancestor-or-self::*[@Mode!='inherit'][1]/@Mode!='none' or (@controlType='inlineTable' or @controlType='embeddedTable')) and *)">
							, [<xsl:value-of select="concat($prefix,$fieldName)" />]=( <xsl:apply-templates mode="node" select="*">
								<xsl:with-param name="unBindPrimaryTable" select="true()" />
								<xsl:with-param name="scope" select="$scope" />
							</xsl:apply-templates>)
						</xsl:when>-->
					</xsl:choose>
				</xsl:for-each>
			</xsl:if>
			<xsl:text>,[</xsl:text>
			<xsl:value-of select="$prefix" />
			<xsl:text>DUMMY]=NULL</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template mode="copy" match="*">
		<xsl:param name="namespace">px:</xsl:param>
		<xsl:param name="path"></xsl:param>
		<xsl:variable name="localpath">
			<xsl:value-of select="$namespace"/>
			<xsl:value-of select="name(.)"/>
			<xsl:text>/</xsl:text>
		</xsl:variable>
		<xsl:for-each select="@*">
			<xsl:text>,[</xsl:text>
			<xsl:value-of select="$path"/>
			<xsl:value-of select="$localpath"/>
			<xsl:text>@</xsl:text>
			<xsl:value-of select="name(.)"/>
			<xsl:text>]='</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>'</xsl:text>
		</xsl:for-each>
		,<xsl:if test="$path!=''">[<xsl:value-of select="substring($path,1,string-length($path)-1)"/>]=</xsl:if>
		<xsl:text>NULL</xsl:text>
		<xsl:apply-templates mode="copy" select="*" >
			<xsl:with-param name="path" select="concat($path,$namespace,name(),'/')"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template mode="copy" match="Relationship">
		<xsl:param name="namespace">px:</xsl:param>
		<xsl:param name="path"></xsl:param>
		<xsl:variable name="localpath">
			<xsl:value-of select="$namespace"/>
			<xsl:value-of select="translate(name(.),$uppercase,$smallcase)"/>
			<xsl:text>/</xsl:text>
		</xsl:variable>
		<xsl:for-each select="@*">
			<xsl:text>,[</xsl:text>
			<xsl:value-of select="$path"/>
			<xsl:value-of select="$localpath"/>
			<xsl:text>@</xsl:text>
			<xsl:value-of select="name(.)"/>
			<xsl:text>]='</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>'</xsl:text>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="queryDefinition">
		<xsl:param name="mode" />
		<xsl:param name="unBindPrimaryTable" select="false()" />
		FROM <xsl:call-template name="viewDefinition" /> [$Table] CROSS APPLY (
		SELECT TOP 1 *, [$mode]=<xsl:choose>
			<xsl:when test="Record/@Mode">
				<xsl:value-of select="Record/@Mode"/>
			</xsl:when>
			<xsl:otherwise>'inherit'</xsl:otherwise>
		</xsl:choose>
		FROM @@Privileges [$Privileges] WHERE [$Privileges].[$UserId]=@@UserId
		<xsl:choose>
			<xsl:when test="ancestor-or-self::Relationship[1]/@DataType='junctionTable'">
				AND [$Privileges].[$SchemaName]='<xsl:value-of select="ancestor-or-self::Relationship[1]/../../@Schema" />'
				AND [$Privileges].[$CatalogName]='<xsl:value-of select="ancestor-or-self::Relationship[1]/../../@Name" />'
			</xsl:when>
			<xsl:otherwise>
				AND [$Privileges].[$SchemaName]='<xsl:value-of select="@Schema" />'
				AND [$Privileges].[$CatalogName]='<xsl:value-of select="@Name" />'
			</xsl:otherwise>
		</xsl:choose>
		AND [$Privileges].[$R]=1 <xsl:if test="string(@filters)!='' and not(@filtersBehavior='replace' and $filters!='')">
			AND (<xsl:value-of select="@filters" />)
		</xsl:if><xsl:if test="key('RequestedTable', generate-id(current()))"> /*#filters#*/</xsl:if>
		) [$Privileges]
		<xsl:choose>
			<xsl:when test="ancestor-or-self::Relationship[1]/@DataType='junctionTable'">
				RIGHT OUTER JOIN <xsl:for-each select="Record/Relationship[key('primaryKey',generate-id())][not(key('foreignReference', generate-id()))]">
					(SELECT [@displayText]=<xsl:value-of select="ForeignTable/@text" />,
					[@order]=<xsl:choose>
						<xsl:when test="ForeignTable/@orderBy">
							ROW_NUMBER() OVER(ORDER BY <xsl:value-of select="ForeignTable/@orderBy" />)
						</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
					, * FROM [<xsl:value-of select="ForeignTable/@Schema" />].[<xsl:value-of select="ForeignTable/@Name" />]) [$Linked] ON [$Linked].[<xsl:value-of select="ForeignTable/@primaryKey" />]=[$Table].[<xsl:value-of select="@Name" />]
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise> WHERE NOT([$mode]='none') </xsl:otherwise>
		</xsl:choose><xsl:choose>
			<xsl:when test="not(key('RequestedTable', generate-id(current()))) and ancestor-or-self::Relationship[1] and not($unBindPrimaryTable)">
				AND ([$Table].[<xsl:value-of select="ancestor-or-self::Relationship[1]/@foreignReference" />]=[$PrimaryTable].[@primaryValue]<xsl:if test="ancestor-or-self::Relationship[1]/@DataType='junctionTable'">
					OR [$PrimaryTable].[@primaryValue] IS NULL AND [$Table].[<xsl:value-of select="ancestor-or-self::Relationship[1]/@foreignReference" />] IS NULL
				</xsl:if>)/*<xsl:value-of select="$unBindPrimaryTable" />*/
			</xsl:when>
			<xsl:otherwise />
		</xsl:choose><xsl:choose>
			<xsl:when test="ancestor-or-self::Relationship[1]/@DataType='junctionTable'"> WHERE NOT([$mode]='none') </xsl:when>
			<xsl:otherwise />
		</xsl:choose>
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