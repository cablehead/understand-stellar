use http-nu/router *
use http-nu/html *
use lib.nu *

# understand-stellar: a visual reference for the Stellar CSS framework.
#
# One scrolling page that shows every design token Stellar gives you,
# grouped by the decision it serves and demonstrated visually rather than
# just named. Light/dark comes from stellar's :root.dark overrides; the
# toggle flips the `dark` class on <html>.
#
# Run: http-nu --datastar :PORT serve.nu

let cfg = (load-config ($env.PWD | path join "stellar.config.json"))

let SECTIONS = [
  [color "Color"]
  [type "Type"]
  [space "Space"]
  [borders "Borders & radius"]
  [elevation "Elevation"]
  [motion "Motion"]
  [layout "Layout"]
]

# Per-page <head>. `meta` carries {title, description, path, image}; every page
# passes its own, so OG/Twitter tags are generated once here for all of them.
def head-block [meta: record] {
  let base = "https://understanding-stellar.cross.stream"
  let img = $"($base)/assets/($meta.image)"
  (HEAD
    (META {charset: "utf-8"})
    (META {name: "viewport" content: "width=device-width, initial-scale=1"})
    (TITLE $meta.title)
    (META {name: "description" content: $meta.description})
    (META {property: "og:type" content: "website"})
    (META {property: "og:title" content: $meta.title})
    (META {property: "og:description" content: $meta.description})
    (META {property: "og:url" content: $"($base)/($meta.path)"})
    (META {property: "og:image" content: $img})
    (META {property: "og:image:width" content: "1200"})
    (META {property: "og:image:height" content: "630"})
    (META {name: "twitter:card" content: "summary_large_image"})
    (META {name: "twitter:title" content: $meta.title})
    (META {name: "twitter:description" content: $meta.description})
    (META {name: "twitter:image" content: $img})
    (SCRIPT {__html: "
(function(){
  var t = localStorage.getItem('theme');
  if (!t) t = window.matchMedia('(prefers-color-scheme:dark)').matches ? 'dark' : 'light';
  if (t === 'dark') document.documentElement.classList.add('dark');
})();
"})
    (LINK {rel: "stylesheet" href: "/assets/stellar.css"})
    (LINK {rel: "stylesheet" href: "/assets/page.css"})
    (SCRIPT-ICONIFY)
  )
}

def sidebar [sections: list, here: string] {
  # served from the closure at the root: canonical absolute routes. Section
  # links are in-page anchors on home, cross-page (/#id) from other routes.
  let p = (if $here == "/" { "" } else { "/" })
  (ASIDE {class: "sidebar"}
    (DIV {class: "brand"}
      (H1 (A {href: "/"} "understand stellar"))
      (P "A visual map of every design token. Click any to copy it.")
    )
    (BUTTON {class: "nav-toggle" data-act: "toggle-nav"} "Sections")
    (NAV {class: "section-nav"}
      (UL
        ( $sections | each {|s| LI (A {href: $"($p)#($s.0)"} $s.1) } )
        (LI {class: "nav-page"} (A {href: "/notes" class: (if $here == "/notes" { "current" } else { "" })} "Notes"))
      )
    )
    (BUTTON {class: "theme-toggle" data-act: "toggle-theme"}
      (ICONIFY "lucide:sun-moon" {width: "16" height: "16"})
      (SPAN {id: "theme-label"} "theme")
    )
    (A {class: "source-link" href: "https://github.com/cablehead/understand-stellar" target: "_blank" rel: "noopener"}
      (ICONIFY "simple-icons:github" {width: "15" height: "15"})
      (SPAN "Source")
    )
  )
}

# ---- color ----------------------------------------------------------

def color-ramp [name: string] {
  (DIV {class: "ramp-group"}
    (DIV {class: "ramp-label"}
      (STRONG $name)
      (token $"--($name)-1")
      (SPAN {class: "note"} "to")
      (token $"--($name)-12")
    )
    (DIV {class: "ramp"} ( 1..12 | each {|n|
      (DIV {class: "stop" data-copy: $"--($name)-($n)"
            style: {background: $"var\(--($name)-($n)\)" color: $"var\(--($name)-($n)-on\)"}}
        (SPAN {class: "n"} $"($n)")
        (SPAN {class: "on" data-copy: $"--($name)-($n)-on"} "on")
      )
    }))
    (DIV {class: "ramp dim"} ( 1..12 | each {|n|
      (DIV {class: "stop" data-copy: $"--($name)-($n)-dim"
            style: {background: $"var\(--($name)-($n)\)"}}
        (SPAN {style: {color: $"var\(--($name)-($n)-dim\)" "font-weight": "var(--font-weight-bold)"}} "dim")
      )
    }))
  )
}

# A compact base+dim ramp for any family that emits -on/-dim per step
# (brands, chart qualitative, chart diverging). `prefix` is the token stem,
# `steps` the suffix list, `labels` what each base stop prints. Clicking a base
# stop copies the base token, its inner "on" copies -on, the dim row copies -dim.
def mini-ramp [prefix: string, steps: list, labels: list] {
  let cols = ($steps | length)
  let gtc = $"repeat\(($cols), minmax\(0, 1fr\)\)"
  [
    (DIV {class: "ramp mini" style: {"grid-template-columns": $gtc}} ( 0..($cols - 1) | each {|i|
      let n = ($steps | get $i)
      (DIV {class: "stop" data-copy: $"($prefix)-($n)"
            style: {background: $"var\(($prefix)-($n)\)" color: $"var\(($prefix)-($n)-on\)"}}
        (SPAN {class: "n"} $"($labels | get $i)")
        (SPAN {class: "on" data-copy: $"($prefix)-($n)-on"} "on"))
    }))
    (DIV {class: "ramp mini dim" style: {"grid-template-columns": $gtc}} ( 0..($cols - 1) | each {|i|
      let n = ($steps | get $i)
      (DIV {class: "stop" data-copy: $"($prefix)-($n)-dim"
            style: {background: $"var\(($prefix)-($n)\)"}}
        (SPAN {style: {color: $"var\(($prefix)-($n)-dim\)" "font-weight": "var(--font-weight-bold)"}} "dim"))
    }))
  ]
}

def color-section [cfg: record] {
  let roles = [primary secondary tertiary neutral neutral-variant error]
  (SECTION {class: "section"}
    (section-head "color" "Color"
      "Six color sets, each with a job: primary for buttons and links, neutral for backgrounds and body text, error for danger, plus three more. Each runs 12 shades from light to dark and flips in dark mode, so you pick by job and it adapts. For any shade, -on is text that stays readable on it, and -dim is quieter text like captions. Each swatch shows its number in its own -on, so you can see where text holds up.")

    (DIV {class: "block"} ( $roles | each {|r| color-ramp $r } ))

    (DIV {class: "block"}
      (H3 {class: "subhead"} "One set in practice")
      (P {class: "note"} "Each card is built from a single color set: a background shade, its -on for text, and -dim for quieter text.")
      (DIV {class: "surfaces"} ( $roles | each {|r|
        (DIV {class: "surface" style: {background: $"var\(--($r)-2\)" color: $"var\(--($r)-2-on\)"}}
          (H4 $r)
          (P "The quick brown fox jumps over the lazy dog.")
          (P {style: {color: $"var\(--($r)-2-dim\)" "margin-bottom": "var(--size-1)"}} "Secondary text uses the -dim variant.")
          (SPAN {class: "pill" style: {background: $"var\(--($r)-7\)" color: $"var\(--($r)-7-on\)"}} "step 7")
        )
      }))
    )

    (if (not ($cfg.colors.named.disabled)) {
      let neg = ($cfg.colors.named.negativeSteps)
      let pos = ($cfg.colors.named.positiveSteps)
      let names = ($cfg.colors.named.colors | get name)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Named brand colors")
        (P {class: "note"} (token "--named-{brand}-{n}") $" : each brand color expanded into a ($neg)+1+($pos) shade ramp, every shade with -on and -dim.")
        (DIV {class: "brands"} ( $names | each {|b|
          let st = (steps $neg $pos)
          (DIV {class: "brand-card"}
            (SPAN {class: "name"} $b)
            (mini-ramp $"--named-($b)" $st $st)
          )
        }))
      )
    })

    (if (not ($cfg.colors.charts.disabled)) {
      let qual = ($cfg.colors.charts.qualitativeCount)
      let div = ($cfg.colors.charts.divergingCount)
      let tones = ($cfg.colors.charts.toneSteps)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Data visualization")
        (P {class: "note"} (token "--chart-qualitative-{n}") " : distinct colors for categories, picked to be easy to tell apart, each with -on and -dim.")
        (mini-ramp "--chart-qualitative" (1..$qual | each {|n| $"($n)"}) (1..$qual | each {|n| $"($n)"}))
        (P {class: "note" style: {"margin-top": "var(--size-1)"}} (token $"--chart-diverging-{1..($div)}-step-{1..($tones)}") " : ordered shade ramps for ranked data, every shade with -on and -dim.")
        (DIV {class: "chart-ramps"} ( 1..$div | each {|p|
          let labs = (1..$tones | each {|n| $"($n)"})
          (mini-ramp $"--chart-diverging-($p)-step" $labs $labs)
        }))
      )
    })

    (if (not ($cfg.colors.gradients.disabled)) {
      let names = ($cfg.colors.gradients.items | get name)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Gradients")
        (DIV {class: "gradients"} ( $names | each {|g|
          (DIV {class: "gradient-card" data-copy: $"--gradient-($g)"}
            (DIV {class: "swatch" style: {background: $"var\(--gradient-($g)\)"}})
            (SPAN {class: "name"} (token $"--gradient-($g)")))
        }))
      )
    })

    (if (not ($cfg.colors.code.disabled)) {
      let sample = "fn ramp(seed: Color, steps: i32) {\n    // derive tones from one seed\n    let scale = 1.618;\n    println!(\"generated {} tones\\n\", steps);\n}"
      # every --code-* token, read from the generated CSS so the list stays complete
      let code_tokens = (open --raw ($env.PWD | path join "assets/stellar.css") | decode utf-8 | parse -r '(--code-[a-z0-9-]+):' | get capture0 | uniq | sort)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Code & syntax")
        (P {class: "note"} "The full set of syntax colors (keyword, string, function name, and so on), taken from the theme and flipped for dark mode. This is exactly what the code highlighter uses.")
        (DIV {class: "code-demo"}
          (PRE (CODE ($sample | .highlight rust))))
        (DIV {class: "token-row"} ( $code_tokens | each {|t| token $t } ))
      )
    })
  )
}

