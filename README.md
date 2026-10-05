# Genesis

Genesis explores a set of sound synthesis procedures built from stochastic, chaotic and network-based functions and a set of tools for playing them: faders, presets, morphing between presets, and workflows that process or resonate the material.

![faders](docs/faders.png)

## Running it

Open `core/example.scd` and work down the blocks. The first one loads everything:

```supercollider
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;   // ~material, ~gen, ~play, ~solo, ~free, ~loaded
(~here ++ "core/fader-specs.scd").load;        // ~specs
(~here ++ "core/ndef-faders.scd").load;        // ~ndefFaders
(~here ++ "core/preset-morph.scd").load;       // ~loadPresets, ~presetMorph
~presets = ~loadPresets.(~here ++ "core/presets.scd");
```

Then `~play.(\gorse)` to hear one, `~free.()` to put everything back to sleep.

## The tools

Fader window: a slider per parameter, four randomize distributions, eight preset slots.

Morph window: travel from one preset to another, nine ways, over a duration.

<img src="docs/morph.png" width="460">

Curve window: one 512-point trajectory per parameter, walked over one duration.

![curves](docs/curves.png)

## The files

- `core/material-library.scd`: the ten processes as source functions, instantiated on demand
- `core/fader-specs.scd`: the fader range per parameter
- `core/ndef-faders.scd`, `core/ndef-curves.scd`, `core/preset-morph.scd`: the three windows
- `core/*-setups.scd`: one block per process, opens its window
- `core/presets.scd`: posted states, one line each; `//` and `/* */` take one out of the set
- `core/selection-principles.scd`: Koenig's six selection principles from SSP, and `~ssp`, which builds a process from a LIST / SELECT / SEGMENT / PERMUTATION plan
- `workflows/wf-*.scd`: granulation, sediment, waveset, feedback, resonance
- `workflows/of/`: processes woven together through OF's `.stack`/`.transform` chains
- `spatial/spatialisers.scd`: five ways of putting a 4-channel process into 8 channels

## Requirements

[OF](https://github.com/bjarnig/OF), a SuperCollider extension. All ten processes are `NF`, its `Ndef` subclass, and the `workflows/of/` files use its `.stack`/`.transform` chains.
