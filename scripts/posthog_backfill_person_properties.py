#!/usr/bin/env python3
"""
Backfill one-shot des person properties PostHog de FaithLock.

Etape 1 : agrege les events de chaque distinct_id via la Query API (HogQL).
Etape 2 : calcule les metriques derivees (deltas de dates, booleens).
Etape 3 : renvoie le tout en $set via la Capture API.

Usage :
    export POSTHOG_PROJECT_TOKEN=phc_xxx
    export POSTHOG_PRIVATE_API_KEY=phx_xxx
    export POSTHOG_PROJECT_ID=239251
    python3 scripts/posthog_backfill_person_properties.py [--dry-run] [--limit N]

Aucune dependance externe : stdlib uniquement (urllib).
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from typing import Any, Iterable

# ============================================================================
# CONFIG
# ============================================================================

POSTHOG_PROJECT_TOKEN = os.environ.get("POSTHOG_PROJECT_TOKEN", "phc_xxx")
POSTHOG_PRIVATE_API_KEY = os.environ.get("POSTHOG_PRIVATE_API_KEY", "phx_xxx")
POSTHOG_PROJECT_ID = os.environ.get("POSTHOG_PROJECT_ID", "12345")

POSTHOG_API_HOST = os.environ.get("POSTHOG_API_HOST", "https://us.posthog.com")
POSTHOG_CAPTURE_HOST = os.environ.get(
    "POSTHOG_CAPTURE_HOST", "https://us.i.posthog.com"
)

BATCH_SIZE = 1000  # users par page SQL
MAX_CONCURRENT = 10  # requetes Capture API simultanees
MAX_RETRIES = 5  # tentatives max par requete Capture
QUERY_TIMEOUT = 300  # secondes, la Query API peut etre lente sur 2 ans d'events
CAPTURE_TIMEOUT = 30

FAILED_USERS_FILE = "failed_users.txt"
SUMMARY_FILE = "summary.json"

# Une date PostHog "absente" ne remonte pas NULL : maxIf/minIf renvoient
# l'epoch (1970-01-01) quand aucun event ne matche. On traite donc toute date
# anterieure a ce seuil comme absente.
EPOCH_SENTINEL_YEAR = 2000

# ============================================================================
# REQUETE HOGQL
# ============================================================================

# Pagination keyset sur distinct_id : la Query API refuse OFFSET quand on
# s'authentifie avec une cle API personnelle
# ("OFFSET is not supported on queries made with a personal API key").
# On avance donc avec `distinct_id > <dernier vu>` + ORDER BY distinct_id, ce
# qui est de toute facon plus sur : pas de saut ni de doublon entre deux pages.
HOGQL_QUERY = """
SELECT
    distinct_id,

    -- PRIERE
    countIf(event = 'prayer_completed') AS total_prayers_completed,
    countIf(event = 'prayer_started') AS total_prayers_started,
    countIf(event = 'prayer_abandoned') AS total_prayers_abandoned,
    countIf(event = 'prayer_flow_cancelled') AS total_prayers_cancelled,
    round(
        countIf(event = 'prayer_completed') * 100.0 /
        nullIf(countIf(event = 'prayer_started'), 0), 2
    ) AS prayer_completion_rate,
    maxIf(timestamp, event = 'prayer_completed') AS last_prayer_at,
    countIf(event = 'prayer_session_started') AS total_prayer_sessions_started,
    countIf(event = 'prayer_session_completed') AS total_prayer_sessions_completed,
    maxIf(timestamp, event = 'prayer_session_completed') AS last_prayer_session_at,
    countIf(event = 'prayer_step_completed') AS total_prayer_steps_completed,
    countIf(event = 'prayer_library_viewed') AS prayer_library_views,
    countIf(event = 'prayer_library_prayer_selected') AS prayer_library_selections,

    -- UNLOCK
    countIf(event = 'unlock_flow_started') AS total_unlock_flows_started,
    countIf(event = 'unlock_completed') AS total_unlocks_completed,
    round(
        countIf(event = 'unlock_completed') * 100.0 /
        nullIf(countIf(event = 'unlock_flow_started'), 0), 2
    ) AS unlock_completion_rate,
    maxIf(timestamp, event = 'unlock_completed') AS last_unlock_at,
    countIf(event = 'apps_relocked') AS total_apps_relocked,
    countIf(event = 'unlock_expired') AS total_unlock_expirations,
    countIf(event = 'unlock_entry') AS total_unlock_entries,

    -- BIBLE
    countIf(event = 'bible_reading_completed') AS bible_chapters_read,
    countIf(event = 'bible_chapter_opened') AS bible_chapters_opened,
    countIf(event = 'bible_book_opened') AS bible_books_opened,
    countIf(event = 'bible_search') AS bible_searches_count,
    countIf(event = 'bible_verse_of_day_shared') AS bible_verses_shared,
    countIf(event = 'bible_verse_of_day_viewed') AS bible_verse_of_day_views,
    maxIf(timestamp, event = 'bible_reading_completed') AS last_bible_read_at,

    -- COMPANION (IA)
    countIf(event = 'companion_message_sent') AS companion_messages_sent,
    countIf(event = 'companion_reply_completed') AS companion_replies_received,
    countIf(event = 'companion_opened') AS companion_sessions_count,
    countIf(event = 'companion_new_chat') AS companion_new_chats,
    countIf(event = 'companion_voice_download') AS companion_voice_downloads,
    maxIf(timestamp, event = 'companion_opened') AS last_companion_used_at,

    -- MOOD
    countIf(event = 'mood_check_in_submitted') AS mood_checkins_count,
    countIf(event = 'mood_recorded') AS mood_recorded_count,
    countIf(event = 'mood_skipped') AS mood_skips_count,
    round(
        countIf(event = 'mood_check_in_submitted') * 100.0 /
        nullIf(
            countIf(event = 'mood_check_in_submitted') + countIf(event = 'mood_skipped'), 0
        ), 2
    ) AS mood_engagement_rate,
    maxIf(timestamp, event = 'mood_check_in_submitted') AS last_mood_checkin_at,

    -- GAMIFICATION / BADGES
    countIf(event = 'badge_earned') AS badges_earned_count,
    maxIf(timestamp, event = 'badge_earned') AS last_badge_earned_at,
    countIf(event = 'streak_freeze_used') AS streak_freezes_used,
    countIf(event = 'streak_intro_viewed') AS streak_intro_views,

    -- PAYWALL & MONETISATION
    countIf(event = 'paywall_viewed') AS paywall_views_count,
    countIf(event = 'paywall_dismissed') AS paywall_dismissals,
    countIf(event = 'paywall_purchase_completed') AS purchases_completed_count,
    countIf(event = 'paywall_purchase_failed') AS purchase_failed_count,
    countIf(event = 'paywall_plan_selected') AS purchase_attempts_count,
    minIf(timestamp, event = 'paywall_purchase_completed') AS purchase_completed_at,
    countIf(event = 'subscription_restore_started') AS subscription_restores_attempted,
    countIf(event = 'subscription_restore_no_purchases') AS subscription_restores_no_purchases,

    -- ONBOARDING
    minIf(timestamp, event = 'onboarding_started') AS onboarding_started_at,
    maxIf(timestamp, event = 'onboarding_completed') AS onboarding_completed_at,
    countIf(event = 'onboarding_step_completed') AS onboarding_steps_completed,
    countIf(event = 'onboarding_feature_adopted') AS onboarding_features_adopted,

    -- NOTIFICATIONS
    countIf(event = 'notification_tapped') AS notifications_tapped_count,

    -- REFLECTIONS
    countIf(event = 'reflections_opened') AS reflections_opened_count,
    countIf(event = 'reflections_bookmark_opened') AS reflections_bookmarks_opened,

    -- APP & SESSIONS
    countIf(event = 'Application Opened') AS sessions_count_total,
    maxIf(timestamp, event = 'Application Opened') AS last_active_date,
    minIf(timestamp, event = 'Application Installed') AS app_installed_at,

    -- TOUR
    countIf(event = 'tour_started') AS tours_started,
    countIf(event = 'tour_completed') AS tours_completed,
    countIf(event = 'tour_skipped') AS tours_skipped,

    -- RATING
    countIf(event = 'rate_intent_shown') AS rate_intents_shown,
    countIf(event = 'rate_completed') AS app_rated_count,
    maxIf(timestamp, event = 'rate_completed') AS app_rated_at,

    -- STATS
    countIf(event = 'stats_dashboard_viewed') AS stats_dashboard_views,

    -- WINBACK
    countIf(event = 'winback_sequence_scheduled') AS winback_sequence_count

