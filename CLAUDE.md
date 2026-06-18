# understand-stellar

## Terminology

Call them **tokens**. Stellar generates design tokens, and this site refers to
them as tokens everywhere: prose, UI copy, code comments, commit messages. Not
"variables", and not "custom properties" (that is the underlying CSS mechanism,
not what we call the thing).

## Styling

`lodestar.md` is how the site is styled: tokens for every value, raw HTML tags
as the starter kit, server components (a Nushell `def`, one class each) as the
add-on blocks. Read it before adding CSS.
