# Lodestar: how this site is styled

This site is built with Stellar, so it is styled the way Stellar wants to be
used. Build it like a box of Lego.

## Every value is a token

Color, size, font, weight, radius, shadow, motion: each comes from a Stellar
token. No literals. A magic number in the CSS is a token that has not been found
yet.

## Raw tags are the blocks in the box

HTML tags are the blocks a Lego starter set ships with: `p`, `a`, `h1` through
`h6`, `code`, `ul`, `li`, `table`, and the rest. Style them once, well, with no
classes. Done right they build about 80% of the site on their own, and most
markup needs no class at all. Reach here first and stay here as long as the tags
carry the job. Strong base typography is the foundation everything else sits on.

## Server components are the add-on blocks

Some blocks do not come in the box: a color ramp, a transition composer, a
z-index demo. Build one as a server component, a Nushell `def` that snaps basic
tags together into the new block. Give the def one class, on its root, and style
everything inside by descending from that one class, so the basic tags are
reached through the block's name instead of each carrying its own. Each block
gets one class and no more.

Adding a block is a two-hammer decision: you would take two hits from a hammer
before writing the `def` and its class. If the blocks in the box and the ones
already built can express the thing, they must. A class that dresses one
element, in one place, named for the spot rather than for a block, is not a
block. It is a literal with a name. Fold it back into the blocks in the box.