FROM events
WHERE timestamp >= now() - interval 2 year
  AND distinct_id != ''
  {cursor_clause}
GROUP BY distinct_id
ORDER BY distinct_id
LIMIT {limit}
"""

# Colonnes a envoyer en date ISO 8601.
DATE_COLUMNS = {
    "last_prayer_at",
    "last_prayer_session_at",
    "last_unlock_at",
    "last_bible_read_at",
    "last_companion_used_at",
    "last_mood_checkin_at",
    "last_badge_earned_at",
    "purchase_completed_at",
    "onboarding_started_at",
    "onboarding_completed_at",
    "last_active_date",
    "app_installed_at",
    "app_rated_at",
}

# Colonnes techniques qui servent au calcul mais ne partent pas telles quelles.
INTERNAL_COLUMNS = {"distinct_id", "purchases_completed_count", "app_rated_count"}

# Proprietes booleennes : `false` porte du sens, on les envoie toujours.
BOOLEAN_PROPERTIES = {
    "purchases_completed",
    "app_rated",
    "subscription_restore_attempted",
}

# ============================================================================
# LOGGING / ETAT PARTAGE
# ============================================================================

_print_lock = threading.Lock()
_failed_lock = threading.Lock()


class HttpResponse:
    """Reponse HTTP minimale, suffisante pour distinguer 429 / 4xx / 5xx."""

    def __init__(self, status: int, body: str, headers: dict[str, str]) -> None:
        self.status = status
        self.body = body
        self.headers = headers

    def json(self) -> Any:
        return json.loads(self.body)


def http_post(url: str, payload: dict, headers: dict[str, str], timeout: int) -> HttpResponse:
    """POST JSON via urllib. Les erreurs HTTP reviennent en HttpResponse, pas
    en exception : seules les pannes reseau/timeout levent (URLError, OSError).
    """
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return HttpResponse(
                response.status,
                response.read().decode("utf-8", errors="replace"),
                dict(response.headers),
            )
    except urllib.error.HTTPError as exc:
        return HttpResponse(
            exc.code,
            exc.read().decode("utf-8", errors="replace"),
            dict(exc.headers or {}),
        )


def log(message: str) -> None:
    with _print_lock:
        print(message, flush=True)


class Counters:
    """Compteurs thread-safe partages entre les workers Capture."""

    def __init__(self, total: int = 0) -> None:
        self._lock = threading.Lock()
        self.total = total
        self.processed = 0
        self.success = 0
        self.failed = 0

    def record(self, ok: bool) -> tuple[int, int, int]:
        with self._lock:
            self.processed += 1
            if ok:
                self.success += 1
            else:
                self.failed += 1
            return self.processed, self.success, self.failed


# ============================================================================
# ETAPE 1 - QUERY API
# ============================================================================


def run_hogql_page(limit: int, cursor: str | None) -> list[dict]:
    """Execute une page de la requete HogQL et renvoie des dicts colonne -> valeur.

    [cursor] est le dernier distinct_id de la page precedente (None au 1er appel).
    """
    if cursor is None:
        cursor_clause = ""
    else:
        escaped = cursor.replace("\\", "\\\\").replace("'", "\\'")
        cursor_clause = f"AND distinct_id > '{escaped}'"

    url = f"{POSTHOG_API_HOST}/api/projects/{POSTHOG_PROJECT_ID}/query/"
    payload = {
        "query": {
            "kind": "HogQLQuery",
            "query": HOGQL_QUERY.format(limit=limit, cursor_clause=cursor_clause),
        }
    }

    delay = 2.0
    last_error: str | None = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = http_post(
                url,
                payload,
                {"Authorization": f"Bearer {POSTHOG_PRIVATE_API_KEY}"},
                QUERY_TIMEOUT,
            )
            if response.status == 429:
                retry_after = float(response.headers.get("Retry-After", delay))
                log(f"  429 sur la Query API, pause {retry_after:.0f}s "
                    f"(tentative {attempt}/{MAX_RETRIES})")
                time.sleep(retry_after)
                delay = min(delay * 2, 60)
                continue
            if response.status >= 400:
                last_error = f"HTTP {response.status}: {response.body[:300]}"
                if response.status < 500:
                    # 4xx hors 429 : cle invalide ou SQL casse, inutile d'insister.
                    break
            else:
                body = response.json()
                columns = body.get("columns") or []
                results = body.get("results") or []
                return [dict(zip(columns, row)) for row in results]
        except (urllib.error.URLError, OSError, json.JSONDecodeError) as exc:
            last_error = f"{type(exc).__name__}: {exc}"

        if attempt == MAX_RETRIES:
            break
        log(f"  Query API en erreur ({last_error}), nouvelle tentative dans {delay:.0f}s")
        time.sleep(delay)
        delay = min(delay * 2, 60)

    raise RuntimeError(f"Query API en echec apres {MAX_RETRIES} tentatives: {last_error}")


def fetch_all_users(max_users: int | None) -> list[dict]:
    """Pagine la Query API jusqu'a epuisement des resultats."""
    users: list[dict] = []
    cursor: str | None = None

    while True:
        page_size = BATCH_SIZE
        if max_users is not None:
            page_size = min(BATCH_SIZE, max_users - len(users))
            if page_size <= 0:
                break

        log(f"Query API : LIMIT {page_size} apres '{cursor or ''}' ...")
        rows = run_hogql_page(page_size, cursor)
        if not rows:
            break

        users.extend(rows)
        log(f"  -> {len(rows)} lignes (total {len(users)})")

        if len(rows) < page_size:
            break
        cursor = str(rows[-1].get("distinct_id") or "")
        if not cursor:
            break

    return users


