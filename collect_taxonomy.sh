# download new taxonomy database
echo 'Download NCBI Taxonomy Dump'
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
echo 'Extract NCBI Taxonomy dump'
tar -xzvf taxdump.tar.gz
# remove additional files
rm citations.dmp
rm delnodes.dmp
rm division.dmp
rm gencode.dmp
rm gc.prt
rm readme.txt
rm taxdump.tar.gz

echo 'Convert dump'
mkdir -p ./Taxonomy
perl convert_dmp.pl
rm merged.dmp
rm names.dmp
rm nodes.dmp

echo 'Remove non-bacterial entries'
cd ./Taxonomy
grep 'Bacteria__k' taxonomy.txt > taxonomy_bact.txt
rm taxonomy.txt 
mv taxonomy_bact.txt taxonomy.txt
