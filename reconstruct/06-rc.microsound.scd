// 06-rc.microsound.scd
// The Sediment granulators on the material. Run 00-rc.load.scd first.
//
// Two kinds of UGen here. Clast and Silt read a buffer directly. Creep, Scree,
// Talus, Loess, Moraine and Sediment granulate a live signal, so they get a
// mono tap of a PlayBuf. Tuff synthesises formant grains and takes no source at
// all, so the material drives it rather than feeds it. All of them return
// stereo.
//
// maxAmbitus, maxLen and maxDelay are read at build time: changing them needs a
// rebuild, not a .set.
//
// Sediment UGens: github.com/bjarnig/Sediment

( // 1. source, and one tap every input-side granulator can share
~m = ~rcch.(\clover01, 1);
~m2 = ~rcch.(\yarrow04, 3);

Ndef(\rcin, { PlayBuf.ar(1, ~m, BufRateScale.kr(~m), loop: 1) * 0.7 });
)


///////////////////////// Reading the buffer /////////////////////////

( // 2. Clast: grains measured in wavecycles, so grain length follows the
  //    source's own period rather than a clock
Ndef(\rcclast, { Clast.ar(~m, 4, 60, 0.3, 0.02, 0, 0.5, 0.5) * 0.5 }).play;
)

( // 3. the same, scanning: cycles per grain under the mouse, pitch under the other
Ndef(\rcclast, {
	Clast.ar(~m, MouseX.kr(1, 24).round, 60, 0.3, 0.05, MouseY.kr(-12, 12), 0.6, 0.5)
}).play;
)

( // 4. Clast with the position walked slowly: a drift through the take
Ndef(\rcclast, {
	Clast.ar(~m, 6, 80, LFNoise2.kr(0.05).range(0, 1), 0.01,
		LFNoise1.kr(0.1).range(-7, 7), 0.7, 0.3) * 0.5
}).play;
)

( // 5. Silt: the grain cloud whose positions are drawn from a distribution.
  //    Seven of them in turn, the shape of the scatter changing each time.
Tdef(\rcsilt, {
	7.do { |d|
		("dist " ++ d).postln;
		Ndef(\rcsilt, {
			Silt.ar(~m, 25, 0.12, 0.4, 0.6, d, 0.5, 0, 0.5) * 0.5
		}).play;
		6.wait;
	};
	Ndef(\rcsilt).stop;
}).play;
)

( // 6. Silt with cauchy scatter: most grains near the pointer, a few nowhere near
Ndef(\rcsilt, {
	Silt.ar(~m, 30, 0.12, MouseX.kr(0, 1), MouseY.kr(0, 1), 1, 0.5, 0, 0.5) * 0.5
}).play;
)

( // 7. Silt as a slow cloud: sparse, long grains, reversed windows
Ndef(\rcsilt, { Silt.ar(~m2, 6, 0.9, LFNoise2.kr(0.03).range(0, 1), 0.2, 4, 0.5, -12, 1) * 0.5 }).play;
)

CmdPeriod.run


///////////////////////// Granulating the stream /////////////////////////

( // 8. Creep: a drunken read head wandering through recent time
Ndef(\rccreep, {
	Creep.ar(Mix(Ndef(\rcin).ar), 2, 1.2, 0.2, 0.12, 0.6, 0, 0, 0.7) * 0.5
}).play;
)

( // 9. the wander widening and slowing: ambitus out, step down
Ndef(\rccreep, {
	Creep.ar(Mix(Ndef(\rcin).ar), 2, Line.kr(0.05, 1.9, 40), Line.kr(0.6, 0.05, 40),
		0.18, 0.7, LFNoise0.kr(0.3).range(-5, 5), 0, 0.8) * 0.5
}).play;
)

( // 10. Scree: the stutterer, slice length and jump walking chaotically
Ndef(\rcscree, {
	var walk = Logistic.kr(0.7, 3.7);
	Scree.ar(Mix(Ndef(\rcin).ar), 2, walk.linexp(0, 1, 0.02, 0.4), walk,
		walk.linlin(0, 1, 1, 8).round, 0, 0.4) * 0.5
}).play;
)

( // 11. Talus: granular feedback delay, held in check by its own level
Ndef(\rctalus, {
	var in = Mix(Ndef(\rcin).ar);
	var rms = RMS.ar(in);
	var fb = (0.5 - rms.linlin(0.1, 0.5, 0, 0.4)).clip(0, 0.85);
	Talus.ar(in, 2, 0.25, 24, 0.2, 0, fb, 0.8) * 0.5
}).play;
)

( // 12. Loess: micro-dust, grains too short to hear one at a time
Ndef(\rcloess, {
	Loess.ar(Mix(Ndef(\rcin).ar), 400, 0.005, 0.7, 0, 0.8) * 4.5
}).play;
)

( // 13. the dust thinning out until the grains separate again
Ndef(\rcloess, {
	Loess.ar(Mix(Ndef(\rcin).ar), XLine.kr(600, 8, 30), 0.006, 0.7, 0, 0.9) * 0.6
}).play;
)

( // 14. Sediment, granular mode: position and scatter under the mouse
Ndef(\rcsediment, {
	var in = Mix(Ndef(\rcin).ar);
	Sediment.ar(in, in, 0, MouseX.kr(0, 1), MouseY.kr(0.1, 0.9), 0.4, 0.3, 0.2, 1, 0, 0) * 0.5
}).play;
)

