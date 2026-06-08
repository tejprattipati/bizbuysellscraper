"""
BizBuySell Agriculture Listings Scraper
Fetches listings via curl_cffi (Chrome TLS fingerprint impersonation),
applies filters, emails new ones since last run.
"""

import json
import os
import smtplib
import time
import random
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

from bs4 import BeautifulSoup
from curl_cffi.requests import Session


def _now() -> datetime:
    return datetime.now(timezone.utc)

# ---------------------------------------------------------------------------
# Configuration — override any of these via environment variables
# ---------------------------------------------------------------------------

BASE_URL = os.getenv(
    "BBS_URL",
    "https://www.bizbuysell.com/agriculture-businesses-for-sale/?q=bHQ9MzAsNDAsODA%3D",
)

def _env_float(key: str, default: str) -> float:
    return float(os.getenv(key, "") or default)

PRICE_MIN = _env_float("PRICE_MIN", "500000")   # $500k
PRICE_MAX = _env_float("PRICE_MAX", "7000000")  # $7M
CF_MIN    = _env_float("CF_MIN",    "300000")   # $300k
CF_MAX    = _env_float("CF_MAX",    "2000000")  # $2M

# Location filter — comma-separated state abbreviations, or "ALL" to disable.
LOCATION_FILTER = os.getenv("LOCATION_FILTER", "ALL")

# Keyword filter — comma-separated words that must appear in title/description.
KEYWORD_FILTER = os.getenv("KEYWORD_FILTER", "")

# Email settings
GMAIL_USER        = os.getenv("GMAIL_USER", "")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD", "")
EMAIL_TO          = os.getenv("EMAIL_TO", "tej.s.prattipati@gmail.com")

# File that stores IDs of listings already seen/reported
SEEN_FILE = Path(os.getenv("SEEN_FILE", "seen_listings.json"))

# Max pages to scrape per run
MAX_PAGES = int(os.getenv("MAX_PAGES", "10") or "10")

# Optional ScraperAPI key — set this if Akamai JS challenge blocks direct access.
# Get a free key at https://scraperapi.com (1000 free requests/month).
SCRAPER_API_KEY = os.getenv("SCRAPER_API_KEY", "")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_dollar(text: str) -> float | None:
    if not text:
        return None
    text = text.strip().replace(",", "").replace("$", "").replace(" ", "")
    if not text or text.lower() in ("n/a", "not disclosed", "-", ""):
        return None
    multiplier = 1
    if text.upper().endswith("M"):
        multiplier = 1_000_000
        text = text[:-1]
    elif text.upper().endswith("K"):
        multiplier = 1_000
        text = text[:-1]
    try:
        return float(text) * multiplier
    except ValueError:
        return None


def load_seen() -> set:
    if SEEN_FILE.exists():
        with open(SEEN_FILE) as f:
            return set(json.load(f))
    return set()


def save_seen(seen: set) -> None:
    with open(SEEN_FILE, "w") as f:
        json.dump(sorted(seen), f, indent=2)


# ---------------------------------------------------------------------------
# HTTP session with Chrome TLS fingerprint
# ---------------------------------------------------------------------------

CHROME_PROFILE = os.getenv("CHROME_PROFILE", "chrome136")


def _make_session(profile: str | None = None) -> Session:
    """curl_cffi session that impersonates Chrome's TLS/HTTP2 fingerprint."""
    session = Session(impersonate=profile or CHROME_PROFILE)
    session.headers.update({
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        "Upgrade-Insecure-Requests": "1",
        "Sec-CH-UA": '"Chromium";v="136", "Google Chrome";v="136", "Not-A.Brand";v="99"',
        "Sec-CH-UA-Mobile": "?0",
        "Sec-CH-UA-Platform": '"Windows"',
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/136.0.0.0 Safari/537.36"
        ),
    })
    return session


