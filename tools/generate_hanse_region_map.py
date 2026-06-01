from __future__ import annotations

import json
import heapq
import math
import argparse
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
OUTPUT_NAVIGATION = ASSET_DIR / "hanse_navigation_1600x900.json"
OUTPUT_NAVIGATION_DEBUG = ASSET_DIR / "hanse_navigation_debug_1600x900.png"
CACHE_DIR = ROOT / ".cache" / "map_data"
COUNTRIES_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson"
RIVERS_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson"

WIDTH = 1600
HEIGHT = 900
NAV_GRID_CELL_SIZE = 2
NAV_GRID_WIDTH = WIDTH // NAV_GRID_CELL_SIZE
NAV_GRID_HEIGHT = HEIGHT // NAV_GRID_CELL_SIZE
NAV_RIVER_RADIUS_CELLS = 4
NAV_HARBOR_RADIUS_CELLS = 2
NAV_SEA_GATE_RADIUS_CELLS = 3
NAV_WATER_COVERAGE_THRESHOLD = 0.42
LON_MIN = -6.0
LON_MAX = 34.6
LAT_MIN = 49.3
LAT_MAX = 62.1
CENTER_LAT = (LAT_MIN + LAT_MAX) * 0.5
COS_CENTER = math.cos(math.radians(CENTER_LAT))
SEA_DEEP = "#15323a"
SEA_MID = "#2a6169"
SEA_SHALLOW = "#6f988c"
LAND_BASE = "#566743"
LAND_FIELD = "#897e55"
LAND_FOREST = "#304b32"
LAND_HIGHLAND = "#817760"
LAND_CROP = "#a79961"
LAND_MEADOW = "#728654"
LAND_WETLAND = "#53664f"
LAND_ROCK = "#6f6d63"
LAND_SHADOW = "#263421"
RIVER_DARK = "#1f4c56"
RIVER_LIGHT = "#79aebb"
CHART_LINE = "#dbc68d"
TITLE_TEXT = "#f4e6bf"
BRASS = "#c69a4f"
_SOURCE_LAND_MASK_CACHE: np.ndarray | None = None

HANSE_CITIES = [
    {"id": "london", "name": "London", "lon": -0.1276, "lat": 51.5072, "marker_lon": -0.102203, "marker_lat": 51.50906, "kind": "kontor"},
    {"id": "hull", "name": "Hull", "lon": -0.3274, "lat": 53.7676, "marker_lon": -0.3274, "marker_lat": 53.7676, "kind": "trade"},
    {"id": "boston", "name": "Boston", "lon": -0.0266, "lat": 52.9789, "marker_lon": -0.0266, "marker_lat": 52.9789, "kind": "trade"},
    {"id": "kings_lynn", "name": "King's Lynn", "lon": 0.3976, "lat": 52.7543, "marker_lon": 0.3976, "marker_lat": 52.7543, "kind": "trade"},
    {"id": "great_yarmouth", "name": "Great Yarmouth", "lon": 1.7305, "lat": 52.6072, "marker_lon": 1.7305, "marker_lat": 52.6072, "kind": "trade"},
    {"id": "bruegge", "name": "Bruegge", "lon": 3.2247, "lat": 51.2093, "marker_lon": 3.3000, "marker_lat": 51.2500, "kind": "kontor"},
    {"id": "koeln", "name": "Koeln", "lon": 6.9603, "lat": 50.9375, "marker_lon": 6.96461, "marker_lat": 50.934027, "kind": "member"},
    {"id": "kampen", "name": "Kampen", "lon": 5.9113, "lat": 52.5550, "marker_lon": 5.9113, "marker_lat": 52.5550, "kind": "member"},
    {"id": "bremen", "name": "Bremen", "lon": 8.8017, "lat": 53.0793, "marker_lon": 8.812918, "marker_lat": 53.070014, "kind": "member"},
    {"id": "stade", "name": "Stade", "lon": 9.4763, "lat": 53.5934, "marker_lon": 9.4763, "marker_lat": 53.5934, "kind": "member"},
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
    "hull": {"x": 250, "y": 588},
    "boston": {"x": 244, "y": 641},
    "kings_lynn": {"x": 257, "y": 651},
    "great_yarmouth": {"x": 307, "y": 657},
    "bruegge": {"x": 366, "y": 752},
    "koeln": {"x": 511, "y": 785},
    "kampen": {"x": 469, "y": 671},
    "bremen": {"x": 584, "y": 634},
    "stade": {"x": 610, "y": 598},
    "hamburg": {"x": 630, "y": 601},
    "luebeck": {"x": 666, "y": 566},
    "wismar": {"x": 681, "y": 562},
    "rostock": {"x": 715, "y": 549},
    "stralsund": {"x": 747, "y": 540},
    "greifswald": {"x": 770, "y": 558},
    "stettin": {"x": 805, "y": 590},
    "kopenhagen": {"x": 732, "y": 451},
    "malmoe": {"x": 746, "y": 457},
    "skanor_falsterbo": {"x": 743, "y": 471},
    "helsingborg": {"x": 736, "y": 426},
    "aalborg": {"x": 646, "y": 348},
    "oslo": {"x": 653, "y": 166},
    "bergen": {"x": 515, "y": 135},
    "stockholm": {"x": 949, "y": 195},
    "kalmar": {"x": 881, "y": 382},
    "visby": {"x": 1014, "y": 324},
    "danzig": {"x": 996, "y": 512},
    "elbing": {"x": 1006, "y": 536},
    "koenigsberg": {"x": 1036, "y": 514},
    "memel": {"x": 1068, "y": 450},
    "riga": {"x": 1186, "y": 362},
    "reval": {"x": 1212, "y": 184},
    "abo": {"x": 1112, "y": 120},
    "viborg": {"x": 1363, "y": 104},
    "narva": {"x": 1346, "y": 191},
    "nowgorod": {"x": 1470, "y": 251},
}

