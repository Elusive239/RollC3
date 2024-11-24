import rollc3;
import std::io;

fn int main(String[] args)
{
    @pool(){
        ByteReader buffer;

        Parser* p = rollc3::new_parser(buffer.init(" 6d6!!5kh3sd+3"));
        Roll roll = p.parse();
		io::printfn("%s", roll.string());
		// io::printfn("%s", roll.roll().results);
		foreach(i, result : roll.roll().results){
			io::printfn("%d:%d", i,  result.result);
		}
        io::printfn("%d", roll.roll().total);
		return (int) roll.err;
    };
}

// fn void test1() @test{
//     ByteReader buffer;
//     buffer.init("3d6+1");
//     while(buffer.available()!!){
//         char c= buffer.read_byte()!!;
//         io::printf("%c", c);
//     }
// }

// fn void test2() @test{
//     ByteReader buffer;
//     InStream stream = buffer.init("3d6+1");
//     while(stream.available()!!){
//         char c= stream.read_byte()!!;
//         io::printf("%c", c);
//     }
// }

// fn void test3() @test{
//     @pool(){
//         ByteReader buffer;
//         // Parser* p = rollc3::new_parser(buffer.init("3d6+1"));
//         // Roll roll = p.parse();
//         // io::printfn("%q", roll.roll().total);
//         rollc3::TokenScanner* scanner = rollc3::new_scanner(buffer.init("3d6+1"));
//         Token current;
//         do{
//             current = scanner.scan();
//             io::printfn("Token: {%s, %s}", current.tok, current.lit);
//         }
//         while(current.tok != rollc3::ILLEGAL);
//     };
// }