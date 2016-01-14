<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:sitemap="http://www.panaxit.com/sitemap"
		xmlns:set="http://exslt.org/sets"
		extension-element-prefixes="msxsl"
		exclude-result-prefixes="set">
	<xsl:output method="xml"/>
	<xsl:variable name="sp" select="' '"/>

	<xsl:template match="/">
		<xsl:apply-templates select="usersitemap/siteMap|usersitemap/sitemap:root"/>
	</xsl:template>
  
	<xsl:template match="parameters|parameter|siteMap|script|filters|sitemap:parameters|sitemap:parameter|sitemap:siteMap|sitemap:script|sitemap:filters">
		<xsl:call-template name="duplicateNode"/>
	</xsl:template>
	<xsl:template match="*">
		<xsl:variable name="catalogName" select="@catalogName"/>
		<xsl:variable name="catalogPrivileges" select="/usersitemap/Privileges/Catalog[@D=1][string(@catalogName)=string($catalogName) or string(@catalogName)=concat('dbo.',$catalogName)]"/>
		<xsl:choose>
			<xsl:when test="not($catalogName)">
				<xsl:if test="descendant-or-self::*[@url or @catalogName and string(@catalogName)=/usersitemap/Privileges/Catalog[@D=1]/@catalogName or concat('dbo.',@catalogName)=/usersitemap/Privileges/Catalog[@D=1]/@catalogName]">
					<xsl:call-template name="duplicateNode"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$catalogPrivileges">
				<xsl:choose>
					<xsl:when test="@mode='insert' and $catalogPrivileges/@A=1 or @mode='edit' and $catalogPrivileges/@C=1 or string(@mode)!='insert' and string(@mode)!='edit' and $catalogPrivileges/@D=1">
						<xsl:call-template name="duplicateNode"/>
					</xsl:when>
					<xsl:otherwise>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="text()" />

	<xsl:template match="*//text()">
		<xsl:copy-of select="." />
	</xsl:template>

	<xsl:template name="duplicateNode">
		<xsl:variable name="catalogName" select="@catalogName"/>
		<xsl:copy>
			<xsl:if test="local-name(.)='siteMap' or local-name(.)='root' ">
				<xsl:attribute name="xml:lang">es</xsl:attribute>
			</xsl:if>
			<xsl:if test="local-name(.)='siteMapNode' and @catalogName or local-name(.)='catalog'">
				<xsl:attribute name="controlType">
					<xsl:choose>
						<xsl:when test="@pageSize=1 or @mode='insert' or @mode='edit' or @mode='filters' ">formView</xsl:when>
						<xsl:otherwise>gridView</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:attribute name="mode">
					<xsl:choose>
						<xsl:when test="@pageSize=1 or @controlType='formView'">insert</xsl:when>
						<xsl:otherwise>readonly</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:copy-of select="@*"/>
			<xsl:if test="@catalogName and not(/usersitemap/Privileges/Catalog[string(@catalogName)=string($catalogName)]) and /usersitemap/Privileges/Catalog[string(@catalogName)=concat('dbo.',$catalogName)]">
				<xsl:attribute name="catalogName">
					<xsl:value-of select="concat('dbo.',$catalogName)"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>