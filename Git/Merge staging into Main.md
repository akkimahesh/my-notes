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