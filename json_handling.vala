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
    internal errordomain MessageError {
        MALFORMED
    }

    internal errordomain InvalidJsonError {
        GENERIC
    }

    internal bool check_valid_json(string json_tree)
    {
        error("not implemented yet");
    }

    internal void build_connection_request(
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
                foreach (string arg in arguments)
                {
                    var p = new Json.Parser();
                    try {
                        p.load_from_data(arg);
                    } catch (Error e) {
                        throw new InvalidJsonError.GENERIC(
                            @"Error parsing JSON for argument: $(e.message)"
                            + @" method-name: $(m_name)"
                            + @" argument #$(j): $(arg)");
                    }
                    unowned Json.Node p_rootnode = p.get_root();
                    Json.Node* cp = p_rootnode.copy();
                    b.add_value(cp);
                }
            b.end_array();

            b.set_member_name("source-id");
            {
                var p = new Json.Parser();
                try {
                    p.load_from_data(source_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for source_id: $(e.message)"
                        + @" string source_id : $(source_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("unicast-id");
            {
                var p = new Json.Parser();
                try {
                    p.load_from_data(unicast_id);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for unicast_id: $(e.message)"
                        + @" string unicast_id : $(unicast_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("src-nic");
            {
                var p = new Json.Parser();
                try {
                    p.load_from_data(src_nic);
                } catch (Error e) {
                    throw new InvalidJsonError.GENERIC(
                        @"Error parsing JSON for src_nic: $(e.message)"
                        + @" string src_nic : $(src_nic)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("wait-reply").add_boolean_value(wait_reply);
        b.end_object();
        Json.Node node = b.get_root();
        json_tree_request = generate_stream(node);
    }

    internal void parse_connection_request(
        string json_tree_request,
        out string m_name,
        out Gee.List<string> arguments,
        out string source_id,
        out string unicast_id,
        out string src_nic,
        out bool wait_reply)
        throws MessageError
    {
        // The parser must not be freed until we finish with the reader.
        Json.Parser p_buf = new Json.Parser();
        p_buf.load_from_data(json_tree_request);
        unowned Json.Node buf_rootnode = p_buf.get_root();
        Json.Reader r_buf = new Json.Reader(buf_rootnode);
        if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");

        if (!r_buf.read_member("method-name")) throw new MessageError.MALFORMED("object must have method-name");
        if (!r_buf.is_value()) throw new MessageError.MALFORMED("method-name must be a string");
        if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("method-name must be a string");
        m_name = r_buf.get_string_value();
        r_buf.end_member();

        if (!r_buf.read_member("arguments")) throw new MessageError.MALFORMED("object must have arguments");
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
            unowned Json.Node node = buf_rootnode.get_object().get_array_member("arguments").get_element(j);
            arguments.add(generate_stream(node));
        }

        if (!r_buf.read_member("source-id")) throw new MessageError.MALFORMED("root must have source-id");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"source-id must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member("source-id");
        source_id = generate_stream(node);

        if (!r_buf.read_member("unicast-id")) throw new MessageError.MALFORMED("root must have unicast-id");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"unicast-id must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member("unicast-id");
        unicast_id = generate_stream(node);

        if (!r_buf.read_member("src-nic")) throw new MessageError.MALFORMED("root must have src-nic");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"src-nic must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member("src-nic");
        src_nic = generate_stream(node);

        if (!r_buf.read_member("wait-reply")) throw new MessageError.MALFORMED("root must have wait-reply");
        if (!r_buf.is_value()) throw new MessageError.MALFORMED("wait-reply must be a boolean");
        if (r_buf.get_value().get_value_type() != typeof(bool)) throw new MessageError.MALFORMED("wait-reply must be a boolean");
        wait_reply = r_buf.get_boolean_value();
        r_buf.end_member();
    }

    internal void build_connection_response(
        string response,
        out string json_tree_response)
        throws InvalidJsonError
    {
        error("not implemented yet");
    }

    internal void parse_connection_response(
        string json_tree_response,
        out string response)
        throws MessageError
    {
        error("not implemented yet");
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