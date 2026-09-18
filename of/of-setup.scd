// of/of-setup.scd
// Wires the Genesis material into the OF library (~/Library/.../Extensions/OF):
// every process in material-library.scd is now built as an NF (OF's own Ndef
// subclass, see NF.sc), so ~gen.(\fern) already responds to .stack, .transform,
// .stackpd, .modulate etc. - no separate OF synthesis/waveform layer needed, our
// ten sonorities stand in for Antithesis's drol/leaf/opca/sofbas.
//
// Run this block once, then see of-weave.scd and of-drift.scd for pieces built
// on it. Each of those is block-by-block like the workflows, not a thing to load.
//
//   a = ~gen.(\fern).play;
//   a.stack([\bfold, \drift], o);            // replace the filter chain
//   a.transform( o.processing.fshift );       // append one more stage
//   ~stateFor.(a, \fern).choose.value;        // jump to one of fern's own presets

(
~here = ~here ? "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;   // ~material, ~gen - all ten are NF now
(~here ++ "core/fader-specs.scd").load;        // ~specs
(~here ++ "core/preset-morph.scd").load;       // ~loadPresets
~presets = ~loadPresets.(~here ++ "core/presets.scd");

o = OF(this);

// one zero-arg "jump to this preset" function per line in presets.scd for that
// key - the same shape as Antithesis's hand-written ~states/~grunt/~thicky
// arrays, but pulled from our own presets instead of typed out per piece.
~stateFor = { |proxy, key|
	(~presets[key] ? []).collect { |preset| { proxy.set(*preset.getPairs) } }
};

"OF wired to the Genesis material: o, ~stateFor.(proxy, key)".postln;
)
