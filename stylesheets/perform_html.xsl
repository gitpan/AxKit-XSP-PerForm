<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:template match="formerrors">
    <xsl:apply-templates select="..//error"/>
</xsl:template>

<xsl:template match="error">
  <span class="form_error"><xsl:value-of select="."/></span>
</xsl:template>

<xsl:template match="textfield">
    <input 
        type="text"
        name="{@name|name}" 
        value="{@value|value}" 
        size="{@width|width}" 
        maxlength="{@maxlength|maxlength}" />
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="password">
    <input 
        type="password"
        name="{@name|name}" 
        value="{@value|value}" 
        size="{@width|width}" 
        maxlength="{@maxlength|maxlength}" />
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="checkbox">
    <input
        type="checkbox"
        name="{@name|name}"
        value="{@value|value}" />
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="submit_button">
    <input
        type="submit"
        name="{@name|name}"
        value="{@value|value}" />
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="hidden">
    <input
        type="hidden"
        name="{@name|name}"
        value="{@value|value}" />
</xsl:template>

<xsl:template match="options/option">
  <option value="{@value|value}">
    <xsl:if test="selected[. = 'selected'] | @selected[. = 'selected']">
      <xsl:attribute name="selected">selected</xsl:attribute>
    </xsl:if>
    <xsl:value-of select="@text|text"/>
  </option>
</xsl:template>

<xsl:template match="single_select">
    <select name="{@name|name}">
        <xsl:apply-templates select="options/option"/>
    </select>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="textarea">
    <textarea name="{@name|name}" cols="{@cols|cols}" rows="{@rows|rows}">
    <xsl:if test="@wrap|wrap"><xsl:attribute name="wrap">physical</xsl:attribute></xsl:if>
    <xsl:value-of select="@value|value"/>
    </textarea> <br />
    <xsl:apply-templates select="error"/>
</xsl:template>

</xsl:stylesheet>
