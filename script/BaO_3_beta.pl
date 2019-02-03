#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;
# use Data::Dumper;
use open IO => ':encoding(UTF-8)';#tree-tagger
use vars '$opt_t';

my $MODIF="2018-05-16";
my $DOC=<<DOCUMENTATION;
    ____________________________________________________________________________

    NOM :   Boîte à Outils 3      
    MODIFICATION :
            $MODIF
    USAGE : 
            perl Bao_3.pl [OPTION] FICHIER-A-EXTRAIRE FICHIER-DE-MOTIF
    DESCRIPTION:
            Le programme prend en entrée le nom du fichier à traiter et le nom
            du fichier de motifs.
            Le programme construit en sortie pour chaque motif un fichier txt de 
            patrons morphosyntaxiques.

            -t
                exige un fichier de motifs correspondant aux jeux 
                d'etiquettes de tree-tagger français, et un fichier XML de
                textes étiquetés par tree-tagger.

            par défault, le script demande d'un fichier de motifs correspondant
            au Cordial, et d'un fichier de texte étiquetés par Cordial.
    ____________________________________________________________________________

DOCUMENTATION

getopts('t');

if (@ARGV!=2) {
    die $DOC;
}

#------------------------------------------------------------------------------
# Ouverture des fichiers en lecture
# si option -t est en active, le fichier d'entree sera traite comme sortie de CORDIAL(txt-iso-8859-15)
# sinon, le fichier d'entree sera traite comme sortie de TreeTagger(XML-utf8)
#------------------------------------------------------------------------------
my $FHTAG;
if(defined($opt_t))
{
    open ($FHTAG,"<", $ARGV[0]) or die ("probleme sur ouverture de la sortie de BaO2...");
}
else
{
    open ($FHTAG,"<:encoding(iso-8859-15)", $ARGV[0]) or die ("probleme sur ouverture de la sortie de BaO2...");
}
open (my $FHPOS,"<", $ARGV[1]) or die ("probleme sur ouverture du fichier des patrons...");
#---------------------------------------------------------------------------
# 1. on localise (desinitialise) le variable global $/ pour permettre a l'operateur
#    <..> de lire l'ensemble de texte dans une chaine de caracs
#    typique usage de local; my est illegal pour les variables de ponctuation
#    (comme $_ $/ $")
# 2. on segmente la chaine (par '\n') en liste de patrons
# astuce : la boucle (comme while(my $var = <FH>)) est couteux pour 
#          la meme tache; split est plus efficace
#---------------------------------------------------------------------------
my $mesPatrons = do { local $/; <$FHPOS> };
# $mesPatrons=~ s/\r//g;
my @listePatrons = split('\n', $mesPatrons);
close($FHPOS);
#---------------------------
# Initialisation des listes
#--------------------------
my @maLigneSegmentee = ();
my @listeTokens = ();
my @listePOS = ();
#------------------------------------------------------------------------------
# Lecture du fichier de tags ligne par ligne
# extraction des tokens et des pos, puis les stocker dans les listes
#------------------------------------------------------------------------------
while (my $ligne = <$FHTAG>) {
    chomp($ligne);
    if(defined($opt_t))
    {
        if ($ligne =~ m/<element><data type=\"type\">([^<]+)<\/data><data type=\"lemma\">[^<]+<\/data><data type=\"string\">([^<]+)<\/data><\/element>/) 
        {
            push(@listeTokens, $2);
            push(@listePOS, $1);
        }
    }
    else
    {
        @maLigneSegmentee = split("\t", $ligne);
        if (scalar(@maLigneSegmentee)==3)
        {
            push(@listeTokens, $maLigneSegmentee[0]);
            push(@listePOS, $maLigneSegmentee[2]);
        }
    }
}
close($FHTAG);
#---------------------------------------------------
# on va maintenant parcourir les POS et les TOKENS
#----------------------------------------------------------------------------------------
# 1. on cree une liste tmp des POS que l'on va parcourir en supprimant le premier element 
#    a chaque fois
# 2. on cree un dictionnaire de termes (table de hashage) pour stocker les termes trouves  
#----------------------------------------------------------------------------------------
my @tmpListePOS=@listePOS;
my $indice=0;
my %terminologie;
while (my $pos = shift(@tmpListePOS)) {
    foreach my $patron (@listePatrons) {
	#-----------------------------------
	# on segmente le patron pour connaitre
	# son premier element
	my @listeTerme = split('#',$patron);
	#-----------------------------------
	# on teste si l'element courant POS correspond au premier element du patron...
	if ($pos=~/$listeTerme[0]/) {
	    # si c'est OK...
	    # on regarde maintenant s'il y a correspondance pour la suite...
	    my $verif=0;
	    for (my $i=0;$i<=$#listeTerme-1;$i++) {
		if ($tmpListePOS[$i]=~/$listeTerme[$i+1]/) { 
		    #Le suivant est bon aussi...
		    $verif++ ;
		}
	    }
	    #------------------------------------------------------------------------
	    # si verif est egal au nb d'element du patron c'est qu'on a trouve un terme
	    # on enchaine les tokens en terme; puis ajoute le terme au dict de termes 
	    #------------------------------------------------------------------------
	    if ($verif == $#listeTerme) { 
		my $termTrouve="";
		for (my $i=0;$i<=$#listeTerme;$i++) {
		    $termTrouve.=$listeTokens[$indice+$i]." ";
		}
 		$termTrouve=~ s/ $/\n/g;
                push(@{$terminologie{$patron}},$termTrouve);
	    }
	}
    }
    $indice++;
    # on avance dans la liste des POS et des TOKEN
}
#-----------------------------------
# Impression de résultats
#-----------------------------------
# alt: print Dumper(\%terminologie);

while ((my $patron, my $terms) = each %terminologie){
    $patron =~ s/#/_/g;
    open(my $FH, ">", "$patron.txt");
    print $FH "\n\n------ $patron ------\n\n";
    foreach my $term (@$terms) { print $FH $term; }
    close($FH);
}

