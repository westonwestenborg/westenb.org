# Projects Page & Blog Posts Implementation Plan

## Overview

Add a Projects page to westenb.org showcasing past and current work, plus publish supporting blog posts. This establishes Weston's portfolio presence with both company experience (Farmscape, SAIFE, Joymode, allUP) and personal projects (Coati).

## Current State Analysis

**Site structure:**
- Jekyll 4.3.2 on GitHub Pages
- Tufte CSS-inspired design
- Current pages: Homepage, About, Archive, Tags
- 1 existing blog post ("Building This Blog")
- Navigation in `_layouts/default.html` (lines 354-358)

**Content ready:**
- Farmscape: 90% complete blog post in vault
- "Denial of Service Attack on the ATS": Complete, needs to be added as backdated post
- Coati: GitHub repo public (`westonwestenborg/VoiceToObsidian`), philosophy documented

**Content to write:**
- Projects page with descriptions
- "Why I Built Coati" blog post
- "Building Coati" blog post (AI-assisted iOS development)

## Desired End State

1. Projects page in main navigation with 5 projects: Farmscape, SAIFE, Joymode, allUP, Coati
2. "Denial of Service Attack on the ATS" published as backdated blog post
3. Two Coati blog posts published
4. Farmscape blog post published (once Weston finishes it)

## What We're NOT Doing

- Writing the Farmscape blog post (Weston has it 90% done)
- Creating detailed case studies with metrics (keeping descriptions concise)
- Adding project logos/images (can be added later)
- Setting up a dedicated `/projects/coati/` subpage structure (keeping it simple)

## Implementation Approach

Start with the simplest additions (backdated ATS post, projects page structure), then layer in the Coati blog posts which require more thought.

---

## Phase 1: Backdated "Denial of Service Attack on the ATS" Post

### Overview
Publish the existing ATS post as a backdated blog entry (December 2025, when it was posted socially).

### Changes Required:

#### 1. Create blog post file
**File**: `_posts/2025-12-07-denial-of-service-attack-on-the-ats.md`

```markdown
---
layout: post
title: "Denial of Service Attack on the ATS"
date: 2025-12-07
tags: [hiring, ai, jobs]
---

With the proliferation of ChatGPT, every smart job seeker is now using it to rewrite their resume and cover letter for each role they apply to, optimizing for keywords and mirroring company language.

Combine this with services that auto-apply candidates to hundreds of jobs for a few hundred dollars, and you get a denial-of-service attack on applicant tracking systems.

A remote tech job that used to get 50 applications now gets 1200+ in 48 hours. LinkedIn is processing 11,000 applications per minute, up 45% in just the past year. Talent teams and hiring managers can't keep up.

So what are companies doing when they have thousands of applicants that look the same? They're turning to AI tools to screen resumes (AI screening AI-written applications), or falling back on the only signals they have left: job titles, school names, company brands.

Nobody wins. Applicants have to use these tools to have any chance at all. Employers make decisions with less signal than ever—and revert to the exact proxies that the market was working to move past. The system is breaking in real time.
```

### Success Criteria:

#### Automated Verification:
- [x] File exists at correct path: `ls _posts/2025-12-07-denial-of-service-attack-on-the-ats.md`
- [ ] Jekyll builds without errors: `bundle exec jekyll build` (needs bundler update locally)
- [ ] Post appears in archive: Check `_site/archive/index.html` contains the post

#### Manual Verification:
- [ ] Run `bundle exec jekyll serve` and verify post appears on homepage
- [ ] Verify post date shows as December 7, 2025
- [ ] Verify tags link correctly

**Status: Post file created. Ready to deploy—will build on GitHub Pages.**

---

## Phase 2: Create Projects Page

### Overview
Add a Projects page to the main navigation showcasing 5 key projects with brief descriptions.

### Changes Required:

#### 1. Create projects page
**File**: `projects.md`

