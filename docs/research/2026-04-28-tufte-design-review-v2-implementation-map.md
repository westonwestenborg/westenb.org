---
date: 2026-04-28T23:57:03Z
topic: "Mapping Claude Design 'Design review v2' recommendations to the current westenb.org Jekyll implementation"
git_commit: a38d78163065d638484ac55d349ec2d3120a3b63
branch: main
repository: westenb.org
tags: [research, design-review, tufte, jekyll, layouts, css, ia]
status: complete
---

# Research: Tufte Design Review v2 — current state map

**Date**: 2026-04-28T23:57:03Z
**Git Commit**: a38d78163065d638484ac55d349ec2d3120a3b63
**Branch**: main
**Repository**: westenb.org

## Research Question

Claude Design produced a `Design review v2.html` (Tufte revision) handoff bundle. The review's six sections recommend dropping the current custom theme in favor of `tufte.css` + ETBook, rebuilding the homepage and archive for scale, and reworking the post-page chrome. **Where in the current codebase does each recommendation land?** This document inventories the current implementation only — it does not propose how to make the changes.

## Summary

The site is a Jekyll 4.3.4 build with two custom plugins (`_plugins/sidenote.rb`, `_plugins/tag_generator.rb`), `jekyll-paginate`, and `jekyll-feed`. **All visual styling is concentrated in one place**: `_layouts/default.html:7-448` holds ~440 lines of inline CSS labeled "Basic Tufte-inspired styles." Other layouts (`post.html`, `page.html`, `tag.html`) are minimal Liquid wrappers with no styling of their own. There is no external production stylesheet — `assets/css/main.css` is a 53-byte stub and `assets/css/tufte.css` is unlinked reference material (per `CLAUDE.md`). No `et-book` font files are present anywhere under `assets/`.

The two largest deltas between the design review and the current site are **structural, not stylistic**. (1) The design review wants flat URLs (`/koa-peat/`); the current `_config.yml:9` produces `/:year/:month/:day/:title/`. (2) The design review wants a homepage with a "newthought" intro + 8–10 Recent posts + handoff to `/archive/`; the current `index.html` is a 15-per-page paginated `post-preview` feed with no bio block. The post-page recommendations are mostly already half-implemented: the `{% sidenote %}` and `{% marginnote %}` Liquid tags exist and are used in six posts, but the rendered markup uses a `<sup>` + `<span>` pattern rather than tufte.css's `<label class="margin-toggle">` + checkbox pattern, so the mobile tap-to-toggle behavior the review assumes "for free" does not work.

One **discrepancy worth flagging**: the design review's "BEFORE" mock for the homepage and post page renders titles in `#0645ad` link-blue with underlined H2s. The current `_layouts/default.html:64-72` styles links as `color:#111` with a 1px `#777` underline; there is no link-blue anywhere in the codebase. Likewise the review describes "inline yellow-highlighted source notes" on the post page, but a grep across `_posts/`, `_layouts/`, and `_includes/` for yellow backgrounds finds none on sidenotes — the only yellow-ish style is `.key-finding { background:#faf6f0 }` inside `_posts/2026-04-11-koa-peat.md`. The reviewer worked from rendered text, not screenshots; their reconstructed "BEFORE" appearance is not pixel-accurate to the live site.

## Detailed Findings

### Design recommendation 1 — Foundation (tufte.css + ETBook)

> "Drop in tufte.css and the et-book font directory, structure each post as `<article> > <section>`, and stop there. Don't override the type. Don't add a custom navigation chrome."

**Files to change**:

