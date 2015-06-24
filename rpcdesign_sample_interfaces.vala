/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

void make_sample_interfaces(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
/*
interfaces.rpcidl
==========================================
    """);
    string[] lines = read_file("interfaces.rpcidl");
    contents += string.joinv("\n", lines);
    contents += prettyformat("""
==========================================
 */

using Gee;
using zcd;
using zcd.ModRpc;

namespace AppDomain
{
    """);
    foreach (Exception exc in errors)
    {
        contents += prettyformat(
@"  public errordomain $(exc.errdomain) {");
        foreach (string errcode in exc.errcodes)
        {
            contents += prettyformat(
@"      $(errcode),");
        }
        contents += prettyformat("""
    }

        """);
    }
    ArrayList<string> classes = new ArrayList<string>();
    ArrayList<string> interfaces = new ArrayList<string>();
    foreach (Root r in roots) foreach (ModuleRemote m in r.modules) foreach (Method me in m.methods)
    {
        {
            string ret_s = me.returntype;
            if (!type_is_basic(ret_s))
            {
                ret_s = type_name(ret_s);
                if (type_is_interface(ret_s))
                {
                    if (!(ret_s in interfaces)) interfaces.add(ret_s);
                }
                else
                {
                    if (!(ret_s in classes)) classes.add(ret_s);
                }
            }
        }
        foreach (Argument arg in me.args)
        {
            string arg_s = arg.argclass;

            if (!type_is_basic(arg_s))
            {
                arg_s = type_name(arg_s);
                if (type_is_interface(arg_s))
                {
                    if (!(arg_s in interfaces)) interfaces.add(arg_s);
                }
                else
                {
                    if (!(arg_s in classes)) classes.add(arg_s);
                }
            }
        }
    }

    foreach (string i in interfaces)
    {
        contents += prettyformat(
@"  public interface $(i) : Object");
        contents += prettyformat("""
    {
    }

        """);
    }

    if (!("UnicastID" in classes)) classes.add("UnicastID");
    if (!("BroadcastID" in classes)) classes.add("BroadcastID");
    foreach (string c in classes)
    {
        contents += prettyformat(
@"  public class $(c) : Object, ISerializable /*optional*/");
        contents += prettyformat("""
    {
        public string sample_property {get; set;}

        public bool check_deserialization() /*optional*/
        {
            // check each property
            if (sample_property == null) return false;
            return true;
        }
    }

        """);
    }

    contents += prettyformat("""
}
    """);

    write_file("sample_interfaces.vala", contents);
}

bool type_is_basic(string s)
{
    ArrayList<string> basic = new ArrayList<string>.wrap({
        "void",
        "string", "string?", "Gee.List<string>",
        "bool", "bool?", "Gee.List<bool>",
        "int", "int?", "Gee.List<int>",
        "long", "long?", "Gee.List<long>",
        "int64", "int64?", "Gee.List<int64>",
        "uint16", "uint16?", "Gee.List<int64>",
        "double", "double?", "Gee.List<double>",
        "uint8[]", "uint8[]?", "Gee.List<double>",
        });
    return s in basic;
}

string type_name(owned string s)
{
    if (s.has_prefix("Gee.List<"))
    {
        assert(s.has_suffix(">"));
        s = s.substring(9, s.length-10);
    }
    if (s.has_suffix("?")) s = s.substring(0, s.length-1);
    return s;
}

bool type_is_interface(string s)
{
    return (s[0] == 'I' && s[1] >= 'A' && s[1] <= 'Z');
}