def fetch_html(session: Session, url: str) -> str | None:
    """Fetch rendered HTML for url.

    If SCRAPER_API_KEY is set, routes through ScraperAPI which handles
    Akamai JS challenges automatically. Otherwise uses direct curl_cffi.
    """
    if SCRAPER_API_KEY:
        api_url = (
            f"http://api.scraperapi.com?api_key={SCRAPER_API_KEY}"
            f"&url={url}&render=true&country_code=us"
        )
        try:
            import urllib.request
            with urllib.request.urlopen(api_url, timeout=60) as r:
                html = r.read().decode("utf-8", errors="replace")
            verdict = _classify_response(html, 200)
            print(f"  ScraperAPI verdict: {verdict} (len={len(html)})")
            if verdict == "REAL_PAGE":
                return html
            print(f"  ScraperAPI did not return real page: {html[:300]}")
            return None
        except Exception as e:
            print(f"  ScraperAPI error: {e}")
            return None

    try:
        resp = session.get(url, timeout=30, allow_redirects=True)
        if resp.status_code == 200:
            html = resp.text
            verdict = _classify_response(html, resp.status_code)
            if verdict == "REAL_PAGE":
                return html
            print(f"  WARNING: {verdict} — not a real listings page")
            print(f"  HTML[:300]: {html[:300]}")
            return None
        print(f"  ERROR: HTTP {resp.status_code} for {url}")
        return None
    except Exception as e:
        print(f"  Request error fetching {url}: {e}")
        return None


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def extract_listings(html: str) -> list[dict]:
    # Primary: parse BBS-state JSON (Angular SSR embeds all listing data here)
    raw = _extract_bbs_state(html)
    if raw is not None:
        print(f"  BBS-state JSON found: {len(raw)} raw listings")
        listings = []
        for item in raw:
            url = item.get("urlStub", "")
            listing_id = str(item.get("listNumber", "")) or url.split("?")[0].rstrip("/")
            price = item.get("price")
            cf = item.get("cashFlow") or item.get("ebitda")
            listings.append({
                "id": listing_id,
                "title": item.get("header", ""),
                "url": url,
                "location": item.get("location", ""),
                "price": float(price) if price is not None else None,
                "cf": float(cf) if cf is not None else None,
                "price_text": f"${price:,}" if price is not None else "N/A",
                "cf_text": f"${cf:,}" if cf is not None else "N/A",
                "description": item.get("description", ""),
                "region": item.get("region", ""),
            })
        return listings

    # Fallback: HTML element selectors (for future layout changes)
    soup = BeautifulSoup(html, "html.parser")
    cards = (
        soup.select("div.listing-result")
        or soup.select("article.result")
        or soup.select(".listings article")
        or soup.find_all("article")
    )
    print(f"  BBS-state not found; HTML card count: {len(cards)}")

    listings = []
    for card in cards:
        title_tag = (
            card.find("a", class_=lambda c: c and "title" in " ".join(c).lower())
            or card.find("h2") or card.find("h3") or card.find("a")
        )
        if not title_tag:
            continue
        href = title_tag.get("href", "")
        if href.startswith("/"):
            href = "https://www.bizbuysell.com" + href

        def get_stat(*keywords: str) -> str:
            for kw in keywords:
                for li in card.select("ul.stats li, li"):
                    txt = li.get_text(" ", strip=True)
                    if kw.lower() in txt.lower():
                        spans = li.find_all("span")
                        return spans[-1].get_text(strip=True) if len(spans) >= 2 else txt
                el = card.find(attrs={"data-label": lambda v: v and kw.lower() in v.lower()})
                if el:
                    return el.get_text(strip=True)
            return ""

        price_text = get_stat("asking price", "listing price", "price")
        cf_text = get_stat("cash flow", "ebitda", "sde")
        listings.append({
            "id": href.split("?")[0].rstrip("/"),
            "title": title_tag.get_text(strip=True),
            "url": href,
            "location": get_stat("location", "city", "state"),
            "price": parse_dollar(price_text),
            "cf": parse_dollar(cf_text),
            "price_text": price_text,
            "cf_text": cf_text,
        })
    return listings


def get_next_page_url(html: str) -> str | None:
    soup = BeautifulSoup(html, "html.parser")
    next_link = soup.select_one("a[rel='next'], .pagination .next a, li.next a, a.next")
    if next_link:
        href = next_link.get("href", "")
        if href.startswith("/"):
            return "https://www.bizbuysell.com" + href
        if href.startswith("http"):
            return href
    return None


