(:BAO3_XQUERY_NomPrpDetNom.xq Sur les fichiers étiquetés avec treetagger (par rubrique a priori), Construire une requête pour extraire les patrons morpho-syntaxiques NOM PRP DET NOM:)
(:les patrons sont écrits respectivement dans des fichiers nommés par rubrique:)
   let $base := collection("TREE-TAGGER")/base
   for $rubrique in distinct-values($base/@rubrique)
   let $fName := concat("./Patrons/", $rubrique, "_XQUERY_NomPrpDetNom.xml")
   let $params := <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
   <output:method value='xml'/>
  <output:omit-xml-declaration value="no"/>
</output:serialization-parameters>
   return 
     file:write($fName,
       <patrons rubrique="{$rubrique}" type="NOM_PRP_DET_NOM">
       {
         for $ele1 in $base[@rubrique=$rubrique]/etiquetage/fichier/element
         let $ele2 := $ele1/following-sibling::element[1]
         let $ele3 := $ele1/following-sibling::element[2]
         let $ele4 := $ele1/following-sibling::element[3]
         where $ele1/data[1]="NOM" and $ele2/data[1][contains(.,"PRP")] and $ele3/data[1][contains(.,"DET")] and $ele4/data[1]="NOM"
         return <patron>{$ele1/data[3]/text()," ", $ele2/data[3]/text()," ", $ele3/data[3]/text()," ", $ele4/data[3]/text()}</patron>
       }
       </patrons>, $params)
   
    