# ---- type -----------------------------------------------------------

def type-section [cfg: record] {
  let sz_neg = ($cfg.fonts.sizes.negativeSteps)
  let sz_pos = ($cfg.fonts.sizes.positiveSteps)
  (SECTION {class: "section"}
    (section-head "type" "Type"
      "Text sizes on a numbered scale, plus font families, weights, line height, and letter spacing. Step 0 is your 1rem body size; smaller steps shrink toward fine print, larger steps grow toward headings. Each size scales smoothly with the screen, so text stays in proportion from phone to desktop. Every sample here is set at its real size.")

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Size scale")
      (P {class: "note"} (token "--font-size-0") " is the 1rem starting point; each step up is about 1.2x the one below it, each step down a little smaller.")
      (DIV {class: "type-scale"} ( (steps $sz_neg $sz_pos) | reverse | each {|n|
        (DIV {class: "type-row" data-copy: $"--font-size-($n)"}
          (DIV {class: "specimen" style: {"font-size": $"var\(--font-size-($n)\)"}} "Grumpy wizards make toxic brew")
          (DIV {class: "meta"} (token $"--font-size-($n)")))
      }))
    )

    (if (not ($cfg.fonts.families.disabled)) {
      let fams = ($cfg.fonts.families.values | get name | filter {|f| $f != "system-ui"})
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Families")
        (P {class: "note"} "Ready-made stacks with system fallbacks, each a different voice. --font-sans for UI and body, --font-mono for code and figures, --font-serif for long-form; the rest are character choices. The same sentence is set in each to compare. " (token "--font-{name}") ".")
        (DIV {class: "families"} ( $fams | each {|f|
          (DIV {class: "family-row"}
            (SPAN (token $"--font-($f)"))
            (SPAN {class: "specimen" style: {"font-family": $"var\(--font-($f)\)"}} "The five boxing wizards jump quickly."))
        }))
      )
    })

    (if (not ($cfg.fonts.weights.disabled)) {
      let ws = ($cfg.fonts.weights.named | get name)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Weights")
        (DIV {class: "weights"} ( $ws | each {|w|
          (DIV {class: "weight-item" data-copy: $"--font-weight-($w)"}
            (SPAN {class: "word" style: {"font-weight": $"var\(--font-weight-($w)\)"}} "Aa")
            (token $"--font-weight-($w)"))
        }))
      )
    })

    (if (not ($cfg.fonts.lineHeights.disabled)) {
      let lh_neg = ($cfg.fonts.lineHeights.negativeSteps)
      let lh_pos = ($cfg.fonts.lineHeights.positiveSteps)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Line height")
        (P {class: "note"} "A fixed line height for each text size, tighter for small text, airier for large. Borrow one for a much bigger heading and the lines can overlap. " (token "--font-line-height-{n}") ".")
        (DIV {class: "leading-demo"} ( (steps $lh_neg $lh_pos) | each {|n|
          (DIV {class: "box" data-copy: $"--font-line-height-($n)"}
            (P {style: {"line-height": $"var\(--font-line-height-($n)\)"}} "Type that wraps across several lines shows its leading. The taller the line height, the more open the paragraph feels.")
            (token $"--font-line-height-($n)"))
        }))
      )
    })

    (if (not ($cfg.fonts.spacing.disabled)) {
      let ls_neg = ($cfg.fonts.spacing.negativeSteps)
      let ls_pos = ($cfg.fonts.spacing.positiveSteps)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Letter spacing")
        (P {class: "note"} "Negative steps tighten spacing for large headings, positive steps open it up for small text, zero in between. It also tightens a little as the screen widens. " (token "--font-letter-spacing-{n}") ".")
        (DIV {class: "tracking-demo"} ( (steps $ls_neg $ls_pos) | reverse | each {|n|
          (P {data-copy: $"--font-letter-spacing-($n)" style: {"letter-spacing": $"var\(--font-letter-spacing-($n)\)" "font-size": "var(--font-size-2)"}}
            "TRACKING " (SPAN {class: "token"} $"--font-letter-spacing-($n)"))
        }))
      )
    })
  )
}