# ---------------------------------------------------------------------------
# Scraping
# ---------------------------------------------------------------------------

def scrape_all() -> list[dict]:
    all_listings = []
    session = _make_session()

    # Warm up: visit the homepage to establish session cookies
    print("Warming up session via homepage...")
    try:
        resp = session.get("https://www.bizbuysell.com/", timeout=30)
        print(f"  Homepage status: {resp.status_code}")
        time.sleep(random.uniform(2, 4))
    except Exception as e:
        print(f"  Homepage warm-up failed (continuing): {e}")

    url = BASE_URL
    for page_num in range(1, MAX_PAGES + 1):
        print(f"Scraping page {page_num}: {url}")
        html = fetch_html(session, url)
        if not html:
            break
        page_listings = extract_listings(html)
        print(f"  Found {len(page_listings)} listings on page {page_num}")
        all_listings.extend(page_listings)
        next_url = get_next_page_url(html)
        if not next_url:
            break
        url = next_url
        time.sleep(random.uniform(2, 4))

    return all_listings


# ---------------------------------------------------------------------------
# Diagnose mode — inspect raw rendered HTML and CSS structure
# ---------------------------------------------------------------------------

def _extract_bbs_state(html: str) -> list[dict] | None:
    """Extract listing objects from the BBS-state JSON script tag, or None."""
    soup = BeautifulSoup(html, "html.parser")
    tag = soup.find("script", {"id": "BBS-state"})
    if not tag:
        return None
    try:
        data = json.loads(tag.string)
    except (json.JSONDecodeError, TypeError):
        return None
    # Navigate nested structure: top-level keys are API endpoint names;
    # find the one containing bfsSearchResult.value (a list of listings).
    for top_val in data.values():
        if not isinstance(top_val, dict):
            continue
        inner = top_val.get("value", {})
        if not isinstance(inner, dict):
            continue
        bfs = inner.get("bfsSearchResult", {})
        if isinstance(bfs, dict):
            listings = bfs.get("value", [])
            if isinstance(listings, list) and listings:
                return listings
    return None


def _classify_response(html: str, status: int) -> str:
    """Return one of: ACCESS_DENIED | AKAMAI_JS_CHALLENGE | REAL_PAGE | UNKNOWN"""
    if status != 200:
        return f"HTTP_{status}"
    if "Access Denied" in html[:600] and len(html) < 2000:
        return "ACCESS_DENIED"
    if "akamai" in html.lower()[:2000] and "behavioral" in html.lower()[:2000]:
        return "AKAMAI_JS_CHALLENGE"
    if 'id="BBS-state"' in html or "BBS-state" in html:
        return "REAL_PAGE"
    if "bizbuysell" in html.lower() and len(html) > 5000:
        return "REAL_PAGE"
    return f"UNKNOWN (len={len(html)})"


