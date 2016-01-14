<xsl:stylesheet xmlns="" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" version="1.0" extension-element-prefixes="msxsl">
  <xsl:key name="table" match="xpath/*[@type='table']" use="generate-id()"/>
  <xsl:key name="record" match="xpath/*[@type='record']" use="generate-id()"/>
  <xsl:key name="field" match="xpath/*[@type='field']" use="generate-id()"/>
  <xsl:template match="/xpath">
    <xpath>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="." mode="autocomplete"/>
    </xpath>
  </xsl:template>
  <xsl:template match="*">
    <xsl:copy>
      <xsl:attribute name="type">pathToAttribute</xsl:attribute>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[following-sibling::node[@type][1][@type='field'] and not(preceding-sibling::node[@type][1][@type='field'])]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">record</xsl:attribute>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[following-sibling::node[@type][1][@type='record' or @type='field'] and not(preceding-sibling::node[@type][1][@type='record' or @type='field'])]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">record</xsl:attribute>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[following-sibling::node[@type][1][@type='table' or @type='record' or @type='field'] and not(preceding-sibling::node[@type][1][@type='table' or @type='record' or @type='field'])]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">pathToTable</xsl:attribute>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@type='table']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">table</xsl:attribute>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
    <xsl:if test="/*[@context='record' or @context='field'] and not(//*[@type='record' or @type='field'])">
      <xsl:element name="slash">
        <xsl:attribute name="type">record</xsl:attribute>
      </xsl:element>
      <xsl:element name="node">
        <xsl:attribute name="type">record</xsl:attribute>
        <xsl:attribute name="value">${record}</xsl:attribute>
      </xsl:element>
    </xsl:if>
    <xsl:if test="/*[@context='field'] and not(//*[@type='record' or @type='field'])">
      <xsl:element name="slash">
        <xsl:attribute name="type">field</xsl:attribute>
      </xsl:element>
      <xsl:element name="node">
        <xsl:attribute name="type">field</xsl:attribute>
        <xsl:attribute name="value">${field}</xsl:attribute>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  <xsl:template match="node[@type='attribute']|xpath/node[last()]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">attribute</xsl:attribute>
      <xsl:attribute name="value">
        <xsl:choose>
          <xsl:when test="starts-with(@value,'@')"><xsl:value-of select="@value"/></xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('@',@value)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node[@type='record']">
    <xsl:if test="not(../*[@type='table'])">
      <xsl:element name="node">
        <xsl:attribute name="type">table</xsl:attribute>
        <xsl:attribute name="value">${table}</xsl:attribute>
      </xsl:element>
      <xsl:element name="slash">
        <xsl:attribute name="type">record</xsl:attribute>
      </xsl:element>
    </xsl:if>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
    <xsl:if test="/*[@context='field'] and not(//*[@type='field'])">
      <xsl:element name="slash">
        <xsl:attribute name="type">field</xsl:attribute>
      </xsl:element>
      <xsl:element name="node">
        <xsl:attribute name="type">field</xsl:attribute>
        <xsl:attribute name="value">${field}</xsl:attribute>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  <xsl:template match="node[@type='field']">
    <xsl:if test="not(../*[@type='table']) and not(../*[@type='record'])">
      <xsl:element name="node">
        <xsl:attribute name="type">table</xsl:attribute>
        <xsl:attribute name="value">${table}</xsl:attribute>
      </xsl:element>
      <xsl:element name="slash">
        <xsl:attribute name="type">record</xsl:attribute>
      </xsl:element>
    </xsl:if>
    <xsl:if test="not(../*[@type='record'])">
      <xsl:element name="node">
        <xsl:attribute name="type">record</xsl:attribute>
        <xsl:attribute name="value">${record}</xsl:attribute>
      </xsl:element>
      <xsl:element name="slash">
        <xsl:attribute name="type">field</xsl:attribute>
      </xsl:element>
    </xsl:if>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="text()"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*" mode="autocomplete">
    <xsl:if test="*[1][@type='table' or @type='record' or @type='field'] or not(*[@type='table' or @type='record' or @type='field'])">
      <xsl:element name="slash">
        <xsl:attribute name="type">pathToTable</xsl:attribute>
      </xsl:element>
        <xsl:element name="slash">
        <xsl:attribute name="type">pathToTable</xsl:attribute>
      </xsl:element>
    </xsl:if>
    <xsl:if test="not(*[@type='table' or @type='record' or @type='field'])">
      <xsl:if test="/*[@context='table' or @context='record' or @context='field'] and not(*[@type='table' or @type='record' or @type='field'])">
        <xsl:element name="node">
          <xsl:attribute name="type">table</xsl:attribute>
          <xsl:attribute name="value">${table}</xsl:attribute>
        </xsl:element>
      </xsl:if>
      <xsl:if test="/*[@context='record' or @context='field'] and not(//*[@type='record' or @type='field'])">
        <xsl:element name="slash">
          <xsl:attribute name="type">record</xsl:attribute>
        </xsl:element>
        <xsl:element name="node">
          <xsl:attribute name="type">record</xsl:attribute>
          <xsl:attribute name="value">${record}</xsl:attribute>
        </xsl:element>
      </xsl:if>
      <xsl:if test="/*[@context='field'] and not(//*[@type='field'])">
        <xsl:element name="slash">
          <xsl:attribute name="type">field</xsl:attribute>
        </xsl:element>
        <xsl:element name="node">
          <xsl:attribute name="type">field</xsl:attribute>
          <xsl:attribute name="value">${field}</xsl:attribute>
        </xsl:element>
      </xsl:if>
      <xsl:if test="not(*[@type='table' or @type='record' or @type='field']) and not(name(*[1])='slash')">
        <xsl:element name="slash">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="*[@type='table']">pathToTable</xsl:when>
              <xsl:when test="*[@type='record']">record</xsl:when>
              <xsl:when test="*[@type='field']">field</xsl:when>
              <xsl:otherwise>pathToAttribute</xsl:otherwise>
            </xsl:choose></xsl:attribute>
        </xsl:element>
      </xsl:if>
    </xsl:if>
    <xsl:apply-templates select="*"/>
  </xsl:template>

</xsl:stylesheet>