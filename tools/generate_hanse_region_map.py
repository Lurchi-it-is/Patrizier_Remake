from __future__ import annotations

import json
import math
import urllib.request
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
from matplotlib.patches import Circle, FancyArrowPatch, Rectangle
from matplotlib.path import Path as MplPath
from matplotlib.patches import PathPatch
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "maps"
OUTPUT_IMAGE = ASSET_DIR / "hanse_region_1600x900.png"
OUTPUT_META = ASSET_DIR / "hanse_region_1600x900.json"
CACHE_DIR = ROOT / ".cache" / "map_data"
COUNTRIES_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson"
RIVERS_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson"

WIDTH = 1600
HEIGHT = 900
LON_MIN = -6.0
LON_MAX = 34.6
LAT_MIN = 49.3
LAT_MAX = 62.1
CENTER_LAT = (LAT_MIN + LAT_MAX) * 0.5
COS_CENTER = math.cos(math.radians(CENTER_LAT))

HANSE_CITIES = [
    {"id": "london", "name": "London", "lon": -0.1276, "lat": 51.5072, "marker_lon": -0.102203, "marker_lat": 51.50906, "kind": "kontor"},
    {"id": "bruegge", "name": "Bruegge", "lon": 3.2247, "lat": 51.2093, "marker_lon": 3.3000, "marker_lat": 51.2500, "kind": "kontor"},
    {"id": "koeln", "name": "Koeln", "lon": 6.9603, "lat": 50.9375, "marker_lon": 6.96461, "marker_lat": 50.934027, "kind": "member"},
    {"id": "bremen", "name": "Bremen", "lon": 8.8017, "lat": 53.0793, "marker_lon": 8.812918, "marker_lat": 53.070014, "kind": "member"},
    {"id": "hamburg", "name": "Hamburg", "lon": 9.9937, "lat": 53.5511, "marker_lon": 9.996755, "marker_lat": 53.542263, "kind": "core"},
    {"id": "luebeck", "name": "Luebeck", "lon": 10.6866, "lat": 53.8655, "marker_lon": 10.6910, "marker_lat": 53.8690, "kind": "core"},
    {"id": "wismar", "name": "Wismar", "lon": 11.4629, "lat": 53.8931, "marker_lon": 11.4650, "marker_lat": 53.8950, "kind": "member"},
    {"id": "rostock", "name": "Rostock", "lon": 12.0991, "lat": 54.0924, "marker_lon": 12.1040, "marker_lat": 54.0930, "kind": "member"},
    {"id": "stralsund", "name": "Stralsund", "lon": 13.0770, "lat": 54.3091, "marker_lon": 13.0900, "marker_lat": 54.3150, "kind": "member"},
    {"id": "greifswald", "name": "Greifswald", "lon": 13.3815, "lat": 54.0958, "marker_lon": 13.3890, "marker_lat": 54.0970, "kind": "member"},
    {"id": "stettin", "name": "Stettin", "lon": 14.5528, "lat": 53.4285, "marker_lon": 14.562673, "marker_lat": 53.42414, "kind": "member"},
    {"id": "kopenhagen", "name": "Kopenhagen", "lon": 12.5683, "lat": 55.6761, "marker_lon": 12.5870, "marker_lat": 55.6810, "kind": "trade"},
    {"id": "malmoe", "name": "Malmoe", "lon": 13.0038, "lat": 55.6050, "marker_lon": 13.0038, "marker_lat": 55.6050, "kind": "trade"},
    {"id": "skanor_falsterbo", "name": "Skanor-Falsterbo", "lon": 12.8469, "lat": 55.3978, "marker_lon": 12.8469, "marker_lat": 55.3978, "kind": "trade"},
    {"id": "helsingborg", "name": "Helsingborg", "lon": 12.6945, "lat": 56.0465, "marker_lon": 12.6945, "marker_lat": 56.0465, "kind": "trade"},
    {"id": "aalborg", "name": "Aalborg", "lon": 9.9217, "lat": 57.0488, "marker_lon": 9.9217, "marker_lat": 57.0488, "kind": "trade"},
    {"id": "oslo", "name": "Oslo", "lon": 10.7522, "lat": 59.9139, "marker_lon": 10.7520, "marker_lat": 59.9080, "kind": "trade"},
    {"id": "bergen", "name": "Bergen", "lon": 5.3221, "lat": 60.3929, "marker_lon": 5.3221, "marker_lat": 60.3929, "kind": "kontor"},
    {"id": "stockholm", "name": "Stockholm", "lon": 18.0686, "lat": 59.3293, "marker_lon": 18.0710, "marker_lat": 59.3250, "kind": "trade"},
    {"id": "kalmar", "name": "Kalmar", "lon": 16.3568, "lat": 56.6634, "marker_lon": 16.3568, "marker_lat": 56.6634, "kind": "trade"},
    {"id": "visby", "name": "Visby", "lon": 18.2948, "lat": 57.6348, "marker_lon": 18.2960, "marker_lat": 57.6400, "kind": "core"},
    {"id": "danzig", "name": "Danzig", "lon": 18.6466, "lat": 54.3520, "marker_lon": 18.6570, "marker_lat": 54.3500, "kind": "member"},
    {"id": "elbing", "name": "Elbing", "lon": 19.4088, "lat": 54.1561, "marker_lon": 19.4088, "marker_lat": 54.1561, "kind": "member"},
    {"id": "koenigsberg", "name": "Koenigsberg", "lon": 20.5106, "lat": 54.7104, "marker_lon": 20.5106, "marker_lat": 54.7104, "kind": "member"},
    {"id": "memel", "name": "Memel", "lon": 21.1443, "lat": 55.7033, "marker_lon": 21.1443, "marker_lat": 55.7033, "kind": "trade"},
    {"id": "riga", "name": "Riga", "lon": 24.1052, "lat": 56.9496, "marker_lon": 24.105154, "marker_lat": 56.956814, "kind": "kontor"},
    {"id": "reval", "name": "Reval", "lon": 24.7536, "lat": 59.4370, "marker_lon": 24.7530, "marker_lat": 59.4440, "kind": "member"},
    {"id": "abo", "name": "Abo", "lon": 22.2666, "lat": 60.4518, "marker_lon": 22.2666, "marker_lat": 60.4300, "kind": "trade"},
    {"id": "viborg", "name": "Viborg", "lon": 28.7528, "lat": 60.7090, "marker_lon": 28.7528, "marker_lat": 60.7090, "kind": "trade"},
    {"id": "narva", "name": "Narva", "lon": 28.1903, "lat": 59.3772, "marker_lon": 28.1903, "marker_lat": 59.3772, "kind": "trade"},
    {"id": "nowgorod", "name": "Nowgorod", "lon": 31.2755, "lat": 58.5228, "marker_lon": 31.299897, "marker_lat": 58.527777, "kind": "kontor"},
]

