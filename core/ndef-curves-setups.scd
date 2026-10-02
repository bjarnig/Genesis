// ndef-curves-setups.scd: one trajectory-editor window per process, handle in ~curves[\key].
// Run the first block once, then any setup; e.g. ~curves[\sedge].run(60); .halt; .rewind; .recallSlot(3)

( // load the GUI function, the material library, and the presets (run once)
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/ndef-curves.scd").load;
(~here ++ "core/material-library.scd").load;
(~here ++ "core/fader-specs.scd").load;
(~here ++ "core/preset-morph.scd").load;
~presets = ~loadPresets.(~here ++ "core/presets.scd");
~curves = ~curves ? ();
)


( // fern
~curves = ~curves ? ();
~curves[\fern] = ~ndefCurves.(~gen.(\fern), ~specs[\fern], presets: ~presets[\fern], dur: 20);
)


( // moss
~curves = ~curves ? ();
~curves[\moss] = ~ndefCurves.(~gen.(\moss), ~specs[\moss], presets: ~presets[\moss], dur: 15);
)


( // sedge
~curves = ~curves ? ();
~curves[\sedge] = ~ndefCurves.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge], dur: 40);
)


( // nettle
~curves = ~curves ? ();
~curves[\nettle] = ~ndefCurves.(~gen.(\nettle), ~specs[\nettle], presets: ~presets[\nettle], dur: 20);
)


( // bramble
~curves = ~curves ? ();
~curves[\bramble] = ~ndefCurves.(~gen.(\bramble), ~specs[\bramble], presets: ~presets[\bramble], dur: 15);
)


( // clover
~curves = ~curves ? ();
~curves[\clover] = ~ndefCurves.(~gen.(\clover), ~specs[\clover], presets: ~presets[\clover], dur: 25);
)


( // thistle
~curves = ~curves ? ();
~curves[\thistle] = ~ndefCurves.(~gen.(\thistle), ~specs[\thistle], presets: ~presets[\thistle], dur: 30);
)


( // yarrow
~curves = ~curves ? ();
~curves[\yarrow] = ~ndefCurves.(~gen.(\yarrow), ~specs[\yarrow], presets: ~presets[\yarrow], dur: 40);
)


( // gorse
~curves = ~curves ? ();
~curves[\gorse] = ~ndefCurves.(~gen.(\gorse), ~specs[\gorse], presets: ~presets[\gorse], dur: 20);
)


( // teasel
~curves = ~curves ? ();
~curves[\teasel] = ~ndefCurves.(~gen.(\teasel), ~specs[\teasel], presets: ~presets[\teasel], dur: 30);
)
