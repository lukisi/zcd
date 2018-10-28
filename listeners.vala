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

namespace zcd
{
    internal class ListenerHandle : Object, IListenerHandle
    {
        private ITaskletHandle th;
        private IListenerTasklet t;
        public ListenerHandle(ITaskletHandle th, IListenerTasklet t)
        {
            this.th = th;
            this.t = t;
        }

        public void kill()
        {
            th.kill();
            t.after_kill();
        }
    }

    internal interface IListenerTasklet : Object, ITaskletSpawnable
    {
        public abstract void after_kill();
    }

    public IListenerHandle stream_net_listen(
        string my_ip, uint16 tcp_port,
        IStreamDelegate stream_dlg,
        IErrorHandler error_handler)
    {
        StreamNetListenerTasklet t = new StreamNetListenerTasklet();
        t.my_ip = my_ip;
        t.tcp_port = tcp_port;
        t.stream_dlg = stream_dlg;
        t.error_handler = error_handler;
        ITaskletHandle th = tasklet.spawn(t);
        var ret = new ListenerHandle(th, t);
        return ret;
    }
    internal class StreamNetListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public string my_ip;
        public uint16 tcp_port;
        public IStreamDelegate stream_dlg;
        public IErrorHandler error_handler;
        private IServerStreamNetworkSocket s;

        public StreamNetListenerTasklet()
        {
            s = null;
        }

        public void * func()
        {
            try {
                s = tasklet.get_server_stream_network_socket(my_ip, tcp_port);
                while (true) {
                    IConnectedStreamSocket c = s.accept();
                    StreamConnectionHandlerTasklet t = new StreamConnectionHandlerTasklet();
                    t.c = c;
                    t.stream_dlg = stream_dlg;
                    t.listener = new StreamNetListener(my_ip, tcp_port);
                    tasklet.spawn(t);
                }
            } catch (Error e) {
                error_handler.error_handler(e.copy());
                cleanup();
                return null;
            }
            assert_not_reached();
            // This function (i.e. the tasklet) will exit after an error (signaled with IErrorHandler)
            // or for a kill.
        }

        public void after_kill()
        {
            // This function should be called only after killing the tasklet.
            assert(s != null);
            cleanup();
        }

