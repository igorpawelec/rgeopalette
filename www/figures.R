# The README figures, generated from test_data so they can be remade.
#
#     Rscript www/figures.R           # from the repository root
#
# Writes two figures and prints the numbers the README captions quote:
#   www/spaces.png       a 30 x 30 m window of the scene in RGB and in seven
#                        colour spaces, each space's three components shown as
#                        the red, green and blue channels;
#   www/separation.png   why a colour space matters: how well each axis tells
#                        the 36 digitised dead trees from the living canopy,
#                        as an AUC over every component of every space and
#                        every RGB band, with the best of each drawn.
# Same scene, window, definitions and palette as pygeopalette's www/figures.py.
# The AUCs are rank statistics, so the single-versus-double precision gap
# between the twins cannot move them; the numbers are expected to match.
# Uses the package in this checkout, not an installed copy.
suppressPackageStartupMessages({ library(terra) })
pkgload::load_all(".", quiet = TRUE)

rgb_file <- "test_data/SNP_21_2020_1.tif"
pts_file <- "test_data/dead_trees_test.shp"
blues  <- c("#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5",
            "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b")
blue <- "#2a78d6"; orange <- "#eb6834"; ink <- "#1f1f1f"; muted <- "#6b6b6b"; line <- "#e4e4e4"
diverging <- colorRampPalette(c("#2a78d6", "#f0efec", "#e34948"))(256)   # green <- 0 -> red, grey at zero
window <- c(row0 = 120, col0 = 90, n = 120)         # 0-based like the Python script: the same 30 m window
grid_spaces <- list(c("rgb", "RGB"), c("lab", "CIELAB  L*, a*, b*"), c("oklab", "Oklab  L, a, b"), c("lchab", "LCH(ab)  L*, C, H"),
                    c("luv", "CIELUV  L*, u*, v*"), c("hsv", "HSV  H, S, V"), c("ycbcr", "YCbCr  Y, Cb, Cr"), c("jzazbz", "Jzazbz  Jz, az, bz"))
pretty <- c("lab a" = "CIELAB a*", "lab b" = "CIELAB b*", "lab L" = "CIELAB L*", "oklab a" = "Oklab a", "dlab a" = "DIN99 a",
            "RGB R" = "RGB red", "RGB G" = "RGB green", "RGB B" = "RGB blue")
dead_r <- 4; living_r <- 8                          # px: within 1 m of a point is a dead crown; beyond 2 m of every point is living

b <- read_rgb(rgb_file)
R <- b$R; G <- b$G; B <- b$B; tmpl <- b$template
res_m <- terra::res(tmpl)[1]; e <- terra::ext(tmpl)
nr <- nrow(R); nc <- ncol(R)
valid <- !(is.na(R) | is.na(G) | is.na(B)) & !(R == 0 & G == 0 & B == 0)
R[!valid] <- 0; G[!valid] <- 0; B[!valid] <- 0     # keep the arithmetic finite; valid masks everything below

xy <- terra::crds(terra::vect(pts_file))
seeds <- cbind(row = floor((e$ymax - xy[, 2]) / res_m) + 1, col = floor((xy[, 1] - e$xmin) / res_m) + 1)
rr <- matrix(seq_len(nr), nr, nc); cc <- matrix(seq_len(nc), nr, nc, byrow = TRUE)
d2 <- matrix(Inf, nr, nc)
for (i in seq_len(nrow(seeds))) d2 <- pmin(d2, (rr - seeds[i, 1])^2 + (cc - seeds[i, 2])^2)
dead <- valid & d2 <= dead_r^2
living <- valid & d2 > living_r^2

auc <- function(x) {                                  # P(dead > living), folded to [0.5, 1]
  xd <- x[dead]; xl <- x[living]; xd <- xd[is.finite(xd)]; xl <- xl[is.finite(xl)]
  r <- rank(c(xd, xl)); u <- sum(r[seq_along(xd)]) - length(xd) * (length(xd) + 1) / 2
  a <- u / (length(xd) * length(xl)); max(a, 1 - a)
}

axes_all <- list("RGB R" = R, "RGB G" = G, "RGB B" = B)
for (space in available_spaces()) {
  comps <- convertbands(R, G, B, space)
  for (n in names(comps)) axes_all[[paste(space, n)]] <- comps[[n]]
}
aucs <- vapply(axes_all, auc, numeric(1))
ord <- order(-round(aucs, 3), !startsWith(names(aucs), "lab "), names(aucs))   # ties: CIELAB first
ranked <- aucs[ord]
best <- names(ranked)[1]
rgb_names <- grep("^RGB", names(ranked), value = TRUE); best_rgb <- rgb_names[1]
cat(sprintf("scene %s: %d x %d px at %g m; %d dead-tree points; %s dead px (within %g m), %s living px (beyond %g m)\n",
            basename(rgb_file), nc, nr, res_m, nrow(seeds), format(sum(dead), big.mark = ","), dead_r * res_m,
            format(sum(living), big.mark = ","), living_r * res_m))
cat(sprintf("%d axes ranked by AUC dead vs living; top 12:\n", length(axes_all)))
for (k in 1:12) cat(sprintf("   %.3f  %s\n", ranked[k], names(ranked)[k]))
cat(sprintf("best RGB band: %s at %.3f; best colour-space axis: %s at %.3f\n", best_rgb, ranked[best_rgb], best, ranked[best]))

