# Supabase CLI Fedora RPM Repository

This project tracks the latest official Supabase CLI RPM release, generates DNF/YUM repository metadata, and deploys the finished repository to GitHub Pages at:

`https://supabase-repo.interhosting.us`

## Install Supabase CLI

### DNF5 — current Fedora releases

```bash
sudo dnf config-manager addrepo --from-repofile=https://supabase-repo.interhosting.us/supabase.repo
sudo dnf install supabase -y
```

### DNF4 — older Fedora/RHEL releases

```bash
sudo dnf config-manager -- --add-repo https://supabase-repo.interhosting.us/supabase.repo
sudo dnf install supabase -y
```

### Manual fallback

Use this when `config-manager` is unavailable:

```bash
curl -fsSL https://supabase-repo.interhosting.us/supabase.repo \
  | sudo tee /etc/yum.repos.d/supabase.repo >/dev/null

sudo dnf install supabase -y
```

The downloaded file must begin with a repository section header:

```ini
[supabase]
name=Supabase CLI Repository
baseurl=https://supabase-repo.interhosting.us/x86_64/
enabled=1
type=rpm-md
gpgcheck=0
repo_gpgcheck=0
```

You can verify the live response before adding it:

```bash
curl -fsSL https://supabase-repo.interhosting.us/supabase.repo | sed -n '1,10p'
```

The first line must be `[supabase]`. HTML, a 404 page, or any other first line means the custom domain is not serving the generated GitHub Pages artifact.

## Deployment setup

1. Create a public GitHub repository and push these files to its `main` branch.
2. Open **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**. This workflow does not create or use a `gh-pages` branch.
4. Under **Custom domain**, enter `supabase-repo.interhosting.us`.
5. Configure DNS with a CNAME record:
   - **Name:** `supabase-repo`
   - **Target:** `<YOUR-GITHUB-USERNAME>.github.io`
6. Open **Actions → Sync Supabase CLI RPMs → Run workflow**.

The workflow downloads the latest official RPM, generates `repodata`, validates `supabase.repo`, uploads the `public` directory as a Pages artifact, deploys it, and then verifies that the deployed `.repo` file begins with `[supabase]`.

## Repository layout

```text
.github/workflows/sync.yml  GitHub Actions synchronization and Pages deployment
build_repo.sh               RPM download, metadata generation, and site build
CNAME                       GitHub Pages custom domain
README.md                   Installation and deployment documentation
```

## Troubleshooting an invalid repo file

If DNF reports `Missing section header on line 1`, inspect the URL directly:

```bash
curl -fsSL https://supabase-repo.interhosting.us/supabase.repo -o /tmp/supabase.repo
sed -n '1,10p' /tmp/supabase.repo
```

The first line must be `[supabase]`. After deploying this revision, remove any invalid local copy before retrying:

```bash
sudo rm -f /etc/yum.repos.d/supabase.repo
sudo dnf config-manager addrepo \
  --from-repofile=https://supabase-repo.interhosting.us/supabase.repo
```
