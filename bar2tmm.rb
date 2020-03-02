# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'

#tmm = CSV.open('data/TMM_Import_Template.csv', headers:true)

# IMPORTANT : because this relies on processing already done in the current row,
# THIS SHOULD BE THE LAST SUBROUTINE CALLED IN MAIN!!!!!
def assign_products(row, input)
  products = []
  base = ''

  if( row['Pub Year'].to_i < 2020 )
    base = 'bar_pre2020_collection'
    products.push base
  else
    #stub for years 2020 and later, TBD
  end

  case row['Series']
  when 'BAR British Series'
    products.push base+='_brit'
  when 'BAR International Series'
    products.push base+='_int'
  end

  row['Fulcrum Products'] = products.join(';')

end

def parse_format(str, row)
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

  row['Media'] = media
  row['Format'] = format
end

def parse_isbn(str, row)
  str.match(/^(\d+)/) { row['ISBN13'] = $1}
end

def parse_creators(creators, row)
  #Only 4 author slots, so only take the first 4
  i = 1
  creators.split('; ').take(4).each { |c|
    c.match(/^(.+?),/) {row["Author Last #{i}"] = $1}
    c.match(/, (.+?)(\(|$)/) {row["Author First #{i}"] = $1.strip}

    role = ''
    c.match(/\((.*?)\)/) {role = $1}
    if role=='editor'
      row["Author Role #{i}"] = 'Editor'
    else
      row["Author Role #{i}"] = 'Author'
    end

    i += 1
  }
end

def parse_subseries(row, input)
  subseries = ''
  if input['Sub Series']
    subseries = input['Sub Series']
  end

  if input['Sub series no']
    subseries += ' ' + input['Sub series no']
  end

  row['Sub Series'] = subseries if subseries
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
  'Shopping Cart Link 1',
  'Open Access Avail.',
  'OA Funder',
  'DOI',
  #The following are custom for Bar
  'Other ID', #BAR Number
  'Other Subjects',
  'Sub Series',
  'Imprint 1',
  'Fulcrum Products',
  'Publisher'
]

CSV.open('data/output.csv', 'w') do |output|
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    #e.g. 9781407333977 (ebook); 9781407303697 (paperback)
    isbns_formats = input['ISBN(s)'].split('; ')
    isbns_formats.each {|i|
      row = CSV::Row.new(header,[])
      parse_isbn(i, row)
      row['Title'] = input['Title']
      row['Subtitle'] = input['Sub-Title']
      row['Division'] = input['Copyright Holder']
      row['Imprint'] = 'British Archaeological Reports'
      row['Publisher'] = 'Fulcrum Hosted Clients'

      parse_format(i, row)

      row['Series'] = input['Series']
      row['BISAC Status'] = 'Active'
      row['Pub Date'] = input['Pub Year']
      input['Pub Year'].match(/^(\d{4})/) {row['Pub Year'] = $1}

      parse_creators( input['Creator(s)'], row )

      row['Language'] = 'English'
      row['Author Bio'] = input['Author Blurb']

      row['Other ID'] = input['BAR Number']
      row['Other Subjects'] = input['Subject']
      row['Shopping Cart Link 1'] = input['Buy Book URL']
      row['Open Access Avail.'] = input['Open Access?']
      row['OA Funder'] = input['Funder']
      row['DOI'] = 'https://doi.org/' + input['DOI'] if input['DOI']
      row['Imprint 1'] = input['Pub Location']
      parse_subseries(row, input)
      assign_products(row, input)


      output << row
    }
  end
end
