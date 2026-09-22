# rgeopalette

<img src="https://raw.githubusercontent.com/igorpawelec/rgeopalette/main/www/rgeopalette.png" alt="rgeopalette logo" align="right" width="200"/>

[![R-CMD-check](https://github.com/igorpawelec/rgeopalette/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/igorpawelec/rgeopalette/actions/workflows/R-CMD-check.yaml)
[![Release](https://img.shields.io/github/v/release/igorpawelec/rgeopalette)](https://github.com/igorpawelec/rgeopalette/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D%203.6-blue.svg)](https://www.r-project.org)

**Colour space conversions for geospatial raster data.**

Three RGB bands go in as matrices; the components of any of 15 colour spaces come out, as a named list or as a raster. Plain R — no compiled code, no Rcpp, no required dependencies, and `terra` only if you want to read and write files.

> **Python users:** the same conversions are in [pygeopalette](https://github.com/igorpawelec/pygeopalette). The two are separate repositories because their tooling and idioms do not mix. They are close, but — unlike the adaptels twins — they are **not identical**, and cannot be. See [Agreement with pygeopalette](#agreement-with-pygeopalette).

## The problem it solves

The three bands of an orthophoto are the camera's axes, not the analyst's. Red, green and blue are correlated with each other and with brightness, so a bleached crown in the sun and a healthy one in the shade can differ more along every band than a dead tree differs from a living one. The questions a forester or an image analyst asks — how bright, how saturated, how far towards red — live on other axes, and CIE colorimetry has been describing those axes since 1976.

rgeopalette moves raster bands onto them. It implements the standard chain — sRGB linearisation (IEC 61966-2-1), CIE XYZ under D65, then CIELAB, CIELUV, their cylindrical LCH forms, DIN99, Oklab, Jzazbz, CIECAM02 and the video and hue-based spaces — vectorised over whole bands, which is why it needs no C, and checked against pygeopalette and against `farver`.

<img src="https://raw.githubusercontent.com/igorpawelec/rgeopalette/main/www/spaces.png" alt="A 30 by 30 m window of a spruce plot orthophoto in RGB and in seven colour spaces, each space's three components shown as the red, green and blue channels" width="100%"/>

*A 30 × 30 m window of a 0.25 m orthophoto of a spruce stand (`test_data/SNP_21_2020_1.tif`) in RGB and in seven of the fifteen spaces, each space's three components shown as the red, green and blue channels and stretched for display. In the opponent spaces — CIELAB, Oklab, CIELUV, Jzazbz — the dead crowns turn magenta, because their `a*` is positive and the living canopy's is negative; the hue-based spaces wrap around the colour circle wherever a pixel is nearly neutral, which is the caveat below made visible. Made by `www/figures.R`, from this package.*

## Why it matters, measured

The plot has 36 standing dead trees digitised as points. Take every pixel within 1 m of a point as dead and every pixel further than 2 m from all of them as living — 1,759 against 118,627 — and ask of each axis how well it tells the two apart, as the probability that a random dead pixel outranks a random living one (an AUC: 0.5 is chance, 1 is perfect). Fifty-one axes: the three RGB bands and all 48 components of the fifteen spaces.

<img src="https://raw.githubusercontent.com/igorpawelec/rgeopalette/main/www/separation.png" alt="CIELAB a* over the plot with the dead-tree points, the dead trees red on a blue canopy; the densities of dead and living pixels along a*, AUC 0.97; and along the blue band, the best RGB band, AUC 0.93" width="100%"/>

*Left: CIELAB `a*` over the plot, red for positive, blue for negative, with the 36 points. Middle: dead and living pixels along `a*` — AUC 0.97, the best of the 51 axes (Oklab `a` and DIN99 `a` tie with it to three decimals). Right: the same along the blue band, the best that RGB can do — AUC 0.93, with the dead trees spread across the whole upper half of the living distribution. The hue axes score 0.94 but are undefined on neutral pixels; the green–red opponent axis is the one that carries the difference, which is why the dead-tree recipe in rgeoadaptels' `grow_seeds` weights `a*` by 2.5. Every number here is the same as in pygeopalette's README: an AUC is a rank statistic, and the precision gap between the twins cannot move a rank.*

The practical reading: convert before you segment or classify, and choose the axis for the question. Brightness lives on `L*`, the dead-versus-living difference on `a*`, and a colour difference with a meaning — a ΔE — only exists in CIELAB, which is what gives a tolerance like `grow_seeds`' `max_cost` its unit.

## When to use it, and when not

Use rgeopalette to prepare an RGB orthophoto for object-based analysis — adaptels, a classifier over segment features, a seeded growing with a ΔE tolerance — or to read an appearance attribute off it. `rgb_to_cam02()` runs the full CIECAM02 model with viewing conditions when the numbers have to be defensible; `rgb_to_jch()` is the fast stand-in when they do not.

It is not a colour-management tool: no ICC profiles, and the input is taken as sRGB under D65, which is what an 8-bit aerial orthophoto is for practical purposes. It has nothing to say about a near-infrared band — there is no colour space for one; use an index.

### The package family

rgeopalette is the first step of a longer chain; the other steps are separate packages, each with an R and a Python twin.

| Step | R | Python |
|---|---|---|
| Colour-space conversion of orthophotos | **rgeopalette** | [pygeopalette](https://github.com/igorpawelec/pygeopalette) |
| Adaptive superpixels and seeded growing on orthophotos | [rgeoadaptels](https://github.com/igorpawelec/rgeoadaptels) | [pygeoadaptels](https://github.com/igorpawelec/pygeoadaptels) |
| Crowns from a canopy height model | [rcacumen](https://github.com/igorpawelec/rcacumen) | [pycacumen](https://github.com/igorpawelec/pycacumen) |
| Standing dead trees on orthophotos | — | [pygeosnag](https://github.com/igorpawelec/pygeosnag) |
| The same, inside QGIS | | [qgis-geoadaptels-geopalette](https://github.com/igorpawelec/qgis-geoadaptels-geopalette), [qgis-geosnag](https://github.com/igorpawelec/qgis-geosnag) |
| Polish national geodata (GUGiK, BDL) | [rgeopl](https://github.com/igorpawelec/rgeopl) | — |

## Install

```r
# install.packages("remotes")
remotes::install_github("igorpawelec/rgeopalette")
```

## Use

Every conversion takes three bands as numeric matrices on the 0–255 sRGB scale and returns a named list of matrices, one per component:

```r
library(rgeopalette)

lab <- rgb_to_lab(R, G, B)
lab$L        # 0-100
lab$a        # unbounded

available_spaces()
#> "cam02" "dlab" "hsi" "hsl" "hsv" "jch" "jzazbz" "jzczhz" "lab"
#> "lchab" "lchuv" "luv" "oklab" "xyY" "ycbcr"

comps <- convertbands(R, G, B, "oklab")    # dispatch on a name chosen at runtime
```

With a raster, via `terra`:

```r
bands <- read_rgb("scene.tif")             # R, G, B matrices and the template
convert_raster("scene.tif", "scene_lab.tif", space = "lab")
```

`rgb_to_cam02()` is the real CIECAM02, not the `rgb_to_jch()` stand-in, so it takes viewing conditions — and they are not a free choice:

```r
rgb_to_cam02(R, G, B)                      # average surround
rgb_to_cam02(R, G, B, surround = "dark")   # J moves by several units
```

Report the parameters you used, or the numbers are not reproducible.

## Reference

### Scales differ between spaces

There is no single convention, and it bites when bands are stacked:

| space | components |
|---|---|
| `hsl`, `hsv` | hue 0–360, rest 0–1 |
| `hsi` | hue 0–360, saturation 0–100 **per cent**, intensity 0–255 |
| `lab`, `luv`, `lchab`, `lchuv` | L 0–100, rest unbounded |
| `jch` | hue spans 0–**324** — an HSV hue scaled by 0.9 |
| `ycbcr` | studio swing, Y 16–235 |
| inverses | return 0–**1**, not 0–255 |

### Agreement with pygeopalette

Not bit-for-bit, and this is stated rather than glossed over. pygeopalette stores its intermediates in single precision; R has no single-precision numeric type, so this package computes in double throughout. The two part company at about the seventh significant figure by construction.

Measured across 1600 pixels — including black, white, greys, near-greys and all six primaries and secondaries — every one of the 60 components of the 15 forward spaces and 4 inverses agrees to better than **1.7e-6 of the component's own range**. Reproduce it:

```sh
python3 tools/generate_pygeopalette_reference.py
Rscript tools/cross_validate_against_pygeopalette.R
```

The double-precision result is the *more* accurate of the two: CIELAB `L*` matches the independent `farver` implementation to 1.4e-14 here.

<details>
<summary><b>One genuine divergence: hue on the neutral axis</b></summary>

`Hab`, `Huv`, `hz` and CIECAM02 `h` come from `atan2()` over an opponent pair that is exactly zero for a neutral pixel, so the angle is decided by floating-point noise. On pure greys pygeopalette reports 0, 90 or 141.34 depending on the pixel; this package reports 158.199. Both are artefacts, neither is meaningful, and the difference reaches 158 degrees.

It touches only pixels with essentially zero chroma — 5 of 1600 in the run above, all with chroma below 1.8e-5. Above a chroma of 0.01 the largest hue difference is 4.4e-4 degrees.

**Do not segment or classify on a hue band without masking low-chroma pixels first.** Grey, white, black, deep shadow and still water are all neutral, so this is ordinary in real imagery, not a corner case. The hues from `rgb_to_hsl()`, `rgb_to_hsv()`, `rgb_to_hsi()` and `rgb_to_jch()` are unaffected: they come from a max-minus-min sextant and are forced to 0 for achromatic pixels in both packages.

</details>

<details>
<summary><b>The figures</b></summary>

`Rscript www/figures.R` from the repository root remakes the two figures from the files in `test_data/` — the orthophoto and the 36 dead-tree points — using the package in the checkout (`pkgload`) rather than an installed copy, and prints the AUC ranking the captions quote.

</details>

## Citation

Pawelec, I. (2026). *rgeopalette: Colour Space Conversions for Geospatial Raster Data*. R package version 0.2.0. https://github.com/igorpawelec/rgeopalette

Machine-readable metadata, including the papers the colour appearance models come from, is in [`CITATION.cff`](CITATION.cff).

## Licence

GPL-3.
