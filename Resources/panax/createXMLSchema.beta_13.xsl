<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.panaxit.com"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"

  xmlns:px="http://www.panaxit.com"
  xmlns:layout="http://www.panaxit.com/layout"
  xmlns:session="http://www.panaxit.com/session"
  xmlns:custom="http://www.panaxit.com/custom"
  xmlns:debug="http://www.panaxit.com/debug"
  xmlns:extjs="http://www.panaxit.com/extjs"
  xmlns:balsamiq="http://www.panaxit.com/balsamiq"

  extension-element-prefixes="msxsl">
	<xsl:output method="text" indent="no" encoding="utf-8"/>
	<xsl:key name="Tables" match="/root/Tables/Table" use="concat('[',@TableSchema,'].[',@TableName,']')" />
	<xsl:key name="ForeignKeys" match="/root/ForeignKeys/ForeignKey" use="concat('[',@TableSchema,'].[',@TableName,'].[]')" />
	<xsl:key name="ForeignKeys" match="/root/ForeignKeys/ForeignKey" use="concat('[',@TableSchema,'].[',@TableName,'].[',@ColumnName,']')" />
	<xsl:key name="Relationships" match="/root/ForeignKeys/ForeignKey" use="concat('[',@TableSchema,'].[',@TableName,']:[',@RelationshipName,']')" />
	<xsl:key name="ForeignKeys.ByParent" match="/root/ForeignKeys/ForeignKey[@OrdinalPosition=1]" use="concat('[',@TableSchema,'].[',@TableName,'].[',@ParentTableSchema,'].[',@ParentTableName,']')" />
	<xsl:variable name="TableSchema"></xsl:variable>
	<xsl:variable name="TableName"></xsl:variable>

	<!--<xsl:template match="*" mode="mode">
    <xsl:choose>
      <xsl:when test="string(@Mode)!='' and string(@scaffold)!='false'">
        <xsl:value-of select="@Mode"/>
      </xsl:when>
      <xsl:when test="name(.)='Field' and ancestor-or-self::*/@Mode='filters' and @IsNullable=1 and not(ancestor-or-self::*/@autoCreateFilters='false')">none</xsl:when>
      <xsl:when test="not(ancestor::*[@Mode='filters']) and @DataType='foreignTable' and string(@scaffold)!='false' and (string(@controlType)!='' and @controlType!='default' or @RelationshipType='hasOne')">inherit</xsl:when>
      <xsl:when test="@DataType='foreignTable' and key('Tables',concat('[',@ForeignSchema,'].[',@ForeignTable,']'))/@onDelete='CASCADE' and string(@scaffold)!='false'">inherit</xsl:when>
      <xsl:when test="@DataType='foreignTable' and string(@scaffold)!='true'">none</xsl:when>
      -->
	<!--  and (not(string(@controlType)!='' and @controlType!='default')) -->
	<!--
      <xsl:when test="@SupportsUpdate='0' and @SupportsInsert='0'">readonly</xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>-->

	<xsl:template mode="namespace" match="*">http://www.panaxit.com</xsl:template>
	<xsl:template mode="namespace" match="Table|Record|Field"></xsl:template>

	<xsl:template match="*" mode="scaffold">
		<xsl:choose>
			<xsl:when test="@DataType='foreignTable' and string(@scaffold)!='false' and (string(@controlType)!='' and @controlType!='default' or @RelationshipType='hasOne' or @moveAfter!=' or @moveBefore!=')">true</xsl:when>
			<xsl:when test="string(@scaffold)!=''">
				<xsl:value-of select="@scaffold"/>
			</xsl:when>
			<xsl:when test="@DataType='foreignTable' and string(@scaffold)=''">false</xsl:when>
			<xsl:otherwise>true</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/root/ForeignKeys/ForeignKey" mode="scaffold">
		<xsl:choose>
			<xsl:when test="@IsNullable=0 and not(preceding-sibling::*[@TableSchema=current()/@TableSchema and @TableName=current()/@TableName]/@IsNullable=0 or following-sibling::*[@TableSchema=current()/@TableSchema and @TableName=current()/@TableName]/@IsNullable=0)">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--<xsl:template mode="mode" match="Parameters|Parameter|PrimaryKeys|PrimaryKey"></xsl:template>-->

	<xsl:template mode="copyattributes" match="@*">
		<xsl:attribute name="{name(.)}">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template mode="copyattributes" match="@Mode|@ObjectId|@Identifier|@TableType|@TableId|@TableSchema|@TableName|Field/@ColumnName|Field/@Name|Table/@Name|Table/@Schema|@RelationshipType|@ForeignSchema|@ForeignTable"/>
	<!--No copia nada-->

	<xsl:template name="attributes.all" mode="attributes" match="*">
		<xsl:apply-templates mode="copyattributes" select="@*"/>
	</xsl:template>

	<xsl:template mode="attributes" match="Field">
		<xsl:call-template name="attributes.all"/>
	</xsl:template>

	<xsl:template mode="attributes" match="Tables/Table">
		<xsl:call-template name="attributes.all"/>
		<xsl:attribute name="xml:lang">es</xsl:attribute>
	</xsl:template>

	<xsl:template mode="attributes" match="ForeignKeys/ForeignKey">
		<xsl:attribute name="headerText">
			<xsl:for-each select="key('Relationships',concat('[',@TableSchema,'].[',@TableName,']:[',@RelationshipName,']'))">
				<xsl:variable name="field" select="@ColumnName"/>
				<xsl:if test="position()&gt;1"> / </xsl:if>
				<xsl:value-of select="key('Tables', concat('[',@TableSchema,'].[',@TableName,']'))/Record/Field[@Name=$field]/@headerText"/>
			</xsl:for-each>
		</xsl:attribute>
		<xsl:apply-templates mode="copyattributes" select="@onDelete|@onUpdate"/>
	</xsl:template>

	<xsl:template name="Routes">
		<xsl:if test="@SupportsInsert=1">
			<xsl:element name="Route">
				<xsl:attribute name="Id">
					<xsl:value-of select="concat('A',generate-id())"/>
				</xsl:attribute>
				<xsl:attribute name="url">
					<xsl:text>/[</xsl:text>
					<xsl:value-of select="@Schema"/>
					<xsl:text>]</xsl:text>
					<xsl:text>/[</xsl:text>
					<xsl:value-of select="@Name"/>
					<xsl:text>]/add</xsl:text>
					<!--<xsl:for-each select="PrimaryKeys/PrimaryKey">
            <xsl:text>/{</xsl:text>
            <xsl:value-of select="@Column_Name"/>
            <xsl:text>}</xsl:text>
          </xsl:for-each>-->
				</xsl:attribute>
				<xsl:attribute name="Method">new</xsl:attribute>
				<xsl:attribute name="controlType">button</xsl:attribute>
				<xsl:attribute name="enabled">true</xsl:attribute>
				<xsl:element name="Param">
					<xsl:attribute name="name">schemaName</xsl:attribute>
					<xsl:value-of select="@Schema"/>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">catalogName</xsl:attribute>
					<xsl:value-of select="@Name"/>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">mode</xsl:attribute>
					<xsl:text>edit</xsl:text>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">controlType</xsl:attribute>
					<xsl:text>formview</xsl:text>
				</xsl:element>
			</xsl:element>
		</xsl:if>
		<xsl:if test="@SupportsUpdate=1">
			<xsl:element name="Route">
				<xsl:attribute name="Id">
					<xsl:value-of select="concat('E',generate-id())"/>
				</xsl:attribute>
				<xsl:attribute name="url">
					<xsl:text>/[</xsl:text>
					<xsl:value-of select="@Schema"/>
					<xsl:text>]</xsl:text>
					<xsl:text>[</xsl:text>
					<xsl:value-of select="@Name"/>
					<xsl:text>]/edit</xsl:text>
					<xsl:for-each select="PrimaryKeys/PrimaryKey">
						<xsl:text>/{</xsl:text>
						<xsl:value-of select="@Column_Name"/>
						<xsl:text>}</xsl:text>
					</xsl:for-each>
				</xsl:attribute>
				<xsl:attribute name="Method">edit</xsl:attribute>
				<xsl:attribute name="controlType">button</xsl:attribute>
				<xsl:attribute name="enabled">true</xsl:attribute>
				<xsl:element name="Param">
					<xsl:attribute name="name">schemaName</xsl:attribute>
					<xsl:value-of select="@Schema"/>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">catalogName</xsl:attribute>
					<xsl:value-of select="@Name"/>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">mode</xsl:attribute>
					<xsl:text>edit</xsl:text>
				</xsl:element>
				<xsl:element name="Param">
					<xsl:attribute name="name">controlType</xsl:attribute>
					<xsl:text>formview</xsl:text>
				</xsl:element>
			</xsl:element>
		</xsl:if>
		<!--<xsl:if test="@SupportsDelete=1">
      <xsl:element name="Route">
        <xsl:attribute name="Id">
          <xsl:value-of select="concat('D',generate-id())"/>
        </xsl:attribute>
        <xsl:attribute name="Method">delete</xsl:attribute>
        <xsl:attribute name="controlType">button</xsl:attribute>
        <xsl:attribute name="enabled">true</xsl:attribute>
        <xsl:element name="Param">
          <xsl:attribute name="name">schemaName</xsl:attribute>
          <xsl:value-of select="@Schema"/>
        </xsl:element>
        <xsl:element name="Param">
          <xsl:attribute name="name">catalogName</xsl:attribute>
          <xsl:value-of select="@Name"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>-->
	</xsl:template>

	<xsl:template match="Table" mode="Routes">
		<!--TODO: Hacer la búsqueda en profundidad para tener un solo nodo Routes-->
		<!--TODO: Hacer la ruta para las tablas dependientes agregando los parámetros necesarios para navegar-->
		<xsl:element name="Routes">
			<xsl:call-template name="Routes"/>
			<xsl:for-each select="key('ForeignKeys',concat('[',@Schema,'].[',@Name,'].[]'))[@OrdinalPosition=1]">
				<xsl:sort select="@ParentTableSchema" order="ascending"/>
				<xsl:sort select="@ParentTableName" order="ascending"/>
				<xsl:if test="count(.|key('ForeignKeys.ByParent',concat('[',@TableSchema,'].[',@TableName,'].[',@ParentTableSchema,'].[',@ParentTableName,']'))[1])=1">
					<xsl:for-each select="key('Tables', concat('[',@ParentTableSchema,'].[',@ParentTableName,']'))">
						<xsl:call-template name="Routes"/>
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>

	<xsl:template mode="processNode" match="*">
		<xsl:param name="lastNode" select="."/>
		<xsl:param name="referencerFK" select="/"/>
		<xsl:param name="path" select="'/'" />
		<xsl:param name="localpath" select="'/'" />
		<xsl:param name="tables" select="concat('[',@TableSchema,'].[',@TableName,']')"/>
		<xsl:param name="depth" select="0"/>
		<xsl:variable name="currentNode" select="."/>
		<xsl:variable name="scaffold">
			<xsl:apply-templates mode="scaffold" select="."/>
		</xsl:variable>
		<!--<xsl:if test="$scaffold='true'">-->
		<!--<xsl:variable name="mode">
        <xsl:apply-templates mode="mode" select="."/>
      </xsl:variable>-->
		<xsl:if test="name(.)='Record'">
			<xsl:apply-templates mode="Routes" select=".."/>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@DataType='foreignKey'">
				<xsl:apply-templates mode="Relationships" select=".">
					<xsl:with-param name="referencerFK" select="$referencerFK"/>
					<xsl:with-param name="path" select="$path" />
					<xsl:with-param name="localpath" select="$localpath" />
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="@DataType='foreignTable' or @DataType='junctionTable'">
				<xsl:variable name="dependantFK" select="key('ForeignKeys',concat('[',@ForeignSchema,'].[',@ForeignTable,'].[]'))[@ParentTableSchema=$currentNode/@TableSchema and @ParentTableName=$currentNode/@TableName]"/>
				<xsl:if test="$depth&lt;100 and not(contains($path, concat('/', @TableSchema, '.', @TableName, ':', $dependantFK[@OrdinalPosition=1]/@RelationshipName, '/')))">
					<!--and (@scaffold='true' or @DataType='junctionTable' or @controlType='inlineTable' or @controlType='embeddedTable')-->
					<!--<node tables="{$tables}"></node>-->
					<xsl:element name="Relationship" namespace="">
						<xsl:attribute name="Name">
							<xsl:value-of select="@Name"/>
						</xsl:attribute>
						<xsl:attribute name="Type">
							<xsl:value-of select="$dependantFK[1]/@RelationshipType"/>
						</xsl:attribute>
						<xsl:attribute name="RelationshipName">
							<xsl:value-of select="$dependantFK[1]/@RelationshipName"/>
						</xsl:attribute>
						<xsl:attribute name="TableSchema">
							<xsl:value-of select="$dependantFK[1]/@TableSchema" />
						</xsl:attribute>
						<xsl:attribute name="TableName">
							<xsl:value-of select="$dependantFK[1]/@TableName" />
						</xsl:attribute>
						<xsl:attribute name="scaffold">
							<xsl:value-of select="$scaffold" />
						</xsl:attribute>
						<xsl:attribute name="controlType">
							<xsl:apply-templates mode="controlType" select="."/>
						</xsl:attribute>
						<!--TODO: Definir el tipo de control según el tipo de relación, por ejemplo fieldset para hasOne -->
						<xsl:apply-templates mode="attributes" select="."/>
						<xsl:variable name="primaryTable" select="ancestor-or-self::Table[1]"/>
						<xsl:element name="Mappings">
							<xsl:for-each select="$primaryTable/PrimaryKeys/PrimaryKey">
								<xsl:variable name="referencedField" select="key('Relationships', concat('[',$dependantFK[1]/@TableSchema,'].[',$dependantFK[1]/@TableName,']:[',$dependantFK[1]/@RelationshipName,']'))[@ParentTableSchema=$primaryTable/@Schema and @ParentTableName=$primaryTable/@Name and @ParentColumnName=current()/@Column_Name]"/>
								<xsl:element name="Map">
									<xsl:attribute name="Key">
										<xsl:value-of select="@Column_Name"/>
									</xsl:attribute>
									<xsl:attribute name="Map">
										<xsl:value-of select="$referencedField/@ColumnName"/>
									</xsl:attribute>
								</xsl:element>
							</xsl:for-each>
						</xsl:element>
						<xsl:apply-templates mode="processNode" select="key('Tables',concat('[',@ForeignSchema,'].[',@ForeignTable,']'))">
							<xsl:with-param name="lastNode" select="."/>
							<xsl:with-param name="referencerFK" select="$dependantFK"/>
							<xsl:with-param name="path" select="concat($path, @TableSchema, '.', @TableName, ':', $dependantFK[1]/@RelationshipName, '/')"/>
							<xsl:with-param name="localpath" select="concat('/', @TableSchema, '.', @TableName, ':', $dependantFK[1]/@RelationshipName, '/')"/>
							<xsl:with-param name="depth" select="$depth+1"/>
						</xsl:apply-templates>
					</xsl:element>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="copy">
					<xsl:with-param name="lastNode" select="$lastNode"/>
					<xsl:with-param name="referencerFK" select="$referencerFK"/>
					<xsl:with-param name="path" select="$path" />
					<xsl:with-param name="localpath" select="$localpath" />
					<xsl:with-param name="tables" select="$tables"/>
					<xsl:with-param name="depth" select="$depth"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		<!--</xsl:if>-->
	</xsl:template>

	<xsl:template mode="controlType" match="*">default</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='tinyint' or @DataType='smallint' or @DataType='int' or @DataType='bigint']">numericbox</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='float' or @DataType='numeric' or @DataType='real']">numericbox</xsl:template>
	<xsl:template mode="controlType" match="Field[contains(@DataType,'time')]">timebox</xsl:template>
	<xsl:template mode="controlType" match="Field[contains(@DataType,'date')]">datebox</xsl:template>
	<xsl:template mode="controlType" match="Field[contains(@DataType,'datetime')]">datetimebox</xsl:template>
	<xsl:template mode="controlType" match="Field[contains(@DataType,'money')]">moneybox</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='bit']">checkbox</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='bit' and @IsNullable='1']">tristatecheckbox</xsl:template>
	<xsl:template mode="controlType" match="Field[contains(@DataType,'char') or contains(@DataType,'text') or @DataType='sql_variant']">textbox</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='timestamp' or contains(@DataType,'binary')]">default</xsl:template>
	<xsl:template mode="controlType" match="Field[@IsIdentity='1']">hiddenbox</xsl:template>

	<xsl:template mode="controlType" match="Field[@DataType='foreignTable']">tab</xsl:template>
	<xsl:template mode="controlType" match="Field[@RelationshipType='belongsTo']">combobox</xsl:template>
	<xsl:template mode="controlType" match="Field[@RelationshipType='hasOne']">fieldset</xsl:template>
	<xsl:template mode="controlType" match="Field[@DataType='junctionTable']">fieldcontainer</xsl:template>

	<xsl:template mode="controlType" match="Table">formview</xsl:template>
	<xsl:template mode="controlType" match="Table[@Mode='readonly' and @pageSize&gt;1]">gridview</xsl:template>
	<xsl:template mode="controlType" match="*[string(@controlType)!='']">
		<xsl:value-of select="@controlType"/>
	</xsl:template>

	<xsl:template match="*" mode="copy">
		<xsl:param name="lastNode" select="."/>
		<xsl:param name="referencerFK"/>
		<xsl:param name="path" select="'/'" />
		<xsl:param name="localpath" select="'/'" />
		<xsl:param name="tables" select="concat('[',@TableSchema,'].[',@TableName,']')"/>
		<xsl:param name="depth" select="0"/>
		<xsl:variable name="namespace">
			<xsl:apply-templates select="." mode="namespace"/>
		</xsl:variable>
		<xsl:element name="{name()}" namespace="{$namespace}">
			<!--<xsl:apply-templates select="@*|node()" mode="copy" />-->
			<xsl:copy-of select="@Schema|@Name"/>
			<xsl:if test="generate-id($lastNode)=generate-id()">
				<xsl:attribute name="Mode">
					<xsl:value-of select="@Mode"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates mode="attributes" select="."/>
			<xsl:if test="@controlType or name(.)='Table' or name(.)='Field'">
				<xsl:attribute name="controlType">
					<xsl:choose>
						<xsl:when test="@controlType!=''">
							<xsl:value-of select="@controlType"/>
						</xsl:when>
						<xsl:when test="name(.)='Field'">
							<xsl:apply-templates mode="controlType" select="."></xsl:apply-templates>
						</xsl:when>
						<xsl:when test="name(.)='Table'">
							<xsl:choose>
								<xsl:when test="$lastNode/@RelationshipType='hasOne' and $lastNode/@DataType='foreignTable'">formview</xsl:when>
								<xsl:otherwise>gridview</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>NULL</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="name(.)='Field'">
				<xsl:attribute name="editable">
					<xsl:choose>
						<xsl:when test="@IsIdentity=1">true</xsl:when>
						<xsl:otherwise>inherit</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:attribute name="visible">
					<xsl:choose>
						<xsl:when test="@IsIdentity=1">false</xsl:when>
						<xsl:otherwise>true</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="*" mode="processNode">
				<xsl:sort select="self::*[@moveAfter]/../Field[@Name=current()/@moveAfter]/@ordinalPosition|self::*[@moveBefore]/../Field[@Name=current()/@moveBefore]/@ordinalPosition|self::*[not(@moveAfter or @moveBefore)]/@ordinalPosition" data-type="number" order="ascending" />
				<xsl:sort select="number(boolean(@moveBefore))" data-type="number" order="descending" />
				<xsl:sort select="number(boolean(@moveAfter))" data-type="number" order="ascending" />
				<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
				<xsl:with-param name="lastNode" select="."/>
				<xsl:with-param name="referencerFK" select="$referencerFK"/>
				<xsl:with-param name="depth" select="$depth+1"/>
				<xsl:with-param name="path" select="$path"/>
				<xsl:with-param name="localpath" select="$localpath" />
				<!--<xsl:with-param name="tables" select="$tables"/>-->
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<xsl:template match="@*|text()|comment()" mode="copy">
		<xsl:copy/>
	</xsl:template>


	<xsl:template match="/">
		<xsl:apply-templates mode="processNode" select="root/Tables/Table[@TableName=$TableName and @TableSchema=$TableSchema]"/>
	</xsl:template>

	<xsl:template match="*" mode="Relationships">
		<xsl:param name="path" select="'/'" />
		<xsl:param name="localpath" select="'/'" />
		<xsl:param name="referencerFK" select="/"/>

		<!--Por default-->
		<xsl:variable name="referenceField" select="."/>
		<xsl:variable name="isReferenced" select="$referenceField/@Name=$referencerFK/@ColumnName"/>

		<xsl:variable name="foreignKeys" select="key('ForeignKeys',concat('[',@TableSchema,'].[',@TableName,'].[',@Name,']'))"/>
		<xsl:for-each select="$foreignKeys[@OrdinalPosition=1]">
			<xsl:variable name="currentFK" select="." />
			<xsl:variable name="scaffoldableFKs" select="key('ForeignKeys',concat('[',@TableSchema,'].[',@TableName,'].[]'))[@OrdinalPosition=1][@IsNullable=0]" />
			<xsl:variable name="scaffold">
				<xsl:choose>
					<!-- Si trae alguna configuración para scaffold la copia -->
					<xsl:when test="string($referenceField/@scaffold)!=''">
						<xsl:value-of select="$referenceField/@scaffold"/>
					</xsl:when>
					<xsl:when test="$isReferenced">false</xsl:when>
					<!-- Si hay algun hermano de tipo foreignKey con una configuración scaffold=true, entonces ya se calcula como false -->
					<xsl:when test="string($referenceField/../*[@DataType='foreignKey'][@scaffold='true'])!=''">false</xsl:when>
					<!--Todas las FKs de una Tabla tienen scaffold por default-->
					<xsl:when test="$localpath='/'">true</xsl:when>
					<!-- Si el constraint no está forzado-->
					<xsl:when test="number(@IsEnforced)!=1">false</xsl:when>
					<!--Si hay varias FKs que pueden ser escalonadas solamente va a marcar una si no permite nulos, si es la única lo hace-->
					<xsl:when test="count($scaffoldableFKs)=1 and $scaffoldableFKs/@RelationshipName=$currentFK/@RelationshipName">true</xsl:when>
					<!--contains(concat($localpath,'$'),concat('/', @TableSchema, '.', @TableName, ':', $dependantFK/@RelationshipName, '/', @ParentTableSchema, '.', @ParentTableName, '/','$'))-->
					<xsl:when test="count($scaffoldableFKs)=0 and @TableSchema=@ParentTableSchema and @TableName=@ParentTableName">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="primaryTable" select="key('Tables',concat('[',@ParentTableSchema,'].[',@ParentTableName,']'))"/>
			<xsl:if test="not($isReferenced or contains($path, concat('/', @TableSchema, '.', @TableName, ':', $currentFK/@RelationshipName, '/')))">
				<xsl:element name="Relationship" namespace="">
					<xsl:attribute name="Name">
						<xsl:for-each select="key('Relationships',concat('[',@TableSchema,'].[',@TableName,']:[',@RelationshipName,']'))">
							<xsl:variable name="field" select="@ColumnName"/>
							<xsl:if test="position()&gt;1">
								<xsl:text>-</xsl:text>
							</xsl:if>
							<xsl:value-of select="@ColumnName"/>
						</xsl:for-each>
					</xsl:attribute>
					<xsl:attribute name="Type">
						<xsl:value-of select="@RelationshipType"/>
					</xsl:attribute>
					<xsl:attribute name="RelationshipName">
						<xsl:value-of select="@RelationshipName"/>
					</xsl:attribute>
					<xsl:attribute name="TableSchema">
						<xsl:value-of select="@ParentTableSchema" />
					</xsl:attribute>
					<xsl:attribute name="TableName">
						<xsl:value-of select="@ParentTableName" />
					</xsl:attribute>
					<xsl:attribute name="scaffold">
						<xsl:value-of select="$scaffold" />
					</xsl:attribute>
					<xsl:if test="$isReferenced">
						<xsl:attribute name="debug:referencerFK">
							<xsl:value-of select="$referencerFK/@RelationshipName" />
						</xsl:attribute>
						<xsl:attribute name="debug:ColumnName">
							<xsl:value-of select="$referencerFK/@ColumnName" />
						</xsl:attribute>
					</xsl:if>
					<xsl:attribute name="controlType">
						<xsl:choose>
							<xsl:when test="key('ForeignKeys',concat('[',@ParentTableSchema,'].[',@ParentTableName,'].[]'))[@TableSchema=@ParentTableSchema and @TableName=@ParentTableName]">
								<xsl:text>treeview</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>combobox</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:attribute name="visible">
						<xsl:value-of select="$scaffold"/>
					</xsl:attribute>
					<xsl:attribute name="editable">
						<xsl:choose>
							<xsl:when test="@IsIdentity=1">false</xsl:when>
							<xsl:when test="ancestor-or-self::*[@Mode='readonly'][1]">false</xsl:when>
							<xsl:otherwise>true</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:attribute name="visible">
						<xsl:choose>
							<xsl:when test="@IsIdentity=1">false</xsl:when>
							<xsl:otherwise>true</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>

					<xsl:apply-templates mode="attributes" select="$referenceField"/>
					<xsl:apply-templates mode="attributes" select="."/>
					<xsl:attribute name="Type">belongsTo</xsl:attribute>
					<xsl:attribute name="debug:path">
						<xsl:value-of select="$path" />
					</xsl:attribute>
					<xsl:attribute name="debug:localpath">
						<xsl:value-of select="$localpath" />
					</xsl:attribute>
					<xsl:attribute name="text">
						<xsl:choose>
							<xsl:when test="string(@displayText)!=''">
								<xsl:value-of select="@displayText"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="displayText">
									<xsl:with-param name="TableSchema" select="@ParentTableSchema" />
									<xsl:with-param name="TableName" select="@ParentTableName" />
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:if test="not($primaryTable/@identityKey)">
						<xsl:attribute name="disableInsert">true</xsl:attribute>
					</xsl:if>
					<xsl:if test="@IsEnforced=0">
						<xsl:attribute name="EnforceConstraint">
							<xsl:value-of select="@IsEnforced" />
						</xsl:attribute>
					</xsl:if>
					<xsl:copy-of select="$primaryTable/@SupportsInsert|$primaryTable/@SupportsUpdate|$primaryTable/@SupportsDelete"/>
					<xsl:element name="Mappings">
						<xsl:for-each select="$primaryTable/PrimaryKeys/PrimaryKey">
							<xsl:variable name="referencedField" select="key('Relationships', concat('[',$currentFK/@TableSchema,'].[',$currentFK/@TableName,']:[',$currentFK/@RelationshipName,']'))[@ParentTableSchema=$primaryTable/@Schema and @ParentTableName=$primaryTable/@Name and @ParentColumnName=current()/@Column_Name]"/>
							<xsl:element name="Map">
								<xsl:attribute name="Key">
									<xsl:value-of select="@Column_Name"/>
								</xsl:attribute>
								<xsl:attribute name="Map">
									<xsl:value-of select="$referencedField/@ColumnName"/>
								</xsl:attribute>
							</xsl:element>
						</xsl:for-each>
					</xsl:element>
					<!--<xsl:if test="(not(contains($path, concat('/', @ParentTableSchema, '.', @ParentTableName, '/'))) or key('ForeignKeys',concat('[',@ParentTableSchema,'].[',@ParentTableName,'].[]'))[@ParentTableSchema=$currentFK/@TableSchema and @ParentTableName=$currentFK/@TableName] and not(contains($path, concat('/', @ParentTableSchema, '.', @ParentTableName, '/', @ParentTableSchema, '.', @ParentTableName, '/')))) and key('ForeignKeys',concat('[',@ParentTableSchema,'].[',@ParentTableName,'].[]'))">-->
					<xsl:if test="not($isReferenced)">
						<xsl:variable name="formerNode" select="."/>
						<xsl:for-each select="$primaryTable">
							<xsl:apply-templates mode="Relationships" select="$primaryTable/Record/Field[@DataType='foreignKey']">
								<xsl:with-param name="path" select="concat($path, $formerNode/@TableSchema, '.', $formerNode/@TableName, ':', $currentFK/@RelationshipName, '/')" />
								<xsl:with-param name="localpath" select="concat($localpath, $formerNode/@TableSchema, '.', $formerNode/@TableName, ':', $currentFK/@RelationshipName, '/')" />
							</xsl:apply-templates>
						</xsl:for-each>
					</xsl:if>
				</xsl:element>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="displayText">
		<xsl:param name="TableSchema" />
		<xsl:param name="TableName" />
		<xsl:variable name="table" select="key('Tables',concat('[',$TableSchema,'].[',$TableName,']'))"/>
		<xsl:choose>
			<xsl:when test="not($table)">'No se pudo recuperar información de la tabla'</xsl:when>
			<xsl:when test="string($table/@displayText)!=''">
				<xsl:value-of select="$table/@displayText"/>
			</xsl:when>
			<xsl:when test="count($table/*[name(.)='Fields' or name(.)='Record']/*[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='foreignKey')])=1">
				<xsl:text>[</xsl:text>
				<xsl:value-of select="$table/*[name(.)='Fields' or name(.)='Record']/*[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='foreignKey')]/@Name"/>
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="$table/*[name(.)='Fields' or name(.)='Record']/*[not(@DataType='foreignTable' or @DataType='junctionTable' or @DataType='xml' or @DataType='foreignKey' or @Name=$table/@identityKey)]">
					<xsl:sort select="@IsIdentity" data-type="number" order="ascending" />
					<xsl:sort select="@IsNullable" data-type="number" order="ascending" />
					<xsl:sort select="@IsPrimaryKey" data-type="number" order="descending" />
					<xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
					<xsl:if test="position()=1">
						<xsl:text>[</xsl:text>
						<xsl:value-of select="@Name"/>
						<xsl:text>]</xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>