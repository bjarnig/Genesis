// wf-sediment.scd
// Workflow 2: the same shape as wf-granulation, but the readers are the Sediment
// granulators, which take the live signal instead of a buffer.
//
//   ~src -> Ndef(\sedin)  mono tap of the material
//        -> Creep         a drunken read head wandering through recent time
//        -> Scree         stutters the wander, replaying slices out of order
//        -> Talus         granular feedback delay, the tail of the whole chain
//        +  Loess         a parallel dust layer, very short grains
//        +  Sediment      a parallel cloud, drifting on its own
//
// The stages are not independent: Creep's step size is driven by how loud Talus
// has become, so the wander speeds up as the delay fills, and Scree's slicing is
// stepped by a chaotic counter. Talus feedback is held in check by its own RMS.
//
// Moraine is deliberately absent. On this build it returned digital silence in
// every mode and gate setting tried, so the chain routes around it.
//
// Run in order. Sediment UGens: github.com/bjarnig/Sediment

( // 1. library and source (run once)
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;
~srcKey = \sedge;                          // any key in ~material.keys
~src = ~gen.(~srcKey);
)


( // 2. one mono tap, so every granulator hears the same thing
Ndef(\sedin, { Mix(~src.ar) * 0.5 });
)


( // 3. the chain. Each stage listens to the one after it, which is what keeps
  //    the thing from settling: the tail reaches back to the head.
Ndef(\sediment, { |amp = 3, wander = 0.3, grain = 0.12, slice = 0.4,
	delay = 0.25, feedback = 0.35, dust = 0.25, cloud = 0.3, chaos = 1|

	var in = Mix(Ndef(\sedin).ar);          // .ar hands back an array, always
	var tail = Amplitude.kr(Mix(Ndef(\sedreturn).ar), 0.05, 0.4);   // how full the tail is
	var creep, scree, talus, loess, cloudy, rms, fb;

	// a chaotic counter the slicing rides on, stepped slowly
	var walk = Logistic.kr(chaos * 0.7, 3.7);

	// the wander accelerates as the tail fills up
	creep = Creep.ar(in, 2, ambitus: wander.linlin(0, 1, 0.05, 1.8),
		step: wander * tail.linlin(0, 0.4, 0.5, 6), grainDur: grain,
		overlap: 0.6, pitch: (walk - 0.5) * 12, spread: 0.7);

	// stutter, with the slice length and the jump distance walking chaotically
	scree = Scree.ar(Mix(creep) * 0.7, 2,
		sliceDur: slice * walk.linexp(0, 1, 0.2, 3),
		jump: walk, repeats: walk.linlin(0, 1, 1, 6).round, scatter: 0.4);

	// granular feedback delay, self-limited: as it gets loud it feeds back less
	rms = RMS.ar(Mix(scree));
	fb = (feedback - (rms.linlin(0.1, 0.5, 0.0, 0.4))).clip(0, 0.85);
	talus = Talus.ar(Mix(scree) * 0.7, 2, delay: delay, density: 24,
		dur: grain * 2, pitch: 0, feedback: fb, spread: 0.8);

	// a dust layer straight off the source, unrelated to the chain above it
	loess = Loess.ar(in, density: 300 * dust.linexp(0, 1, 0.2, 3), grainDur: 0.005,
		timeSpread: 0.7, pitch: 0, pitchSpread: 0.8) * dust;

	// and a cloud that drifts on its own, position pushed by the same walk
	cloudy = Sediment.ar(in, nil, position: walk, scatter: 0.6, bloom: 0.4,
		drift: 0.5, feedback: 0.2, dryWet: 1) * cloud;

	// each granulator gives back roughly 6 dB less than it was handed, so the
	// default amp here is makeup for three stages of that, not a loud setting
	Limiter.ar((talus + loess + cloudy + (scree * 0.3)) * amp, 0.95)
}).play;
)


( // 4. the tail the chain listens to. Splitting it out keeps the cycle legal:
  //    this proxy reads the output, the output reads this one a block later.
Ndef(\sedreturn, { Ndef(\sediment).ar });
)


( // 5. close the loop onto the material itself. The fuller the tail, the less
  //    the source pushes in, so the texture breathes instead of choking.
Ndef(\sedsense, {
	Amplitude.kr(Mix(Ndef(\sedreturn).ar), 0.1, 0.8).linlin(0, 0.6, 0.9, 0.1).lag(2)
});
~src.map(\amp, Ndef(\sedsense));
)


/*  playing with it

Ndef(\sediment).set(\wander, 0.9, \chaos, 3);      // fast walk, restless slicing
Ndef(\sediment).set(\delay, 0.02, \feedback, 0.8); // short loop, near self-oscillation
Ndef(\sediment).set(\grain, 0.5, \slice, 1.5);     // long grains, long slices
Ndef(\sediment).set(\dust, 1.2, \cloud, 0);        // the smear takes over
Ndef(\sediment).set(\cloud, 1, \dust, 0);          // the cloud takes over

~src.unmap(\amp); ~src.set(\amp, 0.7);

Ndef(\sediment).stop; Ndef(\sedin).clear; Ndef(\sedreturn).clear; ~free.();

*/
