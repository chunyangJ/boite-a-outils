#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use XML::RSS;
use XML::XPath;
use open IO => ':encoding(UTF-8)';  #perl -CD/-C24/-Cio
binmode(STDIN, ':encoding(UTF-8)');
binmode(STDOUT, ':encoding(UTF-8)'); #perl -C3
binmode(STDERR, ':encoding(UTF-8)'); #perl -C7 (assurer bon encodage d'impression de DOCUMENTATION)

my $MODIF="2018-05-15";
my $DOC=<<DOCUMENTATION;
    ____________________________________________________________________________

    NOM :   Boîte à Outils 2      
    MODIFICATION :
            $MODIF
    AUTEURS :  
            XU Yizhou, JIANG Chunyang
    USAGE : 
            perl Bao_2.pl REPERTOIRE-A-PARCOURIR RUBRIQUE-A-EXTRAIRE
    DESCRIPTION:
            Le programme prend en entrée le nom du répertoire contenant les 
            fichiers à traiter
            Le programme construit en sortie un fichier structuré contenant
            sur chaque ligne les contenus textuels étiquetés            
    ____________________________________________________________________________

DOCUMENTATION

if (@ARGV!=2) {
    die $DOC;
}

my $repertoire=$ARGV[0];
my $rubrique=$ARGV[1];
my %redondance;
my $cmptItem=0;
my $fileid=0;

#-----------------------------------
#normaliser le nom du répertoire
#-----------------------------------
$repertoire=~ s/[\/]$//;


open(my $FHXML,">","$rubrique-tagged.xml");
print $FHXML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $FHXML "<base rubrique=\"$rubrique\" type=\"POStagged\">\n<entete>\n<auteur>XU Yizhou</auteur>\n<auteur>JIANG Chunyang</auteur>\n</entete>\n<etiquetage>\n";
#------------------------------------------------------------------
parcourirRecursion($repertoire);
# parcourirPile($repertoire);
#------------------------------------------------------------------
print $FHXML "</etiquetage>\n</base>\n";
close($FHXML);
exit 0;
#------------------------------------------------------------------


#------------------------------------------------------------------
#en profondeur
sub parcourirRecursion
{
    my ($path)=@_;
    opendir(my $dir, $path) or die "ERR : Echec d'ouverture de $path: $!\n";
    my @files=readdir($dir);
    closedir($dir);
    
    foreach my $file (@files)
    {
        next if $file =~ /^\.\.?$/;
	$file=$path."/".$file;
	if ( -d $file ) { parcourirRecursion($file); }
        if ( -f $file and $file=~ m/-$rubrique.+\.xml$/ )
        {
            $fileid++;
# trois moyens d'extraction
            extraireXPath($file);
#             extraireRSS($file);
#             extraireRegex($file);
        }
    }
}

#------------------------------------------------------------------
sub parcourirPile
{
    my ($path)=@_;
    my @dirs=($path.'/');
    
    while(my $dir=pop(@dirs))
    {
        my $DH;
        unless(opendir($DH, $dir))
        {
            warn "ERR : échec d'ouverture de $dir: $!\n";
            next;
        }
        foreach my $file (readdir($DH))
        {
            next if $file =~ /^\.\.?$/;
            $file=$dir."/".$file;
            if ( -d $file ) { push(@dirs, $file); }
            if ( -f $file and $file=~ m/-$rubrique.+\.xml$/ )
            {
                $fileid++;
# trois moyens d'extraction
#             extraireXPath($file);
                extraireRSS($file);
#             extraireRegex($file);
            }
        }
        closedir($DH);
    }
}

sub extraireRSS
{
    my ($file)=@_;
    my $rss=new XML::RSS( encoding => 'utf-8' );
    eval { $rss->parsefile($file); };
    if ($@) {
        warn "ERR: échec d'analyse du fichier $file : $@\n";
    }
    else
    {
        print $FHXML "<fichier id=\"$fileid\" nom=\"$file\">\n";
        my $contenu="";
        foreach my $item (@{$rss->{'items'}})
        {
            my $titre=$item->{'title'};
            my $description=$item->{'description'};
            #---------------------------------
            #éliminer des doublons
            #---------------------------------
            if(not exists $redondance{$titre})
            {
                $cmptItem++;
                $redondance{$titre}=1;
                nettoyer(\$titre);
                if( not $titre=~ m/[?!.]$/ ) { $titre.='.'; }
                $contenu.=$titre." ";
                if( $description )
                {
                    nettoyer(\$description);
                    $contenu.=$description." ";
                } 
            }            
        }
        etiqueter(\$contenu);
        print $FHXML "$contenu";
        print $FHXML "</fichier>\n";
    }
}

