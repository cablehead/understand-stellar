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
    (LINK {rel: "stylesheet" href: "/assets/stellar.css"})
    (LINK {rel: "stylesheet" href: "/assets/page.css"})
    (SCRIPT-ICONIFY)
  )
}

def sidebar [sections: list] {
  (ASIDE {class: "sidebar"}
    (DIV {class: "brand"}
      (H1 "understand stellar")
      (P "A visual map of every design variable. Click any token to copy it.")
    )
    (NAV
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
        (SPAN {class: "on"} "on")
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
          (DIV {class: "brand-card"}
            (SPAN {class: "name"} $b)
            (DIV {class: "brand-chips"} ( (steps $neg $pos) | each {|n|
              SPAN {data-copy: $"--named-($b)-($n)" style: {background: $"var\(--named-($b)-($n)\)"} title: $"--named-($b)-($n)"}
            }))
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
        (P {class: "note"} (token "--chart-qualitative-{n}") " : categorical colors chosen to be distinct.")
        (DIV {class: "qual"} ( 1..$qual | each {|n|
          (DIV {class: "swatch" data-copy: $"--chart-qualitative-($n)"
                style: {background: $"var\(--chart-qualitative-($n)\)" color: $"var\(--chart-qualitative-($n)-on\)"} title: $"--chart-qualitative-($n)"}
            $"($n)")
        }))
        (P {class: "note" style: {"margin-top": "var(--size-1)"}} (token $"--chart-diverging-{1..($div)}-step-{1..($tones)}") " : sequential ramps for ordered data.")
        (DIV ( 1..$div | each {|p|
          (DIV {class: "chart-ramp"} ( 1..$tones | each {|n|
            SPAN {data-copy: $"--chart-diverging-($p)-step-($n)" style: {background: $"var\(--chart-diverging-($p)-step-($n)\)"} title: $"--chart-diverging-($p)-step-($n)"}
          }))
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
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Code & syntax")
        (P {class: "note"} "A full syntax palette, derived from the theme and inverted for dark mode.")
        (DIV {class: "code-demo"}
          (PRE (CODE ($sample | .highlight rust))))
        (DIV {class: "token-row"} ( [--code-bg --code-fg --code-comment --code-keyword --code-string --code-number --code-name-function --code-type --code-name-variable --code-string-escape --code-error --code-inserted --code-deleted] | each {|t| token $t } ))
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
      let fams = ($cfg.fonts.families.values | get name)
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Families")
        (P {class: "note"} "Same sentence, every family. " (token "--font-{name}") ".")
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
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Corner radius")
        (DIV {class: "box-grid"} ( (steps $neg $pos) | each {|n|
          (DIV {class: "demo-box" data-copy: $"--border-radius-($n)" style: {"border-radius": $"var\(--border-radius-($n)\)"}}
            $"--border-radius-($n)")
        }))
        (P {class: "note"} "Half steps interpolate between neighbors: " (token "--border-radius-1-2") " (1->2), " (token "--border-radius-2-3") ", and so on.")
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
      "The building blocks of animation: easing curves, durations and transform presets. Compose them for transitions and keyframes, an easing for how a change accelerates, a duration for how long it runs, a transform preset for how far something scales, rotates or moves. Reach for the same tokens everywhere to keep motion consistent. The demos below are interactive so you can feel each one.")

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Easing")
      (P {class: "note"} "How a change accelerates over time. Use standard for most UI, entrance or emphasized to draw attention, a bounce or elastic for character. Press play to send the dot across the track with that easing. " (token "--anim-ease-{name}") ".")
      (DIV {class: "motion-grid"} ( ($cfg.animations.easings | get name) | each {|e|
        (DIV {class: "motion-card" data-copy: $"--anim-ease-($e)"}
          (DIV {class: "head"} (STRONG $e) (token $"--anim-ease-($e)") (play-btn))
          (DIV {class: "ease-track"}
            (DIV {class: "ease-dot" data-ease: $"--anim-ease-($e)"})))
      }))
    )

    (if (not ($cfg.animations.durations.disabled)) {
      let dn = ($cfg.animations.durations)
      let all = (($dn.named | get name) | append ((steps $dn.negativeSteps $dn.positiveSteps) | each {|n| $"($n)"}))
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Duration")
        (P {class: "note"} "How long a transition runs. Use fast for small hover or toggle feedback, base for most transitions, slow for larger or more deliberate moves. Named aliases read clearly in code; numeric steps give finer control. Press play to pulse the bar, which transitions on the real token, so a fast one visibly beats quicker than a slow one. (Instant in browsers without CSS length-division, e.g. Firefox.)")
        (DIV ( $all | each {|d|
          (DIV {class: "dur-row" data-copy: $"--anim-duration-($d)"}
            (token $"--anim-duration-($d)")
            (DIV {class: "dur-track"}
              (DIV {class: "dur-fill" style: {transition: $"width var\(--anim-duration-($d)\) linear"}}))
            (play-btn))
        }))
      )
    })

    (DIV {class: "block"}
      (H3 {class: "subhead"} "Transforms")
      (P {class: "note"} "Preset amounts for the four things you animate most: how much to scale, rotate, slide (distance) or fade (opacity). Use a subtle step for hover feedback, a stronger one for entrances or attention. Press play on a tile to run its preset.")

      (P {class: "tf-label"} "scale")
      (if (not ($cfg.animations.scales.disabled)) {
        (DIV {class: "transforms"} ( $cfg.animations.scales.named | each {|s|
          (DIV {class: "tf-item" data-copy: $"--anim-scale-($s.name)"}
            (DIV {class: "tf-stage"} (DIV {class: "tf-box tf-scale" style: {"--tf-to": $"var\(--anim-scale-($s.name)\)"}} "scale"))
            (DIV {class: "tf-foot"} (token $"--anim-scale-($s.name)") (play-btn)))
        }))
      })

      (P {class: "tf-label"} "rotate")
      (if (not ($cfg.animations.rotations.disabled)) {
        (DIV {class: "transforms"} ( $cfg.animations.rotations.named | each {|r|
          (DIV {class: "tf-item" data-copy: $"--anim-rotate-($r.name)"}
            (DIV {class: "tf-stage"} (DIV {class: "tf-box tf-rotate" style: {"--tf-to": $"var\(--anim-rotate-($r.name)\)"}} "rotate"))
            (DIV {class: "tf-foot"} (token $"--anim-rotate-($r.name)") (play-btn)))
        }))
      })

      (P {class: "tf-label"} "distance")
      (if (not ($cfg.animations.distances.disabled)) {
        (DIV {class: "transforms"} ( $cfg.animations.distances.named | each {|d|
          (DIV {class: "tf-item" data-copy: $"--anim-distance-($d.name)"}
            (DIV {class: "tf-stage tf-stage-slide"} (DIV {class: "tf-box tf-slide" style: {"--tf-to": $"var\(--anim-distance-($d.name)\)"}} "slide"))
            (DIV {class: "tf-foot"} (token $"--anim-distance-($d.name)") (play-btn)))
        }))
      })

      (P {class: "tf-label"} "opacity")
      (if (not ($cfg.animations.opacities.disabled)) {
        (DIV {class: "transforms"} ( $cfg.animations.opacities.named | each {|o|
          (DIV {class: "tf-item" data-copy: $"--anim-opacity-($o.name)"}
            (DIV {class: "tf-stage"} (DIV {class: "tf-box tf-fade" style: {"--tf-to": $"var\(--anim-opacity-($o.name)\)"}} "fade"))
            (DIV {class: "tf-foot"} (token $"--anim-opacity-($o.name)") (play-btn)))
        }))
      })
    )

    (compose-block $cfg)
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
        (P {class: "note"} "Cards overlap in z-index order. " (token "--zindex-{name}") ".")
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
        (DIV {class: "aspect-grid"} ( $named | each {|a|
          (DIV {class: "aspect-box" data-copy: $"--aspect-ratio-($a.name)"
                style: {"aspect-ratio": $"var\(--aspect-ratio-($a.name)\)"}}
            $a.name)
        }))
      )
    })

    (if (not ($cfg.general.viewport.disabled)) {
      (DIV {class: "block"}
        (H3 {class: "subhead"} "Viewport bounds")
        (P {class: "note"} "Fluid clamp() scales interpolate between these widths.")
        (DIV {class: "token-row"} (token "--viewport-min") (token "--viewport-max") (token "--viewport-base-font-size"))
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
  let amount_chips = ($amount_sets | items {|prop, names|
    $names | each {|a| (BUTTON {class: "chip" data-set: $prop data-amount: $a} $a) }
  } | flatten)
  (DIV {class: "block compose"}
    (H3 {class: "subhead"} "Compose")
    (P {class: "note"} "Tokens are used together: a property, a duration, an easing, and (for transforms) an amount become one transition. Configure it, toggle Activate to hold the state, copy the CSS - this is how you actually reach for them.")
    (DIV {class: "composer"}
      (DIV {class: "config"}
        (chip-row "property" "prop" ([scale rotate slide fade] | each {|p| BUTTON {class: "chip" data-prop: $p} $p}))
        (chip-row "amount" "amount" $amount_chips)
        (chip-row "duration" "dur" (
          ($durs | each {|d| BUTTON {class: "chip" data-dur: $d} $d})
          | append (SPAN {class: "chip-sep"} "steps")
          | append ($dnums | each {|n| BUTTON {class: "chip chip-num" data-dur: $"($n)"} $"($n)"})
        ))
        (chip-row "easing" "ease" ($eases | each {|e| BUTTON {class: "chip" data-ease: $e} $e}))
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
  var state = {prop:'scale', amount:'up', dur:'slow', ease:'emphasized', active:false};
  var MAP = {
    scale: {prop:'transform', fn:'scale', tok:'--anim-scale-', def:'up'},
    rotate:{prop:'transform', fn:'rotate', tok:'--anim-rotate-', def:'md'},
    slide: {prop:'transform', fn:'translateX', tok:'--anim-distance-', def:'md'},
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
  function trigger(){
    // clean restart: settle to rest with no transition, then animate to the
    // target, so the full easing curve plays from the start on every change.
    thing.style.transition='none'; rest(); void thing.offsetWidth;
    applyTransition(); setTargetStyle();
  }
  function relax(){ applyTransition(); rest(); }
  function updateBtn(){ if(go){ go.textContent=state.active?'Reset':'Activate'; go.classList.toggle('on', state.active); } }
  root.addEventListener('click', function(e){
    if(e.target.closest('#compose-go')){ state.active=!state.active; if(state.active){ trigger(); } else { relax(); } updateBtn(); return; }
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
    applyTransition(); if(state.active){ trigger(); } render();
  });
  setActive('prop','data-prop',state.prop);
  setActive('dur','data-dur',state.dur);
  setActive('ease','data-ease',state.ease);
  showAmounts(); applyTransition(); render(); updateBtn();
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
  var pb = e.target.closest('[data-act=\"play\"]');
  if (pb){
    var card = pb.closest('.motion-card');
    var row = pb.closest('.dur-row');
    var tile = pb.closest('.tf-item');
    if (card) playEase(card.querySelector('.ease-dot'));
    else if (row) playDur(row.querySelector('.dur-fill'));
    else if (tile) playTf(tile.querySelector('.tf-box'));
    return;
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

function playEase(dot){
  if (!dot) return;
  dot.getAnimations().forEach(function(a){ a.cancel(); });
  try {
    var name = dot.getAttribute('data-ease');
    var ease = getComputedStyle(document.documentElement).getPropertyValue(name).trim() || 'linear';
    dot.animate(
      [{left: '0%'}, {left: '100%'}],
      {duration: 1200, easing: ease, iterations: 2, direction: 'alternate'}
    );
  } catch (err) {}
}
function playTf(box){
  if (!box) return;
  // .playing transitions the box to the token's value; remove it to ease back.
  box.classList.add('playing');
  clearTimeout(box.__t);
  box.__t = setTimeout(function(){ box.classList.remove('playing'); }, 650);
}

function playDur(fill){
  if (!fill) return;
  // The fill carries `transition: width var(--anim-duration-X) linear`, so each
  // width toggle takes the real token duration. Pulse a few legs so the tempo -
  // fast vs slow - reads. Instant where length-division is unsupported (Firefox).
  var legs = 6;
  fill.ontransitionend = function(){
    legs -= 1;
    if (legs <= 0){ fill.ontransitionend = null; fill.style.width = '0%'; return; }
    fill.style.width = (fill.style.width === '100%') ? '0%' : '100%';
  };
  clearTimeout(fill.__t);
  fill.__t = setTimeout(function(){ fill.ontransitionend = null; fill.style.width = '0%'; }, 6000);
  fill.style.width = '0%';
  void fill.offsetWidth;
  fill.style.width = '100%';
}

"})
}

# A small play button that triggers an adjacent motion demo. Clicking it
# plays; clicking the item itself copies the token (handled in the script).
def play-btn [] {
  (BUTTON {class: "play-btn" title: "Play" data-act: "play"} (ICONIFY "lucide:play" {width: "13" height: "13"}))
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