```markdown
---
layout: page
title: Projects
permalink: /projects/
---

A selection of companies I've helped build and things I've made.

## Companies

### allUP
*Co-founder, 2021–present*

A new professional social network. allUP helps people showcase their capabilities through video profiles, peer testimonials, and async interviews—moving beyond the resume to capture what makes someone great at their work.

[allup.world](https://www.allup.world)

---

### Farmscape
*Co-founder, 2009–2012*

An urban farming company I started after dropping out of college. We built and maintained hundreds of vegetable gardens across Los Angeles, from backyard raised beds to commercial rooftop installations. Featured in USA Today, LA Times, and LA Business Journal.

[farmscapegardens.com](https://farmscapegardens.com)

---

### Joymode
*Head of Operations & Technical PM, 2015–2018*

Led product and operations for a venture-backed startup focused on experience rentals. Scaled the team from early stage through Series A.

---

### SAIFE
*Product, 2013–2014*

Worked on identity verification and security products.

---

## Personal Projects

### Coati
*2025–present*

An iOS app that records voice memos, transcribes them, cleans up the transcript with Claude, and saves a Markdown file directly into your Obsidian vault. Built because I wanted to capture thoughts by voice without losing them to a proprietary app.

[GitHub](https://github.com/westonwestenborg/coati)

{% comment %}
Blog posts:
- Why I Built Coati (coming soon)
- Building Coati: AI-Assisted iOS Development (coming soon)
{% endcomment %}
```

#### 2. Add Projects to navigation
**File**: `_layouts/default.html`
**Change**: Add Projects link to nav (line 357)

```html
<li><a href="{{ '/projects/' | relative_url }}">Projects</a></li>
```

The full nav section becomes:
```html
<nav class="nav-main">
  <ul>
    <li class="logo"><a href="{{ '/' | relative_url }}">{{ site.title }}</a></li>
    <li><a href="{{ '/about/' | relative_url }}">About</a></li>
    <li><a href="{{ '/projects/' | relative_url }}">Projects</a></li>
    <li><a href="{{ '/archive/' | relative_url }}">Archive</a></li>
  </ul>
</nav>
```

### Success Criteria:

#### Automated Verification:
- [ ] Projects page exists: `ls projects.md`
- [ ] Jekyll builds without errors: `bundle exec jekyll build`
- [ ] Projects page generated: `ls _site/projects/index.html`

#### Manual Verification:
- [ ] Run `bundle exec jekyll serve` and verify Projects appears in nav
- [ ] Verify all project descriptions render correctly
- [ ] Verify external links work (allUP, Farmscape, GitHub)
- [ ] Verify page styling matches site aesthetic

---

## Phase 3: "Why I Built Coati" Blog Post

### Overview
Write a blog post about the philosophy behind Coati: local-first data, privacy by design, files over apps.

### Changes Required:

#### 1. Create blog post
**File**: `_posts/2026-01-22-why-i-built-coati.md`

```markdown
---
layout: post
title: "Why I Built Coati"
date: 2026-01-22
tags: [coati, ios, privacy, obsidian]
---

I built Coati because I wanted to capture thoughts by voice without losing them to a proprietary app.

## The Problem

Voice memos are a natural way to capture ideas. You're walking, driving, or just thinking—and pulling out your phone to type feels like friction. But the apps that exist for this either lock your recordings in their own format, require a cloud account, or both.

I use Obsidian for notes, and I wanted my voice memos to end up there as searchable, portable Markdown files. Not as audio blobs trapped in another app. Not synced through someone else's servers.

## Files Over Apps

Steph Ango, the CEO of Obsidian, writes about "file over app"—the idea that your data should outlive any application.{% sidenote 1 "See stephango.com/file-over-app" %} A plain text file written today will be readable in fifty years. Can you say the same about your notes in Notion, or your recordings in Otter.ai?

Coati outputs plain Markdown. The transcript, the cleaned-up version, and a link to the original audio file. You can read it in Obsidian, VS Code, or a text editor that doesn't exist yet. The app is a tool for creating files, not a container for holding them hostage.

## Privacy as Baseline

I took inspiration from Signal and Moxie Marlinspike's approach to privacy: it should be the default, not a premium feature.{% sidenote 2 "Moxie's recent Confer project articulates this well." %}

Coati processes everything locally by default using Apple's speech recognition. If you want more nuanced cleanup—better punctuation, formatting, extracting action items—you can optionally send the transcript to Claude. But that's your choice, and the audio never leaves your device.

No account. No cloud sync. No analytics. The app doesn't know who you are.

## Voice + AI + Local

The interesting part is combining voice capture with AI processing while keeping everything local-first. Apple's on-device speech recognition has gotten good enough for transcription. Claude can clean up the messy parts—fixing grammar, adding paragraph breaks, formatting lists—without needing access to your raw audio.

The result is a workflow that feels modern (speak, get a clean note) without the privacy tradeoffs that usually come with it.

## Why "Coati"?

A coati is a Sonoran desert animal—curious, resourceful, good at finding things. I grew up in Arizona, and I liked the idea of a small, capable creature that does its job without making a fuss.

---

Coati is [open source on GitHub](https://github.com/westonwestenborg/coati). If you use Obsidian and want to capture thoughts by voice, give it a try.
```

