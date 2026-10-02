
( // 1. source and windows

~g = ~rcch.(\clover01, 1);
~g2 = ~rcch.(\yarrow04, 3);

~wrect = Buffer.sendCollection(s, Signal.rectWindow(1024), 1);
~whann = Buffer.sendCollection(s, Signal.hanningWindow(1024), 1);
~wexpo = Buffer.sendCollection(s, Env([1, 0.001], [1], \exp).discretize(1024), 1);
~wrexpo = Buffer.sendCollection(s, Env([0.001, 1], [1], \exp).discretize(1024), 1);

)

( // 6. frozen: one point read over and over
{ GrainBuf.ar(2, Impulse.kr(20), 0.1, ~g2, 1, MouseX.kr(0, 1)) * 0.4 }.play
)


( // 12. the buffer index itself becomes a parameter: one grain per take,
  //     stepping through a whole family
{
	var bufs = ~rcfam.(\yarrow, ~gmsmono).collect { |k| ~gmsmono[k].bufnum };
	var trig = Impulse.kr(24);
	var index = Demand.kr(trig, 0, Drand(bufs, inf));
	GrainBuf.ar(2, trig, 0.12, index, 1, TRand.kr(0, 1, trig), 2, TRand.kr(-1, 1, trig)) * 0.4
}.play
)

CmdPeriod.run


///////////////////////// Grain per synth /////////////////////////

( // 13. one grain, one synth: the shapes the routines below schedule
SynthDef(\rcgrain, { |buf = 0, rate = 1, start = 0, amp = 0.5, dur = 0.3, pan = 0, out = 0|
	var env = EnvGen.ar(Env([0, amp, 0], [dur * 0.5, dur * 0.5], \sine), doneAction: 2);
	var sig = PlayBuf.ar(1, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, Pan2.ar(sig * env, pan));
}).add;

SynthDef(\rcgliss, { |buf = 0, start = 0, amp = 0.5, dur = 0.3, pan = 0, from = 0.5, to = 4, out = 0|
	var env = EnvGen.ar(Env([0, amp, 0], [dur * 0.5, dur * 0.5], \sine), doneAction: 2);
	var sig = PlayBuf.ar(1, buf, Line.ar(from, to, dur) * BufRateScale.ir(buf), 1,
		start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, Pan2.ar(sig * env, pan));
}).add;

SynthDef(\rcfold, { |buf = 0, rate = 1, start = 0, amp = 0.5, dur = 0.3, pan = 0, flo = 0, fhi = 1, out = 0|
	var env = EnvGen.ar(Env([0, amp, 0], [dur * 0.5, dur * 0.5], \sine), doneAction: 2);
	var sig = PlayBuf.ar(1, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, Pan2.ar(Fold.ar(sig, flo, fhi) * env, pan));
}).add;

SynthDef(\rcbp, { |buf = 0, rate = 1, start = 0, amp = 0.5, dur = 0.3, pan = 0, bpf = 100, bw = 1, out = 0|
	var env = EnvGen.ar(Env([0, amp, 0], [dur * 0.5, dur * 0.5], \sine), doneAction: 2);
	var sig = PlayBuf.ar(1, buf, rate * BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 0);
	OffsetOut.ar(out, Pan2.ar(BBandPass.ar(sig, bpf, bw) * env, pan));
}).add;
)

~g2.play

( // 16. glisson: every grain is a small sweep, the sweeps widening as it goes
var dur = 0.001, overlap = 2.0, buf = ~g2;

Tdef(\rcglisson, {
	var total = buf.duration;
	var times = ((total / dur) * overlap).asInteger;

	times.do { |i|
		var next = dur / overlap;
		s.makeBundle(0.1, { Synth(\rcgliss, [\buf, buf, \dur, dur,
			\start, (i * next) / total,
			\from, i.linlin(0, times, 1.0, 2.0),
			\to, i.linlin(0, times, 2.0, 10.0)]) });
		next.wait;
	};
}).play;
)


( // 17. glisson layers, each layer a slower sweep over the same material
var dur = 0.008, overlap = 2.0, buf = ~g2, layers = 5;

Tdef(\rclayers, {
	layers.do { |n|
		var total = buf.duration;
		var times = ((total / dur) * overlap).asInteger;
		n = n + 1;

		Routine({
			times.do { |i|
				var next = dur / overlap;
				s.makeBundle(0.1, { Synth(\rcgliss, [\buf, buf, \dur, dur,
					\amp, 0.4 / layers,
					\start, (i * next) / total,
					\out, 4.rand,
					\from, Env([0.1 * n, 1, 1], [times / 2, times / 2] * n).at(i),
					\to, Env([2 * n, 4, 1], [times / 2, times / 2] * n).at(i)]) });
				next.wait;
			};
		}).play;
	};
}).play;
)


( // 18. a bandpass that climbs while the grains scatter: per-grain processing
var dur = 0.02, overlap = 3.0, buf = ~g2;

Tdef(\rcsweep, {
	var times = ((buf.duration / dur) * overlap).asInteger;

	times.do { |i|
		s.makeBundle(0.1, { Synth(\rcbp, [\buf, buf, \dur, dur, \start, 1.0.rand, \out, 4.rand,
			\bpf, i.linexp(0, times, 100, 8000), \bw, 5, \pan, 1.0.rand2]) });
		(dur / overlap).wait;
	};
}).play;
)


///////////////////////// Linkage and trains /////////////////////////



( // 20. pulsar train on the material: the duty cycle is the formant, the
  //     trigger rate is the fundamental
Ndef(\rcpulsar, { |fund = 30, form = 200, amp = 0.7|
	GrainBuf.ar(2, Impulse.ar(fund), form.reciprocal, ~g2, 1,
		LFNoise1.kr(0.2).range(0, 1), 2, 0, -1, mul: amp)
}).play;
)

Ndef(\rcpulsar).set(\fund, 12, \form, 900);
Ndef(\rcpulsar).set(\fund, 80, \form, 150);


( // 21. a trainlet cloud triggered by the material rather than by a clock
Ndef(\rctrainlet, { |amp = 0.3|
	var src = PlayBuf.ar(1, ~g2, loop: 1);
	var sense = Amplitude.kr(src, 0.02, 0.2);
	var trig = Dust.ar(sense.linexp(0.001, 0.3, 4, 120));
	var env = EnvGen.ar(Env.perc(0.002, 0.04), trig);
	Pan2.ar(Blip.ar(sense.linexp(0.001, 0.3, 30, 400), 200) * env, TRand.ar(-1, 1, trig), amp)
}).play;
)

CmdPeriod.run
