"""
BizBuySell Agriculture Listings Scraper
Fetches listings via Playwright (headless Chromium), applies filters,
emails new ones since last run.
"""

import json
import os
import smtplib
import time
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout
from playwright_stealth import stealth_sync


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
# Scraping with Playwright
# ---------------------------------------------------------------------------

def fetch_html(page, url: str) -> str | None:
    """Navigate to url and return rendered HTML after listings load."""
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=60_000)
        # Wait for listing cards to appear — try several known selectors
        for selector in [
            "div.listing-result",
            "article.result",
            ".listings article",
            "[class*='listing-result']",
            "[class*='ListingResult']",
        ]:
            try:
                page.wait_for_selector(selector, timeout=15_000)
                print(f"  Listings appeared with selector: {selector}")
                break
            except PWTimeout:
                continue
        else:
            # None matched — dump a snippet so we can debug selectors
            body_text = page.inner_text("body")[:500]
            html_snippet = page.content()[:2000]
            print(f"  WARNING: no listing selector matched.")
            print(f"  Body text[:500]: {body_text}")
            print(f"  HTML[:2000]: {html_snippet}")
        time.sleep(2)  # small extra wait for lazy-loaded content
        return page.content()
    except Exception as e:
        print(f"  Playwright error fetching {url}: {e}")
        return None


def extract_listings(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")

    # BizBuySell listing card selectors (try in order)
    cards = (
        soup.select("div.listing-result")
        or soup.select("article.result")
        or soup.select(".listings article")
        or soup.find_all("article")
        or soup.select("[class*='listing-result']")
    )

    print(f"  Raw card count: {len(cards)}")
    if cards:
        print(f"  Sample card classes: {cards[0].get('class')}")

    listings = []
    for card in cards:
        listing = {}

        # Title / URL
        title_tag = (
            card.find("a", class_=lambda c: c and "title" in " ".join(c).lower())
            or card.find("h2")
            or card.find("h3")
            or card.find("a")
        )
        if not title_tag:
            continue
        listing["title"] = title_tag.get_text(strip=True)
        href = title_tag.get("href", "")
        if href.startswith("/"):
            href = "https://www.bizbuysell.com" + href
        listing["url"] = href
        listing["id"] = href.split("?")[0].rstrip("/")

        # Stats — BizBuySell uses labeled <li> items in a <ul class="stats">
        def get_stat(*keywords: str) -> str:
            for kw in keywords:
                # labeled list items
                for li in card.select("ul.stats li, li"):
                    txt = li.get_text(" ", strip=True)
                    if kw.lower() in txt.lower():
                        # value is usually the last span or the text after the label
                        spans = li.find_all("span")
                        if len(spans) >= 2:
                            return spans[-1].get_text(strip=True)
                        return txt
                # data-label attributes
                el = card.find(attrs={"data-label": lambda v: v and kw.lower() in v.lower()})
                if el:
                    return el.get_text(strip=True)
            return ""

        listing["price_text"]   = get_stat("asking price", "listing price", "price")
        listing["cf_text"]      = get_stat("cash flow", "ebitda", "sde")
        listing["revenue_text"] = get_stat("gross revenue", "revenue")
        listing["location"]     = get_stat("location", "city", "state") or ""

        listing["price"] = parse_dollar(listing["price_text"])
        listing["cf"]    = parse_dollar(listing["cf_text"])

        listings.append(listing)

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


def scrape_all() -> list[dict]:
    all_listings = []
    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-dev-shm-usage",
            ],
        )
        ctx = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1280, "height": 800},
            locale="en-US",
            java_script_enabled=True,
            # Mimic real browser accept headers
            extra_http_headers={
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "Upgrade-Insecure-Requests": "1",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
                "Sec-Fetch-User": "?1",
            },
        )
        page = ctx.new_page()
        # Apply stealth patches — removes navigator.webdriver and other bot signals
        stealth_sync(page)
        # Block images/fonts to speed up loading
        page.route("**/*.{png,jpg,jpeg,gif,webp,svg,woff,woff2,ttf}", lambda r: r.abort())

        url = BASE_URL
        for page_num in range(1, MAX_PAGES + 1):
            print(f"Scraping page {page_num}: {url}")
            html = fetch_html(page, url)
            if not html:
                break
            page_listings = extract_listings(html)
            print(f"  Found {len(page_listings)} listings on page {page_num}")
            all_listings.extend(page_listings)
            next_url = get_next_page_url(html)
            if not next_url:
                break
            url = next_url
            time.sleep(2)

        browser.close()
    return all_listings


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