# ---- drawing helpers ---------------------------------------------------------------
stretch <- function(a, lo = 0.01, hi = 0.99) {       # percentile stretch of the valid pixels to [0, 1], display only
  q <- quantile(a[valid & is.finite(a)], c(lo, hi)); s <- (a - q[1]) / max(q[2] - q[1], 1e-9)
  pmin(pmax(s, 0), 1)
}
layer <- function(m) { r <- terra::rast(tmpl, nlyrs = 1); terra::values(r) <- as.numeric(t(m)); r }
composite <- function(comps) {                       # three components as R, G, B channels, white outside the plot
  r <- terra::rast(tmpl, nlyrs = 3)
  ch <- lapply(comps, function(m) { s <- stretch(m) * 255; s[!valid] <- 255; as.numeric(t(s)) })
  terra::values(r) <- cbind(ch[[1]], ch[[2]], ch[[3]]); r
}
frame_label <- function(label, ext) {
  rect(ext$xmin, ext$ymin, ext$xmax, ext$ymax, border = "#d9d9d9")
  text((ext$xmin + ext$xmax) / 2, ext$ymin - 0.05 * (ext$ymax - ext$ymin), label, adj = c(0.5, 1), cex = 0.86, col = ink, xpd = NA)
}
r0 <- window[["row0"]]; c0 <- window[["col0"]]; n <- window[["n"]]
win_ext <- terra::ext(e$xmin + c0 * res_m, e$xmin + (c0 + n) * res_m, e$ymax - (r0 + n) * res_m, e$ymax - r0 * res_m)

# ---- figure 1: the scene in eight spaces, one window --------------------------------
png("www/spaces.png", width = 11.4, height = 6.1, units = "in", res = 160, bg = "white")
layout(matrix(1:8, 2, byrow = TRUE))
for (g in grid_spaces) {
  comps <- if (g[1] == "rgb") list(R, G, B) else unname(convertbands(R, G, B, g[1]))
  terra::plotRGB(terra::crop(composite(comps), win_ext), stretch = NULL, axes = FALSE, mar = c(3.0, 0.4, 0.4, 0.4), maxcell = Inf)
  frame_label(g[2], win_ext)
}
invisible(dev.off())

# ---- figure 2: the separation ---------------------------------------------------------
density_panel <- function(key, label, legend = FALSE) {
  x <- axes_all[[key]]; a <- auc(x)
  xd <- x[dead & is.finite(x)]; xl <- x[living & is.finite(x)]
  lim <- quantile(c(xd, xl), c(0.005, 0.995))
  dl <- density(xl, from = lim[1], to = lim[2], n = 240); dd <- density(xd, from = lim[1], to = lim[2], n = 240)
  par(mar = c(4.2, 1.0, 1.8, 1.0))
  plot(NA, xlim = lim, ylim = c(0, max(dl$y, dd$y) * 1.05), axes = FALSE, xlab = "", ylab = "")
  abline(v = pretty(lim), col = line, lwd = 0.8)
  axis(1, at = pretty(lim), col = line, col.axis = muted, cex.axis = 0.75, lwd = 0, lwd.ticks = 1)
  lines(dl$x, dl$y, col = blue, lwd = 2.4); lines(dd$x, dd$y, col = orange, lwd = 2.4)
  mtext(sprintf("%s   ·   AUC %.2f", label, a), side = 1, line = 2.8, cex = 0.86, col = ink)
  if (legend) legend("topright", legend = c("living canopy", "dead trees, within 1 m of a point"), col = c(blue, orange),
                     lwd = 2.4, bty = "n", cex = 0.85, text.col = ink)
}
image_panel <- function(key, label) {
  x <- axes_all[[key]]
  opponent <- sub(".* ", "", key) %in% c("a", "b", "az", "bz", "u", "v")
  if (opponent) {
    lim <- quantile(abs(x[valid & is.finite(x)]), 0.99)
    m <- pmin(pmax(x, -lim), lim); m[!valid] <- NA
    terra::plot(layer(m), col = diverging, range = c(-lim, lim), legend = FALSE, axes = FALSE, mar = c(3.0, 0.4, 0.4, 0.4), maxcell = Inf)
  } else {
    m <- stretch(x); m[!valid] <- NA
    terra::plot(layer(m), col = colorRampPalette(blues)(256), range = c(0, 1), legend = FALSE, axes = FALSE, mar = c(3.0, 0.4, 0.4, 0.4), maxcell = Inf)
  }
  points(xy, pch = 21, bg = ink, col = "white", cex = 0.8, lwd = 0.8)
  frame_label(label, e)
}
png("www/separation.png", width = 11.4, height = 4.1, units = "in", res = 160, bg = "white")
layout(matrix(1:3, 1), widths = c(1, 1, 1.15))
image_panel(best, sprintf("%s, with the dead-tree points", pretty[best]))
density_panel(best, sprintf("%s, the best axis", pretty[best]))
density_panel(best_rgb, sprintf("%s, the best RGB band", pretty[best_rgb]), legend = TRUE)
invisible(dev.off())
cat("written: www/spaces.png, www/separation.png\n")