def diagnose_page(url: str = BASE_URL) -> None:
    """
    Probe `url` across multiple Chrome TLS fingerprint profiles, classify
    each response, then print a full structural report for the best result.

    Response categories:
      ACCESS_DENIED     — Akamai hard-blocked (wrong TLS fingerprint)
      AKAMAI_JS_CHALLENGE — TLS passed but JS behavioral challenge served
      REAL_PAGE         — Actual BizBuySell content returned
    """
    # Profiles to probe in order from newest to oldest
    profiles = ["chrome146", "chrome142", "chrome136", "chrome131", "chrome124"]

    best_html = None
    best_profile = None
    best_status = None

    for profile in profiles:
        print(f"\n[probe] {profile} ...", end=" ", flush=True)
        try:
            session = _make_session(profile)
            # Homepage warm-up
            session.get("https://www.bizbuysell.com/", timeout=20)
            time.sleep(1)
            resp = session.get(url, timeout=30, allow_redirects=True)
            html = resp.text
            verdict = _classify_response(html, resp.status_code)
            print(f"HTTP {resp.status_code} → {verdict}  (html len={len(html)})")
            if verdict == "REAL_PAGE" and best_html is None:
                best_html = html
                best_profile = profile
                best_status = resp.status_code
            elif best_html is None:
                best_html = html
                best_profile = profile
                best_status = resp.status_code
        except Exception as e:
            print(f"ERROR: {e}")

    html = best_html or ""
    soup = BeautifulSoup(html, "html.parser")
    verdict = _classify_response(html, best_status or 0)
    bbs_listings = _extract_bbs_state(html)

    print("\n" + "=" * 70)
    print(f"BEST PROFILE:     {best_profile}")
    print(f"HTTP STATUS:      {best_status}")
    print(f"VERDICT:          {verdict}")
    print(f"PAGE TITLE:       {soup.title.string if soup.title else '(none)'}")
    print(f"HTML LENGTH:      {len(html):,} bytes")

    if bbs_listings is not None:
        print(f"\nBBS-STATE JSON:   FOUND — {len(bbs_listings)} listings")
        for i, item in enumerate(bbs_listings[:3]):
            print(f"\n  Listing #{i+1}:")
            print(f"    title:    {item.get('title','')[:80]}")
            print(f"    location: {item.get('location','')}")
            price = item.get('price')
            cf = item.get('cf')
            print(f"    price:    ${price:,.0f}" if price else "    price:    N/A")
            print(f"    cf:       ${cf:,.0f}" if cf else "    cf:       N/A")
            print(f"    url:      {item.get('url','')}")
        if len(bbs_listings) > 3:
            print(f"\n  ... and {len(bbs_listings) - 3} more")
    else:
        print("\nBBS-STATE JSON:   NOT FOUND")
        all_classes = sorted({
            c
            for tag in soup.find_all(True)
            for c in (tag.get("class") or [])
        })
        keywords = ("listing", "result", "card", "business", "sale", "item", "tile", "row")
        candidates = [c for c in all_classes if any(k in c.lower() for k in keywords)]
        print(f"<article> tags:   {len(soup.find_all('article'))}")
        print(f"Total CSS classes: {len(all_classes)}")
        print(f"Candidate selectors: {candidates[:20]}")
        body_text = soup.get_text(" ", strip=True)
        print(f"\nVISIBLE TEXT SAMPLE:\n{body_text[:600]}")
        print(f"\nHTML SNIPPET (first 2000 chars):\n{html[:2000]}")

    print("=" * 70)

    if verdict == "AKAMAI_JS_CHALLENGE":
        print("\nAKAMAI JS CHALLENGE ACTIVE — curl_cffi cannot execute behavioral JS.")
        print("Options:")
        print("  1. ScraperAPI (scraperapi.com) — set SCRAPER_API_KEY secret")
        print("  2. Scrapfly (scrapfly.io) — handles Akamai specifically")
        print("  3. Residential proxy + curl_cffi")
    elif verdict == "REAL_PAGE":
        print(f"\nReal page retrieved with profile '{best_profile}'.")
        if bbs_listings:
            print(f"extract_listings() will return {len(bbs_listings)} listings from BBS-state JSON.")


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

def passes_filters(listing: dict) -> tuple[bool, list[str]]:
    reasons = []

    price = listing.get("price")
    if price is not None:
        if price < PRICE_MIN:
            reasons.append(f"Price ${price:,.0f} < min ${PRICE_MIN:,.0f}")
        elif price > PRICE_MAX:
            reasons.append(f"Price ${price:,.0f} > max ${PRICE_MAX:,.0f}")

    cf = listing.get("cf")
    if cf is not None:
        if cf < CF_MIN:
            reasons.append(f"Cash flow ${cf:,.0f} < min ${CF_MIN:,.0f}")
        elif cf > CF_MAX:
            reasons.append(f"Cash flow ${cf:,.0f} > max ${CF_MAX:,.0f}")

    if LOCATION_FILTER and LOCATION_FILTER.upper() != "ALL":
        allowed = [s.strip().upper() for s in LOCATION_FILTER.split(",")]
        loc = listing.get("location", "").upper()
        if not any(s in loc for s in allowed):
            reasons.append(f"Location '{listing.get('location')}' not in {allowed}")

    if KEYWORD_FILTER:
        keywords = [k.strip().lower() for k in KEYWORD_FILTER.split(",") if k.strip()]
        text = (listing.get("title", "") + " " + listing.get("location", "")).lower()
        missing = [k for k in keywords if k not in text]
        if missing:
            reasons.append(f"Missing keywords: {missing}")

    return len(reasons) == 0, reasons


