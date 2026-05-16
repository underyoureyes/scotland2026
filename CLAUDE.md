# Scotland Trip 2026 — Claude Code Project

## What this project does

Generates two output files from a single JSON data source:

1. `output/Scotland_Itinerary_2026.docx` — full Word document itinerary with formatting,
   colour-coded callout boxes, golf/e-bike panels, appendices, and live links
2. `output/index.html` — mobile-optimised iPhone/CarPlay route guide hosted at
   https://underyoureyes.github.io/scotland2026

**Single source of truth:** `data/itinerary.json` — edit this file to update both outputs.

---

## Project structure

```
scotland_trip/
├── CLAUDE.md                  ← you are here
├── data/
│   └── itinerary.json         ← ALL trip data — edit this to change anything
├── builders/
│   ├── build_word.js          ← Node.js script generating the .docx
│   └── build_html.py          ← Python script generating the HTML
├── tests/
│   └── test_all.py            ← test suite (pytest or python directly)
├── assets/
│   └── styles.css             ← shared colour tokens (reference only)
└── output/
    ├── Scotland_Itinerary_2026.docx
    └── index.html
```

---

## Setup

### Prerequisites

```bash
# Python 3.9+
pip install pytest docx2txt

# Node.js 18+ and the docx library
npm install -g docx
```

### Generate both outputs

```bash
# Word document
node builders/build_word.js

# HTML route guide
python builders/build_html.py

# Run tests
python tests/test_all.py
# or
pytest tests/ -v
```

### Deploy HTML to GitHub Pages

```bash
cp output/index.html ../scotland2026/index.html   # adjust path to your gh-pages repo
cd ../scotland2026
git add index.html
git commit -m "Update Scotland route guide"
git push
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

1. Edit `data/itinerary.json`
2. Run `python tests/test_all.py` — all tests should pass
3. Run `node builders/build_word.js` and `python builders/build_html.py`
4. Deploy HTML to GitHub Pages

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

`tests/test_all.py` covers 10 test groups:

1. **JSON integrity** — 16 days, 7 stays, contiguous dates, required fields
2. **Walking limits** — every day ≤ 5.0 miles (Koda's limit)
3. **Fuel/range safety** — no leg exceeds car range, fuel stops on sparse legs
4. **Map waypoints** — 2–10 waypoints per day, no empty strings
5. **URL structure** — all URLs valid http/https, critical domains present
6. **Bookings completeness** — all required bookings defined with priority
7. **HTML output** — 16 day sections, 16 nav tabs, map links, info panels, content
8. **Word doc output** — exists, correct size, all 16 days present, key content
9. **JSON ↔ HTML consistency** — day titles and stay names match between sources
10. **Critical safety** — Holy Island tide warning, Jacobite 2-booking rule, Loch Ness RIB warning

Run with: `python tests/test_all.py`

---

## Trip summary

- **Dates:** 23 May – 7 June 2026
- **Travellers:** David & Lesley + Koda (age 11) + Monty (age 2)
- **Car:** BMW 530e Estate (PHEV, 3-pin charging cable)
- **Route:** Pulloxhill → Gretna → Loch Lomond → Glencoe → Skye → Loch Ness → Edinburgh → York → Home
- **Total accommodation:** 15 nights across 7 stays
- **Total cost:** ~£3,281 accommodation + activities
- **GitHub Pages:** https://underyoureyes.github.io/scotland2026
