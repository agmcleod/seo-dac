require 'net/http'
require 'URI'

class ReportController < ApplicationController
  def index
    if request.post?
      @report = Report.new(params[:report])
      unless @report.valid?
        render :action => 'index'
      end
    else
      @report = Report.new
    end
  end
end
