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

void make_sample_skeleton(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;
using zcd;
using zcd.ModRpc;

namespace AppDomain
{
    namespace ModRpc
    {
    """);

    foreach (Root r in roots)
    {
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat(
@"      public interface I$(mo.modclass)Skeleton : Object");
            contents += prettyformat("""
        {
            """);
            foreach (Method me in mo.methods)
            {
                string signature = @"$(me.returntype) $(me.name)(";
                foreach (Argument arg in me.args)
                {
                    signature += @"$(arg.argclass) $(arg.argname), ";
                }
                signature += "CallerInfo? caller=null)";
                if (!me.errors.is_empty)
                {
                    signature += " throws ";
                    string next = "";
                    foreach (Exception exc in me.errors)
                    {
                        signature += @"$(next)$(exc.errdomain)";
                        next = ", ";
                    }
                }
                contents += prettyformat(
@"          public abstract $(signature);");
            }
            contents += prettyformat("""
        }

            """);
        }

        contents += prettyformat(
@"      public interface I$(r.rootclass)Skeleton : Object");
        contents += prettyformat("""
        {
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat(
@"          protected abstract unowned I$(mo.modclass)Skeleton $(mo.modname)_getter();");
            contents += prettyformat(
@"          public I$(mo.modclass)Skeleton $(mo.modname) {get {return $(mo.modname)_getter();}}");
        }
        contents += prettyformat("""
        }

        """);
    }

    contents += prettyformat("""
        public interface IRpcDelegate : Object
        {
    """);
    foreach (Root r in roots)
    {
        contents += prettyformat(
@"          public abstract I$(r.rootclass)Skeleton? get_$(r.rootname)(CallerInfo caller);");
    }
    contents += prettyformat("""
        }

        internal errordomain InSkeletonDeserializeError {
            GENERIC
        }

    """);

    foreach (Root r in roots)
    {
        contents += prettyformat(
@"      internal class Zcd$(r.rootclass)Dispatcher : Object, IZcdDispatcher");
        contents += prettyformat("""
        {
            private string m_name;
            private ArrayList<string> args;
            private CallerInfo caller_info;
            private I""" + r.rootclass + """Skeleton """ + r.rootname + """;
            public Zcd""" + r.rootclass + """Dispatcher(I""" + r.rootclass + """Skeleton """ + r.rootname + """, string m_name, Gee.List<string> args, CallerInfo caller_info)
            {
                this.""" + r.rootname + """ = """ + r.rootname + """;
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            private string execute_or_throw_deserialize() throws InSkeletonDeserializeError
            {
                string ret;
        """);
        string nextmod = "";
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat(
@"              $(nextmod)if (m_name.has_prefix(\"$(r.rootname).$(mo.modname).\"))");
            contents += prettyformat("""
                {
            """);
            string nextmet = "";
            foreach (Method me in mo.methods)
            {
                contents += prettyformat(
@"                  $(nextmet)if (m_name == \"$(r.rootname).$(mo.modname).$(me.name)\")");
                contents += prettyformat("""
                    {
                        if (args.size != """ + @"$(me.args.size)" + """) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                """);
                if (me.args.size > 0)
                {
                    contents += prettyformat("""
                        // arguments:
                    """);
                    for (int j = 0; j < me.args.size; j++)
                    {
                        Argument arg = me.args[j];
                        contents += prettyformat(
@"                      $(arg.argclass) arg$(j);");
                    }
                    contents += prettyformat("""
                        // position:
                        int j = 0;
                    """);
                    for (int j = 0; j < me.args.size; j++)
                    {
                        Argument arg = me.args[j];
                        contents += prettyformat("""
                        {
                            // deserialize arg""" + @"$(j) ($(arg.argclass) $(arg.argname))" + """
                            string arg_name = """ + @"\"$(arg.argname)\"" + """;
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            try {
                        """);
                        switch (arg.argclass)
                        {
                            case "string":
                                contents += prettyformat("""
                                arg""" + @"$(j)" + """ = read_argument_string_notnull(args[j]);
                                """);
                                break;
                            case "string?":
                                contents += prettyformat("""
                                arg""" + @"$(j)" + """ = read_argument_string_maybe(args[j]);
                                """);
                                break;
                            case "int":
                                contents += prettyformat("""
                                int64 val;
                                val = read_argument_int64_notnull(args[j]);
                                if (val > int.MAX || val < int.MIN)
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                                arg""" + @"$(j)" + """ = (int)val;
                                """);
                                break;
                            case "uint16":
                                contents += prettyformat("""
                                int64 val;
                                val = read_argument_int64_notnull(args[j]);
                                if (val > uint16.MAX || val < uint16.MIN)
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of uint16");
                                arg""" + @"$(j)" + """ = (uint16)val;
                                """);
                                break;
                            case "int?":
                                error("not implemented yet");
                            case "Gee.List<int>":
                                contents += prettyformat("""
                                Gee.List<int64?> values;
                                values = read_argument_array_of_int64(args[j]);
                                arg""" + @"$(j)" + """ = new ArrayList<int>();
                                foreach (int64 val in values)
                                {
                                    if (val > int.MAX || val < int.MIN)
                                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                                    arg""" + @"$(j)" + """.add((int)val);
                                }
                                """);
                                break;
                            default:
                                if (type_is_basic(arg.argclass)) error(@"not implemented yet $(arg.argclass)");
                                if (arg.argclass.has_prefix("Gee.List<"))
                                {
                                    if (arg.argclass.has_suffix("?")) error(@"not supported nullable list: $(arg.argclass)");
                                    if (arg.argclass.has_suffix("?>")) error(@"not supported list of nullable: $(arg.argclass)");
                                    if (!arg.argclass.has_suffix(">")) error(@"not supported type: $(arg.argclass)");
                                    string eltype = arg.argclass.substring(9, arg.argclass.length-10);
                                    contents += prettyformat("""
                                Gee.List<Object> values;
                                values = read_argument_array_of_object(typeof(""" + eltype + """), args[j]);
                                foreach (Object val in values) if (val is ISerializable)
                                    if (!((ISerializable)val).check_deserialization())
                                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                                arg""" + @"$(j)" + """ = (Gee.List<""" + eltype + """>)values;
                                    """);
                                }
                                else if (arg.argclass.has_suffix("?"))
                                {
                                    string eltype = arg.argclass.substring(0, me.returntype.length-1);
                                    contents += prettyformat("""
                                Object? val;
                                val = read_argument_object_maybe(typeof(""" + eltype + """), args[j]);
                                if (val == null)
                                {
                                    arg""" + @"$(j)" + """ = null;
                                }
                                else
                                {
                                    if (val is ISerializable)
                                        if (!((ISerializable)val).check_deserialization())
                                            throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                                    arg""" + @"$(j)" + """ = (""" + eltype + """)val;
                                }
                                    """);
                                }
                                else
                                {
                                    contents += prettyformat("""
                                Object val;
                                val = read_argument_object_notnull(typeof(""" + arg.argclass + """), args[j]);
                                if (val is ISerializable)
                                    if (!((ISerializable)val).check_deserialization())
                                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                                arg""" + @"$(j)" + """ = (""" + arg.argclass + """)val;
                                    """);
                                }
                                break;
                        }
                        contents += prettyformat("""
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            j++;
                        }
                        """);
                    }
                }
                contents += prettyformat("""

                """);
                string try_indent = "";
                if (me.errors.size > 0)
                {
                    try_indent = "    ";
                    contents += prettyformat("""
                        try {
                    """);
                }
                string args_call = "(";
                for (int j = 0; j < me.args.size; j++) args_call += @"arg$(j), ";
                args_call += "caller_info)";
                string method_call = @"$(r.rootname).$(mo.modname).$(me.name)$(args_call);";
                switch (me.returntype)
                {
                    case "void":
                        contents += prettyformat("""
                        """ + try_indent + method_call + """
                        """ + try_indent + """ret = prepare_return_value_null();
                        """);
                        break;
                    case "string":
                        contents += prettyformat("""
                        """ + try_indent + """string result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_string(result);
                        """);
                        break;
                    case "string?":
                        contents += prettyformat("""
                        """ + try_indent + """string? result = """ + method_call + """
                        """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                        """ + try_indent + """else ret = prepare_return_value_string(result);
                        """);
                        break;
                    case "int":
                        contents += prettyformat("""
                        """ + try_indent + """int result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_int64(result);
                        """);
                        break;
                    case "int?":
                        contents += prettyformat("""
                        """ + try_indent + """int? result = """ + method_call + """
                        """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                        """ + try_indent + """else ret = prepare_return_value_int64(result);
                        """);
                        break;
                    case "uint16":
                        contents += prettyformat("""
                        """ + try_indent + """uint16 result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_int64(result);
                        """);
                        break;
                    case "uint16?":
                        contents += prettyformat("""
                        """ + try_indent + """uint16? result = """ + method_call + """
                        """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                        """ + try_indent + """else ret = prepare_return_value_int64(result);
                        """);
                        break;
                    case "bool":
                        contents += prettyformat("""
                        """ + try_indent + """bool result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_boolean(result);
                        """);
                        break;
                    case "bool?":
                        contents += prettyformat("""
                        """ + try_indent + """bool? result = """ + method_call + """
                        """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                        """ + try_indent + """else ret = prepare_return_value_boolean(result);
                        """);
                        break;
                    case "Gee.List<string>":
                        contents += prettyformat("""
                        """ + try_indent + """Gee.List<string> result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_array_of_string(result);
                        """);
                        break;
                    default:
                        if (type_is_basic(me.returntype)) error(@"not implemented yet $(me.returntype)");
                        if (me.returntype.has_prefix("Gee.List<"))
                        {
                            if (me.returntype.has_suffix("?")) error(@"not supported nullable list: $(me.returntype)");
                            if (me.returntype.has_suffix("?>")) error(@"not supported list of nullable: $(me.returntype)");
                            if (!me.returntype.has_suffix(">")) error(@"not supported type: $(me.returntype)");
                            contents += prettyformat("""
                        """ + try_indent + me.returntype + """ result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_array_of_object(result);
                            """);
                        }
                        else if (me.returntype.has_suffix("?"))
                        {
                            error(@"not implemented yet $(me.returntype)");
                        }
                        else
                        {
                            contents += prettyformat("""
                        """ + try_indent + me.returntype + """ result = """ + method_call + """
                        """ + try_indent + """ret = prepare_return_value_object(result);
                            """);
                        }
                        break;
                }
                if (me.errors.size > 0)
                {
                    foreach (Exception err in me.errors)
                    {
                        contents += prettyformat("""
                        } catch (""" + err.errdomain + """ e) {
                            string code = "";
                        """);
                        foreach (string code in err.errcodes)
                        {
                            contents += prettyformat(
@"                          if (e is $(err.errdomain).$(code)) code = \"$(code)\";");
                        }
                        contents += prettyformat("""
                            assert(code != "");
                            ret = prepare_error(""" + @"\"$(err.errdomain)\"" + """, code, e.message);
                        """);
                    }
                    contents += prettyformat("""
                        }
                    """);
                }
                contents += prettyformat("""
                    }
                """);
                nextmet = "else ";
            }
            contents += prettyformat("""
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in """ + @"$(r.rootname).$(mo.modname)" + """: \"$(m_name)\"");
                    }
                }
            """);
            nextmod = "else ";
        }
        contents += prettyformat("""
                else
                {
                    throw new InSkeletonDeserializeError.GENERIC(@"Unknown module in """ + r.rootname + """: \"$(m_name)\"");
                }
                return ret;
            }

            public string execute()
            {
                string ret;
                try {
                    ret = execute_or_throw_deserialize();
                } catch(InSkeletonDeserializeError e) {
                    ret = prepare_error("DeserializeError", "GENERIC", e.message);
                }
                return ret;
            }
        }

        """);
        
    }

    contents += prettyformat("""
    """);

    contents += prettyformat("""
        internal class ZcdTcpDelegate : Object, IZcdTcpDelegate
        {
            private IRpcDelegate dlg;
            public ZcdTcpDelegate(IRpcDelegate dlg)
            {
                this.dlg = dlg;
            }

            public IZcdTcpRequestHandler get_new_handler()
            {
                return new ZcdTcpRequestHandler(dlg);
            }

        }

        internal class ZcdTcpRequestHandler : Object, IZcdTcpRequestHandler
        {
            private IRpcDelegate dlg;
            private string m_name;
            private ArrayList<string> args;
            private zcd.ModRpc.TcpCallerInfo? caller_info;
            public ZcdTcpRequestHandler(IRpcDelegate dlg)
            {
                this.dlg = dlg;
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
            }

            public void set_method_name(string m_name)
            {
                this.m_name = m_name;
            }

            public void add_argument(string arg)
            {
                args.add(arg);
            }

            public void set_caller_info(zcd.TcpCallerInfo caller_info)
            {
                this.caller_info = new zcd.ModRpc.TcpCallerInfo(caller_info.my_addr, caller_info.peer_addr);
            }

            public IZcdDispatcher? get_dispatcher()
            {
                IZcdDispatcher ret;
    """);

    string nextroot = "";
    foreach (Root r in roots)
    {
        contents += prettyformat("""
                """ + nextroot + """if (m_name.has_prefix(""" + @"\"$(r.rootname)" + """."))
                {
                    I""" + r.rootclass + """Skeleton? """ + r.rootname + """ = dlg.get_""" + r.rootname + """(caller_info);
                    if (""" + r.rootname + """ == null) ret = null;
                    else ret = new Zcd""" + r.rootclass + """Dispatcher(""" + r.rootname + """, m_name, args, caller_info);
                }
        """);
        nextroot = "else ";
    }

    contents += prettyformat("""
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
                return ret;
            }

        }

        public class UnicastCallerInfo : CallerInfo
        {
            internal UnicastCallerInfo(string dev, string peer_address, UnicastID unicastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.unicastid = unicastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public UnicastID unicastid {get; private set;}
        }

        public class BroadcastCallerInfo : CallerInfo
        {
            internal BroadcastCallerInfo(string dev, string peer_address, BroadcastID broadcastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.broadcastid = broadcastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public BroadcastID broadcastid {get; private set;}
        }

        internal class ZcdUdpRequestMessageDelegate : Object, IZcdUdpRequestMessageDelegate
        {
            private IRpcDelegate dlg;
            public ZcdUdpRequestMessageDelegate(IRpcDelegate dlg)
            {
                this.dlg = dlg;
            }

            public IZcdDispatcher? get_dispatcher_unicast(
                int id, string unicast_id,
                string m_name, Gee.List<string> arguments,
                zcd.UdpCallerInfo caller_info)
            {
                // deserialize UnicastID unicastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(UnicastID), unicast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for unicast_id: $(e.message)");
                    error(   @" unicast_id: $(unicast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    return null;
                }
                if (val is ISerializable)
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        return null;
                    }
                UnicastID unicastid = (UnicastID)val;
                // call delegate
                UnicastCallerInfo my_caller_info = new UnicastCallerInfo(caller_info.dev, caller_info.peer_addr, unicastid);
                IZcdDispatcher ret;
    """);

    nextroot = "";
    foreach (Root r in roots)
    {
        contents += prettyformat("""
                """ + nextroot + """if (m_name.has_prefix(""" + @"\"$(r.rootname)" + """."))
                {
                    I""" + r.rootclass + """Skeleton? """ + r.rootname + """ = dlg.get_""" + r.rootname + """(my_caller_info);
                    if (""" + r.rootname + """ == null) ret = null;
                    else ret = new Zcd""" + r.rootclass + """Dispatcher(""" + r.rootname + """, m_name, arguments, my_caller_info);
                }
        """);
        nextroot = "else ";
    }

    contents += prettyformat("""
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }

            public IZcdDispatcher? get_dispatcher_broadcast(
                int id, string broadcast_id,
                string m_name, Gee.List<string> arguments,
                zcd.UdpCallerInfo caller_info)
            {
                // deserialize BroadcastID broadcastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(BroadcastID), broadcast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for broadcast_id: $(e.message)");
                    error(   @" broadcast_id: $(broadcast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    return null;
                }
                if (val is ISerializable)
                    if (!((ISerializable)val).check_deserialization())
                        // couldn't verify if it's for me
                        return null;
                BroadcastID broadcastid = (BroadcastID)val;
                // call delegate
                BroadcastCallerInfo my_caller_info = new BroadcastCallerInfo(caller_info.dev, caller_info.peer_addr, broadcastid);
                IZcdDispatcher ret;
    """);

    nextroot = "";
    foreach (Root r in roots)
    {
        contents += prettyformat("""
                """ + nextroot + """if (m_name.has_prefix(""" + @"\"$(r.rootname)" + """."))
                {
                    I""" + r.rootclass + """Skeleton? """ + r.rootname + """ = dlg.get_""" + r.rootname + """(my_caller_info);
                    if (""" + r.rootname + """ == null) ret = null;
                    else ret = new Zcd""" + r.rootclass + """Dispatcher(""" + r.rootname + """, m_name, arguments, my_caller_info);
                }
        """);
        nextroot = "else ";
    }

    contents += prettyformat("""
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }
        }

        public IZcdTaskletHandle tcp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string? my_addr=null)
        {
            return zcd.tcp_listen(new ZcdTcpDelegate(dlg), new ZcdTcpAcceptErrorHandler(err), port, my_addr);
        }

        public IZcdTaskletHandle udp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string dev)
        {
            if (map_udp_listening == null) map_udp_listening = new HashMap<string, ZcdUdpServiceMessageDelegate>();
            string k_map = @"$(dev):$(port)";
            ZcdUdpRequestMessageDelegate del_req = new ZcdUdpRequestMessageDelegate(dlg);
            ZcdUdpServiceMessageDelegate del_ser = new ZcdUdpServiceMessageDelegate();
            ZcdUdpCreateErrorHandler del_err = new ZcdUdpCreateErrorHandler(err, k_map);
            map_udp_listening[k_map] = del_ser;
            return zcd.udp_listen(del_req, del_ser, del_err, port, dev);
        }
    }
}
    """);

    write_file("sample_skeleton.vala", contents);
}

