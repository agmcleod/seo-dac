require 'net/http'
# require 'URI'

class Report < ActiveRecord::Base
  # the url_query method sets the URL's source code to the content attribute appropriately
  # if it's correct, it will then query the pages as required
  validate :url_query
  has_many :pages
  
  attr_accessor :content, :sitemap, :images, :h3, :tracking, :keywords, :contextual_links, :url_type
  
  def add_page(content, url)
    self.pages << Page.new(:name => "Layer #{self.pages.size}", :content => content, :keywords => self.keywords, :url => url)
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
  
    href = get_navigation_tags(index_page)
    unsuccessful = false
    until unsuccessful
      href = get_navigation_tags(self.pages[self.pages.size - 1])
      unsuccessful = parse_page_and_get_next(href)
    end
  end
  
private
  
  def get_navigation_tags(page)
    tag = page.get_tags_with_attribute('class', 'layer-nav', { :after_body => true, :contains => true })[0]
    if !tag.nil?
      indexes = Array.new
      done = false
      last = 0
      Rails.logger.debug "tag: #{tag}| page: #{page.url}"
      until done
        idx = tag.index(/href=("|')/, last)
        unless idx.nil?
          last = idx + 1
          indexes << idx
        else
          done = true
        end
      end
      indexes = indexes.sort_by { rand }   
      href_index = indexes[0]
      url = nil
      unless href_index.nil?
        url = tag[(href_index + 6)..tag.index(/"|'/, href_index+6)].gsub(/'|"/,'')
      end
      return url
    else
      return nil
    end
  end
  
  def parse_page_and_get_next(href)
    unsuccessful = true
    if !href.nil? && !href.blank?
      if href[0,1] == '/'
        begin
         self.add_page(Net::HTTP.get(URI.parse("#{self.domain_no_slash}#{href}")), "#{self.domain_no_slash}#{href}")
         unsuccessful = false
        rescue Exception => ex
          self.errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
        end
      elsif href.index(/http:\/\/|https:\/\//)
        begin
         self.add_page(Net::HTTP.get(href), href)
         unsuccessful = false
        rescue Exception => ex
          self.errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
        end
      else
        begin
          self.add_page(Net::HTTP.get(URI.parse("#{self.domain_with_slash}#{href}")), "#{self.domain_with_slash}#{href}")
          unsuccessful = false
        rescue Exception => ex
          self.errors.add_to_base "Exception occured trying to retrieve the next layer: #{ex.message}"
        end
      end
    end
    unsuccessful
  end
  
  def url_query
    begin
      self.add_page(Net::HTTP.get(URI.parse(self.domain)), self.domain)
      if self.url_type == 'domain'
        self.get_layers(self.pages[0], errors)
      end      
    rescue Exception => ex
      errors.add_to_base("An error occured parsing the given URL. Please check that the URL you provided is correct. #{ex.message}")
      self.content = ""
    end
  end  
end