- `_layouts/default.html:7-448` — the entire `<style>` block (~440 lines). Currently defines body, headings, links, paragraphs, blockquotes, epigraph, hr, code, header/nav, sidenotes, post-preview, post-meta, post-tags, post-list, footer, tag pages, tags cloud, archive styling, profile-image, and a 1160px responsive breakpoint. All of this is the "custom theme" the review proposes removing.
- `_layouts/default.html:7,9-447` — `<style>...</style>` is inline; there is no external CSS link tag. Switching to `tufte.css` requires either inlining its contents or adding a `<link rel="stylesheet" href="…tufte.css">` and serving the et-book font directory.
- `assets/css/tufte.css` (236 lines) — already in the repo as reference, **but unlinked**. References font files at relative paths like `et-book/et-book-roman-line-figures/et-book-roman-line-figures.woff` (lines 5-6, 14-15, 23-24).
- `assets/css/` — contains only `tufte.css` and `main.css`. **No `et-book/` subdirectory**; the font files tufte.css points at do not exist in the repo. `find assets -name "et-book*" -o -iname "*.woff*" -o -iname "*.ttf"` returns nothing.
- `assets/css/main.css` — 3-line stub with front matter and a comment "Main style is in-lined in default.html." Effectively unused.
- `_layouts/default.html:451-470` — `<body>` has `<header><nav class="nav-main">` then `<main>{{ content }}</main>` then `<footer>`. **No `<article>` wrapper at the body level**. The `<article>` element is added per-page inside `_layouts/post.html:4`, `_layouts/page.html:4`, `_layouts/tag.html:5`, `archive.html:7`, and `tags.html:7`. None of these use `<section>` children.
- `CLAUDE.md:24-37` — documents the inline-CSS pattern explicitly: "All CSS is inline here (Tufte-inspired, ~350 lines). No external stylesheets are used in production." and "`assets/css/tufte.css` exists as reference material but is not used in production."

### Design recommendation 2 — Homepage at scale

> "Two-line intro under the masthead… show 'Recent' on the homepage, not 'Everything'… cap at 8–10 with a clear handoff to `/archive/`."

**Files to change**:

- `index.html:1-33` — entire file. Front matter `layout: default, title: Home`. Body iterates `paginator.posts` rendering each as `<article class="post-preview">` containing `h2 > a` + post-meta time + `<div class="post-excerpt"><p>{{ post.excerpt | strip_html }}</p></div>`. Lines 20-32 render Previous/Next pagination links when `paginator.total_pages > 1`. **No bio/intro block. No "Recent" framing. No handoff link.**
- `_config.yml:11-12` — `paginate: 15` and `paginate_path: "/page:num/"`. Drives the homepage feed. The review wants no pagination at all (recommendation 6); for the homepage specifically, the proposed design uses a fixed top-N slice instead.
- `_config.yml:43-45` — `plugins: - jekyll-paginate`. Required by the current `index.html` `paginator` variable; would be unused if pagination is dropped.
- `about.md:1-11` — current bio source. Front matter `layout: page, title: About, permalink: /about/`. The review's proposed homepage intro uses a condensed form of this copy: "Builder & co-founder of allUP. From Tucson, living near Portland with my wife and our dog Mole." That sentence is currently rendered only on `/about/`, not on `/`.
- `_layouts/default.html:244-264` — defines `.post-preview`, `.post-meta`, `.post-tags`, `.post-tag` styles for the homepage feed. Would be replaced by the review's "newthought" opener + 88px-mono-date / title / 110px-italic-kind grid.
- `_layouts/default.html:451-460` — `<header><nav>` with logo + About + Projects + Archive. The review's homepage mock uses `Home · Archive · Projects · About` (different order) with the current page underlined.
- Post excerpts: 6 posts have `excerpt:` front matter (`2025-12-07-…ats.md:6`, `2026-02-19-…picks.md:6`, `2026-03-21-…numbers.md:6`, `2026-04-11-koa-peat.md:6`, `2026-04-15-…engineering.md:6`, `2026-04-25-winning-is-noise.md:6`). The review's proposed feed shows **no excerpts** — title + date + kind only — so the excerpt fields would become unused on the homepage.

### Design recommendation 3 — Archive at scale

> "One page, grouped by year, scannable at 200+ posts… date in mono ISO format on the left, title in middle, kind italic on the right. Add a client-side title search."

**Files to change**:

- `archive.html:1-24` — entire file. Already does year grouping via `group_by_exp:"post", "post.date | date: '%Y'"`. Renders `<h2 class="archive-year">{{ year.name }}</h2>` (line 13) and a `<ul class="post-list">` with one `<li>` per post containing `<span class="post-date">{{ post.date | date: "%b %-d" }}</span>` (line 15) + `<a class="post-link">` (line 16).
  - Current date format `"%b %-d"` ("Apr 11") vs. review's mono `"04·11"` (line 484 in `Design review v2.html`).
  - **No "kind" label** — there is no `kind` field in post front matter today and no template rendering of one.
  - **No search input** — the page is purely templated, no JS.
