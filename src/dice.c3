module roll20::dice;
import std::io;
import std::math::random;
import std::collections::list;
def Dice = int;

fn int Dice.roll(Dice dice){
	return random::rand_in_range(1, dice);
}

struct DiceResult (Printable){
	inline int[] results;
	Dice die;
}

def IntList = List(<int>);

fn DiceResult roll_x(int x, Dice die = 20, bool explode = false){
	IntList results; defer results.free();
	do{
		int value = die.roll();
		results.push(value);
		if(explode && value == die) x++;
	}while(--x != 0);
	return{ results.to_new_array(), die};
}

fn int DiceResult.evaluate(&self){
	int x =0;
	for(int i = 0; i < self.len; ++i){
		x += (*self)[i];
	}
	return x;
}

fn String DiceResult.to_string(&self, Allocator allocator) @dynamic{
	if(self.die == -1) return string::format("%d", self.evaluate(), allocator: allocator);
	return string::format("%dd%d = %d", self.len, self.die, self.evaluate(), allocator: allocator);
}