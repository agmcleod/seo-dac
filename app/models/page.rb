class Page < ActiveRecord::Base
  belongs_to :report
  def h_tags(type)
    tags = self.get_tags("<#{type}")
  end
  
  def title_tag
    tags = self.get_tags("<title>")
  end
  
  def image_tags
    tags = self.get_tags("<img", true)
  end
  
  def link_tags
    tags = self.get_tags("<link", true)
  end
  
  def meta_tags
    tags = self.get_tags('<meta', true)
  end
  
  def script_tracking_tags
    tags = self.get_tags('<script', false, true, true)
  end
  
  def contextual_links_hrefs
    tags = self.get_tags('<p', false, true)
    anchor_hrefs = Array.new
    tags.each do |tag|
      last_index = 0
      done = false
      until done
        done = true if last_index.nil?
        i = tag.index(/href=("|')/i, last_index)
        if i.nil?
          done = true
        else
          last_index = tag.index(/"/, i+6)
          unless last_index.nil?
            anchor_hrefs << tag[(i + 6)..last_index-1]
          else
            done = true
          end
        end
      end
    end
    anchor_hrefs
  end
  
  def get_tags(tag_name, self_closing = false, after_body = false, ignore_comments = true, tag_name_only = false)
    closing_tag = nil
    unless self_closing
      closing_tag = tag_name.gsub(/</, "</")
    end
    last_close = 0
    if after_body
      body_start = self.content.index('<body')
      body_tag = self.content[body_start..self.content.index('>', body_start)]
      last_close = self.content.index(body_tag) + body_tag.size
    end
    done = false
    
    contents = Array.new
    until done      
      comment = comment_position_after_last(last_close)
      comment_close = nil
      unless comment.nil?
        comment_close = comment_close_after_open(comment) + 3
      end
      full_tag_name = self.get_full_tag_name(tag_name, last_close, self_closing)
      # This will append the appropriate tag in the case we are looking for a self closing one
      if self_closing && !full_tag_name.nil? && !full_tag_name.blank?
        last_close = self.content.index(full_tag_name, last_close)
        last_close += full_tag_name.size
        # ignores the content within comments, unless otherwise specified not to
        if ignore_comments
          contents << full_tag_name
        else
          append_if_not_commented(contents, full_tag_name, comment, comment_close)
        end
      # This appends the contents between an opening and closing tag with the given name
      elsif !full_tag_name.nil? && !full_tag_name.blank?
        if tag_name_only
          tag_val = get_full_tag_contents(full_tag_name, last_close)
          contents << tag_val
          last_close = self.content.index(tag_val, last_close) + tag_val.size
        else
          open = self.content.index(full_tag_name, last_close)
          if !open.nil? && !open.blank?
            #get next closing tag
            last_close = self.content.index(closing_tag, open) - 1
            # ignores the content within comments, unless otherwise specified not to
            if ignore_comments
              append_if_not_commented(contents, self.content[(open)+full_tag_name.size..last_close], comment, comment_close)
            else
              contents << self.content[(open)+full_tag_name.size..last_close]
            end
          else
            done = true
          end
        end
      else
        done = true
      end
    end
    contents
  end
  
  def get_full_tag_name(tag_name, index, self_closing = false)
    if />/ =~ tag_name[tag_name.size-1,1]
      tag_name
    else
      start = self.content.index(tag_name, index)
      return nil if start.nil?
      end_tag = 0
      if self_closing
        i = self.content.index('/>', start) || self.content.index('>', start)
        unless i.nil?
          end_tag = i + 1
        else
          return nil
        end
      else
        end_tag = self.content.index('>', start)
      end
      self.content[start..end_tag] 
    end
  end
  
  # Returns the complete tag and inner contents. Such as:
  # <ul><li><a href="#link">link</a></li></ul>
  def get_full_tag_contents(full_tag_name, index)
    content_index = self.content.index(full_tag_name, index)
    # subtract 1 for the space, and one for the size/index difference
    ftn_name_end = (full_tag_name.index(/\s/) || full_tag_name.size-1) - 1
    tag_type = full_tag_name[1..ftn_name_end]
    closing_tag = self.content.index(/<\/#{tag_type}>/, content_index)
    unless closing_tag.nil?
      closing_tag += "</#{tag_type}>".size
      return self.content[content_index..closing_tag]
    else 
      return nil
    end
  end
  
  def get_copy_content
    content = self.content
    body_start = content.index('<body')
    body_tag = content[body_start..content.index('>', body_start)]
    last_close = content.index(body_tag) + body_tag.size
    content = content[last_close..content.index('</body>')-1]
    index = 0
    until index.nil?
      index = content.index('<script')
      break if index.nil?
      close = content.index('</script>', index)
      if close.nil?
        close = content.size
      else
        close + 9
      end
      content = "#{content[0..index-1]}#{content[close..content.size]}"
    end
    content.gsub(/<\/?[^>]*>/, "")
  end
  
private 
  def comment_position_after_last(last)
    return self.content.index("<!--", last)
  end
  
  def comment_close_after_open(open)
    return self.content.index("-->", open)
  end
  
  def script_position_after_last(last)    
    return self.content.index(/<script/i, last)  
  end
  
  def script_close_after_open(open)
    return self.content.index(/<\/script>/i, open)
  end
  
  def is_commented(content, comment_open, comment_close)
    return false if comment_open.nil? || comment_close.nil?
    if self.content.index(content) < comment_open || self.content.index(content) > close
      return false
    else
      return true
    end
  end
  
  def is_javascript(content, script_start, script_end)
    return false if script_start.nil? || script_end.nil?
    if self.content.index(content) < script_start || self.content.index(content) > script_end
      return false
    else
      return true
    end
  end
  
  def append_if_not_commented(contents, tag, open, close)
    if open.nil? || close.nil?
      contents << tag
    else
      contents << tag if self.content.index(tag) < open || self.content.index(tag) > close
    end
  end
end