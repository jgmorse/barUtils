# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'

#tmm = CSV.open('data/TMM_Import_Template.csv', headers:true)

def parse_format(str)
  format = ''
  str.match(/\((.*?)\)/) { format = $1 }
  return format
end

def parse_isbn(str)
  isbn = ''
  str.match(/^(\d+)/) { isbn = $1}
  return isbn
end


CSV.open('data/output.csv', 'w') do |output|
  header = ['isbn','format','imprint']
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    #e.g. 9781407333977 (ebook); 9781407303697 (paperback)
    isbns_formats = input['ISBN(s)'].split('; ')
    isbns_formats.each {|i|
      row = CSV::Row.new(header,[])

      row['isbn'] = parse_isbn(i)
      row['format'] = parse_format(i)
      row['imprint'] = 'British Archaeological Reports'
      output << row
    }
  end
end
