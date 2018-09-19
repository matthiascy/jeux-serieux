// script: js

var score = 0;

var bt = [
    // sprite-id-unpressed name position sprite-id-pressed keymapid not-available
    [0,  "U", [ 8,  0], 16,  0, 32],
    [1,  "D", [ 8, 16], 17,  1, 33],
    [2,  "L", [ 1,  8], 18,  2, 34],
    [3,  "R", [15,  8], 19,  3, 35],
    [4,  "A", [ 0,  0], 20,  1, 36],
    [5,  "Z", [ 0, 14], 21, 26, 37],
];

var 


function TIC() {
    cls(0);
    showHud(score);
}


/*
var wavelimit = 136/2;

function scanline(row) {
    poke(0x3fc0, 190-row);
    poke(0x3fc1, 140-row);
    poke(0x3fc2, 0);
    if (row > wavelimit)
        poke(0x3ff9, Math.sin((time()/200 + row/5)) * 10);
    else
        poke(0x3ff9, 0);
}
*/

function showHud(score) {
    showDirBtns(216, 112);
    showFnBtns(0, 112);
    showTime(0, 0);
    showScore(score, 180, 0);
}

function showDirBtns(x, y) {
    for (var i = 0; i < 4; ++i) {
        spr(bt[i][0], bt[i][2][0] + x, bt[i][2][1] + y);
        if (btn(bt[i][4])) {
            spr(bt[i][3], bt[i][2][0] + x, bt[i][2][1] + y);
        }
    }
}

function showFnBtns(x, y) {
    for (var i = 4; i < 6; ++i) {
        spr(bt[i][0], bt[i][2][0] + x, bt[i][2][1] + y);

        if (key(bt[i][4])) {
            spr(bt[i][3], bt[i][2][0] + x, bt[i][2][1] + y);
        }
    }
}

function showTime(x, y) {
    print("Time: " + (time() / 1000).toFixed(2), x, y, 15, scale=0.5, smallfont=true);
}

function showScore(score, x, y) {
    print("Score: " + score, x, y, 15, scale=0.5, smallfont=true);
}
