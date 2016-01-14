<xsl:stylesheet xmlns="" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" version="1.0" extension-element-prefixes="msxsl">
  <xsl:template match="/xpath">
    <xpath>
      <xsl:apply-templates/>
    </xpath>
  </xsl:template>
  <xsl:template match="node">
    <xsl:value-of select="concat(@value,predicate)"/>
  </xsl:template>
  <xsl:template match="slash">
    <xsl:text>/</xsl:text>
  </xsl:template>

</xsl:stylesheet>