# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'
require 'Date'
require 'isbn'
require 'slop'
require 'nokogiri'

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
monographs = []
File.foreach( opts[:file]) {|l| monographs.push l.chomp}
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
      xml.body('book_type' => 'monograph' ) {
        xml.book_metadata {
          xml.titles {
          }
        }
      }
    }

end

puts builder.to_xml
