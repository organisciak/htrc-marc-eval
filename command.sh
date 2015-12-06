grep -RPo "datafield tag=\"\d*?\" " files/* | perl -pe "s/:data.*tag=\"/\t/g" | perl -pe "s:(files/|\.xml|\")::g" >count-fields.tsv 