( // 15. the three modes in turn: granular, stretch, looping delay
Tdef(\rcmodes, {
	[0, 1, 2].do { |mode|
		("mode " ++ mode).postln;
		Ndef(\rcsediment, {
			var in = Mix(Ndef(\rcin).ar);
			Sediment.ar(in, in, 0, 0.5, 0.5, 0.4, 0.4, 0.2, 1, 0, mode) * 0.5
		}).play;
		10.wait;
	};
}).play;
)

( // 16. freeze: the cloud stops taking new material and lives off what it has.
  //     The phase offset matters: freezing at time zero freezes an empty buffer.
Ndef(\rcsediment, {
	var in = Mix(Ndef(\rcin).ar);
	Sediment.ar(in, in, 0, 0.5, 0.7, 0.6, 0.5, 0.3, 1,
		ToggleFF.kr(Impulse.kr(0.08, 0.5)), 0) * 0.5
}).play;
)

( // 17. Moraine: grains found by amplitude troughs, then reordered.
  //     Four modes: 0 omit, 1 duplicate, 2 reorder, 3 timewarp.
  //     gate is a level threshold: above the material's own level it finds no
  //     grains and returns silence. On this material it stops at about 0.12.
Ndef(\rcmoraine, {
	Moraine.ar(Mix(Ndef(\rcin).ar), 4, 2, MouseY.kr(0.01, 0.1), 0.02, MouseX.kr(0, 1), 0) * 0.5
}).play;
)

( // 17b. the four modes in turn, at a gate the material clears
Tdef(\rcmoraine, {
	[0, 1, 2, 3].do { |mode|
		("mode " ++ mode).postln;
		Ndef(\rcmoraine, { Moraine.ar(Mix(Ndef(\rcin).ar), 4, mode, 0.05, 0.02, 0.5, 0) * 0.5 }).play;
		8.wait;
	};
}).play;
)

CmdPeriod.run


///////////////////////// Synthesis against the material /////////////////////////

( // 18. Tuff: formant grains, no source. Pitch and formant are independent.
Ndef(\rctuff, { Tuff.ar(100, 700, 0.003, 0.02, 0.05, 60, 0, 0.3) * 0.3 }).play;
)

( // 19. the material conducts it: its amplitude moves the formant, its
  //     pitch content moves the fundamental
Ndef(\rctuff, {
	var in = Mix(Ndef(\rcin).ar);
	var amp = Amplitude.kr(in, 0.02, 0.2);
	var freq, hasFreq;
	# freq, hasFreq = Pitch.kr(in);
	Tuff.ar(freq.clip(40, 400), amp.linexp(0.001, 0.3, 300, 3000), 0.003, 0.02, 0.05,
		amp.linlin(0.001, 0.3, 20, 200), 0, 0.4) * 0.3
}).play;
)

( // 20. three formants summed into a vowel, the material only setting its level
Ndef(\rctuff, {
	var in = Mix(Ndef(\rcin).ar);
	var amp = Amplitude.kr(in, 0.02, 0.2).linlin(0, 0.3, 0.05, 1);
	var f = [700, 1220, 2600], a = [1, 0.5, 0.25];
	Mix(f.collect { |hz, i|
		Tuff.ar(110, hz, 0.003, 0.02, 0.05, 60 + (i * 30), 0, 0.3) * a[i]
	}) * amp * 0.2
}).play;
)

CmdPeriod.run


///////////////////////// Chains and fields /////////////////////////

( // 21. a chain: wavecycle grains stuttered, then delayed granularly. Each
  //     stage hands on about 6 dB less than it was given.
Ndef(\rcchain, { |amp = 0.5|
	var clast = Clast.ar(~m, 5, 50, LFNoise2.kr(0.04).range(0, 1), 0.01, 0, 0.5, 0.5);
	var scree = Scree.ar(Mix(clast) * 0.5, 2, 0.12, 0.4, 3, 0, 0.4);
	var talus = Talus.ar(Mix(scree) * 0.5, 2, 0.3, 20, 0.25, 0, 0.4, 0.8);
	(clast * 0.3) + (scree * 0.4) + (talus * 0.5) * amp
}).play;
)

( // 22. the four channels of one take, one granulator each, kept in their places
Ndef(\rcfield, { |amp = 0.4|
	var take = \yarrow06;
	var b = (1..4).collect { |ch| ~rcch.(take, ch) };
	var v = [
		Clast.ar(b[0], 4, 50, 0.3, 0.02, 0, 0.4, 0.5),
		Silt.ar(b[1], 20, 0.15, 0.5, 0.4, 1, 0.5, 0, 0.5),
		Loess.ar(PlayBuf.ar(1, b[2], loop: 1), 300, 0.005, 0.6, 0, 0.7),
		Talus.ar(PlayBuf.ar(1, b[3], loop: 1), 2, 0.2, 18, 0.2, 0, 0.35, 0.6)
	];
	Mix(v.collect { |x, i| Pan2.ar(Mix(x), ((i / 1.5) - 1) * 0.9) }) * amp
}).play;
)

( // 23. take after take through the same granulator, the whole family in
  //     sequence, position drifting across each one
Tdef(\rcwalk, {
	var keys = ~rcfam.(\yarrow, ~gmsmono);
	keys.do { |k|
		var b = ~gmsmono[k];
		k.postln;
		Ndef(\rcone, { Clast.ar(b, 6, 70, Line.kr(0, 1, b.duration * 0.5), 0.01, 0, 0.6, 0.5) * 0.5 }).play;
		(b.duration * 0.5).wait;
	};
	Ndef(\rcone).stop;
}).play;
)

Tdef(\rcwalk).stop; CmdPeriod.run
