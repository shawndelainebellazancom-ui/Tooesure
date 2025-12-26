#!/bin/bash
set -e

echo "Installing .NET 10..."
curl -sSL https://dot.net/v1/dotnet-install.sh > dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh -c 10.0 -InstallDir ./dotnet
export DOTNET_ROOT=$(pwd)/dotnet
export PATH=$DOTNET_ROOT:$PATH

echo "Generating nuget.config..."
cat > nuget.config <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
  </packageSources>
</configuration>
EOF

PROJECT_FILE=$(ls *.csproj | head -n 1)
if [ -z "$PROJECT_FILE" ]; then
  echo "ERROR: No .csproj file found."
  exit 1
fi

echo "Restoring packages..."
dotnet restore "$PROJECT_FILE" --configfile nuget.config

echo "Publishing..."
dotnet publish "$PROJECT_FILE" -c Release -o publish

echo "Build complete."
