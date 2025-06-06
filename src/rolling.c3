module roll;
import std::io;

fn String? parse_string(String rollStr, Allocator allocator = mem) @inline {
    ByteReader br;
    br.init(rollStr);
    return parse(&br, allocator);
}


fn String? parse(InStream r, Allocator allocator = mem) => @pool() {
    Parser* parser = newParser(r, tmem);
    Roll? roll = parser.parse();
    if(catch err = roll) return err?;
    
    DString dstr;
    dstr.tinit();
    dstr.appendf("Rolled \"");
    usz len = dstr.len();
    dstr.appendf("%s\" and got ", roll);
    if(dstr[len] == '+') dstr.delete(len);
    Result results = roll.roll();
    defer results.free();
    foreach(idx, result : results.results){
        dstr.appendf("%s, ", result.symbol);
    }
    len = dstr.len();
    dstr.delete(len-2);
    dstr.appendf("for a total of %d", results.total);
    return dstr.str_view().copy(allocator);
}