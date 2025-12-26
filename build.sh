#!/bin/bash
set -e  # Exit on any error

# 1. Install .NET 10
echo "Installing .NET 10..."
curl -sSL https://dot.net/v1/dotnet-install.sh > dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh -c 10.0 -InstallDir ./dotnet
export DOTNET_ROOT=$(pwd)/dotnet
export PATH=$DOTNET_ROOT:$PATH

# 2. GENERATE CONFIG MANUALLY (Safe for Special Characters)
echo "Generating secure nuget.config..."
if [ -z "$TELERIK_NUGET_KEY" ]; then
  echo "ERROR: TELERIK_NUGET_KEY environment variable is missing."
  echo "Please set it in Cloudflare Pages environment variables."
  exit 1
fi

# XML-escape special characters in the API key
# This handles &, <, >, ", and ' characters
ESCAPED_KEY=$(echo "$TELERIK_NUGET_KEY" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

# Write the XML directly with escaped variable
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

echo "nuget.config created successfully."

# 3. VERIFY & BUILD
PROJECT_FILE=$(ls *.csproj | head -n 1)
if [ -z "$PROJECT_FILE" ]; then
  echo "ERROR: No .csproj file found in repository root."
  exit 1
fi

echo "Targeting: $PROJECT_FILE"

# Restore packages with explicit config file
echo "Restoring NuGet packages..."
dotnet restore "$PROJECT_FILE" --configfile nuget.config

# Publish the project to output/wwwroot (matching Cloudflare Pages setting)
echo "Publishing project..."
dotnet publish "$PROJECT_FILE" -c Release -o output

echo "Build complete. Output directory: output/wwwroot"