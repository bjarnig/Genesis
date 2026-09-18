// preset-morph-setups.scd
// A morph-GUI setup for every process, one block each, storing the handle in
// ~morphs - the preset-morph analogue of ndef-faders-setups.scd. Each duration
// and curve below is a starting point matched to that process's own measured
// timescale and behaviour (see genesis-material-field notes), not a fixed rule:
// the window's own secs/how controls are yours to change after it opens.
//
// Run the first block once, then whichever setups you want.

( // load the GUI function, the material library, and the presets (run once)
"/Users/bjarni/Works/Pieces/Genesis/core/preset-morph.scd".load;   // ~loadPresets, ~presetMorph
"/Users/bjarni/Works/Pieces/Genesis/core/material-library.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/fader-specs.scd".load;    // ~specs, for spec-space blending
~presets = ~loadPresets.("/Users/bjarni/Works/Pieces/Genesis/core/presets.scd");
~morphs = ~morphs ? ();
)


( // fern - Cyclegen layers move on freqMul/detune only; a middling glide
~morphs = ~morphs ? ();
~morphs[\fern] = ~presetMorph.(~gen.(\fern), ~presets[\fern], ~specs[\fern], nil, 15, \smooth);
)


( // moss - grain-rate texture, the fastest-changing of the six-strong family;
  // a short morph lets you hear it as a move, not a held average
~morphs = ~morphs ? ();
~morphs[\moss] = ~presetMorph.(~gen.(\moss), ~presets[\moss], ~specs[\moss], nil, 10, \zigzag);
)


( // sedge - slow FitzHughNagumo/bandstop drift; wants room to settle
~morphs = ~morphs ? ();
~morphs[\sedge] = ~presetMorph.(~gen.(\sedge), ~presets[\sedge], ~specs[\sedge], nil, 25, \decel);
)


( // nettle - still mono and ~14dB hot at defaults (open defect): keep morphs
  // short until that's fixed, so a bad landing doesn't sit there long
~morphs = ~morphs ? ();
~morphs[\nettle] = ~presetMorph.(~gen.(\nettle), ~presets[\nettle], ~specs[\nettle], nil, 12, \linear);
)


( // bramble - grain-scale leaf/gravity events, similar case to moss
~morphs = ~morphs ? ();
~morphs[\bramble] = ~presetMorph.(~gen.(\bramble), ~presets[\bramble], ~specs[\bramble], nil, 10, \scatter);
)


( // clover - DC-fixed ramp/steps texture, moves in even, structural jumps
~morphs = ~morphs ? ();
~morphs[\clover] = ~presetMorph.(~gen.(\clover), ~presets[\clover], ~specs[\clover], nil, 15, \smooth);
)


( // thistle - rebuilt bandpass bank (2026-09-15), 4-channel; a mid-length
  // glide lets the Q-wander per channel actually separate out
~morphs = ~morphs ? ();
~morphs[\thistle] = ~presetMorph.(~gen.(\thistle), ~presets[\thistle], ~specs[\thistle], nil, 18, \accel);
)


( // yarrow - the more complex isolate; give it the room sedge gets
~morphs = ~morphs ? ();
~morphs[\yarrow] = ~presetMorph.(~gen.(\yarrow), ~presets[\yarrow], ~specs[\yarrow], nil, 25, \decel);
)


( // gorse - feedback layer + non-repeatable build (two open defects): presets
  // predate the amp/peakGain edits too, so treat any morph here as exploratory
~morphs = ~morphs ? ();
~morphs[\gorse] = ~presetMorph.(~gen.(\gorse), ~presets[\gorse], ~specs[\gorse], nil, 12, \linear);
)


( // teasel - still mono (open defect), but genuinely the most mobile of the
  // ten on carrier alone; a longer morph shows that off
~morphs = ~morphs ? ();
~morphs[\teasel] = ~presetMorph.(~gen.(\teasel), ~presets[\teasel], ~specs[\teasel], nil, 20, \smooth);
)
