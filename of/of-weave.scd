// of/of-weave.scd
// fern (broadband, harmonic-ish) woven against sedge (a slow bandstop/FitzHugh-
// Nagumo texture) through OF's processing library. Run of-setup.scd first.
//
// fern:  lfnFreq, repeats, freqMult, freqMult2, knumFrom, knumTo, ampStep,
//        stiffness, ampStepB, stiffnessB, harmScale, detuneHi, detuneLo,
//        templateType, ampDistParam, seqMode, factorsMult, amp
// sedge: sdm, ffrom, fto, noiseRate, bsRate, bsLo, bsHi, frequencyB, surface,
//        lop, hip, hpf, lopVol, hipVol, amp

( // hear the pair plain
a = ~gen.(\fern).play;
b = ~gen.(\sedge).play;
)

// try a filter chain on each - .stack replaces it, .transform appends one more.
// full name list: verb decimator fold chopper fshift foldorm ampdrift bfold
// minsaw drift dualdist wloss vesica gravch amclip clip cubmod modsaw rmsfold
// bbstop bcomb bprand bpspread dfmf diffuse dustlay excess fbdelay feedfold
// filtfold ghole lfddel lfdnamp mostchanged pulsecross pvfreeze pvsmear
// centfilt xloss
a.stack([\bfold, \drift], o);
b.stack([\fshift], o);

a.transform( o.processing.dualdist );
b.transform( o.processing.gravch );

// each one's own presets, as zero-arg "jump to state N" functions
(
~fernStates = ~stateFor.(a, \fern);
~sedgeStates = ~stateFor.(b, \sedge);
("fern states: " ++ ~fernStates.size ++ "   sedge states: " ++ ~sedgeStates.size).postln;
)

// a scripted pass through a handful of states, timed by hand
(
TF(\weaveIntro, {
	0.5.wait; "0".postln;
	~fernStates.first.value; ~sedgeStates.first.value;
	8.wait; "1".postln;
	~fernStates.wrapAt(1).value; ~sedgeStates.wrapAt(2).value;
	8.wait; "2".postln;
	~fernStates.wrapAt(3).value; ~sedgeStates.wrapAt(1).value;
	8.wait; "3".postln;
	~fernStates.wrapAt(5).value; ~sedgeStates.wrapAt(4).value;
	8.wait; "4".postln;
}).play;
)

// then let it wander: both proxies jump to a random one of their own presets
// at an interval that itself wanders, indefinitely, until Tdef(\weave).stop
(
Tdef(\weave, {
	inf.do {
		~fernStates.choose.value;
		~sedgeStates.choose.value;
		"weave".postln;
		[6, 8, 10, 14].choose.wait;
	}
}).play;
)

Tdef(\weave).stop;

( // back to silence
~free.(\fern); ~free.(\sedge);
)
