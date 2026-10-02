// 04-rc.montage.scd
// Playback algorithms for going through the whole set. Run 00-rc.load.scd first.
//
// Every block below is one way of ordering the takes: straight through,
// backwards, family against family, two channels of one take against each
// other, a random walk, an accelerating repetition. The items are stereo
// (~gmscombined) unless the algorithm needs single channels, which come from
// ~gmsmono.
//
// start is normalised 0 to 1; dur is the length of the item, not of the file.

( // 1. the items
~fftbuf = Buffer.alloc(s, 512);

SynthDef(\rcitem, { |out = 0, buf = 0, rate = 1, start = 0, amp = 0.7, dur = 0.3|
	var env = EnvGen.ar(Env([0, amp, amp, 0], [dur * 0.01, dur * 0.89, dur * 0.1]), doneAction: 2);
	var sig = PlayBuf.ar(2, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, sig * env);
}).add;

SynthDef(\rcitem1, { |out = 0, buf = 0, rate = 1, start = 0, amp = 0.7, dur = 0.3, pan = 0|
	var env = EnvGen.ar(Env([0, amp, amp, 0], [dur * 0.01, dur * 0.89, dur * 0.1]), doneAction: 2);
	var sig = PlayBuf.ar(1, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, Pan2.ar(sig * env, pan));
}).add;

SynthDef(\rcitemam, { |out = 0, buf = 0, rate = 1, start = 0, amp = 0.8, dur = 0.3, am = 60|
	var env = EnvGen.ar(Env([0, amp, amp, 0], [dur * 0.01, dur * 0.89, dur * 0.1]), doneAction: 2);
	var sig = PlayBuf.ar(2, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, sig.amclip(SinOsc.ar(am)) * env);
}).add;

SynthDef(\rcitemfilter, { |out = 0, buf = 0, rate = 1, start = 0, amp = 0.7, dur = 0.3, hpf = 1000|
	var env = EnvGen.ar(Env([0, amp, amp, 0], [dur * 0.01, dur * 0.89, dur * 0.1]), doneAction: 2);
	var sig = PlayBuf.ar(2, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, RHPF.ar(sig, hpf) * env);
}).add;

SynthDef(\rcitemlisten, { |out = 0, buf = 0, rate = 1, start = 0, amp = 0.7, dur = 0.3, sens = 0.4|
	var env = EnvGen.ar(Env([0, amp, amp, 0], [dur * 0.01, dur * 0.89, dur * 0.1]), doneAction: 2);
	var sig = PlayBuf.ar(2, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	var onsets = Onsets.kr(FFT(~fftbuf, sig.sum), sens, \complex);
	var bleeps = HPF.ar(SinOscFB.ar(50, 0.3, EnvGen.kr(Env.perc(0.1, 0.1, 0.4), onsets)), 20);
	OffsetOut.ar(out, ((sig * 0.6) + (bleeps * 0.4)) * env);
}).add;

SynthDef(\rcnize, { |amp = 0.15, freq = 50, pan = 0|
	var env = EnvGen.kr(Env.perc(0.2, 3), doneAction: 2);
	OffsetOut.ar(0, Pan2.ar(LPF.ar(Gendy3.ar(freq: freq, durscale: 0.1), 8000) * env, pan, amp));
}).add;

SynthDef(\rccross, { |in = 0, out = 0, freq = 300, amp = 0.3|
	var sig = In.ar(in, 2);
	var thres = Lag.kr(Amplitude.kr(sig.sum), 0.1);
	var osc = Splay.ar(Pulse.ar(Array.series(10, freq, 5))) * thres;
	var verb = Mix.fill(10, { CombL.ar(osc, 0.05, rrand(0.02, 0.04), 10.rand) });
	Out.ar(out, (osc + (verb * 0.5)) * amp);
}).add;

~rcbus = Bus.audio(s, 2);
)


( // 2. the material as an ordered sequence
~seq = ~rctakes.();
~seq.size.postln;
)


///////////////////////// Straight lines /////////////////////////

( // 3. original: each take once, in order, at its own length
var seq = ~seq, wait = 1.0;

Tdef(\rcoriginal, {
	seq.do { |k, i|
		var b = ~gmscombined[k];
		("% / % : %".format(i + 1, seq.size, k)).postln;
		Synth(\rcitem, [\buf, b, \dur, b.duration]);
		(b.duration * wait).wait;
	};
}).play;
)


( // 4. reversed order, each take listening to itself: onsets ring a bleep
var seq = ~seq;

Tdef(\rcreversed, {
	seq.reverse.do { |k|
		var b = ~gmscombined[k];
		k.postln;
		Synth(\rcitemlisten, [\buf, b, \dur, b.duration]);
		b.duration.wait;
	};
}).play;
)


( // 5. heads only: the first two seconds of every take, no gaps
var seq = ~seq, dur = 2;

Tdef(\rcheads, {
	seq.do { |k|
		Synth(\rcitem, [\buf, ~gmscombined[k], \dur, dur]);
		dur.wait;
	};
}).play;
)


///////////////////////// Two at once /////////////////////////

( // 6. up and down: the sequence from both ends at once, hard left and right
var seq = ~seq, dur = 1, wait = 1.5;

Tdef(\rcupdown, {
	seq.size.do { |i|
		var a = ~rcch.(seq[seq.size - i - 1], 1);
		var b = ~rcch.(seq[i], 3);
		Synth(\rcitem1, [\buf, a, \dur, dur, \pan, -1]);
		Synth(\rcitem1, [\buf, b, \dur, dur, \pan, 1]);
		Synth(\rcnize, [\freq, 50]);
		wait.wait;
	};
}).play;
)


( // 7. family against family, one take each, alternating
var a = ~rcfam.(\yarrow), b = ~rcfam.(\gorse), dur = 1.5;

Tdef(\rcfamilies, {
	max(a.size, b.size).do { |i|
		Synth(\rcitem, [\buf, ~gmscombined[a.wrapAt(i)], \dur, dur, \amp, 0.5]);
		(dur * 0.5).wait;
		Synth(\rcitemfilter, [\buf, ~gmscombined[b.wrapAt(i)], \dur, dur, \amp, 0.5, \hpf, 2000]);
		(dur * 0.5).wait;
	};
}).play;
)


( // 8. the four channels of each take fanned out in time: a take becomes a
  //    chord that arrives one channel at a time
var seq = ~seq, dur = 3, spread = 0.25;

Tdef(\rcfan, {
	seq.do { |k|
		k.postln;
		(1..4).do { |ch|
			Synth(\rcitem1, [\buf, ~rcch.(k, ch), \dur, dur, \amp, 0.4,
				\pan, ((ch - 1) / 1.5) - 1]);
			spread.wait;
		};
		(dur - (spread * 4)).wait;
	};
}).play;
)


///////////////////////// Non-linear orders /////////////////////////

( // 9. random walk over the sequence: it stays near where it is
var seq = ~seq, dur = 1.2;
var walk = Pbrown(0, seq.size - 1, 3).asStream;

Tdef(\rcwalk, {
	120.do {
		var k = seq[walk.next.round];
		k.postln;
		Synth(\rcitem, [\buf, ~gmscombined[k], \dur, dur, \start, 0.6.rand]);
		dur.wait;
	};
}).play;
)


( // 10. accelerating repetition: each take repeated, the gap shrinking, then on
var seq = ~seq, reps = 12;

Tdef(\rcaccel, {
	seq.do { |k|
		var b = ~gmscombined[k];
		k.postln;
		reps.do { |r|
			Synth(\rcitem, [\buf, b, \dur, b.duration * 0.2, \start, r / reps * 0.5]);
			Synth(\rcitemfilter, [\buf, b, \dur, b.duration * 0.1, \amp, 0.5, \hpf, 2000]);
			(1.5 / (r + 1)).wait;
		};
	};
}).play;
)


( // 11. ring modulation over the whole set, the carrier stepping down
var seq = ~seq, wait = 0.7;
var ams = [60, 45, 30, 22, 15, 11];

Tdef(\rcring, {
	seq.do { |k, i|
		var b = ~gmscombined[k];
		Synth(\rcitemam, [\buf, b, \out, 4.rand, \dur, b.duration * wait * 1.2, \am, ams.wrapAt(i)]);
		(b.duration * wait).wait;
	};
}).play;
)


( // 12. a pulse follower listening to the montage on a private bus
var seq = ~seq, dur = 0.2, wait = 1.1;

Tdef(\rcfollow, {
	Synth(\rccross, [\in, ~rcbus, \out, 0, \freq, 40]);
	seq.reverse.do { |k|
		var b = ~gmscombined[k];
		Synth(\rcitem, [\out, ~rcbus, \buf, b, \dur, dur]);
		Synth(\rcitem, [\out, 0, \buf, b, \dur, dur]);
		wait.wait;
	};
}).play;
)


( // 13. granular montage: the buffer index walks the sequence, one grain each
{
	var bufs = ~seq.collect { |k| ~rcch.(k, 1).bufnum };
	var trig = Impulse.kr(8);
	var index = Demand.kr(trig, 0, Dseq(bufs, inf));
	GrainBuf.ar(2, trig, 0.3, index, 1, TRand.kr(0, 1, trig), 2, TRand.kr(-1, 1, trig)) * 0.5
}.play
)


Tdef.all.do(_.stop);
CmdPeriod.run