# ============================================================================
# ETAPE 2 - NORMALISATION + METRIQUES DERIVEES
# ============================================================================


def parse_timestamp(value: Any) -> datetime | None:
    """Convertit une valeur PostHog en datetime aware, ou None si absente.

    maxIf/minIf renvoient l'epoch (et non NULL) quand aucun event ne matche :
    toute date anterieure a EPOCH_SENTINEL_YEAR est donc consideree absente.
    """
    if value is None:
        return None

    if isinstance(value, datetime):
        parsed = value
    elif isinstance(value, str):
        text = value.strip()
        if not text:
            return None
        text = text.replace("Z", "+00:00")
        # ClickHouse renvoie parfois "YYYY-MM-DD HH:MM:SS" sans le T.
        if " " in text and "T" not in text:
            text = text.replace(" ", "T", 1)
        try:
            parsed = datetime.fromisoformat(text)
        except ValueError:
            return None
    else:
        return None

    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    if parsed.year < EPOCH_SENTINEL_YEAR:
        return None
    return parsed


def round_floats(value: Any) -> Any:
    if isinstance(value, float):
        return round(value, 2)
    return value


def build_set_payload(row: dict, now: datetime) -> dict[str, Any]:
    """Construit le dict $set d'un user : dates ISO, derivees, sans null ni 0."""
    dates: dict[str, datetime | None] = {
        column: parse_timestamp(row.get(column)) for column in DATE_COLUMNS
    }

    props: dict[str, Any] = {}

    # -- Colonnes brutes -----------------------------------------------------
    for column, value in row.items():
        if column in INTERNAL_COLUMNS:
            continue
        if column in DATE_COLUMNS:
            parsed = dates.get(column)
            if parsed is not None:
                props[column] = parsed.isoformat()
            continue
        value = round_floats(value)
        if value is None or value == 0:
            continue
        props[column] = value

    # -- Metriques derivees --------------------------------------------------
    onboarding_started = dates.get("onboarding_started_at")
    onboarding_completed = dates.get("onboarding_completed_at")
    if onboarding_started is not None and onboarding_completed is not None:
        delta_days = (onboarding_completed - onboarding_started).total_seconds() / 86400
        props["days_to_complete_onboarding"] = round(max(delta_days, 0.0), 2)

    last_active = dates.get("last_active_date")
    if last_active is not None:
        since_days = (now - last_active).total_seconds() / 86400
        props["days_since_last_active"] = round(max(since_days, 0.0), 2)

    # Booleens : `false` est informatif, on l'envoie meme s'il est "vide".
    props["app_rated"] = int(row.get("app_rated_count") or 0) >= 1
    props["purchases_completed"] = int(row.get("purchases_completed_count") or 0) >= 1
    props["subscription_restore_attempted"] = (
        int(row.get("subscription_restores_attempted") or 0) >= 1
    )

    return props


