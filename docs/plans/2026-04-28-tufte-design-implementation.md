---
date: 2026-04-28T23:57:03Z
title: "Tufte design review v2 — implementation"
status: draft
areas: [layouts, plugins, posts, assets]
---

# Implementation Plan: Tufte design review v2

**Created**: 2026-04-28T23:57:03Z
**Status**: Draft
**Repository**: westenb.org
**Branch**: `tufte-redesign` (to be created from `main`)

## Overview

Replace the inline custom theme in `_layouts/default.html` with self-hosted `tufte.css` 1.8.0 + ETBook + JetBrains Mono, rework the post / homepage / archive layouts to match the Design review v2 patterns (sidenotes via the canonical Tufte `<label>`+`<input>`+`<span>` markup, tags at the foot of posts, ISO mono dates, single-letter kind labels, intro + Recent feed), and harmonize the per-post inline styles in the three chart-heavy posts so they continue to render correctly through the foundation swap.

## Success Criteria

- [ ] `bundle exec jekyll build` produces a clean build with no warnings
- [ ] Every existing post renders without visual regression on desktop (≥1200px) and mobile (<760px)
- [ ] Sidenotes show in the right margin on desktop and as tap-to-toggle on mobile (tufte.css's mobile behavior, working "for free")
- [ ] Homepage shows intro + 10 most-recent posts + handoff to `/archive/`
- [ ] Archive page lists every post in one scrollable list grouped by year, with ISO mono dates and kind labels, plus a working title-filter input
- [ ] No reference to `jekyll-paginate` remains in `_config.yml`
- [ ] No `kind:`-less post remains in `_posts/`
- [ ] Footer contains an RSS link pointing at `/feed.xml`

## Desired End State

- `_layouts/default.html` `<style>` block is reduced from ~440 lines to a small (<80 line) overrides block over `<link rel="stylesheet" href="/assets/css/tufte.css">`. Variables for accent (`#a8332b`), rule, mono font, and a couple of small layout overrides only.
- `assets/css/tufte.css` is the canonical 1.8.0 release; `assets/css/et-book/` directory contains the four et-book font weights; `assets/fonts/jetbrains-mono/` contains JetBrains Mono with `@font-face` declarations in the overrides block.
- `_plugins/sidenote.rb` emits the tufte.css canonical pattern (`<label class="margin-toggle sidenote-number">` + `<input type="checkbox" class="margin-toggle">` + `<span class="sidenote">…</span>`).
- All three chart-heavy posts (`koa-peat`, `winning-is-noise`, `criterion-closet-by-the-numbers`) have their inline `<style>` selectors prefixed with `.post-{slug}`, with `#c23b22` → `#a8332b` harmonization.
- All 8 posts have `kind:` front matter (Post / Project / Guest) and a `<span class="newthought">` lead-in.
- Homepage (`index.html`) is intro + 10 most recent + handoff.
- Archive (`archive.html`) is one list, year-grouped, ISO dates, kind labels, client-side title filter.
- Footer (`_layouts/default.html`) has RSS link; nav order is Home · Archive · Projects · About.
- `_includes/tag-generator.html` (dead code) is deleted.

## What We're NOT Doing

- **URL flattening** — keep `/:year/:month/:day/:title/` permalinks; no redirects, no `jekyll-redirect-from` plugin.
- **Email signup** — no provider, no form, no JS.
- **Strict accent-color discipline inside posts** — keep `.key-finding`, `#player-detail`, calculator slider, and `.verdict-*` accent usage. Just harmonize the hex.
- **`<article> > <section>` post structuring** — kramdown can't naturally produce sections; tufte.css doesn't need them.
- **Per-post style audit / consolidation** — keep all current rules, only scope them. No tufte-redundancy rewrite.
- **Refactoring the three big posts' charts/calculators** — leave the embedded JS alone.
- **Committing unpublished posts** — `_posts/2026-03-21-criterion-closet-by-the-numbers.md`, `_posts/2026-04-15-code-driven-prompt-engineering.md`, and `_posts/2026-04-25-winning-is-noise.md` are currently untracked. They get the same edits (scoping, kind, newthought) but their changes stay on the working tree, never staged.

## Areas Affected

- **Layouts** (`_layouts/default.html`, `_layouts/post.html`, `_layouts/page.html`, `_layouts/tag.html`) — full theme replacement, post chrome rework
- **Pages** (`index.html`, `archive.html`, `tags.html`) — content/structure rework
- **Plugins** (`_plugins/sidenote.rb`) — markup migration; `_plugins/tag_generator.rb` unchanged
- **Posts** (all 8 files in `_posts/`) — `kind:` front matter, newthought wrap, scoped styles in 3 of them
- **Assets** (`assets/css/`, `assets/fonts/`) — new fonts and stylesheet
- **Config** (`_config.yml`) — drop pagination
- **Cleanup** — delete `_includes/tag-generator.html`

---

## Phase 0: Branch setup

### Objective
Create `tufte-redesign` branch from `main`. No code changes yet.

### Tasks
- [ ] Create branch `tufte-redesign` from `main`
- [ ] Verify the branch is clean (apart from the pre-existing modifications and untracked files already present)

### Success Criteria

#### Automated Verification
```bash
git rev-parse --abbrev-ref HEAD  # → tufte-redesign
git rev-parse main..HEAD         # → empty (no commits ahead yet)
```

---

## Phase 1: Isolate per-post styles ✓ (commit 5f91a88)

### Objective
Wrap each post body in `<article class="post post-{slug}">` and prefix every inline `<style>` selector in the three chart-heavy posts with their post class. Harmonize accent hex from `#c23b22` to `#a8332b`. Done first so the Phase 2 theme swap can't expose collisions.

### Tasks
- [ ] In `_layouts/post.html`, change `<article class="post">` → `<article class="post post-{{ page.slug }}">` (kramdown / Jekyll computes `page.slug` from the filename)
- [ ] In `_posts/2026-04-11-koa-peat.md`'s `<style>` block, prefix every selector with `.post-koa-peat ` (e.g., `figure { … }` → `.post-koa-peat figure { … }`); update `#c23b22` → `#a8332b` everywhere in this file's `<style>`
- [ ] In `_posts/2026-04-25-winning-is-noise.md`'s `<style>` block (untracked, unpublished — local edit only), apply the same prefix using `.post-winning-is-noise` and the same hex harmonization
- [ ] In `_posts/2026-03-21-criterion-closet-by-the-numbers.md`'s `<style>` block (untracked, unpublished — local edit only), apply the same prefix using `.post-criterion-closet-by-the-numbers` and the same hex harmonization (currently uses `#c23b22` only inline in figcaption — check there too)
- [ ] Inspect each post's HTML for inline `style="color:#c23b22"` (criterion-by-numbers has one in a figcaption); harmonize to `#a8332b`

### Files to Modify
- `_layouts/post.html` — add `post-{{ page.slug }}` to article class
- `_posts/2026-04-11-koa-peat.md` — scope inline style block
- `_posts/2026-04-25-winning-is-noise.md` — scope inline style block (local-only)
- `_posts/2026-03-21-criterion-closet-by-the-numbers.md` — scope inline style block (local-only)

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# Sanity: every per-post selector should now be prefixed
grep -c "^\.post-" _posts/2026-04-11-koa-peat.md  # > 20
# No stray #c23b22 in posts:
grep -rn "c23b22" _posts/  # → empty
```

#### Manual Verification
- [ ] `bundle exec jekyll serve` — open `/2026/04/11/koa-peat/`; charts, table, calculator, key-finding callout, sliders all render identically to before the change
- [ ] Same on `/2026/04/25/winning-is-noise/` (prospect cards, player-detail panel, key-finding)
- [ ] Same on `/2026/03/21/criterion-closet-by-the-numbers/` (stat-row, gem-card, section-break, table)
- [ ] No bleed: visit a non-styled post (e.g., `/2026/01/22/coati/`) — figure/table/figcaption must look like the rest of the site, not like koa-peat's

### Rollback Plan
`git restore _layouts/post.html` and `git checkout HEAD~1 -- _posts/2026-04-11-koa-peat.md` (the unpublished posts can be reverted via working-tree comparison since they aren't committed; keep a copy of original `<style>` blocks before editing).

**Implementation Note**: Pause for manual verification before Phase 2. If anything looks off, fix here — the foundation swap will make collisions much harder to debug.

---

## Phase 2: Foundation swap ✓ (commit bd3fdab)

### Objective
Replace the ~440-line inline theme in `_layouts/default.html` with `<link rel="stylesheet" href="/assets/css/tufte.css">` plus a small overrides block. Bring in self-hosted ETBook and JetBrains Mono.

### Tasks
- [ ] Download canonical `tufte.css` 1.8.0 to `assets/css/tufte.css` (overwrite existing stale local copy)
- [ ] Add Front-matter `---\n---` at top of `tufte.css` if not present (Jekyll requires it for asset processing — check; usually not needed for static CSS)
- [ ] Download et-book font directory and place at `assets/css/et-book/` (4 weights: roman line figures, bold line figures, display italic, semi-bold line figures)
- [ ] Download JetBrains Mono `.woff2` (regular 400 + medium 500) and place at `assets/fonts/jetbrains-mono/`
- [ ] In `_layouts/default.html`, replace lines 7-448 (the `<style>` block) with:
  - `<link rel="stylesheet" href="{{ '/assets/css/tufte.css' | relative_url }}">`
  - A new short `<style>` block containing: CSS variables (`--accent`, `--rule`, `--rule-soft`, `--ink-soft`); `@font-face` declarations for JetBrains Mono; `.mono` utility; small body/header/footer overrides; the responsive 1160px breakpoint adjustments tufte.css doesn't already cover
- [ ] Verify counter-reset for sidenotes is on `body` (already in tufte.css)

### Files to Modify
- `_layouts/default.html` — full theme replacement
- `assets/css/tufte.css` — replace with canonical 1.8.0
- `assets/css/main.css` — leave as stub (or delete; it's currently unused)

### New Files to Create
- `assets/css/et-book/et-book-roman-line-figures/*.{eot,woff,ttf,svg}` — 4 files
- `assets/css/et-book/et-book-display-italic-old-style-figures/*` — 4 files
- `assets/css/et-book/et-book-bold-line-figures/*` — 4 files
- `assets/css/et-book/et-book-semi-bold-line-figures/*` — 4 files (optional — only if tufte.css 1.8.0 references it)
- `assets/fonts/jetbrains-mono/JetBrainsMono-Regular.woff2`
- `assets/fonts/jetbrains-mono/JetBrainsMono-Medium.woff2`

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# tufte.css is linked from default layout:
grep -c 'tufte.css' _layouts/default.html  # → 1
# Old inline theme is gone:
[ "$(wc -l < _layouts/default.html)" -lt 200 ]
```

#### Manual Verification
- [ ] `/` — homepage typography is now ETBook (serif), paper is `#fffff8`, no link-blue
- [ ] `/2026/04/11/koa-peat/` — body type is ETBook, sidenotes show in right margin on desktop with numbered superscripts, charts/table/calculator still render correctly thanks to Phase 1 scoping
- [ ] `/2026/03/21/criterion-closet-by-the-numbers/` — same checks
- [ ] At <760px width — sidenotes collapse and the UI doesn't overflow horizontally
- [ ] Mono dates / kickers display in JetBrains Mono (will appear in Phase 4–6 changes; for now just verify the font loads — temporarily add `<span style="font-family: 'JetBrains Mono'">test</span>` to one page if needed)
- [ ] All four nav links work; about/projects/archive/tags pages all render

### Rollback Plan
`git restore _layouts/default.html assets/css/tufte.css` and remove new asset directories with `git clean -fd assets/css/et-book assets/fonts`.

---

## Phase 3: Sidenote plugin migration ✓ (commit b07d528)

### Objective
Rewrite `_plugins/sidenote.rb` to emit the canonical tufte.css markup pattern so mobile tap-to-toggle works "for free." Existing `{% sidenote N text %}` and `{% marginnote text %}` calls in 6 posts continue to render without Markdown edits.

### Tasks
- [ ] In `_plugins/sidenote.rb`, change `SideNoteTag#render` to emit:
  ```html
  <label for="sn-{id}" class="margin-toggle sidenote-number"></label>
  <input type="checkbox" id="sn-{id}" class="margin-toggle"/>
  <span class="sidenote">{content}</span>
  ```
- [ ] The `id` parameter (currently parsed but unused) becomes load-bearing: tufte.css's mobile collapse needs unique IDs per sidenote. Generate one with `SecureRandom.hex(4)` if id is missing or non-unique
- [ ] Update `MarginNoteTag#render` similarly:
  ```html
  <label for="mn-{id}" class="margin-toggle">⊕</label>
  <input type="checkbox" id="mn-{id}" class="margin-toggle"/>
  <span class="marginnote">{content}</span>
  ```
- [ ] Drop the now-redundant sidenote/marginnote CSS rules from `_layouts/default.html` overrides — tufte.css covers them
- [ ] Drop the 1160px responsive sidenote-collapse rules — tufte.css's mobile pattern handles this

### Files to Modify
- `_plugins/sidenote.rb` — rewrite render methods
- `_layouts/default.html` — remove redundant sidenote CSS

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# Output markup contains the label/input pattern:
grep -c 'class="margin-toggle' _site/2026/04/11/koa-peat/index.html  # ≥ 16 (8 sidenotes × 2 elements)
```

#### Manual Verification
- [ ] `/2026/04/11/koa-peat/` on desktop ≥1200px — every sidenote shows in the right margin with a numbered superscript in the body
- [ ] Same page resized to <760px — superscripts become `⊕`-style indicators that toggle the sidenote inline when tapped
- [ ] Numbering increments correctly across the page (1, 2, 3, …, not all 1)
- [ ] Marginnotes (criterion-by-numbers `{% marginnote ... %}` at line 305) render unnumbered

### Rollback Plan
`git restore _plugins/sidenote.rb _layouts/default.html`

---

## Phase 4: Post page rework ✓ (commit 110e129)

### Objective
Move tags from above the title to the foot of the post body, switch the date to ISO mono format, add `kind:` front matter to all 8 posts, wrap the lead-in of every post in `<span class="newthought">`.

### Tasks
- [ ] Modify `_layouts/post.html`:
  - Remove the tags block (lines 7-13)
  - Change date format from `"%B %-d, %Y"` to `"%Y &middot; %m &middot; %d"` (or `"%Y · %m · %d"`) wrapped in `class="date-iso"`
  - Render `{{ page.kind | default: "Post" }}` as a kind label below the date or in a kicker line
  - After `{{ content }}`, add a footer with: tags line ("Posts in *tag1*, *tag2*, …" italic, body color, linking to `/tags/{slug}/`), and a "← Archive" link
- [ ] Add `kind:` front matter to each post (3 currently committed, 3 unpublished, plus the 2 between):
  - `_posts/2025-03-01-building-this-blog.md` → `kind: Guest`
  - `_posts/2025-12-07-denial-of-service-attack-on-the-applicant-tracking-system.md` → `kind: Post`
  - `_posts/2026-01-22-coati.md` → `kind: Project`
  - `_posts/2026-02-19-criterion-closet-picks.md` → `kind: Project`
  - `_posts/2026-03-21-criterion-closet-by-the-numbers.md` → `kind: Post` (local-only)
  - `_posts/2026-04-11-koa-peat.md` → `kind: Post`
  - `_posts/2026-04-15-code-driven-prompt-engineering.md` → `kind: Post` (local-only)
  - `_posts/2026-04-25-winning-is-noise.md` → `kind: Post` (local-only)
- [ ] Wrap the first 2-3 words of each post body in `<span class="newthought">…</span>` — manual edit, judgement on which words form the natural lead-in
- [ ] Update `_layouts/default.html` overrides to add `.date-iso { font-family: var(--mono); }` and `.kicker-kind { font-style: italic; color: var(--ink-soft); }` if those classes aren't already covered

### Files to Modify
- `_layouts/post.html` — full restructure
- All 8 `_posts/*.md` — front matter + newthought lead-in
- `_layouts/default.html` — minor utility class additions

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# Every post has a kind:
grep -L "^kind:" _posts/*.md  # → empty
# Tags moved out of post.html top:
! grep -A2 'page.title' _layouts/post.html | grep -q 'page.tags'
```

#### Manual Verification
- [ ] `/2026/04/11/koa-peat/` — title appears, ISO mono date below it, no tags above; tags line appears at the foot in italic body color
- [ ] First sentence opens with small-caps lead-in
- [ ] Same checks on 4 other posts of varying types (Project, Guest)

### Rollback Plan
`git restore _layouts/post.html _layouts/default.html _posts/`. Note: this also reverts unpublished post edits, which is acceptable since they're local-only.

---

## Phase 5: Homepage + archive at scale ✓ (commit ff554de)

### Objective
Rewrite `index.html` as intro + 10-most-recent + handoff. Rewrite `archive.html` as one year-grouped list with ISO dates, kind labels, and a client-side title filter. Drop pagination from `_config.yml`.

### Tasks
- [ ] Rewrite `index.html`:
  - Front matter unchanged (`layout: default, title: Home`)
  - Remove `paginator.posts` loop
  - Add intro block: small-caps `<span class="newthought">Builder & co-founder</span>` of allUP. From Tucson, living near Portland with my wife and our dog Mole. I write here about basketball, hiring, technology, and whatever I'm building. (lifted from `about.md`'s opening lines — confirm copy)
  - Render `{{ site.posts | slice: 0, 10 }}` (or `limit: 10`) as the recent feed: ISO mono date · title · italic kind label per row, dotted divider between rows
  - Add handoff line: italic "Read everything →" linking to `/archive/`
- [ ] Rewrite `archive.html`:
  - Group every post by year (already does this)
  - Replace "%b %-d" date with "%m·%d" mono ISO
  - Add right-column kind label using `{{ post.kind | default: "Post" }}`
  - Add a `<input type="text" id="archive-filter" placeholder="Filter…">` at top
  - Add a small inline `<script>` that hides rows whose title doesn't match the filter (vanilla JS, no deps)
- [ ] Drop pagination from `_config.yml`:
  - Remove `paginate: 15`
  - Remove `paginate_path: "/page:num/"`
  - Remove `- jekyll-paginate` from `plugins:`
- [ ] Remove `jekyll-paginate` from `Gemfile` if listed there

### Files to Modify
- `index.html` — full rewrite
- `archive.html` — full rewrite
- `_config.yml` — drop pagination
- `Gemfile` — drop `jekyll-paginate` if present
- `Gemfile.lock` — regenerate via `bundle install`

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# Pagination is gone:
! grep -q "paginate" _config.yml
! grep -q "jekyll-paginate" Gemfile
# Homepage shows intro and recent posts:
grep -q 'newthought' _site/index.html
grep -q 'archive' _site/index.html
```

#### Manual Verification
- [ ] `/` — intro block renders with small-caps lead, 10 most recent posts in dotted-divider rows with ISO dates and kind labels, "Read everything →" links to `/archive/`
- [ ] `/archive/` — one list, all posts grouped by year; ISO mono dates; kind labels right-aligned italic
- [ ] Type "koa" into the archive filter — only Koa Peat row remains visible
- [ ] Clear filter — all rows return
- [ ] No `/page2/`, `/page3/` URLs exist (irrelevant with 8 posts but verify config drop took effect)

### Rollback Plan
`git restore index.html archive.html _config.yml Gemfile Gemfile.lock`. Run `bundle install` to regenerate the lockfile.

---

## Phase 6: Tags page, footer, cleanup ✓ (commit 05d61cd)

### Objective
Sync `/tags/` and per-tag pages to the new ISO date + kind primitives. Add an RSS link to the footer. Reorder nav. Delete dead code.

### Tasks
- [ ] Update `_layouts/tag.html` — change date format from `"%b %-d"` to ISO mono, add kind label column
- [ ] Update `tags.html` — change date format in per-tag sections from `"%B %-d, %Y"` to ISO mono, add kind label column. Keep the cloud + sections shape (already aligned with the review's "alphabetical index w/ counts")
- [ ] In `_layouts/default.html` footer (the `<footer>` element near the bottom), add RSS link: `<a href="{{ '/feed.xml' | relative_url }}">RSS</a>` alongside the copyright line, set in mono kicker style
- [ ] In `_layouts/default.html` nav (`<nav class="nav-main">`), reorder `<li>` elements to: `Home (logo) · Archive · Projects · About`. Highlight the active page via `{% if page.url == "/archive/" %}…cur…{% endif %}`
- [ ] Delete `_includes/tag-generator.html` (dead code; broken `{% assign %}`; not referenced anywhere)

### Files to Modify
- `_layouts/tag.html`
- `tags.html`
- `_layouts/default.html` (footer + nav)
- Delete: `_includes/tag-generator.html`

### Success Criteria

#### Automated Verification
```bash
bundle exec jekyll build
# Dead include is gone:
[ ! -f _includes/tag-generator.html ]
# RSS link in footer:
grep -q 'feed.xml' _layouts/default.html
# Nav order: Home → Archive → Projects → About
grep -A8 'nav-main' _layouts/default.html | grep -E '(Home|Archive|Projects|About)'
```

#### Manual Verification
- [ ] `/tags/` — alphabetized cloud at top with counts; per-tag sections below with ISO dates and kind labels
- [ ] Click any tag → `/tags/{slug}/` lists that tag's posts with ISO dates + kind
- [ ] Footer on every page has an RSS link that points at `/feed.xml`; clicking it returns valid XML
- [ ] Nav order on every page is `Home · Archive · Projects · About`; the current page's link is visually distinguished

### Rollback Plan
`git restore _layouts/default.html _layouts/tag.html tags.html` and recreate the deleted include from git history if needed (it's effectively dead code, but `git checkout main -- _includes/tag-generator.html` works).

---

## Testing Strategy

### Manual Testing Steps
1. After each phase, `bundle exec jekyll serve` and click through:
   - `/` (homepage)
   - `/about/`, `/projects/`
   - `/archive/`, `/tags/`, a sampled `/tags/{slug}/`
   - At least one post of each kind (Post, Project, Guest)
   - The three chart-heavy posts
2. Resize the browser between 1500px and 320px and confirm no horizontal scroll, no overlapping text, no broken sidenotes
3. View source on a chart-heavy post and verify per-post `<style>` selectors are scoped (`.post-koa-peat …`)

### Visual Regression
- Before Phase 2, capture full-page screenshots of: `/`, `/2026/04/11/koa-peat/`, `/2026/03/21/criterion-closet-by-the-numbers/`, `/archive/`, `/tags/`
- After Phase 6, capture again and compare. Expect deliberate drift (the whole point) but check for unintentional layout breaks

## Risk Assessment

- **Per-post style collisions**: Phase 1 mitigates by scoping. If a stray unscoped selector slips through, it'll only show up in Phase 2 manual verification. Fix forward by adding the prefix.
- **Sidenote markup migration breaking existing posts**: Phase 3 changes plugin output. The 6 posts using `{% sidenote %}` should render correctly without Markdown edits. If numbering breaks, check the `id` generation (must be unique per page).
- **Dropping `jekyll-paginate` while index still references `paginator.posts`**: Phase 5 removes both at the same time. If split, build will fail loudly — easy to catch.
- **et-book font path mismatches**: tufte.css's `@font-face` URLs are relative to the stylesheet location. Place fonts under `assets/css/et-book/` (matching tufte.css's expectations), not `assets/fonts/et-book/`.
- **Unpublished post edits accidentally committed**: When committing, always stage explicitly (`git add <file>`), never `git add -A` or `git add .`. The three unpublished posts must stay on the working tree only.

## Commit strategy

Per phase, when ready to commit:
- Phase 0 — no commit (just branch creation)
- Phase 1 — commit only `_layouts/post.html` and `_posts/2026-04-11-koa-peat.md` (the published post). The unpublished posts get the same in-place edits but stay unstaged.
- Phase 2 — commit `_layouts/default.html`, `assets/css/tufte.css`, new font files
- Phase 3 — commit `_plugins/sidenote.rb`, `_layouts/default.html` (overrides cleanup)
- Phase 4 — commit `_layouts/post.html`, `_layouts/default.html`, and only the 5 published posts' front-matter + newthought edits
- Phase 5 — commit `index.html`, `archive.html`, `_config.yml`, `Gemfile`, `Gemfile.lock`
- Phase 6 — commit `_layouts/tag.html`, `tags.html`, `_layouts/default.html`; delete `_includes/tag-generator.html`

Untracked unpublished posts (`_posts/2026-03-21-…`, `_posts/2026-04-15-…`, `_posts/2026-04-25-…`) and assets (`assets/images/dybantsa.jpg`, `karaban.jpg`) stay untracked throughout.

## References

- Research: `docs/research/2026-04-28-tufte-design-review-v2-implementation-map.md`
- Design source: bundle extracted to `/tmp/design-review/westenb-org/project/Design review v2.html`
- tufte.css canonical: https://github.com/edwardtufte/tufte-css (1.8.0 release)
- ETBook fonts: bundled with the tufte-css repo under `et-book/`
- JetBrains Mono: https://github.com/JetBrains/JetBrainsMono
