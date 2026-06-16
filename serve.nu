use http-nu/router *
use http-nu/html *
use lib.nu *

# understand-stellar: a visual reference for the Stellar CSS framework.
#
# One scrolling page that shows every design variable Stellar gives you,
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

def head-block [] {
  (HEAD
    (META {charset: "utf-8"})
    (META {name: "viewport" content: "width=device-width, initial-scale=1"})
    (TITLE "understand stellar")
    (SCRIPT {__html: "
(function(){
  var t = localStorage.getItem('theme');
  if (!t) t = window.matchMedia('(prefers-color-scheme:dark)').matches ? 'dark' : 'light';
  if (t === 'dark') document.documentElement.classList.add('dark');
})();
"})
    (LINK {rel: "stylesheet" href: "assets/stellar.css"})
    (LINK {rel: "stylesheet" href: "assets/page.css"})
    (SCRIPT-ICONIFY)
  )
}

def sidebar [sections: list] {
  (ASIDE {class: "sidebar"}
    (DIV {class: "brand"}
      (H1 "understand stellar")
      (P "A visual map of every design variable. Click any token to copy it.")
    )
    (BUTTON {class: "nav-toggle" data-act: "toggle-nav"} "Sections")
    (NAV {class: "section-nav"}
      (UL ( $sections | each {|s| LI (A {href: $"#($s.0)"} $s.1) } ))
    )
    (BUTTON {class: "theme-toggle" data-act: "toggle-theme"}
      (ICONIFY "lucide:sun-moon" {width: "16" height: "16"})
      (SPAN {id: "theme-label"} "theme")
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
      "Six semantic color roles, each a 12-step ramp from light to dark. Reach for primary on main actions, neutral for most surfaces and body text, and error for destructive or warning states. Build any component from a single role: a surface step for the background, its -on for text on top, and -dim for secondary text. Each swatch's number is painted in that step's -on color, so you can see where text stays readable.")

    (DIV {class: "block"} ( $roles | each {|r| color-ramp $r } ))

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Roles in practice")
      (P {class: "note"} "Each card is built only from one role's surface, -on, and -dim tokens.")
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
        (P {class: "note"} (token "--named-{brand}-{n}") $" : each brand seeded into a ($neg)+1+($pos) step ramp, plus -on and -dim.")
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
        (P {class: "note"} (token "--chart-qualitative-{n}") " : categorical colors chosen to be distinct, each with -on and -dim.")
        (mini-ramp "--chart-qualitative" (1..$qual | each {|n| $"($n)"}) (1..$qual | each {|n| $"($n)"}))
        (P {class: "note" style: {"margin-top": "var(--size-1)"}} (token $"--chart-diverging-{1..($div)}-step-{1..($tones)}") " : sequential ramps for ordered data.")
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
        (P {class: "note"} "The full syntax palette, derived from the theme and inverted for dark mode. Every token below is what the highlighter emits.")
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
      "A fluid type scale, plus font families, weights, line-height and letter-spacing. Size text from the scale instead of hard-coding pixels: step 0 is the 1rem body size, negative steps for fine print, positive steps for headings. Every size uses clamp(), so it grows smoothly with the viewport. Each specimen is set at the real token value, so what you see is what renders.")

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Size scale")
      (P {class: "note"} (token "--font-size-0") " is the 1rem base. Negative steps shrink, positive steps grow.")
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
        (P {class: "note"} "Each is a ready-made font stack with system fallbacks - a different typographic voice. Reach for --font-sans on UI and body text, --font-mono for code and figures, --font-serif for long-form; the rest are character choices. The same sentence is set in each so you can compare. " (token "--font-{name}") ".")
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
        (P {class: "note"} "Tighter at low steps, airier at high. " (token "--font-line-height-{n}") ".")
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
      "One fluid scale for padding, margin, gaps and component sizing. Pull spacing from these steps rather than arbitrary pixels, and reuse the same step for related gaps to keep a consistent rhythm. Each step is a fixed musical ratio larger than the last, so the scale stays harmonious as it grows. Each bar's width is the token value itself.")
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
      "Border widths and corner radii, plus a few organic shapes. Use a small radius for inputs and cards, a larger one for pills and avatars, and match border width to emphasis. The blob and hand-drawn radii are pre-generated for surfaces that should feel less rigid. Each box applies the token directly, so a rounder corner is a larger value.")

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
            (P {class: "note"} (token "--radius-blob-{n}") " : soft, asymmetric blobs.")
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
      "A shadow scale that separates surfaces by depth. Use higher positive steps the further an element floats above the page: a card sits low, a dropdown higher, a dialog highest. Negative steps press a surface inward as an inset well, handy for inputs. The further from zero, the stronger the effect.")
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
      "Motion is three tokens working together. An easing (--anim-ease-*) shapes how a change accelerates and settles - standard for most UI, entrance or emphasized to pull the eye, a bounce or elastic for character. A duration (--anim-duration-*) sets how long it takes - fast for hover and toggle feedback, base for most transitions, slow for larger or more deliberate moves. A transform amount (--anim-scale-*, -rotate-*, -distance-*, -opacity-*) says how far it goes - how much to grow, turn, slide, or fade. You spend them together in one rule - transition: <property> <duration> <easing> - with the amount as the value it animates to. Build one below, play it, and copy the exact CSS.")
    (compose-block $cfg)

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Raw amount stops")
      (P {class: "note"} "The compose chips above use the named amounts (up, xl, muted). Each maps onto a numeric stop on the underlying scale - copy these when you want the raw step.")
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
      "Stacking order, aspect ratios and the viewport bounds behind every fluid scale. Use the named z-index steps to keep overlapping elements in a predictable order, a dropdown above content and a toast above that, instead of guessing magic numbers. Aspect-ratio tokens frame media at common proportions. The viewport min and max are the widths the fluid scales interpolate between.")

    (if (not ($cfg.general.zindexes.disabled)) {
      let levels = ($cfg.general.zindexes.levels)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Stacking order")
        (P {class: "note"} "Named layers so overlapping UI stacks predictably - a dropdown above content, a tooltip above that, a dialog and its toast on top - instead of hand-picked z-index numbers that drift out of order. The cards below overlap in their real order. " (token "--zindex-{name}") ".")
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
        (P {class: "note"} "Lock a box to a proportion so media and embeds hold their shape at any width - 16:9 for video, 1:1 for avatars, and so on. " (token "--aspect-ratio-{name}") ".")
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
        (P {class: "note"} $"Every fluid token - the type scale, the spacing scale, the rest - interpolates with clamp\(\) across this window. At ($vmin)px and narrower it sits at its smallest; at ($vmax)px and wider, its largest; it scales linearly between. You rarely set these directly - they are the anchors the whole responsive system is tuned to. Reach for them when you want a media query or your own fluid value to line up with the scales.")
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

{|req|
  dispatch $req [
    (route {path: "/"} {|req ctx|
      (HTML
        (head-block)
        (BODY
          (DIV {class: "shell"}
            (sidebar $SECTIONS)
            (MAIN {class: "content"}
              (DIV {class: "intro"}
                (H1 "See what Stellar gives you")
                (P {class: "lede"} "Stellar generates a complete set of design tokens from one config: color systems, a fluid type scale, a spacing rhythm, elevation, motion, and layout primitives. This page shows each one visually. Click any token to copy its variable name. Toggle the theme to check both modes.")
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
    })

    (route {path-matches: "/assets/:file"} {|req ctx|
      .static ($env.PWD | path join "assets") $ctx.file
    })

    (route true {|req ctx|
      "Not Found" | metadata set { merge {'http.response': {status: 404}} }
    })
  ]
}
