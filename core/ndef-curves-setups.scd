// ndef-curves-setups.scd
// A trajectory-editor setup for every process, one block each, storing the
// handle in ~curves - the ndef-curves analogue of ndef-faders-setups.scd and
// preset-morph-setups.scd. Each window opens with its eight preset buttons
// already lit and every row flat at whatever the proxy currently holds, so
// opening one changes nothing until you draw or recall.
//
// The duration on each block is a starting point matched to that process's own
// timescale - a gesture wants longer than the morph window's A-to-B glide, since
// the shape itself has to have room to read. The secs box is yours after that.
//
// Run the first block once, then whichever setups you want.
//
//   ~curves[\sedge].run;          // or .run(60) to override the secs box
//   ~curves[\sedge].recallSlot(3);
//   ~curves[\sedge].halt;

( // load the GUI function, the material library, and the presets (run once)
"/Users/bjarni/Works/Pieces/Genesis/core/ndef-curves.scd".load;    // ~ndefCurves
"/Users/bjarni/Works/Pieces/Genesis/core/material-library.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/fader-specs.scd".load;    // ~specs, the ranges
"/Users/bjarni/Works/Pieces/Genesis/core/preset-morph.scd".load;   // ~loadPresets
~presets = ~loadPresets.("/Users/bjarni/Works/Pieces/Genesis/core/presets.scd");
~curves = ~curves ? ();
)


( // fern
~curves = ~curves ? ();
~curves[\fern] = ~ndefCurves.(~gen.(\fern), ~specs[\fern], presets: ~presets[\fern], dur: 20);
)


( // moss - grain-rate texture, the fastest-changing of the six; a shorter pass
~curves = ~curves ? ();
~curves[\moss] = ~ndefCurves.(~gen.(\moss), ~specs[\moss], presets: ~presets[\moss], dur: 15);
)


( // sedge - slow drift, wants a long walk to hear the shape rather than the state
~curves = ~curves ? ();
~curves[\sedge] = ~ndefCurves.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge], dur: 40);
)


( // nettle - still mono and hot at defaults (open defect): keep passes short
~curves = ~curves ? ();
~curves[\nettle] = ~ndefCurves.(~gen.(\nettle), ~specs[\nettle], presets: ~presets[\nettle], dur: 20);
)


( // bramble - grain-scale leaf/gravity events, the moss case again
~curves = ~curves ? ();
~curves[\bramble] = ~ndefCurves.(~gen.(\bramble), ~specs[\bramble], presets: ~presets[\bramble], dur: 15);
)


( // clover - DC-fixed ramp/steps, moves in even structural jumps
~curves = ~curves ? ();
~curves[\clover] = ~ndefCurves.(~gen.(\clover), ~specs[\clover], presets: ~presets[\clover], dur: 25);
)


( // thistle - no presets in presets.scd yet, so its eight buttons stay unlit;
  // draw from the defaults, or post states into presets.scd from the fader window
~curves = ~curves ? ();
~curves[\thistle] = ~ndefCurves.(~gen.(\thistle), ~specs[\thistle], presets: ~presets[\thistle], dur: 30);
)


( // yarrow - the more complex isolate, give it the room sedge gets
~curves = ~curves ? ();
~curves[\yarrow] = ~ndefCurves.(~gen.(\yarrow), ~specs[\yarrow], presets: ~presets[\yarrow], dur: 40);
)


( // gorse - feedback layer and a non-repeatable build (open defects), and one
  // preset value sits under the c floor: treat a pass here as exploratory
~curves = ~curves ? ();
~curves[\gorse] = ~ndefCurves.(~gen.(\gorse), ~specs[\gorse], presets: ~presets[\gorse], dur: 20);
)


( // teasel - still mono (open defect) but the most mobile of the ten on carrier
~curves = ~curves ? ();
~curves[\teasel] = ~ndefCurves.(~gen.(\teasel), ~specs[\teasel], presets: ~presets[\teasel], dur: 30);
)
