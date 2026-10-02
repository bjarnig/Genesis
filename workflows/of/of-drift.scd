// of-drift.scd
// moss and clover drifting through the OF processing library. Run of-setup.scd first.

( // plain pair
a = ~gen.(\moss).play;
b = ~gen.(\clover).play;
)

(
~mossStates = ~stateFor.(a, \moss);
~cloverStates = ~stateFor.(b, \clover);
("moss states: " ++ ~mossStates.size ++ "   clover states: " ++ ~cloverStates.size).postln;
)

// scripted pass, folding a processing stage in mid-stream
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

// random preset jumps, each at its own pace
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

( // free
~free.(\moss); ~free.(\clover);
)
