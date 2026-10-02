// of-setup.scd
// Wires the material library into OF: every ~gen process is an NF; ~stateFor.(proxy, key) returns preset-jump functions.

(
~here = ~here ? (thisProcess.nowExecutingPath.dirname +/+ "../../");
(~here ++ "core/material-library.scd").load;
(~here ++ "core/fader-specs.scd").load;
(~here ++ "core/preset-morph.scd").load;
~presets = ~loadPresets.(~here ++ "core/presets.scd");

o = OF(this);

// each preset becomes a zero-arg function that sets the proxy
~stateFor = { |proxy, key|
	(~presets[key] ? []).collect { |preset| { proxy.set(*preset.getPairs) } }
};

"OF wired to the Genesis material: o, ~stateFor.(proxy, key)".postln;
)
