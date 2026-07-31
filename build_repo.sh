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

# Generate a plain-text, INI-formatted DNF/YUM repository definition.
REPO_FILE="public/supabase.repo"
cat > "$REPO_FILE" <<REPO_EOF
[supabase]
name=Supabase CLI Repository
baseurl=https://${DOMAIN}/x86_64/
enabled=1
type=rpm-md
gpgcheck=0
repo_gpgcheck=0
REPO_EOF

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

<<<<<<< HEAD
# Create the static installation page.
=======
# 3. Create static HTML user installation manual page 
>>>>>>> d625c712861fea177fe5375729ec5d0112c20bd1
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
        .note { background: #fff8c5; border: 1px solid #d4a72c; border-radius: 6px; padding: 12px 14px; }
    </style>
</head>
<body>
    <h1>Supabase CLI Custom RPM Repository</h1>
    <div class="version-badge">Latest Synced: v${VERSION}</div>
    <p>This repository provides a native Fedora/RHEL-compatible RPM package for the official Supabase CLI and synchronizes it automatically.</p>

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

    <p class="note"><strong>Repository file check:</strong> <code>https://${DOMAIN}/supabase.repo</code> must begin with <code>[supabase]</code>. If it displays HTML or an error page, the Pages deployment or custom-domain routing is not serving the generated artifact.</p>

    <p style="margin-top: 40px; font-size: 0.85em; color: #586069; border-top: 1px solid #e1e4e8; padding-top: 20px;">
        Automated synchronization and deployment are managed through GitHub Actions.
    </p>
</body>
</html>
HTML_EOF
<<<<<<< HEAD
=======

>>>>>>> d625c712861fea177fe5375729ec5d0112c20bd1
