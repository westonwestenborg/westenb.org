---
date: 2026-04-29T16:15:48Z
topic: "Rebuild westenb.org from scratch against Claude Design's 'Design review v2' spec, preserving all existing content"
git_commit: a38d78163065d638484ac55d349ec2d3120a3b63
branch: main
repository: westenb.org
tags: [research, codebase, redesign, tufte, jekyll, layouts, css]
status: complete
---

# Research: rebuilding westenb.org from scratch to match Design Review v2

**Date**: 2026-04-29T16:15:48Z
**Git commit**: `a38d781` (main)
**Branch (working tree)**: `main` (the prior incremental attempt is at `tufte-redesign`, tip `f027e33`)
**Repository**: `westenb.org`
**Inputs read in full**: `docs/handoff/2026-04-29-tufte-rebuild-handoff.md`, the design bundle from `https://api.anthropic.com/v1/design/h/4ODH4ncfr5DN9I3RQQaqKg` (README, `chats/chat1.md`, `project/Design review v2.html`, 761 lines), and every file in the current `main` tree referenced below.

## Research question

> "What would it take to keep all of our content, but rebuild / restyle the site from the ground up to match Claude's design (`Design review v2.html`)?"

This document maps the **current codebase as it exists on `main`** against the **target design**, and inventories the work product on the `tufte-redesign` branch as a reference. Per scope, this is documentation only — the prescriptive parts come from primary sources (the handoff doc and the design HTML's own copy).

## Summary

The current site is a small Jekyll 4.3.4 install with all CSS inlined in one ~470-line `<style>` block in `_layouts/default.html`, two custom plugins (`sidenote.rb` and `tag_generator.rb`), and 8 posts (5 published, 3 untracked). The design target is also single-file CSS — but rebuilt around `tufte.css` 1.8.0 + ETBook + JetBrains Mono, with three distinct layout modes (broadsheet homepage, prose post page, dense list archive/tags). The previous attempt on `tufte-redesign` (10 commits ahead of `main`) imported `tufte.css` verbatim and layered overrides; the handoff doc records that approach as the source of friction and recommends writing layout CSS from scratch while keeping tufte's *primitives* (ETBook, off-white paper `#fffff8`, sidenote markup pattern, no link-blue, "newthought" small-caps opener).

All eight posts of content can be carried over without Markdown edits, *except* that three posts contain ~150-line inline `<style>` blocks (Koa Peat, Criterion Closet by the Numbers, Winning Is Noise) that redefine `figure`, `figcaption`, `table`, and post-specific custom components, and whose accent color (`#c23b22` / `#a8332b`) the design v2 spec restricts to "chrome only — never in body content." The `tufte-redesign` branch already scoped these style blocks to a `.post-{slug}` wrapper as a working compromise; both posts and the wrapper are intact on that branch.

The major structural deltas from `main` to the design are: (1) homepage shifts from a paginated post-preview list to a non-paginated "broadsheet" — masthead + intro + Recent (8–10) + footer; (2) archive shifts from year-grouped `<h2>` + `<ul>` to a 3-column grid (date · title · kind) with dotted dividers, plus a client-side title search; (3) post page gains a mono ISO kicker (`2026 · 04 · 11 · Post`), tags move from above the title to a foot-of-post line, the post body opens with a `<span class="newthought">`; (4) tags page restyles to dense list view; (5) navigation reorders to `Home · Archive · Projects · About` and the brand changes from "westenb.org" to "Weston Westenborg." All Markdown post content stays. The `permalink: /:year/:month/:day/:title/` decision is preserved per the handoff (the design's "drop dates from URLs" recommendation is explicitly out-of-scope per the user).

## Detailed findings

### 1. Current codebase inventory (on `main`, commit `a38d781`)

**Build chain**

- `Gemfile` declares `jekyll`, `jekyll-paginate`, `jekyll-feed`. Locked versions in `Gemfile.lock`.
- `_config.yml:8-12` sets `markdown: kramdown`, `permalink: /:year/:month/:day/:title/`, `paginate: 15`, `paginate_path: "/page:num/"`.
- `_config.yml:13-18` defines a `pages` collection at `/:path/`.
- `_config.yml:19-34` sets layout defaults: posts → `post`, pages → `page`, fallback → `default`.
- `_config.yml:36-40` excludes `ruby`, `vendor`, `Gemfile`, `Gemfile.lock`.
- `_config.yml:43-45` enables `jekyll-paginate` and `jekyll-feed`.
- `.github/workflows/jekyll-gh-pages.yml` (per `CLAUDE.md`) builds with Ruby 3.2 on push to `main` and deploys to GitHub Pages. `CNAME` declares `westenb.org`.

**Layouts** (parent → child inheritance)

- `_layouts/default.html` — base shell. **All production CSS lives here**, ~440 lines of styles in one `<style>` block (`default.html:7-448`). Uses Palatino-stack serif, off-white `#fffff8`, custom inline navigation. Body: `max-width:1400px; padding:0 5%`. Main column: `max-width:650px; padding-right:150px` (the 150px is the sidenote gutter). Responsive breakpoint at 1160px collapses sidenotes inline (`default.html:414-447`).
- `_layouts/post.html` — `<article class="post">` with `<h1>{{ page.title }}</h1>`, then a `.post-tags` paragraph (tags above title), then a `.post-meta` time element, then `<div class="post-content">{{ content }}</div>`.
- `_layouts/page.html` — `<article class="page">` with `<h1>{{ page.title }}</h1>` and `<div class="page-content">{{ content }}</div>`. **No `<section>` wrapper** — relevant to the design v2 spec which uses `<section>` for prose-width constraints.
- `_layouts/tag.html` — `<article class="tag-page">` with `Posts tagged with <em>{{ page.tag }}</em>` heading; iterates `site.tags[page.tag]` grouped by year.

**Top-level pages**

- `index.html` — `<div class="home">` iterates `paginator.posts`, emits `<article class="post-preview">` per post (h2 link + post-meta time + excerpt). Pagination links at bottom (`index.html:20-32`).
- `archive.html` — `permalink: /archive/`. `<article class="archive-page">` with `<h1>Archive</h1>`, then year groups: `<h2 class="archive-year">{{ year }}</h2>` + `<ul class="post-list">` with `<span class="post-date">{{ post.date | date: "%b %-d" }}</span>` + `<a class="post-link">`.
- `tags.html` — `permalink: /tags/`. `<article class="tags-page">` with two sections: `.tags-cloud` (alphabetical tag list with counts) and `.tags-posts` (per-tag year-grouped list).
- `about.md` — `layout: page`, `permalink: /about/`. Includes `![Weston Westenborg](/assets/images/profile.jpeg){:class="profile-image"}` and a 2-paragraph bio.
- `projects.md` — `layout: page`, `permalink: /projects/`. 6 project links, em-dash separators.

**Plugins**

- `_plugins/sidenote.rb` — defines `{% sidenote N text %}` and `{% marginnote text %}` Liquid tags. Current main implementation emits `<sup class='sidenote-number'></sup><span class='sidenote'>...</span>` (`sidenote.rb:14-17`). The `id` parameter is parsed but unused — numbering is via CSS counters on `body { counter-reset: sidenote-counter }` and `.sidenote-number:after { content: counter(sidenote-counter) }` (`default.html:21,221-235`).
- `_plugins/tag_generator.rb` — at build time, gathers all unique post tags and creates `/tags/{slugified-tag}/index.html` pages using the `tag.html` layout. Each generated page sets `data['tag'] = tag` for the layout to consume (`tag_generator.rb:14-26`).

**Includes**

- `_includes/tag-generator.html` — appears to be a non-functional artifact (line 7 has malformed Liquid: `{% assign tag_path = | append: '/tags/' | ... %}`). The handoff doc flags this style of file as a Jekyll-build-breaker if not in `exclude:`. **Not referenced anywhere** in the active layouts. The `tufte-redesign` branch deletes it (commit `05d61cd`).

**Posts** (`_posts/*.md`)

| File | Date | Tags | Inline `<style>` | Untracked? | Approx body lines |
| --- | --- | --- | --- | --- | --- |
| `2025-03-01-building-this-blog.md` | 2025-03-01 | meta, design, jekyll, collaboration | no | tracked | 139 |
| `2025-12-07-denial-of-service-attack-on-the-applicant-tracking-system.md` | 2025-12-07 | hiring, ai, jobs | no | tracked | 17 |
| `2026-01-22-coati.md` | 2026-01-22 | coati, ios, obsidian | no | tracked | 33 |
| `2026-02-19-criterion-closet-picks.md` | 2026-02-19 | criterion, film | no | tracked | 35 |
| `2026-03-21-criterion-closet-by-the-numbers.md` | 2026-03-21 | criterion, film, data | **yes** (~150 lines, prefixed `.post-criterion-closet-by-the-numbers`) | **untracked** | 845 |
| `2026-04-11-koa-peat.md` | 2026-04-11 | basketball, nba, nil, data, sports-economics | **yes** (unscoped on main; scoped to `.post-koa-peat` on `tufte-redesign`) | tracked | 574 |
| `2026-04-15-code-driven-prompt-engineering.md` | 2026-04-15 | ai, engineering, llm, prompts, evals | no, but uses `<span class="newthought">` and `kind: Post` front matter | **untracked** | 85 |
| `2026-04-25-winning-is-noise.md` | 2026-04-25 | basketball, nba, data, march-madness | **yes** (~150 lines, prefixed `.post-winning-is-noise`) | **untracked** | 530 |

The unscoped Koa Peat `<style>` (`koa-peat.md:9-` of file) defines `.chart-container`, `figure`, `figcaption`, `.key-finding` (a `border-left: 3px solid #c23b22; background: #faf6f0` callout), `#player-detail`, range slider styles, `.verdict-negative`. The handoff doc (handoff §6) lists three approaches considered for these blocks (scope-and-keep, audit-and-strip, per-post CSS files); `tufte-redesign` chose scope-and-keep.

The `kind: Post` front-matter key appears on three of the eight posts (criterion-closet-by-the-numbers, code-driven-prompt-engineering, winning-is-noise). The design v2 spec uses three values: `Post`, `Project`, `Guest`. None of the layouts on `main` consume `page.kind`.

The `<span class="newthought">` opener appears in only one post (code-driven-prompt-engineering.md:9). The design v2 spec wants this on the first 2–3 words of every post's opening paragraph (Issue 3 in section 04 of the spec).

**Assets**

- `assets/css/main.css` — exists (size unknown, not loaded by `default.html`).
- `assets/css/tufte.css` — 235 lines on `main`, **not loaded** anywhere. CLAUDE.md notes "exists as reference material but is not used in production." On `tufte-redesign` it grows to 486 lines (the actual upstream tufte.css 1.8.0).
- `assets/data/nba-players.json` — modified in working tree (untracked changes), used by Koa Peat post.
- `assets/images/` — `profile.jpeg`, plus untracked `dybantsa.jpg` and `karaban.jpg` (likely for Winning Is Noise).
- `assets/js/` — directory exists; contents not surveyed.

**Working-tree state when this research was conducted**

- HEAD: `a38d781` on `main` (the system's git status header listed `tufte-redesign` but `git branch --show-current` reports `main`; the branch had been switched).
- Modified: `assets/data/nba-players.json`.
- Untracked: `.bundle/`, `_posts/2026-03-21-criterion-closet-by-the-numbers.md`, `_posts/2026-04-15-code-driven-prompt-engineering.md`, `_posts/2026-04-25-winning-is-noise.md`, `assets/images/dybantsa.jpg`, `assets/images/karaban.jpg`, `docs/`, `ruby/`.

### 2. Design Review v2 — what the target says, in full

The full design HTML is 761 lines, served from a Claude Design bundle with this structure:

```
westenb-org/
  README.md
  chats/chat1.md          (the design conversation transcript; 156 lines)
  project/
    Design review v2.html  (761 lines — the primary spec)
    Design review.html     (678 lines — superseded v1)
    probe.html
    uploads/...
```

The README's instruction is explicit: "**Read `westenb-org/project/Design review v2.html` in full.** … **Don't render these files in a browser or take screenshots.** Everything you need — dimensions, colors, layout rules — is spelled out in the source. Read the HTML and CSS directly." The chat transcript records the user's three constraints that v2 was rewritten to honor:

1. "I am heavily influenced by Edward Tufte, and I would like to use tufte.css as defaults whenever possible."
2. "I do plan to add many more posts."
3. "I wouldn't have a tool category, just projects. … *Posts*, not *essays*. … Don't like estimated reading times either."

#### 2.1 Design tokens (CSS custom properties, lines 11-21 of v2)

```css
--bg:        #fffff8;   /* tufte's signature off-white */
--ink:       #111;
--ink-soft:  #5b5750;
--rule:      #cfc8b8;
--rule-soft: #e6dfcc;
--accent:    #a8332b;   /* muted Arizona red — chrome only, never in body */
--good:      #3d6b3a;
--warn:      #a45a1f;
--mono:      "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
```

Body type: ETBook (via `@font-face`, files at `assets/css/et-book/...`) with Palatino, Georgia, serif fallback. Mono: JetBrains Mono. **No sans** (the design's typespec explicitly rejects Gill Sans / Tufte sans for licensing and pairing reasons, line 649).

#### 2.2 Page geometry

- `.page` wrapper: `max-width:1400px; margin:0 4vw; padding-left:0`. At ≥1500px, `margin-left:8vw`. At ≤760px, `margin:0 1.4rem`. (lines 65-67)
- `.col` (prose column): `width:55%; max-width:780px`. At ≤760px, `width:90%`. (lines 70-71)
- `.wide`: `width:90%; max-width:1280px` — used for masthead, scorecard, section heads, panes, etc.
- `article { padding:5rem 0 8rem }` and `article > section { width:100%; max-width:none; padding:0 }` — important: the design explicitly *resets* tufte's section width.

#### 2.3 Three layout modes documented in the spec

##### A. Broadsheet homepage (`.mock-after`, lines 134-152, 422-441)

```
top:        flex; baseline; justify-content:space-between
            border-bottom: 1px solid var(--ink); padding 18px 22px 14px
brand:      ETBook 24px (the literal text "Weston Westenborg")
nav:        flex gap:20px; ETBook italic 15px; current item has
            border-bottom 1px solid #111
intro:      ETBook 1.05rem/1.5; max-width 55ch; <newthought> opener
            "Builder & co-founder of allUP. From Tucson, ..."
yr:         "Recent" mono kicker 11px, uppercase, .16em letter-spacing,
            with ::after content:""; flex:1; height:1px;
            background:var(--rule)  ← horizontal rule extending right
feed:       grid-template-columns: 88px 1fr 110px;
            (date  ·  title  ·  kind), border-top 1px dotted var(--rule)
post.date:  JetBrains Mono 11px, font-variant-numeric: tabular-nums
            "2026·04·11"  (interpunct, not slash)
post h4:    ETBook 1.15rem/1.25, weight 400, links black + transparent border
post.kind:  ETBook italic 0.95rem, color var(--ink-soft), text-align:right
            (values: Post / Project / Guest)
foot:       border-top 1px solid var(--ink); flex space-between;
            ETBook italic; left "Read everything →", right "RSS · Email"
```

##### B. Prose post page (`.wire-after`, lines 198-208, 580-601)

```
crumbs:     italic 0.95rem; "← Archive"
h2:         ETBook 2rem/1.05; weight 400; font-style:normal
date:       JetBrains Mono 11px; ink-soft; .06em letter-spacing
            (e.g. "2026 · 04 · 11" — interpunct separators)
twocol:     grid 1fr / 30%  (body column + sidenote rail)
body p:     ETBook 1rem/1.55; max-width: 55ch
newthought: small-caps 1.1em on first 2-3 words of opening para
side:       0.85rem/1.45; ink-soft; padding-left .7rem;
            border-left 1px solid var(--rule); italic
            <b> labels: mono 9.5px uppercase, accent color
sup:        accent color (sidenote number marker)
outro:      margin-top 1.2rem; border-top 1px solid var(--rule); italic
            "— posts in *basketball*, *nba*, … · sources at the foot"
```

The mock uses an ad-hoc `.side`/`<sup>` markup, but Issue 1 (line 605-609) is explicit that the production conversion should use **tufte.css's canonical sidenote pattern**: `<label class="margin-toggle sidenote-number">` + `<input type="checkbox" class="margin-toggle"/>` + `<span class="sidenote">`. The handoff doc (§5) confirms this pattern is required for tufte's mobile collapse rule (`@media (max-width:760px) { .margin-toggle:checked + .sidenote }`) — the `<input>` MUST immediately precede the `<span>` because the rule uses an adjacent-sibling combinator.

##### C. Dense list archive (`.denspane`, lines 254-261, 481-494)

```
yr:    JetBrains Mono 11px, uppercase, .16em letter-spacing, ink-soft
       (year header, e.g. "2026")
row:   grid-template-columns: 74px 1fr 100px; gap 10px
       (date  ·  title  ·  kind)
       padding .35rem .9rem
       border-bottom: 1px dotted var(--rule-soft)
.d:    JetBrains Mono 10.5px; ink-soft; tabular-nums
       (e.g. "04·11")
.t:    ETBook (inherits); body color
.k:    ETBook italic; #666; .9rem; text-align:right
```

Plus a client-side title-search input above (called out at line 501: "A single search input at the top — client-side, plain JS over titles + tags").

#### 2.4 Section IA / nav decisions

The design's IA tree (lines 510-528) compares "Today" vs. "Proposed":

| Today | Proposed |
| --- | --- |
| `/` — all 5 posts | `/` — intro + 8–10 recent |
| `/about/` — bio | `/archive/` — full list, by year, with search |
| `/projects/` — overlaps `/` | `/projects/` — Coati, Criterion DB, NIL model — own page each |
| `/archive/` — overlaps `/` | `/about/` — keep as-is |
| `/yyyy/mm/dd/<slug>/` — heavy URL | `/tags/` — alphabetical index w/ counts |
|  | `/<slug>/` — flat URLs; redirect old date paths |

The handoff doc explicitly notes that **URL flattening is out-of-scope** — the user wants `permalink: /:year/:month/:day/:title/` retained.

The "checks" panel (lines 533-549) gives three direct calls:

- **Date in URL?** — "Drop it" *(out-of-scope per user)*.
- **Pagination?** — "Don't. One archive page is faster, fully searchable in-browser, and prints."
- **RSS / email?** — "Both, in the footer."

#### 2.5 Accent color discipline (line 689)

> "**One color rule.** The Arizona red appears in three places, total: the active nav indicator, the sidenote number, and the rule under section headings on the homepage and archive. Inside the body of any post, links are body-color underlines. *That's it.* Resist all temptation to colorize callouts, headers, or quote bars in body content."

The handoff doc (§7) flags this as a real conflict: existing posts use accent in `.key-finding` callouts, `#player-detail` panels, range slider accents, `.verdict-negative` text. The previous attempt's pragmatic resolution was to harmonize the in-post hex (`#c23b22` → `#a8332b`) rather than refactor the callouts to ink-only.

#### 2.6 Priority list from the design (the "where to start" punch list, lines 699-749)

The design ranks the work from highest to lowest impact:

1. **Drop in tufte.css + et-book; restructure pages as `article > section`.** Effort: half wknd. Impact: huge.
2. **Convert inline highlight footnotes to sidenotes.** Effort: 2–4 hrs. Impact: huge.
3. **Build the homepage as intro + Recent (8–10).** Effort: 1 hr. Impact: big.
4. **Build the archive page — one list, by year.** Effort: half wknd. Impact: big at scale.
5. **Flatten URLs (no dates) and add 301 redirects.** *(out-of-scope per user)*.
6. **Tags index page + RSS / email in footer.** Effort: 2 hrs. Impact: big over time.

### 3. The `tufte-redesign` branch — what was tried, as reference

`git diff --stat main..tufte-redesign` shows 39+ files changed. Tip is `f027e33`, 10 commits ahead of `main`. Key commits, in order:

- `5f91a88` — Scope per-post style blocks to post slug (the `.post-{slug}` wrapper convention).
- `bd3fdab` — Adopt tufte.css 1.8.0 + self-hosted ETBook and JetBrains Mono.
- `b07d528` — Migrate sidenote plugin to tufte.css canonical markup.
- `110e129` — Rework post page chrome — kicker, kind, newthought, tags-at-foot.
- `ff554de` — Rebuild homepage and archive for scale.
- `05d61cd` — Sync tags pages, add RSS link, reorder nav, drop dead include.
- `fd7c5b7` — Fix masthead — serif brand, italic nav, no underline bleed.
- `8d53624` — Fix column width and stacking padding on non-post pages.
- `f027e33` — Rebuild homepage as full-width broadsheet, add right gutter to body.

Files added on `tufte-redesign` (binary asset paths, kept verbatim from a fresh rebuild perspective):

- `assets/css/et-book/et-book-bold-line-figures/{eot,svg,ttf,woff}`
- `assets/css/et-book/et-book-display-italic-old-style-figures/{eot,svg,ttf,woff}`
- `assets/css/et-book/et-book-roman-line-figures/{eot,svg,ttf,woff}`
- `assets/css/et-book/et-book-roman-old-style-figures/{eot,svg,ttf,woff}`
- `assets/css/et-book/et-book-semi-bold-old-style-figures/{eot,svg,ttf,woff}`
- `assets/fonts/jetbrains-mono/JetBrainsMono-Regular.woff2`
- `assets/fonts/jetbrains-mono/JetBrainsMono-Medium.woff2`

The branch's `_layouts/default.html` is 437 lines (vs. `main`'s 471) and `assets/css/tufte.css` is 486 lines (vs. `main`'s 235 — the 235 was reference material; the 486 is the actual upstream `tufte.css` 1.8.0 plus localized font URLs).

The handoff doc (`docs/handoff/2026-04-29-tufte-rebuild-handoff.md`, 186 lines) is the comprehensive post-mortem. Its top-level recommendation is direct: "**Don't adopt tufte.css 1.8.0 verbatim and try to layer overrides on top.** … The cleanest path is: take the *ideas* from tufte (ETBook, off-white `#fffff8` paper, sidenote markup pattern, no link-blue) and write your own CSS for everything else."

The handoff also lists nine concrete gotchas, in order of "how much time they ate":

1. Tufte 1.8.0's column rule is `section > p { width: 55% }`, not `p { width: 55% }` — element-tree-dependent.
2. Body geometry has no right gutter (`width:87.5%; padding-left:12.5%; padding-right:0`), so anything full-width clips right.
3. Tufte's `a:link` underline is a `background-image` gradient that bleeds into brand text, nav links, footer.
4. `article { padding: 5rem 0 }` + `h1 { margin-top: 4rem }` stack to ~135px of empty space before first content.
5. Sidenote markup MUST be `<label>` + `<input>` + `<span>` adjacent-sibling for mobile collapse to work.
6. Per-post `<style>` blocks need scoping — the branch chose `.post-{slug}` wrappers.
7. Accent color discipline conflicts with existing posts (resolved by harmonizing hex, not refactoring).
8. `_config.yml` doesn't auto-reload — restart server after config edits.
9. `.md` files in `docs/` get processed as Liquid templates and crash the build — must be in both `exclude:` and `.gitignore`.

### 4. Content → design mapping

This table maps every existing piece of content to where it lands in the design v2 system. **All Markdown content carries over without edits**; only chrome, layout, and scoping change.

| Current artifact | Where in design v2 | Notes on what changes |
| --- | --- | --- |
| `_layouts/default.html` (~470 lines inline CSS, Palatino, custom nav) | Single `<style>` block in default.html, ETBook + JetBrains Mono, design v2 tokens. Handoff §"What I'd do differently" estimates ~400 lines. | Full rewrite of CSS. Body geometry written from scratch (not tufte's `width:87.5%; padding-left:12.5%`). Nav reordered to `Home · Archive · Projects · About`. Brand text: "Weston Westenborg" (not "westenb.org"). |
| `_layouts/post.html` (h1 → tags-line → date → content) | `<article class="post">` with mono ISO kicker (`2026 · 04 · 11 · Post`) → h1 → content → outro with tags-at-foot italic line + "← Archive" mono back-link | Order changes: kicker before h1, tags move from above content to below content. New: `kind` displayed in kicker. New: outro section. |
| `_layouts/page.html` (no `<section>` wrapper) | `<article class="page"><section>...</section></article>` | The `<section>` wrapper matters for whatever column-width rule you scope. (handoff §1) |
| `_layouts/tag.html` (year groups, `<h2 class="archive-year">` + `<ul>`) | Dense list mode (`.denspane` style): year header in mono uppercase + grid rows (date 74px · title 1fr · kind 100px) | Visual overhaul; logic the same. |
| `index.html` (paginator.posts iter → `<article class="post-preview">` w/ excerpts; pagination links) | Broadsheet: masthead → intro paragraph → "Recent" kicker w/ horizontal rule → 8-10 most-recent posts in 3-col grid → footer | Full rewrite. Pagination removed. Excerpts removed (only title + date + kind on home). Per design's "Recent" cap of 8–10, then "Read everything →" handoff to `/archive/`. Drop `jekyll-paginate` from Gemfile and plugins list. |
| `archive.html` (year groups + `<ul>` of `<span class="post-date"> + <a>`) | Same structure but rendered in dense-list grid (date 74px · title 1fr · kind 100px) + client-side title search input at top | Add `<input>` + ~30 lines of vanilla JS to filter `.row` elements by `.t` text content. Date format becomes mono ISO (`04·11`). Add `kind` column reading `page.kind` from front matter. |
| `tags.html` (`.tags-cloud` + `.tags-posts` per-tag year groups) | Alphabetical index with counts at top; per-tag dense lists below | Visual overhaul; logic the same. |
| `about.md` | Same content, layout: page | Wrap in `<section>` so column rule applies. |
| `projects.md` | Same content, layout: page (or per design, eventually individual project pages — out of immediate scope) | Same as about. |
| `_plugins/sidenote.rb` (emits `<sup>` + `<span>`) | Must emit `<label class="margin-toggle sidenote-number">` + `<input type="checkbox" id="sn-{rand}" class="margin-toggle"/>` + `<span class="sidenote">`. Existing `{% sidenote N text %}` call sites in 6 posts work unchanged. | Use `SecureRandom.hex` per id. The branch already did this in `b07d528`. |
| `_plugins/tag_generator.rb` | Unchanged. | The plugin produces `/tags/{slug}/` pages; the layout does the visual work. |
| `_includes/tag-generator.html` | Delete. | Has malformed Liquid; not referenced. The branch deleted it (`05d61cd`). |
| Sidenote tag in posts: `{% sidenote N body %}` (6 posts use it) | Same call site; new HTML output via the rewritten plugin. | No Markdown edits required. |
| Per-post `<style>` blocks (Koa Peat, Criterion by the Numbers, Winning Is Noise; ~150 lines each) | Wrap each post body in `<article class="post post-{slug}">`; prefix every selector in the inline style with `.post-{slug}`. | The `tufte-redesign` branch already did this for Koa Peat (`5f91a88`); the two untracked posts also have prefixed selectors but the wrapper isn't applied yet because `_layouts/post.html` still produces `<article class="post">`. |
| Post accent (`#c23b22` `.key-finding`, `#player-detail`, `.verdict-negative`) | Per design v2 §05: in-body accent forbidden ("chrome only"). Per handoff §7: pragmatic harmonization to `#a8332b` was the previous resolution; strict refactor would mean re-rendering callouts ink-only. | Decision-required — design strict vs. preserve post visuals. |
| `kind:` front matter (3 posts have it; 5 don't) | Used by homepage + archive + post page kicker. Values: `Post`, `Project`, `Guest`. | Backfill the 5 posts that lack `kind:`. Default in layout if missing. |
| `<span class="newthought">` opener (1 post has it) | First 2–3 words of every post's first paragraph. | Manual edit per post (the handoff calls this "tedious — keep it"). |
| Permalink `/:year/:month/:day/:title/` | Design suggests flat `/<slug>/`. | **Out-of-scope per user** — keep as-is. |
| `paginate: 15` + `paginate_path` | Not used by new homepage (capped at 8–10, no pagination). | Drop both keys + `jekyll-paginate` plugin + Gemfile dep. |
| `assets/css/main.css` | Not loaded today; not needed by design. | Could delete. |
| `assets/css/tufte.css` (235 lines on main) | Not loaded today; not needed by design (handoff says skip tufte.css and write your own). | Could delete from `main`. The 486-line version on `tufte-redesign` is the upstream library — also can be skipped per handoff. |
| ETBook font files (`.eot/.svg/.ttf/.woff` × 5 weights) | Required. Self-host at `assets/css/et-book/`. | Files exist on `tufte-redesign` only. Carry over. |
| JetBrains Mono (`.woff2` × 2 weights) | Required. Self-host at `assets/fonts/jetbrains-mono/`. | Files exist on `tufte-redesign` only. Carry over. |

### 5. Cross-cutting structural notes

**Sidenote numbering.** `default.html` on `main` uses `body { counter-reset: sidenote-counter }` + `.sidenote-number { counter-increment: sidenote-counter }` + `.sidenote-number:after { content: counter(sidenote-counter) }`. This works only when `<sup class="sidenote-number">` immediately precedes `<span class="sidenote">` in the markup. The handoff §5 explains this must change for the `<label>` + `<input>` + `<span>` pattern to work — the counter target moves from `<sup>` to `<label>`, and the `:after` content is generated on the label.

**Build excludes.** The handoff §9 records that `.md` files in `docs/` crash the Jekyll build because Liquid tries to interpret them. Both `_config.yml` (`exclude:`) and `.gitignore` need to list whatever directory holds research/handoff docs. Currently `_config.yml:36-40` excludes `ruby`, `vendor`, `Gemfile`, `Gemfile.lock` — `docs` is NOT in either list on `main`.

**Tags-page route conflict.** `tags.html` declares `permalink: /tags/`. `_plugins/tag_generator.rb` generates `/tags/{slug}/` per tag. These coexist fine — the index lives at `/tags/index.html`, individual tag pages at `/tags/{slug}/index.html`.

**RSS.** `jekyll-feed` plugin auto-generates `/feed.xml`. Design v2 footer calls for "RSS · Email" links. RSS exists; email signup is a new component (a single input field, per design — not specified deeper).

**Print stylesheet.** Design line 502 has an aside: `@media print: archive pages should print clean — the same dotted-rule list, no chrome.` Not yet implemented anywhere.

**Mobile.** Design has explicit `@media (max-width:980px)` and `@media (max-width:760px)` breakpoints throughout. Tufte's own collapse breakpoint is 760px (handoff §5). `main` uses 1160px, which is wider and aimed at the sidenote-collapse case.

## Code references

- `_layouts/default.html:7-448` — current inline CSS (to be replaced wholesale)
- `_layouts/default.html:451-460` — current header/nav markup (Home is implicit via brand link; nav order = About · Projects · Archive)
- `_layouts/post.html:5-18` — current post header order (h1 → tags → date → content)
- `_layouts/page.html:4-9` — page wrapper without `<section>`
- `index.html:7-17` — paginated post-preview iteration
- `archive.html:11-22` — year-grouped post list
- `tags.html:11-32` — tag cloud + per-tag year groups
- `_plugins/sidenote.rb:14-17` — current sidenote HTML output (`<sup>` + `<span>`)
- `_plugins/tag_generator.rb:5-12` — automatic per-tag page generation
- `_includes/tag-generator.html:7` — malformed Liquid (delete file)
- `_config.yml:8-12` — paginate + permalink config (paginate to be dropped)
- `_config.yml:36-40` — exclude list (add `docs`)
- `_posts/2026-04-11-koa-peat.md:9-` — unscoped inline `<style>` block (~150 lines, defines `.key-finding`, `.chart-container`, `#player-detail`)
- `_posts/2026-03-21-criterion-closet-by-the-numbers.md:9-` — `<style>` block prefixed `.post-criterion-closet-by-the-numbers`
- `_posts/2026-04-25-winning-is-noise.md:9-` — `<style>` block prefixed `.post-winning-is-noise`
- `_posts/2026-04-15-code-driven-prompt-engineering.md:9` — uses `<span class="newthought">` and `kind: Post` already
- `docs/handoff/2026-04-29-tufte-rebuild-handoff.md` — full post-mortem from the prior attempt (186 lines)
- `tufte-redesign:_layouts/default.html` — 437-line reference layout from the prior attempt
- `tufte-redesign:_plugins/sidenote.rb` — the canonical-markup sidenote rewrite
- `tufte-redesign:assets/css/et-book/` — self-hosted ETBook (5 weight directories, 20 files total)
- `tufte-redesign:assets/fonts/jetbrains-mono/` — self-hosted JetBrains Mono (Regular + Medium .woff2)

## Architecture documentation

**Single-file CSS pattern.** Both the current site and the design target keep all CSS inline in one `<style>` block in `_layouts/default.html`. There is no SCSS, no Node toolchain, no build step beyond Jekyll. CLAUDE.md confirms this is intentional: "All CSS is inline here (Tufte-inspired, ~350 lines). No external stylesheets are used in production."

**Layout inheritance.** `default.html` is the only layout with markup beyond `{{ content }}`. `post.html`, `page.html`, `tag.html` each set `layout: default` in front matter and inject their own `<article>` wrapper around `{{ content }}`.

**Plugin-generated pages.** `tag_generator.rb` programmatically creates `/tags/{slug}/index.html` pages by instantiating `Jekyll::Page` subclasses at build time, reading `_layouts/tag.html` as the template, and setting `data['tag']` so the layout can iterate `site.tags[page.tag]`.

**Sidenote rendering.** The current pipeline:
1. Markdown post contains `{% sidenote 1 body text %}`.
2. Liquid tag fires; `sidenote.rb` emits `<sup class='sidenote-number'></sup><span class='sidenote'>body text</span>`.
3. Browser renders. CSS counters in `default.html` increment a `body` counter and project the number via `:after` pseudo-elements on both `<sup>` and `<span>`.
4. Mobile: at `max-width:1160px`, `.sidenote { float: none; ... display: block }` collapses notes inline below the paragraph.

**Per-post styling.** Three posts ship their own `<style>` block as the first content under front matter. Two of three are scoped via class-name prefixes (e.g. `.post-winning-is-noise .chart-container`); one (Koa Peat on `main`) is unscoped, but the `tufte-redesign` branch's post layout wraps it in `<article class="post post-{slug}">` for explicit isolation.

**Pagination.** `index.html` consumes `paginator.posts` provided by `jekyll-paginate`. With `paginate: 15` and 8 posts total, the home is currently a single page; `paginate_path: "/page:num/"` would only kick in past 15 posts.

## Open questions

The handoff doc closes (§"Things to ask the user before you start") with four explicit decision points that this research surfaces but does not resolve:

1. **Branch disposition.** Is `tufte-redesign` a starting point (cherry-pick the asset commits, sidenote plugin rewrite, per-post style scoping) or a graveyard (`git branch -D` after a fresh-from-`main` rebuild)?
2. **Accent color in body content.** Strict adherence to design v2 §05 requires refactoring `.key-finding`, `#player-detail`, `.verdict-negative` to ink-only. Pragmatic option (taken on `tufte-redesign`) is to harmonize hex from `#c23b22` to `#a8332b` and call it done.
3. **Brand text in masthead.** Design wants "Weston Westenborg." Two paths: change `_config.yml`'s `title:` value (also affects `<title>` tags), or add a separate `brand:` field in `_config.yml` and reference it as `{{ site.brand }}` in the masthead.
4. **The 3 untracked posts.** Are `criterion-closet-by-the-numbers`, `code-driven-prompt-engineering`, `winning-is-noise` shipping with this redesign or being held back? Their inline styles need scoping with the post-slug wrapper convention regardless. The first two are also missing from `main` entirely.

Other items the design surfaces but the handoff explicitly puts out-of-scope:
- URL flattening (`/:year/:month/:day/:title/` stays).
- Email signup form (footer calls for "RSS · Email" but no spec for the email side).
- Project pages (design says "Coati, Criterion DB, NIL model — own page each"; current `projects.md` is a 6-link list).

Items the design mentions in passing that have no current implementation:
- Print stylesheet for archive (design line 502).
- Client-side archive title search (design line 501; not in current `archive.html`).
- "Read everything →" handoff on home, footer "RSS · Email" line.
