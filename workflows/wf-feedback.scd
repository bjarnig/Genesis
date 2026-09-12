// wf-feedback.scd
// Workflow 4: a cybernetic configuration. Four nodes, each a delay with its own
// saturation, cross-connected by a random matrix. The material excites the
// network rather than passing through it.
//
//   ~src -> Ndef(\fbnet)  n nodes, each delayed, saturated, band-limited
//                         and mixed back into every other node
//
// Two loops of control, not one. Inside, each node's delay time is written by an
// envelope follower on the node before it, so the network retunes itself as it
// rings. Outside, the total RMS decides the global feedback: quiet lets it grow,
// loud pulls it back, too loud kills it. That is what keeps a network this open
// from either dying or exploding.
//
// Run in order.

( // 1. library and source (run once)
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;
~srcKey = \nettle;                         // any key in ~material.keys
~src = ~gen.(~srcKey);
)


( // 2. the excitation: a mono tap, gated so the network is pushed in bursts
  //    rather than held open. Silence is where feedback becomes audible.
Ndef(\fbin, { |drive = 0.35, opening = 0.3|   // not \gate: NodeProxy reserves that name
	var sig = Mix(~src.ar) * 0.5;
	var open = LFNoise1.kr(opening).range(-0.4, 1).max(0).sqrt;   // long closures
	sig * open * drive
});
)


( // 3. the network. The matrix is drawn once per build, so rebuilding the proxy
  //    deals a new set of couplings while everything keeps running.
Ndef(\fbnet, { |amp = 0.3, fbBase = 0.85, spread = 1, tone = 1200, chaos = 0.5|

	var n = 4;
	var matrix = n.collect { Array.rand(n, -1.2, 1.2) };
	var in = Mix(Ndef(\fbin).ar);           // .ar hands back an array, always
	var fb = LocalIn.ar(n) + in;
	var rms, level, soft, loud, tooLoud, global, nodes;

	// self-regulation: the network's own level decides how much comes back
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
		// each node hears its neighbours through the matrix, then saturates
		var mixed = (fb * matrix[i]).sum.tanh;
		// and is delayed by an amount the previous node's envelope is writing:
		// loud neighbour, longer delay, so the ring detunes as it fills
		var follow = Amplitude.kr(fb.wrapAt(i - 1), 0.01, 0.15);
		var time = (0.004 * (i + 1) + (follow * 0.25 * chaos)).clip(0.0005, 0.6);
		var node = RLPF.ar(mixed, (tone * (i + 1).sqrt).clip(60, 16000), 0.4);
		DelayC.ar(node, 0.6, Lag.kr(time, 0.2))   // time is kr, so the lag is too
	};

	LocalOut.ar(nodes * global);

	Limiter.ar(Splay.ar(nodes, spread) * amp, 0.95)
}).play;
)


( // 4. let the material wander while the network holds its own state
Ndef(\fbdrift, { LFNoise1.kr(0.02).range(0.1, 0.9) });
~src.map(\amp, Ndef(\fbdrift));
)


( // 5. the outer loop: what the network is doing decides how hard it is pushed.
  //    Ringing loudly closes the gate, so the network is left alone to decay.
Ndef(\fbsense, {

	Amplitude.kr(Mix(Ndef(\fbnet).ar), 0.1, 1.0).linlin(0, 0.5, 0.5, 0.02).lag(1.5)
});
Ndef(\fbin).map(\drive, Ndef(\fbsense));
)


/*  playing with it

Ndef(\fbnet).rebuild;                              // deal a new coupling matrix
Ndef(\fbnet).set(\fbBase, 0.98);                   // right at the edge
Ndef(\fbnet).set(\fbBase, 0.4);                    // short memory, more like reverb
Ndef(\fbnet).set(\chaos, 3, \tone, 400);           // long detuning swings, dark
Ndef(\fbin).set(\opening, 0.02);                   // near-permanent silence between pushes

Ndef(\fbin).unmap(\drive); Ndef(\fbin).set(\drive, 0.35);
Ndef(\fbin).set(\drive, 0);                        // cut the source, listen to the network alone

Ndef(\fbnet).stop; Ndef(\fbin).clear; ~free.();

*/
