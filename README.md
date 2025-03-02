# Personal Blog

A simple, elegant personal blog built with Jekyll and styled with Tufte CSS.

## Features

- Clean, readable design based on Tufte CSS
- Support for sidenotes and margin notes
- Responsive layout
- Tag system for categorizing posts
- Archive page for browsing all posts
- Pagination for the home page

## Getting Started

### Prerequisites

- Ruby (2.5.0 or higher)
- RubyGems
- Bundler

### Installation

1. Install Jekyll and Bundler:
   ```
   gem install jekyll bundler
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Run the development server:
   ```
   bundle exec jekyll serve
   ```

4. View your site at `http://localhost:4000`

## Creating Content

### Blog Posts

Create new blog posts in the `_posts` directory with the filename format: `YYYY-MM-DD-title.md`. For example: `2025-03-01-welcome-post.md`

Each post should have front matter at the top:

```yaml
---
layout: post
title: "Your Post Title"
date: YYYY-MM-DD
tags: [tag1, tag2]
---
```

### Tufte CSS Features

#### Sidenotes

Add sidenotes to your content using the sidenote tag:

```
This is text with a sidenote.{% sidenote 1 "This is the sidenote content." %}
```

The number parameter is used as an ID and should be unique within the post.

#### Margin Notes

Add margin notes (without numbers) using the marginnote tag:

```
This is text with a margin note.{% marginnote "This is the margin note content." %}
```

## Deployment

### GitHub Pages

1. Create a GitHub repository named `username.github.io`
2. Push your Jekyll site to the repository
3. Your site will be available at `https://username.github.io`

To use a custom domain:

1. Create a file named `CNAME` in the root directory with your domain name
2. Configure your domain's DNS settings as [described in GitHub's documentation](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

## Customization

- Edit `_config.yml` to update site settings
- Modify layouts in the `_layouts` directory
- Add partials to the `_includes` directory
- Edit CSS in the `assets/css` directory