#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks every file in _data/ and explains problems in plain language.
#
#   ruby scripts/validate_data.rb            # errors fail, TODO notes are just reminders
#   ruby scripts/validate_data.rb --strict   # TODO notes fail too (use right before launch)
#
# Needs only Ruby itself (no gems), so it also runs in GitHub Actions in a few seconds.

require "yaml"
require "date"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "_data")
STRICT = ARGV.include?("--strict")
ON_GITHUB = ENV["GITHUB_ACTIONS"] == "true"

$errors = []
$notes = []

# ----- helpers --------------------------------------------------------------

def rel(file) = "_data/#{file}"

def error(file, where, message)
  $errors << { file: rel(file), where: where, message: message }
end

def note(file, where, message)
  $notes << { file: rel(file), where: where, message: message }
end

def blank?(v) = v.nil? || (v.respond_to?(:empty?) && v.empty?) || (v.is_a?(String) && v.strip.empty?)

def label(item, keys)
  keys.each { |k| return "\"#{item[k]}\"" if item.is_a?(Hash) && !blank?(item[k]) }
  "(no name yet)"
end

# Required text field. `fix` is an example line students can copy.
def need_text(file, where, item, key, fix = nil)
  v = item[key]
  if blank?(v)
    hint = fix ? " Add a line like:  #{fix}" : ""
    error(file, where, "is missing `#{key}`.#{hint}")
    return nil
  end
  unless v.is_a?(String)
    error(file, where, "`#{key}` should be text. Put it in quotes, like  #{key}: \"#{v}\"")
    return nil
  end
  note(file, where, "`#{key}` still says TODO. Fill it in before launch.") if v.include?("TODO")
  v
end

