// ndef-faders-setups.scd: one fader window per process, handle in ~faders[\key].
// Run the first block once, then any setup; e.g. ~faders[\gorse].randomize(\beta)

( // load the GUI function, the material library, and the presets (run once)
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/ndef-faders.scd").load;
(~here ++ "core/material-library.scd").load;
(~here ++ "core/fader-specs.scd").load;
(~here ++ "core/preset-morph.scd").load;
~faders = ~faders ? ();
~presets = ~loadPresets.(~here ++ "core/presets.scd");
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
