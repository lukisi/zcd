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
            // point not_reached
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
            // point not_reached
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
                Gee.List<string> arguments;
                bool wait_reply;
                try {
                    parse_unicast_request(
                        (string)buf,
                        out m_name,
                        out arguments,
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
                    string resp = disp.execute(m_name, arguments, caller_info);
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
                        arguments,
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
            Gee.List<string> arguments,
            StreamCallerInfo caller_info)
        {
            this.disp = disp;
            this.m_name = m_name;
            this.arguments = arguments;
            this.caller_info = caller_info;
        }

        private IStreamDispatcher disp;
        private string m_name;
        private Gee.List<string> arguments;
        private StreamCallerInfo caller_info;

        public void * func()
        {
            disp.execute(m_name, arguments, caller_info);
            return null;
        }
    }

    internal size_t max_pkt_size = 60000;

    public IListenerHandle datagram_net_listen(
        string my_dev, uint16 udp_port, string src_nic,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        DatagramNetListenerTasklet t = new DatagramNetListenerTasklet();
        t.my_dev = my_dev;
        t.udp_port = udp_port;
        t.src_nic = src_nic;
        t.datagram_dlg = datagram_dlg;
        t.error_handler = error_handler;
        ITaskletHandle th = tasklet.spawn(t);
        var ret = new ListenerHandle(th, t);
        return ret;
    }
    internal class DatagramNetListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public string my_dev;
        public uint16 udp_port;
        public string src_nic;
        public IDatagramDelegate datagram_dlg;
        public IErrorHandler error_handler;
        private IServerDatagramNetworkSocket s;

        public void * func()
        {
            try {
                s = tasklet.get_server_datagram_network_socket(udp_port, my_dev);
                while (true)
                {
                    try {
                        uint8* b;
                        size_t sz = max_pkt_size + 1;
                        b = try_malloc(sz);
                        if (b == null)
                        {
                            throw new RecvMessageError.FAIL_ALLOC(@"Could not allocate memory ($(sz) bytes)");
                        }
                        size_t msglen = s.recvfrom(b, max_pkt_size);
                        b[msglen] = 0; // NULL terminate
                        unowned uint8[] buf;
                        buf = (uint8[])b;
                        buf.length = (int)msglen;
                        string msg = (string)buf; // copy
                        free(b);
                        DatagramPktHandlerTasklet t = new DatagramPktHandlerTasklet();
                        t.msg = msg;
                        t.datagram_dlg = datagram_dlg;
                        t.listener = new DatagramNetListener(my_dev, udp_port, src_nic);
                        tasklet.spawn(t);
                    } catch (Error e) {
                        // log message temporary error
                        warning(@"datagram_listener: temporary error $(e.message)");
                        tasklet.ms_wait(20);
                    }
                }
            } catch (Error e) {
                error_handler.error_handler(e.copy());
                cleanup();
                return null;
            }
            // point not_reached
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

    public IListenerHandle datagram_system_listen(
        string listen_pathname, string send_pathname, string src_nic,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        DatagramSystemListenerTasklet t = new DatagramSystemListenerTasklet();
        t.listen_pathname = listen_pathname;
        t.send_pathname = send_pathname;
        t.src_nic = src_nic;
        t.datagram_dlg = datagram_dlg;
        t.error_handler = error_handler;
        ITaskletHandle th = tasklet.spawn(t);
        var ret = new ListenerHandle(th, t);
        return ret;
    }
    internal class DatagramSystemListenerTasklet : Object, ITaskletSpawnable, IListenerTasklet
    {
        public string listen_pathname;
        public string send_pathname;
        public string src_nic;
        public IDatagramDelegate datagram_dlg;
        public IErrorHandler error_handler;
        private IServerDatagramLocalSocket s;

        public void * func()
        {
            try {
                s = tasklet.get_server_datagram_local_socket(listen_pathname);
                while (true)
                {
                    try {
                        uint8* b;
                        size_t sz = max_pkt_size + 1;
                        b = try_malloc(sz);
                        if (b == null)
                        {
                            throw new RecvMessageError.FAIL_ALLOC(@"Could not allocate memory ($(sz) bytes)");
                        }
                        size_t msglen = s.recvfrom(b, max_pkt_size);
                        b[msglen] = 0; // NULL terminate
                        unowned uint8[] buf;
                        buf = (uint8[])b;
                        buf.length = (int)msglen;
                        string msg = (string)buf; // copy
                        free(b);
                        DatagramPktHandlerTasklet t = new DatagramPktHandlerTasklet();
                        t.msg = msg;
                        t.datagram_dlg = datagram_dlg;
                        t.listener = new DatagramSystemListener(listen_pathname, send_pathname, src_nic);
                        tasklet.spawn(t);
                    } catch (Error e) {
                        // log message temporary error
                        warning(@"datagram_listener: temporary error $(e.message)");
                        tasklet.ms_wait(20);
                    }
                }
            } catch (Error e) {
                error_handler.error_handler(e.copy());
                cleanup();
                return null;
            }
            // point not_reached
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

    internal class DatagramPktHandlerTasklet : Object, ITaskletSpawnable
    {
        public string msg;
        public IDatagramDelegate datagram_dlg;

        /* This class (ITaskletSpawnable) should be usable both for `datagram_net_listen` and for `datagram_system_listen`.
        ** That is why we have a generic `Listener` here:
        **/
        public Listener listener;

        public void * func()
        {
            string? json_tree_request;
            string? json_tree_ack;
            try {
                parse_broadcast_packet(msg, out json_tree_request, out json_tree_ack);
            } catch (MessageError e) {
                // log message
                warning(@"datagram_listener: Error parsing JSON of received packet: $(e.message)");
                // terminate tasklet
                return null;
            }
            if (json_tree_request != null && json_tree_ack == null)
            {
                int packet_id;
                string m_name;
                Gee.List<string> arguments;
                string source_id;
                string broadcast_id;
                string src_nic;
                bool send_ack;
                try {
                    parse_broadcast_request(json_tree_request,
                        out packet_id, out m_name, out arguments,
                        out source_id, out broadcast_id, out src_nic, out send_ack);
                } catch (MessageError e) {
                    // log message
                    warning(@"datagram_listener: Error parsing JSON of received request: $(e.message)");
                    // terminate tasklet
                    return null;
                }

                if (datagram_dlg.is_my_own_message(packet_id))
                {
                    // terminate tasklet
                    return null;
                }
                if (send_ack)
                {
                    SendAckTasklet t = new SendAckTasklet();
                    t.packet_id = packet_id;
                    t.listener = listener;
                    tasklet.spawn(t);
                }
                DatagramCallerInfo caller_info = new DatagramCallerInfo(
                    packet_id,
                    source_id,
                    src_nic,
                    broadcast_id,
                    m_name,
                    send_ack,
                    listener);
                IDatagramDispatcher? disp = datagram_dlg.get_dispatcher(caller_info);
                if (disp == null)
                {
                    // log message
                    warning(@"datagram_listener: Delegate datagram_dlg did not recognize this message.");
                    // Ignore this msg and terminate tasklet
                    return null;
                }
                disp.execute(m_name, arguments, caller_info);
            }
            else if (json_tree_request == null && json_tree_ack != null)
            {
                int packet_id;
                string src_nic;
                try {
                    parse_broadcast_ack(json_tree_ack,
                        out packet_id, out src_nic);
                } catch (MessageError e) {
                    // log message
                    warning(@"datagram_listener: Error parsing JSON of received ack: $(e.message)");
                    // terminate tasklet
                    return null;
                }
                datagram_dlg.got_ack(packet_id, src_nic);
            }
            else assert_not_reached();
            return null;
        }
    }

    internal class SendAckTasklet : Object, ITaskletSpawnable
    {
        public int packet_id;

        /* This class (ITaskletSpawnable) should be usable both for `datagram_net_listen` and for `datagram_system_listen`.
        ** That is why we have a generic `Listener` here:
        **/
        public Listener listener;

        public void * func()
        {
            string src_nic;
            if (listener is DatagramNetListener) src_nic = ((DatagramNetListener)listener).src_nic;
            else if (listener is DatagramSystemListener) src_nic = ((DatagramSystemListener)listener).src_nic;
            else assert_not_reached();
            string json_tree_packet;
            try {
                build_broadcast_ack(packet_id, src_nic, out json_tree_packet);
            } catch (InvalidJsonError e) {
                error(@"SendAckTasklet: Error building JSON from my own src_nic: $(e.message)");
            }
            for (int i = 0; i < 3; i++)
            {
                if (listener is DatagramNetListener)
                {
                    uint16 udp_port = ((DatagramNetListener)listener).udp_port;
                    string my_dev = ((DatagramNetListener)listener).my_dev;
                    send_ack_net(my_dev, udp_port, json_tree_packet);
                }
                else if (listener is DatagramSystemListener)
                {
                    string send_pathname = ((DatagramSystemListener)listener).send_pathname;
                    send_ack_system(send_pathname, json_tree_packet);
                }
                else assert_not_reached();
                tasklet.ms_wait(Random.int_range(10, 200));
            }
            return null;
        }
    }

    internal void send_ack_net(string my_dev, uint16 udp_port, string json_tree_packet)
    {
        try {
            var cs = tasklet.get_client_datagram_network_socket(udp_port, my_dev);
            cs.sendto(json_tree_packet.data, json_tree_packet.length);
        } catch (Error e) {
            // log message
            warning(@"datagram_listener: Error sending ack: $(e.message)");
            // ignore this one, hope better luck on the other ones
        }
    }

    internal void send_ack_system(string send_pathname, string json_tree_packet)
    {
        try {
            var cs = tasklet.get_client_datagram_local_socket(send_pathname);
            cs.sendto(json_tree_packet.data, json_tree_packet.length);
        } catch (Error e) {
            // log message
            warning(@"datagram_listener: Error sending ack: $(e.message)");
            // ignore this one, hope better luck on the other ones
        }
    }
}