# How to update the Team Kuiper website

You never need to touch HTML or CSS. Everything you'll change lives in the `_data/` folder, plus photos in `assets/images/`.

## What lives where

| I want to… | Edit this file | Form name in Pages CMS |
| --- | --- | --- |
| Add an award or competition result | `_data/awards.yml` | Awards |
| Add this season's robot | `_data/robots.yml` (photo in `assets/images/robots/`) | Robots |
| Update outreach and impact | `_data/impact.yml` | Impact |
| Add a sponsor | `_data/sponsors.yml` (logo in `assets/images/sponsors/`) | Sponsors |
| Add or mark off a wishlist item | `_data/wishlist.yml` | Wishlist |
| Change the email, donate link, tagline or home photo | `_data/site.yml` (**ask a captain first**) | Site info |
| Change sponsor levels and perks | `_data/sponsor_tiers.yml` (**ask a captain first**) | Sponsor tiers |

## The easy way: Pages CMS

`main` is locked, so you always work on **your own branch** and then ask for a review. The steps:

1. Go to <https://app.pagescms.org> and sign in with your GitHub account.
2. Open the team's website repo. It opens on the `main` branch. **Don't edit here.**
3. Click the **branch name** near the top (it says `main`). A list opens with a box that says *Search branches by name*.
4. Type a new branch name that describes your change, like `add-states-award`, and click **Create**. Then click your new branch in the list to switch to it.
   *(Use lowercase letters and dashes, no spaces.)*
5. Pick a form from the left menu (Awards, Robots, Wishlist…), make your change, and press **Save**. For photos, use the picture field to upload.
   - Every save is a "commit" on your branch. Save as many times as you like.
6. Go to the repo on **github.com**. A yellow banner says *"your-branch had recent pushes"*. Click **Compare & pull request**, write one sentence about what you changed, and click **Create pull request**.

> Pages CMS can't open the pull request for you; step 6 is always done on GitHub.
> Saving also removes comments (lines starting with `#`) from the file you edited. That's normal.

## The GitHub way (no Pages CMS)

1. Open the file on github.com and click the **pencil** icon.
2. Copy an existing block, paste it at the top, and change the text. **Keep the indentation exactly the same.** YAML cares about spaces.
3. Choose **Commit changes → Create a new branch → Propose changes**, then **Create pull request**.

## Then

- A few seconds after you open the pull request, the **"Check site data"** check runs. If it's red, click **Details → Summary**: it tells you in plain English which file and line to fix. Fix it on the same branch and the check re-runs by itself.
- Photos are **shrunk automatically**. A bot may add a small commit to your branch ("resize and compress photos"). That's expected.
- Within about 2 minutes the Cloudflare bot comments with a **preview link**. Open it and check your change on your phone.
- A captain or mentor reviews and approves. When it's merged, the live site updates in about a minute.

## Rules

- **Photos:** use landscape JPGs. Get permission before posting someone's face, and use **first names only** for students.
- **Describe every photo** in the `alt` box (for example, *"Pluto, our 2024-25 robot, on the field"*). It's for people who can't see the picture, and the site won't merge without it.
- **Never** put home addresses, phone numbers or personal emails on the site. The check will block them. Only `@teamkuiper.org` addresses are allowed.
- **Quotes:** if text contains a `#` (like `Qualifier #2`) or a colon, put the whole thing in quotes: `event: "Qualifier #2"`. Pages CMS does this for you.
- Broke something? Don't worry. Every change is saved and can be undone. Tell a captain.
