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
    internal HashMap<string, Gee.List<IConnectedStreamSocket>> connected_pools;
    internal delegate IConnectedStreamSocket GetNewConnection() throws Error;

    public string send_stream_net(
        string peer_ip, uint16 tcp_port,
        string source_id, string src_nic, string unicast_id,
        string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
    {
        // Handle pools of connections.
        if (connected_pools == null) connected_pools = new HashMap<string, Gee.List<IConnectedStreamSocket>>();
        string key = @"network_$(peer_ip):$(tcp_port)";
        if (!connected_pools.has_key(key)) connected_pools[key] = new ArrayList<IConnectedStreamSocket>();
        Gee.List<IConnectedStreamSocket> connected_pool = connected_pools[key];
        GetNewConnection get_new_connection = () => tasklet.get_client_stream_network_socket(peer_ip, tcp_port);

        // common part
        return send_stream(
            connected_pool, key, get_new_connection,
            source_id, src_nic, unicast_id,
            m_name, arguments, wait_reply);
    }

    public string send_stream_system(
        string send_pathname,
        string source_id, string src_nic, string unicast_id,
        string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
    {
        // Handle pools of connections.
        if (connected_pools == null) connected_pools = new HashMap<string, Gee.List<IConnectedStreamSocket>>();
        string key = @"local_$(send_pathname)";
        if (!connected_pools.has_key(key)) connected_pools[key] = new ArrayList<IConnectedStreamSocket>();
        Gee.List<IConnectedStreamSocket> connected_pool = connected_pools[key];
        GetNewConnection get_new_connection = () => tasklet.get_client_stream_local_socket(send_pathname);

        // common part
        return send_stream(
            connected_pool, key, get_new_connection,
            source_id, src_nic, unicast_id,
            m_name, arguments, wait_reply);
    }

    internal string send_stream(
        Gee.List<IConnectedStreamSocket> connected_pool, string key, GetNewConnection get_new_connection,
        string source_id, string src_nic, string unicast_id,
        string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
    {
        IConnectedStreamSocket c = null;
        bool try_again = true;
        while (try_again)
        {
            // Get a connection
            try_again = false;
            bool old_socket = false;
            if (connected_pool.is_empty) {
                try {
                    c = get_new_connection();
                } catch (Error e) {
                    throw new ZCDError.GENERIC(@"send_stream($(key)): Error connecting: $(e.message)");
                }
            } else {
                old_socket = true;
                c = connected_pool.remove_at(0);
            }

            // build message
            string json_tree_request;
            try {
                build_unicast_request(
                    m_name,
                    arguments,
                    source_id,
                    unicast_id,
                    src_nic,
                    wait_reply,
                    out json_tree_request);
            } catch (InvalidJsonError e) {
                error(@"send_stream($(key)): Error building JSON from my own request: $(e.message)");
            }

            // send one message
            try {
                send_one_message(c, json_tree_request);
            } catch (SendMessageError e) {
                if (old_socket)
                {
                    try_again = true;
                    // log message (because we'll retry)
                    warning(@"send_stream($(key)): could not write to old socket: $(e.message). We'll try another one.");
                    continue;
                }
                else throw new ZCDError.GENERIC(@"send_stream($(key)): Error while writing: $(e.message)");
            }
        }
        assert(c != null);

        // no reply?
        if (! wait_reply)
        {
            connected_pool.add(c);
            return "";
        }

        // wait reply
        // Get one message
        void *m;
        size_t s;
        try {
            bool got = get_one_message(c, out m, out s);
            if (!got) throw new ZCDError.GENERIC(@"send_stream($(key)): Connection was closed while waiting reply.");
        } catch (RecvMessageError e) {
            throw new ZCDError.GENERIC(@"send_stream($(key)): Error receiving reply: $(e.message)");
        }
        unowned uint8[] buf;
        buf = (uint8[])m;
        buf.length = (int)s;
        string json_tree_response = (string)buf; // copy
        free(m);

        // Parse JSON
        string response;
        try {
            parse_unicast_response(
                json_tree_response,
                out response);
        } catch (MessageError e) {
            throw new ZCDError.GENERIC(@"send_stream($(key)): Error parsing JSON of received reply: $(e.message)");
        }
        connected_pool.add(c);
        return response;
    }

    public void send_datagram_net(
        string my_dev, uint16 udp_port,
        int packet_id,
        string source_id, string src_nic, string broadcast_id,
        string m_name, Gee.List<string> arguments, bool send_ack) throws ZCDError
    {
        string key = @"network_$(my_dev):$(udp_port)";
        string json_tree_packet;
        try {
            build_broadcast_request(
                packet_id,
                m_name,
                arguments,
                source_id,
                broadcast_id,
                src_nic,
                send_ack,
                out json_tree_packet);
        } catch (InvalidJsonError e) {
             error(@"send_datagram($(key)): Error building JSON from my own request: $(e.message)");
        }
        try {
            var cs = tasklet.get_client_datagram_network_socket(udp_port, my_dev);
            cs.sendto(json_tree_packet.data, json_tree_packet.length);
        } catch (Error e) {
            throw new ZCDError.GENERIC(@"send_datagram($(key)): Error while writing: $(e.message)");
        }
    }

    public void send_datagram_system(
        string send_pathname,
        int packet_id,
        string source_id, string src_nic, string broadcast_id,
        string m_name, Gee.List<string> arguments, bool send_ack) throws ZCDError
    {
        string key = @"local_$(send_pathname)";
        string json_tree_packet;
        try {
            build_broadcast_request(
                packet_id,
                m_name,
                arguments,
                source_id,
                broadcast_id,
                src_nic,
                send_ack,
                out json_tree_packet);
        } catch (InvalidJsonError e) {
             error(@"send_datagram($(key)): Error building JSON from my own request: $(e.message)");
        }
        try {
            var cs = tasklet.get_client_datagram_local_socket(send_pathname);
            cs.sendto(json_tree_packet.data, json_tree_packet.length);
        } catch (Error e) {
            throw new ZCDError.GENERIC(@"send_datagram($(key)): Error while writing: $(e.message)");
        }
    }
}