sub extraireXPath
{
    my ($file)=@_;
    print $FHXML "<fichier id=\"$fileid\" nom=\"$file\">\n";
    
    my $xp=XML::XPath->new( filename => $file );
    my $contenu="";
    foreach my $node ($xp->find('/rss/channel/item')->get_nodelist)
    {
        my $titre=$node->find('title')->string_value;
        my $description=$node->find('description')->string_value;
            if(not exists $redondance{$titre})
            {
                $cmptItem++;
                $redondance{$titre}=1;
                nettoyer(\$titre);
                if( not $titre=~ m/[?!.]$/ ) { $titre.='.'; }
                $contenu.=$titre." ";
                if( $description )
                {
                    nettoyer(\$description);
                    $contenu.=$description." ";
                }
            }
    }
    etiqueter(\$contenu);
    print $FHXML "$contenu";
    print $FHXML "</fichier>\n";
}

sub extraireRegex 
{
    my ($file)=@_;
    print $FHXML "<fichier id=\"$fileid\" nom=\"$file\">\n";
    
    open (my $FH, "<", $file);
    my $texte="";
    while (my $ligne=<$FH>)
    {
        chomp $ligne;
        $ligne=~ s/\r//g;
        $texte.=$ligne;
    }
    close($FH);
    my $contenu="";
    $texte=~ s/>\s+</></g;
    while ($texte=~ m/<item>.+?<title>([^<]*)<\/title>[^<]*<description>([^<]*)<\/description>.+?<\/item>/g)
    {
        my $titre=$1;
        my $description=$2;
        if(not exists $redondance{$titre})
        {
            $cmptItem++;
            $redondance{$titre}=1;
            nettoyer(\$titre);
            if( not $titre=~ m/[?!.]$/ ) { $titre.='.'; }
            $contenu.=$titre." ";
            if( $description )
            {
                nettoyer(\$description);
                $contenu.=$description." ";
            }
        }
    }
    etiqueter(\$contenu);
    print $FHXML "$contenu";
    print $FHXML "</fichier>\n";
}

sub nettoyer
{
    my $contenu=$_[0];
    $$contenu =~ s/<[^>]+>//g;
    $$contenu =~ s/&lt;.+&gt;//g;
    $$contenu =~ s/&(#38;)?#39;/'/g;
    $$contenu =~ s/&(#38;)?#34;/"/g;
    $$contenu =~ s/&(amp;)?/et/g;
#     $$contenu =~ s/\x{2019}/\'/g;
}

sub etiqueter
{
    my $contenu=$_[0];
    $$contenu=`echo "$$contenu" | sed "s/\’/\'/g" | tree-tagger-french `;
    traitement($contenu);
}

#--------------------------------------------------------------
#   treetagger2xml
#   entree: référence à la chaîne de caractères contenant 
#           le texte étiqueté et lemmatisé par tree-tagger
#   sortie: le même texte au format xml
#--------------------------------------------------------------
sub traitement 
{
    my $texte="";
    my $contenu=$_[0];
    my @Lignes=split('\n',$$contenu);
    while (my $Ligne=shift(@Lignes)) 
    {
	if ($Ligne!~/\ô\¯\:\\ô\¯\:\\/) 
	{
	    $Ligne=~s/\"/<![CDATA[\"]]>/g;
	    $Ligne=~s/([^\t]*)\t([^\t]*)\t(.*)/<element><data type=\"type\">$2<\/data><data type=\"lemma\">$3<\/data><data type=\"string\">$1<\/data><\/element>/;
	    $Ligne=~s/<unknown>/unknown/g;
            $texte.=$Ligne."\n";
	}
    }
    $$contenu=$texte;
}
