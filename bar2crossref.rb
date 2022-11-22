# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'
require 'Date'
require 'isbn'
require 'slop'
require 'nokogiri'

def parse_format(str)
  media =''
  format = ''
  str.match(/\((.*?)\)/) { format = $1 }
  case format
  when /ebook/i
      media = 'Ebook Format'
      format = 'All Ebooks'
      crossref = 'electronic'
  when /paper/i
      media = 'Book'
      format = 'Paperback'
      crossref = 'print'
  when /hard/i
      media = 'Book'
      format = 'Hardcover'
      crossref = 'print'
  end

  return [media, format, crossref]
end

begin
  opts = Slop.parse strict: true do |opt|
    opt.string '-f', '--file', 'Input exported csv from TMM'
    opt.bool   '-h', '--help' do
      puts opts
    end
  end
rescue Slop::Error => e
  puts e
  puts 'Try -h or --help'
  exit
end

base_url = "https://www.fulcrum.org"
  #start XML document for submisison to CrossRef
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.doi_batch( 'xmlns' => "http://www.crossref.org/schema/4.3.0", 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 'version' => "4.3.0", 'xsi:schemaLocation' => "http://www.crossref.org/schema/4.3.0 http://www.crossref.org/schema/deposit/crossref4.3.0.xsd") {
      xml.head {
        xml.doi_batch_id "umpre-fulcrum-#{Time.now.strftime('%F-%T')}-components"
        xml.timestamp Time.now.strftime('%Y%m%d%H%M%S')
        xml.depositor {
          xml.name 'scpo'
          xml.email_address 'mpub.xref@gmail.com'
        }
        xml.registrant 'MPublishing'
      }
      xml.body {
        CSV.foreach(opts[:file], headers: true) do |input|
          xml.book('book_type' => 'monograph' ) {
            xml.book_metadata {
              xml.titles {
                xml.title input['Title']
                xml.subtitle input['Sub-Title']
              }
              xml.publication_date {
                xml.year input['Pub Date'].gsub(/^\d\d?\/\d\d?\//, '')
              }
              isbns_formats = input['ISBN(s)'].split('; ')
              isbns_formats.each {|i|
                isbn = ''
                i.match(/^ ?(\d+)/) { isbn = $1}
                m_f = parse_format(i)
                xml.isbn isbn
              }
              xml.publisher {
                xml.publisher_name input['Publisher']
                xml.publisher_place input['Pub Location']
              }
              xml.doi_data {
                xml.doi input['DOI']
                xml.resource input['Resource']
              }
            }
          }
        end
      }
    }

end

puts builder.to_xml
