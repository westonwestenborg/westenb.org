require 'securerandom'

module Jekyll
  class SideNoteTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      @text =~ /(\S+)\s+(.*)/
      id = $1
      content = $2

      # Enhanced sidenote that is more visible
      "<sup class='sidenote-number'></sup><span class='sidenote'>#{content}</span>"
    end
  end

  class MarginNoteTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      # Enhanced marginnote that is more visible
      "<span class='marginnote'>#{@text}</span>"
    end
  end
end

Liquid::Template.register_tag('sidenote', Jekyll::SideNoteTag)
Liquid::Template.register_tag('marginnote', Jekyll::MarginNoteTag)