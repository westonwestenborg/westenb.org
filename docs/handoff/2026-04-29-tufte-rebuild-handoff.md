# Handoff: westenb.org redesign — what I learned trying to layer on tufte.css

Written 2026-04-29 by the previous Claude that worked on the `tufte-redesign` branch (10 commits, on-disk reference). The goal was to implement the Claude Design "Design review v2" spec on top of the existing Jekyll codebase. **It mostly works but the homepage in particular keeps fighting tufte.css.** A from-scratch rebuild has a chance to do this cleaner. Here's what to know before you start.

## TL;DR — biggest single recommendation

**Don't adopt `tufte.css` 1.8.0 verbatim and try to layer overrides on top.** The framework is opinionated for one layout (single-column long-form prose with sidenotes), and the design review wants three different layouts:

| Page kind | Layout the design wants | What tufte gives you |
| --- | --- | --- |
| Post | Column + sidenotes | ✓ matches |
| Homepage | Full-container "broadsheet" — masthead + intro + dense feed grid + footer | ✗ forces 55% column on every `<p>` inside `<section>` |
| Archive / Tags / About | Dense list view with mono dates and italic kind labels | ✗ same problem |

Every non-post page becomes a fight against `section > p { width: 55% }`, the body's left-anchored geometry, and tufte's default link-underline gradient. The cleanest path is: take the *ideas* from tufte (ETBook, off-white `#fffff8` paper, sidenote markup pattern, no link-blue) and write your own CSS for everything else. The whole production CSS we ended up with was ~200 lines of overrides plus 486 lines of imported tufte.css. A clean rewrite would be one file, ~400 lines.

## The codebase you're inheriting

- Jekyll 4.3.4, two plugins (`jekyll-feed`, `jekyll-paginate`), Ruby 4.0 via Homebrew (`/opt/homebrew/opt/ruby/bin`)
- Build: `PATH="/opt/homebrew/opt/ruby/bin:$PATH" bundle exec jekyll build` or `... jekyll serve --livereload`
- Local gem dir: `ruby/4.0.0/` (vendored, in `.gitignore`)
- The `tufte-redesign` branch is intact — `git diff main..tufte-redesign` shows everything we did. Worth reading even if you start fresh, because the patches reveal where the friction was.
- `docs/research/2026-04-28-tufte-design-review-v2-implementation-map.md` (gitignored) has a complete map of every file involved and where each design recommendation lands. Still accurate against `main`.

## Concrete gotchas, ranked by how much time they ate

### 1. Tufte 1.8.0's column rule is `section > p { width: 55% }`, not `p { width: 55% }`

This caught me twice. Implications:

- A `<p>` directly inside `<article>` or `<div>` with no `<section>` wrapper is **full body-content width** — looks broken on prose pages.
- A `<p>` inside `<section>` is constrained to 55% — but if you wrap a section in another container that also has `max-width: 55%`, you get 55% × 55% = ~30% of body width (looks anorexic).
- The original `_layouts/page.html` had no `<section>` wrapper, so About/Projects ran prose at full viewport width — looked terrible. Easy fix; just wrap in `<section>`.

**For a rebuild:** decide your column rule once, scope it explicitly (`.prose p`, `.column p`, whatever). Don't rely on tufte's element-tree-dependent rule.

### 2. Body geometry has no right gutter

Tufte's body is `width: 87.5%` + `padding-left: 12.5%` (content-box) → total = 100% of viewport with `padding-right: 0`. Content runs to the screen's right edge. Sidenotes float into that "gutter" via `margin-right: -60%`. On non-post pages with no sidenotes, the rightmost element (last nav link, kind label, table cell) visually clips at the screen edge.

**Adding `padding-right: 6%` directly causes horizontal scroll** because total becomes 106%. Either:

- Drop body width to compensate: `width: 81.5%; padding-right: 6%;` (what I ended up with), or
- Use `box-sizing: border-box` on body (but then auto margins center the box, breaking the left-anchored aesthetic), or
- Just write your own body geometry from scratch.

**For a rebuild:** if you want left-anchored, compute width + padding-left + padding-right = 100% explicitly. Don't inherit tufte's body rule.

### 3. Tufte's `a:link` underline is a `background-image` gradient that bleeds everywhere

```css
a:link, a:visited { background: linear-gradient(...); }
```

This applies to every `<a>` on the page. Brand text, nav links, footer copyright — they all get the gradient underline unless you explicitly override:

```css
.brand, .brand:link, .brand:visited { background: none; text-shadow: none; border-bottom: none; }
```