# ---- space ----------------------------------------------------------

def space-section [cfg: record] {
  let neg = ($cfg.general.size.negativeSteps)
  let pos = ($cfg.general.size.positiveSteps)
  (SECTION {class: "section"}
    (section-head "space" "Space & size"
      "One numbered scale for padding, margins, gaps, and sizes. Reuse the same step for related spacing and the layout keeps a steady rhythm. Like text, each step scales smoothly with the screen. Each bar's width is the value itself.")
    (DIV {class: "space-stack"} ( (steps $neg $pos) | each {|n|
      (DIV {class: "space-bar" data-copy: $"--size-($n)"}
        (SPAN {class: "lbl"} $"--size-($n)")
        (DIV {class: "bar" style: {width: $"var\(--size-($n)\)"}}))
    }))
  )
}

# ---- borders --------------------------------------------------------

def borders-section [cfg: record] {
  (SECTION {class: "section"}
    (section-head "borders" "Borders & radius"
      "Corner roundness and border thickness, each on its own numbered scale. A small radius for inputs and cards, a large one for pills and avatars; thicker borders for more emphasis. The blob and hand-drawn shapes are ready-made irregular corners for surfaces that should feel less rigid. Each box here uses the value directly.")

    (if (not ($cfg.borders.radii.disabled)) {
      let neg = ($cfg.borders.radii.negativeSteps)
      let pos = ($cfg.borders.radii.positiveSteps)
      let r_ints = ((steps $neg $pos) | each {|n| $n | into int} | where {|n| $n >= 1})
      let r_top = ($r_ints | math max)
      let r_blends = ($r_ints | where {|n| $n < $r_top} | each {|n| $"--border-radius-($n)-($n + 1)"})
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Corner radius")
        (DIV {class: "box-grid"} ( (steps $neg $pos) | each {|n|
          (DIV {class: "demo-box" data-copy: $"--border-radius-($n)" style: {"border-radius": $"var\(--border-radius-($n)\)"}}
            $"--border-radius-($n)")
        }))
        (P {class: "note"} "Half steps interpolate between neighbors (n -> n+1): " ( $r_blends | each {|b| [(token $b) " "] } ))
      )
    })

    (if (not ($cfg.borders.widths.disabled)) {
      let neg = ($cfg.borders.widths.negativeSteps)
      let pos = ($cfg.borders.widths.positiveSteps)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Border width")
        (P {class: "note"} "Numbered steps that scale with the screen; thicker for more emphasis. " (token "--border-width-{n}") ".")
        (DIV {class: "box-grid"} ( (steps $neg $pos) | each {|n|
          (DIV {class: "border-box" data-copy: $"--border-width-($n)" style: {"border-width": $"var\(--border-width-($n)\)"}}
            $"--border-width-($n)")
        }))
      )
    })

    (if (not ($cfg.borders.generators.disabled)) {
      let blobs = (if ($cfg.borders.generators.shouldGenerateBlobs) { $cfg.borders.generators.blobs.count } else { 0 })
      let drawn = (if ($cfg.borders.generators.shouldGenerateDrawn) { $cfg.borders.generators.drawn.count } else { 0 })
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Organic radii")
        (if $blobs > 0 {
          (DIV {class: "block"}
            (P {class: "note"} (token "--radius-blob-{n}") " : soft, asymmetric multi-corner blobs.")
            (DIV {class: "box-grid"} ( 1..$blobs | each {|n|
              (DIV {class: "demo-box organic-box" data-copy: $"--radius-blob-($n)" style: {"border-radius": $"var\(--radius-blob-($n)\)"}}
                $"--radius-blob-($n)")
            }))
          )
        })
        (if $drawn > 0 {
          (DIV {class: "block"}
            (P {class: "note"} (token "--radius-drawn-{n}") " : subtle hand-drawn wobble.")
            (DIV {class: "box-grid"} ( 1..$drawn | each {|n|
              (DIV {class: "demo-box organic-box" data-copy: $"--radius-drawn-($n)" style: {"border-radius": $"var\(--radius-drawn-($n)\)"}}
                $"--radius-drawn-($n)")
            }))
          )
        })
      )
    })
  )
}

