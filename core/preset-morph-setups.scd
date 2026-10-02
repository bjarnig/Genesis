// preset-morph-setups.scd
// One morph setup per process, handle stored in ~morphs. Run the first block once.

( // load (run once)
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/preset-morph.scd").load;
(~here ++ "core/material-library.scd").load;
(~here ++ "core/fader-specs.scd").load;
~presets = ~loadPresets.(~here ++ "core/presets.scd");
~morphs = ~morphs ? ();
)


( // fern
~morphs = ~morphs ? ();
~morphs[\fern] = ~presetMorph.(~gen.(\fern), ~presets[\fern], ~specs[\fern], nil, 15, \smooth);
)


( // moss
~morphs = ~morphs ? ();
~morphs[\moss] = ~presetMorph.(~gen.(\moss), ~presets[\moss], ~specs[\moss], nil, 10, \zigzag);
)


( // sedge
~morphs = ~morphs ? ();
~morphs[\sedge] = ~presetMorph.(~gen.(\sedge), ~presets[\sedge], ~specs[\sedge], nil, 25, \decel);
)


( // nettle
~morphs = ~morphs ? ();
~morphs[\nettle] = ~presetMorph.(~gen.(\nettle), ~presets[\nettle], ~specs[\nettle], nil, 12, \linear);
)


( // bramble
~morphs = ~morphs ? ();
~morphs[\bramble] = ~presetMorph.(~gen.(\bramble), ~presets[\bramble], ~specs[\bramble], nil, 10, \scatter);
)


( // clover
~morphs = ~morphs ? ();
~morphs[\clover] = ~presetMorph.(~gen.(\clover), ~presets[\clover], ~specs[\clover], nil, 15, \smooth);
)


( // thistle
~morphs = ~morphs ? ();
~morphs[\thistle] = ~presetMorph.(~gen.(\thistle), ~presets[\thistle], ~specs[\thistle], nil, 18, \accel);
)


( // yarrow
~morphs = ~morphs ? ();
~morphs[\yarrow] = ~presetMorph.(~gen.(\yarrow), ~presets[\yarrow], ~specs[\yarrow], nil, 25, \decel);
)


( // gorse
~morphs = ~morphs ? ();
~morphs[\gorse] = ~presetMorph.(~gen.(\gorse), ~presets[\gorse], ~specs[\gorse], nil, 12, \linear);
)


( // teasel
~morphs = ~morphs ? ();
~morphs[\teasel] = ~presetMorph.(~gen.(\teasel), ~presets[\teasel], ~specs[\teasel], nil, 20, \smooth);
)