You also need `text-shadow: none` because tufte uses text-shadow to "knockout" descenders crossing the underline. Forgetting this leaves a faint white halo around link text.

**For a rebuild:** pick a simpler underline pattern. `border-bottom: 1px solid` works fine for body links without the gradient gymnastics.

### 4. Article + H1 padding stack to ~140px of empty space

Tufte applies `article { padding: 5rem 0rem }` (line 120) and `h1 { margin-top: 4rem }` (line 47). Combined that's 75px + 60px = 135px of dead space at the top of every page before any content renders. Plus your masthead margin-bottom. On the projects page in the original implementation, the H1 didn't appear until ~280px from the top of viewport.

**For a rebuild:** zero out article padding by default; add it back explicitly on long-form posts.

### 5. Sidenote markup: tufte's mobile tap-to-toggle requires the canonical pattern

The `_plugins/sidenote.rb` Liquid tag emits `<sup>` + `<span>` by default — but tufte's mobile collapse rule is:

```css
@media (max-width: 760px) {
  .sidenote, .marginnote { display: none; }
  .margin-toggle:checked + .sidenote { display: block; ... }
}
```

That `+` adjacent-sibling selector means the markup MUST be:

```html
<label for="sn-1" class="margin-toggle sidenote-number"></label>
<input type="checkbox" id="sn-1" class="margin-toggle"/>
<span class="sidenote">…</span>
```

The `<input>` must immediately precede the `<span>`. We rewrote the plugin in Phase 3 to emit this — see `_plugins/sidenote.rb` on the branch. **Existing call sites (`{% sidenote N text %}` in 6 posts) still work without Markdown edits**, only the rendered HTML changes. IDs need to be unique per page, not just per post — `SecureRandom.hex` is the easy answer.

### 6. Per-post inline `<style>` blocks collide with the global theme

Three posts have ~150-line `<style>` blocks at the top (chart styles, calculator UI, prospect cards):
- `_posts/2026-04-11-koa-peat.md` (published)
- `_posts/2026-03-21-criterion-closet-by-the-numbers.md` (UNPUBLISHED — untracked)
- `_posts/2026-04-25-winning-is-noise.md` (UNPUBLISHED — untracked)

They all redefine `figure`, `figcaption`, and `table` rules that collide with whatever global theme you adopt. Approaches we considered:

- **A. Scope-and-keep** (what I shipped): wrap the post in `<article class="post post-{{ page.slug }}">` and prefix every selector with `.post-{slug}`. Inline styles stay next to content. Works.
- **B. Audit and strip redundant rules**, keep only post-specific bits. Smaller diff but tufte's table styling differs from the post's, so visual drift.
- **C. Move to per-post CSS files** under `assets/css/posts/{slug}.css`, loaded via a `stylesheet:` front-matter key. Cleanest separation but adds a Liquid include.

For a rebuild I'd probably do **A** again. It's the safest preservation of existing post output.

### 7. The accent-color discipline rule conflicts with existing posts

The design v2 spec says: "one accent color, **chrome only** — never in body content." But the existing posts use accent (`#c23b22`, harmonized to `#a8332b`) for `.key-finding` callouts, `#player-detail` panels, range slider accents, `.verdict-negative` text. Strict adherence would mean refactoring those callouts to ink-only. We took the pragmatic route and just harmonized the hex. Worth deciding up front for a rebuild.

### 8. `_config.yml` doesn't auto-reload

Jekyll's `--watch` ignores `_config.yml` changes. After config edits you have to restart the server. We hit this when changing `title: westenb.org` → `title: Weston Westenborg` and the brand kept showing the old value through livereload.

### 9. Plan/handoff/research files in the repo break the Jekyll build

If you write `.md` files anywhere in the source tree, Jekyll tries to process them as Liquid templates. A plan with `{% assign tag_path = | append: ... %}` (a quoted snippet) crashed the build. Add `docs` (or whatever directory you use) to `_config.yml` `exclude:` AND to `.gitignore`. Both are already done on the branch.

## Things you'd inherit from the branch — worth keeping

- **Self-hosted ETBook fonts** at `assets/css/et-book/` (4 weight directories, 16 files). Don't re-download.
- **Self-hosted JetBrains Mono** at `assets/fonts/jetbrains-mono/` (Regular + Medium .woff2). Don't re-download.
- **Sidenote plugin rewrite** at `_plugins/sidenote.rb` — emits canonical tufte markup. Working.
- **Tag-page generator** at `_plugins/tag_generator.rb` — already creates `/tags/{slug}/` pages. Don't reinvent.
- **`kind:` front matter** added to all 8 posts (Post / Project / Guest). The taxonomy works.
- **`<span class="newthought">` lead-ins** added to each post body. Manual edit was tedious — keep it.