# ---- elevation ------------------------------------------------------

def elevation-section [cfg: record] {
  (SECTION {class: "section"}
    (section-head "elevation" "Elevation"
      "Shadows that show how far something sits off the page, each built from a few soft layers so it reads as real, not a flat drop. The higher the step, the more it lifts: a card sits low, a dropdown higher, a dialog highest. Negative steps press inward instead, for input fields. Step 0 is no shadow.")
    (if (not ($cfg.colors.shadows.disabled)) {
      let outer = ($cfg.colors.shadows.outer.steps)
      let inner = ($cfg.colors.shadows.inner.steps)
      (DIV {class: "elevation"} ( (steps $inner $outer) | each {|n|
        (DIV {class: "elev-item" data-copy: $"--shadow-($n)"}
          (DIV {class: "elev-box" style: {"box-shadow": $"var\(--shadow-($n)\)"}})
          (token $"--shadow-($n)"))
      }))
    })
  )
}

# ---- motion ---------------------------------------------------------

def motion-section [cfg: record] {
  (SECTION {class: "section"}
    (section-head "motion" "Motion"
      "A transition is three choices: how it moves (the easing), how long it takes (the duration), and how far it goes (the amount: scale, rotate, slide, or fade). Easings run from a plain standard curve to springy ones like bounce and shake. Durations adjust to screen size, and switch off when the visitor prefers reduced motion. Build one below, play it, and copy the CSS it produces.")
    (compose-block $cfg)

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Raw amount stops")
      (P {class: "note"} "The chips above use friendly names (up, xl, muted). Each one is just a nickname for one of these numbered steps. Copy a number to use it directly.")
      (DIV {class: "raw-amounts"} (
        # numeric amount stops, read from the generated CSS so the set stays complete
        open --raw ($env.PWD | path join "assets/stellar.css") | decode utf-8
        | parse -r '(--anim-(?:scale|rotate|distance|opacity)--?\d+):'
        | get capture0 | uniq | sort | each {|t| token $t }
      ))
    )
  )
}

