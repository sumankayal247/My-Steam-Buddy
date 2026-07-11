# My-Steam-Buddy

A web app to track all time low games I can buy from Steam and to track giveaways in Steam and Epic.

**[Live Link →](https://sumankayal247.github.io/My-Steam-Buddy/)**

## Features

- **Browse** — infinite-scroll feed of Steam deals currently at their all-time-low price, or one that just broke a new record
- **Studios** — curated game lists from major publishers (Valve, Rockstar, CD Projekt Red, FromSoftware, and more)
- **Monitor** — a personal watchlist with live price tracking
- **Giveaways** — free game giveaways across Steam, Epic, and GOG

## Setup

The app needs a free [IsThereAnyDeal API key](https://isthereanydeal.com/apps/) — paste it into Settings on first launch.

## Tech

Flutter (Android + Web), [IsThereAnyDeal API](https://isthereanydeal.com/), Steam Web API, [GamerPower API](https://www.gamerpower.com/api-read).

The web build routes Steam/ITAD calls through a small CORS proxy since neither API sends CORS headers — see `tool/web_proxy.py` (local dev) and `cloudflare-worker/` (production).

---

Made for personal use, built with AI assistance.
