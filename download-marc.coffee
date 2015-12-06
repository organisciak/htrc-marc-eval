request = require 'request'
async = require 'async'
xml2js = require 'xml2js'
parser = xml2js.Parser()
_ = require 'lodash'
argv = require('yargs').array('oclc').argv

# Sample usage
#    coffee download-marc.coffee --oclc 424023 500011
  
# OCLC values can be extracted from hathifiles, using csvkit
# command: csvcut -t -c 8 hathifiles.txt.gz
# [Hathifiles]: https://www.hathitrust.org/hathifiles

main = () ->
  
  async.eachLimit(argv.oclc, 10, (url, callback) ->
    parseMarc(url, (err, result) ->
      for field in result.fields
        console.log "#{result.oclc} #{field}"
    )
  )

parseMarc = (oclc, callback) ->
  # Get Marc record from url return a JSON of available fields
  #
  url = "http://catalog.hathitrust.org/api/volumes/full/oclc/#{oclc}.json"

  options = { url: url, json: true}

  async.waterfall([
    # Load JSON from URL
    (callback) ->
      request(options, (err, res, body) ->
        if (err) then callback(err)
        record = body.items[0].fromRecord
        marc = body.records
        xmlstring = marc[record]['marc-xml']
        callback(null, xmlstring)
      )
    
    # Parse XML as JS object
    (xmlstring, callback) ->
        parser.parseString(xmlstring, callback)
    
    # Extract important info
    (marc, callback) ->
      record = marc.collection.record[0]
      allSubFields = _.map(record.datafield, (field) ->
        subFields = _.map(field.subfield, (subfield) -> subfield.$.code)
        { field: field.$.tag, subFields: _.unique(subFields)}
      )
      callback(null, allSubFields)
    
    # Flatten to list of fields and list of subfields, and
    # Remove duplicates (i.e. if there's more than one volume)
    (json, callback) ->
      fields = _.reduce(json,
                        ((arr, next) -> arr.concat next.field),
                        [])

      subfields = _.reduce(json, ((arr, next) ->
        subFields = _.map(next.subFields, (sf) -> "#{next.field}#{sf}")
        arr.concat subFields
      ), [])

      callback(null,
               {oclc: oclc, fields: _.uniq(fields), subFields: _.uniq(subfields)}
      )
  ], callback
  )

main()
