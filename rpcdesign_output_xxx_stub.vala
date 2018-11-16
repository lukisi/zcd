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

void output_xxx_stub(Root r, Gee.List<Exception> errors)
{
    /*
     * start flow:
            string contents = prettyformat("""
     * break flow:
            """);
            contents += prettyformat("""
     * reopen flow:
            contents += prettyformat("""
            """);
     * insert variable:
            """ + @"$(j)" + """
    */
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
    public interface I""" + @"$(mo.modclass)" + """Stub : Object
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
        public abstract """ + @"$(signature)" + """;
            """);
        }
        contents += prettyformat("""
    }

        """);
    }
    contents += prettyformat("""
    public interface I""" + @"$(r.rootclass)" + """Stub : Object
    {
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        protected abstract unowned I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """_getter();
        public I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """ {get {return """ + @"$(mo.modname)" + """_getter();}}
        """);
    }
    contents += prettyformat("""
    }

    public I""" + @"$(r.rootclass)" + """Stub get_""" + @"$(r.rootname)" + """_stream_net(
        string peer_ip, uint16 tcp_port,
        ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
        bool wait_reply)
    {
        return new StreamNet""" + @"$(r.rootclass)" + """Stub(peer_ip, tcp_port,
            source_id, unicast_id, src_nic,
            wait_reply);
    }

    public I""" + @"$(r.rootclass)" + """Stub get_""" + @"$(r.rootname)" + """_stream_system(
        string send_pathname,
        ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
        bool wait_reply)
    {
        return new StreamSystem""" + @"$(r.rootclass)" + """Stub(send_pathname,
            source_id, unicast_id, src_nic,
            wait_reply);
    }

    public I""" + @"$(r.rootclass)" + """Stub get_""" + @"$(r.rootname)" + """_datagram_net(
        string my_dev, uint16 udp_port,
        int packet_id,
        ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
        IAckCommunicator? notify_ack=null)
    {
        return new DatagramNet""" + @"$(r.rootclass)" + """Stub(my_dev, udp_port,
            source_id, broadcast_id, src_nic,
            notify_ack);
    }

    public I""" + @"$(r.rootclass)" + """Stub get_""" + @"$(r.rootname)" + """_datagram_system(
        string send_pathname,
        int packet_id,
        ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
        IAckCommunicator? notify_ack=null)
    {
        return new DatagramSystem""" + @"$(r.rootclass)" + """Stub(send_pathname,
            source_id, broadcast_id, src_nic,
            notify_ack);
    }

    internal class StreamNet""" + @"$(r.rootclass)" + """Stub : Object, I""" + @"$(r.rootclass)" + """Stub
    {
        private string s_source_id;
        private string s_unicast_id;
        private string s_src_nic;
        private string peer_ip;
        private uint16 tcp_port;
        private bool wait_reply;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        private """ + @"$(mo.modclass)" + """Remote _""" + @"$(mo.modname)" + """;
        """);
    }
    contents += prettyformat("""
        public StreamNet""" + @"$(r.rootclass)" + """Stub(
            string peer_ip, uint16 tcp_port,
            ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
            bool wait_reply)
        {
            s_source_id = prepare_direct_object(source_id);
            s_unicast_id = prepare_direct_object(unicast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.peer_ip = peer_ip;
            this.tcp_port = tcp_port;
            this.wait_reply = wait_reply;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
            _""" + @"$(mo.modname)" + """ = new """ + @"$(mo.modclass)" + """Remote(this.call);
        """);
    }
    contents += prettyformat("""
        }

    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        protected unowned I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """_getter()
        {
            return _""" + @"$(mo.modname)" + """;
        }

        """);
    }
    contents += prettyformat("""
        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            string ret =
                zcd.send_stream_net(
                peer_ip, tcp_port,
                s_source_id, s_src_nic, s_unicast_id, m_name, arguments,
                wait_reply);
            if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
            return ret;
        }
    }

    internal class StreamSystem""" + @"$(r.rootclass)" + """Stub : Object, I""" + @"$(r.rootclass)" + """Stub
    {
        private string s_source_id;
        private string s_unicast_id;
        private string s_src_nic;
        private string send_pathname;
        private bool wait_reply;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        private """ + @"$(mo.modclass)" + """Remote _""" + @"$(mo.modname)" + """;
        """);
    }
    contents += prettyformat("""
        public StreamSystem""" + @"$(r.rootclass)" + """Stub(
            string send_pathname,
            ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
            bool wait_reply)
        {
            s_source_id = prepare_direct_object(source_id);
            s_unicast_id = prepare_direct_object(unicast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.send_pathname = send_pathname;
            this.wait_reply = wait_reply;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
            _""" + @"$(mo.modname)" + """ = new """ + @"$(mo.modclass)" + """Remote(this.call);
        """);
    }
    contents += prettyformat("""
        }

    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        protected unowned I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """_getter()
        {
            return _""" + @"$(mo.modname)" + """;
        }

        """);
    }
    contents += prettyformat("""
        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            string ret =
                zcd.send_stream_system(
                send_pathname,
                s_source_id, s_src_nic, s_unicast_id, m_name, arguments,
                wait_reply);
            if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
            return ret;
        }
    }

    internal class DatagramNet""" + @"$(r.rootclass)" + """Stub : Object, I""" + @"$(r.rootclass)" + """Stub
    {
        private string s_source_id;
        private string s_broadcast_id;
        private string s_src_nic;
        private string my_dev;
        private uint16 udp_port;
        private IAckCommunicator? notify_ack;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        private """ + @"$(mo.modclass)" + """Remote _""" + @"$(mo.modname)" + """;
        """);
    }
    contents += prettyformat("""
        public DatagramNet""" + @"$(r.rootclass)" + """Stub(
            string my_dev, uint16 udp_port,
            ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
            IAckCommunicator? notify_ack=null)
        {
            s_source_id = prepare_direct_object(source_id);
            s_broadcast_id = prepare_direct_object(broadcast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.my_dev = my_dev;
            this.udp_port = udp_port;
            this.notify_ack = notify_ack;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
            _""" + @"$(mo.modname)" + """ = new """ + @"$(mo.modclass)" + """Remote(this.call);
        """);
    }
    contents += prettyformat("""
        }

    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        protected unowned I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """_getter()
        {
            return _""" + @"$(mo.modname)" + """;
        }

        """);
    }
    contents += prettyformat("""
        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            IChannel ch = tasklet.get_channel();
            int packet_id = Random.int_range(0, int.MAX);
            string k_map = @"$(my_dev):$(udp_port)";

            if (notify_ack != null)
            {
                assert(map_datagram_listening != null && map_datagram_listening.has_key(k_map));
                DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                datagram_dlg.going_to_send_broadcast_with_ack(packet_id, ch);
            }
            else
            {
                if (map_datagram_listening != null && map_datagram_listening.has_key(k_map))
                {
                    DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                    datagram_dlg.going_to_send_broadcast_no_ack(packet_id);
                }
            }

            zcd.send_datagram_net(
                my_dev, udp_port,
                packet_id,
                s_source_id, s_src_nic, s_broadcast_id, m_name, arguments,
                notify_ack!=null);

            if (notify_ack != null)  // and no error was thrown before...
            {
                tasklet.spawn(new NotifyAckTasklet(notify_ack, ch));
            }
            // This implementation of FakeRmt will never return a value.
            throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
        }
    }

    internal class DatagramSystem""" + @"$(r.rootclass)" + """Stub : Object, I""" + @"$(r.rootclass)" + """Stub
    {
        private string s_source_id;
        private string s_broadcast_id;
        private string s_src_nic;
        private string send_pathname;
        private IAckCommunicator? notify_ack;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        private """ + @"$(mo.modclass)" + """Remote _""" + @"$(mo.modname)" + """;
        """);
    }
    contents += prettyformat("""
        public DatagramSystem""" + @"$(r.rootclass)" + """Stub(
            string send_pathname,
            ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
            IAckCommunicator? notify_ack=null)
        {
            s_source_id = prepare_direct_object(source_id);
            s_broadcast_id = prepare_direct_object(broadcast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.send_pathname = send_pathname;
            this.notify_ack = notify_ack;
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
            _""" + @"$(mo.modname)" + """ = new """ + @"$(mo.modclass)" + """Remote(this.call);
        """);
    }
    contents += prettyformat("""
        }

    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        protected unowned I""" + @"$(mo.modclass)" + """Stub """ + @"$(mo.modname)" + """_getter()
        {
            return _""" + @"$(mo.modname)" + """;
        }

        """);
    }
    contents += prettyformat("""
        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            IChannel ch = tasklet.get_channel();
            int packet_id = Random.int_range(0, int.MAX);
            string k_map = @"$(send_pathname)";

            if (notify_ack != null)
            {
                assert(map_datagram_listening != null && map_datagram_listening.has_key(k_map));
                DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                datagram_dlg.going_to_send_broadcast_with_ack(packet_id, ch);
            }
            else
            {
                if (map_datagram_listening != null && map_datagram_listening.has_key(k_map))
                {
                    DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                    datagram_dlg.going_to_send_broadcast_no_ack(packet_id);
                }
            }

            zcd.send_datagram_system(
                send_pathname,
                packet_id,
                s_source_id, s_src_nic, s_broadcast_id, m_name, arguments,
                notify_ack!=null);

            if (notify_ack != null)  // and no error was thrown before...
            {
                tasklet.spawn(new NotifyAckTasklet(notify_ack, ch));
            }
            // This implementation of FakeRmt will never return a value.
            throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
        }
    }
    """);
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""

    internal class """ + @"$(mo.modclass)" + """Remote : Object, I""" + @"$(mo.modclass)" + """Stub
    {
        private unowned FakeRmt rmt;
        public """ + @"$(mo.modclass)" + """Remote(FakeRmt rmt)
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

        public """ + @"$(signature)" + """
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
                    case "int64":
                        contents += prettyformat("""
                args.add(prepare_argument_int64(arg""" + @"$(j)" + """));
                        """);
                        break;
                    case "int?":
                    case "int64?":
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
            catch (zcd.ZCDError e) {
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
    contents += prettyformat("""
}
    """);
    write_file(@"$(r.rootname)_stub.vala", contents);
}