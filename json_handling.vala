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
    internal errordomain MessageError {
        MALFORMED
    }

    internal errordomain InvalidJsonError {
        GENERIC
    }

    internal void build_unicast_request(
        string m_name,
        Gee.List<string> arguments,
        string source_id,
        string unicast_id,
        string src_nic,
        bool wait_reply,
        out string json_tree_request)
        throws InvalidJsonError
    {
        Json.Builder b = new Json.Builder();
        b.begin_object();
            b.set_member_name("method-name").add_string_value(m_name);

            b.set_member_name("arguments").begin_array();
                for (int j = 0; j < arguments.size; j++)
                {
                    string arg = arguments[j];
                    var p = new Json.Parser();
                    try {
                        parse_and_validate(p, arg);
                    } catch (Error e) {
                        throw new InvalidJsonError.GENERIC(
                            @"Error parsing JSON for argument from my own stub: $(e.message)"
                            + @" method-name: $(m_name)"
                            + @" argument #$(j): '$(arg)'");
                    }
                    unowned Json.Node p_rootnode = p.get_root();
                    assert(p_rootnode != null);
                    Json.Node* cp = p_rootnode.copy();
                    b.add_value(cp);
                }
            b.end_array();

            b.set_member_name("source-id");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, source_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for source_id from my own stub: $(e.message)"
                        + @" string source_id : $(source_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("unicast-id");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, unicast_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for unicast_id from my own stub: $(e.message)"
                        + @" string unicast_id : $(unicast_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("src-nic");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, src_nic);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for src_nic from my own stub: $(e.message)"
                        + @" string src_nic : $(src_nic)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("wait-reply").add_boolean_value(wait_reply);
        b.end_object();
        Json.Node node = b.get_root();
        json_tree_request = generate_stream(node);
    }

    internal void parse_unicast_request(
        string json_tree_request,
        out string m_name,
        out Gee.List<string> arguments,
        out string source_id,
        out string unicast_id,
        out string src_nic,
        out bool wait_reply)
        throws MessageError
    {
        try {
            // The parser must not be freed until we finish with the reader.
            Json.Parser p_buf = new Json.Parser();
            parse_and_validate(p_buf, json_tree_request);
            unowned Json.Node buf_rootnode = p_buf.get_root();
            assert(buf_rootnode != null);
            Json.Reader r_buf = new Json.Reader(buf_rootnode);
            if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");

            if (!r_buf.read_member("method-name")) throw new MessageError.MALFORMED("root must have method-name");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("method-name must be a string");
            if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("method-name must be a string");
            m_name = r_buf.get_string_value();
            r_buf.end_member();

            if (!r_buf.read_member("arguments")) throw new MessageError.MALFORMED("root must have arguments");
            if (!r_buf.is_array()) throw new MessageError.MALFORMED("arguments must be an array");
            int num_elements = r_buf.count_elements();
            arguments = new ArrayList<string>();
            for (int j = 0; j < num_elements; j++)
            {
                r_buf.read_element(j);
                if (!r_buf.is_object() && !r_buf.is_array()) throw new MessageError.MALFORMED("each argument must be a valid JSON tree");
                r_buf.end_element();
            }
            r_buf.end_member();
            for (int j = 0; j < num_elements; j++)
            {
                unowned Json.Node node1 = buf_rootnode.get_object().get_array_member("arguments").get_element(j);
                arguments.add(generate_stream(node1));
            }

            if (!r_buf.read_member("source-id")) throw new MessageError.MALFORMED("root must have source-id");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"source-id must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node2 = buf_rootnode.get_object().get_member("source-id");
            source_id = generate_stream(node2);

            if (!r_buf.read_member("unicast-id")) throw new MessageError.MALFORMED("root must have unicast-id");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"unicast-id must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node3 = buf_rootnode.get_object().get_member("unicast-id");
            unicast_id = generate_stream(node3);

            if (!r_buf.read_member("src-nic")) throw new MessageError.MALFORMED("root must have src-nic");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"src-nic must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node4 = buf_rootnode.get_object().get_member("src-nic");
            src_nic = generate_stream(node4);

            if (!r_buf.read_member("wait-reply")) throw new MessageError.MALFORMED("root must have wait-reply");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("wait-reply must be a boolean");
            if (r_buf.get_value().get_value_type() != typeof(bool)) throw new MessageError.MALFORMED("wait-reply must be a boolean");
            wait_reply = r_buf.get_boolean_value();
            r_buf.end_member();
        } catch (MessageError e) {
            throw e;
        } catch (Error e) {
            throw new MessageError.MALFORMED(@"Error parsing json_tree_request: $(e.message)");
        }
    }

    internal void build_unicast_response(
        string response,
        out string json_tree_response)
        throws InvalidJsonError
    {
        Json.Builder b = new Json.Builder();
        Json.Parser p = new Json.Parser();
        b.begin_object();
            b.set_member_name("response");
            try {
                parse_and_validate(p, response);
            } catch (Error e) {
                throw new InvalidJsonError.GENERIC(
                    @"Error parsing JSON for response from my own dispatcher: $(e.message)"
                    + @" response: $(response)");
            }
            unowned Json.Node p_rootnode = p.get_root();
            assert(p_rootnode != null);
            Json.Node* cp = p_rootnode.copy();
            b.add_value(cp);
        b.end_object();
        Json.Node node = b.get_root();
        json_tree_response = generate_stream(node);
    }

    internal void parse_unicast_response(
        string json_tree_response,
        out string response)
        throws MessageError
    {
        try {
            Json.Parser p_buf = new Json.Parser();
            parse_and_validate(p_buf, json_tree_response);
            unowned Json.Node buf_rootnode = p_buf.get_root();
            assert(buf_rootnode != null);
            Json.Reader r_buf = new Json.Reader(buf_rootnode);
            if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
            if (!r_buf.read_member("response")) throw new MessageError.MALFORMED("root must have response");
            if (!r_buf.is_object() && !r_buf.is_array()) throw new MessageError.MALFORMED("response must be a valid JSON tree");
            r_buf.end_member();
            Json.Node cp = buf_rootnode.get_object().get_member("response").copy();
            Json.Generator g = new Json.Generator();
            g.pretty = false;
            g.root = cp;
            response = g.to_data(null);
        } catch (MessageError e) {
            throw e;
        } catch (Error e) {
            throw new MessageError.MALFORMED(@"Error parsing json_tree_response: $(e.message)");
        }
    }

    internal void build_broadcast_request(
        int packet_id,
        string m_name,
        Gee.List<string> arguments,
        string source_id,
        string broadcast_id,
        string src_nic,
        bool send_ack,
        out string json_tree_packet)
        throws InvalidJsonError
    {
        Json.Builder b = new Json.Builder();
        b.begin_object().set_member_name("request").begin_object();
            b.set_member_name("packet-id").add_int_value(packet_id);

            b.set_member_name("method-name").add_string_value(m_name);

            b.set_member_name("arguments").begin_array();
                for (int j = 0; j < arguments.size; j++)
                {
                    string arg = arguments[j];
                    var p = new Json.Parser();
                    try {
                        parse_and_validate(p, arg);
                    } catch (Error e) {
                        throw new InvalidJsonError.GENERIC(
                            @"Error parsing JSON for argument from my own stub: $(e.message)"
                            + @" method-name: $(m_name)"
                            + @" argument #$(j): '$(arg)'");
                    }
                    unowned Json.Node p_rootnode = p.get_root();
                    assert(p_rootnode != null);
                    Json.Node* cp = p_rootnode.copy();
                    b.add_value(cp);
                }
            b.end_array();

            b.set_member_name("source-id");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, source_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for source_id from my own stub: $(e.message)"
                        + @" string source_id : $(source_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("broadcast-id");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, broadcast_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for broadcast_id from my own stub: $(e.message)"
                        + @" string broadcast_id : $(broadcast_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("src-nic");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, src_nic);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for src_nic from my own stub: $(e.message)"
                        + @" string src_nic : $(src_nic)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("send-ack").add_boolean_value(send_ack);
        b.end_object().end_object();
        Json.Node node = b.get_root();
        json_tree_packet = generate_stream(node);
    }

    internal void parse_broadcast_packet(
        string json_tree_packet,
        out string? json_tree_request,
        out string? json_tree_ack)
        throws MessageError
    {
        try {
            Json.Parser p_buf = new Json.Parser();
            parse_and_validate(p_buf, json_tree_packet);
            unowned Json.Node buf_rootnode = p_buf.get_root();
            assert(buf_rootnode != null);
            Json.Reader r_buf = new Json.Reader(buf_rootnode);
            if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
            string[] members = r_buf.list_members();
            if (members.length != 1) throw new MessageError.MALFORMED("root must have 1 member");
            switch (members[0]) {
                case "request":
                    r_buf.read_member("request");
                    if (!r_buf.is_object()) throw new MessageError.MALFORMED("root.request must be an object");
                    r_buf.end_member();
                    Json.Node cp = buf_rootnode.get_object().get_member("request").copy();
                    Json.Generator g = new Json.Generator();
                    g.pretty = false;
                    g.root = cp;
                    json_tree_request = g.to_data(null);
                    json_tree_ack = null;
                    break;
                case "ack":
                    r_buf.read_member("ack");
                    if (!r_buf.is_object()) throw new MessageError.MALFORMED("root.ack must be an object");
                    r_buf.end_member();
                    Json.Node cp = buf_rootnode.get_object().get_member("ack").copy();
                    Json.Generator g = new Json.Generator();
                    g.pretty = false;
                    g.root = cp;
                    json_tree_ack = g.to_data(null);
                    json_tree_request = null;
                    break;
                default:
                    throw new MessageError.MALFORMED(@"root has unknown member $(members[0])");
            }
        } catch (MessageError e) {
            throw e;
        } catch (Error e) {
            throw new MessageError.MALFORMED(@"Error parsing json_tree_packet: $(e.message)");
        }
    }

    internal void parse_broadcast_request(
        string json_tree_request,
        out int packet_id,
        out string m_name,
        out Gee.List<string> arguments,
        out string source_id,
        out string broadcast_id,
        out string src_nic,
        out bool send_ack)
        throws MessageError
    {
        try {
            // The parser must not be freed until we finish with the reader.
            Json.Parser p_buf = new Json.Parser();
            parse_and_validate(p_buf, json_tree_request);
            unowned Json.Node buf_rootnode = p_buf.get_root();
            assert(buf_rootnode != null);
            Json.Reader r_buf = new Json.Reader(buf_rootnode);
            if (!r_buf.is_object()) throw new MessageError.MALFORMED("root.request must be an object");

            if (!r_buf.read_member("packet-id")) throw new MessageError.MALFORMED("root.request must have packet-id");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("packet-id must be a int");
            if (r_buf.get_value().get_value_type() != typeof(int64)) throw new MessageError.MALFORMED("packet-id must be a int");
            int64 val = r_buf.get_int_value();
            if (val > int.MAX || val < int.MIN) throw new MessageError.MALFORMED("packet-id overflows size of int");
            packet_id = (int)val;
            r_buf.end_member();

            if (!r_buf.read_member("method-name")) throw new MessageError.MALFORMED("root.request must have method-name");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("method-name must be a string");
            if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("method-name must be a string");
            m_name = r_buf.get_string_value();
            r_buf.end_member();

            if (!r_buf.read_member("arguments")) throw new MessageError.MALFORMED("root.request must have arguments");
            if (!r_buf.is_array()) throw new MessageError.MALFORMED("arguments must be an array");
            int num_elements = r_buf.count_elements();
            arguments = new ArrayList<string>();
            for (int j = 0; j < num_elements; j++)
            {
                r_buf.read_element(j);
                if (!r_buf.is_object() && !r_buf.is_array()) throw new MessageError.MALFORMED("each argument must be a valid JSON tree");
                r_buf.end_element();
            }
            r_buf.end_member();
            for (int j = 0; j < num_elements; j++)
            {
                unowned Json.Node node1 = buf_rootnode.get_object().get_array_member("arguments").get_element(j);
                arguments.add(generate_stream(node1));
            }

            if (!r_buf.read_member("source-id")) throw new MessageError.MALFORMED("root.request must have source-id");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"source-id must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node2 = buf_rootnode.get_object().get_member("source-id");
            source_id = generate_stream(node2);

            if (!r_buf.read_member("broadcast-id")) throw new MessageError.MALFORMED("root.request must have broadcast-id");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"broadcast-id must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node3 = buf_rootnode.get_object().get_member("broadcast-id");
            broadcast_id = generate_stream(node3);

            if (!r_buf.read_member("src-nic")) throw new MessageError.MALFORMED("root.request must have src-nic");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"src-nic must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node4 = buf_rootnode.get_object().get_member("src-nic");
            src_nic = generate_stream(node4);

            if (!r_buf.read_member("send-ack")) throw new MessageError.MALFORMED("root.request must have send-ack");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("send-ack must be a boolean");
            if (r_buf.get_value().get_value_type() != typeof(bool)) throw new MessageError.MALFORMED("send-ack must be a boolean");
            send_ack = r_buf.get_boolean_value();
            r_buf.end_member();
        } catch (MessageError e) {
            throw e;
        } catch (Error e) {
            throw new MessageError.MALFORMED(@"Error parsing json_tree_request: $(e.message)");
        }
    }

    internal void build_broadcast_ack(
        int packet_id,
        string src_nic,
        out string json_tree_packet)
        throws InvalidJsonError
    {
        Json.Builder b = new Json.Builder();
        b.begin_object().set_member_name("ack").begin_object();
            b.set_member_name("packet-id").add_int_value(packet_id);

            b.set_member_name("src-nic");
            {
                var p = new Json.Parser();
                try {
                    parse_and_validate(p, src_nic);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for src_nic from my own stub: $(e.message)"
                        + @" string src_nic : $(src_nic)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                assert(p_rootnode != null);
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }
        b.end_object().end_object();
        Json.Node node = b.get_root();
        json_tree_packet = generate_stream(node);
    }

    internal void parse_broadcast_ack(
        string json_tree_ack,
        out int packet_id,
        out string src_nic)
        throws MessageError
    {
        try {
            // The parser must not be freed until we finish with the reader.
            Json.Parser p_buf = new Json.Parser();
            parse_and_validate(p_buf, json_tree_ack);
            unowned Json.Node buf_rootnode = p_buf.get_root();
            assert(buf_rootnode != null);
            Json.Reader r_buf = new Json.Reader(buf_rootnode);
            if (!r_buf.is_object()) throw new MessageError.MALFORMED("root.ack must be an object");

            if (!r_buf.read_member("packet-id")) throw new MessageError.MALFORMED("root.ack must have packet-id");
            if (!r_buf.is_value()) throw new MessageError.MALFORMED("packet-id must be a int");
            if (r_buf.get_value().get_value_type() != typeof(int64)) throw new MessageError.MALFORMED("packet-id must be a int");
            int64 val = r_buf.get_int_value();
            if (val > int.MAX || val < int.MIN) throw new MessageError.MALFORMED("packet-id overflows size of int");
            packet_id = (int)val;
            r_buf.end_member();

            if (!r_buf.read_member("src-nic")) throw new MessageError.MALFORMED("root.ack must have src-nic");
            if (!r_buf.is_object() && !r_buf.is_array())
                throw new MessageError.MALFORMED(@"src-nic must be a valid JSON tree");
            r_buf.end_member();
            unowned Json.Node node1 = buf_rootnode.get_object().get_member("src-nic");
            src_nic = generate_stream(node1);
        } catch (MessageError e) {
            throw e;
        } catch (Error e) {
            throw new MessageError.MALFORMED(@"Error parsing json_tree_ack: $(e.message)");
        }
    }

    internal void parse_and_validate(Json.Parser p, string s) throws Error
    {
        p.load_from_data(s);
        unowned Json.Node p_rootnode = p.get_root();
        if (p_rootnode == null) throw new IOError.FAILED("null-root");
    }

    internal string generate_stream(Json.Node node)
    {
        Json.Node cp = node.copy();
        Json.Generator g = new Json.Generator();
        g.pretty = false;
        g.root = cp;
        return g.to_data(null);
    }
}