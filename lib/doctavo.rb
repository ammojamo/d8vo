require 'pp'
require 'uuid'

class DoctavoParser
  @@comment_start_re = /^\/\*\*/
  @@comment_continue_re = /^ \*/
  @@comment_end_re = /^.*\*\/.*/

  @@comment_content_re = /^(?:\/\*\*| \*)(.*?)(?:\*\/.*)?$/

  attr_reader :groups, :items

  def initialize()
    @groups = {}
    @items = []
  end

  def parse(filename)
    @filename = filename
    @line_number = 0
    @state = :idle

    File.open(filename) do |file|
      file.each_line do |line|
        @line_number += 1
        line.chomp!

        case @state

        when :idle
          begin_comment(line) if line =~ @@comment_start_re

        when :comment
          handle_comment_line(line) if line =~ @@comment_continue_re

        when :post_comment
          if line =~ @@comment_start_re
            begin_comment(line)
          elsif !line.strip.empty?
            begin_item(line)
          end

        when :item
          handle_item_line(line)
        end

      end
    end

    return @items
  end

  private

  def begin_item(line)
    @item_line_number = @line_number
    @item_lines = []
    @state = :item
    handle_item_line(line)
  end

  def handle_item_line(line)
    @item_lines << line

    # defines
    if @item_lines[0] =~ /#define/
      @type = :define
      @signature = line
      @name = line.scan(/#define\s+(\w*)/)[0][0]
      complete_item and return
    end

    # typedef structs
    if @item_lines[0] =~ /^typedef\s+struct\s*\{/
      if @item_lines[-1] =~ /^\}\s*\w+;/
        @type = :struct
        @name = @item_lines[-1].scan(/^\}\s*(\w+);/)[0][0]
        @signature = "typedef struct { ... } #{@name}"
        complete_item and return
      end
      if @item_lines.size > 1 and @item_lines[-2].strip == "}" and @item_lines[-1] =~ /^\w+;/
        @type = :struct
        @name = @item_lines[-1].scan(/^(\w+);/)[0][0]
        @signature = "typedef struct { ... } #{@name}"
        complete_item and return
      end
    end

    # functions, variables
    if @item_lines[0] =~ /^(extern|static|void|char|long|signed|unsigned|int|short|float|double|inline)/
      if @item_lines[-1] =~ /[;{]/
        declaration = @item_lines.join(" ").scan(/([^;{]*)[;{]/)[0][0]
        declaration.gsub!(/\s+/, " ")
        @signature = declaration
        if(declaration.include?("("))
          @name = declaration.scan(/(\w+)\s*\(/)[0][0]
          @type = :function
        else
          @name = declaration.scan(/(\w+)$/)
          @type = :variable
        end
        complete_item and return
      end
    end
  end

  def complete_item
    item = {
      :id => UUID.create,
      :type => @type,
      :signature => @signature,
      :name => @name,
      :line_number => @line_number,
      :filename => @filename,
      :comments => @comment_lines,
      :groups => @item_groups
    }

    @item_groups.each{ |group| add_item_to_group(item, group) }
    @items << item

    @state = :idle
    true
  end

  def begin_comment(line)
    @comment_lines = []
    @state = :comment
    handle_comment_line(line)
  end

  def handle_comment_line(line)
    @comment_lines << get_comment_content(line)
    if line =~ @@comment_end_re
      @state = :post_comment
      process_comment
    end
  end

  def get_comment_content(line)
    content = line.scan(@@comment_content_re)[0][0].strip rescue ""
    content == "/" ? "" : content
  end

  def process_comment
    @item_groups = []

    @comment_lines.each do |line|

      # @ingroup
      if line =~ /^\s*[@\\]ingroup\s+\w/
        groups = line.scan(/^\s*[@\\]ingroup\s+(.*)/)[0][0].strip rescue ""
        @item_groups += groups.split(",").map { |group| group.intern }
      end

      # @defgroup
      #if line =~ /^\s*[@\\]defgroup\s+\w/
      #  group = line.scan(/^\s*[@\\]defgroup\s+(\w+)/)[0][0]
      #end
    end
  end

  def add_item_to_group(item, group)
    group = group.to_s.intern
    if !@groups.include?(group)
      @groups[group] = {
        :name => group.to_s,
        :items => []
      }
    end
    @groups[group][:items] << item[:id]
  end
end
