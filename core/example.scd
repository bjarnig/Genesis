// example.scd: the running order, one block at a time. Nothing sounds until .play.

( // 1. load everything (run once)
~here = thisProcess.nowExecutingPath.dirname +/+ "../";
(~here ++ "core/material-library.scd").load;   // ~material, ~gen, ~play, ~solo, ~free, ~loaded
(~here ++ "core/fader-specs.scd").load;        // ~specs, the fader range per parameter
(~here ++ "core/ndef-faders.scd").load;        // ~ndefFaders
(~here ++ "core/preset-morph.scd").load;       // ~loadPresets, ~morphCurves, ~presetMorph
~presets = ~loadPresets.(~here ++ "core/presets.scd");
~faders = ~faders ? ();
~material.keys.asArray.sort.postln;       // what is on offer
)


( // 2. hear one process
~play.(\gorse);
)


( // 3. faders for it, with the randomize distributions and reset
~faders[\gorse] = ~ndefFaders.(~gen.(\gorse), ~specs[\gorse]);
)


( // 4. morph between the presets you posted from that window
~morph = ~presetMorph.(~gen.(\gorse), ~presets[\gorse], ~specs[\gorse]);
)


( // 5. or drive the morph from code
~morph.go(3, \zigzag, 20);   // to preset 3, zigzagging, over 20 seconds
)


( // 6. back to no synths
~free.();
)


// 7. or open a workflow: workflows/wf-*.scd (granulation, sediment, waveset, feedback, resonance)
//    are block-by-block files like this one, not things to .load


/*

~solo.(\teasel);              // free everything else and play this one
~free.(\gorse);               // one process back to sleep
~loaded;                      // what is instantiated right now

~faders[\gorse].randomize(\beta);    // uni, beta, exp, walk
~faders[\gorse].resetAll;            // every fader back to the Ndef's own default
~faders[\gorse].printState;          // print the state; paste into presets.scd

~morph.place(0.5);            // sit between the two presets by hand
~morph.cancel;                // abandon a morph in progress
~morphCurves.keys;            // jump hold linear smooth accel decel zigzag steps scatter

*/
