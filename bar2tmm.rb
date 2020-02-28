# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'

#tmm = CSV.open('data/TMM_Import_Template.csv', headers:true)

CSV.open('data/output.csv', 'w') do |output|
  header = ['isbn','imprint']
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    #ISBNs = row['ISBN(s)']
    row = CSV::Row.new(header,[])
    row['isbn'] = input['ISBN(s)']
    row['imprint'] = 'British Archaeological Reports'
    output << row
  end
end