- `_layouts/default.html:375-403` — defines `.archive-year`, `.archive ul.post-list`, `.archive ul.post-list li`, `.archive ul.post-list a`, `.post-date`. These styles target the archive markup.
- `_posts/*.md` front matter — 8 posts, none have a `kind:` field. Current tags are: `[basketball, nba, nil, data, sports-economics]` (koa-peat), `[hiring, ai]` (DDoS), `[criterion, film]` (criterion-closet-picks), `[coati, ios]` (coati), etc. The review proposes one of three kinds — Post / Project / Guest — orthogonal to tags.

### Design recommendation 4 — Post page (sidenotes, tag location, newthought, fullwidth figures)

> "Convert every inline highlight into a numbered sidenote. Move tags from above the title to the foot of the post. Open with a 'newthought,' not a date. Charts use `.fullwidth` figures."

**Files to change**:

- `_layouts/post.html:1-22` — entire layout.
  - Lines 7-13: tags block rendered **above** the date metadata, immediately under H1. Each tag is an `<a class="post-tag">` linking to `/tags/{tag-slug}/`. The review wants this moved to the foot of the post in italic body color ("Posts in *basketball*, *nba*, …").
  - Lines 15-17: date in "April 11, 2026" format. The review wants mono ISO "2026 · 04 · 11."
  - Line 19: `<div class="post-content">{{ content }}</div>` — content is rendered as a flat block. The review's proposed structure uses a 2-column grid (`twocol`) where sidenotes flow in a right rail; tufte.css achieves this without an explicit grid by floating sidenotes into the right margin.
  - **No newthought rendering**. The review proposes wrapping the first 2-3 words of every post in `<span class="newthought">` (small-caps lead-in). Today this would have to be authored manually inside each Markdown file.
- `_plugins/sidenote.rb:1-34` — `{% sidenote ID text %}` and `{% marginnote text %}` Liquid tags **already exist**. Render as `<sup class='sidenote-number'></sup><span class='sidenote'>...</span>` (line 16) and `<span class='marginnote'>...</span>` (line 28).
  - **The output markup differs from tufte.css's expected pattern.** Tufte CSS uses `<label for="sn-1" class="margin-toggle sidenote-number"></label><input type="checkbox" id="sn-1" class="margin-toggle"/><span class="sidenote">…</span>` (visible in the design review v2 HTML lines 309, 339). Adopting tufte.css verbatim — and getting the mobile tap-to-toggle behavior the review treats as "for free" — would require either rewriting `sidenote.rb` to emit the label/checkbox pattern, or accepting that the current floating-sup pattern stays and the mobile breakpoint is custom (it currently is — `_layouts/default.html:414-447` collapses sidenotes to inline blocks at 1160px).
- `_layouts/default.html:206-242` — current sidenote/marginnote CSS (float right, `margin-right:-60%`, `width:50%`, color `#555`, counter `sidenote-counter`, `:after`/`:before` for numbered superscripts).
- `_layouts/default.html:414-447` — responsive breakpoint at 1160px that collapses sidenotes to inline italic blocks with dotted borders.
- Posts already using sidenote/marginnote tags (6 of 8 posts):
  - `_posts/2026-04-11-koa-peat.md:60,68,79,96,104,106,112` — 8 sidenotes
  - `_posts/2026-04-25-winning-is-noise.md:66,95,190` — 3+ sidenotes
  - `_posts/2026-03-21-criterion-closet-by-the-numbers.md:56,89,198,204,272,305` — 6 sidenotes/marginnotes
  - `_posts/2026-02-19-criterion-closet-picks.md:23` — 1 sidenote
  - `_posts/2026-01-22-coati.md:23` — 1 sidenote
  - `_posts/2025-03-01-building-this-blog.md:40,71` — 1 sidenote, 1 marginnote