## Things that aren't in scope per the original spec

- URL flattening (we kept `/year/month/day/slug/`)
- Email signup
- A separate `<section>` structure inside posts (kramdown can't auto-produce sections; tufte doesn't strictly need them)

## Specific layout decisions worth knowing about the design v2 mock

When the design says "broadsheet" homepage:

- Masthead: brand name + nav, separated by ink-black `border-bottom`
- Intro: small-caps "Builder & co-founder" newthought lead-in, `max-width: 55ch` for line-length comfort but the **container** is full body width
- "RECENT" mono kicker with a horizontal rule extending right (CSS: `display: flex` + `::after { content:""; flex:1; height:1px; background: var(--rule); }`)
- Recent feed: 3-column grid (date / title / kind), dotted dividers
- Footer: ink-black `border-top`, "Read everything →" italic on left, "RSS · Email" on right
- The whole homepage is INSIDE a single container. No 55% column constraint on anything.

When the design says "post page":

- Mono kicker line: `2026 · 04 · 11 · Post` (ISO date + kind, in JetBrains Mono 11px, ink-soft)
- H1 in ETBook 3.2rem (tufte default — feels right)
- 55% column for body prose
- Sidenotes float into the right gutter
- Post footer: "Posted in *basketball*, *nba*, …" italic body-color, then "← Archive" mono back-link

## Site config notes

- `title:` in `_config.yml` is currently `westenb.org`. Design wants "Weston Westenborg" as the masthead. Either change the title value (also affects `<title>` tags) or add a separate `brand:` field.
- `paginate: 15` and `paginate_path: "/page:num/"` are set but the homepage doesn't actually need pagination (8 posts today, design says cap at 10 + handoff to archive). Drop both, plus `jekyll-paginate` from `Gemfile` and plugins list.
- `permalink: /:year/:month/:day/:title/` stays — user wants dates in URLs.

## Files to reference on the `tufte-redesign` branch

If you want to see what worked, the branch is the canonical reference. The most informative diffs:

- `_layouts/default.html` — how I ended up structuring the page shell + overrides block
- `_plugins/sidenote.rb` — canonical markup migration
- `index.html` — the broadsheet homepage that I eventually got close to the design
- `archive.html` — dense list with client-side title filter (vanilla JS, no deps)
- `_posts/2026-04-11-koa-peat.md` first 60 lines — example of scoped per-post styles

## What I'd do differently from scratch

1. Skip tufte.css entirely. Self-host ETBook + JetBrains Mono. Write ~400 lines of CSS yourself with explicit layout classes (`.layout-broadsheet`, `.layout-prose`, `.layout-list`).
2. CSS variables for everything: `--paper`, `--ink`, `--ink-soft`, `--rule`, `--rule-soft`, `--accent`, `--mono`. Theme tweaks become trivial.
3. Define column width once: e.g. `.prose { max-width: 38rem; }` — character-based, not viewport-percentage. Decouples from body geometry.
4. Body: simple centered or left-anchored container with explicit `max-width: 1200px`, `padding: 0 6%`. No tufte arithmetic.
5. Sidenotes: keep tufte's pattern (`<label>` + `<input>` + `<span>`) — it's the only thing that gives mobile tap-to-toggle for free, and the existing plugin already emits it on the branch. Steal that.
6. Use `<section>` only when you actually want column-width prose. Use `<div>` for everything else.
7. Per-post `<style>` blocks: scope them with a `.post-{slug}` wrapper from day one. Tell the user this is the convention so they keep doing it on new posts.

## Things to ask the user before you start

1. Is the `tufte-redesign` branch a starting point or a graveyard? (i.e., merge or `git branch -D`?)
2. The design v2 spec says accent color is "chrome only." The existing posts violate this in their `.key-finding` and calculator UI. Strict refactor or pragmatic harmonize?
3. Brand name in masthead: change `_config.yml title:` from "westenb.org" to "Weston Westenborg," or keep config and add a `brand:` field?
4. The 3 unpublished posts (criterion-closet-by-the-numbers, code-driven-prompt-engineering, winning-is-noise) are untracked. Are they being shipped soon? Their inline styles need scoping too.

Good luck. The content is genuinely good — the chrome is the bottleneck, and that's fixable.
