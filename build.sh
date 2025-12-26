#!/bin/bash
set -e

echo "Installing .NET 10..."
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0

export DOTNET_ROOT=$HOME/dotnet
export PATH=$DOTNET_ROOT:$PATH

echo "Generating secure nuget.config..."
cat > nuget.config << EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="Telerik" value="https://nuget.telerik.com/v3/index.json" protocolVersion="3" />
  </packageSources>
  <packageSourceCredentials>
    <Telerik>
      <add key="Username" value="api-key" />
      <add key="ClearTextPassword" value="$TELERIK_NUGET_KEY" />
    </Telerik>
  </packageSourceCredentials>
</configuration>
EOF
echo "nuget.config created successfully."

echo "Targeting: website.csproj"

echo "Installing wasm-tools workload..."
dotnet workload install wasm-tools

echo "Restoring NuGet packages..."
dotnet restore website.csproj

echo "Publishing project..."
dotnet publish website.csproj -c Release -o output

echo "Build completed successfully!"
echo "Output directory: output/wwwroot"