# ---- layout ---------------------------------------------------------

def layout-section [cfg: record] {
  (SECTION {class: "section"}
    (section-head "layout" "Layout"
      "Stacking order, aspect ratios, and the screen-width limits behind every fluid size. Named z-index layers keep overlapping elements in order, a dropdown over the page, a dialog over that, without guessing numbers. Aspect-ratio tokens hold media at set proportions. The viewport min and max are the narrow and wide widths every fluid size scales between.")

    (if (not ($cfg.general.zindexes.disabled)) {
      let levels = ($cfg.general.zindexes.levels)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Stacking order")
        (P {class: "note"} "Named layers so overlapping elements stack in a set order: dropdown over the page, tooltip over that, dialog, drawer, and toast on top. No hand-picked numbers that drift out of order. The cards below overlap in that order. " (token "--zindex-{name}") ".")
        (DIV {class: "zindex-demo"} ( $levels | enumerate | each {|it|
          let i = $it.index
          let lvl = $it.item
          (DIV {class: "z-card" data-copy: $"--zindex-($lvl.name)"
                style: {"z-index": $"var\(--zindex-($lvl.name)\)"
                        background: $"var\(--primary-($i + 2)\)"
                        color: $"var\(--primary-($i + 2)-on\)"
                        left: $"($i * 2.6)rem" top: $"($i * 0.7)rem"}}
            (STRONG $lvl.name) (SPAN $"($lvl.value)"))
        }))
      )
    })

    (if (not ($cfg.general.aspectRatio.disabled)) {
      let named = ($cfg.general.aspectRatio.named)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Aspect ratio")
        (P {class: "note"} "Lock a box to a proportion so media holds its shape at any width: square for avatars, widescreen for 16:9 video, plus portrait, cinematic and ultrawide. " (token "--aspect-ratio-{name}") ".")
        (DIV {class: "aspect-grid"} ( $named | each {|a|
          (DIV {class: "aspect-box" data-copy: $"--aspect-ratio-($a.name)"
                style: {"aspect-ratio": $"var\(--aspect-ratio-($a.name)\)"}}
            $a.name)
        }))
      )
    })

    (if (not ($cfg.general.viewport.disabled)) {
      let vmin = ($cfg.general.viewport.min)
      let vmax = ($cfg.general.viewport.max)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Viewport bounds")
        (P {class: "note"} $"Every fluid size scales across this range: smallest at ($vmin)px and below, largest at ($vmax)px and above, smoothly in between. Text, spacing, radius, border width, and duration all scale between these two widths. You rarely set them directly; reach for them to line a media query up with the scales.")
        (DIV {class: "viewport-range"}
          (SPAN {class: "vp-edge"} $"($vmin)px")
          (DIV {class: "vp-bar"} "fluid scaling")
          (SPAN {class: "vp-edge"} $"($vmax)px"))
        (DIV {class: "token-row"} (token "--viewport-min") (token "--viewport-max"))
      )
    })
  )
}

def chip-row [label: string group: string chips: list] {
  (DIV {class: "config-row"}
    (SPAN {class: "config-label"} $label)
    (DIV {class: "chips" data-group: $group} $chips))
}