- Posts with **inline `<style>` blocks** (per-post CSS, charts, tables, calculator):
  - `_posts/2026-04-11-koa-peat.md:9` — opens a `<style>` block defining `.chart-container`, `figure`, `.key-finding` (border-left `#c23b22`, background `#faf6f0`), `table`, `.controls`, etc. ~544+ lines. Includes a D3-driven interactive calculator.
  - `_posts/2026-04-25-winning-is-noise.md:9` — opens a `<style>` block.
  - `_posts/2026-03-21-criterion-closet-by-the-numbers.md:9` — opens a `<style>` block. Line 93 has an inline `style="color:#c23b22;"` in a figcaption.
- "Inline yellow highlight" claim (recommendation 4 wireframe). A grep for `background-color: #ff*` and yellow-ish hex codes across `_posts/`, `_layouts/`, `_includes/` returns **only** `_layouts/default.html:23` (`background-color: #fffff8;` — the off-white paper). **No yellow highlight on sidenotes exists in the live code.** The closest match is `.key-finding { background:#faf6f0 }` in `_posts/2026-04-11-koa-peat.md:18` — a faint cream callout with a red border, not yellow. The design review's BEFORE mock (`Design review v2.html:196-197`) renders `.quote { background:#ffeaa7; padding:0 2px }` as its own reconstruction, not a capture of the live site.
- Charts in posts. `_posts/2026-04-11-koa-peat.md:70-149` wraps charts in `<figure>` + `<div class="chart-container">`. The review proposes `<figure class="fullwidth">` + `<span class="marginnote">` for captions. The `.fullwidth` class is part of tufte.css (currently unused), and no figure in the current posts uses it.

### Design recommendation 5 — Type system

> "ETBook + JetBrains Mono. One accent color (Arizona red, `#A8332B`), reserved for chrome only — active nav, sidenote numbers, section rules. Inside body copy: ink, paper, underlines."

**Files to change**:

- `_layouts/default.html:22` — body `font-family: Palatino, "Palatino Linotype", "Palatino LT STD", "Book Antiqua", Georgia, serif;`. The review wants `et-book, Palatino, "Palatino Linotype", "Palatino LT STD", "Book Antiqua", Georgia, serif` (which is what `assets/css/tufte.css:40` already declares — but tufte.css is unlinked).
- `_layouts/default.html:23-24` — `background-color: #fffff8; color: #111;` already matches the review's paper / ink. **No accent color is defined anywhere in the current CSS** — the proposed `#A8332B` Arizona red is net-new.
- `_layouts/default.html:62-72` — link styling (`color:#111`, `border-bottom:1px solid #777`, hover `#777`). Already body-color underlines; matches the review's prescription. **No link-blue exists**, contradicting the review's BEFORE mock.
- `_layouts/default.html:142-157` — code block styling uses `Consolas, "Liberation Mono", Menlo, Courier, monospace`. The review wants `JetBrains Mono` for dates, kickers, and code, with `font-variant-numeric: tabular-nums` for date columns. Neither JetBrains Mono nor `tabular-nums` appears in the current CSS.
- Date formatting in templates uses `date: "%B %-d, %Y"` (long form: "April 11, 2026") at:
  - `_layouts/post.html:16` (post date)
  - `index.html:11` (homepage feed)
  - `tags.html:26` (tag-page list)
- Date formatting `date: "%b %-d"` (short: "Apr 11"):
  - `archive.html:17`
  - `_layouts/tag.html:15`
- The review wants ISO mono `"2026 · 04 · 11"` (display) and `"04·11"` (in dense lists). All five locations would need format changes.

### Design recommendation 6 — Information architecture

> "Drop dates from URLs (`/koa-peat/`). No pagination. Tags index at `/tags/` with counts. RSS + email signup in footer."

**Files to change**:

