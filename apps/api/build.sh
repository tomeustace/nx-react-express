#!/bin/bash
set -e

# Navigate to repository root
cd "$(dirname "$0")/../.."

# Install dependencies from root (where workspaces are defined)
npm ci

# Build the API with Nx (handles workspace dependencies)
npx nx build api --configuration=production

