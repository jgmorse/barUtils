# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'

#tmm = CSV.open('data/TMM_Import_Template.csv', headers:true)

def parse_format(str)
  media =''
  format = ''
  str.match(/\((.*?)\)/) { format = $1 }
  case format
  when /ebook/i
      media = 'Ebook Format'
      format = 'All Ebooks'
  when /paper/i
      media = 'Book'
      format = 'Paperback'
  when /hard/i
      media = 'Book'
      format = 'Hardcover'
  end

  return [media, format]
end

def parse_isbn(str)
  isbn = ''
  str.match(/^(\d+)/) { isbn = $1}
  return isbn
end

header = [
  'Bookkey',
  'ISBN13', 'ISBN10', #at least one of these is required
  'Primary ISBN13',
  'Title Prefix',
  'Title',            #required
  'Short Title',
  'Subtitle',
  'Division',         #required
  'Imprint',          #required
  'Media',            #required
  'Format',           #required
  'Page Count',
  'Trim Width',
  'Trim Length',
  'Insert/Illustrations',
  'Series',
  'BISAC Status',
  'Discount',
  'Pub Date',
  'Pub Year',
  'Acq Editor',
  'Price',
  'Price Effective',
  'Author First 1',
  'Author Last 1',
  'Author Role 1',
  'Author First 2',
  'Author Last 2',
  'Author Role 2',
  'Author First 3',
  'Author Last 3',
  'Author Role 3',
  'Author First 4',
  'Author Last 4',
  'Author Role 4',
  'Author Bio',
  'Language',
  'Audience',
  'Supply To Region',
  'Send to Elo',
  'All Subjects 1',
  'All Subjects 2',
  'All Subjects 3',
  'All Subjects 4',
  'All Subjects 5',
  'Book Description Marketing',
  'Keynote',
  'Shopping Cart Link 1'
]


CSV.open('data/output.csv', 'w') do |output|
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    #e.g. 9781407333977 (ebook); 9781407303697 (paperback)
    isbns_formats = input['ISBN(s)'].split('; ')
    isbns_formats.each {|i|
      row = CSV::Row.new(header,[])

      row['ISBN13'] = parse_isbn(i)
      mediaFormat = parse_format(i)
      row['Media'] = mediaFormat[0]
      row['Format'] = mediaFormat[1]
      row['Imprint'] = 'British Archaeological Reports'
      output << row
    }
  end
end
