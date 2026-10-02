// spatialisers.scd
// Processors that spread a 4-channel proxy over 8 outputs by band, channel, grain or bin instead of panning a point.

( // outputs, source, shared tap
s.options.numOutputBusChannels = 8;

~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;

~spsrc = ~gen.(\sedge);

Ndef(\spin, { ~spsrc.ar(4) });

~spatialisers = [\spbands, \sprotate, \spbreathe, \spgrains, \spspectral];
// stopped proxies keep computing, so switching is instant
~spOnly = { |key|
	~spatialisers.do { |k| if(k != key) { Ndef(k).stop } };
	Ndef(key);
};
)

( // sp-bands: log-spaced bandpass lattice creeping around the ring
Ndef(\spbands, { |amp = 1.6, base = 60, octaves = 8, bw = 0.28, creep = 0.01, tilt = 0.5|
	var src = Ndef(\spin).ar(4);
	var phase = LFSaw.ar(creep).range(0, 1);
	8.collect { |i|
		var step = (i + phase) * (octaves / 8);
		var freq = (base * (2 ** step)).clip(20, 18000);
		var pick = src.wrapAt(i) * (1 - tilt) + (Mix(src) * 0.25 * tilt);
		BBandPass.ar(pick, freq, bw) * amp
	}
}).stop;
~spOnly.(\spbands);
)


( // sp-rotate: per-channel azimuth rates, decorrelated
Ndef(\sprotate, { |amp = 0.5, rate = 0.05, width = 2.5, spread = 1, decorr = 0.011|
	var src = Ndef(\spin).ar(4);
	var rates = [1, -0.63, 0.41, -0.29] * rate;
	Mix(src.collect { |ch, i|
		var pos = LFSaw.ar(rates[i], i * 0.5).range(-1, 1) * spread;
		var w = width * LFNoise1.ar(0.05 + (i * 0.03)).range(0.7, 1.6);
		PanAz.ar(8, DelayC.ar(ch, 0.05, decorr * (i + 1)), pos, 1, w)
	}) * amp
}).play;
~spOnly.(\sprotate);
)


( // sp-breathe: eight incommensurate gain LFOs, no panning
Ndef(\spbreathe, { |amp = 1.2, rate = 0.05, depth = 0.85, skew = 1|
	var src = Ndef(\spin).ar(4);
	var periods = [1, 1.37, 1.79, 2.31, 2.87, 3.41, 4.13, 4.79] * rate;
	var gains = 8.collect { |i|
		SinOsc.ar(periods[i] * skew, i * 0.7).range(1 - depth, 1)
	};
	var norm = (Mix(gains) / 8).max(0.05);
	8.collect { |i| src.wrapAt(i) * (gains[i] / norm) * amp }
}).play;
~spOnly.(\spbreathe);
)


( // sp-grains: grains latched to random azimuths
Ndef(\spgrains, { |amp = 0.8, density = 28, dur = 0.09, jitter = 1, focus = 0|
	var src = Ndef(\spin).ar(4);
	Mix(4.collect { |i|
		var trig = Dust.ar(density * (1 + (i * 0.31)));
		var env = EnvGen.ar(Env.sine(dur * LFNoise1.ar(0.3).range(0.5, 2)), trig);
		var pos = Latch.ar(WhiteNoise.ar(jitter), trig) + (focus * (i / 2 - 0.75));
		PanAz.ar(8, src.wrapAt(i) * env, pos.clip(-1, 1), 1, 1.5)
	}) * amp
}).play;
~spOnly.(\spgrains);
)


( // sp-spectral: eight random bin masks from one FFT
Ndef(\spspectral, { |amp = 2.2, keep = 0.35, shuffle = 0.4, restir = 0.2|
	var in = Mix(Ndef(\spin).ar(4)) * 0.5;
	var stir = Impulse.kr(restir);
	8.collect { |i|
		var chain = FFT(LocalBuf(1024), in);
		chain = PV_RandComb(chain, keep, stir);
		chain = PV_BinScramble(chain, shuffle, 0.1, stir);
		IFFT(chain) * amp
	}
}).play;
~spOnly.(\spspectral);
)


/* try

// fold to stereo; stop the eight-channel monitor first
Ndef(\spbands).stop;
Ndef(\spfold, { Splay.ar(Ndef(\spbands).ar(8)) }).play;
Ndef(\spfold).stop;

Ndef(\spbands).set(\creep, 0.3, \bw, 0.05);
Ndef(\spbands).set(\octaves, 3, \base, 400);
Ndef(\sprotate).set(\rate, 0.9, \width, 1);
Ndef(\sprotate).set(\rate, 0.004, \width, 6);
Ndef(\spbreathe).set(\rate, 0.4, \depth, 1);
Ndef(\spgrains).set(\density, 200, \dur, 0.01);
Ndef(\spgrains).set(\focus, 1);
Ndef(\spspectral).set(\keep, 0.08, \restir, 2);

~free.(\sedge); ~spsrc = ~gen.(\nettle); Ndef(\spin).rebuild;
~spsrc = Ndef(\granulation); Ndef(\spin).rebuild;

~spatialisers.do { |k| Ndef(k).clear }; Ndef(\spin).clear; ~free.();

*/
