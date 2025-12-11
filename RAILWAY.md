# Railway Deployment Guide

This guide explains how to deploy both the frontend and backend services to Railway when using subdirectories as root directories.

## Problem

When Railway sets the root directory to `apps/api` or `apps/shop`, running `npm install` in those directories fails because workspace packages like `@org/api-products` and `@org/models` are not found in the npm registry - they're local workspace packages defined in the repository root.

## Solution Applied

**For the backend (`apps/api`):**

- Removed workspace dependencies from `apps/api/package.json` since esbuild bundles everything (`bundle: true`), so they're not needed at runtime
- Created `railpack.json` to configure Railway to install from repository root and build with Nx
- Nx still tracks dependencies via workspace configuration

**For the frontend (`apps/shop`):**

- Workspace dependencies are in `devDependencies`, which Railway won't install in production mode
- Created `railpack.json` to configure Railway to install from repository root and build with Nx

## Solution

The issue is that Railway automatically runs `npm install` in the root directory (`apps/api` or `apps/shop`), which fails because workspace packages aren't in the npm registry.

**Railpack Configuration (Recommended)**

Railpack configuration files (`railpack.json`) are automatically detected by Railway and will:

- Install dependencies from the repository root (`cd ../.. && npm ci`)
- Build using Nx from the repository root
- Start the application using the configured start command

The `railpack.json` files in `apps/api` and `apps/shop` handle this automatically.

**Alternative: Manual Configuration**

If you prefer to configure manually in Railway dashboard:

- Install Command: `cd ../.. && npm ci` (for both services)
- Build Command: `cd ../.. && npx nx build api --configuration=production` (or `shop` for frontend)
- Start Command: `node dist/main.js` (backend) or `npx serve -s dist -l $PORT` (frontend)

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

### Error: "npm ci can only install with an existing package-lock.json"

This error occurs when Railway tries to run `npm ci` automatically in `apps/api` or `apps/shop` before the railpack.json steps execute. These directories don't have `package-lock.json` files (they're in the repository root).

**Solution:**

1. **Disable Railway's automatic install (Recommended):**

   - Go to Railway project settings → Service → Settings
   - Look for "Install Command" or "Auto-install" settings
   - Disable automatic install, or set it to: `echo "Skipping auto-install, using railpack.json"`
   - The `railpack.json` install step will handle dependency installation from the repository root

2. **Alternative: Configure Railway to use repository root:**
   - Change Railway root directory to `/` (repository root) instead of `apps/api` or `apps/shop`
   - Update build/start commands as shown in the "Alternative: Use Repository Root" section below

If you still get 404 errors for workspace packages:

1. **Railway runs npm install automatically:** Railway may try to run `npm install` in `apps/api` before your build command. To fix:

   - Go to Railway project settings → Service → Settings
   - Look for "Build Command" or "Install Command" settings
   - Either disable automatic install, or set install command to: `cd ../.. && npm ci`
   - Or use Railway's Railpack configuration (`railpack.json`) to customize the install step

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