def need_url(file, where, item, key, required: true)
  v = item[key]
  if blank?(v)
    error(file, where, "is missing `#{key}` (a full link starting with https://).") if required
    return
  end
  error(file, where, "`#{key}` should be a full link starting with https:// (got: #{v}).") unless v.to_s =~ %r{\Ahttps?://\S+\z}
end

def need_list(file, where, item, key)
  v = item[key]
  unless v.is_a?(Array)
    error(file, where, "`#{key}` should be a list (each entry starts with a dash and a space).")
    return []
  end
  v
end

def need_image_file(file, where, path, folder)
  return if path.nil? || path.include?("TODO")
  unless path.start_with?("/assets/images/#{folder}/")
    error(file, where, "image path should start with /assets/images/#{folder}/ (got: #{path}).")
    return
  end
  full = File.join(ROOT, path)
  error(file, where, "photo not found: #{path}. Upload it to assets/images/#{folder}/ and check the spelling (and .jpg vs .jpeg).") unless File.exist?(full)
end

def load(file)
  path = File.join(DATA, file)
  unless File.exist?(path)
    error(file, "whole file", "is missing. Every site file in _data/ has to exist.")
    return nil
  end
  raw = File.read(path)
  check_hash_comments(file, raw)
  data = begin
    YAML.safe_load(raw, permitted_classes: [Date, Time], aliases: false)
  rescue Psych::SyntaxError => e
    error(file, "line #{e.line}", "has a YAML typo: #{e.problem} #{e.context}. Check the spaces at the start of that line: every item in a list must line up exactly. Tip: compare with the entry above it.")
    return nil
  end
  data
end

# YAML treats "#" after a space as the start of a comment, so "Qualifier #2" silently becomes "Qualifier".
def check_hash_comments(file, raw)
  raw.each_line.with_index(1) do |line, i|
    next unless line =~ /\A\s*(?:- )?\w+:\s+([^"'\s#][^"'#]*)\s#\S/
    error(file, "line #{i}", "has a # inside unquoted text, and YAML treats everything after # as a comment, so part of your text will vanish. Wrap the whole value in quotes, like  event: \"Qualifier #2\"")
  end
end

def check_privacy(file, raw_text)
  # Personal contact info doesn't belong on a site run by minors.
  raw_text.scan(/[\w.+-]+@[\w-]+\.[\w.-]+/).each do |email|
    next if email.downcase.end_with?("@teamkuiper.org")
    error(file, "contact info", "contains the email address #{email}. Only team addresses (@teamkuiper.org) may appear on the site.")
  end
  if raw_text =~ /(?<!\d)(?:\(\d{3}\)\s?|\d{3}[-.\s])\d{3}[-.\s]\d{4}(?!\d)/
    error(file, "contact info", "looks like it contains a phone number. Remove it: phone numbers must never appear on the site.")
  end
end

# ----- per-file checks ------------------------------------------------------

def check_site
  f = "site.yml"
  d = load(f) or return
  return error(f, "whole file", "should be a set of `name: value` lines.") unless d.is_a?(Hash)
  %w[team_name program school location].each { |k| need_text(f, "top", d, k) }
  need_text(f, "top", d, "email", "email: info@teamkuiper.org")
  need_text(f, "top", d, "tagline", "tagline: \"Your one-line team motto\"")
  error(f, "top", "`team_number` should be a number like 8013.") unless d["team_number"].is_a?(Integer)
  need_url(f, "top", d, "donate_url")
  need_url(f, "top", d, "ftcscout_url")
  need_url(f, "top", d, "first_events_url", required: false)
  g = d["season_goal_usd"]
  error(f, "top", "`season_goal_usd` should be a number of dollars, like 12000.") unless g.is_a?(Numeric)
  note(f, "top", "`season_goal_usd` is 0, so the wishlist bar falls back to the wishlist total. Set the real goal before launch.") if g == 0
  if d["social"].is_a?(Hash)
    d["social"].each { |k, v| error(f, "social.#{k}", "should be a full link starting with https:// (or leave it blank).") unless blank?(v) || v.to_s.start_with?("https://") }
  end
  c = d["check_donations"]
  if c.is_a?(Hash)
    %w[payable_to mail_to].each { |k| need_text(f, "check_donations", c, k) }
  else
    error(f, "check_donations", "is missing. It needs `payable_to` and `mail_to`.")
  end
  note(f, "hero_alt", "still says TODO. Describe the home page photo for screen readers.") if d["hero_alt"].to_s.include?("TODO")
end

SEASON = /\A\d{4}-\d{2}\z/

def check_awards
  f = "awards.yml"
  list = load(f) or return
  return error(f, "whole file", "should be a list. Each award starts with a dash and a space (- title: ...).") unless list.is_a?(Array)
  list.each_with_index do |a, i|
    where = "item #{i + 1}"
    unless a.is_a?(Hash)
      error(f, where, "isn't a block of `name: value` lines.")
      next
    end
    where = "item #{i + 1} #{label(a, %w[title])}"
    need_text(f, where, a, "title", "title: Inspire Award — 1st Place")
    need_text(f, where, a, "event", "event: \"Long Island Qualifier #1\"")
    s = need_text(f, where, a, "season", "season: \"2025-26\"")
    error(f, where, "`season` should look like 2025-26 (got: #{s}).") if s && !s.include?("TODO") && s !~ SEASON
    error(f, where, "`type` must be one of: award, performance, event (got: #{a['type'].inspect}).") unless %w[award performance event].include?(a["type"])
  end
end

def check_robots
  f = "robots.yml"
  list = load(f) or return
  return error(f, "whole file", "should be a list. Each robot starts with a dash and a space (- season: ...).") unless list.is_a?(Array)
  list.each_with_index do |r, i|
    where = "item #{i + 1}"
    next error(f, where, "isn't a block of `name: value` lines.") unless r.is_a?(Hash)
    where = "item #{i + 1} #{label(r, %w[name season])}"
    s = need_text(f, where, r, "season", "season: 2025-26")
    error(f, where, "`season` should look like 2025-26 (got: #{s}).") if s && s !~ SEASON
    # `name` is optional: a robot we never named just shows its game, e.g. "DECODE robot".
    error(f, where, "`name` is empty. Either type a name or delete the whole `name:` line.") if r.key?("name") && blank?(r["name"])
    img = need_text(f, where, r, "image", "image: /assets/images/robots/pluto.jpg")
    need_image_file(f, where, img, "robots")
    need_text(f, where, r, "alt", "alt: \"Pluto, our 2024-25 robot, on the field\"")
    if r.key?("highlights")
      need_list(f, where, r, "highlights").each { |h| error(f, where, "each highlight should be one line of text.") unless h.is_a?(String) }
    end
    if r.key?("stats")
      need_list(f, where, r, "stats").each do |st|
        next error(f, where, "each stat needs a `label` and a `value`.") unless st.is_a?(Hash)
        need_text(f, "#{where} stat", st, "label")
        v = st["value"]
        error(f, "#{where} stat", "is missing `value`.") if blank?(v)
        error(f, "#{where} stat", "`value` should be in quotes, like value: \"161.40\" (so zeros aren't dropped).") if v.is_a?(Numeric)
      end
    end
  end
end

def check_impact
  f = "impact.yml"
  d = load(f) or return
  return error(f, "whole file", "should have `stats:` and `items:` lists.") unless d.is_a?(Hash)
  need_list(f, "top", d, "stats").each_with_index do |s, i|
    where = "stat #{i + 1}"
    next error(f, where, "needs `number` and `label`.") unless s.is_a?(Hash)
    error(f, where, "is missing `number`.") if blank?(s["number"])
    need_text(f, where, s, "label", "label: FLL teams mentored")
  end
  need_list(f, "top", d, "items").each_with_index do |s, i|
    where = "item #{i + 1}"
    next error(f, where, "needs `title` and `text`.") unless s.is_a?(Hash)
    where = "item #{i + 1} #{label(s, %w[title])}"
    need_text(f, where, s, "title")
    need_text(f, where, s, "text")
  end
end

def tier_names
  d = YAML.safe_load(File.read(File.join(DATA, "sponsor_tiers.yml")), permitted_classes: [Date, Time], aliases: false) rescue nil
  d.is_a?(Hash) && d["tiers"].is_a?(Array) ? d["tiers"].map { |t| t.is_a?(Hash) ? t["name"] : nil }.compact : []
end

def check_tiers
  f = "sponsor_tiers.yml"
  d = load(f) or return
  return error(f, "whole file", "should have a `tiers:` list.") unless d.is_a?(Hash)
  last_min = -1
  need_list(f, "top", d, "tiers").each_with_index do |t, i|
    where = "tier #{i + 1}"
    next error(f, where, "needs `name`, `min` and `perks`.") unless t.is_a?(Hash)
    where = "tier #{i + 1} #{label(t, %w[name])}"
    need_text(f, where, t, "name", "name: Gold")
    unless t["min"].is_a?(Numeric)
      error(f, where, "`min` should be a number of dollars, like min: 1000.")
      next
    end
    error(f, where, "tiers must go from the smallest gift to the largest (this one is smaller than the one above it).") if t["min"] < last_min
    last_min = t["min"]
    perks = need_list(f, where, t, "perks")
    error(f, where, "needs at least one perk.") if perks.empty?
    perks.each { |p| error(f, where, "each perk should be one line of text. If a perk has a comma inside it, wrap it in quotes.") unless p.is_a?(String) }
  end
end

def check_sponsors
  f = "sponsors.yml"
  list = load(f) or return
  return error(f, "whole file", "should be a list (use `[]` when there are no sponsors yet).") unless list.is_a?(Array)
  names = tier_names
  list.each_with_index do |s, i|
    where = "item #{i + 1}"
    next error(f, where, "isn't a block of `name: value` lines.") unless s.is_a?(Hash)
    where = "item #{i + 1} #{label(s, %w[name])}"
    need_text(f, where, s, "name", "name: Example Company")
    if names.include?(s["tier"])
      # ok
    else
      error(f, where, "`tier` must match a tier name exactly (one of: #{names.join(', ')}). Got: #{s['tier'].inspect}.")
    end
    need_image_file(f, where, s["logo"], "sponsors") unless blank?(s["logo"])
    need_url(f, where, s, "url", required: false)
  end
end

def check_wishlist
  f = "wishlist.yml"
  list = load(f) or return
  return error(f, "whole file", "should be a list. Each item starts with a dash and a space (- item: ...).") unless list.is_a?(Array)
  list.each_with_index do |w, i|
    where = "item #{i + 1}"
    next error(f, where, "isn't a block of `name: value` lines.") unless w.is_a?(Hash)
    where = "item #{i + 1} #{label(w, %w[item])}"
    t = need_text(f, where, w, "item", "item: goBILDA motor (x4)")
    note(f, where, "is still marked EXAMPLE. Replace it with a real wishlist item.") if t&.start_with?("EXAMPLE")
    need_url(f, where, w, "url", required: false)
    p = w["price"]
    error(f, where, "`price` should be a number of dollars with no $ sign, like price: 129.99.") unless p.is_a?(Numeric)
    note(f, where, "price is 0. Fill in the real price.") if p == 0
    error(f, where, "`priority` must be high, medium or low.") unless %w[high medium low].include?(w["priority"])
    error(f, where, "`funded` must be true or false (no quotes).") unless [true, false].include?(w["funded"])
  end
end

# ----- run ------------------------------------------------------------------

check_site
check_awards
check_robots
check_impact
check_tiers
check_sponsors
check_wishlist

Dir.glob(File.join(DATA, "*.yml")).each { |p| check_privacy(File.basename(p), File.read(p)) }

if STRICT
  $errors.concat($notes.map { |n| n.merge(message: "#{n[:message]} (strict mode)") })
  $notes.clear
end

def gh(level, item)
  return unless ON_GITHUB
  puts "::#{level} file=#{item[:file]},title=#{item[:where]}::#{item[:message]}"
end

summary = []
if $errors.empty?
  puts "All data files look good."
else
  puts "\nOops. A few things need fixing before this can be merged:\n\n"
  $errors.each do |e|
    puts "  [x] #{e[:file]} -> #{e[:where]} #{e[:message]}"
    gh("error", e)
    summary << "- **#{e[:file]}** (#{e[:where]}): #{e[:message]}"
  end
  puts "\nDon't panic. Open the file, fix the line(s) above, and save again. The check re-runs on its own."
end

unless $notes.empty?
  puts "\nReminders (these don't block anything yet):\n\n"
  $notes.each do |n|
    puts "  [!] #{n[:file]} -> #{n[:where]} #{n[:message]}"
    gh("notice", n)
  end
end

if (path = ENV["GITHUB_STEP_SUMMARY"])
  File.open(path, "a") do |io|
    if $errors.empty?
      io.puts "### :white_check_mark: Data files look good"
    else
      io.puts "### :x: A few things need fixing\n"
      io.puts summary.join("\n")
      io.puts "\nOpen the file named above, fix the line, and save. This check re-runs automatically."
    end
    unless $notes.empty?
      io.puts "\n#### Reminders\n"
      $notes.each { |n| io.puts "- **#{n[:file]}** (#{n[:where]}): #{n[:message]}" }
    end
  end
end

exit($errors.empty? ? 0 : 1)
