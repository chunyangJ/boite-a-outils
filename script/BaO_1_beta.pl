#!/usr/bin/perl
use strict;
use warnings;
use XML::RSS;
use XML::XPath;
use open IO => ':encoding(UTF-8)';

my $MODIF="2018-05-15";
my $DOC=<<DOCUMENTATION;
    ____________________________________________________________________________

    NOM :   Boîte à Outils 1      
    MODIFICATION :
            $MODIF
    AUTEURS :  
            XU Yizhou, JIANG Chunyang
    USAGE : 
            perl Bao_1.pl REPERTOIRE-A-PARCOURIR RUBRIQUE-A-EXTRAIRE
    DESCRIPTION:
            Le programme prend en entrée le nom du répertoire contenant les 
            fichiers à traiter
            Le programme construit en sortie un fichier de texte bruit,
            et un fichier structuré contenant
            sur chaque ligne le nom du fichier et le résultat du filtrage :
            <fichier \@id \@nom><item \@numero><titre>titre</titre>
            <description>description</description></item></fichier> 
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

open(my $FHTXT,">","$rubrique-raw.txt");
open(my $FHXML,">","$rubrique-raw.xml");
print $FHXML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $FHXML "<base rubrique=\"$rubrique\" type=\"texte\">\n<entete>\n<auteur>JIANG Chunyang</auteur>\n<auteur>XU Yizhou</auteur>\n</entete>\n<fichiers>\n";
#------------------------------------------------------------------
parcourirRecursion($repertoire);
# parcourirPile($repertoire);
#------------------------------------------------------------------
print $FHXML "</fichiers>\n</base>\n";
close($FHTXT);
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
#             extraireXPath($file);
            extraireRSS($file);
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
        foreach my $item (@{$rss->{'items'}})
        {
            my $titre=$item->{'title'};
            my $description=$item->{'description'};
            #---------------------------------
            # éliminer des doublons
            #---------------------------------
            if(not exists $redondance{$titre})
            {
                $cmptItem++;
                $redondance{$titre}=1;
                nettoyer(\$titre);
                if( $description )
                {
                    nettoyer(\$description);
                }else{
		    $description="";
                }
                if( not $titre=~ m/[?!.]$/ ){ $titre.='.'; }
                print $FHTXT "$titre\n";
                print $FHTXT "$description\n\n";
                print $FHXML "<item numero=\"$cmptItem\">\n<titre>$titre</titre>\n<description>$description</description>\n</item>\n";
            }            
        }
        print $FHXML "</fichier>\n";
    }
}

sub extraireXPath
{
    my ($file)=@_;
    print $FHXML "<fichier id=\"$fileid\" nom=\"$file\">\n";
    
    my $xp=XML::XPath->new( filename => $file );
    foreach my $node ($xp->find('/rss/channel/item')->get_nodelist)
    {
        my $titre=$node->find('title')->string_value;
        my $description=$node->find('description')->string_value;
        if(not exists $redondance{$titre})
        {
            $cmptItem++;
            $redondance{$titre}=1;
            nettoyer(\$titre);
            nettoyer(\$description);
            if( not $titre=~ m/[?!.]$/ ){ $titre.='.'; }
            print $FHTXT "$titre\n";
            print $FHTXT "$description\n\n";
            print $FHXML "<item numero=\"$cmptItem\">\n<titre>$titre</titre>\n<description>$description</description>\n</item>\n";
        }            
    }
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
            nettoyer(\$description);
            if( not $titre=~ m/[?!.]$/ ){ $titre.='.'; }
            print $FHTXT "$titre\n";
            print $FHTXT "$description\n\n";
            print $FHXML "<item numero=\"$cmptItem\">\n<titre>$titre</titre>\n<description>$description</description>\n</item>\n";
        }
    }
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
    $$contenu =~ s/\x{2019}/\'/g;
}