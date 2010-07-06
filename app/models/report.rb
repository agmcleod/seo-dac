require 'net/http'
require 'URI'

class Report < ActiveRecord::Base
  # the url_query method sets the URL's source code to the content attribute appropriately
  validate :url_query
  has_many :pages
  
  attr_accessor :content, :sitemap, :images, :h3, :tracking, :keywords, :contextual_links, :url_type
  
  def add_page(content)
    self.pages << Page.new(:name => "Layer #{self.pages.size}", :content => content)
    self.content = self.pages[0].content if self.pages.size == 0
  end
  
  def has_sitemaps
    begin
      sitemap = Net::HTTP.get(URI.parse("#{self.domain_no_slash}/sitemap.xml"))
      index = Net::HTTP.get(URI.parse("#{self.domain_no_slash}/sitemap-index.xml"))
      [sitemap, index]
    rescue
      return [nil, nil]
    end    
  end
  
  def domain_no_slash
    domain = self.domain
    slash = self.domain.index('/', domain.index(/http:\/\/|https:\/\//)+8)
    if slash.nil?
      domain
    else
      domain[0..slash-1]
    end
  end
  
  def domain_with_slash
    "#{self.domain_no_slash}/"
  end
  
  # Scans progressively through the program to grab the code of each layer
  # @param [String] index_page - The page object for the index page of the site
  # @param [ActiveRecord Error] errors - passed to allow addition of validation errors
  # @return [void]
  def get_layers(index_page, errors)
    ul_tags = index_page.get_tags('<ul', false, true, true, true)
    logger.debug "ul: #{ul_tags.size}"
      ul_tags.each do |tag|
      class_index = tag.index(/class=("|')/)
      unless class_index.nil?
        class_attribute = tag[(class_index + 7)..tag.index(/"|'/, class_index+7)]
        if class_attribute.index('layer-nav')
          href_index = tag.index(/href=("|')/)
          success = false        
          unless href_index.nil?
            href = tag[(href_index + 6)..tag.index(/"|'/, href_index+6)].gsub(/'|"/,'')
            unless href.blank?
              logger.debug "href: #{href}"
              if href[0,1] == '/'
                #begin
                  self.add_page(Net::HTTP.get(URI.parse("#{self.domain_no_slash}#{href}")))
                  success = true
                #rescue Exception => ex
                #  errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
                #end
              elsif href.index(/http:\/\/|https:\/\//)
                #begin
                  self.add_page(Net::HTTP.get(href))
                  success = true
                #rescue Exception => ex
                  errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
                #end
              else
                #begin
                  logger.debug "with-slash"
                  self.add_page(Net::HTTP.get(URI.parse("#{self.domain_with_slash}#{href}")))
                  success = true
                #rescue Exception => ex
                  errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
                #end
              end
            end
          end
          if success
            ul_tags = self.pages[self.pages.size - 1].get_tags('<ul', false, true, true, true)
          end
        end
      end
    end
  end
  
private
  
  def url_query
    # begin
      self.add_page(Net::HTTP.get(URI.parse(self.domain)))
      if self.url_type == 'domain'
        self.get_layers(self.pages[0], errors)
      end      
    # rescue Exception => ex
    #  errors.add_to_base("An error occured parsing the given URL. Please check that the URL you provided is correct.")
      self.content = ""
    # end
  end  
end
