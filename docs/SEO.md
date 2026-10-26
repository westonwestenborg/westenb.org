# SEO rules for westenb.org

Every page on westenb.org must be easy for search engines to find and understand. CI enforces these rules on every pull request and before every deploy, so a change that breaks them cannot ship. `docs/` is excluded from the Jekyll build, so this file is not published.

## How the site gets its SEO tags

The site is Jekyll 4.3 with three plugins:

- `jekyll-seo-tag` (`{% seo title=false %}` in `_layouts/default.html`) emits the meta description, canonical URL, Open Graph and Twitter tags, and JSON-LD: `BlogPosting` for posts, `WebSite` for the home page, `Person` for about.
- `jekyll-sitemap` writes `/sitemap.xml`. `robots.txt` points to it.
- `jekyll-feed` writes `/feed.xml`.

Don't hand-write any of these tags. Set front matter and let the plugins render them.

Two local plugins also matter:

- `_plugins/tag_generator.rb` builds a page at `/tags/{slug}/` for every tag. Tags with fewer than `tag_index_min_posts` posts get `noindex` and `sitemap: false` (see Tag pages).
- `_plugins/last_modified_at.rb` sets each page's `last_modified_at` from git history (see Sitemap `<lastmod>`).

## What every new page needs

- **Posts** (`_posts/YYYY-MM-DD-slug.md`): `title:` and a one-line `excerpt:` in front matter. The excerpt becomes the meta description, `og:description`, the BlogPosting JSON-LD description, and the summary in `feed.xml` and `llms.txt`. The check fails a post without one, because Jekyll's automatic excerpt (the whole first paragraph) makes a poor description.
- **Pages** (about, projects, anything new): `title:`, `description:` and `permalink:`. A page with no `description:` silently inherits the site description from `_config.yml`, and the check fails it as a duplicate.
- **Unique titles.** `<title>` renders as `{title} — Weston Westenborg`; the home page is just `Weston Westenborg`. No two pages in the sitemap may share one.
- **One `<h1>` per page.** The layouts already render the title as the h1 (`post.html`, `page.html`, `tag.html`; on the home page the masthead brand is the h1). Post and page bodies use `##` and below, never `#`.
- **`alt` on every `<img>`.** In Markdown: `![Koa Peat in Arizona jersey](/assets/images/koa.png)`. Use `alt=""` only for purely decorative images.
- **Pages that should not be indexed** get both `noindex: true` (the default layout then emits `<meta name="robots" content="noindex, follow">`) and `sitemap: false`. The 404 page is the example. One without the other fails the check.

## Tag pages

A tag page with fewer than `tag_index_min_posts` posts (3, set in `_config.yml`) is `noindex, follow` and left out of the sitemap. A tag page with one or two posts is a heading and a link or two, which is thin content. The posts don't need it to be found: every post is linked from the home page or the archive. Once a tag reaches 3 posts, its page becomes indexable and enters the sitemap with no further change. The `/tags/` index stays indexed.

## Sitemap `<lastmod>`

`_plugins/last_modified_at.rb` sets `last_modified_at`, which drives the sitemap's `<lastmod>`, `article:modified_time` and JSON-LD `dateModified`:

- A post gets the later of its date and the last commit that touched its file.
- A page with a source file gets the last commit that touched it. The home page, archive and tags index also move forward when a newer post is published. They don't move when an old post is edited, since their lists don't change.
- A generated tag page gets the date of its newest post.

A `last_modified_at:` in front matter overrides the plugin. Use it when a post changes because of something outside its file, for example new data in `assets/data/` behind the Koa Peat charts.

CI checks out full history (`fetch-depth: 0` in the workflow). On a shallow clone the plugin warns and falls back to post dates. Don't remove `fetch-depth: 0`: every file would then report the latest commit's date, and every deploy would resubmit every page to IndexNow.

## The SEO check (CI gate)

