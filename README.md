# teamkuiper.org

Public website for **Team Kuiper, FIRST Tech Challenge team #8013** (Locust Valley High School, NY).

- Built with **Jekyll 4** (static site, no database, no tracking, no cookies).
- Hosted on **Cloudflare Pages**.
- **Students edit YAML files in `_data/`** (usually through [Pages CMS](https://app.pagescms.org)); they never touch HTML. See [`EDITING.md`](EDITING.md), the student guide.

This file is for mentors.

## Run it on your computer

You need Ruby (the version in [`.ruby-version`](.ruby-version)) and Bundler.

- **Windows:** `winget install RubyInstallerTeam.RubyWithDevKit.3.3`, then open a new terminal.
- **Mac:** `brew install rbenv ruby-build && rbenv install` (reads `.ruby-version`).

```sh
bundle install
bundle exec jekyll serve      # then open http://localhost:4000
```

The page reloads its content when you refresh. Edits to `_data/*.yml` need a restart of `jekyll serve` only if you add new files; changing values is picked up automatically.

Check the data files the same way CI does:

```sh
ruby scripts/validate_data.rb            # errors fail; "TODO" items are only reminders
ruby scripts/validate_data.rb --strict   # TODO items fail too: run this before launch
```

## How the site is put together

```
_data/            ALL the content (YAML). Students edit these.
  site.yml          email, tagline, donate link, season goal, check-donation details, hero photo
  awards.yml        awards timeline (newest first; grouped by season on the page)
  robots.yml        one entry per season
  impact.yml        big numbers + outreach items
  wishlist.yml      items to sponsor; `funded: true` checks them off
  sponsor_tiers.yml levels and perks
  sponsors.yml      current sponsors (empty list hides the logo strip)
_layouts/         page shell (head, header, footer)
_includes/        small reusable pieces (robot card, award row, wishlist row, progress bar…)
*.html            the six pages: index, robots, awards, impact, support, contact (+ 404)
assets/css/main.css   the one stylesheet; colors/fonts are CSS variables at the top
assets/js/main.js     ~50 lines: mobile menu + scroll fade-in
assets/images/    brand/ (logo), robots/, sponsors/, placeholders/
_redirects        Cloudflare Pages redirects from the old Google Sites addresses
.pages.yml        Pages CMS forms and media folders
scripts/validate_data.rb   plain-English data checker
.github/          CODEOWNERS and the two workflows
```

Page → data it reads:

| Page | Data |
| --- | --- |
| Home `/` | `site`, `impact.stats`, newest `robots` entry, 3 newest judged `awards`, `sponsors` |
| Robots `/robots/` | `robots` (sorted by season, newest first) |
| Awards `/awards/` | `awards` grouped by `season`, links to FTCScout + FIRST |
| Impact `/impact/` | `impact` |
| Support Us `/support/` | `site` (donate link, check details, goal), `wishlist`, `sponsor_tiers`, `sponsors` |
| Contact `/contact/` | `site.email` |

Designed so a mistake can't break the site: a missing or misspelled photo falls back to a labeled placeholder, `TODO` taglines fall back to a default, and an empty `sponsors.yml` hides the sponsor strip.

## Deploy (Cloudflare Pages)

Create a Pages project connected to this GitHub repo with:

| Setting | Value |
| --- | --- |
| Production branch | `main` |
| Build command | `bundle exec jekyll build` |
| Build output directory | `_site` |
| Environment variable | `JEKYLL_ENV` = `production` |

Ruby is picked up from `.ruby-version`. Every pull request gets a preview URL automatically; merging to `main` publishes the live site. Then attach the custom domain `teamkuiper.org` in the Pages project.

`Gemfile.lock` lists both `x64-mingw-ucrt` (Windows) and `x86_64-linux` (Cloudflare and GitHub Actions). If you add a gem, run `bundle lock --add-platform x86_64-linux` again.

## One-time GitHub setup (needs an org/repo admin)

1. **Create the approvers team** and put its name in `.github/CODEOWNERS` (currently the placeholder `@team-kuiper/website-approvers`).
2. **Protect `main`** (Settings → Branches → Add rule): require a pull request, require review from Code Owners, require status checks **"Validate data files"** and **"Build the site"**, and block direct pushes.
3. **Install the Pages CMS GitHub App** on the repo (app.pagescms.org walks you through it). Students need at least **write** access to the repo, because they create branches. If you'd rather not give students write access, Pages CMS can invite them by email as *collaborators* instead. It commits for them through its app, but see the note below.
4. **Actions → General → Workflow permissions:** "Read and write", so the photo workflow can push resized images to a PR branch.
5. Cloudflare: connect the repo as described above.

### Things to know about the automations

- **Check site data** (`.github/workflows/validate-data.yml`) runs `scripts/validate_data.rb` and a Jekyll build on every PR. Failures explain the problem in the run's Summary tab.
- **Shrink photos** (`.github/workflows/compress-images.yml`) caps photos at 2000px wide, strips location metadata, compresses them with [`calibreapp/image-actions`](https://github.com/calibreapp/image-actions), and pushes the result onto the PR branch. Commits pushed with the built-in token don't trigger other workflows, so the job starts the data check by hand afterward (otherwise a required check would hang). It only works for branches in this repo, not forks. `image-actions` is referenced as `@main`; pin it to a commit SHA if your org requires that.
- **Pages CMS and branches:** Pages CMS has a branch picker (type a name, click Create) and saves commits to whichever branch you're on, but it can't open pull requests, and it won't write to `main` if `main` is protected. Students open the PR on GitHub (see `EDITING.md`). If you add a sponsor tier or rename one, also update the tier list in `.pages.yml` (the Sponsors form uses a fixed dropdown).

## Before launch checklist

Run `ruby scripts/validate_data.rb --strict` and clear every reminder. Currently outstanding:

- [ ] Real tagline, and `season_goal_usd` in `_data/site.yml`
- [ ] Hero photo at `assets/images/hero.jpg` and a description in `hero_alt`
- [ ] Robot names, photos and `alt` text in `_data/robots.yml`
- [ ] Real wishlist items and prices (the two entries marked EXAMPLE are placeholders)
- [ ] Confirm the game names and awards marked `# verify` in the data files
- [ ] Optional: `social.instagram` / `social.youtube` links

## Privacy

The site is run by minors. By design it has **no analytics, no embedded third-party widgets and no cookies**. The only external request is Google Fonts (CSS and font files). Students appear by first name only. The data checker rejects phone numbers and any email that isn't `@teamkuiper.org`.

## Design notes

Colors come from the team logo (deep navy and violet) plus an icy-blue accent for the Kuiper belt. To re-theme, change the variables at the top of `assets/css/main.css`. Fonts are Sora (headings) and Inter (body), loaded in `_layouts/default.html`. Motion is limited to a short fade-in and a slow starfield twinkle, and it's all switched off for visitors who set "reduce motion".