WATER_ALIGNED_MARKER_PIXELS = {
    "london": {"x": 231, "y": 744},
    "bruegge": {"x": 366, "y": 752},
    "koeln": {"x": 511, "y": 785},
    "bremen": {"x": 584, "y": 634},
    "hamburg": {"x": 630, "y": 601},
    "luebeck": {"x": 665, "y": 568},
    "wismar": {"x": 685, "y": 572},
    "rostock": {"x": 710, "y": 557},
    "stralsund": {"x": 753, "y": 546},
    "greifswald": {"x": 766, "y": 558},
    "stettin": {"x": 810, "y": 610},
    "kopenhagen": {"x": 732, "y": 451},
    "malmoe": {"x": 746, "y": 457},
    "skanor_falsterbo": {"x": 743, "y": 471},
    "helsingborg": {"x": 736, "y": 426},
    "aalborg": {"x": 646, "y": 348},
    "oslo": {"x": 653, "y": 166},
    "bergen": {"x": 440, "y": 125},
    "stockholm": {"x": 949, "y": 195},
    "kalmar": {"x": 881, "y": 382},
    "visby": {"x": 956, "y": 313},
    "danzig": {"x": 975, "y": 540},
    "elbing": {"x": 990, "y": 543},
    "koenigsberg": {"x": 1022, "y": 522},
    "memel": {"x": 1068, "y": 450},
    "riga": {"x": 1186, "y": 362},
    "reval": {"x": 1212, "y": 184},
    "abo": {"x": 1112, "y": 120},
    "viborg": {"x": 1363, "y": 104},
    "narva": {"x": 1346, "y": 191},
    "nowgorod": {"x": 1470, "y": 251},
}

