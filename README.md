# metaphlan2_to_qiime
Convert MetaPhlAn2 OTU abundance table format to QIIME format. Script set up to work with bacterial-only communities as they are the main subject of our lab, but it could be modified to include all species.

## Usage
### 1. Download NCBI taxonomy

`collect_taxonomy.sh` script downloads a dump of current NCBI Taxonomy database, converts it to a `<Name>\t<TaxIDs>\t<Linage>` format and removes all non-bacterial and low-ranked items (currently everything which is above family level).

### 2. Convert MetaPhlAn2 to QIIME forma

`python3 metaphlan2_to_qiime.py [arguments]` script converts MetaPhlAn2 output to QIIME output.

Arguments:
```
-m, --metaphlan     MetaPhlAn2 output (input for the script)
-t, --taxonomy      File with NCBI taxonomy
-o, --out           Output file in QIIME format
```