- `_config.yml:9` — `permalink: /:year/:month/:day/:title/`. The review wants `/:title/` (or equivalent flat slug), with 301 redirects from old paths. **8 existing posts have URLs derived from this template**; flattening would change every public URL.
- `_config.yml:11-12` — `paginate: 15`, `paginate_path: "/page:num/"`. Used only by `index.html`'s `paginator.posts` (lines 7, 20-32). Removing pagination means dropping these keys, removing the `jekyll-paginate` plugin (line 44), and rewriting `index.html` to slice `site.posts` directly.
- `tags.html:1-34` — already exists at `/tags/`. Renders a tag cloud (lines 11-17, sorted alphabetically with counts) **and** a per-tag posts index (lines 19-33). Front matter uses `permalink: /tags/`. The review's IA tree (`Design review v2.html:526`) calls for "/tags/ — alphabetical index w/ counts" — **the cloud at the top already satisfies this**; the per-tag-section block below is additional and could stay or go.
- `_plugins/tag_generator.rb:1-27` — generates one `/tags/{slug}/` page per unique tag using `_layouts/tag.html`. Already aligned with the review's IA proposal.
- `_layouts/tag.html:1-22` — per-tag page. Groups posts by year with `archive-year` H2s and the same `post-date` + `post-link` pattern as `archive.html`. No "kind" label.
- `_includes/tag-generator.html` — appears to be dead code. The "include" body has a broken `{% assign %}` (line 9 has an empty left operand: `{% assign tag_path = | append: '/tags/' | ... %}`). It is **not** referenced from any layout (`grep -rn "tag-generator" _layouts _includes` returns only the file itself). The actual tag-page generation runs through `_plugins/tag_generator.rb`.
- `_config.yml:44` — `jekyll-feed` plugin enabled. Generates `/feed.xml` automatically (Jekyll convention). **No link to it is rendered in any layout.** The review wants "RSS · Email" in the footer.
- `_layouts/default.html:466-470` — current footer. Single `<p>` with copyright span only. No RSS link, no email signup form.
- Email signup: not implemented. Would require a new field/component and a backend (Buttondown, Substack, ConvertKit, mailto:, etc.) — none are wired up today.

## Code References

- `_config.yml:9` — `permalink: /:year/:month/:day/:title/` (current; review wants flat slugs)
- `_config.yml:11-12` — pagination config (review wants none)
- `_config.yml:43-45` — plugins list (`jekyll-paginate`, `jekyll-feed`)
- `_layouts/default.html:7-448` — entire inline `<style>` block (the "custom theme" the review proposes replacing)
- `_layouts/default.html:22-27` — body font/color/bg
- `_layouts/default.html:62-72` — link styling (already body-color underlines)
- `_layouts/default.html:206-242` — sidenote/marginnote CSS
- `_layouts/default.html:244-264` — post-preview / post-meta / post-tags styles
- `_layouts/default.html:375-403` — archive page styles
- `_layouts/default.html:414-447` — 1160px responsive breakpoint (collapses sidenotes inline)
- `_layouts/default.html:451-460` — header nav (Home logo, About, Projects, Archive)
- `_layouts/default.html:466-470` — footer (copyright only; no RSS/email)
- `_layouts/post.html:7-13` — tags rendered above title (review wants foot)
- `_layouts/post.html:15-17` — date in "April 11, 2026" format (review wants ISO mono)
- `_layouts/page.html:1-9` — minimal page wrapper
- `_layouts/tag.html:1-22` — per-tag page wrapper
- `index.html:1-33` — paginated homepage feed (review wants intro + Recent + handoff)
- `archive.html:1-24` — year-grouped post list (review wants ISO dates + kind + search)
- `tags.html:1-34` — tag cloud + per-tag sections
- `about.md:1-11` — bio content (review wants its first sentence on homepage)
- `_plugins/sidenote.rb:1-34` — Liquid tags emit `<sup>`+`<span>`, not tufte.css's label+checkbox pattern
- `_plugins/tag_generator.rb:1-27` — per-tag page generator
- `_includes/tag-generator.html` — appears to be dead code with a broken `{% assign %}`
- `assets/css/tufte.css:1-236` — full tufte.css present, unlinked (per `CLAUDE.md`)
- `assets/css/main.css:1-4` — 3-line stub
- `assets/css/` — **no `et-book/` font directory**; tufte.css's `@font-face` URLs (lines 5-6, 14-15, 23-24) point at files that do not exist
- `_posts/2026-04-11-koa-peat.md:9` — opens a per-post `<style>` block (charts, calculator, `.key-finding` callout)
- `_posts/2026-04-25-winning-is-noise.md:9` — opens a per-post `<style>` block
- `_posts/2026-03-21-criterion-closet-by-the-numbers.md:9` — opens a per-post `<style>` block

## Architecture Documentation (current state)

