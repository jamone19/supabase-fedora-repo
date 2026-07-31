# Supabase CLI Fedora RPM Repository

This repository automatically tracks the official Supabase CLI releases, builds DNF/YUM repository metadata, and hosts everything via your custom subdomain.

## Installation Client Setup
```bash
sudo tee /etc/yum.repos.d/supabase.repo << 'EOF'
[supabase]
name=Supabase CLI Repository
baseurl=https://interhosting.us
enabled=1
gpgcheck=0
EOF

sudo dnf install supabase -y
```

---

### 🚀 Step-by-Step Deployment Guide

Follow these mechanical steps to bind this repository configuration to your live subdomain:

1. **Create the GitHub Repo:** Create a blank, **Public** repository on GitHub. Push the code files provided above directly to your `main` branch.
2. **Authorize GitHub Action Permissions:** 
   * Navigate to your repo's **Settings** -> **Actions** -> **General**.
   * Scroll to *Workflow permissions* and switch it to **Read and write permissions**. Click **Save**.
3. **Trigger Your First Build:** Go to the **Actions** tab inside GitHub, select the *Sync Supabase CLI RPMs* workflow, and click **Run workflow**. This will populate your repository's backend data and automatically generate a new remote branch named `gh-pages`.
4. **Link GitHub Pages to the Build Branch:**
   * Go to **Settings** -> **Pages**.
   * Under *Build and deployment*, change the source to **Deploy from a branch**.
   * Select **`gh-pages`** as your source target and click **Save**.
5. **Attach Your DNS Subdomain:**
   * On that same **Pages** menu, locate the **Custom Domain** input box.
   * Input your custom address (e.g., `supabase-fedora-repo.interhosting.us`) and click **Save**.
6. **Configure DNS Records:** Log into your primary DNS management dashboard (e.g., Cloudflare, Route53, Namecheap) and issue an authoritative steering record:
   * **Type:** `CNAME`
   * **Host/Name:** `supabase-fedora-repo` *(or your preferred prefix)*
   * **Value/Target:** `<YOUR-GITHUB-USERNAME>.github.io`
   * **TTL:** `Auto` or `3600`


