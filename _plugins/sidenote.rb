require 'securerandom'

module Jekyll
  class SideNoteTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text.strip
    end

    def render(context)
      @text =~ /(\S+)\s+(.*)/m
      raw_id = $1
      content = $2 || @text

      id = "sn-#{raw_id || SecureRandom.hex(4)}-#{SecureRandom.hex(3)}"

      <<~HTML.gsub(/\n\s*/, '')
        <label for="#{id}" class="margin-toggle sidenote-number"></label>
        <input type="checkbox" id="#{id}" class="margin-toggle"/>
        <span class="sidenote">#{content}</span>
      HTML
    end
  end

  class MarginNoteTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text.strip
    end

    def render(context)
      id = "mn-#{SecureRandom.hex(4)}"

      <<~HTML.gsub(/\n\s*/, '')
        <label for="#{id}" class="margin-toggle">&#8853;</label>
        <input type="checkbox" id="#{id}" class="margin-toggle"/>
        <span class="marginnote">#{@text}</span>
      HTML
    end
  end
end

Liquid::Template.register_tag('sidenote', Jekyll::SideNoteTag)
Liquid::Template.register_tag('marginnote', Jekyll::MarginNoteTag)
