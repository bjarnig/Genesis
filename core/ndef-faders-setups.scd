// ndef-faders-setups.scd
// A fader-GUI setup for every process in sketches/material-combined-v4.scd.
// Each block opens a window for one Ndef/NF and stores the handle in ~faders,
// so you can drive it from code, e.g.  ~faders[\gorse].randomize(\beta)
//
// Run the first block once (loads ~ndefFaders, the material library, and the
// presets), then whichever setups you want. Each block asks the library for
// its process with ~gen, so opening a window instantiates that one and
// nothing else; ~free.(\key) puts it back to sleep. Each window also arrives
// with its preset slots pre-filled from presets.scd, up to the first 8 - see
// ndef-faders.scd for what a slot then does.
//
// The ranges live in fader-specs.scd as ~specs[\gorse]; edit them there.

( // load the GUI function, the material library, and the presets (run once)
"/Users/bjarni/Works/Pieces/Genesis/core/ndef-faders.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/material-library.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/fader-specs.scd".load;    // ~specs, the ranges
"/Users/bjarni/Works/Pieces/Genesis/core/preset-morph.scd".load;   // ~loadPresets
~faders = ~faders ? ();
~presets = ~loadPresets.("/Users/bjarni/Works/Pieces/Genesis/core/presets.scd");
)


( // fern
~faders = ~faders ? ();
~faders[\fern] = ~ndefFaders.(~gen.(\fern), ~specs[\fern], presets: ~presets[\fern]);
)


( // moss
~faders = ~faders ? ();
~faders[\moss] = ~ndefFaders.(~gen.(\moss), ~specs[\moss], presets: ~presets[\moss]);
)


( // sedge
~faders = ~faders ? ();
~faders[\sedge] = ~ndefFaders.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge]);
)


( // nettle
~faders = ~faders ? ();
~faders[\nettle] = ~ndefFaders.(~gen.(\nettle), ~specs[\nettle], presets: ~presets[\nettle]);
)


( // bramble
~faders = ~faders ? ();
~faders[\bramble] = ~ndefFaders.(~gen.(\bramble), ~specs[\bramble], presets: ~presets[\bramble]);
)


( // clover
~faders = ~faders ? ();
~faders[\clover] = ~ndefFaders.(~gen.(\clover), ~specs[\clover], presets: ~presets[\clover]);
)


( // thistle
~faders = ~faders ? ();
~faders[\thistle] = ~ndefFaders.(~gen.(\thistle), ~specs[\thistle], presets: ~presets[\thistle]);
)


( // yarrow
~faders = ~faders ? ();
~faders[\yarrow] = ~ndefFaders.(~gen.(\yarrow), ~specs[\yarrow], presets: ~presets[\yarrow]);
)


( // gorse
~faders = ~faders ? ();
~faders[\gorse] = ~ndefFaders.(~gen.(\gorse), ~specs[\gorse], presets: ~presets[\gorse]);
)


( // teasel
~faders = ~faders ? ();
~faders[\teasel] = ~ndefFaders.(~gen.(\teasel), ~specs[\teasel], presets: ~presets[\teasel]);
)
