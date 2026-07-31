# Supabase CLI Fedora RPM Repository

This project tracks the latest official Supabase CLI RPM release, generates DNF/YUM repository metadata, and deploys the finished repository to GitHub Pages at:

`https://supabase-fedora-repo.interhosting.us`

## Install Supabase CLI

### DNF5 — current Fedora releases

```bash
sudo dnf config-manager addrepo --from-repofile=https://supabase-fedora-repo.interhosting.us/supabase.repo
sudo dnf install supabase -y
```

### DNF4 — older Fedora/RHEL releases

```bash
sudo dnf config-manager -- --add-repo https://supabase-fedora-repo.interhosting.us/supabase.repo
sudo dnf install supabase -y
```

### Manual fallback

Use this when `config-manager` is unavailable:

```bash
curl -fsSL https://supabase-fedora-repo.interhosting.us/supabase.repo \
  | sudo tee /etc/yum.repos.d/supabase.repo >/dev/null

sudo dnf install supabase -y
```

The exact repository definition is checked into this project as `supabase.repo` and copied unchanged into the deployed Pages artifact.

You can verify the live response before adding it:

```bash
curl -fsSLD /tmp/supabase-repo.headers \
  https://supabase-fedora-repo.interhosting.us/supabase.repo \
  -o /tmp/supabase.repo

sed -n '1,10p' /tmp/supabase.repo
```

The first line must be `[supabase]`.

## Deployment setup

1. Create a public GitHub repository and push these files to its `main` branch.
2. Open **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**. This workflow does not create or use a `gh-pages` branch.
4. Under **Custom domain**, enter `supabase-fedora-repo.interhosting.us` and click **Save**.
5. Configure Cloudflare DNS with this exact record:
   - **Type:** `CNAME`
   - **Name:** `supabase-fedora-repo`
   - **Target:** `jamone19.github.io`
   - **Proxy status:** **DNS only** (gray cloud)
   - **TTL:** `Auto`
6. Wait for **DNS check successful** in GitHub Pages, then enable **Enforce HTTPS** when it becomes available.
7. Open **Actions → Sync Supabase CLI RPMs → Run workflow**.

Because this project publishes through a custom GitHub Actions workflow, GitHub Pages ignores a repository `CNAME` file for domain assignment. The hostname must be entered under **Settings → Pages → Custom domain**. The checked-in `CNAME` file in this repository is used only by `build_repo.sh` as the canonical hostname for generated URLs.

To verify the Cloudflare record after saving it as DNS only:

```bash
dig supabase-fedora-repo.interhosting.us CNAME +short
```

Expected output:

```text
jamone19.github.io.
```

If your local resolver still returns no answer, bypass its negative cache:

```bash
dig @1.1.1.1 supabase-fedora-repo.interhosting.us CNAME +short
dig @rafe.ns.cloudflare.com supabase-fedora-repo.interhosting.us CNAME +short
```

The workflow downloads the latest official RPM, generates `repodata`, validates `supabase.repo`, uploads the `public` directory as a Pages artifact, and deploys it. It then tests both the GitHub Pages deployment URL and the exact custom-domain URL with a DNF-like user agent.

## Repository layout

```text
.github/workflows/sync.yml  GitHub Actions synchronization and Pages deployment
build_repo.sh               RPM download, metadata generation, and site build
supabase.repo               Exact DNF/YUM repository definition deployed by the workflow
CNAME                       Canonical hostname consumed by build_repo.sh
README.md                   Installation and deployment documentation
```

## Troubleshooting an invalid repo response

If DNF reports `Missing section header on line 1`, the downloaded response is not the checked-in `supabase.repo` file. Capture the HTTP headers and body:

```bash
curl -sSLD /tmp/supabase-repo.headers \
  -A 'libdnf5 (Fedora Linux; x86_64)' \
  https://supabase-fedora-repo.interhosting.us/supabase.repo \
  -o /tmp/supabase.repo

cat /tmp/supabase-repo.headers
sed -n '1,30p' /tmp/supabase.repo
```

The body must begin with `[supabase]`. If it contains HTML, a redirect page, or an access-denied response, correct the GitHub Pages custom-domain/DNS configuration or any CDN/WAF rule in front of it. For a GitHub Actions publishing source, configure the custom domain in **Settings → Pages** and point the DNS CNAME directly to `<YOUR-GITHUB-USERNAME>.github.io`.

After the workflow passes its custom-domain verification, remove any failed temporary copy and retry:

```bash
sudo rm -f /etc/yum.repos.d/supabase.repo*
sudo dnf config-manager addrepo \
  --from-repofile=https://supabase-fedora-repo.interhosting.us/supabase.repo
```
