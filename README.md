Counting MARC field occurrences from the HathiTrust, via their [bibliographic API](https://www.hathitrust.org/bib_api).

Stats for the most common fields are listed in [top-marc-fields.csv](./top-marc-fields.csv).


### Process Notes

These stats were processed from 100k randomly selected MARC records. Here's the rough process used:

1. Download the most current [Hathifiles](https://www.hathitrust.org/hathifiles) archive. Hathifiles are tab-separated data with basic bibliographic information.

2. Extract OCLC numbers
    
   If you use [cskvit](csvkit.readthedocs.org), it's as easy as extracting the 8th column of the hathifiles, i.e.:
   ``` csvcut -t -c 8 hathifiles.txt.gz >oclc.txt```
   
   After extracting the OCLC numbers, I removed duplicates, threw out lines that were oddly extracted, and sorted semi-randomly (Something like this on Unix/Linux: ```cat oclc.txt | sort -n | uniq | grep -P '^\d+$' | sort -R > oclc-cleaned.txt```).

3. Download the corresponding MARC record through the [Bibliographic API](https://www.hathitrust.org/bib_api).
   
   The full records served through the Bib API can be accessed using the oclc number (`http://catalog.hathitrust.org/api/volumes/full/oclc/OCLC_ID.json`), and have MARC-XML accessible as as a string within the JSON response. [download-marc.coffee](./download-marc.coffee) is a Node script written that takes a list of OCLC numbers, downloads the records, parses the XML, counts the occurrances of fields, and prints them to stdout as '<oclc> <field number>'. You may need to install coffeescript for Node with ```npm install -g coffee-script```, then you can prepare dependencies and use the script as follows:
   ```
   npm install
   coffee download-marc.coffee --oclc <oclc #1> <oclc#2> ... 
   ```
   
   The script runs asynchronously, so you shouldn't run too many concurrent jobs (both for your compute power and politeness to HathiTrust's server),  but you can distribution the jobs with GNU Parallel, sending 10 oclc numbers at a time:
   ```
   head -n 100000 oclc.txt | parallel --eta --n 10 --jobs 3 coffee download-marc.coffee --oclc > count-fields.txt
   ```

4. Sum occurrences of each field, and determine the name of the field.
   This is done with the accompanying R script.
