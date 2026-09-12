// spatialisers.scd
// A set of processors that read a 4-channel proxy and put it into 8 channels.
// The source can be any process from core/material-library.scd or the output of any
// workflow: all of them are 4-channel, and all of them are proxies.
//
// These do not pan a mono point around a ring. Each one takes the four channels
// apart by some other property, frequency, time, grain, or bin, and lets the
// eight outputs disagree about the material. That is what makes a texture sit in
// a room rather than travel across it.
//
//   sp-bands      eight bandpass filters, one per speaker, lattice creeping
//   sp-rotate     the four channels rotating at four rates, decorrelated
//   sp-breathe    amplitude only, eight incommensurate LFOs, no panning law
//   sp-grains     the live signal chopped and each grain latched to an azimuth
//   sp-spectral   one FFT, eight different random bin masks
//
// Run block 1, then any one of the others. ~spOnly silences the rest, since two
// eight-channel proxies playing at once just sum on the hardware outs. They keep
// computing while silent, so switching is instant; clear them to get the CPU back.
// With fewer than eight hardware outs you hear only the first two: the playground
// at the foot of the file has a fold for that.

( // 1. eight outputs, a source, and one tap the processors share (run once)
s.options.numOutputBusChannels = 8;
// s.reboot;   // uncomment if the server was already up with fewer outs

~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;

~spsrc = ~gen.(\sedge);                    // any 4-channel proxy: a process ...
// ~spsrc = Ndef(\granulation);            // ... or a workflow output

Ndef(\spin, { ~spsrc.ar(4) });

~spatialisers = [\spbands, \sprotate, \spbreathe, \spgrains, \spspectral];
~spOnly = { |key|
	~spatialisers.do { |k| if(k != key) { Ndef(k).stop } };
	Ndef(key);
};
)


( // 2. sp-bands. Eight bandpasses on a log lattice, one per speaker, and the
  //    whole lattice creeps around the ring: a frequency migrates from speaker
  //    to speaker without anything being panned. Each band is fed by a rotating
  //    pick of the four source channels, so the material's own spread is kept.
Ndef(\spbands, { |amp = 1.6, base = 60, octaves = 8, bw = 0.28, creep = 0.01, tilt = 0.5|
	var src = Ndef(\spin).ar(4);
	var phase = LFSaw.ar(creep).range(0, 1);          // the lattice, creeping
	8.collect { |i|
		var step = (i + phase) * (octaves / 8);
		var freq = (base * (2 ** step)).clip(20, 18000);
		var pick = src.wrapAt(i) * (1 - tilt) + (Mix(src) * 0.25 * tilt);
		BBandPass.ar(pick, freq, bw) * amp
	}
}).stop;
~spOnly.(\spbands);
)


( // 3. sp-rotate. Each source channel gets its own azimuth and its own rate, so
  //    the four rotate through each other rather than as a block. Small delays
  //    keep them from phasing into the middle when they cross.
Ndef(\sprotate, { |amp = 0.5, rate = 0.05, width = 2.5, spread = 1, decorr = 0.011|
	var src = Ndef(\spin).ar(4);
	var rates = [1, -0.63, 0.41, -0.29] * rate;       // coprime-ish, never in step
	Mix(src.collect { |ch, i|
		var pos = LFSaw.ar(rates[i], i * 0.5).range(-1, 1) * spread;
		var w = width * LFNoise1.ar(0.05 + (i * 0.03)).range(0.7, 1.6);
		// a few ms of delay per channel, enough to decorrelate, too short to hear
		PanAz.ar(8, DelayC.ar(ch, 0.05, decorr * (i + 1)), pos, 1, w)
	}) * amp
}).play;
~spOnly.(\sprotate);
)


