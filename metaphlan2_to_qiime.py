import argparse
import pandas as pd
import re

parser = argparse.ArgumentParser(description="Script converts Mataphlan2 multisample files to QIIME format")
parser.add_argument('-m', '--metaphlan', nargs='+', help="Metaphlan output (input for the script)")
parser.add_argument('-t', '--taxonomy', nargs='+', help="File with NCBI taxonomy")
parser.add_argument('-o', '--out', nargs='+', help="Output file in QIIME format")
args = parser.parse_args()

class qiime:
    def __init__(self, metaphlan_file, tax_file):
        self.metaphlan = pd.read_csv(metaphlan_file, sep='\t')
        self.ncbi = self._read_ncbi(tax_file)    # dictonary for NCBI taxonomy

    # auxillary function that decides to keep OTU or not based on taxonomy
    @staticmethod
    def _keep(tax_string):
        keep = 0                                            # Keep (1) or not (0)
        if 'k__Bacteria' in tax_string:                 # Remove kingdoms other than Bacteria
            if 't__' not in tax_string:
                if 's__' in tax_string:  # Keep lines if they have species name and do not have strain
                    keep = 1
                if re.search('unclassified$', tax_string):          # Keep string with unclassified in the end
                    keep = 1
        return keep

    # remove unclassified and noname parts
    @staticmethod
    def _clean_tax(tax_string):
        tax_string = re.sub(r'\|[^\|]+_unclassified$', '', tax_string)
        tax_string = re.sub(r'\|[^\|]+_noname$', '', tax_string)
        tax_string = re.sub(r'^.+\|\w+__', '', tax_string)    # remove all but last rank
        return tax_string

    # keep only significant OTU in metaphlan table
    def keep_significant(self):
        print('Remove non-relevant OTU')
        self.metaphlan['Keep'] = self.metaphlan['#SampleID'].apply(self._keep)     # Apply _keep function to every value
        self.metaphlan = self.metaphlan.loc[self.metaphlan['Keep'] != 0]
        self.metaphlan = self.metaphlan.drop('Keep', axis=1)
        self.metaphlan['#SampleID'] = self.metaphlan['#SampleID'].apply(self._clean_tax)  # Apply _clean_tax function to every value

    # convert ncbi taxonomy to qiime format k__Bacteria; p__Firmicutes; c__Clostridia; o__Clostridiales; f__Ruminococcaceae; g__Faecalibacterium; s__prausnitzii
    @staticmethod
    def _tax_convert(ncbi_tax):
        ranks = ['k', 'p', 'c', 'o', 'f', 'g', 's']
        taxes = [re.search(';([^;]+)__' + rank + '(;|$)', ncbi_tax) for rank in ranks]
        taxes = ['' if tax is None else tax.group(1) for tax in taxes]
        taxes = [tax[0] + '__' + tax[1] for tax in zip(ranks, taxes)]       # make a new tax string
        return ';'.join(taxes)

    # read taxonomy file
    def _read_ncbi(self, tax_file_path):
        print('Read NCBI Taxonomy dump: ' + tax_file_path)
        with open(tax_file_path, 'r') as tax_file:
            ncbi_taxonomy = dict()
            for line in tax_file.readlines():
                line = line.rstrip()
                line = line.split('\t')
                line[1] = re.sub(',.+', '', line[1])    # remove additional taxids
                line[2] = self._tax_convert(line[2])
                ncbi_taxonomy[line[0]] = line[1:]   # read 'Name' => 'taxid', 'linage'
            return ncbi_taxonomy

    # process NCBI OTU
    @staticmethod
    def _process_out(otu):
        otu = re.sub('__[^;]+ bacterium [^;]+', '__', otu)
        otu = re.sub('__[^;]+ sp\. [^;]+', '__', otu)
        otu = re.sub('s__[A-Z][a-z]+ ', 's__', otu)         # remove genus part from the species name
        return otu

    # reformat to qiime format
    def reformat_table(self):
        print('Reformatting OTU table')
        self.metaphlan.insert(0, '#OTU ID', '')    # insert new OTU ID column
        self.metaphlan['#OTU ID'] = self.metaphlan['#SampleID'].apply(lambda tax: self.ncbi[tax][0] if tax in self.ncbi else 'Missing ' + tax)
        self.metaphlan['taxonomy'] = self.metaphlan['#SampleID'].apply(lambda tax: self.ncbi[tax][1] if tax in self.ncbi else 'Missing ' + tax)
        self.metaphlan['taxonomy'] = self.metaphlan['taxonomy'].apply(self._process_out)
        self.metaphlan = self.metaphlan.drop('#SampleID', axis=1)


qiime = qiime(' '.join(args.metaphlan), ' '.join(args.taxonomy))
qiime.keep_significant()
qiime.reformat_table()
qiime.metaphlan.to_csv(' '.join(args.out), sep='\t', index=False, quoting=3)