### Success Criteria:

#### Automated Verification:
- [ ] File exists: `ls _posts/2026-01-22-why-i-built-coati.md`
- [ ] Jekyll builds without errors: `bundle exec jekyll build`
- [ ] Post appears in build output

#### Manual Verification:
- [ ] Run `bundle exec jekyll serve` and verify post appears
- [ ] Verify sidenotes render correctly
- [ ] Verify tone matches Weston's voice (not too formal, not AI-sounding)
- [ ] Verify GitHub link works

**Implementation Note**: This post draft captures the core ideas from the voice memo. Review and adjust voice/tone before publishing.

---

## Phase 4: "Building Coati" Blog Post

### Overview
Write a blog post about the experience of building an iOS app with AI assistance, from first attempts with Windsurf to effective pairing with Claude.

### Changes Required:

#### 1. Create blog post
**File**: `_posts/2026-01-23-building-coati.md`

```markdown
---
layout: post
title: "Building Coati: Learning to Build iOS Apps with AI"
date: 2026-01-23
tags: [coati, ios, ai, claude, development]
---

I'm not an iOS developer. Before Coati, I'd never written Swift. But I had an idea for an app, and I wanted to see if AI tools had gotten good enough to help someone like me build it.

The short answer: yes, but not in the way I expected.

## First Attempts

My first serious try was around March 2025 with Windsurf—one of the early "AI-native" IDEs. The promise was that you could describe what you wanted and the AI would write the code. And it did write code. Lots of it. Code that sometimes worked, often didn't, and was hard to debug because I didn't understand what it had generated.

I got something running, but I didn't learn much. When things broke, I was stuck.

## Learning to Pair

The shift came when I started treating the AI less like a code generator and more like a pairing partner. Instead of "build me this feature," I started asking "how does SwiftUI handle state?" and "what's the right pattern for this?"

With Claude, particularly through the Claude Code CLI, I found a rhythm that worked. I'd describe what I was trying to do. Claude would explain the approach and write the code. I'd read it, ask questions about parts I didn't understand, and then we'd iterate.

The key insight: I learned more when I slowed down. When I read the code Claude wrote and asked "why this pattern?" or "what happens if this fails?", I started building a mental model of iOS development that stuck.

## Infrastructure That Helped

A few things made the process smoother:

**Tests.** Setting up XCTest early meant I could verify changes without manually testing everything. Claude helped write tests, and then the tests helped catch regressions when we made changes. A feedback loop that actually worked.

**Small commits.** Committing after each working change gave me rollback points. When something broke badly, I could get back to a known state.

**Reading the docs.** Claude is good at explaining, but it hallucinates. When something seemed off, I learned to check Apple's documentation. This caught several mistakes before they became problems.

## What I Built

Coati records voice memos, transcribes them using Apple's speech framework, optionally sends the transcript to Claude for cleanup, and saves a Markdown file to your Obsidian vault. It handles Obsidian's daily note linking, displays past recordings, and includes audio playback.

It's not a complex app, but it has real functionality: audio recording, speech recognition, network requests, file management, state handling across views. Building it taught me enough about iOS development that I could probably build the next thing faster.

## The Takeaway

AI tools didn't replace learning—they accelerated it. I got a working app in a fraction of the time it would have taken to learn iOS from scratch. But I also actually learned things, because I stayed engaged with what the AI was producing instead of just running whatever it generated.

If you're thinking about building something outside your expertise: the tools are good enough now. But treat them as collaborators, not black boxes. Ask questions. Read the code. Build your understanding alongside the features.

---

Coati is [open source](https://github.com/westonwestenborg/coati) if you want to see what AI-assisted iOS development looks like in practice.
```

