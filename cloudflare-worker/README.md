# MySteamBuddy CORS proxy (Cloudflare Worker)

The live GitHub Pages site is static-only, so it can't run `tool/web_proxy.py`
itself. This Worker does the same job — add CORS headers when relaying to
Steam's and ITAD's APIs — but runs publicly on Cloudflare's free tier.

## Deploy (dashboard, no CLI needed)

1. Go to https://dash.cloudflare.com/ and sign up / log in (free).
2. **Workers & Pages** → **Create** → **Create Worker**.
3. Give it a name (e.g. `mysteambuddy-proxy`) → **Deploy** (deploys a placeholder first).
4. Click **Edit code**, delete the placeholder contents, paste in `worker.js` from this folder, then **Deploy**.
5. Copy the Worker's URL — it looks like `https://mysteambuddy-proxy.<your-subdomain>.workers.dev`.
6. Send that URL back so the web build can be pointed at it (`--dart-define=PROXY_BASE=<url>` in `.github/workflows/deploy.yml`), or set it yourself and re-run the Actions workflow.

Free tier is 100,000 requests/day — far more than this app needs.
