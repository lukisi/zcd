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
    public string send_stream_net(
        string peer_ip, uint16 tcp_port,
        string source_id, string src_nic, string unicast_id,
        string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
    {
        error("not implemented yet");
    }

    public string send_stream_system(
        string send_pathname,
        string source_id, string src_nic, string unicast_id,
        string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
    {
        error("not implemented yet");
    }

    public void send_datagram_net(
        string my_dev, uint16 udp_port,
        int packet_id,
        string source_id, string src_nic, string broadcast_id,
        string m_name, Gee.List<string> arguments, bool send_ack) throws ZCDError
    {
        error("not implemented yet");
    }

    public void send_datagram_system(
        string send_pathname,
        int packet_id,
        string source_id, string src_nic, string broadcast_id,
        string m_name, Gee.List<string> arguments, bool send_ack) throws ZCDError
    {
        error("not implemented yet");
    }
}