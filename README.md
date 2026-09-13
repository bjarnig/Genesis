# Genesis

Ten processes, and a set of tools for playing them: faders, presets, morphing
between presets, five workflows that granulate or resonate the material, and five
spatialisers that put a 4-channel process into 8 channels.

Everything is a NodeProxy. Nothing reaches the server until a key is asked for,
and nothing is heard until something monitors it.

## Running it

Open `example.scd` and work down the blocks. The first one loads everything:

```supercollider
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;   // ~material, ~gen, ~play, ~solo, ~free, ~loaded
(~here ++ "core/fader-specs.scd").load;        // ~specs
(~here ++ "core/ndef-faders.scd").load;        // ~ndefFaders
(~here ++ "core/preset-morph.scd").load;       // ~loadPresets, ~presetMorph
~presets = ~loadPresets.(~here ++ "core/presets.scd");
```

Then `~play.(\gorse)` to hear one, `~free.()` to put everything back to sleep.

## The files

| | |
|---|---|
| `example.scd` | the running order |
| `core/material-library.scd` | the ten processes as source functions, instantiated on demand |
| `core/fader-specs.scd` | the fader range per parameter: min, max, warp, step, default |
| `core/ndef-faders.scd` | the fader GUI: play, reset, four randomize distributions, post |
| `core/ndef-faders-setups.scd` | one block per process, opens its window |
| `core/presets.scd` | posted states, one line each; `//` and `/* */` take one out of the set |
| `core/preset-morph.scd` | travel from one preset to another, nine ways, over a duration |
| `core/selection-principles.scd` | Koenig's six selection principles from SSP, and `~ssp`, which builds a process from a LIST / SELECT / SEGMENT / PERMUTATION plan |
| `workflows/wf-*.scd` | five workflows: granulation, sediment, waveset, feedback, resonance |
| `spatial/spatialisers.scd` | five ways of putting a 4-channel process into 8 channels |
| `variants/` | the same ten in one direction each: distortion, feedback, pitch |
| `sketches/` | the scratch files the library was lifted from, plus the earlier studies |
| `reference/` | the two patches the workflows were modelled on |
| `envgen/` | DemandEnvGen blocks harvested from across `Works/`, its own README |

`sketches/material-combined-v4.scd` is the original scratch file the library was
lifted from. It is now behind for `fern`, `moss`, `gorse` and `teasel`: the
library is the live copy.

## Worth knowing

- Handles are called method-style: `~faders[\gorse].randomize(\beta)`,
  `~morph.go(3, \zigzag, 20)`. Dot access on an Event calls the function it finds,
  so `.randomize.(\beta)` silently drops the argument.
- `Cyclegen` fixes `knum` and `freqs` at build time, so fern's `knumFrom`/`knumTo`
  only bite on the next `~gen.(\fern)`. They have no faders for that reason.
- `Moraine` returned digital silence on this build, in all four modes against
  three gate settings. `wf-sediment.scd` routes around it; `Creep`, `Scree`,
  `Talus`, `Loess` and `Sediment` all work.
- The gorse presets predate the gorse edits: no `fbGain` or `peakGain`, and a few
  values sit outside the current fader ranges. They still morph correctly.
- Preset blending happens in fader space, so an `\exp` parameter glides
  geometrically. That needs `~specs`; without it the blend is linear.
