from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
import os
import math
import httpx

load_dotenv()

app = FastAPI(title="AI Business Agent API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    prompt: str


class LocationAnalysisRequest(BaseModel):
    city: str
    business_type: str
    address: str = ""


class RoiRequest(BaseModel):
    rent: float
    average_ticket: float
    margin: float = 0.35


class NegotiationRequest(BaseModel):
    address: str
    risks: list[str] = []


TWOGIS_ITEMS_URL = "https://catalog.api.2gis.com/3.0/items"


def _distance_meters(first: tuple[float, float], second: tuple[float, float]) -> float:
    latitude_one, longitude_one = map(math.radians, first)
    latitude_two, longitude_two = map(math.radians, second)
    delta_latitude = latitude_two - latitude_one
    delta_longitude = longitude_two - longitude_one
    value = (
        math.sin(delta_latitude / 2) ** 2
        + math.cos(latitude_one)
        * math.cos(latitude_two)
        * math.sin(delta_longitude / 2) ** 2
    )
    return 6_371_000 * 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value))


def _point(item: dict) -> tuple[float, float] | None:
    point = item.get("point") or {}
    try:
        return float(point["lat"]), float(point["lon"])
    except (KeyError, TypeError, ValueError):
        return None


def _two_gis_items(query: str, *, point: tuple[float, float] | None = None, radius: int | None = None) -> list[dict]:
    api_key = os.getenv("TWOGIS_API_KEY")
    if not api_key:
        raise RuntimeError("TWOGIS_API_KEY is not configured")
    params = {"key": api_key, "q": query, "page_size": 50, "fields": "items.point,items.rubrics"}
    if point:
        params["point"] = f"{point[1]},{point[0]}"
    if radius:
        params["radius"] = radius
    response = httpx.get(TWOGIS_ITEMS_URL, params=params, timeout=15)
    response.raise_for_status()
    return response.json().get("result", {}).get("items", [])


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/chat")
def chat(payload: ChatRequest | None = None, prompt: str | None = None):
    effective_prompt = prompt or (payload.prompt if payload else "")
    provider = os.getenv("AI_PROVIDER", "gemini").lower()
    if provider == "gemini" and os.getenv("GEMINI_API_KEY"):
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent"
        response = httpx.post(
            endpoint,
            params={"key": os.environ["GEMINI_API_KEY"]},
            json={"contents": [{"parts": [{"text": effective_prompt}]}]},
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        return {"response": text, "model": "gemini-3.6-flash", "prompt": effective_prompt}

    if provider == "openai" and os.getenv("OPENAI_API_KEY"):
        response = httpx.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}"},
            json={"model": os.getenv("OPENAI_MODEL", "gpt-4o-mini"), "messages": [{"role": "user", "content": effective_prompt}]},
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        return {"response": data["choices"][0]["message"]["content"], "model": data["model"], "prompt": effective_prompt}

    return {
        "response": (
            f"AI backend is ready. You asked: {effective_prompt or 'nothing'}"
        ),
        "model": "placeholder",
        "prompt": effective_prompt,
    }


@app.post("/analysis/location")
def location_analysis(payload: LocationAnalysisRequest):
    search = payload.address.strip() or payload.city.strip()
    if not search:
        raise HTTPException(status_code=400, detail="city or address is required")
    try:
        locations = _two_gis_items(search)
    except RuntimeError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except httpx.HTTPStatusError as error:
        provider_status = error.response.status_code
        raise HTTPException(
            status_code=502,
            detail=f"2GIS API returned HTTP {provider_status}",
        ) from error
    except httpx.HTTPError as error:
        raise HTTPException(status_code=502, detail="2GIS API request failed") from error
    if not locations or not _point(locations[0]):
        raise HTTPException(status_code=404, detail="2GIS could not resolve this location")

    selected_point = _point(locations[0])
    assert selected_point is not None
    try:
        competitors = _two_gis_items(
            payload.business_type.strip() or "business",
            point=selected_point,
            radius=500,
        )
    except httpx.HTTPError as error:
        raise HTTPException(status_code=502, detail="2GIS competitor search failed") from error
    distances = [
        _distance_meters(selected_point, competitor_point)
        for competitor in competitors
        if (competitor_point := _point(competitor)) is not None
    ]
    competitor_count = len(distances)
    nearest_distance = round(min(distances)) if distances else None
    density = min(100, competitor_count * 10)
    location_score = round(max(0, 82 - density * 0.35), 1)
    traffic_score = round(min(100, 35 + competitor_count * 5), 1)
    return {
        "provider": "2gis",
        "city": payload.city,
        "business_type": payload.business_type,
        "address": payload.address or locations[0].get("name", search),
        "coordinates": {"lat": selected_point[0], "lon": selected_point[1]},
        "score": location_score,
        "survival_rate": round(location_score * 0.9),
        "pedestrian_traffic": "high" if traffic_score >= 70 else "medium" if traffic_score >= 45 else "low",
        "pedestrian_traffic_score": traffic_score,
        "competitors_500m": competitor_count,
        "nearest_competitor_meters": nearest_distance,
        "risks": [
            "Rəqib sıxlığı yüksəkdir" if competitor_count >= 8 else "Rəqib sıxlığı idarəolunandır",
            "Piyada axını 2GIS obyekt sıxlığı əsasında proqnozlaşdırılıb",
        ],
        "verdict": "Məkan ilkin mərhələ üçün uyğundur." if location_score >= 60 else "Məkan əlavə yoxlama tələb edir.",
    }


@app.post("/analysis/roi")
def roi_analysis(payload: RoiRequest):
    contribution = payload.average_ticket * max(payload.margin, 0)
    monthly_customers = 0 if contribution <= 0 else round(payload.rent / contribution)
    return {
        "monthly_customers": monthly_customers,
        "daily_customers": round(monthly_customers / 30),
        "margin": payload.margin,
        "break_even_note": "Bu, ilkin planlama hesabıdır; real xərclər ayrıca təsdiqlənməlidir.",
    }


@app.post("/analysis/negotiate")
def negotiate(payload: NegotiationRequest):
    risks = ", ".join(payload.risks) if payload.risks else "məkanın ilkin riskləri"
    return {
        "message": f"Salam. {payload.address} məkanı ilə maraqlanıram. {risks} nəzərə alınaraq icarə qiymətində güzəşt müzakirə edə bilərikmi?"
    }
