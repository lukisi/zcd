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
    internal class StreamNetListenerTasklet : Object, IListenerTasklet, ITaskletSpawnable
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
                    StreamNetListener stream_net_listener = new StreamNetListener();
                    stream_net_listener.my_ip = my_ip;
                    stream_net_listener.tcp_port = tcp_port;
                    StreamConnectionHandlerTasklet t = new StreamConnectionHandlerTasklet();
                    t.c = c;
                    t.stream_dlg = stream_dlg;
                    t.listener = stream_net_listener;
                    tasklet.spawn(t);
                }
            } catch (Error e) {
                err.error_handler(e.copy());
                if (s != null) s.close();
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
            s.close();
        }
    }

    public IListenerHandle stream_system_listen(
        string listen_pathname,
        IStreamDelegate stream_dlg,
        IErrorHandler error_handler)
    {
        StreamSystemListenerTasklet t = new StreamSystemListenerTasklet();
        t.listen_pathname;
        t.stream_dlg = stream_dlg;
        t.error_handler = error_handler;
        ITaskletHandle th = tasklet.spawn(t);
        var ret = new ListenerHandle(th, t);
        return ret;
    }
    internal class StreamSystemListenerTasklet : Object, IListenerTasklet, ITaskletSpawnable
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
                    StreamSystemListener stream_system_listener = new StreamSystemListener();
                    stream_system_listener.listen_pathname = listen_pathname;
                    StreamConnectionHandlerTasklet t = new StreamConnectionHandlerTasklet();
                    t.c = c;
                    t.stream_dlg = stream_dlg;
                    t.listener = stream_system_listener;
                    tasklet.spawn(t);
                }
            } catch (Error e) {
                err.error_handler(e.copy());
                if (s != null) s.close();
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
            s.close();
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

        public void * func()
        {
            error("not implemented yet");
        }
    }

    public IListenerHandle datagram_net_listen(
        string my_dev, uint16 udp_port, string ack_mac,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
    }
    internal class DatagramNetListenerTasklet : Object, IListenerTasklet, ITaskletSpawnable
    {
        public void * func()
        {
            error("not implemented yet");
        }

        public void after_kill()
        {
            // This function should be called only after killing the tasklet.
            assert(s != null);
            s.close();
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
    internal class DatagramSystemListenerTasklet : Object, IListenerTasklet, ITaskletSpawnable
    {
        public void * func()
        {
            error("not implemented yet");
        }

        public void after_kill()
        {
            // This function should be called only after killing the tasklet.
            assert(s != null);
            s.close();
        }
    }

    internal void send_ack_system(send_pathname, int packet_id, string ack_mac)
    {
        error("not implemented yet");
    }
}