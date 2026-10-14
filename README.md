# introduction_card

A one-page personal introduction card for a software engineer, written entirely
in [Gleam](https://gleam.io) with [Lustre](https://lustre.build) and styled after
the menu interface of *NieR:Automata* — rendered in a deep navy palette instead
of the game's sand tones. Deployed as a static site to GitHub Pages.

The visual language is modelled on
[Kndgy/NieR-Automata-Design-System](https://github.com/Kndgy/NieR-Automata-Design-System)
(the site behind <https://yorha-archive.netlify.app>), but rebuilt from scratch
as a single Gleam program with no hand-written JavaScript or TypeScript.

## What it does

- Plays a YoRHa-style boot sequence on load: a glitch `LOADING — CHECKING
  SYSTEM` header, a spinning loader, and eighteen system-check lines that type
  themselves out one character at a time before the overlay fades away.
- Slides in the main card, whose title and subtitle use the same tri-layer
  glitch effect as the reference site.
- Shows a horizontal row of destination tabs at the top (GitHub, website,
  LinkedIn, email), followed by the profile card. Each tab uses the signature
  YoRHa menu interaction: the bar inverts from navy to ice, the icon flips, and
  two lines flick out above and below the item on hover or keyboard focus.
- Responsive down to small phone widths, where the tab row scrolls sideways.

## Editing your details

Almost everything you may want to change lives near the top of
[`src/introduction_card.gleam`](src/introduction_card.gleam):

- `destinations()` — the top tabs and where they redirect to.
- `fields()` — the status readout (designation, location, stack, …).
- `loading_messages()` — the boot diagnostics.
- `document_title`, `identifier`, `callsign`, `subtitle`, `summary` — identity
  text.

Visual styling lives in [`assets/style.css`](assets/style.css). The palette is
defined as CSS custom properties at the top of that file; the boot timing is
driven by the `--boot-total` custom property, which Gleam computes from the
length of the boot messages.

## How it works without JavaScript/TypeScript

The only thing Gleam emits is the application bundle; all motion is CSS. The
boot log is revealed with a per-line `clip-path` animation whose `steps()` count
and delay are generated in Gleam and passed through inline custom properties
(`--chars`, `--dur`, `--delay`). Highlight state is the one piece of Lustre
state, used to add an `is-active` class for keyboard focus.

## Development

```sh
gleam run -m lustre/dev start   # dev server at http://localhost:1234
gleam test                      # run the tests
```

## Building

```sh
gleam run -m lustre/dev build --minify --outdir=dist
```

The static site is written to `dist/` (Gleam bundle, `style.css`, `emblem.svg`
and `favicon.svg`).

## Deployment

Pushing to `main` triggers the workflow in
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which builds the
site and publishes `dist/` to GitHub Pages. Because a project site is served
from `/<repo>/`, the workflow rewrites the bundle's absolute `src` path to a
relative one before uploading.

Before the first deploy, head to your repository's **Settings → Pages** and set
the source to **GitHub Actions**.
