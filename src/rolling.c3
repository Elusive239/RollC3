/**
MIT License

Copyright (c) 2016 Andrew Montgomery-Hurrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

module rollc3;
import std::io;
import std::math;
import std::math::random;
import std::collections::list;
import std::collections::tuple;

// DieRoll is the result of a die roll
struct DieRoll{
	int result;
	String symbol;
}

// Die is the interface allDice must confirm to
interface Die { 
	fn DieRoll roll();
	fn String string();
}

// FateDie is a die representing the typical Fate/Fudge die
def FateDie = int;
// FATEBLANK is the symbol for a blank Fate die face
const String FATEBLANK = "☐";
// FATEMINUS is the symbol for a minus Fate die face
const String FATEMINUS = "⊟";
// FATEPLUS is the symbol for a plus Fate die face
const String FATEPLUS = "⊞";

// Roll generates a random number and the appropriate symbol
fn DieRoll FateDie.roll(FateDie d){
    int val = random::rand_in_range(-1, 1);
    String sym = FATEBLANK;
    switch (val) {
	    case -1: sym = FATEMINUS; break;
	    case 1: sym = FATEPLUS; break;
	}
    return {val,sym};
}

// String returns the string representation of the FateDie type
fn String FateDie.string(FateDie d) => "df";

// NormalDie is a die representing an N-sided die
def NormalDie = int;

// Roll generates a random number and the appropriate symbol
fn DieRoll NormalDie.roll(NormalDie d){
    int val = random::rand_in_range(1, d);
	String sym = string::tformat("%d", val);
    return {val, sym};
}

// String returns the string representation of the NormalDie type
fn String NormalDie.string(NormalDie d) => string::tformat("d%d", d);
