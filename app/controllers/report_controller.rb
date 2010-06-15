require 'net/http'
require 'URI'

class ReportController < ApplicationController
  def index
    if request.post?
      @report = Report.new(params[:report])
      if @report.valid?
        begin
          @report.content = Net::HTTP.get(URI.parse(params[:report][:domain]))
        rescue Exception:
          flash[:error] = "An error occured parsing the given URL. Please check that the URL you provided is correct."
          @report.content = ""
        end
      else
        render :action => 'index'
      end
    else
      @report = Report.new
    end
  end
end
