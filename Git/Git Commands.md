# Git Useful Commands Guide

## 1. Revert Latest Commit (Safe Rollback)

If code was pushed by mistake to `main` or `staging`:

```bash
git revert HEAD
git push origin main   # Confirm branch before pushing
```

### What it does

* Creates a new commit that reverses the latest commit
* Safe for shared branches
* Keeps Git history intact

### Note

This may remove changes/files from:

* Local branch
* Remote branch

because Git is reversing the previous commit changes.

---

## 2. Undo Latest Commit Without Removing Local Files

If you want to:

* Keep files locally
* Remove latest commit from remote

Use:

```bash
git reset --soft HEAD~1
```

### Then push carefully

```bash
git push --force origin main
```

### What it does

* Removes latest commit
* Keeps all files and changes locally
* Requires force push because remote history changes

⚠️ Use `--force` carefully on shared branches.

---

# Branch Push & Delete Commands

## Push Local `staging` Branch to Remote

```bash
git push -u origin staging
```

### What it does

* Pushes local `staging` branch to remote
* Creates remote branch if it does not exist
* Sets upstream tracking

After this, you can use:

```bash
git push
git pull
```

without specifying branch name.

---

## Delete Remote `staging` Branch

```bash
git push origin --delete staging
```

### What it does

* Deletes `staging` branch from remote repository
* Local branch still remains

---

## Delete Local Branch

```bash
git branch -d staging
```

### What it does

* Deletes local branch safely
* Works only if branch is already merged

---

## Force Delete Local Branch

```bash
git branch -D staging
```

### What it does

* Force deletes local branch
* Deletes even if not merged

---

# Merge `staging` Branch Into `main`

```bash
git clone <repo-url>
cd <repo-name>

git checkout main
git merge origin/staging
git push origin main
```

### What it does

* Switches to `main`
* Merges remote `staging` branch into `main`
* Pushes updated `main` branch to remote

Flow:

```text
staging  --->  main
```

---

# Recover Previous Working State After Failed Pull/Build

If:

* `git pull` was done on server
* Build/deployment failed
* Need to rollback previous working code

Use:

```bash
git reflog
```

### Example Output

```bash
HEAD@{0}   # Current state
HEAD@{1}   # Previous working state
```

---

## Rollback to Previous State

```bash
git reset --hard HEAD@{1}
```

or using commit ID:

```bash
git reset --hard def5678
```

### What it does

* Restores repository to previous working commit
* Removes current broken changes completely

⚠️ `--hard` removes:

* Uncommitted changes
* Modified files
* Current working state

Use carefully.

---

Relevant software entities:

* Git
* GitHub

# Merge `mahesh` Branch Changes into `staging`

If all your changes are currently in your local `mahesh` branch and you want to merge them into `staging` and push them to GitHub, follow these steps.

## 1. Check Your Current Branch and Changes

```bash
git status
git branch
```

Make sure you are on the `mahesh` branch and your changes are committed.

If your changes are not committed:

```bash
git add .
git commit -m "Your changes"
```

## 2. Switch to the `staging` Branch

```bash
git switch staging
```

## 3. Get the Latest Changes from GitHub

Before merging, update your local `staging` branch:

```bash
git pull origin staging
```

## 4. Merge `mahesh` into `staging`

```bash
git merge mahesh
```

If there are no conflicts, your `mahesh` changes will now be part of the local `staging` branch.

## 5. Handle Merge Conflicts

If Git reports conflicts, check which files have conflicts:

```bash
git status
```

Open the conflicted files and resolve the conflicts.

Then add the resolved files:

```bash
git add .
```

Commit the merge:

```bash
git commit
```

## 6. Push `staging` to GitHub

After the merge is complete:

```bash
git push origin staging
```

Your changes from `mahesh` will now be available in the remote `staging` branch on GitHub.

## Complete Command Sequence

If all your changes are already committed in `mahesh`, you can use:

```bash
git switch staging
git pull origin staging
git merge mahesh
git push origin staging
```

## Important

Do **not** use:

```bash
git push --force
```

unless you specifically know why it is required. A normal push is safer for a shared `staging` branch.
