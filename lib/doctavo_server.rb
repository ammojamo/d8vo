require 'rubygems'
require 'sinatra'
require 'doctavo'
require 'haml'

dp = DoctavoParser.new
dp.parse('example.c')

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

__END__

@@ layout
%html
  %head
    %title Doctavo
  %body
    = yield

@@ index
%h1 Doctavo
%h2 Items
%table
  - @items.each do |item|
    %tr
      %td= item[:type]
      %td= item[:name]
      %td= item[:signature]
      %td= item[:filename]
      %td= item[:line_number]

@@ group_list
%h2 Groups
%ul
  - @groups.each do |name, group|
    %li
      %a{:href =>"/group/#{name}"}= group[:name]

@@ group
%h2= @group[:name]
%table
  - @group_items.each do |item|
    %tr
      %td= item[:type]
      %td= item[:name]
      %td= item[:signature]
      %td= "#{item[:filename]}:#{item[:line_number]}"
