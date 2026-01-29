# RSS Generator - Project Instructions

## Development Environment

This project uses **Nix flakes** for development environment management.

### Automatic Environment Setup
- `direnv` is configured with `.envrc` (`use flake`)
- When you `cd` into this directory, the flake environment is automatically loaded
- Run `direnv allow` if prompted

### Running Commands
```bash
# With direnv (automatic):
bundle exec ruby bin/generate
bundle exec rspec

# Without direnv (manual):
nix develop -c bundle exec ruby bin/generate
nix develop -c xvfb-run bundle exec rspec
```

### Headless Browser Testing (WSL2/CI)
Use `xvfb-run` for Playwright/Chromium:
```bash
xvfb-run bundle exec ruby bin/generate
```

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
  sites.yml        # Site configurations
spec/
  *_spec.rb        # RSpec tests
docs/
  *.xml            # Generated RSS feeds
  index.html       # Feed index page
```

## Site Configuration

Two scraping modes are supported in `config/sites.yml`:

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
