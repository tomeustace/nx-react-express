#!/bin/bash
set -e

# Navigate to repository root
cd "$(dirname "$0")/../.."

# Install dependencies from root (where workspaces are defined)
npm ci

# Build the shop app with Nx (handles workspace dependencies)
npx nx build shop --configuration=production

