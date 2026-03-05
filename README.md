# Qualys CLI

A unified command line interface for Qualys Cloud Platform services. Built with TypeScript and Bun, following AWS CLI architecture patterns.

## Quick Start

### Install

```bash
# One liner install (auto detects OS and architecture)
curl -fsSL https://raw.githubusercontent.com/valllabh/qualys-cli/main/download.sh | bash

```

Or download manually from [Releases](https://github.com/valllabh/qualys-cli/releases):

| Platform | Binary |
|---|---|
| macOS (Apple Silicon) | `qualys-darwin-arm64` |
| macOS (Intel) | `qualys-darwin-x64` |
| Linux (x64) | `qualys-linux-x64` |
| Linux (ARM64) | `qualys-linux-arm64` |
| Windows (x64) | `qualys-windows-x64.exe` |

### Update

```bash
# Check for updates and upgrade
qualys update

# Auto confirm without prompt
qualys update --yes
```

The CLI also shows a notification when a new version is available.

### Configure

```bash
# Interactive setup
qualys auth

# Non-interactive setup (password auth)
qualys auth --pod us1 --method password --username <user> --password <pass>

# Non-interactive setup (OIDC auth)
qualys auth --pod us1 --method oidc --client-id <id> --client-secret <secret>

# See detailed auth help
qualys auth --help
```

### Usage

```bash
# List available services
qualys --help

# TotalAppSec operations
qualys tas search-web-apps --output table
qualys tas launch-scan --input-json '{"webAppId": 12345}'
qualys tas search-findings --filter '{"scanQql": "finding.severity > 3"}'

# Per command help with parameters
qualys tas search-scans --help

# QQL syntax reference
qualys docs qql

# Output formats
qualys tas search-web-apps --output json
qualys tas search-web-apps --output table
qualys tas search-web-apps --output csv

# JMESPath query filtering
qualys tas search-web-apps --query "data[?status=='ACTIVE'].name"

# Shell tab completion
eval "$(qualys completion)"
```

## Authentication

Two methods are supported:

**Password Auth** (username/password): Qualys account credentials used to obtain a JWT token. The token is automatically refreshed every 4 hours.

**OIDC / Passwordless Auth** (Client ID/Secret): Client ID and secret for machine to machine authentication. Designed for CI/CD pipelines and automated integrations.

Credentials are resolved in order: CLI flags, credentials file (`~/.qualys/credentials`).

Run `qualys auth --help` for detailed information on each method, including how to enable OIDC.

### Profiles

```bash
# Configure a named profile
qualys auth --profile production

# Use a profile
qualys tas search-web-apps --profile production
```

### Platforms

| Platform | Data Center |
|---|---|
| qg1 | US Platform 1 |
| qg2 | US Platform 2 |
| qg3 | US Platform 3 |
| qg4 | US Platform 4 |
| eu1 | EU Platform 1 |
| eu2 | EU Platform 2 |
| in1 | India Platform 1 |
| ae1 | UAE Platform 1 |
| uk1 | UK Platform 1 |
| au1 | Australia Platform 1 |
| ca1 | Canada Platform 1 |
| jp1 | Japan Platform 1 |

## Services

### TotalAppSec (`tas`)

Web application and API security scanning.

```bash
# Web Apps
qualys tas search-web-apps
qualys tas create-web-app --input-json '{"name": "My App", "url": "https://example.com"}'
qualys tas get-web-app-by-id --id 12345

# Scans
qualys tas launch-scan --input-json '{"webAppId": 12345}'
qualys tas search-scans
qualys tas get-scan-status --id 67890

# Findings
qualys tas search-findings --filter '{"scanQql": "finding.severity >= 4"}'
qualys tas count-findings

# APIs
qualys tas search-apis
qualys tas create-api --input-json '{"name": "My API", "url": "https://api.example.com"}'
```

## License

Proprietary
