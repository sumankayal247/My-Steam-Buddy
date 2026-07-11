// MySteamBuddy CORS proxy — deploy on Cloudflare Workers (free tier).
//
// Neither Steam's nor IsThereAnyDeal's API sends CORS headers, so the
// deployed web build (GitHub Pages, static-only, can't run its own proxy)
// needs a public relay. This mirrors tool/web_proxy.py (the local dev
// version of the same proxy) but runs on Cloudflare's edge instead of
// localhost. See README.md in this folder for deploy steps.
//
// Routes:
//   /steam/<path>  -> https://api.steampowered.com/<path>
//   /itad/<path>   -> https://api.isthereanydeal.com/<path>

const UPSTREAMS = {
  '/steam/': 'https://api.steampowered.com/',
  '/itad/': 'https://api.isthereanydeal.com/',
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const match = Object.entries(UPSTREAMS).find(([prefix]) => url.pathname.startsWith(prefix));
    if (!match) {
      return new Response('Unknown proxy route', { status: 404, headers: CORS_HEADERS });
    }
    const [prefix, upstreamBase] = match;
    const target = upstreamBase + url.pathname.slice(prefix.length) + url.search;

    const upstreamRes = await fetch(target, {
      method: request.method,
      headers:
        request.method === 'POST'
          ? { 'Content-Type': request.headers.get('Content-Type') || 'application/json' }
          : undefined,
      body: request.method === 'POST' ? await request.text() : undefined,
    });

    const body = await upstreamRes.arrayBuffer();
    return new Response(body, {
      status: upstreamRes.status,
      headers: {
        ...CORS_HEADERS,
        'Content-Type': upstreamRes.headers.get('Content-Type') || 'application/json',
      },
    });
  },
};
