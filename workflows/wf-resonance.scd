// wf-resonance.scd
// Twelve coupled Ringz resonators on a lattice that follows the tracked pitch of the source.

( // library and source
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;
~srcKey = \moss;
~src = ~gen.(~srcKey);
)


( // excitation tap and pitch tracker
Ndef(\resin, { Mix(~src.ar) * 0.5 });

Ndef(\respitch, {
	// Mix, not .ar: Pitch would multichannel-expand over the proxy array
	var sig = Mix(Ndef(\resin).ar);
	var freq, hasFreq;
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.01, median: 7);
	Gate.kr(freq, hasFreq).clip(40, 2000).lag(3)
});
)


( // resonator bank
Ndef(\resonance, { |amp = 0.12, ring = 2, bw = 0.06, tune = 1, spread = 0.9,
	couple = 1, drift = 0.4, dry = 0.15|

	var n = 12;
	var in = Mix(Ndef(\resin).ar);
	var root = Mix(Ndef(\respitch).kr) * tune;   // a kr proxy, so read it at kr
	var ratios = n.collect { |i|
		(i + 1) * (1 + (LFNoise1.ar(0.02 + (i * 0.013)).range(drift.neg, drift) * 0.06))
	};
	var freqs = ratios.collect { |r| (root * r).clip(30, 17000) };
	var prev = LocalIn.ar(n);              // last block's band amplitudes
	var bands, amps;

	bands = n.collect { |i|
		var neighbour = prev.wrapAt(i - 1);
		var rt = (ring * (1 + (neighbour * couple * 6))).clip(0.02, 20);
		var exc = BPF.ar(in, freqs[i], bw * (i + 1).sqrt);
		Ringz.ar(exc, freqs[i], rt) * (i + 1).reciprocal.sqrt
	};

	amps = bands.collect { |b| Amplitude.ar(b, 0.01, 0.2) };
	LocalOut.ar(amps.clip(0, 1));

	Limiter.ar(
		(Splay.ar(bands, spread) * amp) + (in.dup * dry),
		0.95)
}).play;
)


( // feedback: resonance level lowers the source amp
Ndef(\ressense, {
	Amplitude.kr(Mix(Ndef(\resonance).ar), 0.05, 1.2).linlin(0, 0.6, 0.8, 0.05).lag(2)
});
~src.map(\amp, Ndef(\ressense));
)


( // slow transposition
Ndef(\restune, { LFNoise1.kr(0.015).exprange(0.5, 2) });
Ndef(\resonance).map(\tune, Ndef(\restune));
)


/* try

Ndef(\resonance).set(\ring, 12, \couple, 3);
Ndef(\resonance).set(\ring, 0.15, \bw, 0.3);
Ndef(\resonance).set(\drift, 2);
Ndef(\resonance).set(\couple, 0);
Ndef(\resonance).set(\dry, 0.6);

Ndef(\resonance).unmap(\tune); Ndef(\resonance).set(\tune, 1);
Ndef(\respitch).bus.getnSynchronous(1);

~src.unmap(\amp); ~src.set(\amp, 0.7);

Ndef(\resonance).stop; Ndef(\resin).clear; Ndef(\respitch).clear; ~free.();

*/
