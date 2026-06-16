# Helpers for the Stellar visual reference.
#
# Reads stellar.config.json to learn how many steps each scale has and
# the named values, so the page reflects whatever the config generates.

use http-nu/html *

# Normalize config: recursively coerce step/count fields to int.
export def coerce-ints []: any -> any {
  let input = $in
  if ($input | describe | str starts-with "record") {
    $input | items {|k, v|
      let val = if ($k =~ 'Steps$|Count$|toneSteps') {
        $v | into int
      } else if ($v | describe | str starts-with "record") {
        $v | coerce-ints
      } else if ($v | describe | str starts-with "list") {
        $v | each {|item|
          if ($item | describe | str starts-with "record") { $item | coerce-ints } else { $item }
        }
      } else {
        $v
      }
      {$k: $val}
    } | into record
  } else {
    $input
  }
}

export def load-config [path: string]: nothing -> record {
  open $path | coerce-ints
}

# Inclusive list of integer steps from a negative/positive count.
export def steps [neg: int pos: int]: nothing -> list {
  seq (0 - $neg) $pos
}

# A copyable token chip. Clicking copies the variable name.
export def token [name: string]: nothing -> record {
  CODE {class: "token" data-copy: $name title: $"copy ($name)"} $name
}

# A section heading with an anchor id for sidebar nav.
export def section-head [id: string title: string lede: string]: nothing -> record {
  (HEADER {class: "section-head" id: $id}
    (H2 $title)
    (P {class: "lede"} $lede)
  )
}
