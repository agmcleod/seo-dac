require 'net/http'
require 'URI'

class ReportController < ApplicationController
  def index
    if request.post?
      @report = Report.new(params[:report])
      if @report.valid?
        
      else
        render :action => 'index'
      end
    else
      @report = Report.new
    end
  end
end
