import rollc3;
import std::io;

fn int main(String[] args)
{
    @pool(){
        io::printfn("Hi!");
        ByteBuffer buffer; defer buffer.free();
        io::printfn("Hi!");
        Parser* p = rollc3::new_parser((InStream*) buffer.init_with_buffer("3d6+1")!!);
        io::printfn("Hi!");
        RollAndError re = p.parse();
        Roll* roll = re.first;
        io::printfn("%q", roll.roll().total);
    };
	return 0;
}

fn void test() @test{
    io::printfn("\nTEST 1");
}