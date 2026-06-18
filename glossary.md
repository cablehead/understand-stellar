APCA
: Accessible Perceptual Contrast Algorithm. A contrast model that accounts for whether text is light-on-dark or dark-on-light, which a plain WCAG ratio does not. Stellar tunes its foreground tokens to APCA targets, measured in Lc.

clamp()
: The CSS function `clamp(min, preferred, max)` behind every fluid scale. The value tracks the viewport but never drops below the minimum or rises above the maximum.

color set
: One of Stellar's six color families: primary, secondary, tertiary, neutral, neutral-variant, and error. Each is a ramp of 12 shades.

contrast ratio
: WCAG's measure of the luminance difference between text and its background, from 1:1 (none) to 21:1 (black on white). Body text wants at least 4.5:1.

-dim
: The quieter foreground token paired to a shade, for secondary text like captions. Softer than -on, still readable.

dimTargetLc
: The config knob that sets the APCA Lc target Stellar aims for when generating every -dim. This site raised it to 65 so secondary text stays readable in light mode. See onTargetLc.

fluid scale
: A size that grows with the screen, smoothly between a minimum and a maximum viewport width, using clamp(). Type, spacing, radius, and more all scale this way.

Lc
: Lightness contrast, the unit APCA reports, running from 0 to about 106. Lc 30 is decorative, Lc 60 suits large text, and Lc 75 to 90 is body text.

OKLCH
: A perceptual color space that addresses color by lightness, chroma, and hue. Stellar builds its ramps in OKLCH so shades stay evenly spaced and flip cleanly between light and dark.

-on
: The high-contrast foreground token paired to a shade: text guaranteed to read on that exact shade. `--primary-7-on` is the text color for `--primary-7`.

onTargetLc
: The config knob that sets the APCA Lc target for every -on foreground. Higher means more contrast against its shade. See dimTargetLc.

ramp
: The 12 shades of a color set laid out from light to dark.

shade
: One numbered position, 1 to 12, within a color set's ramp. `--neutral-5` is the fifth shade of the neutral set.

step
: One numbered position on a scale such as type size or spacing. Step 0 is the base, so `--font-size-0` is 1rem; steps grow above it and shrink below.

token
: A named design value Stellar generates from the config and delivers as plain CSS, like `--primary-7` or `--font-size-2`. Everything this site shows is a token.

WCAG
: Web Content Accessibility Guidelines, the W3C accessibility standard. Its contrast criteria, 4.5:1 for body text and 3:1 for large text, are what this site checks against.