# ---------------------------------------------------------------------------
# Email
# ---------------------------------------------------------------------------

def build_email_html(new_listings: list[dict]) -> str:
    rows = ""
    for l in new_listings:
        price = f"${l['price']:,.0f}" if l.get("price") else l.get("price_text") or "N/A"
        cf    = f"${l['cf']:,.0f}"    if l.get("cf")    else l.get("cf_text")    or "N/A"
        rows += f"""
        <tr>
            <td style="padding:8px;border-bottom:1px solid #eee;">
                <a href="{l['url']}" style="color:#1a73e8;font-weight:bold;">{l['title']}</a><br>
                <small style="color:#555;">{l.get('location','')}</small>
            </td>
            <td style="padding:8px;border-bottom:1px solid #eee;">{price}</td>
            <td style="padding:8px;border-bottom:1px solid #eee;">{cf}</td>
        </tr>"""

    return f"""
    <html><body style="font-family:Arial,sans-serif;color:#333;max-width:900px;margin:auto;">
    <h2 style="color:#1a73e8;">BizBuySell — New Agriculture Listings</h2>
    <p>Found <strong>{len(new_listings)}</strong> new listing(s) matching your criteria
    as of {_now().strftime('%Y-%m-%d %H:%M UTC')}.</p>

    <p><strong>Active filters:</strong><br>
    Price: ${PRICE_MIN:,.0f} – ${PRICE_MAX:,.0f}<br>
    Cash Flow / EBITDA: ${CF_MIN:,.0f} – ${CF_MAX:,.0f}<br>
    Location: {LOCATION_FILTER}<br>
    Keywords: {KEYWORD_FILTER or '(none)'}
    </p>

    <table style="width:100%;border-collapse:collapse;">
        <thead>
            <tr style="background:#f0f4f8;">
                <th style="padding:10px;text-align:left;">Business</th>
                <th style="padding:10px;text-align:left;">Asking Price</th>
                <th style="padding:10px;text-align:left;">Cash Flow / EBITDA</th>
            </tr>
        </thead>
        <tbody>{rows}</tbody>
    </table>

    <p style="margin-top:24px;font-size:12px;color:#888;">
        Powered by BizBuySell Scraper · <a href="{BASE_URL}">View all listings</a>
    </p>
    </body></html>
    """


def send_email(new_listings: list[dict]) -> None:
    if not GMAIL_USER or not GMAIL_APP_PASSWORD:
        print("Email credentials not set — skipping email.")
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"[BizBuySell] {len(new_listings)} New Agriculture Listing(s)"
    msg["From"]    = GMAIL_USER
    msg["To"]      = EMAIL_TO

    msg.attach(MIMEText(build_email_html(new_listings), "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        server.sendmail(GMAIL_USER, EMAIL_TO, msg.as_string())
    print(f"Email sent to {EMAIL_TO} with {len(new_listings)} listing(s).")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    import sys
    if "--diagnose" in sys.argv:
        url = BASE_URL
        for arg in sys.argv[1:]:
            if arg.startswith("http"):
                url = arg
        diagnose_page(url)
        return

    print(f"=== BizBuySell Scraper — {_now().isoformat()} ===")

    seen = load_seen()
    print(f"Previously seen listings: {len(seen)}")

    all_listings = scrape_all()
    print(f"Total scraped: {len(all_listings)}")

    new_listings = []
    for listing in all_listings:
        lid = listing.get("id")
        if not lid or lid in seen:
            continue
        passes, reasons = passes_filters(listing)
        if passes:
            new_listings.append(listing)
            print(f"  NEW: {listing['title']} | {listing.get('price_text')} | {listing.get('cf_text')}")
        else:
            print(f"  FILTERED: {listing['title']} — {'; '.join(reasons)}")
        seen.add(lid)

    print(f"New listings matching filters: {len(new_listings)}")

    if new_listings:
        send_email(new_listings)
    else:
        print("No new matching listings — no email sent.")

    save_seen(seen)
    print("Done.")


if __name__ == "__main__":
    main()
