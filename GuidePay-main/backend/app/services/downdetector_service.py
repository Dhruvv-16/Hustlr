import httpx
from bs4 import BeautifulSoup
import logging

logger = logging.getLogger(__name__)

PLATFORM_URLS = {
    "zepto": "https://downdetector.in/status/zepto/",
    "swiggy": "https://downdetector.in/status/swiggy/",
    "blinkit": "https://downdetector.in/status/blinkit/",
    "zomato": "https://downdetector.in/status/zomato/",
}

OUTAGE_THRESHOLD = 500  # reports per hour


async def check_platform_status(platform: str) -> dict:
    """
    Check if a platform is experiencing an outage via Downdetector.
    Returns outage info if threshold exceeded.
    """
    url = PLATFORM_URLS.get(platform)
    if not url:
        return {"platform": platform, "status": "unknown"}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(
                url,
                headers={"User-Agent": "Mozilla/5.0"}
            )
            if response.status_code != 200:
                return {"platform": platform, "status": "unknown"}

            soup = BeautifulSoup(response.text, "html.parser")
            # Try to extract report count from page
            report_count = 0
            stat_el = soup.find(class_="entry-signal")
            if stat_el:
                text = stat_el.get_text(strip=True)
                # Parse number from text like "1,234 reports"
                import re
                nums = re.findall(r"[\d,]+", text)
                if nums:
                    report_count = int(nums[0].replace(",", ""))

            is_outage = report_count >= OUTAGE_THRESHOLD
            return {
                "platform": platform,
                "status": "outage" if is_outage else "normal",
                "report_count": report_count,
            }

    except Exception as e:
        logger.warning(f"Downdetector check failed for {platform}: {e}")
        return {"platform": platform, "status": "unknown"}


async def get_all_platform_statuses() -> list:
    """Check all monitored platforms"""
    import asyncio
    tasks = [check_platform_status(p) for p in PLATFORM_URLS]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return [r for r in results if isinstance(r, dict)]
