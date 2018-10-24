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
    public int i;
}

class OneDest : Object
{
    public int i;
}

class MultiDest : Object
{
    public int i1;
    public int i2;
    public int i3;
}

class Nic : Object
{
    public string mac;
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

void main() {
    OneSource source_id = new OneSource(); source_id.i = 1;
    OneDest unicast_id = new OneDest(); unicast_id.i = 2;
    Nic src_nic = new Nic(); src_nic.mac = "ab:ab:ab:ab:ab:ab";
    string json_tree_request;
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
    print(@"ret: '$(json_tree_request)'\n");
}

/*
{
    "method-name":"multiply",
    "arguments":[{"argument":12},{"argument":42}],
    "source-id":{"typename":"OneSource","value":{}},
    "unicast-id":{"typename":"OneDest","value":{}},
    "src-nic":{"typename":"Nic","value":{}},
    "wait-reply":true
}
*/