### Success Criteria:

#### Automated Verification:
- [ ] File exists: `ls _posts/2026-01-23-building-coati.md`
- [ ] Jekyll builds without errors: `bundle exec jekyll build`

#### Manual Verification:
- [ ] Run `bundle exec jekyll serve` and verify post appears
- [ ] Verify tone matches Weston's voice
- [ ] Review for any claims that need fact-checking (timeline, specific tools used)
- [ ] Consider adding specific examples from the actual Coati codebase

**Implementation Note**: This draft captures the narrative arc from the voice memo. The timeline (March 2025 for Windsurf) should be verified. Consider adding more specific examples from actual development if desired.

---

## Phase 5: Update Projects Page with Blog Links

### Overview
Once the Coati posts are published, update the Projects page to link to them.

### Changes Required:

#### 1. Update projects.md
**File**: `projects.md`
**Change**: Replace the comment block under Coati with actual links

```markdown
### Coati
*2025–present*

An iOS app that records voice memos, transcribes them, cleans up the transcript with Claude, and saves a Markdown file directly into your Obsidian vault. Built because I wanted to capture thoughts by voice without losing them to a proprietary app.

[GitHub](https://github.com/westonwestenborg/coati) ·
[Why I Built Coati](/2026/01/22/why-i-built-coati/) ·
[Building Coati](/2026/01/23/building-coati/)
```

### Success Criteria:

#### Automated Verification:
- [ ] Jekyll builds without errors: `bundle exec jekyll build`

#### Manual Verification:
- [ ] Verify all three Coati links work on the Projects page

---

## Phase 6 (Future): Farmscape Blog Post

### Overview
Once Weston completes the remaining 10% of the Farmscape blog post, publish it and add to the Projects page.

### Changes Required:

1. Create `_posts/2026-XX-XX-farmscape.md` with the completed content
2. Update `projects.md` to add link under Farmscape section

### Success Criteria:
- [ ] Post publishes correctly
- [ ] Projects page links to it

**Note**: This phase depends on Weston finishing the post. The content exists in `/Users/ww/vaults/notes/02_Areas/Blog/Ideas/Farmscape.md`.

---

## Testing Strategy

### Local Testing:
```bash
cd /Users/ww/dev/westenb.org
bundle exec jekyll serve
# Visit http://localhost:4000
```

### Pre-deployment Checks:
1. All pages render without errors
2. Navigation works on all pages
3. Tags link correctly
4. Sidenotes display properly (desktop and mobile)
5. External links work

### Post-deployment:
1. Verify site builds on GitHub Pages (check Actions tab)
2. Test live URLs
3. Check mobile rendering

---

## References

- Voice memo: `/Users/ww/vaults/notes/Voice Notes/Building Karate- Projects Page, Blog Posts, and iOS Development Workflow.md`
- Voice memo: `/Users/ww/vaults/notes/Voice Notes/2026 Career Planning and Blog Goals.md`
- ATS post source: `/Users/ww/vaults/notes/02_Areas/Blog/Published/Denial of Service Attack on the ATS.md`
- Farmscape draft: `/Users/ww/vaults/notes/02_Areas/Blog/Ideas/Farmscape.md`
- Coati project: `/Users/ww/vaults/notes/01_Projects/Coati/README.md`
- GitHub repo: `https://github.com/westonwestenborg/coati`
