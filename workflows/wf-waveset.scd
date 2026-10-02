// wf-waveset.scd
// Six waveset operations reading a live ring buffer at different distances behind the write head.

( // library and source
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;
~srcKey = \thistle;
~src = ~gen.(~srcKey);
~wring = ~wring ?? { Buffer.alloc(s, s.sampleRate * 3) };
)


( // ring buffer and write head
Ndef(\wwrite, {
	var sig = Mix(~src.ar) * 0.5;
	var pos = Phasor.ar(0, BufRateScale.kr(~wring), 0, BufFrames.kr(~wring));
	BufWr.ar(sig, ~wring, pos);
	pos / BufFrames.kr(~wring)
});
)


( // six waveset readers
Ndef(\waveset, { |amp = 0.35, rate = 1, lag = 0.25, chaos = 1, seekHz = 18,
	spread = 0.9, drift = 1|

	var n = 6;
	var head = Mix(Ndef(\wwrite).ar);       // .ar hands back an array, always
	var buf = ~wring;
	var trig = Impulse.ar(seekHz * [1, 1.37, 0.61, 2.13, 0.83, 1.71]);
	var voices;

	// Latoocarfian spans about -1.5 to 1.5
	var branch = n.collect { |i|
		LatoocarfianL.ar(chaos * 3 * (2 ** (i / 3))).linlin(-1.5, 1.5, 0, 1).clip(0, 1)
	};

	var seek = n.collect { |i|
		(head - (lag * ((i + 1) / n) * branch[i].linlin(0, 1, 0.3, 2))).wrap(0, 1)
	};
	var r = n.collect { |i|
		rate * (branch[i] * drift).linexp(0, 1, 0.25, 4) * ((i % 2) * 2 - 1).neg
	};

	voices = [
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


( // seek rate follows source level
Ndef(\wsense, {
	Amplitude.kr(Mix(~src.ar), 0.02, 0.25).linexp(0.001, 0.3, 3, 60).lag(0.3)
});
Ndef(\waveset).map(\seekHz, Ndef(\wsense));
)


( // feedback onto the source
Ndef(\wreturn, {
	Amplitude.kr(Mix(Ndef(\waveset).ar), 0.08, 0.6).linlin(0, 0.5, 1.0, 0.15).lag(2)
});
~src.map(\amp, Ndef(\wreturn));
)


/* try

Ndef(\waveset).set(\rate, 0.25, \lag, 0.9);
Ndef(\waveset).set(\chaos, 6, \drift, 2);
Ndef(\waveset).set(\seekHz, 200);
Ndef(\waveset).unmap(\seekHz); Ndef(\waveset).set(\seekHz, 4);

~src.unmap(\amp); ~src.set(\amp, 0.7);

~wring.free; ~wring = Buffer.alloc(s, s.sampleRate * 10); Ndef(\wwrite).rebuild;

Ndef(\waveset).stop; Ndef(\wwrite).clear; ~free.();

*/
