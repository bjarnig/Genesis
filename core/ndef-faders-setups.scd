// ndef-faders-setups.scd
// A fader-GUI setup for every process in sketches/material-combined-v4.scd.
// Each block opens a window for one Ndef/NF and stores the handle in ~faders,
// so you can drive it from code, e.g.  ~faders[\gorse].randomize(\beta)
//
// Run the first block once (loads ~ndefFaders and the material library), then
// whichever setups you want. Each block asks the library for its process with
// ~gen, so opening a window instantiates that one and nothing else; ~free.(\key)
// puts it back to sleep.
//
// The ranges live in fader-specs.scd as ~specs[\gorse]; edit them there.

( // load the GUI function and the material library (run once)
"/Users/bjarni/Works/Pieces/Genesis/core/ndef-faders.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/material-library.scd".load;
"/Users/bjarni/Works/Pieces/Genesis/core/fader-specs.scd".load;   // ~specs, the ranges
~faders = ~faders ? ();
)


( // fern
~faders = ~faders ? ();
~faders[\fern] = ~ndefFaders.(~gen.(\fern), ~specs[\fern]);
)


( // moss
~faders = ~faders ? ();
~faders[\moss] = ~ndefFaders.(~gen.(\moss), ~specs[\moss]);
)


( // sedge
~faders = ~faders ? ();
~faders[\sedge] = ~ndefFaders.(~gen.(\sedge), ~specs[\sedge]);
)


( // nettle
~faders = ~faders ? ();
~faders[\nettle] = ~ndefFaders.(~gen.(\nettle), ~specs[\nettle]);
)


( // bramble
~faders = ~faders ? ();
~faders[\bramble] = ~ndefFaders.(~gen.(\bramble), ~specs[\bramble]);
)


( // clover  (Ndef)
~faders = ~faders ? ();
~faders[\clover] = ~ndefFaders.(~gen.(\clover), ~specs[\clover]);
)


( // thistle  (Ndef)
~faders = ~faders ? ();
~faders[\thistle] = ~ndefFaders.(~gen.(\thistle), ~specs[\thistle]);
)


( // yarrow  (Ndef)
~faders = ~faders ? ();
~faders[\yarrow] = ~ndefFaders.(~gen.(\yarrow), ~specs[\yarrow]);
)


( // gorse
~faders = ~faders ? ();
~faders[\gorse] = ~ndefFaders.(~gen.(\gorse), ~specs[\gorse]);
)


( // teasel
~faders = ~faders ? ();
~faders[\teasel] = ~ndefFaders.(~gen.(\teasel), ~specs[\teasel]);
)
