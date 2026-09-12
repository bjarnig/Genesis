// wf-granulation.scd
// Workflow 1: material -> ring buffer -> a family of grain readers.
//
//   ~src (any process from core/material-library.scd)
//     -> Ndef(\gwrite)      writes it into a ring buffer, outputs the write head
//     -> Ndef(\granulation) six readers chasing that head at different distances
//
// The readers are siblings rather than strangers: they share one Lorenz
// attractor, read at six related speeds, so they drift together and separate
// slowly. Grain density listens to how busy the material is, and block 5 closes
// the loop by feeding the grain level back onto the source's own amp.
//
// Run the blocks in order. Nothing is heard until block 3.

( // 1. library and source (run once)
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;
~srcKey = \gorse;                          // any key in ~material.keys
~src = ~gen.(~srcKey);                     // instantiated, silent, into its own bus
~ring = ~ring ?? { Buffer.alloc(s, s.sampleRate * 4) };
)


( // 2. the write head. The material is recorded into the ring continuously and
  //    this proxy hands out the head position, 0 to 1, for the readers to chase.
Ndef(\gwrite, {
	var sig = Mix(~src.ar) * 0.5;
	var pos = Phasor.ar(0, BufRateScale.kr(~ring), 0, BufFrames.kr(~ring));
	BufWr.ar(sig, ~ring, pos);
	pos / BufFrames.kr(~ring)
});
)


( // 3. the readers. Each sits a different distance behind the head, and that
  //    distance breathes with its own branch of the attractor.
Ndef(\granulation, { |amp = 0.4, density = 30, grainDur = 0.08, lag = 0.3,
	chaos = 1, spread = 0.9, pitch = 0|

	var n = 6;
	var head = Mix(Ndef(\gwrite).ar);       // .ar hands back an array, always
	var sense = Amplitude.kr(Mix(~src.ar), 0.02, 0.3);   // how busy the material is
	var grains;

	// one attractor read at six related speeds: coupled, never quite in step.
	// Lorenz x runs about -0.4 to 0.8, so map that span rather than assume unity.
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


( // 4. the material is not a fixed source: let it wander while it is being read
~src.set(\amp, 0.7);
Ndef(\gdrift, { LFNoise1.kr(0.03).range(0.2, 1.2) });
~src.map(\amp, Ndef(\gdrift));
)


( // 5. close the loop. The louder the grains, the less the source pushes into
  //    the ring, so the texture regulates itself instead of piling up.
Ndef(\gsense, {
	Amplitude.kr(Mix(Ndef(\granulation).ar), 0.05, 0.5).linlin(0, 0.4, 1.0, 0.08).lag(1.5)
});
~src.map(\amp, Ndef(\gsense));
)


/*  playing with it

Ndef(\granulation).set(\density, 120, \grainDur, 0.02);   // dust
Ndef(\granulation).set(\density, 6, \grainDur, 0.5);      // slabs
Ndef(\granulation).set(\lag, 0.9, \chaos, 0.15);          // long memory, slow drift
Ndef(\granulation).set(\chaos, 8);                        // scattered, sensitive
Ndef(\granulation).set(\pitch, -12);

~src.unmap(\amp); ~src.set(\amp, 0.7);   // open the loop again

// swap the material underneath without stopping the grains
~free.(~srcKey); ~srcKey = \sedge; ~src = ~gen.(~srcKey); Ndef(\gwrite).rebuild;

Ndef(\granulation).stop; Ndef(\gwrite).clear; ~free.();

*/
