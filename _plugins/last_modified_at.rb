require "open3"
require "time"

module Jekyll
  # Sets `last_modified_at` from git history so the sitemap's <lastmod>,
  # `article:modified_time` and JSON-LD `dateModified` change when content does.
  # The IndexNow step in CI submits a URL only when its <lastmod> changes, so
  # these dates must be accurate and stable between builds.
  #
  # - Posts: the later of the post date and the last commit touching the file.
  # - Pages with a source file: the last commit touching the file. Pages that
  #   list posts (their source mentions site.posts or site.tags) move forward
  #   when a newer post is published, but not when an old post is edited,
  #   because the list itself doesn't change.
  # - Generated tag pages: the date of the newest post carrying the tag.
  #
  # A `last_modified_at` set in front matter always wins. Shallow clones are
  # skipped, because every file would report the HEAD commit's date.
  class GitLastModified < Generator
    safe true
    priority :low # after TagPageGenerator, before jekyll-sitemap

    LISTS_POSTS = /site\.(posts|tags)\b/

    def generate(site)
      @site = site
      unless git_history_available?
        Jekyll.logger.warn "LastModified:", "no full git history; sitemap <lastmod> falls back to post dates"
        return
      end

      site.posts.docs.each do |post|
        next if post.data.key?("last_modified_at")
        committed = commit_time(post.path)
        post.data["last_modified_at"] = [post.date, committed].compact.max
      end

      newest_post = site.posts.docs.map(&:date).max

      site.pages.each do |page|
        next if page.data.key?("last_modified_at")
        if page.data["tag"]
          tagged = site.tags[page.data["tag"]] || []
          page.data["last_modified_at"] = tagged.map(&:date).max
          next
        end

        source = site.in_source_dir(page.relative_path)
        next unless File.file?(source)
        committed = commit_time(source)
        next unless committed
        committed = [committed, newest_post].compact.max if File.read(source).match?(LISTS_POSTS)
        page.data["last_modified_at"] = committed
      end
    end

    private

    def git(*args)
      out, status = Open3.capture2("git", "-C", @site.source, *args, err: File::NULL)
      status.success? ? out.strip : nil
    rescue Errno::ENOENT
      nil
    end

    def git_history_available?
      git("rev-parse", "--is-shallow-repository") == "false"
    end

    # Last commit time for a file, or nil if the file has never been committed.
    def commit_time(path)
      stamp = git("log", "-1", "--format=%cI", "--", path)
      stamp.nil? || stamp.empty? ? nil : Time.iso8601(stamp)
    end
  end
end
