import rollc3;
import std::io;

fn int main(String[] args)
{
    @pool(){
        ByteReader buffer;

        Parser* p = rollc3::new_parser(buffer.init(" 1d6!"));
        Roll roll = p.parse();
		io::printfn("%s", roll.string());
        io::printfn("%d", roll.roll().total);
		return (int) roll.err;
    };
}

fn void test1() @test{
    ByteReader buffer;
    buffer.init("3d6+1");
    while(buffer.available()!!){
        char c= buffer.read_byte()!!;
        io::printf("%c", c);
    }
}

fn void test2() @test{
    ByteReader buffer;
    InStream stream = buffer.init("3d6+1");
    while(stream.available()!!){
        char c= stream.read_byte()!!;
        io::printf("%c", c);
    }
}

fn void test3() @test{
    @pool(){
        ByteReader buffer;
        // Parser* p = rollc3::new_parser(buffer.init("3d6+1"));
        // Roll roll = p.parse();
        // io::printfn("%q", roll.roll().total);
        rollc3::Scanner* scanner = rollc3::new_scanner(buffer.init("3d6+1"));
        Token current;
        do{
            current = scanner.scan();
            io::printfn("Token: {%s, %s}", current.tok, current.lit);
        }
        while(current.tok != rollc3::ILLEGAL);
    };
}