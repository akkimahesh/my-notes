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