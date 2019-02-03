<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" encoding="utf-8"/>
    <!-- Bao3 extraction de 3 patrons morpho-syntaxiques sur les fichiers de sorties XQUERY -->
    <!--(head -n 4 $nomFic; tail -n +5 $nomFic | sort | uniq -ic | sort -gr) > $nomFicSort-->
    <xsl:template match="/">
        <xsl:variable name="rubrique" select="patrons/@rubrique"/>
        <xsl:variable name="motif" select="patrons/@type"/>
        <xsl:result-document href="{concat($rubrique,'_XQUERY_',$motif,'.txt')}">
            <xsl:text>
                
----------------</xsl:text><xsl:value-of select="$motif"/><xsl:text>-------------------
                
</xsl:text>
            <xsl:apply-templates select="patrons/patron" mode="NomAdj"/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="patron" mode="NomAdj">
        <xsl:value-of select="."/>
        <xsl:text>
</xsl:text>
    </xsl:template>

</xsl:stylesheet>
