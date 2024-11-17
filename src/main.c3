import rollc3;
import std::io;

fn int main(String[] args)
{
    @pool(){
        ByteReader buffer;

        Parser* p = rollc3::new_parser(buffer.init("3d6+1"));
        RollAndError re = p.parse();
        Roll* roll = re.first;
        io::printfn("%q", roll.roll().total);
    };
	return 0;
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