"""
BizBuySell Agriculture Listings Scraper
Fetches listings, applies filters, emails new ones since last run.
"""

import json
import os
import smtplib
import time
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
from urllib.parse import urlencode

import requests
from bs4 import BeautifulSoup


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
    """Read env var as float, falling back to default if unset or empty."""
    return float(os.getenv(key, "") or default)

# Price filter (listing asking price). Set to 0 / float('inf') to disable.
PRICE_MIN = _env_float("PRICE_MIN", "500000")   # $500k
PRICE_MAX = _env_float("PRICE_MAX", "7000000")  # $7M

# Cash flow / EBITDA filter.
CF_MIN = _env_float("CF_MIN", "300000")   # $300k
CF_MAX = _env_float("CF_MAX", "2000000")  # $2M

# Location filter — comma-separated state abbreviations, or "ALL" to disable.
# Example: "MA,NH,RI,CT,ME,VT,NY"  (within ~2hr drive of Boston)
LOCATION_FILTER = os.getenv("LOCATION_FILTER", "ALL")

# Keyword filter — comma-separated words that must appear in title/description.
# Leave empty string to disable.
KEYWORD_FILTER = os.getenv("KEYWORD_FILTER", "")

# ScraperAPI key — routes requests through residential IPs to bypass bot blocks.
# Free tier: 1,000 credits/month at https://scraperapi.com (enough for hourly runs).
SCRAPERAPI_KEY = os.getenv("SCRAPERAPI_KEY", "")

# Email settings
GMAIL_USER = os.getenv("GMAIL_USER", "")          # your Gmail address
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD", "")  # 16-char app password
EMAIL_TO = os.getenv("EMAIL_TO", "tej.s.prattipati@gmail.com")

# File that stores IDs of listings already seen/reported
SEEN_FILE = Path(os.getenv("SEEN_FILE", "seen_listings.json"))

# Max pages to scrape per run
MAX_PAGES = int(os.getenv("MAX_PAGES", "10"))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}

_session = requests.Session()
_session.headers.update(HEADERS)


def _build_url(target_url: str) -> str:
    """Wrap target URL through ScraperAPI if a key is configured."""
    if SCRAPERAPI_KEY:
        params = urlencode({"api_key": SCRAPERAPI_KEY, "url": target_url, "render": "false"})
        return f"https://api.scraperapi.com?{params}"
    return target_url


def parse_dollar(text: str) -> float | None:
    """Convert '$1,250,000' or '1.25M' style strings to a float."""
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
# Scraping
# ---------------------------------------------------------------------------

def fetch_page(url: str, retries: int = 3) -> BeautifulSoup | None:
    fetch_url = _build_url(url)
    for attempt in range(retries):
        try:
            resp = _session.get(fetch_url, timeout=60)
            if resp.status_code == 200:
                return BeautifulSoup(resp.text, "html.parser")
            print(f"HTTP {resp.status_code} for {url}")
        except Exception as e:
            print(f"Request error (attempt {attempt + 1}): {e}")
        time.sleep(2 ** attempt)
    return None


