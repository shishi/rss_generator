# Directory Restructure Design

**Date:** 2026-01-31
**Status:** Approved

## Overview

Separate documentation files from generated artifacts by restructuring the directory layout. Currently, `docs/` contains both design documents (`docs/plans/`) and generated RSS feeds (`docs/*.xml`, `docs/index.html`), which creates confusion and mixing of concerns.

## Problem

- **Mixed concerns**: `docs/` directory contains both development documentation and generated artifacts
- **Management difficulty**: Hard to distinguish between source documentation and build outputs
- **Unclear purpose**: The `docs/` directory serves two different roles

## Proposed Solution

Restructure directories to separate documentation from generated artifacts:

```
docs/                           ← Documentation only
  ├── 2026-01-25-rss-generator-design.md
  └── 2026-01-26-session-summary.md

output/                         ← Generated artifacts (GitHub Pages source)
  ├── index.html
  ├── mangaone-rairairai.xml
  └── yanmaga-seijun.xml
```

## Detailed Design

### Directory Structure Changes

**Before:**
```
docs/
  ├── plans/
  │   ├── 2026-01-25-rss-generator-design.md
  │   └── 2026-01-26-session-summary.md
  ├── index.html
  ├── mangaone-rairairai.xml
  └── yanmaga-seijun.xml
```

**After:**
```
docs/                           ← Design documents
  ├── 2026-01-25-rss-generator-design.md
  └── 2026-01-26-session-summary.md

output/                         ← Generated RSS feeds (GitHub Pages)
  ├── index.html
  ├── mangaone-rairairai.xml
  └── yanmaga-seijun.xml
```

### Code Changes

#### 1. `bin/generate` (Line 24)
```ruby
# Before
output_dir = ARGV[1] || "docs"

# After
output_dir = ARGV[1] || "output"
```

Update help message (Line 13):
```ruby
# Before
output_dir   Output directory for RSS feeds (default: docs)

# After
output_dir   Output directory for RSS feeds (default: output)
```

#### 2. `.github/workflows/generate.yml` (Line 38)
```yaml
# Before
git add docs/

# After
git add output/
```

#### 3. `spec/rss_generator_spec.rb`
No changes needed - tests use `tmp/docs` which is independent from production directories.

### Documentation Updates

#### README.md Changes

**Output section (around L81-84):**
```markdown
# Before
## 出力

- `docs/*.xml` - 各サイトの RSS フィード
- `docs/index.html` - フィード一覧ページ

# After
## 出力

- `output/*.xml` - 各サイトの RSS フィード
- `output/index.html` - フィード一覧ページ
```

**GitHub Pages section (around L92-96):**
```markdown
# Before
3. Branch: `main` (or `master`) / `docs`

# After
3. Branch: `main` (or `master`) / `output`
```

**Directory structure (around L107-123):**
```markdown
# Before
├── docs/                  # 生成された RSS フィード

# After
├── docs/                  # 設計ドキュメント
├── output/                # 生成された RSS フィード（GitHub Pages）
```

## Migration Steps

### Phase 1: Local Changes

1. **Create directory and move files:**
   ```bash
   # Create output directory
   mkdir output

   # Move generated artifacts (preserving history)
   git mv docs/*.xml output/
   git mv docs/index.html output/

   # Move design documents
   git mv docs/plans/*.md docs/
   rmdir docs/plans
   ```

2. **Update code:**
   - `bin/generate`: Change default output to `"output"`
   - `.github/workflows/generate.yml`: Change to `git add output/`
   - `README.md`: Update 3 sections mentioned above

3. **Local testing:**
   ```bash
   # Run tests
   bundle exec rspec

   # Generate feeds
   bundle exec ruby bin/generate

   # Verify output/ contains generated files
   ls -la output/
   ```

### Phase 2: GitHub Configuration

4. **Push changes:**
   ```bash
   git add -A
   git commit -m "refactor: separate docs/ and output/ directories

   - Move generated feeds from docs/ to output/
   - Move design docs from docs/plans/ to docs/
   - Update default output directory in bin/generate
   - Update GitHub Actions to commit output/
   - Update README.md to reflect new structure"

   git push
   ```

5. **Update GitHub Pages settings** (manual):
   - Navigate to repository Settings → Pages
   - Source: Deploy from a branch
   - Branch: `master` / `/output`
   - Click Save

6. **Test GitHub Actions:**
   - Actions tab → "Generate RSS Feeds" → "Run workflow"
   - Verify commits go to `output/`

## Risk Management

### Potential Risks

- **Temporary 404**: GitHub Pages may briefly show 404 after configuration change
- **Redeployment delay**: GitHub Pages takes a few minutes to redeploy
- **RSS subscriber impact**: URLs remain the same, minimal impact expected

### Rollback Plan

- Revert GitHub Pages settings to `/docs` to restore old URLs
- Use `git revert` to rollback code changes
- Generated feeds remain in git history

## Benefits

- **Clear separation**: Documentation vs. artifacts clearly separated
- **Easier maintenance**: Each directory has single, clear purpose
- **Better discoverability**: Design docs are immediately visible in `docs/`
- **Semantic clarity**: `docs/` contains documents, `output/` contains outputs
