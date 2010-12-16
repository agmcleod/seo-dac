require 'net/http'
# require 'URI'

class ReportController < ApplicationController
  def index
    if request.post?
      @report = Report.new(params[:report])
      @report.domain = "http://#{@report.domain}" if @report.domain.index('http://').nil?
      unless @report.valid?
        render :action => 'index'
      end
    else
      @report = Report.new
    end
  end
end
