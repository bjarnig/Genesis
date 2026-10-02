// 02-rc.wavesets.scd
// The fourteen CDP-style waveset operations on the mono material.
// Run 00-rc.load.scd first.
//
// Every one of these wants a mono buffer, so they all read ~gmsmono. A waveset
// is the stretch between two zero crossings; cyclecnt groups several of them
// into one unit, and rate transposes the unit without moving the read pointer.
// Seeking is quantised to waveset boundaries, so scrubbing is clickless.
//
// Waveset UGens: github.com/bjarnig/WavesetUGens

( // 1. source
~w = ~rcch.(\clover01, 1);
~w2 = ~rcch.(\yarrow04, 3);
)


///////////////////////// One operation each /////////////////////////

( // 2. omit, three of every four wavesets silenced, timing kept
{ WavesetOmit.ar(~w2, 2, MouseX.kr(3, 10).round, mul: 0.5) ! 2 }.play
)

( // 3. delete, the same proportion removed rather than silenced: it shortens
{ WavesetDelete.ar(~w2, 1, 2, mul: 0.5) ! 2 }.play
)

( // 4. repeat, each waveset played eight times: the material stalls
{ WavesetRepeat.ar(~w2, 8, mul: 0.4) ! 2 }.play
)

( // 5. divide, the waveset squeezed into n copies of itself, an octave ladder
{ WavesetDivide.ar(~w2, MouseX.kr(1, 12).round, mul: 0.4) ! 2 }.play
)

( // 6. multiply, the opposite: the cycle stretched over n waveset slots
{ WavesetMultiply.ar(~w, 4, mul: 0.4) ! 2 }.play
)

( // 7. reverse, groups of six played backwards while the pointer runs forwards
{ WavesetReverse.ar(~w, 6, mul: 0.5) ! 2 }.play
)

( // 8. average, four wavesets replaced by their mean shape
{ WavesetAverage.ar(~w, 8, mul: 0.5) ! 2 }.play
)

( // 9. replace, the loudest waveset of each group standing in for the group
{ WavesetReplace.ar(~w, 6, mul: 0.5) ! 2 }.play
)

( // 10. telescope, groups collapsed into a single waveset: a time compression
{ WavesetTelescope.ar(~w2, 8, 1, mul: 0.5) ! 2 }.play
)

( // 11. interpolate, morphing between one waveset and the next
{ WavesetInterpolate.ar(~w2, 8, mul: 0.5) ! 2 }.play
)

( // 12. fractal, the waveset drawn again inside itself at a smaller scale
{ WavesetFractal.ar(~w, 6, 0.5, mul: 0.4) ! 2 }.play
)

( // 13. harmonic, harmonics of the waveset period added to it
{ WavesetHarmonic.ar(~w, [2, 3, 5], [0.5, 0.3, 0.2], mul: 0.4) ! 2 }.play
)

( // 14. pitch, each group transposed by a random amount inside an octave range
{ WavesetPitch.ar(~w, 0.6, 32, 0, mul: 0.4) ! 2 }.play
)

( // 15. shuffle, a window of four wavesets emitted in a pattern over itself
{ WavesetShuffle.ar(~w2, "abcd", "adcbba", mul: 0.5) ! 2 }.play
)

CmdPeriod.run


///////////////////////// Reading the buffer /////////////////////////

( // 16. scrub: the mouse is the read position, the seek lands on a boundary
{ WavesetOmit.ar(~w2, 3, 4, trig: Impulse.kr(30), seek: MouseX.kr(0, 1), mul: 0.5) ! 2 }.play
)

( // 17. the playhead comes back out, so it can drive something else
{
	var sig, pos;
	# sig, pos = WavesetShuffle.arWithPos(~w2, "abcd", "dcba");
	Pan2.ar(sig * 0.5, pos.linlin(0, 1, -1, 1))
}.play
)

( // 18. transposition per waveset, walked rather than set
{ WavesetRepeat.ar(~w2, 3, LFNoise1.kr(0.3).exprange(0.25, 4), mul: 0.4) ! 2 }.play
)

( // 19. seek driven by the material's own amplitude: loud passages jump more
Ndef(\rcwseek, {
	var src = PlayBuf.ar(1, ~w, loop: 1);
	var sense = Amplitude.kr(src, 0.02, 0.25);
	var trig = Impulse.ar(sense.linexp(0.001, 0.3, 2, 40));
	WavesetOmit.ar(~w, 1, [3,6], trig: trig, seek: TRand.ar(0, 1, trig), mul: 0.4) ! 2
}).play;
)

Ndef.clear


///////////////////////// Layers /////////////////////////

( // 20. the four channels of one take, one operation each, kept in their places
{
	var take = \yarrow06;
	var b = (1..4).collect { |ch| ~rcch.(take, ch) };
	var v = [
		WavesetOmit.ar(b[0], 1, 3),
		WavesetRepeat.ar(b[1], 4),
		WavesetReverse.ar(b[2], 6),
		WavesetDivide.ar(b[3], 3)
	];
	Splay.ar(v) * 0.3
}.play
)


( // 21. one buffer, six operations, each seeking to a different age of it.
  //     One attractor drives all six rates, so they pull on each other.
Ndef(\rcwaveset, { |amp = 0.3, rate = 1, chaos = 1, seekHz = 12, spread = 0.9|
	var n = 6;
	var buf = ~w;
	var trig = Impulse.ar(seekHz * [1, 1.37, 0.61, 2.13, 0.83, 1.71]);
	var branch = n.collect { |i|
		LatoocarfianL.ar(chaos * 3 * (2 ** (i / 3))).linlin(-1.5, 1.5, 0, 1).clip(0, 1)
	};
	var seek = n.collect { |i| branch[i] };
	var r = n.collect { |i| rate * branch[i].linexp(0, 1, 0.25, 4) };

	var voices = [
		WavesetOmit.ar(buf, 1, 3, r[0], trig: trig[0], seek: seek[0]),
		WavesetRepeat.ar(buf, branch[1].linlin(0, 1, 1, 8).round, r[1], trig: trig[1], seek: seek[1]),
		WavesetDivide.ar(buf, branch[2].linlin(0, 1, 2, 9).round, r[2], trig: trig[2], seek: seek[2]),
		WavesetFractal.ar(buf, 4, 0.5, r[3], trig: trig[3], seek: seek[3]),
		WavesetPitch.ar(buf, branch[4] * 0.8, 48, 0, r[4], trig: trig[4], seek: seek[4]),
		WavesetReverse.ar(buf, branch[5].linlin(0, 1, 1, 6).round, r[5], trig: trig[5], seek: seek[5])
	];

	Mix(voices.collect { |v, i| Pan2.ar(v, ((i / (n - 1) * 2) - 1) * spread) }) * amp
}).play;
)

Ndef(\rcwaveset).set(\chaos, 8, \seekHz, 40);
Ndef(\rcwaveset).set(\chaos, 0.2, \rate, 0.5);


( // 22. a take at a time through one operation, the whole family in sequence
var keys = ~rcfam.(\yarrow, ~gmsmono);

Tdef(\rcwalk, {
	keys.do { |k|
		var b = ~gmsmono[k];
		k.postln;
		Ndef(\rcone, { WavesetTelescope.ar(b, 6, 1, mul: 0.4) ! 2 }).play;
		(b.duration * 0.5).wait;
	};
	Ndef(\rcone).stop;
}).play;
)

CmdPeriod.run