TRADE_ROUTES = [
    ("hamburg", "london"),
    ("hamburg", "bruegge"),
    ("hamburg", "bergen"),
    ("hamburg", "luebeck"),
    ("luebeck", "visby"),
    ("luebeck", "danzig"),
    ("visby", "riga"),
    ("visby", "reval"),
    ("riga", "nowgorod"),
    ("danzig", "koenigsberg"),
]

LABEL_OFFSETS = {
    "london": (10, 14),
    "bruegge": (10, 16),
    "koeln": (10, 16),
    "hamburg": (-62, 18),
    "luebeck": (12, -10),
    "wismar": (-56, -10),
    "rostock": (12, -10),
    "stralsund": (12, -8),
    "greifswald": (12, 12),
    "stettin": (12, 16),
    "malmoe": (12, -8),
    "skanor_falsterbo": (-76, 16),
    "helsingborg": (12, 0),
    "aalborg": (12, 0),
    "kopenhagen": (12, 0),
    "oslo": (12, 0),
    "bergen": (12, 8),
    "stockholm": (12, 0),
    "kalmar": (12, 0),
    "visby": (12, 0),
    "danzig": (12, 14),
    "elbing": (12, 12),
    "koenigsberg": (12, 12),
    "memel": (12, 0),
    "riga": (12, 0),
    "reval": (12, 0),
    "abo": (12, 0),
    "viborg": (12, 0),
    "narva": (12, 0),
    "nowgorod": (12, 0),
    "bremen": (-58, 12),
}

