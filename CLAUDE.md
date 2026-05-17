# Trip Planner — Claude Code Project

## What this project does

Generates per-trip output files from a per-trip JSON data source:

1. `trips/<trip-id>/output/<Trip>.docx` — full Word document itinerary
2. `trips/<trip-id>/output/index.html` — mobile-optimised iPhone/CarPlay route guide

Each trip is self-contained under `trips/<trip-id>/`. Builders and tests accept a `--trip` argument.

**GitHub Pages:** each trip deploys to `https://underyoureyes.github.io/trip-planner/<trip-id>/`

---

## Project structure

```
trip-planner/
├── CLAUDE.md                  ← you are here
├── trips/
│   ├── scotland-2026/
│   │   ├── data.json          ← ALL Scotland trip data — edit to change anything
│   │   └── output/
│   │       ├── Scotland_Itinerary_2026.docx
│   │       └── index.html
│   └── lake-garda-2026/       ← future trips follow the same pattern
│       ├── data.json
│       └── output/
├── builders/
│   └── build_html.py          ← Python script generating the HTML (--trip <id>)
├── tests/
│   └── test_all.py            ← test suite (--trip <id>)
└── assets/
    └── styles.css             ← shared colour tokens (reference only)
```

---

## Setup

### Prerequisites

```bash
# Python 3.9+
pip install pytest docx2txt
```

### Generate outputs for a trip

```bash
# HTML route guide (defaults to scotland-2026 if --trip omitted)
python builders/build_html.py --trip scotland-2026

# Run tests
python tests/test_all.py --trip scotland-2026
# or
pytest tests/ -v
```

### Deploy HTML to GitHub Pages

```bash
./deploy.sh scotland-2026
# deploys to https://underyoureyes.github.io/trip-planner/scotland-2026/
```

---

## Data model — itinerary.json

### trip
Top-level metadata: travellers, dogs (name, age, max_walk_miles), car specs, home postcode.

### stays[]
One entry per accommodation. Fields: `id`, `name`, `location`, `nights`, `checkin`,
`checkout`, `type` (airbnb/hotel/booking_com), `url`, `cost_gbp`, `confirm_socket_with_host`.

### days[]
One entry per day (16 total). Required fields:
- `day` (1–16), `date`, `title`, `stay_id` (matches a stays.id)
- `leg_miles`, `leg_drive_hours`
- `total_walk_miles` — must not exceed 5.0 (Koda's limit)
- `flags[]` — optional: "highlight", "golf", "ebike", "fuel_warning", "train", "ballot_action"
- `map_waypoints[]` — array of place strings for Google Maps (max 10)
- `stops[]` — each stop has: `name`, `type`, `detail`, optional `cost`/`url`/`maps_query`/`walk_miles`/`book_ahead`
- `eating[]` — each eating option has: `name`, `type`, `dog_friendly`, optional `url`
- `notes[]` — plain string tips and warnings

### stop types (used in stops[].type)
```
dog_walk          walk with dogs
walk_dogs         walk with dogs (alias)
fuel              fill up car — generates amber warning box
lunch_fuel        combined lunch and fuel stop
cruise_dogs       boat trip with dogs
boat_dogs         boat trip with dogs (alias)
castle_dogs       castle visit, dogs in grounds
castle_dogs_optional  optional detour castle
sightseeing       general sightseeing
sightseeing_dogs  sightseeing with dogs
photo_stop        quick photo stop
supplies          shopping stop
ebike_optional    optional e-bike hire
golf              golf round
distillery        whisky distillery visit
pub_dogs          dog-friendly pub
gondola_dogs      gondola/cable car with dogs
train_dogs        train journey with dogs
viewpoint         roadside viewpoint, minimal walking
attraction_dogs   indoor attraction that allows dogs
attraction_no_dogs   indoor attraction, dogs stay at accommodation
tidal_warning     tide-dependent crossing — generates red warning box
afternoon_tea_no_dogs  afternoon tea, dogs stay at accommodation
```

### Special day fields
- `golf{}` — course, holes, cost_gbp, hire_included, booking, url, dogs_welcome
- `afternoon_tea{}` — name, detail, cost, url
- `ballot_reminder{}` — action, deadline, url, detail (generates highlighted reminder on Day 10)
- `ebike{}` — for days with e-bike panels

---

## Key constraints (enforced by tests)

| Constraint | Value | Reason |
|---|---|---|
| Max daily walk | 5.0 miles | Koda is 11 — senior dog |
| Car tank range | 300 miles | BMW 530e |
| EV overnight top-up | ~28 miles | 3-pin socket charging |
| Map waypoints per day | ≤ 10 | Google Maps URL limit |
| Jacobite bookings | 2 separate | 1 dog per booking rule |
| Loch Ness cruise | Standard only | RIB does not allow dogs |

---

## How to add a new day / change content

1. Edit `trips/<trip-id>/data.json`
2. Run `python tests/test_all.py --trip <trip-id>` — all tests should pass
3. Run `python builders/build_html.py --trip <trip-id>`
4. Deploy: `./deploy.sh <trip-id>`

## How to add a new stop to a day

Find the day in `days[]`, add to `stops[]`:

```json
{
  "name": "Glencoe Visitor Centre",
  "type": "sightseeing_dogs",
  "detail": "Dog-friendly café and discovery trails outside. Museum inside.",
  "cost": "Free outside; museum ~£8pp",
  "url": "https://www.nts.org.uk/visit/places/glencoe",
  "maps_query": "Glencoe Visitor Centre PH49"
}
```

Then update `total_walk_miles` for the day if the stop adds walking.

---

## Test suite overview

`tests/test_all.py` covers 10 test groups (generic + scotland-2026-specific):

1. **JSON integrity** — days sequential, stays valid, contiguous dates, required fields
2. **Walking limits** — every day ≤ most-constrained dog's limit
3. **Fuel/range safety** — no leg exceeds car range, fuel stops on sparse legs
4. **Map waypoints** — 2–10 waypoints per day, no empty strings
5. **URL structure** — all URLs valid http/https; critical domains (scotland-2026 only)
6. **Bookings completeness** — all required bookings defined with priority
7. **HTML output** — all day sections, nav tabs, map links, info panels, content
8. **Word doc output** — exists, correct size, all days present, key content
9. **JSON ↔ HTML consistency** — day titles and stay names match between sources
10. **Critical safety** — Holy Island, Jacobite, Loch Ness RIB (scotland-2026 only)

Run with: `python tests/test_all.py --trip scotland-2026`

---

## Trip summary

- **Dates:** 23 May – 7 June 2026
- **Travellers:** David & Lesley + Koda (age 11) + Monty (age 2)
- **Car:** BMW 530e Estate (PHEV, 3-pin charging cable)
- **Route:** Pulloxhill → Gretna → Loch Lomond → Glencoe → Skye → Loch Ness → Edinburgh → York → Home
- **Total accommodation:** 15 nights across 7 stays
- **Total cost:** ~£3,281 accommodation + activities
- **GitHub Pages:** https://underyoureyes.github.io/trip-planner
