require "base64"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

module Jekyll
  # Open Graph preview images. Every post gets its own 1200x630 card (kicker,
  # title, excerpt if it fits); every other HTML page shares the site card.
  #
  # The generator sets `image:` on each page, which jekyll-seo-tag turns into
  # og:image, og:image:width/height/alt and a summary_large_image Twitter card.
  # After the site is written, each card is rendered from
  # _includes/og-card.html to _site/assets/og/*.png with headless Chrome.
  # Renders are cached in .jekyll-cache/og-images by a hash of the card's
  # HTML, so `jekyll serve` only re-renders cards whose content changed.
  #
  # A page that sets its own `image:` keeps it; script/seo-check requires
  # every og:image to be 1200x630. Set CHROME_PATH if Chrome is not found.
  module OgImages
    WIDTH = 1200
    HEIGHT = 630
    DIR = "/assets/og"
    TEMPLATE = "_includes/og-card.html"
    FONTS = {
      "serif" => "assets/css/et-book/et-book-roman-line-figures/et-book-roman-line-figures.woff",
      "serif_italic" => "assets/css/et-book/et-book-display-italic-old-style-figures/et-book-display-italic-old-style-figures.woff",
      "mono" => "assets/fonts/jetbrains-mono/JetBrainsMono-Regular.woff2",
    }.freeze

    @queue = {}

    class << self
      attr_reader :queue

      def post_card(site, post)
        title = post.data["title"].to_s
        excerpt = (post.data["description"] || post.data["excerpt"]).to_s.gsub(/<[^>]+>/, "").strip
        {
          "path" => "#{DIR}/#{File.basename(post.path, '.*')}.png",
          "alt" => "#{title} by #{site.config['brand']}, #{post.date.strftime('%B %-d, %Y')}",
          "vars" => {
            "variant" => "post",
            "brand" => site.config["brand"],
            "domain" => domain(site),
            "kicker" => "#{post.date.strftime('%Y · %m · %d')} · #{post.data['kind'] || 'Post'}",
            "title" => typeset(site, title),
            "subtitle" => excerpt.empty? ? nil : typeset(site, excerpt),
          },
        }
      end

      def site_card(site)
        subtitle = site.config.dig("og_card", "site_subtitle") || site.config["description"]
        {
          "path" => "#{DIR}/site.png",
          "alt" => "#{site.config['brand']}: #{subtitle}",
          "vars" => {
            "variant" => "site",
            "brand" => "",
            "domain" => domain(site),
            "kicker" => nil,
            "title" => typeset(site, site.config["brand"]),
            "subtitle" => typeset(site, subtitle),
          },
        }
      end

      def image_data(card)
        { "path" => card["path"], "width" => WIDTH, "height" => HEIGHT, "alt" => card["alt"] }
      end

      # Curly quotes and dashes, as kramdown sets them in post bodies. Returns
      # HTML-safe text: SmartyPants escapes "&", and "<"/">" are escaped first.
      def typeset(site, text)
        smartypants = site.find_converter_instance(Converters::SmartyPants)
        smartypants.convert(text.to_s.gsub("<", "&lt;").gsub(">", "&gt;")).strip
      end

      # From config, because `jekyll serve` rewrites site.url to localhost.
      def domain(site)
        site.config.dig("og_card", "domain") || site.config["url"].to_s.sub(%r{\Ahttps?://}, "").chomp("/")
      end

      def render_all(site)
        cards = queue.delete(site) || []
        return if cards.empty?

        chrome = chrome_path
        unless chrome
          Jekyll.logger.warn "OgImages:", "Chrome not found (set CHROME_PATH); preview images not rendered"
          return
        end

        template = Liquid::Template.parse(File.read(site.in_source_dir(TEMPLATE)))
        fonts = FONTS.transform_values { |path| data_uri(site.in_source_dir(path)) }
        cache_dir = File.join(site.source, site.config.fetch("cache_dir", ".jekyll-cache"), "og-images")
        FileUtils.mkdir_p(cache_dir)

        jobs = cards.map do |card|
          html = template.render!("card" => card["vars"], "fonts" => fonts)
          [card, html, File.join(cache_dir, "#{Digest::SHA256.hexdigest(html)}.png")]
        end
        missing = jobs.reject { |_, _, cached| File.exist?(cached) }
        # One Chrome at a time: parallel headless launches on macOS can abort.
        missing.each do |card, html, cached|
          screenshot(chrome, html, cached)
        rescue StandardError => e
          # Leave it missing; script/seo-check fails the build on a missing image.
          Jekyll.logger.warn "OgImages:", "#{card['path']}: #{e.message}"
        end

        jobs.each do |card, _, cached|
          next unless File.exist?(cached)
          dest = File.join(site.dest, card["path"])
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(cached, dest)
        end
        Jekyll.logger.info "OgImages:", "#{jobs.size} preview images (#{missing.size} rendered, #{jobs.size - missing.size} cached)"
      end

      private

      def screenshot(chrome, html, out)
        Dir.mktmpdir("og-card") do |dir|
          page = File.join(dir, "card.html")
          shot = File.join(dir, "card.png")
          File.write(page, html)
          args = [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                  "--no-first-run", "--no-default-browser-check", "--user-data-dir=#{dir}/profile",
                  "--window-size=#{WIDTH},#{HEIGHT}", "--virtual-time-budget=5000",
                  "--screenshot=#{shot}", "file://#{page}"]
          # GitHub's Ubuntu runners block Chrome's sandbox; the page is our own template.
          args.insert(1, "--no-sandbox") if RUBY_PLATFORM.include?("linux")
          log, status = Open3.capture2e(*args)
          log, status = Open3.capture2e(*args) unless status.success? && File.exist?(shot) # one retry
          raise "Chrome failed to render a preview image: #{log.lines.last(3).join}" unless status.success? && File.exist?(shot)
          size = png_size(shot)
          raise "preview image is #{size.join('x')}, expected #{WIDTH}x#{HEIGHT}" unless size == [WIDTH, HEIGHT]
          FileUtils.mv(shot, out)
        end
      end

      def png_size(path)
        File.binread(path, 24)[16, 8].unpack("NN")
      end

      def data_uri(path)
        type = File.extname(path) == ".woff2" ? "font/woff2" : "font/woff"
        "data:#{type};base64,#{Base64.strict_encode64(File.binread(path))}"
      end

      def chrome_path
        candidates = [ENV["CHROME_PATH"]].compact
        %w[google-chrome google-chrome-stable chromium chromium-browser].each do |name|
          ENV["PATH"].to_s.split(File::PATH_SEPARATOR).each { |dir| candidates << File.join(dir, name) }
        end
        candidates << "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        candidates.find { |path| File.file?(path) && File.executable?(path) }
      end
    end
  end

  class OgImageGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      cards = {}
      site.posts.docs.each do |post|
        next if post.data["image"]
        card = OgImages.post_card(site, post)
        cards[card["path"]] = card
        post.data["image"] = OgImages.image_data(card)
      end

      site_card = OgImages.site_card(site)
      site.pages.each do |page|
        next if page.data["image"] || !page.html?
        cards[site_card["path"]] = site_card
        page.data["image"] = OgImages.image_data(site_card)
      end
      OgImages.queue[site] = cards.values
    end
  end

  Hooks.register :site, :post_write do |site|
    OgImages.render_all(site)
  end
end