HISTORICAL_WATERWAY_REFERENCES = [
    {
        "id": "thames_london",
        "name": "Thames to London",
        "kind": "tidal_river",
        "cities": ["london"],
        "basis": "London Hanse kontor at the Steelyard on the Thames.",
        "source_names": ["Thames"],
    },
    {
        "id": "zwin_bruegge",
        "name": "Zwin, Damme and Reie access to Bruegge",
        "kind": "tidal_inlet",
        "cities": ["bruegge"],
        "basis": "Bruges used the medieval Zwin inlet, with Damme and Sluis as access points.",
        "source_names": [],
    },
    {
        "id": "rhine_koeln",
        "name": "Lower Rhine to Koeln",
        "kind": "river",
        "cities": ["koeln"],
        "basis": "Cologne's Hanseatic trade used its Rhine harbour and lower Rhine route.",
        "source_names": ["Rhine"],
    },
    {
        "id": "weser_bremen",
        "name": "Weser to Bremen",
        "kind": "river",
        "cities": ["bremen"],
        "basis": "Bremen's maritime access followed the Weser; the medieval quay lay on the riverside.",
        "source_names": ["Weser"],
    },
    {
        "id": "elbe_hamburg",
        "name": "Elbe to Hamburg",
        "kind": "tidal_river",
        "cities": ["hamburg"],
        "basis": "Hamburg is an Elbe port, roughly 100 km from the North Sea.",
        "source_names": ["Elbe"],
    },
    {
        "id": "trave_luebeck",
        "name": "Trave from Travemuende to Luebeck",
        "kind": "river",
        "cities": ["luebeck"],
        "basis": "Luebeck's harbour lay on the Trave near the Baltic.",
        "source_names": [],
    },
    {
        "id": "warnow_rostock",
        "name": "Unterwarnow to Rostock",
        "kind": "river_estuary",
        "cities": ["rostock"],
        "basis": "Rostock developed on the Warnow; Warnemuende secured Baltic access.",
        "source_names": [],
    },
    {
        "id": "ryck_greifswald",
        "name": "Ryck to Greifswald",
        "kind": "river",
        "cities": ["greifswald"],
        "basis": "Greifswald's medieval Hanseatic port used the Ryck near Greifswalder Bay.",
        "source_names": [],
    },
    {
        "id": "oder_stettin",
        "name": "Oder and lagoon access to Stettin",
        "kind": "river_lagoon",
        "cities": ["stettin"],
        "basis": "Stettin/Szczecin was reached through the Oder system and Baltic lagoon waters.",
        "source_names": ["Oder"],
    },
    {
        "id": "vistula_danzig",
        "name": "Vistula and Motlawa access to Danzig",
        "kind": "delta_river",
        "cities": ["danzig"],
        "basis": "Danzig/Gdansk stood at the Vistula-Baltic nexus; the old port used the Motlawa.",
        "source_names": ["Vistula"],
    },
    {
        "id": "pregel_koenigsberg",
        "name": "Pregel and lagoon access to Koenigsberg",
        "kind": "river_lagoon",
        "cities": ["koenigsberg"],
        "basis": "Koenigsberg/Kaliningrad used the Pregel/Pregolya and lagoon route to the Baltic.",
        "source_names": [],
    },
    {
        "id": "daugava_riga",
        "name": "Daugava to Riga",
        "kind": "river",
        "cities": ["riga"],
        "basis": "Riga's medieval port developed by the Daugava/Ridzene waters.",
        "source_names": ["Daugava"],
    },
    {
        "id": "scania_herring_ports",
        "name": "Scania herring ports around Oresund",
        "kind": "coastal_market",
        "cities": ["malmoe", "skanor_falsterbo", "helsingborg"],
        "basis": "The Scania herring market connected Oresund coastal towns with merchants from Luebeck and other Hanseatic towns.",
        "source_names": [],
    },
    {
        "id": "kalmar_sound",
        "name": "Kalmar Sound trading access",
        "kind": "coastal_sound",
        "cities": ["kalmar"],
        "basis": "Kalmar was a Baltic trading place with connections to the Hanseatic League.",
        "source_names": [],
    },
    {
        "id": "aura_turku",
        "name": "Aura river harbour to Abo/Turku",
        "kind": "river_harbour",
        "cities": ["abo"],
        "basis": "Turku's German Hanseatic trade concentrated around the river harbour in the late 13th century.",
        "source_names": [],
    },
    {
        "id": "viborg_bay",
        "name": "Viborg Bay trading access",
        "kind": "coastal_bay",
        "cities": ["viborg"],
        "basis": "Viborg traded goods from Novgorod, with trade mainly controlled by Hanseatic merchants.",
        "source_names": [],
    },
    {
        "id": "narva_river",
        "name": "Narva river and Gulf of Finland access",
        "kind": "river_port",
        "cities": ["narva"],
        "basis": "Narva's medieval trade role depended on its river and Gulf of Finland route between Livonia and Russian trade.",
        "source_names": [],
    },
    {
        "id": "elbing_lagoon",
        "name": "Elbing river and Vistula Lagoon access",
        "kind": "river_lagoon",
        "cities": ["elbing"],
        "basis": "Elbing joined the Hanseatic League in the late 13th century and operated as a Baltic commercial port.",
        "source_names": [],
    },
    {
        "id": "memel_curonian_lagoon",
        "name": "Memel and Curonian Lagoon access",
        "kind": "lagoon_port",
        "cities": ["memel"],
        "basis": "Memel/Klaipeda was involved in maritime trade from the 13th century at the Curonian Lagoon outlet.",
        "source_names": [],
    },
    {
        "id": "aalborg_limfjord",
        "name": "Aalborg Bay and Limfjord access",
        "kind": "fjord_port",
        "cities": ["aalborg"],
        "basis": "Aalborg controlled a Limfjord crossing and had maritime access through Aalborg Bay.",
        "source_names": [],
    },
    {
        "id": "volkhov_nowgorod",
        "name": "Neva, Ladoga and Volkhov route to Nowgorod",
        "kind": "river_lake_route",
        "cities": ["nowgorod"],
        "basis": "Novgorod was connected to Baltic trade through the Neva, Lake Ladoga and Volkhov route.",
        "source_names": ["Neva", "Volkhov"],
    },
]


