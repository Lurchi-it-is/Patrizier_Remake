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
RIVERS_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_rivers_lake_centerlines.geojson"

WIDTH = 1600
HEIGHT = 900
LON_MIN = -6.0
LON_MAX = 34.6
LAT_MIN = 49.3
LAT_MAX = 62.1
CENTER_LAT = (LAT_MIN + LAT_MAX) * 0.5
COS_CENTER = math.cos(math.radians(CENTER_LAT))

HANSE_CITIES = [
    {"id": "london", "name": "London", "lon": -0.1276, "lat": 51.5072, "kind": "kontor"},
    {"id": "bruegge", "name": "Bruegge", "lon": 3.2247, "lat": 51.2093, "kind": "kontor"},
    {"id": "koeln", "name": "Koeln", "lon": 6.9603, "lat": 50.9375, "kind": "member"},
    {"id": "bremen", "name": "Bremen", "lon": 8.8017, "lat": 53.0793, "kind": "member"},
    {"id": "hamburg", "name": "Hamburg", "lon": 9.9937, "lat": 53.5511, "kind": "core"},
    {"id": "luebeck", "name": "Luebeck", "lon": 10.6866, "lat": 53.8655, "kind": "core"},
    {"id": "wismar", "name": "Wismar", "lon": 11.4629, "lat": 53.8931, "kind": "member"},
    {"id": "rostock", "name": "Rostock", "lon": 12.0991, "lat": 54.0924, "kind": "member"},
    {"id": "stralsund", "name": "Stralsund", "lon": 13.0770, "lat": 54.3091, "kind": "member"},
    {"id": "greifswald", "name": "Greifswald", "lon": 13.3815, "lat": 54.0958, "kind": "member"},
    {"id": "stettin", "name": "Stettin", "lon": 14.5528, "lat": 53.4285, "kind": "member"},
    {"id": "kopenhagen", "name": "Kopenhagen", "lon": 12.5683, "lat": 55.6761, "kind": "trade"},
    {"id": "oslo", "name": "Oslo", "lon": 10.7522, "lat": 59.9139, "kind": "trade"},
    {"id": "bergen", "name": "Bergen", "lon": 5.3221, "lat": 60.3929, "kind": "kontor"},
    {"id": "stockholm", "name": "Stockholm", "lon": 18.0686, "lat": 59.3293, "kind": "trade"},
    {"id": "visby", "name": "Visby", "lon": 18.2948, "lat": 57.6348, "kind": "core"},
    {"id": "danzig", "name": "Danzig", "lon": 18.6466, "lat": 54.3520, "kind": "member"},
    {"id": "koenigsberg", "name": "Koenigsberg", "lon": 20.5106, "lat": 54.7104, "kind": "member"},
    {"id": "riga", "name": "Riga", "lon": 24.1052, "lat": 56.9496, "kind": "kontor"},
    {"id": "reval", "name": "Reval", "lon": 24.7536, "lat": 59.4370, "kind": "member"},
    {"id": "nowgorod", "name": "Nowgorod", "lon": 31.2755, "lat": 58.5228, "kind": "kontor"},
]

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
    "kopenhagen": (12, 0),
    "oslo": (12, 0),
    "bergen": (12, 8),
    "stockholm": (12, 0),
    "visby": (12, 0),
    "danzig": (12, 14),
    "koenigsberg": (12, 12),
    "riga": (12, 0),
    "reval": (12, 0),
    "nowgorod": (12, 0),
    "bremen": (-58, 12),
}


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


def add_polygon(ax, polygon: list, face: str, edge: str) -> None:
    if not intersects_map(polygon):
        return

    exterior = projected_ring(polygon[0])
    if len(exterior) < 3:
        return

    vertices = exterior.tolist()
    codes = [MplPath.MOVETO] + [MplPath.LINETO] * (len(exterior) - 2) + [MplPath.CLOSEPOLY]
    path = MplPath(vertices, codes)
    ax.add_patch(PathPatch(path, facecolor=face, edgecolor=edge, linewidth=0.7, zorder=3))


def draw_geography(ax) -> None:
    country_data = json.loads(download(COUNTRIES_URL, "ne_50m_admin_0_countries.geojson").read_text(encoding="utf-8"))
    for feature in country_data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            add_polygon(ax, polygon, "#526345", "#31402f")

    river_data = json.loads(download(RIVERS_URL, "ne_50m_rivers_lake_centerlines.geojson").read_text(encoding="utf-8"))
    for feature in river_data["features"]:
        coords = feature["geometry"].get("coordinates", [])
        if not coords or not intersects_map(coords):
            continue
        lines = coords if feature["geometry"]["type"] == "MultiLineString" else [coords]
        for line in lines:
            points = np.array([project(float(lon), float(lat)) for lon, lat in line])
            ax.plot(points[:, 0], points[:, 1], color="#6e99a9", linewidth=0.8, alpha=0.55, zorder=4)


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


def draw_route(ax, start_id: str, end_id: str) -> None:
    start = city_by_id(start_id)
    end = city_by_id(end_id)
    start_xy = project(start["lon"], start["lat"])
    end_xy = project(end["lon"], end["lat"])
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
        x, y = project(city["lon"], city["lat"])
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
    city_pixels = {
        city["id"]: {
            "name": city["name"],
            "lon": city["lon"],
            "lat": city["lat"],
            "position": pixel(city["lon"], city["lat"]),
            "kind": city["kind"],
        }
        for city in HANSE_CITIES
    }
    data = {
        "image": OUTPUT_IMAGE.name,
        "source_size": {"x": WIDTH, "y": HEIGHT},
        "projection": "equirectangular adjusted by cosine of center latitude",
        "bounds": {"lon_min": LON_MIN, "lon_max": LON_MAX, "lat_min": LAT_MIN, "lat_max": LAT_MAX},
        "data_sources": [
            "Natural Earth 1:50m Admin 0 countries",
            "Natural Earth 1:50m rivers and lake centerlines",
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