SEA_GATE_PIXELS = {
    "bruegge": {"x": 369, "y": 759},
    "koeln": {"x": 396, "y": 712},
    "kampen": {"x": 430, "y": 675},
    "bremen": {"x": 562, "y": 589},
    "stade": {"x": 579, "y": 578},
    "hamburg": {"x": 579, "y": 578},
    "stettin": {"x": 795, "y": 578},
    "riga": {"x": 1184, "y": 355},
    "nowgorod": {"x": 1415, "y": 152},
}

SEA_ACCESS_PATH_PIXELS = {
    "bruegge": [
        {"x": 366, "y": 752},
        {"x": 369, "y": 759},
    ],
    "koeln": [
        {"x": 510, "y": 786},
        {"x": 486, "y": 766},
        {"x": 456, "y": 742},
        {"x": 426, "y": 724},
        {"x": 398, "y": 710},
    ],
    "kampen": [
        {"x": 470, "y": 670},
        {"x": 452, "y": 674},
        {"x": 430, "y": 675},
    ],
    "bremen": [
        {"x": 586, "y": 634},
        {"x": 574, "y": 616},
        {"x": 566, "y": 600},
        {"x": 562, "y": 589},
    ],
    "stade": [
        {"x": 610, "y": 598},
        {"x": 594, "y": 586},
        {"x": 579, "y": 578},
    ],
    "hamburg": [
        {"x": 630, "y": 602},
        {"x": 610, "y": 594},
        {"x": 594, "y": 586},
        {"x": 579, "y": 578},
    ],
    "stettin": [
        {"x": 810, "y": 610},
        {"x": 804, "y": 594},
        {"x": 795, "y": 578},
    ],
    "riga": [
        {"x": 1186, "y": 362},
        {"x": 1184, "y": 355},
    ],
    "nowgorod": [
        {"x": 1470, "y": 250},
        {"x": 1448, "y": 222},
        {"x": 1430, "y": 184},
        {"x": 1415, "y": 152},
    ],
}

