/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
 *
 *  Netsukuku is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Netsukuku is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Netsukuku.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;
using TaskletSystem;
using zcd;

class OneSource : Object
{
    public int i {get; set;}
}

class OneDest : Object
{
    public int i {get; set;}
}

class MultiDest : Object
{
    public int i1 {get; set;}
    public int i2 {get; set;}
    public int i3 {get; set;}
}

class Nic : Object
{
    public string mac {get; set;}
}




public string prepare_direct_object(Object obj)
{
    IJsonBuilderElement cb = new JsonBuilderObject(obj);
    var b = new Json.Builder();
    cb.execute(b);
    var g = new Json.Generator();
    g.pretty = false;
    g.root = b.get_root();
    return g.to_data(null);
}

internal string prepare_argument(IJsonBuilderElement cb)
{
    var b = new Json.Builder();
    b.begin_object();
    b.set_member_name("argument");
    cb.execute(b);
    b.end_object();
    var g = new Json.Generator();
    g.pretty = false;
    g.root = b.get_root();
    return g.to_data(null);
}

public string prepare_argument_int64(int64 i)
{
    return prepare_argument(new JsonBuilderInt64(i));
}

internal string prepare_return_value(IJsonBuilderElement cb)
{
    var b = new Json.Builder();
    b.begin_object();
    b.set_member_name("return-value");
    cb.execute(b);
    b.end_object();
    var g = new Json.Generator();
    g.pretty = false;
    g.root = b.get_root();
    return g.to_data(null);
}

public string prepare_return_value_int64(int64 i)
{
    return prepare_return_value(new JsonBuilderInt64(i));
}




internal interface IJsonBuilderElement : Object {
    public abstract void execute(Json.Builder b);
}

internal class JsonBuilderInt64 : Object, IJsonBuilderElement
{
    private int64 i;
    public JsonBuilderInt64(int64 i) {
        this.i = i;
    }
    public void execute(Json.Builder b) {
        b.add_int_value(i);
    }
}

internal class JsonBuilderObject : Object, IJsonBuilderElement
{
    private Object obj;
    public JsonBuilderObject(Object obj) {
        this.obj = obj;
    }
    public void execute(Json.Builder b) {
        b.begin_object();
        b.set_member_name("typename");
        b.add_string_value(obj.get_type().name());
        b.set_member_name("value");
        Json.Node* obj_n = Json.gobject_serialize(obj);
        // json_builder_add_value docs says: The builder will take ownership of the #JsonNode.
        // but the vapi does not specify that the formal parameter is owned.
        // So I try and handle myself the unref of obj_n
        b.add_value(obj_n);
        b.end_object();
    }
}




public errordomain HelperDeserializeError {
    GENERIC
}

public errordomain HelperNotJsonError {
    GENERIC
}



internal void read_direct(string js, IJsonReaderElement cb) throws HelperDeserializeError, HelperNotJsonError
{
    Json.Parser p = new Json.Parser();
    try {
        p.load_from_data(js);
    } catch (Error e) {
        throw new HelperNotJsonError.GENERIC(e.message);
    }
    Json.Reader r = new Json.Reader(p.get_root());
    cb.execute(r);
}

public Object read_direct_object_notnull(Type expected_type, string js) throws HelperDeserializeError, HelperNotJsonError
{
    JsonReaderObject cb = new JsonReaderObject(expected_type, false);
    read_direct(js, cb);
    assert(cb.ret_ok);
    return cb.deserialize_or_null(js, (root) => {
        return root;
    });
}

internal void read_argument(string js, IJsonReaderElement cb) throws HelperDeserializeError, HelperNotJsonError
{
    Json.Parser p = new Json.Parser();
    try {
        p.load_from_data(js);
    } catch (Error e) {
        throw new HelperNotJsonError.GENERIC(e.message);
    }
    Json.Reader r = new Json.Reader(p.get_root());
    if (!r.is_object())
        throw new HelperDeserializeError.GENERIC(@"root JSON node must be an object");
    if (!r.read_member("argument"))
        throw new HelperDeserializeError.GENERIC(@"root JSON node must have argument");
    cb.execute(r);
    r.end_member();
}

public int64? read_argument_int64_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
{
    return read_argument_int64(js, true);
}

