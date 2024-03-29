# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'
require 'Date'
require 'isbn'

#tmm = CSV.open('data/TMM_Import_Template.csv', headers:true)

# IMPORTANT : because this relies on processing already done in the current row,
# THIS SHOULD BE THE LAST SUBROUTINE CALLED IN MAIN!!!!!
def assign_products(row, input, pubYear)
  products = []
  base = ''

  if( pubYear < 2020 )
    base = 'bar_pre2020_collection'
  else
    base = "bar_#{pubYear}_annual"
  end
  products.push base

  case input['Series']
  when 'BAR British Series'
    products.push base+='_brit'
  when 'BAR International Series'
    products.push base+='_int'
  end

  i = 1
  products.each { |p|
    row["Fulcrum Product #{i}"] = p
    i += 1
  }

end

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

def parse_isbn_format(this_isbn_format, row, all_isbns_formats)
  #Get the isbn for this row
  isbn = ''
  this_isbn_format.match(/^ ?(\d+)/) { isbn = $1}
  # Change ISBN13 column to be the 10 digit ISBN with dashes -- as per jvanderw
  row['ISBN13'] = ISBN.with_dashes( ISBN.ten(isbn) )
  row['ISBN10'] = ISBN.ten(isbn)
  m_f = parse_format(this_isbn_format)
  row['Media'] = m_f[0]
  row['Format'] = m_f[1]
  #This is goofy: recall that we're in an 'each' loop of all isbn/formats for this title.
  #The following block is how we get the isbn/format we're *NOT* currently operating on in the 'each' loop.
  #This only works because we know BAR will only have 2 isbn/formats per title.
  #Still, there's probably a better way to write this.
  #Make a copy because we will need the deleted value later in this loop....
  copy = all_isbns_formats.slice(0 .. -1)
  copy.delete(this_isbn_format)
  child_isbn_format = copy.shift
  child_isbn_format.match(/^ ?(\d+)/) { row['ChildISBN'] = $1}
  m_f = parse_format(child_isbn_format)
  row['ChildMedia'] = m_f[0]
  row['ChildFormat'] = m_f[1]
end

def parse_creators(creators, row)
  #Only 4 author slots, so only take the first 4
  i = 1
  creators.split('; ').take(4).each { |c|
    c.match(/^(.+?),/) {row["authorlastname#{i}"] = $1}
    c.match(/, (.+?)(\(|$)/) {row["authorfirstname#{i}"] = $1.strip}

    role = ''
    c.match(/\((.*?)\)/) {role = $1}
    if role=='editor'
      row["authortype#{i}"] = 'Editor'
    else
      row["authortype#{i}"] = 'Author'
    end

    i += 1
  }
end

def parse_series(row, input)
  series = input['Series']
  if input['Sub Series']
    series +=  ":" + input['Sub Series']
  end

  if input['Sub series no']
    series += ' ' + input['Sub series no']
  end

  row['FulcrumPartnerSeries'] = series
end


header = [
  'Bookkey',
  'ISBN13', 'ISBN10', #at least one of these is required
  'Primary ISBN13',
  'ChildISBN',
  'Title Prefix',
  'Title',            #required
  'Short Title',
  'Subtitle',
  'grouplevel1',
  'grouplevel2',      #required (Division)
  'grouplevel3',      #required (Imprint)
  'Media',            #required
  'Format',           #required
  'ChildMedia',       #required
  'ChildFormat',      #required
  'Page Count',
  'Trim Width',
  'Trim Length',
  'Insert/Illustrations',
  'FulcrumPartnerSeries',
  'BISAC Status',
  'Discount',
  'Pub Date', #MM/DD/YYYY
  'Pub Year',
  'Acq Editor',
  'Price',
  'Price Effective',
  'authorfirstname1',
  'authorlastname1',
  'authortype1',
  'authorfirstname2',
  'authorlastname2',
  'authortype2',
  'authorfirstname3',
  'authorlastname3',
  'authortype3',
  'authorfirstname4',
  'authorlastname4',
  'authortype4',
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
  'Shopping Cart Link 1',
  'Open Access Avail.',
  'OA Funder',
  'DOI',
  #The following are custom for Bar
  'Other ID', #BAR Number
  'Other Subjects',
  'Imprint 1',
  'Fulcrum Product 1',
  'Fulcrum Product 2',
  'Fulcrum Product 3',
  'Fulcrum Product 4',
  'Publisher'
]

CSV.open('data/output.csv', 'w') do |output|
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    #e.g. 9781407333977 (ebook); 9781407303697 (paperback)
    isbns_formats = input['ISBN(s)'].split(';')
    isbns_formats.each {|i|
      row = CSV::Row.new(header,[])
      parse_isbn_format(i, row, isbns_formats)
      row['Title'] = input['Title']
      row['Subtitle'] = input['Sub-Title']
      row['grouplevel1'] = 'Michigan Publishing'
      row['grouplevel2'] = input['Copyright Holder']
      row['grouplevel3'] = 'British Archaeological Reports'
      row['Publisher'] = 'Fulcrum Hosted Clients'
      row['BISAC Status'] = 'Active'

      #WARNING!!!
      #BAR have switched btw USA and Euro date formatting in the past....
      #parse European-format date
      pubDate = Date.strptime(input['Pub Date'].strip, "%m/%d/%Y")
      row['Pub Date'] = pubDate.strftime('%m/%d/%Y')
      row['Pub Year'] = pubDate.year

      parse_creators( input['Creator(s)'], row )

      row['Language'] = 'English'
      row['Author Bio'] = input['Author Blurb']
      row['Book Description Marketing'] = input['Description']

      row['Other ID'] = input['BAR Number']
      row['Other Subjects'] = input['Subject']
      row['Shopping Cart Link 1'] = input['Buy Book URL']
      row['Open Access Avail.'] = input['Open Access?']
      row['OA Funder'] = input['Funder']
      row['DOI'] = 'https://doi.org/' + input['DOI'] if input['DOI']
      row['grouplevel3 1'] = input['Pub Location']
      parse_series(row, input)
      assign_products(row, input, pubDate.year)


      output << row
    }
  end
end