# Compose block: configure a transition (property/amount/duration/easing),
# press Play, copy the CSS. Shows how the tokens are actually used together.
def compose-block [cfg: record] {
  let eases = ($cfg.animations.easings | get name)
  let dn = ($cfg.animations.durations)
  let durs = ($dn.named | get name)
  let dnums = (steps $dn.negativeSteps $dn.positiveSteps)
  let amount_sets = {
    scale: ($cfg.animations.scales.named | get name)
    rotate: ($cfg.animations.rotations.named | get name)
    slide: ($cfg.animations.distances.named | get name)
    fade: ($cfg.animations.opacities.named | get name)
  }
  let amount_pfx = {scale: "anim-scale", rotate: "anim-rotate", slide: "anim-distance", fade: "anim-opacity"}
  let amount_chips = ($amount_sets | items {|prop, names|
    $names | each {|a| (BUTTON {class: "chip" data-set: $prop data-amount: $a data-copy: $"--($amount_pfx | get $prop)-($a)"} $a) }
  } | flatten)
  (DIV {class: "block compose"}
    (H3 {class: "subhead"} "Compose")
    (P {class: "note"} "Pick a property, an amount, a duration, and an easing; toggle Activate to play the transition (changing any chip replays it), then copy the rule below. The box on the right is exactly what you would ship.")
    (DIV {class: "composer"}
      (DIV {class: "config"}
        (chip-row "property" "prop" ([scale rotate slide fade] | each {|p| BUTTON {class: "chip" data-prop: $p} $p}))
        (chip-row "amount" "amount" $amount_chips)
        (chip-row "duration" "dur" (
          ($durs | each {|d| BUTTON {class: "chip" data-dur: $d data-copy: $"--anim-duration-($d)"} $d})
          | append (SPAN {class: "chip-sep"} "steps")
          | append ($dnums | each {|n| BUTTON {class: "chip chip-num" data-dur: $"($n)" data-copy: $"--anim-duration-($n)"} $"($n)"})
        ))
        (chip-row "easing" "ease" ($eases | each {|e| BUTTON {class: "chip" data-ease: $e data-copy: $"--anim-ease-($e)"} $e}))
      )
      (DIV {class: "stage-col"}
        (DIV {class: "stage"} (DIV {id: "compose-thing" class: "thing"} "thing"))
        (BUTTON {id: "compose-go" class: "go-btn"} "Activate")
      )
    )
    (DIV {class: "compose-out"}
      (DIV {class: "compose-code-head"} (SPAN {class: "config-label"} "CSS") (BUTTON {id: "compose-copy" class: "chip"} "copy"))
      (PRE (CODE {id: "compose-code"} "")))
  )
}

