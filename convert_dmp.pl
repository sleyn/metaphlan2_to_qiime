#!/usr/bin/perl -w
use strict;

my %take = (     #look take or not the category
    "common name" => 1,
    "genbank anamorph" => 1,
    "acronym" => 1,
    "scientific name" => 1,
    "authority" => 0,
    "anamorph" => 1,
    "equivalent name" => 1,
    "includes" => 1,
    "blast name" => 0,
    "genbank acronym" => 1,
    "in-part" => 1,
    "teleomorph" => 1,
    "misspelling" => 1,
    "synonym" => 1,
    "genbank synonym" => 1,
    "type material" => 0,
    "genbank common name" => 1,
    "misnomer" => 1,
);

my %abbr = (
    "kingdom" => "kk",
    "species" => "s",
    "subfamily" => "sf",
    "cohort" => "ch",
    "infraorder" => "io",
    "infraclass" =>  "oc",
    "order" => "o",
    "subclass" => "sc",
    "superorder" => "suo",
    "superphylum" => "sup",
    "class" => "c",
    "subphylum" => "sp",
    "superfamily" => "suf",
    "superkingdom" => "k",
    "subkingdom" => "sk",
    "suborder" => "so",
    "tribe" => "t",
    "no rank" => "r",
    "subgenus" => "sg",
    "species group" => "sgr",
    "phylum" => "p",
    "varietas" => "v",
    "superclass" => "suc",
    "genus" => "g",
    "parvorder" => "pv",
    "species subgroup" => "ssu",
    "subspecies" => "ss",
    "forma" => "fo",
    "subtribe" => "st",
    "family" => "f",
    "subcohort" => "sch",
    "section" => "sn",
    "subsection" => "ssn",
    "series" => "sr",
);

my %s_names;
my %nodes;
my %scientific;
my %tax_string;
my %rank;

open MERGED, "merged.dmp";
print "Collect merged TaxIDs\n";

my %merged;		#collect merged taxids

while(<MERGED>){
	chomp;
	$_ =~ m/(\d+)\t\|\t(\d+)\t/;
	$merged{$2} .= ",$1";
}

close MERGED;

open NODES, "nodes.dmp";
print "Collect TaxIDs relations\n";

while(<NODES>){
    my @node = split /\t\|\t/, $_;
    $nodes{$node[0]} = $node[1];            #child => parent
    $rank{$node[0]} = $node[2];             #child => rank
}

close NODES;

open NAMES, "names.dmp";
print "Collect scientific names for TaxIDs\n";

while(<NAMES>){
    chomp;
    $_ =~ s/\t\|$//;            #remove last tab and vertical line
    my @tax_str = split /\t\|\t/, $_;
    if( $take{$tax_str[3]} == 0 ){          #look if we skip this category
        next;
    }
    
    # setup what levels of taxonomy do you want to keep
    my %keep_rank = (
    	"family" => 1,
    	"genus" => 1,
    	"species" => 1,
    	"no rank" => 1,
    	"subspecies" => 1,
    	"varietas" => 1
    );
    
    if( $rank{$tax_str[0]} eq "family" | $rank{$tax_str[0]} eq "genus" | $rank{$tax_str[0]} eq "species" | $rank{$tax_str[0]} eq "no rank" | $rank{$tax_str[0]} eq "subspecies" | $rank{$tax_str[0]} eq "varietas" ){
        if( exists $s_names{$tax_str[0]}){
            $s_names{$tax_str[0]} .= ";$tax_str[1]";      #collect all species names  taxid => names
        }else{
            $s_names{$tax_str[0]} = $tax_str[1];
        }
        
    }
    
    if( $tax_str[3] eq "scientific name" ){
        $scientific{$tax_str[0]} = $tax_str[1];             #collect scientific names for taxids
    }
}

close NAMES;

open TAXONOMY, ">./Taxonomy/taxonomy.txt";
print "Make a taxonomy output in ../Taxonomy/taxonomy.txt file";
foreach my $taxid ( keys %s_names ){
    my $cur_taxid = $taxid;
    my $tax_string = "";
    
    while( $cur_taxid != 1 ){
    	if( not exists $abbr{$rank{$cur_taxid}}){
    		print "$rank{$cur_taxid}\n";
    	}
        $tax_string = ";$scientific{$cur_taxid}__$abbr{$rank{$cur_taxid}}" . $tax_string;
        $cur_taxid = $nodes{$cur_taxid};
    }
    
    my @names = split /;/, $s_names{$taxid};
    
    foreach my $name ( @names ){
    	$name =~ s/[ -]/_/g;
    	$name =~ s/\.//g;
    	if( exists $merged{$taxid} ){
    		print TAXONOMY "$name\t$taxid$merged{$taxid}\t$tax_string\n";
    	}else{
	        print TAXONOMY "$name\t$taxid\t$tax_string\n";
	    }
    }
}