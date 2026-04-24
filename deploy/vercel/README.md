# Vercel Deployment — Hustlr Flutter Web App

## One-time setup on Vercel dashboard

1. Go to vercel.com → Add New Project → Import from GitHub
2. Select this repo (monorepo root — `vercel.json` lives at the root).
3. In the configuration screen, override these fields:

   Framework Preset:    Other
   Build Command:       bash vercel-build.sh
                        (root `vercel.json` sets this; `deploy/vercel/build.sh` delegates to the same script)
   Output Directory:    build/web
   Install Command:     echo done

4. **Environment variables** (Project → Settings → Environment Variables):

   | Name | Value | Environments |
   |------|--------|--------------|
   | `HUSTLR_API_PROD` | `https://<hustlr-api>.onrender.com` (your Render Node service URL, HTTPS, no trailing slash) | Production (and Preview if you want preview builds to hit a real API) |

   Production builds **fail** if `HUSTLR_API_PROD` is missing (the Flutter web client needs a real API).

5. On **Render**, set **`CORS_ORIGIN`** on `hustlr-api` to your Vercel site origin(s), e.g. `https://your-project.vercel.app`, so the browser can call the API. (Omit on Render only if you still use wide-open CORS in code — default is allow-all when unset.)

6. Click Deploy

## How it works

- Vercel runs build.sh which clones the Flutter SDK (~300MB, cached after first run)
- Flutter builds the web app into build/web/
- Vercel serves build/web/ as a static site
- The rewrites rule in vercel.json routes all paths to index.html
  so Flutter's client-side router works on page refresh

## First deploy takes 5–8 minutes (Flutter SDK download)
## After that, ~2–3 minutes per deploy

## Every push to main auto-deploys — no manual steps needed

## If the build fails

Check these common issues:
- pubspec.yaml has a dependency that does not support web — remove it or add
  a web-compatible alternative
- flutter build web fails locally — fix it locally first, then push
- Run locally to test: flutter build web --release
