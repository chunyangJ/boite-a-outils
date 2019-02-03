<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" encoding="utf-8"/>
    <!-- Bao3 extraction de 3 patrons morpho-syntaxiques sur les fichiers -->
    <!--(head -n 4 $nomFic; tail -n +5 $nomFic | sort | uniq -ic | sort -gr) > $nomFicSort-->
    <xsl:template match="/">
        <xsl:variable name="rubrique" select="base/@rubrique"/>
        <xsl:result-document href="{concat($rubrique,'_XSLT_NomAdj.txt')}">
            <xsl:text>
                
----------------Nom Adj-------------------
                
                
</xsl:text>
            <xsl:apply-templates select="base/etiquetage/fichier/element" mode="NomAdj"/>
        </xsl:result-document>
        <xsl:result-document href="{concat($rubrique,'_XSLT_NomPrpNom.txt')}">
            <xsl:text>
                
----------------Nom Prp Nom-----------------
                                
</xsl:text>
            <xsl:apply-templates select="base/etiquetage/fichier/element" mode="NomPrpNom"/>
        </xsl:result-document>

        <xsl:result-document href="{concat($rubrique,'_XSLT_NomPrpDetNom.txt')}">
            <xsl:text>
                
----------------Nom Prp Det Nom----------------
                                
</xsl:text>
            <xsl:apply-templates select="base/etiquetage/fichier/element" mode="NomPrpDetNom"/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="element" mode="NomAdj">
        <xsl:variable name="ele1" select="."/>
        <xsl:variable name="ele2" select="following-sibling::element[1]"/>
        <xsl:if test="($ele1/data[1]='NOM') and ($ele2/data[1]='ADJ')">
            <xsl:value-of select="concat($ele1/data[3],' ',$ele2/data[3])"/>
            <xsl:text>
</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="element" mode="NomPrpNom">
        <xsl:variable name="ele1" select="."/>
        <xsl:variable name="ele2" select="following-sibling::element[1]"/>
        <xsl:variable name="ele3" select="following-sibling::element[2]"/>
        <xsl:if
            test="($ele1/data[1]='NOM') and ($ele2/data[1][matches(.,'PRP')]) and ($ele3/data[1]='NOM')">
            <xsl:value-of select="concat($ele1/data[3],' ',$ele2/data[3],' ',$ele3/data[3])"/>
            <xsl:text>
</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="element" mode="NomPrpDetNom">
        <xsl:variable name="ele1" select="."/>
        <xsl:variable name="ele2" select="following-sibling::element[1]"/>
        <xsl:variable name="ele3" select="following-sibling::element[2]"/>
        <xsl:variable name="ele4" select="following-sibling::element[3]"/>
        <xsl:variable name="ele5" select="following-sibling::element[4]"/>
        <xsl:if
            test="($ele1/data[1]='NOM') and ($ele2/data[1][contains(.,'PRP')]) and ($ele3/data[1][contains(.,'DET')]) and ($ele4/data[1]='NOM')">
            <xsl:value-of
                select="concat($ele1/data[3],' ',$ele2/data[3],' ',$ele3/data[3],' ',$ele4/data[3])"/>
            <xsl:text>
</xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
