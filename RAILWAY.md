# Railway Deployment Guide

This guide explains how to deploy both the frontend and backend services to Railway when using subdirectories as root directories.

## Problem

When Railway sets the root directory to `apps/api` or `apps/shop`, running `npm install` in those directories fails because workspace packages like `@org/api-products` and `@org/models` are not found in the npm registry - they're local workspace packages defined in the repository root.

## Solution

The issue is that Railway automatically runs `npm install` in the root directory (`apps/api` or `apps/shop`), which fails because workspace packages aren't in the npm registry.

**Option 1: Use Custom Build Commands (Recommended)**

Configure Railway to skip automatic npm install and use custom build commands that install from the repository root:

1. In Railway project settings, disable "Auto-detected Build Command" or set it to empty
2. Use the build commands below that navigate to root and install there

**Option 2: Configure Install Command**

If Railway doesn't allow skipping install, you can try setting a custom install command:
- Install Command: `cd ../.. && npm ci` (for both services)
- Then use the build commands below

## Backend Service Configuration

**Root Directory:** `apps/api`

**If Railway allows custom install command:**
- Install Command: `cd ../.. && npm ci`
- Build Command: `cd ../.. && npx nx build api --configuration=production`
- Start Command: `node dist/main.js`

**If Railway runs install automatically (and it fails):**
You have two options:

1. **Skip install, use build command only:**
   - Disable automatic install in Railway settings
   - Build Command: `cd ../.. && npm ci && npx nx build api --configuration=production`
   - Start Command: `node dist/main.js`

2. **Use npm scripts (if Railway allows):**
   - Build Command: `npm run railway:build`
   - Start Command: `npm run railway:start`

## Frontend Service Configuration

**Root Directory:** `apps/shop`

**Build Command:**
```bash
cd ../.. && npm ci && npx nx build shop --configuration=production
```

**Start Command:**
For a static React app, you'll need a static file server. Options:

1. **Using serve (recommended):**
   ```bash
   npx serve -s dist -l $PORT
   ```
   Add `serve` to `apps/shop/package.json` dependencies or install it globally.

2. **Using Railway's static site feature:**
   - Set the output directory to `dist`
   - Railway will automatically serve static files

**Alternative (using npm script):**
- Build Command: `npm run railway:build`

## Environment Variables

### Backend (`apps/api`)
- `PORT` - Port to run the API server (default: 3333)
- `HOST` - Host to bind to (default: localhost, use `0.0.0.0` for Railway)

### Frontend (`apps/shop`)
- `PORT` - Port for the static server (if using serve)
- `VITE_API_URL` - API endpoint URL (if your frontend needs to know the API URL)

## How It Works

1. The build command navigates to the repository root (`cd ../..`)
2. Runs `npm ci` from the root, which installs all dependencies and resolves workspace packages
3. Uses Nx to build the specific app, which handles all workspace dependencies correctly
4. The built output is in the app's `dist` directory
5. The start command runs from the app directory using the built output

## Troubleshooting

If you still get 404 errors for workspace packages:

1. **Railway runs npm install automatically:** Railway may try to run `npm install` in `apps/api` before your build command. To fix:
   - Go to Railway project settings → Service → Settings
   - Look for "Build Command" or "Install Command" settings
   - Either disable automatic install, or set install command to: `cd ../.. && npm ci`
   - Or use Railway's "Nixpacks" buildpack settings to customize the install step

2. **Verify root directory:** Make sure Railway's root directory is set correctly (`apps/api` or `apps/shop`)

3. **Check build command:** Ensure the build command navigates to root (`cd ../..`)

4. **Verify workspace configuration:** Check that `package.json` in the repository root has the correct `workspaces` array

5. **Check Nx installation:** Ensure `nx` is installed in the root `package.json` devDependencies

6. **Alternative: Use repository root:** If the above doesn't work, consider changing Railway root directory to `/` (repository root) and adjust build/start commands accordingly (see "Alternative: Use Repository Root" section)

## Alternative: Use Repository Root

If you prefer, you can set both Railway services to use the repository root (`/`) as the root directory:

**Backend:**
- Root Directory: `/`
- Build Command: `npm ci && npx nx build api --configuration=production`
- Start Command: `node apps/api/dist/main.js`

**Frontend:**
- Root Directory: `/`
- Build Command: `npm ci && npx nx build shop --configuration=production`
- Start Command: `npx serve -s apps/shop/dist -l $PORT`

This approach is simpler but requires changing your Railway configuration.

