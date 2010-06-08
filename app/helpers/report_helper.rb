class String
  def get_tag_attribute(attribute)
    index = (self.index(/#{attribute}=/i) || 0) + (attribute.size + 2)
    return "" if index.nil?
    end_index = self.index(/"|'/i, index)-1
    return "" if end_index.nil?
    self[index..end_index] || ""
  end
  
  def occurances_of(str, ignore_case = false)
    last_index = 0
    done = false
    occurances = 0
    until done
      last_index += 1 if last_index > 0
      i = nil
      if ignore_case
        i = self.index(/#{str}/i, last_index)
      else
        i = self.index(str, last_index)
      end
      done = true if i.nil?
      last_index = i
      occurances += 1 if !done
    end
    occurances
  end
  
  def word_count
    self.scan(/(\w|-)+/).size
  end
  
  def density_in_percent(keyword, keyword_amount = nil)
    count = self.gsub(/<\/?[^>]*>/, "").word_count
    keyword_amount = self.occurances_of(keyword, true) if keyword_amount.nil?
    Rails.logger.debug "kwd: #{keyword_amount} count: #{count} | result: #{(keyword_amount.to_f / count.to_f) * 100}"
    (keyword_amount.to_f / count.to_f) * 100
  end
end
module ReportHelper
  
  def display_h1_report(report)
    out = ""
    tag_contents = report.h_tags('h1')
    if tag_contents.size == 0
      out = "<tr><td class=\"report-error-td\">H1 Tag Error</td><td class=\"report-error-td\"><span class=\"small-errors\">" + 
        "Error: h1 not found.</span></tr>"
      return out
    end
    counter = 1
    tag_contents.each do |content|
      if counter > 1
        out = "#{out}<tr><td class=\"report-error-td\">H1 Tag Error</td><td class=\"report-error-td\">" + 
          "Error: more than one h1 found.</td></tr>"
      else
        out = "#{out}<tr><td>H1 Tag</td><td>#{h(content)}</td></tr>"
      end      
      counter += 1
    end
    out
  end
  
  def display_title_report(report)
    out = ""
    tag_contents = report.title_tag
    
    if tag_contents.size == 0
      out = "<tr><td class=\"report-error-td\">Title Tag Error</td><td class=\"report-error-td\"><span class=\"small-errors\">" + 
        "Error: title tag not found.</span></td></tr>"
    elsif tag_contents.size > 1
      out = "<tr><td class=\"report-error-td\">Title Tag Error</td><td class=\"report-error-td\"><span class=\"small-errors\">" + 
        "Error: more than one title tag found.</span></td></tr>"
    end
    counter = 1
    tag_contents.each do |content|
      if !content.index('Invalid').nil?
        out = "#{out}<tr><td class=\"report-error-td\">Title Tag"
        if counter > 1
          out = "#{out} ##{counter}"
        end
        out = "#{out}</td><td class=\"report-error-td\">#{h(content)}</td></tr>"
      else
        out = "#{out}<tr><td>Title Tag"
        if counter > 1
          out = "#{out} ##{counter}"
        end
        out = "#{out}</td><td>#{h(content)}</td></tr>"
      end
      counter += 1
    end
    out
  end
  
  def display_h_report(report, type)
    out = ""
    tag_contents = report.h_tags(type)
    counter = 1
    tag_contents.each do |content|      
      out = "#{out}<tr><td>#{type.upcase} ##{counter}</td><td>#{h(content)}</td></tr>"
      counter += 1
    end
    out
  end
  
  def display_image_alt_report(report)
    out = ""
    tag_contents = report.image_tags
    counter = 1
    tag_contents.each do |content|
      alt = content.get_tag_attribute('alt')
      src = content.get_tag_attribute('src')
      if alt.blank?
        out = bad_image(counter, out, src)
      elsif !src.nil?
        out = "#{out}<tr><td>Image ##{counter}</td><td>alt value: #{alt}</td></tr>"
      else
        out = "#{out}<tr class=\"report-error-td\"><td>Image ##{counter}</td><td class=\"report-error-td\">Image is broken, review src attribute</td></tr>"
      end
      counter += 1
    end
    out
  end
  
  def display_sitemap_report(report)
    sitemaps = report.has_sitemaps
    out = ""
    if sitemaps[0].nil?
      out = "<tr><td class=\"report-error-td\">Sitemap Error:</td><td class=\"report-error-td\">" + 
        "sitemap.xml not found, it should be created and then submitted to web master central</td></tr>"
    else
      xml = sitemaps[0].index("<?xml")
      logger.debug "xml: #{xml}"
      if xml.nil?
        out = "<tr><td class=\"report-error-td\">Sitemap Error:</td><td class=\"report-error-td\">" + 
          "sitemap.xml url has returned, but does not have content labeling it as an xml file. Please review"
      else
        out = "<tr><td>Sitemap</td><td>The sitemap.xml has been found. Review web master central for # of URLs submitted & indexed</td></tr>"
      end
      out
    end
    
    if sitemaps[1].nil?
      out = "#{out}<tr><td class=\"report-warning-td\">Sitemap Index Error:</td><td class=\"report-warning-td\">" + 
        "sitemap-index.xml not found, depending on the program, it may need to be created</td></tr>"
    else
      xml = sitemaps[1].index("<?xml")
      if xml.nil?
        out = "#{out}<tr><td class=\"report-warning-td\">Sitemap Index Error:</td><td class=\"report-warning-td\">" + 
          "sitemap-index.xml url has returned, but does not have content labeling it as an xml file. Please review"
      else
        out = "#{out}<tr><td>Sitemap Index</td><td>The sitemap-index.xml has been found. Review web master central for # of URLs submitted & indexed</td></tr>"
      end
      out
    end
  end
  
  def display_canonical_report(report)
    out = ""
    tag_contents = report.link_tags
    tag_contents.each do |tag|
      rel = tag.get_tag_attribute "rel"
      if /canonical/ =~ rel
        href = tag.get_tag_attribute 'href'
        #if href.downcase != report.domain
        #  out = "#{out}<tr><td>Link/Canonical</td><td><b>Does not match current URL:</b> #{tag.get_tag_attribute('href')}</td></tr>"
        #else
          out = "#{out}<tr><td>Link/Canonical</td><td>#{tag.get_tag_attribute('href')}</td></tr>"
        #end
      end
    end
    return "<tr><td class=\"report-error-td\">Link/Canonical</td><td class=\"report-error-td\">
      No canonical link tag found</td></tr>" if out.blank?
    out
  end
  
  def display_description_meta_tag_report(report)
    out = ""
    tag_contents = report.meta_tags
    counter = 1
    tag_contents.each do |tag|
      name = tag.get_tag_attribute "name"
      content = tag.get_tag_attribute "content"
      if /description/ =~ name && !content.nil? && !content.blank?
        if counter > 1
          out = "#{out}<tr><td class=\"report-error-td\">Meta Tag - Description</td><td class=\"report-error-td\">More than 
            one meta description, should only be one</td></tr>"
        else
          out = "#{out}<tr><td>Meta Tag - Description</td><td>#{content}</td></tr>"
        end
      elsif /description/ =~ name
        out = "#{out}<tr><td class=\"report-error-td\">Meta Tag - Description</td><td class=\"report-error-td\">
          Description tag found, but has no content.</td></tr>"
      end      
      counter += 1 if /description/ =~ name
    end
    out = "<tr><td class=\"report-error-td\">Meta Tag - Description</td><td class=\"report-error-td\">
      No meta tag for a description found.</td></tr>" if out.blank?
    out
  end
  
  def display_invalid_report(report)
    num = report.content.occurances_of('Invalid Parameters')
    if num > 0
      out = "<tr><td class=\"report-error-td\">Invalid Parameters found</td><td class=\"report-error-td\">
        Number of occurances: #{report.content.occurances_of('Invalid Parameters')}</td></tr>"
    else
      ""
    end
  end
  
  def display_tracking_report(report)
    out = ""
    tag_contents = report.script_tracking_tags
    tag_contents.each do |tag|
      tag_name = "Tracking Code"
      tag_name = "GA Code" unless tag.index(/(('|")(UA\-))/).nil? 
      tag_name = "GA Code" unless tag.index('google-analytics.com/ga.js').nil? || tag.index('gaJsHost').nil?
      tag_name = "ClickTracks" unless tag.index(/window\.CT_X_TrackVisit/i).nil?
      out = "#{out}<tr><td>#{tag_name}</td><td>#{h(tag)}</td></tr>"
    end
    if out.blank?
      out = "<tr><td class=\"report-error-td\">Tracking Code</td><td class=\"report-error-td\">No GA or Clicktracks found</td></tr>"
    end
    out
  end
  
  def keywords_report(report)
    out = ""
    keywords = report.keywords.split(',')
    content = report.get_copy_content
    keywords_out = Array.new
    keywords.each do |keyword|
      keyword_amount = content.occurances_of(keyword, true)
      keywords_out << "#{keyword}: #{pluralize(keyword_amount, 'time')} | 
        density: #{number_to_percentage(content.density_in_percent(keyword, keyword_amount), 
        :precision => 2, :delimiter => ',', :separator => '.')}"
    end
    keywords_out = keywords_out.join(', ')
    out = "<tr><td>Keyword occurances</td><td>#{keywords_out}</td></tr>"
  end
  
  def contextual_links_report(report)
    out = "<tr><td>Contextual links</td><td>#{h(report.contextual_links_hrefs.join('; '))}</td></tr>"    
  end
  
  def show_options(f)
    options = {
      :sitemap => 'Sitemaps',
      :images => 'Images',
      :h3 => 'H3 Tags',
      :tracking => 'GA & ClickTracks',
      :contextual_links => 'Contextual Links'
    }
    out = ""
    options.each do |k, v|
      out = "#{out}<span class=\"small-option\"> #{f.label k, v}</span>
      #{f.check_box k, {}, "y", "n"}"
    end
    out
  end  
private
  
  def bad_image(counter, out, src = "")
    "#{out}<tr><td class=\"report-warning-td\">Image ##{counter}</td>
      <td class=\"report-warning-td\">No alt attribute found, or it was set to empty. |
      src: #{src}</td></tr>"
  end
  
end
