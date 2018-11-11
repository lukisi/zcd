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

void output_common_skeleton(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    internal class ErrorHandler : Object, zcd.IErrorHandler
    {
        private IErrorHandler err;
        private string? key_datagram_listening;
        public ErrorHandler(IErrorHandler err, string? key_datagram_listening = null)
        {
            this.err = err;
            this.key_datagram_listening = key_datagram_listening;
        }

        public void error_handler(Error e)
        {
            if (map_datagram_listening != null && key_datagram_listening != null)
                map_datagram_listening.unset(key_datagram_listening);
            err.error_handler(e);
        }
    }

    internal class ListenerHandle : Object, IListenerHandle
    {
        private zcd.IListenerHandle lh;
        private string? key_datagram_listening;
        public ListenerHandle(zcd.IListenerHandle lh, string? key_datagram_listening = null)
        {
            this.lh = lh;
            this.key_datagram_listening = key_datagram_listening;
        }

        public void kill()
        {
            lh.kill();
            if (map_datagram_listening != null && key_datagram_listening != null)
                map_datagram_listening.unset(key_datagram_listening);
        }
    }

    internal class StreamDelegate : Object, zcd.IStreamDelegate
    {
        public StreamDelegate(IDelegate dlg)
        {
            this.dlg = dlg;
        }
        private IDelegate dlg;

        public zcd.IStreamDispatcher? get_dispatcher(zcd.StreamCallerInfo caller_info)
        {
            StreamCallerInfo mod_caller_info;
            try {
                mod_caller_info = new StreamCallerInfo(caller_info);
            } catch (HelperDeserializeError e) {
                warning(@"Error deserializing parts of zcd.StreamCallerInfo: $(e.message)");
                tasklet.exit_tasklet();
            }
    """);
    string s_if = "if";
    foreach (Root r in roots)
    {
        contents += prettyformat("""
            """ + @"$(s_if)" + """ (mod_caller_info.m_name.has_prefix("""" + @"$(r.rootname)" + """."))
            {
                Gee.List<I""" + @"$(r.rootclass)" + """Skeleton> """ + @"$(r.rootname)" + """_set = dlg.get_""" + @"$(r.rootname)" + """_set(mod_caller_info);
                if (""" + @"$(r.rootname)" + """_set.is_empty) return null;
                assert(""" + @"$(r.rootname)" + """_set.size == 1);
                return new """ + @"$(r.rootclass)" + """StreamDispatcher(""" + @"$(r.rootname)" + """_set[0]);
            }
        """);
        s_if = "else if";
    }
    contents += prettyformat("""
            else
            {
                return new StreamDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(mod_caller_info.m_name)\"");
            }
        }
    }

    internal class StreamDispatcherForError : Object, zcd.IStreamDispatcher
    {
        private string domain;
        private string code;
        private string message;
        public StreamDispatcherForError(string domain, string code, string message)
        {
            this.domain = domain;
            this.code = code;
            this.message = message;
        }

        public string execute(string m_name, Gee.List<string> args, zcd.StreamCallerInfo caller_info)
        {
            return prepare_error(domain, code, message);
        }
    }

    internal const int ack_timeout_msec = 3000;
    internal HashMap<string, DatagramDelegate>? map_datagram_listening = null;
    internal class DatagramDelegate : Object, zcd.IDatagramDelegate
    {
        public DatagramDelegate(IDelegate dlg)
        {
            this.dlg = dlg;
            waiting_for_ack = new HashMap<int, WaitingForAck>();
            waiting_for_recv = new HashMap<int, WaitingForRecv>();
        }
        private IDelegate dlg;

        private class WaitingForAck : Object, ITaskletSpawnable
        {
            public WaitingForAck(DatagramDelegate parent, int packet_id, IChannel ch)
            {
                this.parent = parent;
                this.packet_id = packet_id;
                this.ch = ch;
                src_nics_list = new ArrayList<string>();
            }
            private DatagramDelegate parent;
            private int packet_id;
            private IChannel ch;
            public ArrayList<string> src_nics_list {get; private set;}
            public void* func()
            {
                tasklet.ms_wait(ack_timeout_msec);
                // report 'src_nics_list' through 'ch'
                ch.send_async(src_nics_list);
                parent.waiting_for_ack.unset(packet_id);
                return null;
            }
        }
        private HashMap<int, WaitingForAck> waiting_for_ack;

        private class WaitingForRecv : Object, ITaskletSpawnable
        {
            public WaitingForRecv(DatagramDelegate parent, int packet_id)
            {
                this.parent = parent;
                this.packet_id = packet_id;
            }
            private DatagramDelegate parent;
            private int packet_id;
            public void* func()
            {
                tasklet.ms_wait(ack_timeout_msec);
                parent.waiting_for_recv.unset(packet_id);
                return null;
            }
        }
        private HashMap<int, WaitingForRecv> waiting_for_recv;

        internal void going_to_send_broadcast_with_ack(int packet_id, IChannel ch)
        {
            var w = new WaitingForAck(this, packet_id, ch);
            tasklet.spawn(w);
            waiting_for_ack[packet_id] = w;
        }

        internal void going_to_send_broadcast_no_ack(int packet_id)
        {
            var w = new WaitingForRecv(this, packet_id);
            tasklet.spawn(w);
            waiting_for_recv[packet_id] = w;
        }

        public void got_ack(int packet_id, string src_nic)
        {
            if (waiting_for_ack.has_key(packet_id))
            {
                if (! (src_nic in waiting_for_ack[packet_id].src_nics_list))
                    waiting_for_ack[packet_id].src_nics_list.add(src_nic);
            }
        }

        public bool is_my_own_message(int packet_id)
        {
            if (waiting_for_ack.has_key(packet_id)) return true;
            if (waiting_for_recv.has_key(packet_id)) return true;
            return false;
        }

        public zcd.IDatagramDispatcher? get_dispatcher(zcd.DatagramCallerInfo caller_info)
        {
            DatagramCallerInfo mod_caller_info;
            try {
                mod_caller_info = new DatagramCallerInfo(caller_info);
            } catch (HelperDeserializeError e) {
                warning(@"Error deserializing parts of zcd.DatagramCallerInfo: $(e.message)");
                tasklet.exit_tasklet();
            }
    """);
    string s_if2 = "if";
    foreach (Root r in roots)
    {
        contents += prettyformat("""
            """ + @"$(s_if2)" + """ (mod_caller_info.m_name.has_prefix("""" + @"$(r.rootname)" + """."))
            {
                Gee.List<I""" + @"$(r.rootclass)" + """Skeleton> """ + @"$(r.rootname)" + """_set = dlg.get_""" + @"$(r.rootname)" + """_set(mod_caller_info);
                if (""" + @"$(r.rootname)" + """_set.is_empty) return null;
                else return new """ + @"$(r.rootclass)" + """DatagramDispatcher(""" + @"$(r.rootname)" + """_set);
            }
        """);
        s_if2 = "else if";
    }
    contents += prettyformat("""
            else
            {
                return new DatagramDispatcherForError(); // or just terminate this tasklet
            }
        }
    }

    internal class DatagramDispatcherForError : Object, zcd.IDatagramDispatcher
    {
        public void execute(string m_name, Gee.List<string> args, zcd.DatagramCallerInfo caller_info)
        {
        }
    }

    internal errordomain InSkeletonDeserializeError {
        GENERIC
    }

    public IListenerHandle stream_net_listen(IDelegate dlg, IErrorHandler err, string my_ip, uint16 tcp_port)
    {
        zcd.IListenerHandle lh =
            zcd.stream_net_listen(my_ip, tcp_port, new StreamDelegate(dlg), new ErrorHandler(err));
        return new ListenerHandle(lh);
    }

    public IListenerHandle stream_system_listen(IDelegate dlg, IErrorHandler err, string listen_pathname)
    {
        zcd.IListenerHandle lh =
            zcd.stream_system_listen(listen_pathname, new StreamDelegate(dlg), new ErrorHandler(err));
        return new ListenerHandle(lh);
    }

    public IListenerHandle datagram_net_listen(IDelegate dlg, IErrorHandler err, string my_dev, uint16 udp_port, string src_nic)
    {
        if (map_datagram_listening == null)
            map_datagram_listening = new HashMap<string, DatagramDelegate>();
        DatagramDelegate datagram_dlg = new DatagramDelegate(dlg);
        string key = @"$(my_dev):$(udp_port)";
        map_datagram_listening[key] = datagram_dlg;
        zcd.IListenerHandle lh =
            zcd.datagram_net_listen(my_dev, udp_port, src_nic, datagram_dlg, new ErrorHandler(err, key));
        return new ListenerHandle(lh, key);
    }

    public IListenerHandle datagram_system_listen(IDelegate dlg, IErrorHandler err, string listen_pathname, string send_pathname, string src_nic)
    {
        if (map_datagram_listening == null)
            map_datagram_listening = new HashMap<string, DatagramDelegate>();
        DatagramDelegate datagram_dlg = new DatagramDelegate(dlg);
        string key = @"$(send_pathname)";
        map_datagram_listening[key] = datagram_dlg;
        zcd.IListenerHandle lh =
            zcd.datagram_system_listen(listen_pathname, send_pathname, src_nic, datagram_dlg, new ErrorHandler(err, key));
        return new ListenerHandle(lh, key);
    }
}
    """);
    write_file("common_skeleton.vala", contents);
}