def download(url: str, filename: str) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = CACHE_DIR / filename
    if not path.exists():
        with urllib.request.urlopen(url, timeout=30) as response:
            path.write_bytes(response.read())
    return path


def project(lon: float, lat: float) -> tuple[float, float]:
    x = (lon - LON_MIN) * COS_CENTER
    y = lat
    return x, y


def pixel(lon: float, lat: float) -> dict[str, int]:
    x, y = project(lon, lat)
    x_min, y_min = project(LON_MIN, LAT_MIN)
    x_max, y_max = project(LON_MAX, LAT_MAX)
    return {
        "x": int(round((x - x_min) / (x_max - x_min) * WIDTH)),
        "y": int(round((y_max - y) / (y_max - y_min) * HEIGHT)),
    }


def lon_lat_from_pixel(x: int, y: int) -> tuple[float, float]:
    x_min, _ = project(LON_MIN, LAT_MIN)
    x_max, y_max = project(LON_MAX, LAT_MAX)
    _, y_min = project(LON_MIN, LAT_MIN)
    projected_x = float(x) / WIDTH * (x_max - x_min) + x_min
    lat = y_max - float(y) / HEIGHT * (y_max - y_min)
    lon = projected_x / COS_CENTER + LON_MIN
    return lon, lat


def geometry_bounds(coords: list) -> tuple[float, float, float, float]:
    points: list[tuple[float, float]] = []

    def collect(value: list) -> None:
        if not value:
            return
        if isinstance(value[0], (int, float)):
            points.append((float(value[0]), float(value[1])))
            return
        for item in value:
            collect(item)

    collect(coords)
    lons = [point[0] for point in points]
    lats = [point[1] for point in points]
    return min(lons), min(lats), max(lons), max(lats)


def intersects_map(coords: list) -> bool:
    lon_min, lat_min, lon_max, lat_max = geometry_bounds(coords)
    return not (lon_max < LON_MIN or lon_min > LON_MAX or lat_max < LAT_MIN or lat_min > LAT_MAX)


def projected_ring(ring: list[list[float]]) -> np.ndarray:
    return np.array([project(float(lon), float(lat)) for lon, lat in ring])


def add_polygon(ax, polygon: list, face: str) -> None:
    if not intersects_map(polygon):
        return

    exterior = projected_ring(polygon[0])
    if len(exterior) < 3:
        return

    vertices = exterior.tolist()
    codes = [MplPath.MOVETO] + [MplPath.LINETO] * (len(exterior) - 2) + [MplPath.CLOSEPOLY]
    path = MplPath(vertices, codes)
    ax.add_patch(PathPatch(path, facecolor=face, edgecolor="none", linewidth=0.0, zorder=3))