# ============================================================================
# ETAPE 3 - CAPTURE API
# ============================================================================


def send_person_properties(
    distinct_id: str,
    props: dict[str, Any],
    dry_run: bool,
) -> tuple[bool, str | None]:
    """Envoie un $set. Renvoie (succes, message d'erreur)."""
    if dry_run:
        return True, None

    url = f"{POSTHOG_CAPTURE_HOST}/i/v0/e/"
    payload = {
        "api_key": POSTHOG_PROJECT_TOKEN,
        "distinct_id": distinct_id,
        "event": "$set",
        "properties": {"$set": props},
    }

    delay = 2.0
    last_error: str | None = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = http_post(url, payload, {}, CAPTURE_TIMEOUT)
            if response.status == 429:
                retry_after = float(response.headers.get("Retry-After", delay))
                # Jitter : evite que les 10 workers reprennent tous en meme temps.
                time.sleep(retry_after + random.uniform(0, 0.5))
                delay = min(delay * 2, 60)
                last_error = "429 Too Many Requests"
                continue
            if response.status >= 500:
                last_error = f"HTTP {response.status}: {response.body[:200]}"
                time.sleep(delay)
                delay = min(delay * 2, 60)
                continue
            if response.status >= 400:
                # 4xx hors 429 : payload invalide, retenter ne sert a rien.
                return False, f"HTTP {response.status}: {response.body[:200]}"
            return True, None
        except (urllib.error.URLError, OSError) as exc:
            last_error = f"{type(exc).__name__}: {exc}"
            if attempt == MAX_RETRIES:
                break
            time.sleep(delay)
            delay = min(delay * 2, 60)

    return False, last_error or "echec inconnu"


