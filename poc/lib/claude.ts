import Anthropic from '@anthropic-ai/sdk'
import type { IntakeForm, TripData } from './types'

export function getClaudeClient(apiKey: string) {
  return new Anthropic({ apiKey })
}

const SYSTEM_PROMPT = `You are an expert road trip planner specialising in UK and European road trips.
Generate a detailed, day-by-day itinerary as a single JSON object.

CRITICAL RULES:
- Output ONLY valid JSON — no markdown, no explanations, no code fences
- Follow the schema exactly — every field matters
- Every stop must include a real address or at minimum a town/region
- Balance driving and activities sensibly — respect the max_driving_hours constraint
- Realistic drive times (not Google Maps "no traffic" estimates)
- All website URLs must be real https:// links or null — no invented URLs`

export function buildTripPrompt(form: IntakeForm): string {
  const startMs = new Date(form.start_date).getTime()
  const endMs = new Date(form.end_date).getTime()
  const days = Math.max(1, Math.ceil((endMs - startMs) / (1000 * 60 * 60 * 24)) + 1)

  return `Plan a ${days}-day road trip:

TITLE: ${form.title}
FROM: ${form.origin}
TO: ${form.destination}
DATES: ${form.start_date} → ${form.end_date} (${days} days)
TRAVELLERS: ${form.num_travellers}
INTERESTS: ${form.interests.length ? form.interests.join(', ') : 'general sightseeing'}
ACCOMMODATION: ${form.accommodation_style}
BUDGET: £${form.budget_per_day_gbp}/day per person
MAX DRIVING: ${form.driving_max_hours}h/day
${form.must_include ? `MUST INCLUDE: ${form.must_include}` : ''}
${form.notes ? `NOTES: ${form.notes}` : ''}

Output exactly this JSON structure:
{
  "summary": "<one sentence trip summary>",
  "total_days": ${days},
  "total_distance_km": <estimated total km>,
  "total_stops": <number of stops excluding drives>,
  "days": [
    {
      "day_number": 1,
      "date": "${form.start_date}",
      "title": "<catchy day title>",
      "overnight_location": "<town where you sleep>",
      "stops": [
        {
          "name": "<stop name>",
          "type": "<drive|hotel|sightseeing|activity|viewpoint|town|restaurant|cafe|pub|beach|nature|castle|distillery|museum|fuel|other>",
          "description": "<1-2 sentence description>",
          "address": "<full address or town, region>",
          "phone": "<phone or null>",
          "website": "<real https:// url or null>",
          "duration_mins": <minutes to spend here — 0 for drives>,
          "drive_time_mins": <only for type=drive: minutes driving>,
          "distance_km": <only for type=drive: km>,
          "check_in": "<only for type=hotel: e.g. 15:00>",
          "check_out": "<only for type=hotel: e.g. 11:00>",
          "booking_ref": null,
          "notes": "<practical tips or null>"
        }
      ],
      "eating": [
        {
          "name": "<restaurant/pub/cafe name>",
          "meal_type": "<breakfast|lunch|dinner|snack>",
          "description": "<brief description>",
          "address": "<address>",
          "website": "<https:// url or null>",
          "booking_required": false
        }
      ],
      "notes": "<general day tips or null>"
    }
  ]
}`
}

export async function* streamTripGeneration(
  apiKey: string,
  form: IntakeForm
): AsyncGenerator<string> {
  const client = getClaudeClient(apiKey)

  const stream = await client.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 16000,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: buildTripPrompt(form) }],
  })

  for await (const chunk of stream) {
    if (
      chunk.type === 'content_block_delta' &&
      chunk.delta.type === 'text_delta'
    ) {
      yield chunk.delta.text
    }
  }
}

export function parseTripJson(raw: string): TripData {
  const cleaned = raw
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/```\s*$/i, '')
    .trim()
  return JSON.parse(cleaned) as TripData
}

export async function validateClaudeKey(apiKey: string): Promise<boolean> {
  try {
    const client = getClaudeClient(apiKey)
    await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 10,
      messages: [{ role: 'user', content: 'Hi' }],
    })
    return true
  } catch {
    return false
  }
}
