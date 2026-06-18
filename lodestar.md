# Lodestar: how this site is styled

This site is built with Stellar, so it is styled the way Stellar wants to be
used. The CSS is the demonstration. These tiers are the order to reach for, top
to bottom. Stop at the first that carries the job.

## The tiers

0. **Tokens.** Every value comes from a Stellar custom property: color, size,
   font, weight, radius, shadow, motion. No literals. A magic number in the CSS
   is a token that has not been found yet.

1. **Raw tags.** Style bare HTML so unclassed markup reads well: `body`, `a`,
   `p`, `h1`-`h6`, `code`, `ul`, `table`, and the rest. Strong base typography
   is the foundation; most prose needs no class at all.

2. **Utilities.** When a tag cannot carry a local adjustment, use a
   single-purpose class that packages a few tokens, Tailwind-style: one job,
   named for the job, reusable anywhere. `.mono`, `.dim`, `.stack`.

3. **Components.** The smallest possible set of repeated patterns that raw tags
   and utilities cannot express. Each names a pattern that recurs, not a place
   it appears. A component earns its class by being used in many spots.

## The test

A class is wrong when it dresses one element, in one place, and is named for
that spot rather than a pattern. That is not a component; it is a literal with a
name. Fold it back: push what it does into the base tag styles, or express it by
composing utilities. The smallest set of components that covers the whole UI is
the target; everything above tier 3 should be raw tags and utilities.

When a fix means adding a narrowly-scoped class, first ask why the raw tag or an
existing utility cannot carry it, and fix that instead. Reach for a new class
only after confirming the shared one genuinely cannot cover the case.
