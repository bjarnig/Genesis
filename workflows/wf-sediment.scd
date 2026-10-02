// wf-sediment.scd
// Creep, Scree and Talus in series plus parallel Loess and Sediment layers; Talus level feeds back into Creep.

( // library and source
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;
~srcKey = \sedge;
~src = ~gen.(~srcKey);
)


( // mono tap
Ndef(\sedin, { Mix(~src.ar) * 0.5 });
)


( // chain
Ndef(\sediment, { |amp = 3, wander = 0.3, grain = 0.12, slice = 0.4,
	delay = 0.25, feedback = 0.35, dust = 0.25, cloud = 0.3, chaos = 1|

	var in = Mix(Ndef(\sedin).ar);          // .ar hands back an array, always
	var tail = Amplitude.kr(Mix(Ndef(\sedreturn).ar), 0.05, 0.4);
	var creep, scree, talus, loess, cloudy, rms, fb;

	var walk = Logistic.kr(chaos * 0.7, 3.7);

	creep = Creep.ar(in, 2, ambitus: wander.linlin(0, 1, 0.05, 1.8),
		step: wander * tail.linlin(0, 0.4, 0.5, 6), grainDur: grain,
		overlap: 0.6, pitch: (walk - 0.5) * 12, spread: 0.7);

	scree = Scree.ar(Mix(creep) * 0.7, 2,
		sliceDur: slice * walk.linexp(0, 1, 0.2, 3),
		jump: walk, repeats: walk.linlin(0, 1, 1, 6).round, scatter: 0.4);

	rms = RMS.ar(Mix(scree));
	fb = (feedback - (rms.linlin(0.1, 0.5, 0.0, 0.4))).clip(0, 0.85);
	talus = Talus.ar(Mix(scree) * 0.7, 2, delay: delay, density: 24,
		dur: grain * 2, pitch: 0, feedback: fb, spread: 0.8);

	loess = Loess.ar(in, density: 300 * dust.linexp(0, 1, 0.2, 3), grainDur: 0.005,
		timeSpread: 0.7, pitch: 0, pitchSpread: 0.8) * dust;

	cloudy = Sediment.ar(in, nil, position: walk, scatter: 0.6, bloom: 0.4,
		drift: 0.5, feedback: 0.2, dryWet: 1) * cloud;

	// each granulator returns about 6 dB less, so the default amp is makeup
	Limiter.ar((talus + loess + cloudy + (scree * 0.3)) * amp, 0.95)
}).play;
)


( // tail proxy; a separate proxy keeps the feedback cycle legal
Ndef(\sedreturn, { Ndef(\sediment).ar });
)


( // feedback: tail level lowers the source amp
Ndef(\sedsense, {
	Amplitude.kr(Mix(Ndef(\sedreturn).ar), 0.1, 0.8).linlin(0, 0.6, 0.9, 0.1).lag(2)
});
~src.map(\amp, Ndef(\sedsense));
)


/* try

Ndef(\sediment).set(\wander, 0.9, \chaos, 3);
Ndef(\sediment).set(\delay, 0.02, \feedback, 0.8);
Ndef(\sediment).set(\grain, 0.5, \slice, 1.5);
Ndef(\sediment).set(\dust, 1.2, \cloud, 0);
Ndef(\sediment).set(\cloud, 1, \dust, 0);

~src.unmap(\amp); ~src.set(\amp, 0.7);

Ndef(\sediment).stop; Ndef(\sedin).clear; Ndef(\sedreturn).clear; ~free.();

*/
