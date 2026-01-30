# Directory Restructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Separate documentation (`docs/`) from generated artifacts (`output/`) to improve project organization and clarity.

**Architecture:** Refactoring existing directory structure without changing business logic. Move files using `git mv` to preserve history, update code references from `docs/` to `output/`, and update documentation.

**Tech Stack:** Ruby, Git, GitHub Actions, RSpec

---

## Task 1: Directory Restructure and File Migration

**Files:**
- Create: `output/` directory
- Move: `docs/*.xml` → `output/`
- Move: `docs/index.html` → `output/`
- Move: `docs/plans/*.md` → `docs/`
- Remove: `docs/plans/` directory

**Step 1: Create output directory**

Run:
```bash
mkdir output
```

Expected: Directory created successfully

**Step 2: Move generated artifacts to output/**

Run:
```bash
git mv docs/mangaone-rairairai.xml output/
git mv docs/yanmaga-seijun.xml output/
git mv docs/index.html output/
```

Expected: Files moved with history preserved

**Step 3: Move design documents to docs/**

Run:
```bash
git mv docs/plans/2026-01-25-rss-generator-design.md docs/
git mv docs/plans/2026-01-26-session-summary.md docs/
git mv docs/plans/2026-01-31-directory-restructure-design.md docs/
```

Expected: Design documents moved to docs/ root

**Step 4: Remove empty plans directory**

Run:
```bash
rmdir docs/plans
```

Expected: Directory removed successfully

**Step 5: Verify directory structure**

Run:
```bash
ls -la docs/
ls -la output/
```

Expected:
- `docs/` contains only `.md` files
- `output/` contains `.xml` and `.html` files

**Step 6: Commit directory restructure**

Run:
```bash
git add -A
git commit -m "refactor: restructure directories - move artifacts to output/

Move generated RSS feeds and index.html from docs/ to output/.
Move design documents from docs/plans/ to docs/ root.
This separates documentation from build artifacts."
```

Expected: Changes committed successfully

---

## Task 2: Update bin/generate Script

**Files:**
- Modify: `bin/generate:24` (default output_dir)
- Modify: `bin/generate:13` (help message)

**Step 1: Run existing tests to establish baseline**

Run:
```bash
bundle exec rspec
```

Expected: All tests pass

**Step 2: Update default output directory**

In `bin/generate` line 24, change:
```ruby
# Before
output_dir = ARGV[1] || "docs"

# After
output_dir = ARGV[1] || "output"
```

**Step 3: Update help message**

In `bin/generate` line 13, change:
```ruby
# Before
      output_dir   Output directory for RSS feeds (default: docs)

# After
      output_dir   Output directory for RSS feeds (default: output)
```

**Step 4: Run tests to verify no breakage**

Run:
```bash
bundle exec rspec
```

Expected: All tests still pass (tests use `tmp/docs` which is independent)

**Step 5: Test script manually**

Run:
```bash
bundle exec ruby bin/generate --help
```

Expected: Help message shows `(default: output)`

**Step 6: Commit script changes**

Run:
```bash
git add bin/generate
git commit -m "refactor: change default output directory to output/

Update bin/generate to use output/ as default directory instead of docs/.
This aligns with the new directory structure."
```

Expected: Changes committed successfully

---

## Task 3: Update GitHub Actions Workflow

**Files:**
- Modify: `.github/workflows/generate.yml:38`

**Step 1: Update git add command**

In `.github/workflows/generate.yml` line 38, change:
```yaml
# Before
          git add docs/

# After
          git add output/
```

**Step 2: Verify workflow file syntax**

Run:
```bash
cat .github/workflows/generate.yml | grep "git add"
```

Expected: Output shows `git add output/`

**Step 3: Commit workflow changes**

Run:
```bash
git add .github/workflows/generate.yml
git commit -m "ci: update GitHub Actions to commit output/ directory

Change workflow to add and commit output/ instead of docs/.
This ensures generated feeds are tracked in the new location."
```

Expected: Changes committed successfully

---

## Task 4: Update README.md Documentation

**Files:**
- Modify: `README.md` (multiple sections)

**Step 1: Update output section (around L81-84)**

Find and replace in `README.md`:
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

**Step 2: Update GitHub Pages section (around L92-96)**

Find and replace in `README.md`:
```markdown
# Before
3. Branch: `main` (or `master`) / `docs`

# After
3. Branch: `main` (or `master`) / `output`
```

**Step 3: Update directory structure diagram (around L107-123)**

Find and replace in `README.md`:
```markdown
# Before
├── docs/                  # 生成された RSS フィード

# After
├── docs/                  # 設計ドキュメント
├── output/                # 生成された RSS フィード（GitHub Pages）
```

**Step 4: Verify README changes**

Run:
```bash
grep -n "output/" README.md
```

Expected: Multiple lines showing `output/` references

**Step 5: Commit README updates**

Run:
```bash
git add README.md
git commit -m "docs: update README to reflect new directory structure

Update all references from docs/ to output/ for generated artifacts.
Clarify that docs/ now contains design documents only."
```

Expected: Changes committed successfully

---

## Task 5: Verification and Testing

**Step 1: Run full test suite**

Run:
```bash
bundle exec rspec
```

Expected: All tests pass

**Step 2: Generate feeds with new structure**

Run:
```bash
bundle exec ruby bin/generate
```

Expected: Feeds generated successfully in `output/` directory

**Step 3: Verify output files exist**

Run:
```bash
ls -la output/*.xml output/*.html
```

Expected: All feed files present in output/

**Step 4: Check git status**

Run:
```bash
git status
```

Expected: Working tree clean (all changes committed)

**Step 5: Verify commit history**

Run:
```bash
git log --oneline -5
```

Expected: 4 new commits visible:
1. Update README
2. Update GitHub Actions
3. Update bin/generate
4. Restructure directories

---

## Post-Implementation Manual Steps

**These steps require manual intervention in GitHub UI:**

### Step 1: Push changes to GitHub

Run:
```bash
git push origin master
```

### Step 2: Update GitHub Pages Configuration

1. Navigate to repository Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: `master` / `/output`
4. Click "Save"

### Step 3: Verify GitHub Pages Deployment

1. Wait 2-3 minutes for deployment
2. Visit GitHub Pages URL
3. Verify RSS feeds are accessible

### Step 4: Test GitHub Actions Workflow

1. Go to Actions tab
2. Select "Generate RSS Feeds"
3. Click "Run workflow"
4. Verify workflow completes successfully
5. Check that new commits go to `output/` directory

---

## Rollback Plan (If Needed)

If issues arise:

1. **Revert code changes:**
   ```bash
   git revert HEAD~4..HEAD
   git push origin master
   ```

2. **Revert GitHub Pages settings:**
   - Settings → Pages → Branch: `master` / `/docs`

3. **Regenerate feeds in old location:**
   ```bash
   bundle exec ruby bin/generate config/sites.yml docs
   git add docs/
   git commit -m "Restore docs/ location temporarily"
   git push
   ```

---

## Success Criteria

✅ All files properly moved with git history preserved
✅ All tests passing
✅ Feeds generate successfully in `output/` directory
✅ Documentation updated and accurate
✅ GitHub Actions workflow updated
✅ No broken references or dead links
✅ Clear separation: `docs/` = documentation, `output/` = artifacts
