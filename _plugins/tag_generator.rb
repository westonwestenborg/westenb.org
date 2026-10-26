module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      # Tag pages with fewer posts than this are thin (a heading and a link or
      # two), so they get `noindex, follow` and stay out of the sitemap.
      # Crawlers still follow their links to the posts.
      min_posts = site.config.fetch('tag_index_min_posts', 3)

      site.tags.each do |tag, posts|
        # Same slug the post layout and tags page link to.
        page = TagPage.new(site, site.source, File.join('tags', Utils.slugify(tag.to_s)), tag)
        if posts.size < min_posts
          page.data['noindex'] = true
          page.data['sitemap'] = false
        end
        site.pages << page
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['title'] = "Tag: #{tag}"
      self.data['description'] = "Writing by Weston Westenborg tagged #{tag}."
      self.data['tag'] = tag
    end
  end
end
