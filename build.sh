#!/bin/bash
set -e  # Exit on any error

# 1. Install .NET 10
echo "Installing .NET 10..."
curl -sSL https://dot.net/v1/dotnet-install.sh > dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh -c 10.0 -InstallDir ./dotnet
export DOTNET_ROOT=$(pwd)/dotnet
export PATH=$DOTNET_ROOT:$PATH

# 2. GENERATE CONFIG MANUALLY
echo "Generating secure nuget.config..."
if [ -z "$TELERIK_NUGET_KEY" ]; then
  echo "ERROR: TELERIK_NUGET_KEY environment variable is missing."
  exit 1
fi

ESCAPED_KEY=$(echo "$TELERIK_NUGET_KEY" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

cat > nuget.config <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="TelerikFeed" value="https://nuget.telerik.com/v3/index.json" protocolVersion="3" />
  </packageSources>
  <packageSourceCredentials>
    <TelerikFeed>
      <add key="Username" value="api-key" />
      <add key="ClearTextPassword" value="${ESCAPED_KEY}" />
    </TelerikFeed>
  </packageSourceCredentials>
</configuration>
EOF

# 3. BUILD
PROJECT_FILE=$(ls website/*.csproj | head -n 1)
if [ -z "$PROJECT_FILE" ]; then
  echo "ERROR: No .csproj file found."
  exit 1
fi

echo "Restoring NuGet packages..."
dotnet restore "$PROJECT_FILE" --configfile nuget.config

echo "Publishing project..."
# Note: Publish directly to the output folder Cloudflare expects
dotnet publish "$PROJECT_FILE" -c Release -o output/wwwroot

# 4. CLOUDFLARE CONFIGURATION (The Fix)
echo "Copying Cloudflare configuration files..."
# Check if files exist in the website root, then copy them
if [ -f "website/_headers" ]; then
    cp website/_headers output/wwwroot/_headers
    echo "_headers copied."
fi

if [ -f "website/_redirects" ]; then
    cp website/_redirects output/wwwroot/_redirects
    echo "_redirects copied."
fi

echo "Build complete. Output directory: output/wwwroot"