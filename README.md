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
5. In Cloudflare DNS, configure this record:
   - **Type:** `CNAME`
   - **Name:** `supabase-fedora-repo`
   - **Target:** `jamone19.github.io`
   - **Proxy status:** **DNS only** — gray cloud
   - **TTL:** Auto
6. Return to **Settings → Pages** and wait for **DNS check successful**. GitHub then requests and installs a TLS certificate for the custom domain.
7. When the option becomes available, enable **Enforce HTTPS**.
8. Open **Actions → Sync Supabase CLI RPMs → Run workflow**.

The workflow downloads the latest official RPM, generates `repodata`, validates `supabase.repo`, uploads the `public` directory as a Pages artifact, and deploys it. It verifies the custom-domain HTTP URL. While GitHub is provisioning the certificate, HTTPS is reported as a warning rather than incorrectly marking the deployment as failed. Once GitHub reports the certificate as approved, HTTPS verification becomes strict automatically.

## Repository layout

```text
.github/workflows/sync.yml  GitHub Actions synchronization and Pages deployment
build_repo.sh               RPM download, metadata generation, and site build
supabase.repo               Exact DNF/YUM repository definition deployed by the workflow
CNAME                       Domain value used by the site build (Pages is configured in Settings)
README.md                   Installation and deployment documentation
```

## HTTPS certificate provisioning

A Pages deployment can finish before GitHub has issued the certificate for a newly configured custom domain. During that window, HTTP may work while HTTPS fails with:

```text
SSL: no alternative certificate subject name matches target host name
```

That message means GitHub's current certificate does not yet include `supabase-fedora-repo.interhosting.us`; it does not mean the RPM repository artifact failed to deploy.

Keep the Cloudflare record on **DNS only**, confirm the exact domain under **Settings → Pages**, wait for the DNS check and certificate to complete, and then enable **Enforce HTTPS**.

Inspect GitHub's current Pages state with:

```bash
curl -fsSL \
  -H 'Accept: application/vnd.github+json' \
  -H 'X-GitHub-Api-Version: 2026-03-10' \
  https://api.github.com/repos/jamone19/supabase-fedora-repo/pages \
  | jq '{cname, protected_domain_state, https_certificate, https_enforced}'
```

The desired values are an approved certificate and HTTPS enforcement enabled.

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