TRADE_ROUTES = [
    ("hamburg", "london"),
    ("london", "hull"),
    ("london", "boston"),
    ("london", "kings_lynn"),
    ("london", "great_yarmouth"),
    ("hamburg", "bruegge"),
    ("hamburg", "stade"),
    ("hamburg", "kampen"),
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
    "hull": (12, -12),
    "boston": (-58, -8),
    "kings_lynn": (12, 8),
    "great_yarmouth": (12, 2),
    "bruegge": (10, 16),
    "koeln": (10, 16),
    "kampen": (12, 10),
    "stade": (-46, -12),
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
        "id": "humber_hull",
        "name": "Humber and River Hull access to Hull",
        "kind": "estuary_port",
        "cities": ["hull"],
        "basis": "Hull exported wool, grain and lead and imported timber, oil seed and other Baltic goods through its Humber port.",
        "source_names": ["Humber"],
    },
    {
        "id": "witham_boston",
        "name": "Witham and Wash access to Boston",
        "kind": "river_wash_port",
        "cities": ["boston"],
        "basis": "Boston was a Hanse network port on England's east coast with river access inland and a major wool export trade.",
        "source_names": [],
    },
    {
        "id": "great_ouse_kings_lynn",
        "name": "Great Ouse and Wash access to King's Lynn",
        "kind": "river_wash_port",
        "cities": ["kings_lynn"],
        "basis": "King's Lynn preserved a late medieval Hanseatic Warehouse running down to the river, reflecting its Hanse trade role.",
        "source_names": [],
    },
    {
        "id": "yare_great_yarmouth",
        "name": "Yare estuary access to Great Yarmouth",
        "kind": "estuary_port",
        "cities": ["great_yarmouth"],
        "basis": "Great Yarmouth became a Hanse trading post after its role as a herring and wool export port on England's east coast.",
        "source_names": [],
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
        "id": "ijssel_kampen",
        "name": "IJssel and Zuiderzee access to Kampen",
        "kind": "river_sea_port",
        "cities": ["kampen"],
        "basis": "Kampen was a Hanseatic League member and leading commercial centre near the IJssel outflow into the Zuiderzee/IJsselmeer route.",
        "source_names": ["IJssel"],
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
        "id": "schwinge_elbe_stade",
        "name": "Schwinge and lower Elbe access to Stade",
        "kind": "river_elbe_port",
        "cities": ["stade"],
        "basis": "Stade was a Hanseatic League member and the leading port of the lower Elbe before Hamburg dominated that trade.",
        "source_names": ["Elbe"],
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


def load_country_data() -> dict:
    return json.loads(download(COUNTRIES_URL, "ne_50m_admin_0_countries.geojson").read_text(encoding="utf-8"))


def load_river_data() -> dict:
    return json.loads(download(RIVERS_URL, "ne_10m_rivers_lake_centerlines.geojson").read_text(encoding="utf-8"))


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


def grid_cell_from_pixel(position: dict[str, int]) -> tuple[int, int]:
    return (
        max(0, min(NAV_GRID_WIDTH - 1, int(position["x"]) // NAV_GRID_CELL_SIZE)),
        max(0, min(NAV_GRID_HEIGHT - 1, int(position["y"]) // NAV_GRID_CELL_SIZE)),
    )


def pixel_from_grid_cell(cell: tuple[int, int]) -> dict[str, int]:
    return {
        "x": int(cell[0] * NAV_GRID_CELL_SIZE + NAV_GRID_CELL_SIZE * 0.5),
        "y": int(cell[1] * NAV_GRID_CELL_SIZE + NAV_GRID_CELL_SIZE * 0.5),
    }


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


def hex_rgb(color: str) -> np.ndarray:
    value = color.lstrip("#")
    return np.array([int(value[index : index + 2], 16) / 255.0 for index in (0, 2, 4)])


def softened_noise(rows: int, cols: int, seed: int, passes: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    noise = rng.random((rows, cols))
    for _index in range(passes):
        noise = (
            noise
            + np.roll(noise, 1, axis=0)
            + np.roll(noise, -1, axis=0)
            + np.roll(noise, 1, axis=1)
            + np.roll(noise, -1, axis=1)
        ) / 5.0
    return noise


def world_extent() -> tuple[float, float, float, float]:
    x_min, y_min = project(LON_MIN, LAT_MIN)
    x_max, y_max = project(LON_MAX, LAT_MAX)
    return x_min, x_max, y_min, y_max


def lon_lat_grids(rows: int, cols: int) -> tuple[np.ndarray, np.ndarray]:
    x_min, x_max, y_min, y_max = world_extent()
    xs = np.linspace(x_min, x_max, cols)
    ys = np.linspace(y_min, y_max, rows)
    grid_x, lat_grid = np.meshgrid(xs, ys)
    lon_grid = grid_x / COS_CENTER + LON_MIN
    return lon_grid, lat_grid


def smoothstep(value: np.ndarray, lower: float, upper: float) -> np.ndarray:
    t = np.clip((value - lower) / (upper - lower), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def gaussian_2d(
    lon_grid: np.ndarray,
    lat_grid: np.ndarray,
    lon_center: float,
    lat_center: float,
    lon_width: float,
    lat_width: float,
) -> np.ndarray:
    lon_part = ((lon_grid - lon_center) / lon_width) ** 2
    lat_part = ((lat_grid - lat_center) / lat_width) ** 2
    return np.exp(-(lon_part + lat_part))


def build_sea_texture(rows: int, cols: int) -> np.ndarray:
    fine = softened_noise(rows, cols, 11, 2)
    broad = softened_noise(rows, cols, 12, 24)
    y_grad = np.linspace(0.20, 0.82, rows)[:, None]
    x_wave = np.sin(np.linspace(0.0, math.pi * 4.0, cols))[None, :] * 0.045
    depth = np.clip(y_grad + x_wave + broad * 0.26 + fine * 0.055 - 0.14, 0.0, 1.0)

    deep = hex_rgb(SEA_DEEP)
    mid = hex_rgb(SEA_MID)
    shallow = hex_rgb(SEA_SHALLOW)
    sea = np.empty((rows, cols, 3))
    lower = depth < 0.62
    lower_depth = depth[lower][:, None]
    sea[lower] = deep * (1.0 - lower_depth / 0.62) + mid * (lower_depth / 0.62)
    upper_depth = np.clip((depth - 0.62) / 0.38, 0.0, 1.0)
    upper_selected_depth = upper_depth[~lower][:, None]
    sea[~lower] = mid * (1.0 - upper_selected_depth) + shallow * upper_selected_depth

    wave = np.sin(np.linspace(0.0, math.pi * 22.0, cols))[None, :] * 0.010
    sea += wave[:, :, None] + (fine[:, :, None] - 0.5) * 0.035
    return np.clip(sea, 0.0, 1.0)


def build_land_texture(rows: int, cols: int) -> np.ndarray:
    lon_grid, lat_grid = lon_lat_grids(rows, cols)
    broad = softened_noise(rows, cols, 21, 28)
    medium = softened_noise(rows, cols, 22, 9)
    fine = softened_noise(rows, cols, 23, 2)
    parcel = softened_noise(rows, cols, 24, 2)
    ridge_noise = softened_noise(rows, cols, 25, 14)
    woodland_spots = softened_noise(rows, cols, 26, 3)
    field_patch = softened_noise(rows, cols, 27, 1)

    england_fields = gaussian_2d(lon_grid, lat_grid, -1.5, 52.8, 3.1, 1.9)
    low_country_fields = gaussian_2d(lon_grid, lat_grid, 6.2, 52.3, 4.3, 1.6)
    north_german_fields = gaussian_2d(lon_grid, lat_grid, 10.7, 53.3, 5.2, 1.2)
    danish_fields = gaussian_2d(lon_grid, lat_grid, 10.4, 55.7, 3.6, 1.1)
    polish_fields = gaussian_2d(lon_grid, lat_grid, 18.3, 52.8, 5.7, 1.8)
    baltic_fields = gaussian_2d(lon_grid, lat_grid, 23.0, 56.0, 4.6, 1.4)
    fields = np.maximum.reduce(
        [england_fields, low_country_fields, north_german_fields, danish_fields, polish_fields, baltic_fields]
    )
    fields = np.clip(fields * (0.56 + parcel * 0.62), 0.0, 1.0)

    scandinavian_forest = smoothstep(lat_grid, 55.7, 59.4) * gaussian_2d(lon_grid, lat_grid, 17.0, 59.0, 13.5, 4.8)
    baltic_forest = gaussian_2d(lon_grid, lat_grid, 25.2, 57.5, 6.2, 2.8)
    east_forest = gaussian_2d(lon_grid, lat_grid, 29.5, 58.2, 4.6, 2.4)
    upland_forest = gaussian_2d(lon_grid, lat_grid, 14.2, 50.5, 4.3, 1.1)
    forest = np.maximum.reduce([scandinavian_forest, baltic_forest, east_forest, upland_forest])
    scattered_woods = np.clip((woodland_spots - 0.58) * 4.8, 0.0, 1.0) * (1.0 - fields * 0.52)
    forest = np.clip(forest * (0.62 + broad * 0.74) + scattered_woods * 0.32 - fields * 0.34, 0.0, 1.0)

    norway_highland = gaussian_2d(lon_grid, lat_grid, 7.3, 60.0, 2.7, 3.4) * smoothstep(lat_grid, 56.8, 58.6)
    scotland_highland = gaussian_2d(lon_grid, lat_grid, -4.6, 57.0, 2.0, 2.1)
    swedish_highland = gaussian_2d(lon_grid, lat_grid, 13.0, 61.1, 4.5, 1.8)
    highland = np.clip(
        np.maximum.reduce([norway_highland, scotland_highland, swedish_highland]) * (0.72 + ridge_noise * 0.58),
        0.0,
        1.0,
    )

    wetlands = np.maximum(
        gaussian_2d(lon_grid, lat_grid, 4.8, 52.5, 2.2, 1.0),
        gaussian_2d(lon_grid, lat_grid, 8.7, 53.4, 3.8, 0.9),
    )
    wetlands = np.maximum(wetlands, gaussian_2d(lon_grid, lat_grid, 20.0, 54.4, 2.8, 0.8))
    wetlands = np.clip(wetlands * (0.45 + medium * 0.50), 0.0, 0.85)

    low = hex_rgb(LAND_BASE)
    field = hex_rgb(LAND_FIELD)
    crop = hex_rgb(LAND_CROP)
    meadow = hex_rgb(LAND_MEADOW)
    forest_color = hex_rgb(LAND_FOREST)
    highland_color = hex_rgb(LAND_HIGHLAND)
    wetland_color = hex_rgb(LAND_WETLAND)
    rock_color = hex_rgb(LAND_ROCK)
    field_mix = np.clip(parcel * 0.46 + field_patch * 0.54, 0.0, 1.0)
    field_pattern = meadow * (1.0 - field_mix[:, :, None] * 0.62) + crop * (field_mix[:, :, None] * 0.62)
    parcel_lines = np.sin((lon_grid * 3.3 + lat_grid * 4.8 + parcel * 3.5) * math.pi)
    field_pattern *= (0.96 + np.where(parcel_lines > 0.34, 0.045, -0.018))[:, :, None]
    land = low * (1.0 - medium[:, :, None] * 0.18) + field * (medium[:, :, None] * 0.18)
    land = land * (1.0 - fields[:, :, None] * 0.84) + field_pattern * (fields[:, :, None] * 0.84)
    land = land * (1.0 - wetlands[:, :, None] * 0.46) + wetland_color * (wetlands[:, :, None] * 0.46)
    land = land * (1.0 - forest[:, :, None] * 0.68) + forest_color * (forest[:, :, None] * 0.68)
    land = land * (1.0 - highland[:, :, None] * 0.58) + highland_color * (highland[:, :, None] * 0.32) + rock_color * (highland[:, :, None] * 0.26)

    height = highland * 1.35 + forest * 0.18 + broad * 0.18
    gradient_y, gradient_x = np.gradient(height)
    shade = np.clip(1.0 + gradient_y * 9.0 - gradient_x * 7.0, 0.76, 1.24)
    land *= shade[:, :, None]
    land += (fine[:, :, None] - 0.5) * 0.050
    land += (fields * (field_patch - 0.5))[:, :, None] * 0.070
    return np.clip(land, 0.0, 1.0)


def add_polygon(
    ax,
    polygon: list,
    face: str,
    edge: str = "none",
    linewidth: float = 0.0,
    alpha: float = 1.0,
    zorder: int = 3,
) -> None:
    if not intersects_map(polygon):
        return

    exterior = projected_ring(polygon[0])
    if len(exterior) < 3:
        return

    vertices = exterior.tolist()
    codes = [MplPath.MOVETO] + [MplPath.LINETO] * (len(exterior) - 2) + [MplPath.CLOSEPOLY]
    path = MplPath(vertices, codes)
    ax.add_patch(
        PathPatch(
            path,
            facecolor=face,
            edgecolor=edge,
            linewidth=linewidth,
            alpha=alpha,
            zorder=zorder,
        )
    )


def polygon_contains_points(polygon: list, points: np.ndarray) -> np.ndarray:
    exterior = projected_ring(polygon[0])
    if len(exterior) < 3:
        return np.zeros(points.shape[0], dtype=bool)

    mask = MplPath(exterior).contains_points(points)
    for interior_ring in polygon[1:]:
        interior = projected_ring(interior_ring)
        if len(interior) >= 3:
            mask &= ~MplPath(interior).contains_points(points)
    return mask


def build_source_land_mask(country_data: dict) -> np.ndarray:
    global _SOURCE_LAND_MASK_CACHE
    if _SOURCE_LAND_MASK_CACHE is not None:
        return _SOURCE_LAND_MASK_CACHE.copy()

    x_min, x_max, y_min, y_max = world_extent()
    xs = x_min + (np.arange(WIDTH, dtype=float) + 0.5) / float(WIDTH) * (x_max - x_min)
    ys = y_max - (np.arange(HEIGHT, dtype=float) + 0.5) / float(HEIGHT) * (y_max - y_min)
    grid_x, grid_y = np.meshgrid(xs, ys)
    points = np.column_stack([grid_x.ravel(), grid_y.ravel()])
    land = np.zeros(HEIGHT * WIDTH, dtype=bool)

    for feature in country_data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            if not intersects_map(polygon):
                continue

            land |= polygon_contains_points(polygon, points)

    _SOURCE_LAND_MASK_CACHE = land.reshape((HEIGHT, WIDTH))
    return _SOURCE_LAND_MASK_CACHE.copy()


def build_visual_land_mask(country_data: dict, rows: int, cols: int) -> np.ndarray:
    if rows == HEIGHT and cols == WIDTH:
        return np.flipud(build_source_land_mask(country_data))

    x_min, x_max, y_min, y_max = world_extent()
    xs = x_min + (np.arange(cols, dtype=float) + 0.5) / float(cols) * (x_max - x_min)
    ys = y_min + (np.arange(rows, dtype=float) + 0.5) / float(rows) * (y_max - y_min)
    grid_x, grid_y = np.meshgrid(xs, ys)
    points = np.column_stack([grid_x.ravel(), grid_y.ravel()])
    land = np.zeros(rows * cols, dtype=bool)

    for feature in country_data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            if intersects_map(polygon):
                land |= polygon_contains_points(polygon, points)

    return land.reshape((rows, cols))


def draw_geography(ax) -> None:
    country_data = load_country_data()
    x_min, x_max, y_min, y_max = world_extent()
    rows, cols = HEIGHT, WIDTH
    terrain = build_land_texture(rows, cols)
    land_mask = build_visual_land_mask(country_data, rows, cols)
    land_rgba = np.dstack([terrain, np.where(land_mask, 1.0, 0.0)])
    extent = (x_min, x_max, y_min, y_max)
    ax.imshow(land_rgba, extent=extent, origin="lower", interpolation="none", zorder=3)

    river_data = load_river_data()
    for feature in river_data["features"]:
        coords = feature["geometry"].get("coordinates", [])
        if not coords or not intersects_map(coords):
            continue
        lines = coords if feature["geometry"]["type"] == "MultiLineString" else [coords]
        for line in lines:
            points = np.array([project(float(lon), float(lat)) for lon, lat in line])
            ax.plot(points[:, 0], points[:, 1], color=RIVER_DARK, linewidth=2.8, alpha=0.28, solid_capstyle="round", zorder=5)
            ax.plot(points[:, 0], points[:, 1], color=RIVER_LIGHT, linewidth=1.2, alpha=0.56, solid_capstyle="round", zorder=6)


def draw_background(ax) -> None:
    x_min, x_max, y_min, y_max = world_extent()
    sea = build_sea_texture(280, 500)
    ax.imshow(
        sea,
        extent=(x_min, x_max, y_min, y_max),
        origin="lower",
        interpolation="bicubic",
        zorder=0,
    )
    ax.add_patch(Rectangle((x_min, y_min), x_max - x_min, y_max - y_min, color="#061216", alpha=0.08, zorder=1))


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
    return


def draw_compass_rose(ax) -> None:
    x, y = project(-4.75, 50.15)
    radius = 0.42
    ax.add_patch(Circle((x, y), radius, fill=False, edgecolor=BRASS, linewidth=1.2, alpha=0.62, zorder=11))
    for angle, length, linewidth in [
        (math.pi / 2.0, radius * 1.55, 1.8),
        (0.0, radius * 1.05, 1.0),
        (math.pi, radius * 1.05, 1.0),
        (math.pi * 1.5, radius * 1.05, 1.0),
    ]:
        ax.plot(
            [x, x + math.cos(angle) * length],
            [y, y + math.sin(angle) * length],
            color=BRASS,
            alpha=0.72,
            linewidth=linewidth,
            zorder=11,
        )
    ax.text(
        x,
        y + radius * 1.78,
        "N",
        fontsize=8,
        color=TITLE_TEXT,
        ha="center",
        va="center",
        path_effects=[pe.withStroke(linewidth=1.5, foreground="#18303a")],
        zorder=11,
    )


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
            "Pixel-derived land/water contour mask from the current map image",
            "Researched historical waterway references for selected Hanse cities",
        ],
        "visual_style": {
            "name": "illustrated_hanse_strategy_map",
            "basis": "Hand-painted Hanse-era strategy map background with accurate coastline-first composition, restrained historical waterway visibility, readable forests, wetlands, coastal lowlands and plausible highland regions. North German Plain, Denmark and the southern Baltic coast remain flat; larger mountains are limited to Norway, Scotland and the southern map edge.",
        },
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


def land_polygons(country_data: dict) -> list:
    polygons: list = []
    for feature in country_data["features"]:
        geometry = feature["geometry"]
        feature_polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in feature_polygons:
            if intersects_map(polygon):
                polygons.append(polygon)
    return polygons


def build_navigation_sea_mask(country_data: dict) -> np.ndarray:
    source_water = np.logical_not(build_source_land_mask(country_data))
    water_coverage = source_water.reshape(
        NAV_GRID_HEIGHT,
        NAV_GRID_CELL_SIZE,
        NAV_GRID_WIDTH,
        NAV_GRID_CELL_SIZE,
    ).mean(axis=(1, 3))
    return flood_connected_from_edges(water_coverage >= NAV_WATER_COVERAGE_THRESHOLD)


def line_pixel_points(line: list) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for lon, lat in line:
        pixel_position = pixel(float(lon), float(lat))
        points.append((float(pixel_position["x"]), float(pixel_position["y"])))
    return points


def mark_water_circle(water: np.ndarray, gx: int, gy: int, radius_cells: int) -> None:
    for y in range(max(0, gy - radius_cells), min(NAV_GRID_HEIGHT, gy + radius_cells + 1)):
        for x in range(max(0, gx - radius_cells), min(NAV_GRID_WIDTH, gx + radius_cells + 1)):
            if (x - gx) * (x - gx) + (y - gy) * (y - gy) <= radius_cells * radius_cells:
                water[y, x] = True


def flood_connected_from_edges(water: np.ndarray) -> np.ndarray:
    connected = np.zeros((NAV_GRID_HEIGHT, NAV_GRID_WIDTH), dtype=bool)
    queue: list[tuple[int, int]] = []

    for x in range(NAV_GRID_WIDTH):
        for y in (0, NAV_GRID_HEIGHT - 1):
            if water[y, x] and not connected[y, x]:
                connected[y, x] = True
                queue.append((x, y))

    for y in range(NAV_GRID_HEIGHT):
        for x in (0, NAV_GRID_WIDTH - 1):
            if water[y, x] and not connected[y, x]:
                connected[y, x] = True
                queue.append((x, y))

    head = 0
    while head < len(queue):
        x, y = queue[head]
        head += 1
        for neighbor, _cost in route_neighbors(water, (x, y)):
            nx, ny = neighbor
            if connected[ny, nx]:
                continue
            connected[ny, nx] = True
            queue.append((nx, ny))

    return connected


def add_river_waterways(water: np.ndarray, river_data: dict) -> None:
    for feature in river_data["features"]:
        coords = feature["geometry"].get("coordinates", [])
        if not coords or not intersects_map(coords):
            continue

        lines = coords if feature["geometry"]["type"] == "MultiLineString" else [coords]
        for line in lines:
            points = line_pixel_points(line)
            for index in range(len(points) - 1):
                start = points[index]
                end = points[index + 1]
                dx = end[0] - start[0]
                dy = end[1] - start[1]
                steps = max(1, int(max(abs(dx), abs(dy)) / NAV_GRID_CELL_SIZE * 2))
                for step in range(steps + 1):
                    t = float(step) / float(steps)
                    px = start[0] + dx * t
                    py = start[1] + dy * t
                    gx = max(0, min(NAV_GRID_WIDTH - 1, int(px) // NAV_GRID_CELL_SIZE))
                    gy = max(0, min(NAV_GRID_HEIGHT - 1, int(py) // NAV_GRID_CELL_SIZE))
                    mark_water_circle(water, gx, gy, NAV_RIVER_RADIUS_CELLS)


def build_image_sea_water_mask() -> np.ndarray:
    if not OUTPUT_IMAGE.exists():
        country_data = load_country_data()
        return build_navigation_sea_mask(country_data)

    image = plt.imread(OUTPUT_IMAGE)
    if image.dtype.kind in ("u", "i"):
        image = image.astype(float) / 255.0
    if image.shape[2] > 3:
        image = image[:, :, :3]

    red = image[:, :, 0]
    green = image[:, :, 1]
    blue = image[:, :, 2]
    source_water = (
        (blue > red * 1.12)
        & (blue > green * 0.82)
        & (red < 0.42)
        & (green < 0.62)
        & ((blue - red) > 0.035)
    )
    source_water &= ~((red > 0.55) & (green > 0.55) & (blue > 0.55))
    water_coverage = source_water.reshape(
        NAV_GRID_HEIGHT,
        NAV_GRID_CELL_SIZE,
        NAV_GRID_WIDTH,
        NAV_GRID_CELL_SIZE,
    ).mean(axis=(1, 3))
    return flood_connected_from_edges(water_coverage >= NAV_WATER_COVERAGE_THRESHOLD)


def add_harbor_access_cells(water: np.ndarray) -> None:
    for city in HANSE_CITIES:
        gx, gy = grid_cell_from_pixel(city_marker_pixel(city))
        mark_water_circle(water, gx, gy, NAV_HARBOR_RADIUS_CELLS)


def nearest_water_cell(water: np.ndarray, position: dict[str, int]) -> tuple[int, int]:
    start_x, start_y = grid_cell_from_pixel(position)
    if water[start_y, start_x]:
        return start_x, start_y

    best_cell = (start_x, start_y)
    best_distance = float("inf")
    max_radius = max(NAV_GRID_WIDTH, NAV_GRID_HEIGHT)
    for radius in range(1, max_radius):
        found = False
        for y in range(max(0, start_y - radius), min(NAV_GRID_HEIGHT, start_y + radius + 1)):
            for x in range(max(0, start_x - radius), min(NAV_GRID_WIDTH, start_x + radius + 1)):
                if not water[y, x]:
                    continue
                distance = (x - start_x) * (x - start_x) + (y - start_y) * (y - start_y)
                if distance < best_distance:
                    best_distance = distance
                    best_cell = (x, y)
                    found = True
        if found:
            return best_cell

    return best_cell


def city_sea_gate_cell(city: dict, sea_water: np.ndarray, harbor_cell: tuple[int, int]) -> tuple[int, int]:
    if city["id"] in SEA_GATE_PIXELS:
        return nearest_water_cell(sea_water, SEA_GATE_PIXELS[city["id"]])

    direct_path = shortest_path_to_nearest(sea_water, harbor_cell, sea_water)
    if direct_path:
        return direct_path[-1]

    return nearest_water_cell(sea_water, city_marker_pixel(city))


def manual_access_path(city: dict, harbor_cell: tuple[int, int], sea_gate_cell: tuple[int, int]) -> list[tuple[int, int]]:
    if city["id"] not in SEA_ACCESS_PATH_PIXELS:
        return []

    cells: list[tuple[int, int]] = [harbor_cell]
    for point in SEA_ACCESS_PATH_PIXELS[city["id"]]:
        cell = grid_cell_from_pixel(point)
        if cell != cells[-1]:
            cells.append(cell)
    if cells[-1] != sea_gate_cell:
        cells.append(sea_gate_cell)
    return cells


def shortest_path_to_nearest(allowed: np.ndarray, start: tuple[int, int], target_mask: np.ndarray) -> list[tuple[int, int]]:
    start_id = encoded(start)
    distances: dict[int, float] = {start_id: 0.0}
    previous: dict[int, int] = {}
    queue: list[tuple[float, int]] = [(0.0, start_id)]

    while queue:
        distance, current_id = heapq.heappop(queue)
        if distance > distances[current_id]:
            continue

        current = decoded(current_id)
        if target_mask[current[1], current[0]]:
            return reconstruct_path(previous, start, current)

        for neighbor, step_cost in route_neighbors(allowed, current):
            neighbor_id = encoded(neighbor)
            next_distance = distance + step_cost
            if next_distance >= distances.get(neighbor_id, float("inf")):
                continue

            distances[neighbor_id] = next_distance
            previous[neighbor_id] = current_id
            heapq.heappush(queue, (next_distance, neighbor_id))

    return []


def route_neighbors(water: np.ndarray, cell: tuple[int, int]) -> list[tuple[tuple[int, int], float]]:
    neighbors: list[tuple[tuple[int, int], float]] = []
    x, y = cell
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue

            nx = x + dx
            ny = y + dy
            if nx < 0 or ny < 0 or nx >= NAV_GRID_WIDTH or ny >= NAV_GRID_HEIGHT:
                continue
            if not water[ny, nx]:
                continue
            if dx != 0 and dy != 0 and (not water[y, nx] or not water[ny, x]):
                continue

            neighbors.append(((nx, ny), 1.41421356237 if dx != 0 and dy != 0 else 1.0))
    return neighbors


def encoded(cell: tuple[int, int]) -> int:
    return cell[1] * NAV_GRID_WIDTH + cell[0]


def decoded(value: int) -> tuple[int, int]:
    return value % NAV_GRID_WIDTH, value // NAV_GRID_WIDTH


def shortest_paths_from(water: np.ndarray, start: tuple[int, int], targets: set[tuple[int, int]]) -> tuple[dict[int, float], dict[int, int]]:
    start_id = encoded(start)
    target_ids = {encoded(target) for target in targets}
    found_targets: set[int] = set()
    distances: dict[int, float] = {start_id: 0.0}
    previous: dict[int, int] = {}
    queue: list[tuple[float, int]] = [(0.0, start_id)]

    while queue and found_targets != target_ids:
        distance, current_id = heapq.heappop(queue)
        if distance > distances[current_id]:
            continue

        if current_id in target_ids:
            found_targets.add(current_id)

        current = decoded(current_id)
        for neighbor, step_cost in route_neighbors(water, current):
            neighbor_id = encoded(neighbor)
            next_distance = distance + step_cost
            if next_distance >= distances.get(neighbor_id, float("inf")):
                continue

            distances[neighbor_id] = next_distance
            previous[neighbor_id] = current_id
            heapq.heappush(queue, (next_distance, neighbor_id))

    return distances, previous


def reconstruct_path(previous: dict[int, int], start: tuple[int, int], target: tuple[int, int]) -> list[tuple[int, int]]:
    start_id = encoded(start)
    current_id = encoded(target)
    if current_id == start_id:
        return [start]
    if current_id not in previous:
        return []

    path = [decoded(current_id)]
    while current_id != start_id:
        current_id = previous[current_id]
        path.append(decoded(current_id))
    path.reverse()
    return path


def simplify_grid_path(path: list[tuple[int, int]]) -> list[tuple[int, int]]:
    if len(path) <= 2:
        return path

    simplified = [path[0]]
    last_direction = (path[1][0] - path[0][0], path[1][1] - path[0][1])
    for index in range(1, len(path) - 1):
        next_direction = (path[index + 1][0] - path[index][0], path[index + 1][1] - path[index][1])
        if next_direction != last_direction:
            simplified.append(path[index])
            last_direction = next_direction
    simplified.append(path[-1])
    return simplified


def route_distance_pixels(path: list[tuple[int, int]]) -> float:
    distance = 0.0
    for index in range(len(path) - 1):
        dx = path[index + 1][0] - path[index][0]
        dy = path[index + 1][1] - path[index][1]
        distance += math.sqrt(dx * dx + dy * dy) * NAV_GRID_CELL_SIZE
    return distance


def build_navigation_data() -> dict:
    river_data = load_river_data()
    sea_water = build_image_sea_water_mask()
    access_water = np.zeros((NAV_GRID_HEIGHT, NAV_GRID_WIDTH), dtype=bool)
    add_river_waterways(access_water, river_data)
    add_harbor_access_cells(access_water)
    water = np.logical_or(sea_water, access_water)

    city_harbors: dict[str, dict] = {}
    harbor_cells: dict[str, tuple[int, int]] = {}
    sea_gate_cells: dict[str, tuple[int, int]] = {}
    sea_access_paths: dict[str, list[tuple[int, int]]] = {}
    for city in HANSE_CITIES:
        city_position = city_marker_pixel(city)
        harbor_cell = nearest_water_cell(water, city_position)
        sea_gate_cell = city_sea_gate_cell(city, sea_water, harbor_cell)
        access_path = manual_access_path(city, harbor_cell, sea_gate_cell)
        if not access_path:
            access_path = reconstruct_path(shortest_paths_from(water, harbor_cell, {sea_gate_cell})[1], harbor_cell, sea_gate_cell)
        if not access_path:
            access_path = shortest_path_to_nearest(water, harbor_cell, sea_water)
        if not access_path:
            access_path = [harbor_cell, sea_gate_cell] if harbor_cell != sea_gate_cell else [harbor_cell]
        sea_gate_cell = access_path[-1]
        mark_water_circle(sea_water, sea_gate_cell[0], sea_gate_cell[1], NAV_SEA_GATE_RADIUS_CELLS)
        harbor_position = pixel_from_grid_cell(harbor_cell)
        sea_gate_position = pixel_from_grid_cell(sea_gate_cell)
        harbor_cells[city["id"]] = harbor_cell
        sea_gate_cells[city["id"]] = sea_gate_cell
        sea_access_paths[city["id"]] = access_path
        city_harbors[city["id"]] = {
            "name": city["name"],
            "city_position": city_position,
            "harbor_anchor": harbor_position,
            "sea_gate": sea_gate_position,
            "grid": {"x": harbor_cell[0], "y": harbor_cell[1]},
            "sea_grid": {"x": sea_gate_cell[0], "y": sea_gate_cell[1]},
            "anchor_distance_px": round(
                math.dist((city_position["x"], city_position["y"]), (harbor_position["x"], harbor_position["y"])),
                2,
            ),
            "sea_access_distance_px": round(route_distance_pixels(access_path), 2),
            "sea_access_points": [pixel_from_grid_cell(cell) for cell in simplify_grid_path(access_path)],
        }

    routes: dict[str, dict] = {}
    unreachable_routes: list[dict[str, str]] = []
    city_ids = [city["id"] for city in HANSE_CITIES]
    for source_id in city_ids:
        targets = {sea_gate_cells[target_id] for target_id in city_ids if target_id != source_id}
        distances, previous = shortest_paths_from(sea_water, sea_gate_cells[source_id], targets)
        for target_id in city_ids:
            if source_id == target_id:
                continue

            target_cell = sea_gate_cells[target_id]
            target_key = encoded(target_cell)
            if target_key not in distances:
                unreachable_routes.append({"from": source_id, "to": target_id})
                continue

            sea_path = reconstruct_path(previous, sea_gate_cells[source_id], target_cell)
            if not sea_path:
                unreachable_routes.append({"from": source_id, "to": target_id})
                continue

            target_access_path = sea_access_paths[target_id].copy()
            target_access_path.reverse()
            path = sea_access_paths[source_id] + sea_path[1:] + target_access_path[1:]
            simplified_path = simplify_grid_path(path)
            routes[f"{source_id}__{target_id}"] = {
                "from": source_id,
                "to": target_id,
                "distance_px": round(route_distance_pixels(path), 2),
                "sea_distance_px": round(route_distance_pixels(sea_path), 2),
                "points": [pixel_from_grid_cell(cell) for cell in simplified_path],
            }

    water_rows = ["".join("1" if bool(value) else "0" for value in row) for row in water]
    sea_rows = ["".join("1" if bool(value) else "0" for value in row) for row in sea_water]
    return {
        "source_size": {"x": WIDTH, "y": HEIGHT},
        "grid": {
            "cell_size": NAV_GRID_CELL_SIZE,
            "width": NAV_GRID_WIDTH,
            "height": NAV_GRID_HEIGHT,
            "rows": water_rows,
            "sea_rows": sea_rows,
        },
        "city_harbors": city_harbors,
        "routes": routes,
        "unreachable_routes": unreachable_routes,
    }


def write_navigation_data() -> None:
    navigation_data = build_navigation_data()
    OUTPUT_NAVIGATION.write_text(json.dumps(navigation_data, indent=2) + "\n", encoding="utf-8")

    water = np.array([[char == "1" for char in row] for row in navigation_data["grid"]["rows"]], dtype=bool)
    sea = np.array([[char == "1" for char in row] for row in navigation_data["grid"]["sea_rows"]], dtype=bool)
    access = np.logical_and(water, np.logical_not(sea))
    debug = np.zeros((NAV_GRID_HEIGHT, NAV_GRID_WIDTH, 3), dtype=float)
    debug[:, :, 0] = np.where(sea, 0.08, np.where(access, 0.18, 0.28))
    debug[:, :, 1] = np.where(sea, 0.36, np.where(access, 0.58, 0.34))
    debug[:, :, 2] = np.where(sea, 0.48, np.where(access, 0.72, 0.24))
    plt.imsave(OUTPUT_NAVIGATION_DEBUG, debug)
    print(f"Wrote {OUTPUT_NAVIGATION}")
    print(f"Wrote {OUTPUT_NAVIGATION_DEBUG}")


def render_map_image() -> None:
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

    fig.savefig(OUTPUT_IMAGE, dpi=100, facecolor=SEA_DEEP)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description="Update Hanse map metadata and navigation data.")
    parser.add_argument(
        "--render-map",
        action="store_true",
        help="Regenerate the base map image. Without this flag, the existing map image is kept and used as the navigation source.",
    )
    args = parser.parse_args()

    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    if args.render_map or not OUTPUT_IMAGE.exists():
        render_map_image()
        print(f"Wrote {OUTPUT_IMAGE}")
    else:
        print(f"Using existing {OUTPUT_IMAGE} as navigation source")

    write_metadata()
    write_navigation_data()
    print(f"Wrote {OUTPUT_META}")


if __name__ == "__main__":
    main()