`.github/workflows/deploy-cloudflare.yml` has two jobs:

- **Build and SEO check** runs on every pull request to `main` and every push to `main`. It builds the site and runs `script/seo-check`.
- **Deploy** runs only on push to `main` (or a manual run), and only after the check passes. It deploys the `_site` the check inspected to Cloudflare Pages (project `westenb-org`), then runs the IndexNow step. Merging to `main` deploys to production.

`script/seo-check` reads the built `_site` and fails when:

- a sitemap page is missing its `<title>`, meta description, canonical link or `og:title`, or its canonical isn't its own sitemap URL;
- two sitemap pages share a `<title>` or a meta description;
- an indexable built page is missing from the sitemap, or a `noindex` page is in it;
- a sitemap page has zero or several `<h1>` elements, or an `<img>` without `alt`;
- a post lacks a `<lastmod>`, BlogPosting JSON-LD (headline, datePublished, author), or an `excerpt:`;
- `robots.txt` doesn't point at the sitemap, or the IndexNow key file is missing.

Run it locally before opening a pull request:

```bash
bundle exec jekyll build && bundle exec ruby script/seo-check

# If `bundle` resolves to a stale Ruby, prepend the Homebrew path:
PATH="/opt/homebrew/opt/ruby/bin:$PATH" bundle exec jekyll build && bundle exec ruby script/seo-check
```

It prints one `FAIL` line per problem and exits 1. For example, a page that lost its own description fails like this:

```
FAIL  https://westenb.org/, https://westenb.org/projects/: share a meta description (give each page its own `description:`)
```

Fix the page, not the check. If a check is wrong, change `script/seo-check` in its own commit and say why in the pull request.

## IndexNow

IndexNow is a protocol for telling search engines that a URL is new or changed. One POST to `https://api.indexnow.org/indexnow` reaches Bing, Yandex, Naver, Seznam, Yep and Amazon.

The key is public. It lives in `546cd2b49a7d54a9e63c7e088ed613d8.txt` at the repo root, which is served at `https://westenb.org/546cd2b49a7d54a9e63c7e088ed613d8.txt` and contains only the key. Don't rename or delete it; the SEO check fails without it.

The Deploy job runs `script/indexnow` twice:

1. `snapshot`, before deploying, saves the live `https://westenb.org/sitemap.xml`.
2. `submit`, after deploying, compares that snapshot with the new `_site/sitemap.xml`. In one request, it POSTs every URL that is new or whose `<lastmod>` changed. It sends nothing else, because IndexNow asks sites not to resubmit unchanged URLs. For example, publishing one post sends that post plus the home page, archive and tags index, whose `<lastmod>` moved with it. Editing an old post sends only that post.

If the key file was not live before the deploy, as on the first IndexNow deploy, every sitemap URL is submitted. Every IndexNow failure is a warning and never fails the deploy.

To see what a deploy would send without sending it, save the live sitemap and run the comparison with `--dry-run`:

```bash
mkdir -p .indexnow && curl -sS https://westenb.org/sitemap.xml -o .indexnow/before.xml && echo diff > .indexnow/state
bundle exec jekyll build && ruby script/indexnow submit _site .indexnow --dry-run
```

Never run `submit` without `--dry-run` outside CI.

## Google and Brave

Google and Brave do not use IndexNow. Brave Search has no URL-submission API: its crawler finds pages like any other crawler, and it skips anything Googlebot can't crawl. Its CAPTCHA submit form is for re-fetching or delisting a page, so don't automate it.

For both, the levers are the ones the check enforces:

- an accurate sitemap;
- `robots.txt` pointing at it;
- pages linked from other pages (every post is linked from the archive);
- plain HTML that Googlebot can crawl. Don't put the only copy of a page's text in JavaScript.

`_headers` sends `X-Robots-Tag: noindex` on the `*.pages.dev` hostnames, so only westenb.org is indexed.