        private void cleanup()
        {
            if (s != null)
            {
                try {s.close();} catch (Error e) {}
            }
        }
    }

    public IListenerHandle stream_system_listen(
        string listen_pathname,
        IStreamDelegate stream_dlg,
        IErrorHandler error_handler)
    {
        StreamSystemListenerTasklet t = new StreamSystemListenerTasklet();
        t.listen_pathname = listen_pathname;
        t.stream_dlg = stream_dlg;
        t.error_handler = error_handler;
        ITaskletHandle th = tasklet.spawn(t);
        var ret = new ListenerHandle(th, t);
        return ret;
    }
    internal class StreamSystemListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public string listen_pathname;
        public IStreamDelegate stream_dlg;
        public IErrorHandler error_handler;
        private IServerStreamLocalSocket s;

        public StreamSystemListenerTasklet()
        {
            s = null;
        }

        public void * func()
        {
            try {
                s = tasklet.get_server_stream_local_socket(listen_pathname);
                while (true) {
                    IConnectedStreamSocket c = s.accept();
                    StreamConnectionHandlerTasklet t = new StreamConnectionHandlerTasklet();
                    t.c = c;
                    t.stream_dlg = stream_dlg;
                    t.listener = new StreamSystemListener(listen_pathname);
                    tasklet.spawn(t);
                }
            } catch (Error e) {
                error_handler.error_handler(e.copy());
                cleanup();
                return null;
            }
            assert_not_reached();
            // This function (i.e. the tasklet) will exit after an error (signaled with IErrorHandler)
            // or for a kill.
        }

        public void after_kill()
        {
            // This function should be called only after killing the tasklet.
            assert(s != null);
            cleanup();
        }

        private void cleanup()
        {
            if (s != null)
            {
                try {s.close();} catch (Error e) {}
            }
        }
    }

    internal class StreamConnectionHandlerTasklet : Object, ITaskletSpawnable
    {
        public IConnectedStreamSocket c;
        public IStreamDelegate stream_dlg;

        /* This class (ITaskletSpawnable) should be usable both for `stream_net_listen` and for `stream_system_listen`.
        ** That is why we have a generic `Listener` here:
        **/
        public Listener listener;

        private void *m;

        public void * func()
        {
            m = null;
            while (true)
            {
                if (m != null) free(m);
                // Get one message
                size_t s;
                try {
                    bool got = get_one_message(c, out m, out s);
                    if (!got)
                    {
                        // closed normally, terminate tasklet
                        cleanup();
                        return null;
                    }
                } catch (RecvMessageError e) {
                    // log message
                    warning(@"stream_listener: Error receiving message: $(e.message)");
                    // terminate tasklet
                    cleanup();
                    return null;
                }
                unowned uint8[] buf;
                buf = (uint8[])m;
                buf.length = (int)s;

                // Parse JSON
                string source_id;
                string unicast_id;
                string src_nic;
                string m_name;
                Gee.List<string> args;
                bool wait_reply;
                try {
                    parse_unicast_request(
                        (string)buf,
                        out m_name,
                        out args,
                        out source_id,
                        out unicast_id,
                        out src_nic,
                        out wait_reply);
                } catch (MessageError e) {
                    // log message
                    warning(@"stream_listener: Error parsing JSON of received message: $(e.message)");
                    // terminate tasklet
                    cleanup();
                    return null;
                }

                StreamCallerInfo caller_info = new StreamCallerInfo(
                    source_id, src_nic, unicast_id,
                    m_name, wait_reply, listener);
                IStreamDispatcher? disp = stream_dlg.get_dispatcher(caller_info);
                if (disp == null)
                {
                    // log message
                    warning(@"stream_listener: Delegate stream_dlg did not recognize this message.");
                    // Ignore this msg and terminate tasklet
                    cleanup();
                    return null;
                }
                if (wait_reply)
                {
                    string resp = disp.execute(m_name, args, caller_info);
                    string json_tree_response;
                    try {
                        build_unicast_response(
                            resp,
                            out json_tree_response
                            );
                    } catch (InvalidJsonError e) {
                        error(@"stream_listener: Error building JSON from my own result: $(e.message)");
                    }
                    // Send response
                    try {
                        send_one_message(c, json_tree_response);
                    } catch (SendMessageError e) {
                        // log message
                        warning(@"stream_listener: Error sending JSON of response: $(e.message)");
                        // terminate tasklet
                        cleanup();
                        return null;
                    }
                }
                else
                {
                    StreamDispatchTasklet t = new StreamDispatchTasklet(
                        disp,
                        m_name,
                        args,
                        caller_info);
                    tasklet.spawn(t);
                }
            }
            // point not_reached
        }

        private void cleanup()
        {
            // close connection
            try {c.close();} catch (Error e) {}
            if (m != null) free(m);
        }
    }
    internal class StreamDispatchTasklet : Object, ITaskletSpawnable
    {
        public StreamDispatchTasklet(
            IStreamDispatcher disp,
            string m_name,
            Gee.List<string> args,
            StreamCallerInfo caller_info)
        {
            this.disp = disp;
            this.m_name = m_name;
            this.args = args;
            this.caller_info = caller_info;
        }

        private IStreamDispatcher disp;
        private string m_name;
        private Gee.List<string> args;
        private StreamCallerInfo caller_info;

        public void * func()
        {
            disp.execute(m_name, args, caller_info);
            return null;
        }
    }

    public IListenerHandle datagram_net_listen(
        string my_dev, uint16 udp_port, string ack_mac,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
    }
    internal class DatagramNetListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public void * func()
        {
            error("not implemented yet");
        }

        public void after_kill()
        {
            error("not implemented yet");
        }
    }

    internal void send_ack_net(string my_dev, uint16 udp_port, int packet_id, string ack_mac)
    {
        error("not implemented yet");
    }

    public IListenerHandle datagram_system_listen(
        string listen_pathname, string send_pathname, string ack_mac,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
    }
    internal class DatagramSystemListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public void * func()
        {
            error("not implemented yet");
        }

        public void after_kill()
        {
            error("not implemented yet");
        }
    }

    internal void send_ack_system(string send_pathname, int packet_id, string ack_mac)
    {
        error("not implemented yet");
    }
}