- **Single-file styling**: 100% of production CSS lives inline in `_layouts/default.html` lines 7-448. `assets/css/main.css` is a 3-line stub; `assets/css/tufte.css` is unlinked reference material. There is no SCSS pipeline, no Sass, no PostCSS — pure Ruby/Jekyll, as documented in `CLAUDE.md`.
- **Layout inheritance**: `default.html` is the base; `post.html`, `page.html`, `tag.html` each declare `layout: default` in their front matter and contribute only Liquid markup, no CSS.
- **Sidenote primitive**: implemented twice — once as a Liquid tag (`_plugins/sidenote.rb`) emitting a `<sup>`+`<span>` pair, and once as CSS in `default.html:206-242` styling those classes with a margin float. Mobile collapse at 1160px is in `default.html:414-447`. Sidenote *numbering* uses CSS counters on `body` (`counter-reset:sidenote-counter` at `default.html:21`) and `.sidenote-number` (`counter-increment` at `default.html:222-223`).
- **Tag pages**: auto-generated by `_plugins/tag_generator.rb` (1 page per unique tag in `site.tags`), all rendered through `_layouts/tag.html`. The aggregate `/tags/` index lives in `tags.html` at the repo root. The unrelated `_includes/tag-generator.html` appears to be a dead earlier attempt and is not referenced by any layout.
- **Permalink scheme**: `/:year/:month/:day/:title/` from `_config.yml:9`. Eight posts exist; URLs are date-prefixed.
- **Pagination**: `index.html` is the only consumer of `jekyll-paginate`; 15 posts per page; pagination paths under `/page:num/`. With 8 posts today, only page 1 exists.
- **Feed**: `jekyll-feed` plugin is enabled, generating `/feed.xml`. No layout references or links to it.
- **Asset organization**: `assets/css/` (mostly empty), `assets/data/` (NBA data, unrelated to design), `assets/images/` (post images, profile.jpeg), `assets/js/` (post JS).
- **Per-post embedded styling**: three of the eight posts (`koa-peat`, `winning-is-noise`, `criterion-closet-by-the-numbers`) contain their own `<style>` blocks for charts, tables, and the Koa Peat interactive calculator. These are post-local and not part of the global theme.

## Open Questions

- **Sidenote markup migration**: tufte.css's mobile tap-to-toggle relies on `<label class="margin-toggle">` + `<input type="checkbox">` siblings. The current `_plugins/sidenote.rb` emits `<sup>`+`<span>` and is used in 6 posts. Migrating means either rewriting the plugin (and its existing call sites still work because the `id` arg is unused per `CLAUDE.md`) or keeping the current pattern and porting tufte.css's mobile collapse to match. Which path the review intends is not spelled out — the review just says "use the markup pattern."
- **"Kind" labels**: the review proposes Post / Project / Guest as a single kind label per post, distinct from tags. There is no `kind:` field in any post front matter today. Whether `Project` posts overlap with `projects.md` (which currently lists 6 projects with mixed external links and post links) is undefined. `_posts/2026-01-22-coati.md` is referenced from both `projects.md:13` and the homepage feed today.
- **URL flattening blast radius**: 8 existing post URLs would change. Backlinks within the corpus include `projects.md:13` linking to `/2026/01/22/coati/` and `_posts/2026-03-21-criterion-closet-by-the-numbers.md:56` linking externally. A flat-slug rollout needs 301s in GitHub Pages (which doesn't natively support redirects without a plugin like `jekyll-redirect-from`).
- **"Inline yellow highlight" referenced in section 04 of the review**: not present in the live code. The review may be reconstructing what it imagined sidenotes looked like; the only yellow-adjacent style is `.key-finding { background:#faf6f0 }` in `_posts/2026-04-11-koa-peat.md`. Whether the review intends `.key-finding` callouts to also become sidenotes is not addressed.
- **Email signup**: not implemented. Provider choice (Buttondown, ConvertKit, Substack, mailto:) is left to the user.
- **Per-post `<style>` blocks** (`koa-peat`, `winning-is-noise`, `criterion-closet-by-the-numbers`) define their own `figure`, `table`, `figcaption`, `.chart-container` rules. Many of those rules will collide with whatever tufte.css supplies, and the review does not address how to reconcile them.
