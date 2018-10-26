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
        public StreamCallerInfo(
            string source_id,
            string src_nic,
            string unicast_id,
            string m_name,
            bool wait_reply,
            Listener listener)
        {
            this.source_id = source_id;
            this.src_nic = src_nic;
            this.unicast_id = unicast_id;
            this.m_name = m_name;
            this.wait_reply = wait_reply;
            this.listener = listener;
        }

        public string source_id {get; private set;}
        public string src_nic {get; private set;}
        public string unicast_id {get; private set;}
        public string m_name {get; private set;}
        public bool wait_reply {get; private set;}
        public Listener listener {get; private set;}
    }

    public class DatagramCallerInfo : CallerInfo
    {
        public DatagramCallerInfo(
            int packet_id,
            string source_id,
            string src_nic,
            string broadcast_id,
            string m_name,
            bool send_ack,
            Listener listener)
        {
            this.packet_id = packet_id;
            this.source_id = source_id;
            this.src_nic = src_nic;
            this.broadcast_id = broadcast_id;
            this.m_name = m_name;
            this.send_ack = send_ack;
            this.listener = listener;
        }

        public int packet_id {get; private set;}
        public string source_id {get; private set;}
        public string src_nic {get; private set;}
        public string broadcast_id {get; private set;}
        public string m_name {get; private set;}
        public bool send_ack {get; private set;}
        public Listener listener {get; private set;}
    }

    public class StreamNetListener : Listener
    {
        public StreamNetListener(
            string my_ip,
            uint16 tcp_port)
        {
            this.my_ip = my_ip;
            this.tcp_port = tcp_port;
        }

        public string my_ip {get; private set;}
        public uint16 tcp_port {get; private set;}
    }

    public class StreamSystemListener : Listener
    {
        public StreamSystemListener(
            string listen_pathname)
        {
            this.listen_pathname = listen_pathname;
        }

        public string listen_pathname {get; private set;}
    }

    public class DatagramNetListener : Listener
    {
        public DatagramNetListener(
            string my_dev,
            uint16 udp_port,
            string ack_mac)
        {
            this.my_dev = my_dev;
            this.udp_port = udp_port;
            this.ack_mac = ack_mac;
        }

        public string my_dev {get; private set;}
        public uint16 udp_port {get; private set;}
        public string ack_mac {get; private set;}
    }

    public class DatagramSystemListener : Listener
    {
        public DatagramSystemListener(
            string listen_pathname,
            string send_pathname,
            string ack_mac)
        {
            this.listen_pathname = listen_pathname;
            this.send_pathname = send_pathname;
            this.ack_mac = ack_mac;
        }

        public string listen_pathname {get; private set;}
        public string send_pathname {get; private set;}
        public string ack_mac {get; private set;}
    }
}