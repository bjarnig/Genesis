// wf-feedback.scd
// Four delay nodes with saturation, cross-coupled by a random matrix; total RMS regulates the global feedback.

( // library and source
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;
~srcKey = \nettle;
~src = ~gen.(~srcKey);
)


( // excitation, gated into bursts
Ndef(\fbin, { |drive = 0.35, opening = 0.3|   // not \gate: NodeProxy reserves that name
	var sig = Mix(~src.ar) * 0.5;
	var open = LFNoise1.kr(opening).range(-0.4, 1).max(0).sqrt;
	sig * open * drive
});
)


( // network; the matrix is redrawn on each rebuild
Ndef(\fbnet, { |amp = 0.3, fbBase = 0.85, spread = 1, tone = 1200, chaos = 0.5|

	var n = 4;
	var matrix = n.collect { Array.rand(n, -1.2, 1.2) };
	var in = Mix(Ndef(\fbin).ar);           // .ar hands back an array, always
	var fb = LocalIn.ar(n) + in;
	var rms, level, soft, loud, tooLoud, global, nodes;

	rms = RMS.ar(Mix(fb) / n);
	soft = rms < 0.08;
	loud = rms > 0.25;
	tooLoud = rms > 0.6;
	global = fbBase
		+ (LFNoise1.ar(0.1).range(0, 0.12) * soft)
		- (LFNoise1.ar(0.2).range(0, 0.35) * loud)
		- (2 * tooLoud);
	global = global.clip(0, 1.02);

	nodes = fb.collect { |sig, i|
		var mixed = (fb * matrix[i]).sum.tanh;
		var follow = Amplitude.kr(fb.wrapAt(i - 1), 0.01, 0.15);
		var time = (0.004 * (i + 1) + (follow * 0.25 * chaos)).clip(0.0005, 0.6);
		var node = RLPF.ar(mixed, (tone * (i + 1).sqrt).clip(60, 16000), 0.4);
		DelayC.ar(node, 0.6, Lag.kr(time, 0.2))   // time is kr, so the lag is too
	};

	LocalOut.ar(nodes * global);

	Limiter.ar(Splay.ar(nodes, spread) * amp, 0.95)
}).play;
)


( // source level wanders
Ndef(\fbdrift, { LFNoise1.kr(0.02).range(0.1, 0.9) });
~src.map(\amp, Ndef(\fbdrift));
)


( // outer loop: network level scales the excitation
Ndef(\fbsense, {

	Amplitude.kr(Mix(Ndef(\fbnet).ar), 0.1, 1.0).linlin(0, 0.5, 0.5, 0.02).lag(1.5)
});
Ndef(\fbin).map(\drive, Ndef(\fbsense));
)


/* try

Ndef(\fbnet).rebuild;
Ndef(\fbnet).set(\fbBase, 0.98);
Ndef(\fbnet).set(\fbBase, 0.4);
Ndef(\fbnet).set(\chaos, 3, \tone, 400);
Ndef(\fbin).set(\opening, 0.02);

Ndef(\fbin).unmap(\drive); Ndef(\fbin).set(\drive, 0.35);
Ndef(\fbin).set(\drive, 0);

Ndef(\fbnet).stop; Ndef(\fbin).clear; ~free.();

*/
