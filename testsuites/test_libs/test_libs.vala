/*
    This program is to verify that we can link a program
    to ZCD without having to include a direct dependency
    on JsonGlib.
*/

void main()
{
    string x;
    try {
        x = test_libs("{\"argument\":1}", "{\"argument\":null}");
    } catch (Error e) {
        assert_not_reached();
    }
    debug(x);
}

