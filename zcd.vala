public string test_libs(string s1, string s2) throws Error
{
    var b = new Json.Builder();
    var p1 = new Json.Parser();
    var p2 = new Json.Parser();
    // the Parser must not be destructed until we generate the JSON output.
    b.begin_object()
        .set_member_name("return-value").begin_object()
            .set_member_name("number").add_int_value(3)
            .set_member_name("list").begin_array();
                {
                    p1.load_from_data(s1);
                    b.add_value(p1.get_root());
                }
                {
                    p2.load_from_data(s2);
                    b.add_value(p2.get_root());
                }
            b.end_array()
        .end_object()
    .end_object();
    var g = new Json.Generator();
    g.pretty = false;
    g.root = b.get_root();
    return g.to_data(null);
}

