// of/of-drift.scd
// moss (grain/fold texture) drifting under clover (DC-free ramp/steps texture)
// through OF's processing library. Run of-setup.scd first.
//
// moss:   lfnFreq, mod, from, to, freqFrom, freqTo, jitter, ampStep, duty, hpf,
//         sdm, grainGain, knum, factorsMult, amp
// clover: ser, sdm, step, brownLo, brownHi, mf, stepsGain, stepsStep, stepsLen, amp

( // hear the pair plain
a = ~gen.(\moss).play;
b = ~gen.(\clover).play;
)

(
~mossStates = ~stateFor.(a, \moss);
~cloverStates = ~stateFor.(b, \clover);
("moss states: " ++ ~mossStates.size ++ "   clover states: " ++ ~cloverStates.size).postln;
)

// a scripted pass: settle on a preset, sit, then fold a processing stage on top
// mid-stream - the same move as Antithesis's A.Grunt Section 2 (.transform
// applied partway through a running TF, not at the start)
(
TF(\driftIntro, {
	0.5.wait; "0".postln;
	~mossStates.first.value; ~cloverStates.first.value;
	10.wait; "1".postln;
	~mossStates.wrapAt(2).value; ~cloverStates.wrapAt(1).value;
	10.wait; "2 - folding in a filter".postln;
	a.transform( o.processing.foldorm ); b.transform( o.processing.wloss );
	~mossStates.wrapAt(4).value; ~cloverStates.wrapAt(3).value;
	12.wait; "3".postln;
	~mossStates.wrapAt(6).value; ~cloverStates.wrapAt(5).value;
	10.wait; "4".postln;
}).play;
)

// then wander: each jumps to one of its own presets at its own pace
(
Tdef(\drift, {
	inf.do {
		~mossStates.choose.value;
		[5, 7, 9].choose.wait;
	}
}).play;

Tdef(\driftB, {
	inf.do {
		~cloverStates.choose.value;
		[8, 11, 16].choose.wait;
	}
}).play;
)

Tdef(\drift).stop; Tdef(\driftB).stop;

( // back to silence
~free.(\moss); ~free.(\clover);
)