def draw_geography(ax) -> None:
    country_data = json.loads(download(COUNTRIES_URL, "ne_50m_admin_0_countries.geojson").read_text(encoding="utf-8"))
    for feature in country_data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            add_polygon(ax, polygon, "#526345")

    river_data = json.loads(download(RIVERS_URL, "ne_10m_rivers_lake_centerlines.geojson").read_text(encoding="utf-8"))
    for feature in river_data["features"]:
        coords = feature["geometry"].get("coordinates", [])
        if not coords or not intersects_map(coords):
            continue
        lines = coords if feature["geometry"]["type"] == "MultiLineString" else [coords]
        for line in lines:
            points = np.array([project(float(lon), float(lat)) for lon, lat in line])
            ax.plot(points[:, 0], points[:, 1], color="#47717d", linewidth=2.2, alpha=0.34, solid_capstyle="round", zorder=4)
            ax.plot(points[:, 0], points[:, 1], color="#83b7c2", linewidth=1.25, alpha=0.62, solid_capstyle="round", zorder=5)


def draw_background(ax) -> None:
    x_min, y_min = project(LON_MIN, LAT_MIN)
    x_max, y_max = project(LON_MAX, LAT_MAX)
    rng = np.random.default_rng(8)
    sea_noise = rng.normal(0.0, 0.04, (220, 390))
    y_grad = np.linspace(0.78, 1.0, sea_noise.shape[0])[:, None]
    sea = np.clip(y_grad + sea_noise, 0.68, 1.0)
    ax.imshow(
        sea,
        extent=(x_min, x_max, y_min, y_max),
        origin="lower",
        cmap="GnBu",
        alpha=0.72,
        interpolation="bicubic",
        zorder=0,
    )
    ax.add_patch(Rectangle((x_min, y_min), x_max - x_min, y_max - y_min, color="#385d6b", alpha=0.18, zorder=1))

    for lat in range(50, 63, 2):
        _, y = project(LON_MIN, lat)
        ax.plot([x_min, x_max], [y, y], color="#d8e0d2", alpha=0.08, linewidth=0.8, zorder=2)
    for lon in range(-5, 35, 5):
        x, _ = project(lon, LAT_MIN)
        ax.plot([x, x], [y_min, y_max], color="#d8e0d2", alpha=0.08, linewidth=0.8, zorder=2)


def city_by_id(city_id: str) -> dict:
    return next(city for city in HANSE_CITIES if city["id"] == city_id)


def city_marker_lon_lat(city: dict) -> tuple[float, float]:
    if city["id"] in WATER_ALIGNED_MARKER_PIXELS:
        marker = WATER_ALIGNED_MARKER_PIXELS[city["id"]]
        return lon_lat_from_pixel(marker["x"], marker["y"])
    return float(city.get("marker_lon", city["lon"])), float(city.get("marker_lat", city["lat"]))


def city_marker_pixel(city: dict) -> dict[str, int]:
    if city["id"] in WATER_ALIGNED_MARKER_PIXELS:
        marker = WATER_ALIGNED_MARKER_PIXELS[city["id"]]
        return {"x": marker["x"], "y": marker["y"]}
    return pixel(*city_marker_lon_lat(city))


def draw_route(ax, start_id: str, end_id: str) -> None:
    start = city_by_id(start_id)
    end = city_by_id(end_id)
    start_xy = project(*city_marker_lon_lat(start))
    end_xy = project(*city_marker_lon_lat(end))
    curve = 0.16 if start_xy[0] < end_xy[0] else -0.16
    patch = FancyArrowPatch(
        start_xy,
        end_xy,
        connectionstyle=f"arc3,rad={curve}",
        arrowstyle="-",
        linewidth=2.0,
        color="#d7ae58",
        alpha=0.76,
        zorder=7,
    )
    ax.add_patch(patch)


