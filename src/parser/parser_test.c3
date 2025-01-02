module parser;

fn void! test_Parser_next_without_sequences() @test {
    parser::Parser p;
    p.init();

    String want = "hello world";
    DString got;
    defer got.free();

    foreach (char c : want) {
        Action! action = p.next(c);
        if (catch err = action) {
            assert(false, "unexpected err: %s", err);
        }
        got.append_char(action.data.print);
    }

    assert(got.str_view() == want, "want == got");
}
