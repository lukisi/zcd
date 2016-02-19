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

void make_sample_stub(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;
using zcd;

namespace SampleRpc
{
    """);

    foreach (Root r in roots)
    {
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
        public interface I""" + mo.modclass + """Stub : Object
        {
            """);
            foreach (Method me in mo.methods)
            {
                string signature = @"$(me.returntype) $(me.name)(";
                string nextarg = "";
                foreach (Argument arg in me.args)
                {
                    signature += @"$(nextarg)$(arg.argclass) $(arg.argname)";
                    nextarg = ", ";
                }
                signature += ") throws ";
                foreach (Exception exc in me.errors)
                {
                    signature += @"$(exc.errdomain), ";
                }
                signature += "StubError, DeserializeError";
                contents += prettyformat("""
            public abstract """ + signature + """;
                """);
            }
            contents += prettyformat("""
        }

            """);
        }
        contents += prettyformat("""
        public interface I""" + r.rootclass + """Stub : Object
        {
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            protected abstract unowned I""" + mo.modclass + """Stub """ + mo.modname + """_getter();
            public I""" + mo.modclass + """Stub """ + mo.modname + """ {get {return """ + mo.modname + """_getter();}}
            """);
        }
        contents += prettyformat("""
        }

        """);
    }

    foreach (Root r in roots)
    {
        contents += prettyformat("""
        public I""" + r.rootclass + """Stub get_""" + r.rootname + """_tcp_client(string peer_address, uint16 peer_port, ISourceID source_id, IUnicastID unicast_id)
        {
            return new """ + r.rootclass + """TcpClientRootStub(peer_address, peer_port, source_id, unicast_id);
        }

        """);
    }
    foreach (Root r in roots)
    {
        contents += prettyformat("""
        internal class """ + r.rootclass + """TcpClientRootStub : Object, I""" + r.rootclass + """Stub, ITcpClientRootStub
        {
            private TcpClient client;
            private string peer_address;
            private uint16 peer_port;
            private string s_source_id;
            private string s_unicast_id;
            private bool hurry;
            private bool wait_reply;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            private """ + mo.modclass + """Remote _""" + mo.modname + """;
            """);
        }
        contents += prettyformat("""
            public """ + r.rootclass + """TcpClientRootStub(string peer_address, uint16 peer_port, ISourceID source_id, IUnicastID unicast_id)
            {
                this.peer_address = peer_address;
                this.peer_port = peer_port;
                s_source_id = prepare_direct_object(source_id);
                s_unicast_id = prepare_direct_object(unicast_id);
                client = tcp_client(peer_address, peer_port, s_source_id, s_unicast_id);
                hurry = false;
                wait_reply = true;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
                _""" + mo.modname + """ = new """ + mo.modclass + """Remote(this.call);
            """);
        }
        contents += prettyformat("""
            }

            public bool hurry_getter()
            {
                return hurry;
            }

            public void hurry_setter(bool new_value)
            {
                hurry = new_value;
            }

            public bool wait_reply_getter()
            {
                return wait_reply;
            }

            public void wait_reply_setter(bool new_value)
            {
                wait_reply = new_value;
            }

        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            protected unowned I""" + mo.modclass + """Stub """ + mo.modname + """_getter()
            {
                return _""" + mo.modname + """;
            }

            """);
        }
        contents += prettyformat("""
            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                if (hurry && !client.is_queue_empty())
                {
                    client = tcp_client(peer_address, peer_port, s_source_id, s_unicast_id);
                }
                // TODO See destructor of TcpClient. If the low level library ZCD is able to ensure
                //  that the destructor is not called when a call is in progress, then this
                //  local_reference is not needed.
                TcpClient local_reference = client;
                string ret = local_reference.enqueue_call(m_name, arguments, wait_reply);
                if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
                return ret;
            }
        }

        """);
    }

    foreach (Root r in roots)
    {
        contents += prettyformat("""
        public I""" + r.rootclass + """Stub get_""" + r.rootname + """_unicast(string dev, uint16 port, string src_ip, ISourceID source_id, IUnicastID unicast_id, bool wait_reply)
        {
            return new """ + r.rootclass + """UnicastRootStub(dev, port, src_ip, source_id, unicast_id, wait_reply);
        }

        """);
    }
    foreach (Root r in roots)
    {
        contents += prettyformat("""
        internal class """ + r.rootclass + """UnicastRootStub : Object, I""" + r.rootclass + """Stub
        {
            private string s_source_id;
            private string s_unicast_id;
            private string dev;
            private uint16 port;
            private string src_ip;
            private bool wait_reply;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            private """ + mo.modclass + """Remote _""" + mo.modname + """;
            """);
        }
        contents += prettyformat("""
            public """ + r.rootclass + """UnicastRootStub(string dev, uint16 port, string src_ip, ISourceID source_id, IUnicastID unicast_id, bool wait_reply)
            {
                s_source_id = prepare_direct_object(source_id);
                s_unicast_id = prepare_direct_object(unicast_id);
                this.dev = dev;
                this.port = port;
                this.src_ip = src_ip;
                this.wait_reply = wait_reply;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
                _""" + mo.modname + """ = new """ + mo.modclass + """Remote(this.call);
            """);
        }
        contents += prettyformat("""
            }

        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            protected unowned I""" + mo.modclass + """Stub """ + mo.modname + """_getter()
            {
                return _""" + mo.modname + """;
            }

            """);
        }
        contents += prettyformat("""
            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                return call_unicast_udp(m_name, arguments, dev, port, src_ip, s_source_id, s_unicast_id, wait_reply);
            }
        }

        """);
    }

    foreach (Root r in roots)
    {
        contents += prettyformat("""
        public I""" + r.rootclass + """Stub get_""" + r.rootname + """_broadcast
        (Gee.List<string> devs, Gee.List<string> src_ips, uint16 port, ISourceID source_id, IBroadcastID broadcast_id, IAckCommunicator? notify_ack=null)
        {
            return new """ + r.rootclass + """BroadcastRootStub(devs, src_ips, port, source_id, broadcast_id, notify_ack);
        }

        """);
    }
    foreach (Root r in roots)
    {
        contents += prettyformat("""
        internal class """ + r.rootclass + """BroadcastRootStub : Object, I""" + r.rootclass + """Stub
        {
            private string s_source_id;
            private string s_broadcast_id;
            private Gee.List<string> devs;
            private Gee.List<string> src_ips;
            private uint16 port;
            private IAckCommunicator? notify_ack;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            private """ + mo.modclass + """Remote _""" + mo.modname + """;
            """);
        }
        contents += prettyformat("""
            public """ + r.rootclass + """BroadcastRootStub
            (Gee.List<string> devs, Gee.List<string> src_ips, uint16 port, ISourceID source_id, IBroadcastID broadcast_id, IAckCommunicator? notify_ack=null)
            {
                s_source_id = prepare_direct_object(source_id);
                s_broadcast_id = prepare_direct_object(broadcast_id);
                this.devs = new ArrayList<string>();
                this.devs.add_all(devs);
                this.src_ips = new ArrayList<string>();
                this.src_ips.add_all(src_ips);
                this.port = port;
                this.notify_ack = notify_ack;
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
                _""" + mo.modname + """ = new """ + mo.modclass + """Remote(this.call);
            """);
        }
        contents += prettyformat("""
            }

        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
            protected unowned I""" + mo.modclass + """Stub """ + mo.modname + """_getter()
            {
                return _""" + mo.modname + """;
            }

            """);
        }
        contents += prettyformat("""
            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                return call_broadcast_udp(m_name, arguments, devs, src_ips, port, s_source_id, s_broadcast_id, notify_ack);
            }
        }

        """);
    }

    foreach (Root r in roots)
    {
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
        internal class """ + mo.modclass + """Remote : Object, I""" + mo.modclass + """Stub
        {
            private unowned FakeRmt rmt;
            public """ + mo.modclass + """Remote(FakeRmt rmt)
            {
                this.rmt = rmt;
            }

            """);
            foreach (Method me in mo.methods)
            {
                string signature = @"$(me.returntype) $(me.name)(";
                string nextarg = "";
                for (int j = 0; j < me.args.size; j++)
                {
                    Argument arg = me.args[j];
                    signature += @"$(nextarg)$(arg.argclass) arg$(j)";
                    nextarg = ", ";
                }
                signature += ") throws ";
                foreach (Exception exc in me.errors)
                {
                    signature += @"$(exc.errdomain), ";
                }
                signature += "StubError, DeserializeError";
                contents += prettyformat("""
            public """ + signature + """
            {
                string m_name = """ + @"\"$(r.rootname).$(mo.modname).$(me.name)\"" + """;
                ArrayList<string> args = new ArrayList<string>();
                """);
                for (int j = 0; j < me.args.size; j++)
                {
                    Argument arg = me.args[j];
                    contents += prettyformat("""
                {
                    // serialize arg""" + @"$(j)" + """ (""" + arg.argclass + """ """ + arg.argname + """)
                    """);
                    switch (arg.argclass)
                    {
                        case "int":
                            contents += prettyformat("""
                    args.add(prepare_argument_int64(arg""" + @"$(j)" + """));
                            """);
                            break;
                        case "int?":
                            contents += prettyformat("""
                    if (arg""" + @"$(j)" + """ != null)
                        args.add(prepare_argument_int64(arg""" + @"$(j)" + """));
                    else
                        args.add(prepare_argument_null());
                            """);
                            break;
                        case "bool":
                            contents += prettyformat("""
                    args.add(prepare_argument_boolean(arg""" + @"$(j)" + """));
                            """);
                            break;
                        case "bool?":
                            contents += prettyformat("""
                    if (arg""" + @"$(j)" + """ != null)
                        args.add(prepare_argument_boolean(arg""" + @"$(j)" + """));
                    else
                        args.add(prepare_argument_null());
                            """);
                            break;
                        case "uint16":
                            contents += prettyformat("""
                    args.add(prepare_argument_int64(arg""" + @"$(j)" + """));
                            """);
                            break;
                        case "uint16?":
                            contents += prettyformat("""
                    if (arg""" + @"$(j)" + """ != null)
                        args.add(prepare_argument_int64(arg""" + @"$(j)" + """));
                    else
                        args.add(prepare_argument_null());
                            """);
                            break;
                        case "string":
                            contents += prettyformat("""
                    args.add(prepare_argument_string(arg""" + @"$(j)" + """));
                            """);
                            break;
                        case "string?":
                            contents += prettyformat("""
                    if (arg""" + @"$(j)" + """ != null)
                        args.add(prepare_argument_string(arg""" + @"$(j)" + """));
                    else
                        args.add(prepare_argument_null());
                            """);
                            break;
                        case "Gee.List<int>":
                            contents += prettyformat("""
                    ArrayList<int64?> lst = new ArrayList<int64?>();
                    foreach (int el_i in arg""" + @"$(j)" + """) lst.add(el_i);
                    args.add(prepare_argument_array_of_int64(lst));
                            """);
                            break;
                        default:
                            if (type_is_basic(arg.argclass)) error(@"not implemented yet $(arg.argclass)");
                            if (arg.argclass.has_prefix("Gee.List<"))
                            {
                                if (arg.argclass.has_suffix("?")) error(@"not supported nullable list: $(arg.argclass)");
                                if (arg.argclass.has_suffix("?>")) error(@"not supported list of nullable: $(arg.argclass)");
                                if (!arg.argclass.has_suffix(">")) error(@"not supported type: $(arg.argclass)");
                                contents += prettyformat("""
                    args.add(prepare_argument_array_of_object(arg""" + @"$(j)" + """));
                                """);
                            }
                            else if (arg.argclass.has_suffix("?"))
                            {
                                contents += prettyformat("""
                    if (arg""" + @"$(j)" + """ != null)
                        args.add(prepare_argument_object(arg""" + @"$(j)" + """));
                    else
                        args.add(prepare_argument_null());
                                """);
                            }
                            else
                            {
                                contents += prettyformat("""
                    args.add(prepare_argument_object(arg""" + @"$(j)" + """));
                                """);
                            }
                            break;
                    }
                    contents += prettyformat("""
                }
                    """);
                }
                contents += prettyformat("""

                string resp;
                try {
                    resp = rmt(m_name, args);
                }
                catch (ZCDError e) {
                    throw new StubError.GENERIC(e.message);
                }
                """);
                if (me.returntype == "void")
                {
                    contents += prettyformat("""
                // The following catch is to be added only for methods that return void.
                catch (StubError.DID_NOT_WAIT_REPLY e) {return;}
                    """);
                }
                contents += prettyformat("""

                // deserialize response
                string? error_domain = null;
                string? error_code = null;
                string? error_message = null;
                string doing = @"Reading return-value of $(m_name)";
                """);
                switch (me.returntype)
                {
                    case "void":
                        contents += prettyformat("""
                try {
                    read_return_value_void(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "string":
                        contents += prettyformat("""
                string ret;
                try {
                    ret = read_return_value_string_notnull(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "string?":
                        contents += prettyformat("""
                string? ret;
                try {
                    ret = read_return_value_string_maybe(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "int":
                        contents += prettyformat("""
                int ret;
                int64 val;
                try {
                    val = read_return_value_int64_notnull(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "int?":
                        contents += prettyformat("""
                int? ret;
                int64? val;
                try {
                    val = read_return_value_int64_maybe(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "uint16":
                        contents += prettyformat("""
                uint16 ret;
                int64 val;
                try {
                    val = read_return_value_int64_notnull(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "uint16?":
                        contents += prettyformat("""
                uint16? ret;
                int64? val;
                try {
                    val = read_return_value_int64_maybe(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "bool":
                        contents += prettyformat("""
                bool ret;
                try {
                    ret = read_return_value_bool_notnull(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "bool?":
                        contents += prettyformat("""
                bool? ret;
                try {
                    ret = read_return_value_bool_maybe(resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    case "Gee.List<string>":
                        contents += prettyformat("""
                Gee.List<string> ret;
                try {
                    ret = read_return_value_array_of_string
                        (resp, out error_domain, out error_code, out error_message);
                        """);
                        break;
                    default:
                        if (type_is_basic(me.returntype)) error(@"not implemented yet $(me.returntype)");
                        if (me.returntype.has_prefix("Gee.List<"))
                        {
                            if (me.returntype.has_suffix("?")) error(@"not supported nullable list: $(me.returntype)");
                            if (me.returntype.has_suffix("?>")) error(@"not supported list of nullable: $(me.returntype)");
                            if (!me.returntype.has_suffix(">")) error(@"not supported type: $(me.returntype)");
                            string eltype = me.returntype.substring(9, me.returntype.length-10);
                            contents += prettyformat("""
                Gee.List<""" + eltype + """> ret;
                try {
                    ret = (Gee.List<""" + eltype + """>)
                        read_return_value_array_of_object
                        (typeof(""" + eltype + """), resp, out error_domain, out error_code, out error_message);
                            """);
                        }
                        else if (me.returntype.has_suffix("?"))
                        {
                            string eltype = me.returntype.substring(0, me.returntype.length-1);
                            contents += prettyformat("""
                Object? ret;
                try {
                    ret = read_return_value_object_maybe(typeof(""" + eltype + """), resp, out error_domain, out error_code, out error_message);
                            """);
                        }
                        else
                        {
                            contents += prettyformat("""
                Object ret;
                try {
                    ret = read_return_value_object_notnull(typeof(""" + me.returntype + """), resp, out error_domain, out error_code, out error_message);
                            """);
                        }
                        break;
                }
                contents += prettyformat("""
                } catch (HelperNotJsonError e) {
                    error(@"Error parsing JSON for return-value of $(m_name): $(e.message)");
                } catch (HelperDeserializeError e) {
                    throw new DeserializeError.GENERIC(@"$(doing): $(e.message)");
                }
                if (error_domain != null)
                {
                    string error_domain_code = @"$(error_domain).$(error_code)";
                """);
                foreach (Exception err in me.errors)
                {
                    foreach (string errcode in err.errcodes)
                    {
                        contents += prettyformat("""
                    if (error_domain_code == """ + @"\"$(err.errdomain).$(errcode)\"" + """)
                        throw new """ + err.errdomain + """.""" + errcode + """(error_message);
                        """);
                    }
                }
                contents += prettyformat("""
                    if (error_domain_code == "DeserializeError.GENERIC")
                        throw new DeserializeError.GENERIC(error_message);
                """);
                contents += prettyformat("""
                    throw new DeserializeError.GENERIC(@"$(doing): unrecognized error $(error_domain_code) $(error_message)");
                }
                """);
                switch (me.returntype)
                {
                    case "void":
                        contents += prettyformat("""
                return;
                        """);
                        break;
                    case "string":
                        contents += prettyformat("""
                return ret;
                        """);
                        break;
                    case "string?":
                        contents += prettyformat("""
                return ret;
                        """);
                        break;
                    case "int":
                        contents += prettyformat("""
                if (val > int.MAX || val < int.MIN)
                    throw new DeserializeError.GENERIC(@"$(doing): return-value overflows size of int");
                ret = (int)val;
                return ret;
                        """);
                        break;
                    case "int?":
                        contents += prettyformat("""
                if (val == null) ret = null;
                else
                {
                    if (val > int.MAX || val < int.MIN)
                        throw new DeserializeError.GENERIC(@"$(doing): return-value overflows size of int");
                    ret = (int)val;
                }
                return ret;
                        """);
                        break;
                    case "uint16":
                        contents += prettyformat("""
                if (val > uint16.MAX || val < uint16.MIN)
                    throw new DeserializeError.GENERIC(@"$(doing): return-value overflows size of uint16");
                ret = (uint16)val;
                return ret;
                        """);
                        break;
                    case "uint16?":
                        contents += prettyformat("""
                if (val == null) ret = null;
                else
                {
                    if (val > uint16.MAX || val < uint16.MIN)
                        throw new DeserializeError.GENERIC(@"$(doing): return-value overflows size of uint16");
                    ret = (uint16)val;
                }
                return ret;
                        """);
                        break;
                    case "bool":
                        contents += prettyformat("""
                return ret;
                        """);
                        break;
                    case "bool?":
                        contents += prettyformat("""
                return ret;
                        """);
                        break;
                    case "Gee.List<string>":
                        contents += prettyformat("""
                return ret;
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
                return ret;
                            """);
                        }
                        else if (me.returntype.has_suffix("?"))
                        {
                            string eltype = me.returntype.substring(0, me.returntype.length-1);
                            contents += prettyformat("""
                if (ret == null) return null;
                if (ret is ISerializable)
                    if (!((ISerializable)ret).check_deserialization())
                        throw new DeserializeError.GENERIC(@"$(doing): instance of $(ret.get_type().name()) has not been fully deserialized");
                return (""" + eltype + """)ret;
                            """);
                        }
                        else
                        {
                            contents += prettyformat("""
                if (ret is ISerializable)
                    if (!((ISerializable)ret).check_deserialization())
                        throw new DeserializeError.GENERIC(@"$(doing): instance of $(ret.get_type().name()) has not been fully deserialized");
                return (""" + me.returntype + """)ret;
                            """);
                        }
                        break;
                }
                contents += prettyformat("""
            }

                """);
            }
            contents += prettyformat("""
        }

            """);
        }
    }

    contents += prettyformat("""
}
    """);

    write_file("sample_stub.vala", contents);
}