public int64 read_argument_int64_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
{
    return read_argument_int64(js, false);
}

internal int64? read_argument_int64(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
{
    JsonReaderInt64 cb = new JsonReaderInt64(nullable);
    read_argument(js, cb);
    assert(cb.ret_ok);
    return cb.ret;
}

internal void read_return_value(string js, IJsonReaderElement cb) throws HelperDeserializeError, HelperNotJsonError
{
    Json.Parser p = new Json.Parser();
    try {
        p.load_from_data(js);
    } catch (Error e) {
        throw new HelperNotJsonError.GENERIC(e.message);
    }
    Json.Reader r = new Json.Reader(p.get_root());
    if (!r.is_object())
        throw new HelperDeserializeError.GENERIC(@"root JSON node must be an object");
    if (!r.read_member("return-value"))
        throw new HelperDeserializeError.GENERIC(@"root JSON node must have return-value");
    cb.execute(r);
    r.end_member();
}

public int64? read_return_value_int64_maybe(string js)
    throws HelperDeserializeError, HelperNotJsonError
{
    return read_return_value_int64(js, true);
}

public int64 read_return_value_int64_notnull(string js)
    throws HelperDeserializeError, HelperNotJsonError
{
    return read_return_value_int64(js, false);
}

internal int64? read_return_value_int64(string js, bool nullable)
    throws HelperDeserializeError, HelperNotJsonError
{
    JsonReaderInt64 cb = new JsonReaderInt64(nullable);
    read_return_value(js, cb);
    assert(cb.ret_ok);
    return cb.ret;
}





internal interface IJsonReaderElement : Object {
    public abstract void execute(Json.Reader r) throws HelperDeserializeError;
}

internal class JsonReaderInt64 : Object, IJsonReaderElement
{
    public bool ret_ok;
    public bool nullable;
    public int64? ret;
    public JsonReaderInt64(bool nullable) {
        ret_ok = false;
        this.nullable = nullable;
    }
    public void execute(Json.Reader r) throws HelperDeserializeError {
        if (r.get_null_value())
        {
            if (!nullable)
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            ret = null;
            ret_ok = true;
            return;
        }
        if (!r.is_value())
            throw new HelperDeserializeError.GENERIC("element must be a int");
        if (r.get_value().get_value_type() != typeof(int64))
            throw new HelperDeserializeError.GENERIC("element must be a int");
        ret = r.get_int_value();
        ret_ok = true;
    }
}

internal delegate unowned Json.Node JsonExecPath(Json.Node root);
internal class JsonReaderObject : Object, IJsonReaderElement
{
    public bool ret_ok;
    public Type expected_type;
    public bool nullable;
    private bool is_null;
    private Type type;
    public JsonReaderObject(Type expected_type, bool nullable) {
        ret_ok = false;
        this.expected_type = expected_type;
        this.nullable = nullable;
    }
    public void execute(Json.Reader r) throws HelperDeserializeError {
        if (r.get_null_value())
        {
            if (!nullable)
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            is_null = true;
            ret_ok = true;
            return;
        }
        if (!r.is_object())
            throw new HelperDeserializeError.GENERIC("element must be an object");
        string typename;
        if (!r.read_member("typename"))
            throw new HelperDeserializeError.GENERIC("element must have typename");
        if (!r.is_value())
            throw new HelperDeserializeError.GENERIC("typename must be a string");
        if (r.get_value().get_value_type() != typeof(string))
            throw new HelperDeserializeError.GENERIC("typename must be a string");
        typename = r.get_string_value();
        r.end_member();
        type = Type.from_name(typename);
        if (type == 0)
            throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' unknown class");
        if (!type.is_a(expected_type))
            throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' is not a '$(expected_type.name())'");
        if (!r.read_member("value"))
            throw new HelperDeserializeError.GENERIC("element must have value");
        r.end_member();
        is_null = false;
        ret_ok = true;
    }
    public Object? deserialize_or_null(string js, JsonExecPath exec_path) throws HelperDeserializeError
    {
        assert(ret_ok);
        if (is_null) return null;
        // find node, copy tree, deserialize
        Json.Parser p = new Json.Parser();
        try {
            p.load_from_data(js);
        } catch (Error e) {
            error(@"Parser error: This string should have been already parsed: $(e.message) - '$(js)'");
        }
        unowned Json.Node p_root = p.get_root();
        unowned Json.Node p_value = exec_path(p_root).get_object().get_member("value");
        Json.Node cp_value = p_value.copy();
        return Json.gobject_deserialize(type, cp_value);
    }
}






void test_unicast_request()
{
    string json_tree_request;
    {
        OneSource source_id = new OneSource(); source_id.i = 1;
        OneDest unicast_id = new OneDest(); unicast_id.i = 2;
        Nic src_nic = new Nic(); src_nic.mac = "ab:ab:ab:ab:ab:ab";
        try {
            build_unicast_request(
                "multiply",
                new ArrayList<string>.wrap({
                    prepare_argument_int64(12),
                    prepare_argument_int64(42)
                }),
                prepare_direct_object(source_id),
                prepare_direct_object(unicast_id),
                prepare_direct_object(src_nic),
                true,
                out json_tree_request
                );
        } catch (InvalidJsonError e) {
            error(@"InvalidJsonError: $(e.message)");
        }
        //print(@"ret: '$(json_tree_request)'\n");
    }

    {
        OneSource source_id;
        OneDest unicast_id;
        Nic src_nic;
        int arg0;
        int arg1;
        string _source_id;
        string _unicast_id;
        string _src_nic;
        string m_name;
        Gee.List<string> arguments;
        bool wait_reply;
        try {
            parse_unicast_request(
                json_tree_request,
                out m_name,
                out arguments,
                out _source_id,
                out _unicast_id,
                out _src_nic,
                out wait_reply);
        } catch (MessageError e) {
            error(@"MessageError: $(e.message)");
        }
        try {
            source_id = (OneSource)read_direct_object_notnull(typeof(OneSource), _source_id);
            unicast_id = (OneDest)read_direct_object_notnull(typeof(OneDest), _unicast_id);
            src_nic = (Nic)read_direct_object_notnull(typeof(Nic), _src_nic);
            assert(arguments.size == 2);
            int64 val = read_argument_int64_notnull(arguments[0]);
            if (val > int.MAX || val < int.MIN) error("arg0 overflows size of int");
            arg0 = (int)val;
            val = read_argument_int64_notnull(arguments[1]);
            if (val > int.MAX || val < int.MIN) error("arg1 overflows size of int");
            arg1 = (int)val;
        } catch (HelperDeserializeError e) {
            error(@"HelperDeserializeError: $(e.message)");
        } catch (HelperNotJsonError e) {
            error(@"HelperNotJsonError: $(e.message)");
        }
        assert(source_id.i == 1);
        assert(unicast_id.i == 2);
        assert(src_nic.mac == "ab:ab:ab:ab:ab:ab");
        assert(arg0 == 12);
        assert(arg1 == 42);
        assert(m_name == "multiply");
        assert(wait_reply == true);
    }
}

void test_unicast_response()
{
    string json_tree_response;
    {
        OneSource source_id = new OneSource(); source_id.i = 1;
        OneDest unicast_id = new OneDest(); unicast_id.i = 2;
        Nic src_nic = new Nic(); src_nic.mac = "ab:ab:ab:ab:ab:ab";
        try {
            build_unicast_response(
                prepare_return_value_int64(12*42),
                out json_tree_response
                );
        } catch (InvalidJsonError e) {
            error(@"InvalidJsonError: $(e.message)");
        }
        //print(@"ret: '$(json_tree_response)'\n");
    }

    {
        string response;
        int retval;
        try {
            parse_unicast_response(
                json_tree_response,
                out response);
        } catch (MessageError e) {
            error(@"MessageError: $(e.message)");
        }
        try {
            int64 val = read_return_value_int64_notnull(response);
            if (val > int.MAX || val < int.MIN) error("response overflows size of int");
            retval = (int)val;
        } catch (HelperDeserializeError e) {
            error(@"HelperDeserializeError: $(e.message)");
        } catch (HelperNotJsonError e) {
            error(@"HelperNotJsonError: $(e.message)");
        }
        assert(retval == 12*42);
    }
}

void test_broadcast_request()
{
    string json_tree_packet;
    {
        OneSource source_id = new OneSource(); source_id.i = 1;
        MultiDest broadcast_id = new MultiDest(); broadcast_id.i1 = 1; broadcast_id.i2 = 2; broadcast_id.i3 = 3;
        Nic src_nic = new Nic(); src_nic.mac = "ab:ab:ab:ab:ab:ab";
        try {
            build_broadcast_request(
                12345,
                "multiply",
                new ArrayList<string>.wrap({
                    prepare_argument_int64(12),
                    prepare_argument_int64(42)
                }),
                prepare_direct_object(source_id),
                prepare_direct_object(broadcast_id),
                prepare_direct_object(src_nic),
                true,
                out json_tree_packet
                );
        } catch (InvalidJsonError e) {
            error(@"InvalidJsonError: $(e.message)");
        }
        //print(@"ret: '$(json_tree_packet)'\n");
    }

    {
        OneSource source_id;
        MultiDest broadcast_id;
        Nic src_nic;
        int arg0;
        int arg1;
        string _source_id;
        string _broadcast_id;
        string _src_nic;
        int packet_id;
        string m_name;
        Gee.List<string> arguments;
        bool send_ack;
        try {
            string? json_tree_request;
            string? json_tree_ack;
            parse_broadcast_packet(
                json_tree_packet,
                out json_tree_request,
                out json_tree_ack);
            assert(json_tree_ack == null);
            assert(json_tree_request != null);
            parse_broadcast_request(
                json_tree_request,
                out packet_id,
                out m_name,
                out arguments,
                out _source_id,
                out _broadcast_id,
                out _src_nic,
                out send_ack);
        } catch (MessageError e) {
            error(@"MessageError: $(e.message)");
        }
        try {
            source_id = (OneSource)read_direct_object_notnull(typeof(OneSource), _source_id);
            broadcast_id = (MultiDest)read_direct_object_notnull(typeof(MultiDest), _broadcast_id);
            src_nic = (Nic)read_direct_object_notnull(typeof(Nic), _src_nic);
            assert(arguments.size == 2);
            int64 val = read_argument_int64_notnull(arguments[0]);
            if (val > int.MAX || val < int.MIN) error("arg0 overflows size of int");
            arg0 = (int)val;
            val = read_argument_int64_notnull(arguments[1]);
            if (val > int.MAX || val < int.MIN) error("arg1 overflows size of int");
            arg1 = (int)val;
        } catch (HelperDeserializeError e) {
            error(@"HelperDeserializeError: $(e.message)");
        } catch (HelperNotJsonError e) {
            error(@"HelperNotJsonError: $(e.message)");
        }
        assert(source_id.i == 1);
        assert(broadcast_id.i1 == 1);
        assert(broadcast_id.i2 == 2);
        assert(broadcast_id.i3 == 3);
        assert(src_nic.mac == "ab:ab:ab:ab:ab:ab");
        assert(arg0 == 12);
        assert(arg1 == 42);
        assert(m_name == "multiply");
        assert(send_ack == true);
    }
}

void test_broadcast_ack()
{
    string json_tree_packet;
    {
        build_broadcast_ack(
            12345,
            "ab:ab:ab:ab:ab:ab",
            out json_tree_packet
            );
        //print(@"ret: '$(json_tree_packet)'\n");
    }

    {
        int packet_id;
        string ack_mac;
        try {
            string? json_tree_request;
            string? json_tree_ack;
            parse_broadcast_packet(
                json_tree_packet,
                out json_tree_request,
                out json_tree_ack);
            assert(json_tree_request == null);
            assert(json_tree_ack != null);
            parse_broadcast_ack(
                json_tree_ack,
                out packet_id,
                out ack_mac);
        } catch (MessageError e) {
            error(@"MessageError: $(e.message)");
        }
        assert(packet_id == 12345);
        assert(ack_mac == "ab:ab:ab:ab:ab:ab");
    }
}




int main(string[] args)
{
    GLib.Test.init(ref args);
    GLib.Test.add_func ("/json_handling/unicast_request", () => {
        test_unicast_request();
    });
    GLib.Test.add_func ("/json_handling/unicast_response", () => {
        test_unicast_response();
    });
    GLib.Test.add_func ("/json_handling/broadcast_request", () => {
        test_broadcast_request();
    });
    GLib.Test.add_func ("/json_handling/broadcast_ack", () => {
        test_broadcast_ack();
    });
    GLib.Test.run();
    return 0;
}