def compose-script [] {
  (SCRIPT {__html: r##'
(function(){
  var root = document.querySelector('.compose'); if (!root) return;
  var thing = document.getElementById('compose-thing');
  var code = document.getElementById('compose-code');
  var go = document.getElementById('compose-go');
  var state = {prop:'slide', amount:'xl', dur:'slow', ease:'emphasized', active:false};
  var MAP = {
    scale: {prop:'transform', fn:'scale', tok:'--anim-scale-', def:'up'},
    rotate:{prop:'transform', fn:'rotate', tok:'--anim-rotate-', def:'lg'},
    slide: {prop:'transform', fn:'translateX', tok:'--anim-distance-', def:'xl'},
    fade:  {prop:'opacity', fn:null, tok:'--anim-opacity-', def:'muted'}
  };
  function chips(g){ return root.querySelectorAll('.chips[data-group="'+g+'"] .chip'); }
  function setActive(g, attr, val){ chips(g).forEach(function(c){ c.classList.toggle('on', c.getAttribute(attr)===val); }); }
  function showAmounts(){
    var first=null, valid=false, hasDef=false, def=MAP[state.prop].def;
    chips('amount').forEach(function(c){
      var vis=c.getAttribute('data-set')===state.prop, a=c.getAttribute('data-amount');
      c.style.display=vis?'':'none';
      if(vis){ if(!first) first=c; if(a===state.amount) valid=true; if(a===def) hasDef=true; }
    });
    if(!valid) state.amount = hasDef ? def : (first?first.getAttribute('data-amount'):null);
    setActive('amount','data-amount',state.amount);
  }
  function target(){
    var m=MAP[state.prop];
    return state.prop==='fade' ? 'opacity: var('+m.tok+state.amount+');' : 'transform: '+m.fn+'(var('+m.tok+state.amount+'));';
  }
  function render(){
    var m=MAP[state.prop];
    code.textContent='.thing {\n  transition: '+m.prop+' var(--anim-duration-'+state.dur+') var(--anim-ease-'+state.ease+');\n}\n.thing.active {\n  '+target()+'\n}';
  }
  function applyTransition(){
    var m=MAP[state.prop];
    thing.style.transition=m.prop+' var(--anim-duration-'+state.dur+') var(--anim-ease-'+state.ease+')';
  }
  function rest(){ thing.style.transform='none'; thing.style.opacity='1'; }
  function setTargetStyle(){
    var m=MAP[state.prop];
    if(state.prop==='fade'){ thing.style.transform='none'; thing.style.opacity='var('+m.tok+state.amount+')'; }
    else { thing.style.opacity='1'; thing.style.transform=m.fn+'(var('+m.tok+state.amount+'))'; }
  }
  // Active/inactive toggle that holds its state. Toggling animates rest<->target
  // so you feel the easing. Changing any chip while active "replays": ease out to
  // rest, then back in with the new setting - smooth (no snap), ends settled.
  function goActive(){ applyTransition(); setTargetStyle(); thing.__phase='active'; }
  function goRest(){ applyTransition(); rest(); thing.__phase='rest'; }
  function replay(){ applyTransition(); rest(); thing.__phase='out'; }
  thing.addEventListener('transitionend', function(e){
    if(e.target!==thing) return;
    if(thing.__phase==='out' && state.active){ applyTransition(); setTargetStyle(); thing.__phase='active'; }
  });
  function updateBtn(){ if(go){ go.textContent=state.active?'Reset':'Activate'; go.classList.toggle('on', state.active); } }
  root.addEventListener('click', function(e){
    if(e.target.closest('#compose-go')){ state.active=!state.active; if(state.active){ goActive(); } else { goRest(); } updateBtn(); return; }
    if(e.target.closest('#compose-copy')){
      if(navigator.clipboard) navigator.clipboard.writeText(code.textContent);
      var t=document.getElementById('toast'); if(t){ t.textContent='copied CSS'; t.classList.add('show'); clearTimeout(window.__ct); window.__ct=setTimeout(function(){t.classList.remove('show');},1100); }
      return;
    }
    var c=e.target.closest('.chip'); if(!c) return;
    if(c.hasAttribute('data-prop')){ state.prop=c.getAttribute('data-prop'); setActive('prop','data-prop',state.prop); showAmounts(); }
    else if(c.hasAttribute('data-amount')){ state.amount=c.getAttribute('data-amount'); setActive('amount','data-amount',state.amount); }
    else if(c.hasAttribute('data-dur')){ state.dur=c.getAttribute('data-dur'); setActive('dur','data-dur',state.dur); }
    else if(c.hasAttribute('data-ease')){ state.ease=c.getAttribute('data-ease'); setActive('ease','data-ease',state.ease); }
    render();
    if(state.active){ replay(); }
  });
  setActive('prop','data-prop',state.prop);
  setActive('dur','data-dur',state.dur);
  setActive('ease','data-ease',state.ease);
  showAmounts(); render(); updateBtn();
})();
'##})
}

def page-script [] {
  (SCRIPT {__html: "
function setLabel(){
  var d = document.documentElement.classList.contains('dark');
  var el = document.getElementById('theme-label');
  if (el) el.textContent = d ? 'dark' : 'light';
}
setLabel();
document.addEventListener('click', function(e){
  var t = e.target.closest('[data-act=\"toggle-theme\"]');
  if (t){
    var d = document.documentElement.classList.toggle('dark');
    localStorage.setItem('theme', d ? 'dark' : 'light');
    setLabel();
    return;
  }
  var n = e.target.closest('[data-act=\"toggle-nav\"]');
  if (n){
    var sb = n.closest('.sidebar');
    if (sb) sb.classList.toggle('nav-open');
    return;
  }
  var link = e.target.closest('.section-nav a');
  if (link){
    var sb2 = link.closest('.sidebar');
    if (sb2) sb2.classList.remove('nav-open');
    // fall through: let the anchor jump happen
  }
  var c = e.target.closest('[data-copy]');
  if (c){
    var name = c.getAttribute('data-copy');
    if (navigator.clipboard) navigator.clipboard.writeText(name);
    var toast = document.getElementById('toast');
    if (toast){
      toast.textContent = 'copied ' + name;
      toast.classList.add('show');
      clearTimeout(window.__t);
      window.__t = setTimeout(function(){ toast.classList.remove('show'); }, 1100);
    }
    if (c.classList.contains('token')){
      c.classList.add('copied');
      setTimeout(function(){ c.classList.remove('copied'); }, 500);
    }
  }
});

"})
}

def home-page [cfg: record, sections: list] {
  (HTML
    (head-block {
      title: "understand stellar"
      description: "Every Stellar CSS design token, shown visually. Click any token to copy it."
      path: ""
      image: "og.png"
    })
    (BODY
      (DIV {class: "shell"}
        (sidebar $sections "/")
        (MAIN {class: "content"}
          (DIV {class: "intro"}
            (H1 "See what Stellar gives you")
            (P {class: "lede"} "Stellar turns one config file into a full set of CSS variables: colors, text sizes, spacing, shadows, motion, and layout. This page shows each one in action. Click any token to copy it, and flip the theme to see light and dark.")
          )
          (color-section $cfg)
          (type-section $cfg)
          (space-section $cfg)
          (borders-section $cfg)
          (elevation-section $cfg)
          (motion-section $cfg)
          (layout-section $cfg)
        )
      )
      (DIV {class: "toast-copied" id: "toast"} "")
      (page-script)
      (compose-script)
    )
  )
}

# ---- notes: the journey + how to pair tokens ------------------------

# A live pairing sample: real surface + foreground tokens, with the WCAG
# contrast measured in the browser (see notes-script) so it tracks the theme.
def pair-card [surface: string, fg: string, label: string, desc: string] {
  (DIV {class: "pair-card"}
    (DIV {class: "pair-sample" style: {background: $"var\(($surface)\)" color: $"var\(($fg)\)"}}
      (SPAN {class: "pair-fg"} $fg)
      (SPAN {class: "pair-ratio"} "")
    )
    (DIV {class: "pair-meta"}
      (STRONG $label)
      (SPAN {class: "note"} $desc)
      (DIV {class: "token-row"} (token $surface) (token $fg))
    )
  )
}

def sweep-row [lc: string, light: string, dark: string, note: string] {
  (TR (TD $lc) (TD {class: "num"} $light) (TD {class: "num"} $dark) (TD {class: "muted"} $note))
}

def notes-script [] {
  (SCRIPT {__html: r##'
function toRGB(c){var cv=document.createElement("canvas");cv.width=1;cv.height=1;var x=cv.getContext("2d");x.fillStyle="#000";x.fillStyle=c;x.fillRect(0,0,1,1);var d=x.getImageData(0,0,1,1).data;return [d[0],d[1],d[2]];}
function lin(v){v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);}
function rl(p){return 0.2126*lin(p[0])+0.7152*lin(p[1])+0.0722*lin(p[2]);}
function ratio(a,b){var l1=rl(a),l2=rl(b),hi=Math.max(l1,l2),lo=Math.min(l1,l2);return (hi+0.05)/(lo+0.05);}
function annotate(){
  document.querySelectorAll(".pair-sample").forEach(function(el){
    var cs=getComputedStyle(el);
    var r=ratio(toRGB(cs.backgroundColor),toRGB(cs.color));
    var b=el.querySelector(".pair-ratio");
    if(!b)return;
    var sym=r>=4.5?" \u2713":(r>=3?" \u2248":" \u2717");
    b.textContent=r.toFixed(1)+":1"+sym;
    b.className="pair-ratio "+(r>=4.5?"ok":(r>=3?"mid":"bad"));
  });
}
annotate();
new MutationObserver(annotate).observe(document.documentElement,{attributes:true,attributeFilter:["class"]});
'##})
}

def notes-page [cfg: record, sections: list] {
  (HTML
    (head-block {
      title: "Notes | understand stellar"
      description: "Working notes on understanding Stellar, and how to pair its design tokens for readable, accessible UI."
      path: "notes"
      image: "og-notes.png"
    })
    (BODY
      (DIV {class: "shell"}
        (sidebar $sections "/notes")
        (MAIN {class: "content"}
          (DIV {class: "intro"}
            (H1 "Notes")
            (P {class: "lede"} "Working notes from understanding Stellar: the decisions, the dead ends, and how to pair tokens so they actually read. This page grows as the journey does.")
          )
          (SECTION {class: "section"}
            (section-head "pairing" "Pairing tokens" "Every shade in a ramp is a surface, with its own -on for readable text and -dim for a quieter companion. -on and -dim only work on their own shade. For a color on a different surface, reach into the ramp and pick a shade by contrast, which comes from how many shades apart two colors sit, not from which set they belong to.")

            (DIV {class: "block"}
              (H3 {class: "subhead"} "Built on a neutral-1 surface")
              (P {class: "note"} "What this whole site is built from. Each sample is the real token pair, and its WCAG contrast is measured live in your browser. Flip the theme and the numbers update.")
              (DIV {class: "pairing-grid"}
                (pair-card "--neutral-1" "--neutral-1-on" "Primary text" "headings, body")
                (pair-card "--neutral-1" "--neutral-1-dim" "Secondary text" "ledes, notes, captions")
                (pair-card "--neutral-1" "--primary-7" "Link / accent" "links, focus, active")
              )
            )

            (DIV {class: "block"}
              (H3 {class: "subhead"} "Making -dim readable")
              (P {class: "note"} "-dim is generated to an APCA contrast target. At the default Lc 30 it is decorative, far too faint for the prose this site is mostly made of. Raising the target makes it a legible secondary tier. One value cannot be both readable and muted in both modes, since APCA is polarity-aware, so the light side needs a higher target; 65 is the lowest that clears light while keeping dim softer than -on.")
              (DIV {class: "sweep"}
                (TABLE
                  (THEAD (TR (TH "dimTargetLc") (TH "light") (TH "dark") (TH "")))
                  (TBODY
                    (sweep-row "30 (before)" "1.7" "4.0" "decorative")
                    (sweep-row "50" "2.8" "7.0" "light still fails")
                    (sweep-row "60" "3.8" "8.9" "")
                    (sweep-row "65 (after)" "4.4" "9.9" "readable, still muted")
                    (sweep-row "70" "5.2" "11.0" "dark nears -on")
                  )
                )
                (P {class: "note"} "WCAG contrast of --neutral-1-dim on --neutral-1, light / dark.")
              )
              (DIV {class: "ba"}
                (FIGURE (IMG {src: "/assets/pairing-before.png" alt: "secondary text washed out"}) (FIGCAPTION "Before: Lc 30 (1.7:1)"))
                (FIGURE (IMG {src: "/assets/pairing-after.png" alt: "secondary text readable"}) (FIGCAPTION "After: Lc 65 (4.4:1)"))
              )
            )
          )
        )
      )
      (DIV {class: "toast-copied" id: "toast"} "")
      (page-script)
      (notes-script)
    )
  )
}

# Each page is deterministic from the config, so render once at startup and
# serve the cached HTML. A reload re-sources this file and re-renders; without
# the cache the full token reference rebuilds on every request (~4s).
let HOME = (home-page $cfg $SECTIONS)
let NOTES = (notes-page $cfg $SECTIONS)

{|req|
  dispatch $req [
    (route {path: "/"} {|req ctx| $HOME })
    (route {path: "/notes"} {|req ctx| $NOTES })

    (route {path-matches: "/assets/:file"} {|req ctx|
      .static ($env.PWD | path join "assets") $ctx.file
    })

    (route true {|req ctx|
      "Not Found" | metadata set { merge {'http.response': {status: 404}} }
    })
  ]
}