def extract_listings(soup: BeautifulSoup) -> list[dict]:
    listings = []
    # BizBuySell listing cards — selector may need updating if site changes
    cards = soup.select("div.listings article") or soup.select("article.result")
    if not cards:
        # Fallback: grab any <article> tags
        cards = soup.find_all("article")

    for card in cards:
        listing = {}

        # Title / URL
        title_tag = card.find("a", class_=lambda c: c and "title" in c.lower()) or card.find("h2")
        if not title_tag:
            title_tag = card.find("a")
        if title_tag:
            listing["title"] = title_tag.get_text(strip=True)
            href = title_tag.get("href", "")
            if href.startswith("/"):
                href = "https://www.bizbuysell.com" + href
            listing["url"] = href
            # Use URL path as stable ID
            listing["id"] = href.split("?")[0].rstrip("/")
        else:
            continue  # skip cards with no link

        # Price / Cash Flow / Revenue — look for labeled data
        def find_value(labels: list[str]) -> str:
            for label in labels:
                el = card.find(string=lambda t: t and label.lower() in t.lower())
                if el:
                    # value is usually in a sibling or nearby element
                    parent = el.find_parent()
                    if parent:
                        sibling = parent.find_next_sibling()
                        if sibling:
                            return sibling.get_text(strip=True)
                        # Try parent's next parent text
                        return parent.get_text(strip=True).replace(label, "").strip()
            return ""

        # BizBuySell uses data- attributes or structured spans
        def extract_stat(card, *keywords):
            for kw in keywords:
                # Try data attributes
                el = card.find(attrs={"data-label": lambda v: v and kw.lower() in v.lower()})
                if el:
                    return el.get_text(strip=True)
                # Try span/div with class containing keyword
                el = card.find(class_=lambda c: c and kw.lower() in " ".join(c).lower() if isinstance(c, list) else kw.lower() in c.lower())
                if el:
                    return el.get_text(strip=True)
                # Try text search
                el = card.find(string=lambda t: t and kw.lower() in t.lower())
                if el:
                    p = el.find_parent()
                    if p:
                        nxt = p.find_next_sibling()
                        if nxt:
                            return nxt.get_text(strip=True)
            return ""

        listing["price_text"] = extract_stat(card, "asking price", "listing price", "price")
        listing["cf_text"] = extract_stat(card, "cash flow", "ebitda", "sde")
        listing["revenue_text"] = extract_stat(card, "gross revenue", "revenue")
        listing["location"] = extract_stat(card, "location") or ""

        # Fallback: scrape visible text blocks that look like dollar amounts
        # Many BizBuySell cards have a <ul class="stats"> structure
        stats = card.select("ul.stats li, .businessInfo li, .listing-info li")
        for stat in stats:
            text = stat.get_text(" ", strip=True).lower()
            value_el = stat.find("span") or stat
            val = value_el.get_text(strip=True)
            if "asking" in text or "price" in text:
                if not listing["price_text"]:
                    listing["price_text"] = val
            elif "cash flow" in text or "ebitda" in text or "sde" in text:
                if not listing["cf_text"]:
                    listing["cf_text"] = val
            elif "revenue" in text or "gross" in text:
                if not listing["revenue_text"]:
                    listing["revenue_text"] = val
            elif any(s in text for s in ["city", "state", "location"]):
                if not listing["location"]:
                    listing["location"] = val

        listing["price"] = parse_dollar(listing["price_text"])
        listing["cf"] = parse_dollar(listing["cf_text"])

        listings.append(listing)

    return listings


def get_next_page_url(soup: BeautifulSoup, current_url: str) -> str | None:
    next_link = soup.select_one("a[rel='next'], .pagination .next a, li.next a")
    if next_link:
        href = next_link.get("href", "")
        if href.startswith("/"):
            return "https://www.bizbuysell.com" + href
        if href.startswith("http"):
            return href
    return None


def scrape_all() -> list[dict]:
    url = BASE_URL
    all_listings = []
    for page_num in range(1, MAX_PAGES + 1):
        print(f"Scraping page {page_num}: {url}")
        soup = fetch_page(url)
        if not soup:
            break
        page_listings = extract_listings(soup)
        print(f"  Found {len(page_listings)} listings on page {page_num}")
        all_listings.extend(page_listings)
        url = get_next_page_url(soup, url)
        if not url:
            break
        time.sleep(2)  # polite delay between pages
    return all_listings


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

def passes_filters(listing: dict) -> tuple[bool, list[str]]:
    """Return (passes, list_of_reasons_excluded)."""
    reasons = []

    # Price filter
    price = listing.get("price")
    if price is not None:
        if price < PRICE_MIN:
            reasons.append(f"Price ${price:,.0f} < min ${PRICE_MIN:,.0f}")
        elif price > PRICE_MAX:
            reasons.append(f"Price ${price:,.0f} > max ${PRICE_MAX:,.0f}")
    # If price not disclosed, let it through (we can't disqualify unknown)

    # Cash flow filter
    cf = listing.get("cf")
    if cf is not None:
        if cf < CF_MIN:
            reasons.append(f"Cash flow ${cf:,.0f} < min ${CF_MIN:,.0f}")
        elif cf > CF_MAX:
            reasons.append(f"Cash flow ${cf:,.0f} > max ${CF_MAX:,.0f}")

    # Location filter
    if LOCATION_FILTER and LOCATION_FILTER.upper() != "ALL":
        allowed_states = [s.strip().upper() for s in LOCATION_FILTER.split(",")]
        loc = listing.get("location", "").upper()
        if not any(state in loc for state in allowed_states):
            reasons.append(f"Location '{listing.get('location')}' not in {allowed_states}")

    # Keyword filter
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
        cf = f"${l['cf']:,.0f}" if l.get("cf") else l.get("cf_text") or "N/A"
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
    msg["From"] = GMAIL_USER
    msg["To"] = EMAIL_TO

    html = build_email_html(new_listings)
    msg.attach(MIMEText(html, "html"))

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
