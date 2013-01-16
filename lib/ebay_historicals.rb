require "net/http"
require "open-uri"
require 'nokogiri'

module Ebay
  class EbayError     < StandardError; end
  class EbayAckError  < StandardError; end

class TeraPeak 
  ENDPOINT = "http://api.terapeak.com/v1/research"
  API      = "GetResearchResults"

    def initialize(api_key, cond)
      @api_key = api_key
      @cond = cond
    end

    def average_price(item)
      average_price_text(to_xml(item)).to_f
    end

    def max_price(item)
      max_price_text(to_xml(item)).to_f
    end

    def min_price(item)
      min_price_text(to_xml(item)).to_f
    end

    def median_price(item)
      median_price_text(to_xml(item)).to_f
    end

    def to_xml(item)
      xml = Nokogiri::XML.parse(xml_response(item))
      xml
    end

    def all_xml(item)
      response = to_xml(item)
      puts response    
    end

    private

    def price_text(xml, price_type)
      price_node = xml.xpath("//#{price_type}")
      raise EbayError if price_node.nil?
      raise EbayError if price_node.text.nil?
      price_node.text
    end

    def median_price_text(xml)
      price_text(xml, "Median")
    end

    def average_price_text(xml)
      price_text(xml, "Average")
    end

    def min_price_text(xml)
      price_text(xml, "Lowest")
    end

    def max_price_text(xml)
      price_text(xml, "Highest")
    end

    def ensure_short_description(description)
      short_description = ""
      description.split(" ").each do |word|
        if (short_description+word).size < 80
          short_description << word + " "
        end
      end
      short_description.strip
    end

    def xml_response(item)
      keyword = item
      api_key = @api_key
      days = 30
      cond = @cond
      url = URI.parse("http://api.terapeak.com/v1/research/xml?api_key=#{api_key}")
      api_url = "/v1/research/xml?api_key=#{api_key}"
      request = "<GetResearchResults>
                    <Version>2</Version>
                    <SearchQuery>
                      <Keywords>#{keyword}</Keywords>
                      <Dates><DateRange>#{days}</DateRange></Dates>
                      <ItemCondition>
                          <RollupValueID>#{cond}</RollupValueID>
                      </ItemCondition>
                    </SearchQuery>
                  </GetResearchResults>"
      http = Net::HTTP::new(url.host, url.port)
      response = http.post(api_url, request)
      puts response
      responsebody = response.body
    end
  end

class ListingInfo
  ENDPOINT = "http://open.api.ebay.com/shopping"

  def initialize(ebay_appId)
    @ebay_appId = ebay_appId
  end

   def item_array(item)
    response = xml_response(item)
    product = []
    response.search('Product').each do |i|
      info = Hash.new
      info['image'] = i.search('StockPhotoURL').text
      info['details'] = i.search('DetailsURL').text
      info['title'] = i.search('Title').text
      h = Hash.new
      i.search('ProductID').each do |id|
        idvalue = id.values[0]
        h[idvalue] = id.text
      end
      info['id'] = h
      product << info
    end
    return product
  end

  def ensure_short_description(description)
    description.chomp
    short_description = ""
    description.split(" ").each do |word|
      if (short_description+word).size < 80
        short_description << word + " "
      end
    end
    short_description.strip
  end

  def xml_response(item)
    params = {
      "callname"          => "FindProducts",
      "appid"             => @ebay_appId,
      "responseencoding"  => 'XML',
      "siteid"            => "0",
      "version"           => "525",
      "QueryKeywords"     => ensure_short_description(item),
      "AvailableItemsOnly"=> "true",
      "MaxEntries"        => "10"
    }
    url     = URI.parse(ENDPOINT)
    request = Net::HTTP::Get.new(url.path)
    request.set_form_data(params)
    api_url = "#{ENDPOINT}?#{request.body}"

    xml = Nokogiri::XML(open(api_url))
    response = Nokogiri::XML.parse(xml.to_xml)
  end
end

class FindProducts
  ENDPOINT = "http://svcs.ebay.com/services/search/FindingService/v1"

  def initialize(ebay_appId)
    @ebay_appId = ebay_appId
  end

  def item_array(item, zip, distance)
    response = xml_response(item, zip, distance)
    product = []
    response.search('item').each do |i|
      info = Hash.new
      info['title']             = i.search('title').text
      info['url']               = i.search('viewItemURL').text
      info['image']             = i.search('galleryURL').text
      info['condition']         = i.search('conditionDisplayName').text
      info['listingType']       = i.search('listingType').text
      info['buyItNowAvailable'] = i.search('buyItNowAvailable').text
      info['currentPrice']      = i.search('currentPrice').text
      info['postalCode']        = i.search('postalCode').text
      info['distance']          = i.search('distance').text
      product << info
    end
    return product
  end

  def xml_response(item, zip, distance)
    if zip.blank? || distance.blank?
      id = item
      params = {
        "operation-name"                    => "findItemsByProduct",
        "service-version"                   => "1.0.0",
        "security-appname"                  => @ebay_appId,
        "response-data-format"              => 'XML',
        "REST-PAYLOAD"                      => '',
        "productId.@type"                   => "ReferenceID",
        "paginationInput.entriesPerPage"    => '5',
        "itemFilter(0).name"                => 'ListingType',
        "itemFilter(0).value"               => 'AuctionWithBIN',
        "itemFilter(0).value"               => 'FixedPrice',
        "productId"                         =>  id
      }
    else
      id = item
      zip = zip
      distance = distance
      params = {
        "operation-name"                    => "findItemsByProduct",
        "service-version"                   => "1.0.0",
        "security-appname"                  => @ebay_appId,
        "response-data-format"              => 'XML',
        "REST-PAYLOAD"                      => '',
        "productId.@type"                   => "ReferenceID",
        "paginationInput.entriesPerPage"    => '5',
        "itemFilter(0).name"                => 'ListingType',
        "itemFilter(0).value"               => 'AuctionWithBIN',
        "itemFilter(0).value"               => 'FixedPrice',
        "buyerPostalCode"                   =>  zip,
        "sortOrder"                         => 'Distance',
        "itemFilter.name"                   => 'MaxDistance',
        "itemFilter.value"                  =>  distance,
        "productId"                         =>  id
      }
    end

    url     = URI.parse(ENDPOINT)
    request = Net::HTTP::Get.new(url.path)
    request.set_form_data(params)    
    api_url = "#{ENDPOINT}?#{request.body}"

    # puts api_url
    xml = Nokogiri::XML(open(api_url))
    response = Nokogiri::XML.parse(xml.to_xml)
  end
end

end