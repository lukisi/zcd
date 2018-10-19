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
    public class CallerInfo : Object
    {
    }

    public class Listener : Object
    {
    }

    public class StreamCallerInfo : CallerInfo
    {
        public string source_id;
        public string src_nic;
        public string unicast_id;
        public string m_name;
        public bool wait_reply;
        public Listener listener;
    }

    public class DatagramCallerInfo : CallerInfo
    {
        public int packet_id;
        public string source_id;
        public string src_nic;
        public string broadcast_id;
        public string m_name;
        public bool send_ack;
        public Listener listener;
    }

    public class StreamNetListener : Listener
    {
        public string my_ip;
        public uint16 tcp_port;
    }

    public class StreamSystemListener : Listener
    {
        public string listen_pathname;
    }

    public class DatagramNetListener : Listener
    {
        public string my_dev;
        public uint16 udp_port;
        public string ack_mac;
    }

    public class DatagramSystemListener : Listener
    {
        public string listen_pathname;
        public string send_pathname;
        public string ack_mac;
    }
}