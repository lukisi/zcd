/*
    valac -C \
    ../testsuites/test_libs/test_libs.vala \
    ../zcd.vapi

    gcc -c test_libs.c \
    -w \
    $(pkg-config --cflags gobject-2.0 gee-0.8)

    gcc -o test_libs test_libs.o \
    $(pkg-config --libs gobject-2.0 gee-0.8) \
	./libzcd.la

*/

void main()
{
    string x = test_libs("{\"argument\":1}", "{\"argument\":null}");
    assert(x != "");
}

