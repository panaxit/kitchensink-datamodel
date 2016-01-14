<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	extension-element-prefixes="msxsl">
  <xsl:output method="text" indent="no" encoding="utf-8"/>
  <xsl:key name="Tables" match="/root/Tables/Table" use="concat('[',@Table_Schema,'].[',@Table_Name,']')" />
  <xsl:key name="ForeignKeys" match="/root/ForeignKeys/Table" use="concat('[',@tableSchema,'].[',@tableName,'].[]')" />
  <xsl:key name="ForeignKeys" match="/root/ForeignKeys/Table" use="concat('[',@tableSchema,'].[',@tableName,'].[',@columnName,']')" />

  <xsl:variable name="tableSchema"></xsl:variable>
  <xsl:variable name="tableName"></xsl:variable>

  <xsl:template match="*" mode="mode">
    <xsl:choose>
      <xsl:when test="string(@mode)!='' and string(@scaffold)!='false'">
        <xsl:value-of select="@mode"/>
      </xsl:when>
      <xsl:when test="name(.)='Field' and ancestor-or-self::*/@mode='filters' and @isNullable=1 and not(ancestor-or-self::*/@autoCreateFilters='false')">none</xsl:when>
      <xsl:when test="not(ancestor::*[@mode='filters']) and @dataType='foreignTable' and string(@scaffold)!='false' and (string(@controlType)!='' and @controlType!='default')">inherit</xsl:when>
      <xsl:when test="@dataType='foreignTable' and string(@scaffold)!='true'">none</xsl:when>
      <!--  and (not(string(@controlType)!='' and @controlType!='default')) -->
      <xsl:when test="@supportsUpdate='0' and @supportsInsert='0'">readonly</xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="scaffold">
    <xsl:param name="depth" select="0"/>
    <xsl:choose>
      <xsl:when test="@dataType='foreignTable' and string(@scaffold)!='false' and (string(@controlType)!='' and @controlType!='default' or @moveAfter!=' or @moveBefore!=')">true</xsl:when>
      <xsl:when test="string(@scaffold)!=''">
        <xsl:value-of select="@scaffold"/>
      </xsl:when>
      <xsl:when test="@dataType='foreignTable' and string(@scaffold)=''">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/root/ForeignKeys/Table" mode="scaffold">
    <xsl:choose>
      <xsl:when test="@isNullable=0 and not(preceding-sibling::*[@tableSchema=current()/@tableSchema and @tableName=current()/@tableName]/@isNullable=0 or following-sibling::*[@tableSchema=current()/@tableSchema and @tableName=current()/@tableName]/@isNullable=0)">true</xsl:when>
      <xsl:otherwise>false</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Parameters|Parameter|PrimaryKeys|PrimaryKey" mode="mode"></xsl:template>

  <xsl:template mode="duplicateNode" match="*">
    <xsl:param name="lastNode" select=".."/>
    <xsl:param name="path" select="concat('/', @Table_Schema, '.', @Table_Name, '/')" />
    <xsl:param name="tables" select="concat('[',@Table_Schema,'].[',@Table_Name,']')"/>
    <xsl:param name="depth" select="0"/>
    <xsl:variable name="scaffold">
      <xsl:apply-templates mode="scaffold" select=".">
        <xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$scaffold='true'">
      <xsl:variable name="mode">
        <xsl:apply-templates mode="mode" select="."/>
      </xsl:variable>
      <xsl:copy>
        <xsl:for-each select="@*[not(
			name(.)='mode' or
			name(.)='object_id' or
			name(.)='Identifier' or
			name(.)='Table_Type' or
			name(.)='table_id' or
			name(.)='column_id' or
			name(.)='controlType' or
			name(..)='Field' and (
				name(.)='Table_Schema' or 
				name(.)='Table_Name'
			)
		)]" >
          <xsl:attribute name="{name(.)}">
            <xsl:value-of select="."/>
          </xsl:attribute>
        </xsl:for-each>
        <xsl:if test="name(.)='Field'">
          <xsl:attribute name="ordinalPosition">
            <xsl:value-of select="position()"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="$mode!=''">
          <xsl:attribute name="mode">
            <xsl:value-of select="$mode"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="name(.)='Table'">
          <xsl:attribute name="xml:lang">es</xsl:attribute>
        </xsl:if>
        <xsl:if test="@controlType or name(.)='Table' or name(.)='Field'">
          <xsl:attribute name="controlType">
            <xsl:choose>
              <xsl:when test="@controlType!=''">
                <xsl:value-of select="@controlType"/>
              </xsl:when>
              <xsl:when test="name(.)='Field'">default</xsl:when>
              <xsl:when test="name(.)='Table'">
                <xsl:choose>
                  <xsl:when test="$lastNode/@relationshipType='hasOne'">formView</xsl:when>
                  <xsl:otherwise>gridView</xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>NULL</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="@dataType='foreignKey'">
            <xsl:call-template name="ForeignKeys">
              <xsl:with-param name="path" select="$path" />
              <xsl:with-param name="tableSchema" select="@Table_Schema" />
              <xsl:with-param name="tableName" select="@Table_Name" />
              <xsl:with-param name="columnName" select="@Column_Name" />
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="@dataType='foreignTable' or @dataType='junctionTable'">
            <xsl:variable name="dependantSchema" select="@foreignSchema" />
            <xsl:variable name="dependantTable" select="@foreignTable" />
            <xsl:if test="$depth&lt;100 and not(contains($path, concat('/', $dependantSchema, '.', $dependantTable, '/'))) and string(@scaffold)!='false'">
              <!--and (@scaffold='true' or @dataType='junctionTable' or @controlType='inlineTable' or @controlType='embeddedTable')-->
              <!--<node tables="{$tables}"></node>-->
              <xsl:apply-templates mode="duplicateNode" select="key('Tables',concat('[',$dependantSchema,'].[',$dependantTable,']'))">
                <xsl:with-param name="lastNode" select="."/>
                <xsl:with-param name="path" select="concat($path, $dependantSchema, '.', $dependantTable, '/')"/>
                <!--<xsl:with-param name="tables" select="concat($tables,'||','[',$dependantSchema,'].[',$dependantTable,']')"/>-->
                <xsl:with-param name="depth" select="$depth+1"/>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="*" mode="duplicateNode">
          <xsl:sort select="self::*[@moveAfter]/../Field[@Column_Name=current()/@moveAfter]/@ordinalPosition|self::*[@moveBefore]/../Field[@Column_Name=current()/@moveBefore]/@ordinalPosition|self::*[not(@moveAfter or @moveBefore)]/@ordinalPosition" data-type="number" order="ascending" />
          <xsl:sort select="number(boolean(@moveBefore))" data-type="number" order="descending" />
          <xsl:sort select="number(boolean(@moveAfter))" data-type="number" order="ascending" />
          <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
          <xsl:with-param name="lastNode" select="."/>
          <xsl:with-param name="depth" select="$depth+1"/>
          <xsl:with-param name="path" select="$path"/>
          <!--<xsl:with-param name="tables" select="$tables"/>-->
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates mode="duplicateNode" select="root/Tables/Table[@Table_Name=$tableName and @Table_Schema=$tableSchema]"/>
  </xsl:template>

  <xsl:template name="PrimaryKeys">
    <xsl:param name="path" select="'/'" />
    <xsl:param name="tableSchema" />
    <xsl:param name="tableName" />
    <xsl:param name="columnName" />
    <xsl:variable name="primaryTable" select="key('Tables',concat('[',$tableSchema,'].[',$tableName,']'))"/>
    <xsl:element name="ForeignTable">
      <xsl:attribute name="Table_Schema">
        <xsl:value-of select="$tableSchema" />
      </xsl:attribute>
      <xsl:attribute name="Table_Name">
        <xsl:value-of select="$tableName" />
      </xsl:attribute>
      <!--<xsl:attribute name="dataType">foreignTable</xsl:attribute>-->
      <xsl:attribute name="controlType">default</xsl:attribute>
      <xsl:if test="not($primaryTable/@identityKey)">
        <xsl:attribute name="disableInsert">true</xsl:attribute>
      </xsl:if>
      <!--<xsl:attribute name="path">
        <xsl:value-of select="$path" />
      </xsl:attribute>-->
      <xsl:attribute name="primaryKey">
        <xsl:value-of select="$columnName" />
      </xsl:attribute>
      <xsl:if test="@isEnforced=0">
        <xsl:attribute name="enforceConstraint">
          <xsl:value-of select="@isEnforced" />
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="text">
        <xsl:choose>
          <xsl:when test="string(@text)!=''">
            <xsl:value-of select="@text"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="displayText">
              <xsl:with-param name="tableSchema" select="$tableSchema" />
              <xsl:with-param name="tableName" select="$tableName" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:copy-of select="$primaryTable/@supportsInsert|$primaryTable/@supportsUpdate|$primaryTable/@supportsDelete"/> 
      <!-- <xsl:copy-of select="key('Tables', concat('[',$tableSchema,'].[',$tableName,']'))/PrimaryKeys"/> -->

      <!-- <xsl:attribute name="foreignKey">
		<xsl:value-of select="concat('[',$tableSchema,'].[',$tableName,'].[',$columnName,']',count(key('ForeignKeys',concat('[',$tableSchema,'].[',$tableName,'].[]'))))" />
	</xsl:attribute> -->
      <xsl:if test="(not(contains($path, concat('/', $tableSchema, '.', $tableName, '/'))) or key('ForeignKeys',concat('[',$tableSchema,'].[',$tableName,'].[]'))[@parentTableSchema=$tableSchema and @parentTableName=$tableName] and not(contains($path, concat('/', $tableSchema, '.', $tableName, '/', $tableSchema, '.', $tableName, '/')))) and key('ForeignKeys',concat('[',$tableSchema,'].[',$tableName,'].[]'))">
        <xsl:element name="ForeignKeys">
          <xsl:call-template name="ForeignKeys">
            <xsl:with-param name="path" select="concat($path, $tableSchema, '.', $tableName, '/')" />
            <xsl:with-param name="tableSchema" select="$tableSchema" />
            <xsl:with-param name="tableName" select="$tableName" />
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  <xsl:template name="ForeignKeys">
    <xsl:param name="path" select="'/'" />
    <xsl:param name="tableSchema" />
    <xsl:param name="tableName" />
    <xsl:param name="columnName" />
    <xsl:variable name="parentTableName" select="@parentTableName" />

    <xsl:for-each select="key('ForeignKeys',concat('[',$tableSchema,'].[',$tableName,'].[',$columnName,']'))">
      <xsl:choose>
        <xsl:when test="$parentTableName">
          <xsl:element name="ForeignKey">
            <xsl:attribute name="Column_Name">
              <xsl:value-of select="@columnName" />
            </xsl:attribute>
            <xsl:attribute name="parent">
              <xsl:value-of select="name(..)" />
            </xsl:attribute>
            <xsl:attribute name="scaffold">
              <xsl:apply-templates mode="scaffold" select="."></xsl:apply-templates>
            </xsl:attribute>
            <!--<xsl:attribute name="dataType">foreignKey</xsl:attribute>-->
            <xsl:call-template name="PrimaryKeys">
              <xsl:with-param name="path" select="$path" />
              <xsl:with-param name="tableSchema" select="@parentTableSchema" />
              <xsl:with-param name="tableName" select="@parentTableName" />
              <xsl:with-param name="columnName" select="@parentColumnName" />
            </xsl:call-template>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="PrimaryKeys">
            <xsl:with-param name="path" select="$path" />
            <xsl:with-param name="tableSchema" select="@parentTableSchema" />
            <xsl:with-param name="tableName" select="@parentTableName" />
            <xsl:with-param name="columnName" select="@parentColumnName" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="displayText">
    <xsl:param name="tableSchema" />
    <xsl:param name="tableName" />
    <xsl:variable name="table" select="key('Tables',concat('[',$tableSchema,'].[',$tableName,']'))"/>
    <xsl:choose>
      <xsl:when test="not($table)">'No se pudo recuperar información de la tabla'</xsl:when>
      <xsl:when test="string($table/@displayText)!=''">
        <xsl:value-of select="$table/@displayText"/>
      </xsl:when>
      <xsl:when test="count($table/Fields/*[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey')])=1">[<xsl:value-of select="$table/Fields/*[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey')]/@Column_Name"/>]</xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$table/Fields/*[not(@dataType='foreignTable' or @dataType='junctionTable' or @dataType='xml' or @dataType='foreignKey' or @Column_Name=$table/@identityKey)]">
          <xsl:sort select="@isIdentity" data-type="number" order="ascending" />
          <xsl:sort select="@isNullable" data-type="number" order="ascending" />
          <xsl:sort select="@ordinalPosition" data-type="number" order="ascending" />
          <xsl:if test="position()=1">[<xsl:value-of select="@Column_Name"/>]</xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>