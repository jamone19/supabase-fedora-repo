#!/bin/bash
set -e

# Establish variables passed from the workflow env
VERSION=$1
RPM_NAME=$2
RPM_URL=$3

mkdir -p x86_64
DOMAIN=$(cat CNAME)

# Download package if it doesn't exist locally
if [ ! -f "x86_64/${RPM_NAME}" ]; then
  echo "Downloading new version: ${VERSION}"
  wget -q "${RPM_URL}" -O "x86_64/${RPM_NAME}"
fi

# 1. Generate local repository profile file
echo "[supabase]" > supabase.repo
echo "name=Supabase CLI Repository" >> supabase.repo
echo "baseurl=https://${DOMAIN}/x86_64/" >> supabase.repo
echo "enabled=1" >> supabase.repo
echo "gpgcheck=0" >> supabase.repo

# 2. Compile indexes
createrepo_c x86_64/

# 3. Generate HTML document stream 
cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Supabase CLI Fedora RPM Repository</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; max-width: 700px; margin: 40px auto; padding: 0 20px; color: #24292e; background-color: #fafbfc; }
        h1 { border-bottom: 1px solid #e1e4e8; padding-bottom: 10px; color: #1a1a1a; }
        code { background-color: #f1f2f4; padding: 3px 6px; font-family: sfmono-regular, consolas, liberation mono, menlo, monospace; font-size: 85%; border-radius: 3px; color: #d73a49; }
        pre { background: #f6f8fa; padding: 16px; overflow: auto; font-size: 85%; line-height: 1.45; border-radius: 6px; border: 1px solid #e1e4e8; }
        pre code { background: none; padding: 0; color: #24292e; font-size: 100%; }
        .version-badge { display: inline-block; background-color: #34d399; color: #064e3b; padding: 2px 8px; font-weight: bold; border-radius: 20px; font-size: 0.8rem; margin-bottom: 10px; }
    </style>
</head>
<body>
    <h1>Supabase CLI Custom RPM Repository</h1>
    <div class="version-badge">Latest Synced: v${VERSION}</div>
    <p>This repository provides native Fedora/RHEL/CentOS RPM package hosting for the official Supabase CLI tool, synchronized daily.</p>
    
    <h2>Installation Instructions</h2>
    <p>Run the following command to download your system's <code>.repo</code> configuration mapping file and immediately install the package:</p>
    
    <pre><code># 1. Fetch and install the repository config file
sudo dnf config-manager --add-repo https://${DOMAIN}/supabase.repo

# 2. Install the Supabase CLI package
sudo dnf install supabase -y</code></pre>

    <p><em>Note: If you run an older version of Fedora or RHEL missing dnf config-manager, use this alternative single command block instead:</em></p>
    
    <pre><code>sudo tee /etc/yum.repos.d/supabase.repo &lt;&lt; 'EOF'
[supabase]
name=Supabase CLI Repository
baseurl=https://${DOMAIN}/x86_64/
enabled=1
gpgcheck=0
EOF

sudo dnf install supabase -y</code></pre>

    <p style="margin-top: 40px; font-size: 0.85em; color: #586069; border-top: 1px solid #e1e4e8; padding-top: 20px;">
        Automated sync script managed via GitHub Actions. Maintainer updates are pushed directly to this domain.
    </p>
</body>
</html>
EOF