def draw_cities(ax) -> None:
    colors = {
        "core": "#f7cf61",
        "kontor": "#ef9a54",
        "member": "#e8d7a0",
        "trade": "#cbd6b1",
    }
    for city in HANSE_CITIES:
        x, y = project(*city_marker_lon_lat(city))
        radius = 0.105 if city["kind"] in ("core", "kontor") else 0.075
        ax.add_patch(Circle((x, y), radius * 1.75, color="#1d2118", alpha=0.50, zorder=8))
        ax.add_patch(Circle((x, y), radius, color=colors[city["kind"]], ec="#25190b", lw=0.9, zorder=9))
        off_x, off_y = LABEL_OFFSETS.get(city["id"], (10, 8))
        ax.annotate(
            city["name"],
            xy=(x, y),
            xytext=(off_x, off_y),
            textcoords="offset points",
            fontsize=8.5 if city["kind"] in ("core", "kontor") else 7.5,
            color="#f5eed6",
            path_effects=[pe.withStroke(linewidth=2.0, foreground="#1d2118")],
            zorder=10,
        )


def draw_annotations(ax) -> None:
    title_x, title_y = project(-5.25, 61.55)
    title_effect = [pe.withStroke(linewidth=3.0, foreground="#18303a")]
    ax.text(
        title_x,
        title_y,
        "Ehemalige Hanseregion",
        fontsize=25,
        color="#fbf0cf",
        weight="bold",
        path_effects=title_effect,
        zorder=11,
    )
    ax.text(
        title_x,
        title_y - 0.42,
        "Nordsee- und Ostseeraum, ca. 13.-15. Jh.",
        fontsize=11,
        color="#e5d9b9",
        path_effects=title_effect,
        zorder=11,
    )

    for label, lon, lat, size in [
        ("Nordsee", 3.1, 56.0, 16),
        ("Ostsee", 18.5, 56.2, 16),
        ("Skagerrak", 8.6, 58.1, 10),
    ]:
        x, y = project(lon, lat)
        ax.text(x, y, label, fontsize=size, color="#d9e8e5", alpha=0.52, style="italic", zorder=5)


def write_metadata() -> None:
    city_pixels = {}
    for city in HANSE_CITIES:
        marker_lon, marker_lat = city_marker_lon_lat(city)
        city_pixels[city["id"]] = {
            "name": city["name"],
            "lon": city["lon"],
            "lat": city["lat"],
            "marker_lon": marker_lon,
            "marker_lat": marker_lat,
            "position": city_marker_pixel(city),
            "kind": city["kind"],
        }

    data = {
        "image": OUTPUT_IMAGE.name,
        "source_size": {"x": WIDTH, "y": HEIGHT},
        "projection": "equirectangular adjusted by cosine of center latitude",
        "bounds": {"lon_min": LON_MIN, "lon_max": LON_MAX, "lat_min": LAT_MIN, "lat_max": LAT_MAX},
        "data_sources": [
            "Natural Earth 1:50m Admin 0 countries",
            "Natural Earth 1:10m rivers and lake centerlines",
            "Researched historical waterway references for selected Hanse cities",
        ],
        "historical_waterways": [
            {
                "id": reference["id"],
                "name": reference["name"],
                "kind": reference["kind"],
                "cities": reference["cities"],
                "basis": reference["basis"],
                "source_names": reference["source_names"],
            }
            for reference in HISTORICAL_WATERWAY_REFERENCES
        ],
        "city_pixels": city_pixels,
    }
    OUTPUT_META.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    x_min, y_min = project(LON_MIN, LAT_MIN)
    x_max, y_max = project(LON_MAX, LAT_MAX)

    fig, ax = plt.subplots(figsize=(16, 9), dpi=100)
    fig.subplots_adjust(0, 0, 1, 1)
    ax.set_xlim(x_min, x_max)
    ax.set_ylim(y_min, y_max)
    ax.set_axis_off()

    draw_background(ax)
    draw_geography(ax)
    draw_annotations(ax)

    fig.savefig(OUTPUT_IMAGE, dpi=100, facecolor="#385d6b")
    plt.close(fig)
    write_metadata()
    print(f"Wrote {OUTPUT_IMAGE}")
    print(f"Wrote {OUTPUT_META}")


if __name__ == "__main__":
    main()
