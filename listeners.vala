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
        public ListenerHandle(ITaskletHandle th)
        {
            this.th = th;
        }

        public void kill()
        {
            error("not implemented yet");
        }
    }

    public IListenerHandle stream_net_listen(
        string my_ip, uint16 tcp_port,
        IStreamDelegate stream_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
    }

    public IListenerHandle stream_system_listen(
        string listen_pathname,
        IStreamDelegate stream_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
    }

    public IListenerHandle datagram_net_listen(
        string my_dev, uint16 udp_port, string ack_mac,
        IDatagramDelegate datagram_dlg,
        IErrorHandler error_handler)
    {
        error("not implemented yet");
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

    internal void send_ack_system(send_pathname, int packet_id, string ack_mac)
    {
        error("not implemented yet");
    }
}