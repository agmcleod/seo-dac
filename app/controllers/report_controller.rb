require 'rubygems'
require 'Curl'
require 'net/http'
require 'URI'

class ReportController < ApplicationController
  def index
    if request.post?
      @report = Report.new(params[:report])
      if @report.valid?
        @report.content = Curl::Easy.perform(URI.encode(params[:report][:domain])).body_str
      else
        render :action => 'index'
      end
    else
      @report = Report.new
    end
  end
end
