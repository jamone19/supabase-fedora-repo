#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <version> <rpm-name> <rpm-url>" >&2
    exit 64
fi

VERSION=$1
RPM_NAME=$2
RPM_URL=$3

# Normalize the custom domain and reject an empty value.
DOMAIN=$(tr -d '\r\n[:space:]' < CNAME)
if [ -z "$DOMAIN" ]; then
    echo "ERROR: CNAME is empty." >&2
    exit 1
fi

# Always build a clean GitHub Pages artifact so stale files cannot survive.
rm -rf public
mkdir -p public/x86_64
printf '%s\n' "$DOMAIN" > public/CNAME
printf '%s\n' > public/.nojekyll

# Fetch the official RPM asset into the repository architecture directory.
echo "Downloading Supabase CLI ${VERSION}: ${RPM_NAME}"
wget -q --https-only "${RPM_URL}" -O "public/x86_64/${RPM_NAME}"

# Publish the checked-in, plain-text DNF/YUM repository definition.
# Keeping this file in the repository makes its exact deployed contents reviewable.
REPO_SOURCE="supabase.repo"
REPO_FILE="public/supabase.repo"
if [ ! -f "$REPO_SOURCE" ]; then
    echo "ERROR: ${REPO_SOURCE} is missing." >&2
    exit 1
fi
install -m 0644 "$REPO_SOURCE" "$REPO_FILE"

# Fail the build if the repo file is malformed or accidentally contains HTML.
if [ "$(sed -n '1p' "$REPO_FILE")" != "[supabase]" ]; then
    echo "ERROR: ${REPO_FILE} does not begin with [supabase]." >&2
    sed -n '1,20p' "$REPO_FILE" >&2
    exit 1
fi

if grep -Eiq '<!doctype|<html|<body' "$REPO_FILE"; then
    echo "ERROR: ${REPO_FILE} contains HTML instead of repository configuration." >&2
    exit 1
fi

if ! grep -Fqx "baseurl=https://${DOMAIN}/x86_64/" "$REPO_FILE"; then
    echo "ERROR: ${REPO_FILE} contains an unexpected baseurl." >&2
    exit 1
fi

# Generate RPM repository metadata.
createrepo_c public/x86_64/

# Create the static installation page.
cat <<HTML_EOF > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Supabase CLI Fedora RPM Repository</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; max-width: 760px; margin: 40px auto; padding: 0 20px; color: #24292e; background-color: #fafbfc; }
        h1 { border-bottom: 1px solid #e1e4e8; padding-bottom: 10px; color: #1a1a1a; }
        h2 { margin-top: 32px; }
        h3 { margin-top: 24px; margin-bottom: 8px; }
        code { background-color: #f1f2f4; padding: 3px 6px; font-family: sfmono-regular, consolas, liberation mono, menlo, monospace; font-size: 85%; border-radius: 3px; color: #d73a49; }
        pre { background: #f6f8fa; padding: 16px; overflow: auto; font-size: 85%; line-height: 1.45; border-radius: 6px; border: 1px solid #e1e4e8; }
        pre code { background: none; padding: 0; color: #24292e; font-size: 100%; }
        .version-badge { display: inline-block; background-color: #34d399; color: #064e3b; padding: 2px 8px; font-weight: bold; border-radius: 20px; font-size: 0.8rem; margin-bottom: 10px; }
        .config-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin: 18px 0; }
        .config-card { background: #fff; border: 1px solid #d8dee4; border-radius: 8px; padding: 18px; }
        .config-card h3 { margin-top: 0; }
        .config-card dl { margin: 0; }
        .config-card dt { font-weight: 700; margin-top: 10px; }
        .config-card dt:first-child { margin-top: 0; }
        .config-card dd { margin: 2px 0 0; overflow-wrap: anywhere; }
        .notice { background: #fff8c5; border: 1px solid #d4a72c; border-radius: 6px; padding: 12px 14px; }
        a { color: #0969da; }
    </style>
</head>
<body>
    <h1>Supabase CLI Custom RPM Repository</h1>
    <div class="version-badge">Latest Synced: v${VERSION}</div>
    <p>This repository provides a native Fedora/RHEL-compatible RPM package for the official Supabase CLI and synchronizes it automatically.</p>

    <h2>Hosting configuration</h2>
    <div class="config-grid">
        <section class="config-card">
            <h3>GitHub Pages</h3>
            <dl>
                <dt>Deployment source</dt>
                <dd>GitHub Actions</dd>
                <dt>Custom domain</dt>
                <dd><code>${DOMAIN}</code></dd>
                <dt>Default project URL</dt>
                <dd><code>https://jamone19.github.io/supabase-fedora-repo/</code></dd>
                <dt>HTTPS</dt>
                <dd>Enable <strong>Enforce HTTPS</strong> after GitHub completes DNS verification.</dd>
            </dl>
        </section>
        <section class="config-card">
            <h3>Cloudflare DNS</h3>
            <dl>
                <dt>Type</dt>
                <dd><code>CNAME</code></dd>
                <dt>Name</dt>
                <dd><code>supabase-fedora-repo</code></dd>
                <dt>Target</dt>
                <dd><code>jamone19.github.io</code></dd>
                <dt>Proxy status</dt>
                <dd><strong>DNS only</strong> — gray cloud</dd>
                <dt>TTL</dt>
                <dd>Auto</dd>
            </dl>
        </section>
    </div>
    <p class="notice"><strong>Important:</strong> Keep the Cloudflare record set to <strong>DNS only</strong>. GitHub must see the underlying CNAME while it verifies and provisions the custom domain.</p>

    <h2>Installation</h2>

    <h3>DNF5 — current Fedora releases</h3>
    <pre><code># Add the repository definition
sudo dnf config-manager addrepo --from-repofile=https://${DOMAIN}/supabase.repo

# Install Supabase CLI
sudo dnf install supabase -y</code></pre>

    <h3>DNF4 — older Fedora/RHEL releases</h3>
    <pre><code># Add the repository definition
sudo dnf config-manager -- --add-repo https://${DOMAIN}/supabase.repo

# Install Supabase CLI
sudo dnf install supabase -y</code></pre>

    <h3>Manual fallback</h3>
    <p>Use this method when <code>config-manager</code> is not installed or available:</p>
    <pre><code>curl -fsSL https://${DOMAIN}/supabase.repo \
  | sudo tee /etc/yum.repos.d/supabase.repo &gt;/dev/null

sudo dnf install supabase -y</code></pre>


    <p style="margin-top: 40px; font-size: 0.85em; color: #586069; border-top: 1px solid #e1e4e8; padding-top: 20px;">
        Automated synchronization and deployment are managed through GitHub Actions.
    </p>
</body>
</html>
HTML_EOF
