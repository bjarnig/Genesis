// wf-granulation.scd
// Source recorded into a ring buffer and read by six grain readers sharing one Lorenz attractor; grain level feeds back onto the source amp.

( // library and source
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;
~srcKey = \gorse;
~src = ~gen.(~srcKey);
~ring = ~ring ?? { Buffer.alloc(s, s.sampleRate * 4) };
)


( // write head: records the source, outputs position 0 to 1
Ndef(\gwrite, {
	var sig = Mix(~src.ar) * 0.5;
	var pos = Phasor.ar(0, BufRateScale.kr(~ring), 0, BufFrames.kr(~ring));
	BufWr.ar(sig, ~ring, pos);
	pos / BufFrames.kr(~ring)
});
)


( // grain readers
Ndef(\granulation, { |amp = 0.4, density = 30, grainDur = 0.08, lag = 0.3,
	chaos = 1, spread = 0.9, pitch = 0|

	var n = 6;
	var head = Mix(Ndef(\gwrite).ar);       // .ar hands back an array, always
	var sense = Amplitude.kr(Mix(~src.ar), 0.02, 0.3);
	var grains;

	// Lorenz x spans about -0.4 to 0.8
	var branch = n.collect { |i|
		LorenzL.ar(chaos * 4 * (2 ** (i / 2.5))).linlin(-0.4, 0.8, 0, 1).clip(0, 1)
	};

	grains = n.collect { |i|
		var c = Lag.ar(branch[i], 0.05);
		var behind = lag * ((i + 1) / n) * c.linlin(0, 1, 0.4, 2.2);
		var pos = (head - behind).wrap(0, 1);
		var rate = (pitch + ((c - 0.5) * 2 * ((i % 2) * 2 - 1))).midiratio;
		var dens = density * (1 + (sense * 6)) * (i + 1).sqrt;
		var dur = grainDur * c.linexp(0, 1, 0.25, 4);
		GrainBuf.ar(2, Dust.ar(dens), dur, ~ring, rate, pos, 2,
			((i / (n - 1) * 2) - 1) * spread)
	};

	Mix(grains) * amp
}).play;
)


( // source level wanders
~src.set(\amp, 0.7);
Ndef(\gdrift, { LFNoise1.kr(0.03).range(0.2, 1.2) });
~src.map(\amp, Ndef(\gdrift));
)


( // feedback: grain level lowers the source amp
Ndef(\gsense, {
	Amplitude.kr(Mix(Ndef(\granulation).ar), 0.05, 0.5).linlin(0, 0.4, 1.0, 0.08).lag(1.5)
});
~src.map(\amp, Ndef(\gsense));
)


/* try

Ndef(\granulation).set(\density, 120, \grainDur, 0.02);
Ndef(\granulation).set(\density, 6, \grainDur, 0.5);
Ndef(\granulation).set(\lag, 0.9, \chaos, 0.15);
Ndef(\granulation).set(\chaos, 8);
Ndef(\granulation).set(\pitch, -12);

~src.unmap(\amp); ~src.set(\amp, 0.7);

~free.(~srcKey); ~srcKey = \sedge; ~src = ~gen.(~srcKey); Ndef(\gwrite).rebuild;

Ndef(\granulation).stop; Ndef(\gwrite).clear; ~free.();

*/