( // 4. sp-breathe. No panning at all: eight slow gains on incommensurate
  //    periods. The image never moves, it opens and closes in different places,
  //    and the sum is held roughly constant so the level does not pump.
Ndef(\spbreathe, { |amp = 1.2, rate = 0.05, depth = 0.85, skew = 1|
	var src = Ndef(\spin).ar(4);
	var periods = [1, 1.37, 1.79, 2.31, 2.87, 3.41, 4.13, 4.79] * rate;
	var gains = 8.collect { |i|
		SinOsc.ar(periods[i] * skew, i * 0.7).range(1 - depth, 1)
	};
	var norm = (Mix(gains) / 8).max(0.05);            // hold the total steady
	8.collect { |i| src.wrapAt(i) * (gains[i] / norm) * amp }
}).play;
~spOnly.(\spbreathe);
)


( // 5. sp-grains. Four streams chop the live signal with short windows, and
  //    each grain latches a new azimuth as it starts, so the material lands in
  //    a different place every few milliseconds without being moved.
Ndef(\spgrains, { |amp = 0.8, density = 28, dur = 0.09, jitter = 1, focus = 0|
	var src = Ndef(\spin).ar(4);
	Mix(4.collect { |i|
		var trig = Dust.ar(density * (1 + (i * 0.31)));
		var env = EnvGen.ar(Env.sine(dur * LFNoise1.ar(0.3).range(0.5, 2)), trig);
		// a new random azimuth held for the life of the grain
		var pos = Latch.ar(WhiteNoise.ar(jitter), trig) + (focus * (i / 2 - 0.75));
		PanAz.ar(8, src.wrapAt(i) * env, pos.clip(-1, 1), 1, 1.5)
	}) * amp
}).play;
~spOnly.(\spgrains);
)


( // 6. sp-spectral. One analysis, eight different random bin masks: each speaker
  //    gets a different sparse handful of the spectrum. Nothing is panned and
  //    nothing is filtered in the usual sense, the sound simply comes apart.
Ndef(\spspectral, { |amp = 2.2, keep = 0.35, shuffle = 0.4, restir = 0.2|
	var in = Mix(Ndef(\spin).ar(4)) * 0.5;
	var stir = Impulse.kr(restir);                    // redraw the masks slowly
	8.collect { |i|
		var chain = FFT(LocalBuf(1024), in);
		chain = PV_RandComb(chain, keep, stir);       // keep a sparse set of bins
		chain = PV_BinScramble(chain, shuffle, 0.1, stir);
		IFFT(chain) * amp
	}
}).play;
~spOnly.(\spspectral);
)


/*  playing with them

// fold eight down to two on a stereo setup. Stop the eight-channel monitor
// first, or speakers 1 and 2 carry the fold and the first two channels at once.
Ndef(\spbands).stop;
Ndef(\spfold, { Splay.ar(Ndef(\spbands).ar(8)) }).play;   // name the one you are on
Ndef(\spfold).stop;

Ndef(\spbands).set(\creep, 0.3, \bw, 0.05);        // narrow, fast migration
Ndef(\spbands).set(\octaves, 3, \base, 400);       // one register smeared around
Ndef(\sprotate).set(\rate, 0.9, \width, 1);        // fast, tight, points flying
Ndef(\sprotate).set(\rate, 0.004, \width, 6);      // almost still, very wide
Ndef(\spbreathe).set(\rate, 0.4, \depth, 1);       // pulsing, holes opening
Ndef(\spgrains).set(\density, 200, \dur, 0.01);    // a cloud with no location
Ndef(\spgrains).set(\focus, 1);                    // streams pull back into sectors
Ndef(\spspectral).set(\keep, 0.08, \restir, 2);    // sparse and restless

// change what is being spatialised, without stopping the spatialiser
~free.(\sedge); ~spsrc = ~gen.(\nettle); Ndef(\spin).rebuild;
~spsrc = Ndef(\granulation); Ndef(\spin).rebuild;

// stop silences them but leaves them running; clear frees them outright
~spatialisers.do { |k| Ndef(k).clear }; Ndef(\spin).clear; ~free.();

*/
