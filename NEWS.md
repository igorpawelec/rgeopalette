# rgeopalette 0.1.0


# rgeopalette 0.2.0

## Changed

* **Renamed from `GeoPaletteR`.** The package name is now `rgeopalette`, which is a
  breaking change for `library()` calls and for any dependency on it. The
  algorithms and the results are unchanged.


First release. The R twin of the pygeopalette Python package.

* Fifteen forward conversions — `hsl`, `hsv`, `hsi`, `lab`, `dlab`,
  `oklab`, `luv`, `lchab`, `lchuv`, `xyY`, `jch`, `cam02`, `ycbcr`,
  `jzazbz`, `jzczhz` — and four inverses back to sRGB.
* `convertbands()` dispatches on a space name; `available_spaces()` lists
  them. The names and component labels match pygeopalette exactly, so band
  files written by either package line up.
* `rgb_to_cam02()` is the real CIECAM02 forward model, with the viewing
  conditions exposed as arguments. `rgb_to_jch()` remains the cheap
  stand-in and says so.
* `read_rgb()` and `convert_raster()` bridge to \pkg{terra}, which is only
  a Suggests: the conversions work on plain matrices with no spatial
  dependency.
* Plain R, no compiled code, no required dependencies.
* Agreement with pygeopalette 0.4.0 is measured rather than claimed: every
  one of the 60 components matches to better than 1.7e-6 of its own range
  across 1600 pixels including greys and primaries. It is not exact, and
  cannot be, because pygeopalette stores single precision and R has only
  double. See `?rgeopalette-agreement`, which also documents the one real
  divergence: the hue angle of a neutral colour, which is undefined in
  both packages.
