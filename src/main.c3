module roll20;
import std::io;
import std::math::random;
import std::collections::list;

fn int main(String[] args)
{
	io::printn("Hello, World!");
	DiceResult result = roll_xy(902, 100);
	result.keep_more(90);
	io::printfn("%s, rolled = %d, len = %d", result, result.num_rolls, result.rolled_len);
	io::printfn("%s, rolled = %d, len = %d", result.print_friendly(5, allocator: allocator::temp()), result.num_rolls, result.rolled_len);

	MultiDiceResult results = roll_xyz(6, 20, 4);
	io::printfn("%s", results);
	for(int i = 0; i < results.len; i++) results[i].free();
	allocator::free(allocator::heap(), results);
	result.free();
	return 0;
}

struct DiceResult (Printable){
	int num_rolls;
	int rolled_len;
	int max_value;
	int[] rolled;
	bool exploded;
}

fn void DiceResult.free(&self, Allocator allocator = allocator::heap()){
	allocator::free(allocator, self.rolled);
}

fn String DiceResult.print_friendly(&self, int max_to_print, Allocator allocator) @dynamic{
	DString dstr; defer dstr.free();
	dstr.append("%dd%d");
	if(self.exploded) dstr.append_char('!');
	dstr.append(" = ");

	if(max_to_print > self.rolled_len) max_to_print = self.rolled_len;

	if(max_to_print == self.rolled_len){
		for(int i = 0; i < self.rolled_len; i++){
			dstr.appendf("%d", self.rolled[i]);
			if(self.rolled.len -1 != i) dstr.appendf(" + ");
		}
	}else{
		for(int i = 0; i < max_to_print; i++){
			dstr.appendf("%d", self.rolled[i]);
			if(max_to_print -1 != i) dstr.appendf(" + ");
		}
		if(self.rolled.len > 1) {dstr.append(" + ...");}
		else{
			dstr.append("...");
		}
	}

	dstr.append(" = %d");

	return string::tformat(dstr.str_view(), self.num_rolls, self.max_value, self.sum());
}

fn String DiceResult.to_string(&self, Allocator allocator) @dynamic{
	return self.print_friendly(self.rolled.len, allocator);
}

fn int DiceResult.sum(&self){
	int x =0;
	for(int i = 0; i < self.rolled_len; ++i){
		x += self.rolled[i];
	}
	return x;
}

fn int DiceResult.count(&self, int v){
	int x =0;
	for(int i = 0; i < self.rolled_len; ++i){
		if(self.rolled[i] == v) x++;
	}
	return x;
}

fn void DiceResult.drop_equal(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] == v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.drop_less(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] <= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.drop_more(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] >= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_equal(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] != v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_more(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] <= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_less(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] >= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

def ResultList = List(<int>);

fn DiceResult roll_xy(int x, int y, bool explode = false, Allocator allocator = allocator::heap()){
	DiceResult result;// = {x, y, 0};
	result.num_rolls = x;
	result.max_value = y;
	ResultList results; defer results.free();
	for(int i =0 ;i < result.num_rolls; ++i){
		int v = random::rand_in_range(1, result.max_value);
		results.push(v);
		if(v == result.max_value && explode) i--;
	}
	result.exploded = results.len() != x;
	result.rolled = results.to_new_array(allocator);
	result.rolled_len = result.rolled.len;
	return result;
}

def MultiDiceResult = DiceResult[];

fn MultiDiceResult roll_xyz(int x, int y, int z, bool explode = false, Allocator allocator = allocator::heap()){
	MultiDiceResult results = allocator::new_array(allocator, DiceResult, z);
	for(int i = 0; i < z; i++){
		results[i] = roll_xy(x, y, explode, allocator);
	}
	return results;
}

fn int[] MultiDiceResult.sum(&self, Allocator allocator = allocator::heap()){
	int[] s = allocator::new_array(allocator, int, self.len);
	for(int i =0; i < s.len; i++) {
		DiceResult result = (*self)[i];
		s[i] = result.sum();
	}
	return s;
}