def process_user(
    row: dict,
    now: datetime,
    counters: Counters,
    failed: list[tuple[str, str]],
    dry_run: bool,
) -> None:
    distinct_id = str(row.get("distinct_id") or "").strip()
    if not distinct_id:
        return

    try:
        props = build_set_payload(row, now)
        ok, error = send_person_properties(distinct_id, props, dry_run)
    except Exception as exc:  # noqa: BLE001 - un user casse ne doit pas tuer le run
        ok, error = False, f"{type(exc).__name__}: {exc}"

    if not ok:
        with _failed_lock:
            failed.append((distinct_id, error or "erreur inconnue"))

    processed, success, failures = counters.record(ok)
    if processed % 25 == 0 or processed == counters.total:
        log(
            f"Traitement user {processed} / {counters.total} "
            f"| OK: {success} | Erreurs: {failures}"
        )


# ============================================================================
# ORCHESTRATION
# ============================================================================


def check_config() -> None:
    missing = [
        name
        for name, value in (
            ("POSTHOG_PROJECT_TOKEN", POSTHOG_PROJECT_TOKEN),
            ("POSTHOG_PRIVATE_API_KEY", POSTHOG_PRIVATE_API_KEY),
            ("POSTHOG_PROJECT_ID", POSTHOG_PROJECT_ID),
        )
        if not value or value.endswith("xxx") or value == "12345"
    ]
    if missing:
        log("Configuration incomplete, variables manquantes : " + ", ".join(missing))
        log("Exporte-les avant de lancer le script (voir docstring en tete de fichier).")
        sys.exit(1)


def write_reports(
    failed: Iterable[tuple[str, str]], counters: Counters, duration: float, dry_run: bool
) -> None:
    failed = list(failed)

    with open(FAILED_USERS_FILE, "w", encoding="utf-8") as handle:
        for distinct_id, error in failed:
            handle.write(f"{distinct_id}\t{error}\n")

    summary = {
        "total": counters.total,
        "success": counters.success,
        "failed": counters.failed,
        "duration": round(duration, 2),
        "dry_run": dry_run,
        "finished_at": datetime.now(timezone.utc).isoformat(),
    }
    with open(SUMMARY_FILE, "w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)

    log("")
    log("=" * 60)
    log(f"Termine en {duration:.1f}s")
    log(f"  Total   : {counters.total}")
    log(f"  Succes  : {counters.success}")
    log(f"  Erreurs : {counters.failed}")
    log(f"  Rapports: {SUMMARY_FILE}, {FAILED_USERS_FILE}")
    if dry_run:
        log("  (DRY RUN : aucune requete Capture n'a ete envoyee)")
    log("=" * 60)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="interroge la Query API mais n'envoie rien a la Capture API",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="nombre maximum de users a traiter (test)",
    )
    parser.add_argument(
        "--print-sample",
        action="store_true",
        help="affiche le payload $set du premier user puis continue",
    )
    args = parser.parse_args()

    check_config()

    started = time.monotonic()
    now = datetime.now(timezone.utc)

    log("Etape 1/3 : recuperation des users via la Query API")
    users = fetch_all_users(args.limit)
    log(f"  {len(users)} users recuperes")

    if not users:
        write_reports([], Counters(0), time.monotonic() - started, args.dry_run)
        return

    if args.print_sample:
        sample = build_set_payload(users[0], now)
        log("")
        log("Exemple de payload $set :")
        log(json.dumps(sample, indent=2, ensure_ascii=False))
        log("")

    log("Etape 2/3 + 3/3 : calcul des derivees et envoi des $set")
    counters = Counters(total=len(users))
    failed: list[tuple[str, str]] = []

    with ThreadPoolExecutor(max_workers=MAX_CONCURRENT) as pool:
        for row in users:
            pool.submit(process_user, row, now, counters, failed, args.dry_run)

    write_reports(failed, counters, time.monotonic() - started, args.dry_run)


if __name__ == "__main__":
    main()
