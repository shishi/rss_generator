# RSS Generator - Project Instructions

## Development Environment

This project uses **Nix flakes** for development environment management.

### ⚠️ IMPORTANT: Claude Code / AI Agent Environment

**Claude Code does NOT have direnv loaded.** Always use `nix develop -c` prefix:

```bash
# ✅ CORRECT - Always use this pattern:
nix develop -c bundle exec rspec
nix develop -c xvfb-run bundle exec ruby bin/generate

# ❌ WRONG - Will fail without Nix environment:
bundle exec rspec
xvfb-run bundle exec ruby bin/generate
```

**Playwright requires:**
1. `nix develop -c` for Chromium and system libraries
2. `xvfb-run` for headless browser (WSL2/CI)
3. `CHROME_PATH` environment variable (set automatically by flake.nix)

### Human Developer Environment (with direnv)
- `direnv` is configured with `.envrc` (`use flake`)
- When you `cd` into this directory, the flake environment is automatically loaded
- Run `direnv allow` if prompted
- With direnv active, you can run commands directly: `bundle exec rspec`

## Testing

- Tests are located in `spec/` directory (RSpec)
- Run tests with: `bundle exec rspec`
- Always run tests after making changes

## Project Structure

```
lib/
  scraper.rb       # Web scraping with Playwright (2 modes: selector/script)
  feed_builder.rb  # RSS XML generation
  rss_generator.rb # Main orchestrator
  index_builder.rb # HTML index generation
config/
  sites/           # Site configurations (split by domain)
    yanmaga.yml
    mangaone.yml
    corocoro.yml
    typemoon.yml
spec/
  *_spec.rb        # RSpec tests
output/
  *.xml            # Generated RSS feeds
  index.html       # Feed index page
docs/
  *.md             # Design documents
```

## Site Configuration

Site configs are split by domain in `config/sites/`. Each file contains a `sites:` array.
YAML anchors (`&name` / `*name`) can be used to share extraction scripts within a file.

### Standard Mode (CSS Selectors)
For sites with static HTML structure:
```yaml
- name: "Manga Title"
  id: "site-manga"
  url: "https://example.com/manga/1"
  selectors:
    episode_list: ".episode"
    episode_title: ".title"
    episode_url: "a"
    episode_date: ".date"
  wait_for: ".episode-list"
  exclude_selector: "[data-is-free='false']"  # optional
```

### JavaScript Evaluation Mode (SPA Sites)
For React/Next.js SPAs requiring custom extraction:
```yaml
- name: "SPA Manga"
  id: "spa-manga"
  url: "https://spa-site.com/manga/1"
  base_url: "https://spa-site.com"  # for relative URL conversion
  user_agent: "Mozilla/5.0 ..."
  wait_seconds: 8
  extraction_script: |
    () => {
      // Return array of {title, url, date}
      return episodes;
    }
```
