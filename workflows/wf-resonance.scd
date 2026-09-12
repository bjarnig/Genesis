// wf-resonance.scd
// Workflow 5: giving the material pitch. A bank of resonators and bandpass
// filters is excited by the source, and the bank tunes itself to what it hears.
//
//   ~src -> Ndef(\resin)  mono tap plus a pitch tracker
//        -> Ndef(\resonance)  twelve Ringz resonators on a drifting lattice,
//                             each fed through its own bandpass, cross-coupled
//
// The couplings are what make it a network rather than a chord: each resonator's
// ring time is written by its neighbour's amplitude, so energy in one band keeps
// the next one open, and a band that goes quiet lets its neighbour dry out.
// The lattice itself drifts around the tracked pitch of the material.
//
// Run in order.

( // 1. library and source (run once)
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;
~srcKey = \moss;                           // any key in ~material.keys
~src = ~gen.(~srcKey);
)


( // 2. the excitation, and what the material's pitch is doing. hasFreq gates the
  //    tracker so noise does not drag the lattice around.
Ndef(\resin, { Mix(~src.ar) * 0.5 });

Ndef(\respitch, {
	// Mix, not .ar on its own: a proxy hands back an array, and Pitch would
	// multichannel-expand over it and lose its second output
	var sig = Mix(Ndef(\resin).ar);
	var freq, hasFreq;
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.01, median: 7);
	Gate.kr(freq, hasFreq).clip(40, 2000).lag(3)
});
)


( // 3. the bank. Twelve resonators on a lattice that drifts around the tracked
  //    pitch, each one's ring time held open by the band below it.
Ndef(\resonance, { |amp = 0.12, ring = 2, bw = 0.06, tune = 1, spread = 0.9,
	couple = 1, drift = 0.4, dry = 0.15|

	var n = 12;
	var in = Mix(Ndef(\resin).ar);
	var root = Mix(Ndef(\respitch).kr) * tune;   // a kr proxy, so read it at kr
	// a lattice that is not quite harmonic, drifting slowly apart and back
	var ratios = n.collect { |i|
		(i + 1) * (1 + (LFNoise1.ar(0.02 + (i * 0.013)).range(drift.neg, drift) * 0.06))
	};
	var freqs = ratios.collect { |r| (root * r).clip(30, 17000) };
	var prev = LocalIn.ar(n);              // last block's band amplitudes
	var bands, amps;

	bands = n.collect { |i|
		// the band below writes this one's ring time: energy propagates upward
		var neighbour = prev.wrapAt(i - 1);
		var rt = (ring * (1 + (neighbour * couple * 6))).clip(0.02, 20);
		var exc = BPF.ar(in, freqs[i], bw * (i + 1).sqrt);
		Ringz.ar(exc, freqs[i], rt) * (i + 1).reciprocal.sqrt
	};

	// what each band is doing, fed back for the next block
	amps = bands.collect { |b| Amplitude.ar(b, 0.01, 0.2) };
	LocalOut.ar(amps.clip(0, 1));

	Limiter.ar(
		(Splay.ar(bands, spread) * amp) + (in.dup * dry),
		0.95)
}).play;
)


( // 4. excitation follows resonance: when the bank rings, the source backs off,
  //    so the material punctuates rather than masks it
Ndef(\ressense, {
	Amplitude.kr(Mix(Ndef(\resonance).ar), 0.05, 1.2).linlin(0, 0.6, 0.8, 0.05).lag(2)
});
~src.map(\amp, Ndef(\ressense));
)


( // 5. and the lattice slowly transposes on its own
Ndef(\restune, { LFNoise1.kr(0.015).exprange(0.5, 2) });
Ndef(\resonance).map(\tune, Ndef(\restune));
)


/*  playing with it

Ndef(\resonance).set(\ring, 12, \couple, 3);       // long, self-sustaining, near-feedback
Ndef(\resonance).set(\ring, 0.15, \bw, 0.3);       // dry, percussive, the material shows through
Ndef(\resonance).set(\drift, 2);                   // the lattice pulls apart
Ndef(\resonance).set(\couple, 0);                  // twelve independent resonators, a chord
Ndef(\resonance).set(\dry, 0.6);

Ndef(\resonance).unmap(\tune); Ndef(\resonance).set(\tune, 1);
Ndef(\respitch).bus.getnSynchronous(1);           // what pitch it thinks it hears

~src.unmap(\amp); ~src.set(\amp, 0.7);

Ndef(\resonance).stop; Ndef(\resin).clear; Ndef(\respitch).clear; ~free.();

*/
