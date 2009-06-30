require 'rubygems'
require 'sinatra'
require 'doctavo'
require 'haml'
require 'sass'

dp = DoctavoParser.new
dp.parse('example.c')

class String
  def humanize()
    humanized = self.tr("_", " ")
    humanized[0] = humanized[0,1].upcase[0] unless humanized.empty?
    return humanized
  end
end

get '/' do
  @items = dp.items
  @groups = dp.groups
  haml :group_list
end

get '/group/:name' do
  @items = dp.items
  @groups = dp.groups
  name = params[:name].intern rescue nil
  pass unless @groups.include?(name)
  @group = @groups[name]
  @group_items = @items.select { |item| @group[:items].include?(item[:id]) }
  haml :group
end

# SASS stylesheet
get '/stylesheets/style.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end
