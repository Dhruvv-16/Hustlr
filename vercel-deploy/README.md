# Vercel Deployment — Hustlr Flutter Web App

## One-time setup on Vercel dashboard

1. Go to vercel.com → Add New Project → Import from GitHub
2. Select the Guidewire_hackathon repo
3. In the configuration screen, override these three fields:

   Framework Preset:    Other
   Build Command:       bash vercel-deploy/build.sh
   Output Directory:    build/web
                        (use app/build/web if Flutter is in an app/ subfolder)
   Install Command:     echo done

4. Click Deploy

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
