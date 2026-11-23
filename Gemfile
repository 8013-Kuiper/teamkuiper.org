source "https://rubygems.org"

# Jekyll 4 (NOT the github-pages gem: this site deploys to Cloudflare Pages).
gem "jekyll", "~> 4.3"

group :jekyll_plugins do
  gem "jekyll-sitemap", "~> 1.4"
end

# Needed on Ruby 3+ for `jekyll serve`, and on Windows for time zones.
gem "webrick", "~> 1.8"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
