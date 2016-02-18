/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
    internal string get_mac(string iface)
    {
        return macgetter.get_mac(iface);
    }

    internal ITasklet tasklet;

    public void init_tasklet_system(ITasklet _tasklet)
    {
        tasklet = _tasklet;
    }

    public errordomain ZCDError {
        GENERIC
    }

    internal errordomain RecvMessageError {
        TOO_BIG,
        FAIL_ALLOC,
        GENERIC
    }

    internal errordomain SendMessageError {
        GENERIC
    }

    internal errordomain MessageError {
        MALFORMED
    }

    public interface IZcdTcpDelegate : Object
    {
        public abstract IZcdTcpRequestHandler get_new_handler();
    }

    public interface IZcdCallerInfo : Object
    {
    }

    public class TcpCallerInfo : Object, IZcdCallerInfo
    {
        internal TcpCallerInfo(string my_address, string peer_address, string source_id)
        {
            this.my_address = my_address;
            this.peer_address = peer_address;
            this.source_id = source_id;
        }
        public string my_address {get; private set;}
        public string peer_address {get; private set;}
        public string source_id {get; private set;}
    }

    public class UdpCallerInfo : Object, IZcdCallerInfo
    {
        internal UdpCallerInfo(string dev, string peer_address, string source_id)
        {
            this.dev = dev;
            this.peer_address = peer_address;
            this.source_id = source_id;
        }
        public string dev {get; private set;}
        public string peer_address {get; private set;}
        public string source_id {get; private set;}
    }

    public interface IZcdTcpRequestHandler : Object
    {
        public abstract void set_unicast_id(string unicast_id);
        public abstract void set_method_name(string m_name);
        public abstract void add_argument(string arg);
        public abstract void set_caller_info(TcpCallerInfo caller_info);
        public abstract IZcdDispatcher? get_dispatcher();
    }

    public interface IZcdUdpRequestMessageDelegate : Object
    {
        public abstract IZcdDispatcher? get_dispatcher_unicast(
            int id, string unicast_id,
            string m_name, Gee.List<string> arguments,
            UdpCallerInfo caller_info);
        public abstract IZcdDispatcher? get_dispatcher_broadcast(
            int id, string broadcast_id,
            string m_name, Gee.List<string> arguments,
            UdpCallerInfo caller_info);
    }

    public interface IZcdUdpServiceMessageDelegate : Object
    {
        public abstract bool is_my_own_message(int id);
        public abstract void got_keep_alive(int id);
        public abstract void got_response(int id, string response);
        public abstract void got_ack(int id, string mac);
    }

    public interface IZcdDispatcher : Object
    {
        public abstract string execute();
    }

    public interface IZcdTcpAcceptErrorHandler : Object
    {
        public abstract void error_handler(Error e);
    }

    public interface IZcdUdpCreateErrorHandler : Object
    {
        public abstract void error_handler(Error e);
    }

    internal size_t max_msg_size = 10000000;

    public ITaskletHandle tcp_listen(IZcdTcpDelegate del, IZcdTcpAcceptErrorHandler err, uint16 port, string? my_addr = null)
    {
        TcpListenTasklet t = new TcpListenTasklet();
        t.del = del;
        t.err = err;
        t.port = port;
        t.my_addr = my_addr;
        return tasklet.spawn(t);
    }
    internal class TcpListenTasklet : Object, ITaskletSpawnable
    {
        public IZcdTcpDelegate del;
        public IZcdTcpAcceptErrorHandler err;
        public uint16 port;
        public string? my_addr;
        public void * func()
        {
            try {
                IServerStreamSocket s = tasklet.get_server_stream_socket(port, my_addr);
                debug(@"tcp_listen: Listening on port $(port) at address $(my_addr == null ? "any" : my_addr)");
                while (true) {
                    IConnectedStreamSocket c = s.accept();
                    debug(@"tcp_listen: got a connection");
                    var req = del.get_new_handler();
                    TcpAcceptTasklet t = new TcpAcceptTasklet();
                    t.c = c;
                    t.req = req;
                    tasklet.spawn(t);
                }
            } catch (Error e) {
                err.error_handler(e.copy());
            }
            return null;
        }
    }
    internal class TcpAcceptTasklet : Object, ITaskletSpawnable
    {
        public IConnectedStreamSocket c;
        public IZcdTcpRequestHandler req;
        public void * func()
        {
            while (true)
            {
                // Get one message
                void * m;
                size_t s;
                try {
                    bool got = get_one_message(c, out m, out s);
                    if (!got)
                    {
                        // closed normally
                        debug("tcp_listen: connection closed by client.");
                        return null;
                    }
                } catch (RecvMessageError e) {
                    // log message
                    warning(@"tcp_listen: $(e.message)");
                    // close connection
                    try {c.close();} catch (Error e) {}
                    // abort tasklet
                    if (m != null) free(m);
                    return null;
                }
                unowned uint8[] buf;
                buf = (uint8[])m;
                buf.length = (int)s;

                // Parse JSON
                string source_id;
                string unicast_id;
                string method_name;
                bool wait_reply;
                string[] args;
                try {
                    // The parser must not be freed until we finish with the reader.
                    Json.Parser p_buf = new Json.Parser();
                    p_buf.load_from_data((string)buf);
                    unowned Json.Node buf_rootnode = p_buf.get_root();
                    Json.Reader r_buf = new Json.Reader(buf_rootnode);
                    if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
                    if (!r_buf.read_member("wait-reply")) throw new MessageError.MALFORMED("root must have wait-reply");
                    if (!r_buf.is_value()) throw new MessageError.MALFORMED("wait-reply must be a boolean");
                    if (r_buf.get_value().get_value_type() != typeof(bool)) throw new MessageError.MALFORMED("wait-reply must be a boolean");
                    wait_reply = r_buf.get_boolean_value();
                    r_buf.end_member();
                    if (!r_buf.read_member("unicast-id")) throw new MessageError.MALFORMED("root must have unicast-id");
                    if (!r_buf.is_object() && !r_buf.is_array())
                        throw new MessageError.MALFORMED(@"unicast-id must be a valid JSON tree");
                    r_buf.end_member();
                    unowned Json.Node node = buf_rootnode.get_object().get_member("unicast-id");
                    unicast_id = generate_stream(node);
                    parse_method_call(buf_rootnode, out source_id, out method_name, out args);
                } catch (Error e) {
                    // log message
                    warning(@"tcp_listen: Error parsing JSON of received message: $(e.message)");
                    // close connection
                    try {c.close();} catch (Error e) {}
                    // abort tasklet
                    if (m != null) free(m);
                    return null;
                }

                // Get dispatcher
                TcpCallerInfo caller = new TcpCallerInfo(c.my_address, c.peer_address, source_id);
                req.set_unicast_id(unicast_id);
                req.set_method_name(method_name);
                foreach (string arg in args) req.add_argument(arg);
                req.set_caller_info(caller);
                IZcdDispatcher? disp = req.get_dispatcher();
                if (disp == null)
                {
                    // log message
                    warning("tcp_listen: Delegate did not return a dispatcher for a received message.");
                    // close connection
                    try {c.close();} catch (Error e) {}
                    // abort tasklet
                    if (m != null) free(m);
                    return null;
                }

                // Execute
                if (wait_reply)
                {
                    string resp = disp.execute();
                    string ret_s = build_json_response(resp);
                    // Send response
                    try {
                        send_one_message(c, ret_s);
                    } catch (SendMessageError e) {
                        // log message
                        warning(@"tcp_listen: Error sending JSON of response: $(e.message)");
                        // close connection
                        try {c.close();} catch (Error e) {}
                        // abort tasklet
                        if (m != null) free(m);
                        return null;
                    }
                }
                else
                {
                    TcpDispatchTasklet t = new TcpDispatchTasklet();
                    t.disp = disp;
                    tasklet.spawn(t);
                }
                if (m != null) free(m);
            }
            // point not_reached
        }
    }
    internal class TcpDispatchTasklet : Object, ITaskletSpawnable
    {
        public IZcdDispatcher disp;
        public void * func()
        {
            disp.execute();
            return null;
        }
    }

    public TcpClient tcp_client(string peer_address, uint16 peer_port, string source_id, string unicast_id)
    {
        return new TcpClient(peer_address, peer_port, source_id, unicast_id);
    }

    public class TcpClient : Object
    {
        private string peer_address;
        private uint16 peer_port;
        private string source_id;
        private string unicast_id;
        private IConnectedStreamSocket? c;
        private bool connected;
        private bool processing;
        private ArrayList<int> queue;
        internal TcpClient(string peer_address, uint16 peer_port, string source_id, string unicast_id)
        {
            this.peer_address = peer_address;
            this.peer_port = peer_port;
            this.source_id = source_id;
            this.unicast_id = unicast_id;
            c = null;
            connected = false;
            processing = false;
            queue = new ArrayList<int>();
        }

        public bool is_queue_empty()
        {
            if (processing) return false;
            if (queue.size > 0) return false;
            return true;
        }

        public string enqueue_call(string m_name, Gee.List<string> arguments, bool wait_reply) throws ZCDError
        {
            int id = Random.int_range(0, int.MAX);
            queue.add(id);
            while (processing || queue[0] != id) tasklet.ms_wait(10);
            processing = true;
            queue.remove_at(0);
            if (!connected)
            {
                try {
                    c = tasklet.get_client_stream_socket(peer_address, peer_port);
                } catch (Error e) {
                    // log message
                    warning(@"enqueue_call: could not connect to $(peer_address):$(peer_port) - $(e.message)");
                    c = null;
                    // return error
                    processing = false;
                    throw new ZCDError.GENERIC("Trying to connect");
                }
                connected = true;
            }
            // build JSON message
            string msg = build_json_request(source_id, unicast_id, m_name, arguments, wait_reply);
            // Send message
            try {
                send_one_message(c, msg);
            } catch (SendMessageError e) {
                // log message
                warning(@"enqueue_call: Error sending JSON of message: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                c = null;
                // return error
                processing = false;
                connected = false;
                throw new ZCDError.GENERIC("Trying to send message");
            }

            if (!wait_reply)
            {
                processing = false;
                return "";
            }
            // Wait for result
            // Get one message
            void * m;
            size_t sz;
            try {
                bool got = get_one_message(c, out m, out sz);
                if (!got) throw new RecvMessageError.GENERIC("Response did not come");
            } catch (RecvMessageError e) {
                // log message
                warning(@"enqueue_call: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                c = null;
                // return error
                processing = false;
                connected = false;
                throw new ZCDError.GENERIC("Trying to get response");
            }
            unowned uint8[] buf;
            buf = (uint8[])m;
            buf.length = (int)sz;

            // Parse JSON
            string result;
            try {
                Json.Parser p_buf = new Json.Parser();
                p_buf.load_from_data((string)buf);
                unowned Json.Node buf_rootnode = p_buf.get_root();
                Json.Reader r_buf = new Json.Reader(buf_rootnode);
                if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
                if (!r_buf.read_member("response")) throw new MessageError.MALFORMED("root must have response");
                if (!r_buf.is_object() && !r_buf.is_array()) throw new MessageError.MALFORMED("response must be a valid JSON tree");
                r_buf.end_member();
                Json.Node cp = buf_rootnode.get_object().get_member("response").copy();
                Json.Generator g = new Json.Generator();
                g.pretty = false;
                g.root = cp;
                result = g.to_data(null);
            } catch (Error e) {
                // log message
                warning(@"enqueue_call: Error parsing JSON of received response: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                c = null;
                // return error
                processing = false;
                connected = false;
                throw new ZCDError.GENERIC("Trying to get response");
            }

            processing = false;
            return result;
        }

        ~TcpClient()
        {
            // TODO Make a testsuite to make sure that if a call is in progress
            //  then this instance is not destroyed.
            if (connected)
            {
                try {c.close();} catch (Error e) {}
            }
        }
    }

    internal void send_one_message(IConnectedStreamSocket c, string msg) throws SendMessageError
    {
        size_t len = msg.length;
        assert(len <= uint32.MAX);
        uint8 buf_numbytes[4];
        buf_numbytes[3] = (uint8)(len % 256);
        len -= buf_numbytes[3];
        len /= 256;
        buf_numbytes[2] = (uint8)(len % 256);
        len -= buf_numbytes[2];
        len /= 256;
        buf_numbytes[1] = (uint8)(len % 256);
        len -= buf_numbytes[1];
        len /= 256;
        buf_numbytes[0] = (uint8)(len % 256);
        try {
            c.send(buf_numbytes, 4);
            c.send(msg.data, msg.length);
        } catch (Error e) {
            throw new SendMessageError.GENERIC(@"$(e.message)");
        }
    }

    // the caller has to free m.
    internal bool get_one_message(IConnectedStreamSocket c, out void * m, out size_t s) throws RecvMessageError
    {
        // Get one message
        m = null;
        s = 0;
        unowned uint8[] buf;

        uint8 buf_numbytes[4];
        size_t maxlen = 4;
        uint8* b = buf_numbytes;
        while (maxlen > 0)
        {
            try {
                size_t len = c.recv(b, maxlen);
                maxlen -= len;
                b += len;
            } catch (Error e) {
                if (maxlen == 4)
                {
                    // normal closing from client, abnormal if from server.
                    return false;
                }
                throw new RecvMessageError.GENERIC(e.message);
            }
        }
        size_t msglen = buf_numbytes[0];
        msglen *= 256;
        msglen += buf_numbytes[1];
        msglen *= 256;
        msglen += buf_numbytes[2];
        msglen *= 256;
        msglen += buf_numbytes[3];
        if (msglen > max_msg_size)
        {
            throw new RecvMessageError.TOO_BIG(@"Refusing to receive a message too big ($(msglen) bytes)");
        }

        s = msglen + 1;
        m = try_malloc(s);
        if (m == null)
        {
            throw new RecvMessageError.FAIL_ALLOC(@"Could not allocate memory ($(s) bytes)");
        }
        buf = (uint8[])m;
        buf.length = (int)s;
        maxlen = msglen;
        b = buf;
        while (maxlen > 0)
        {
            try {
                size_t len = c.recv(b, maxlen);
                maxlen -= len;
                b += len;
            } catch (Error e) {
                free(m);
                m = null;
                s = 0;
                throw new RecvMessageError.GENERIC(e.message);
            }
        }
        buf[msglen] = (uint8)0;
        return true;
    }

    internal string build_json_request(string source_id, string unicast_id, string m_name, Gee.List<string> arguments, bool wait_reply)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        b.begin_object()
            .set_member_name("method-name").add_string_value(m_name);

            // source_id
            b.set_member_name("source-id");
            {
                var p = new Json.Parser();
                try {
                    p.load_from_data(source_id);
                } catch (Error e) {
                    critical(@"Error parsing JSON for source_id: $(e.message)");
                    error(@" string source_id : $(source_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }
            // unicast_id
            b.set_member_name("unicast-id");
            {
                var p = new Json.Parser();
                try {
                    p.load_from_data(unicast_id);
                } catch (Error e) {
                    critical(@"Error parsing JSON for unicast_id: $(e.message)");
                    error(@" string unicast_id : $(unicast_id)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp);
            }

            b.set_member_name("wait-reply").add_boolean_value(wait_reply)
            .set_member_name("arguments").begin_array();
                for (int j = 0; j < arguments.size; j++)
                {
                    var p = new Json.Parser();
                    try {
                        p.load_from_data(arguments[j]);
                    } catch (Error e) {
                        critical(@"Error parsing JSON for argument: $(e.message)");
                        critical(@" method-name: $(m_name)");
                        error(@" argument #$(j): $(arguments[j])");
                    }
                    unowned Json.Node p_rootnode = p.get_root();
                    Json.Node* cp = p_rootnode.copy();
                    b.add_value(cp);
                }
            b.end_array()
        .end_object();
        Json.Node node = b.get_root();
        return generate_stream(node);
    }

    internal string build_json_response(string result)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        Json.Parser p = new Json.Parser();
        b.begin_object()
            .set_member_name("response");
            try {
                p.load_from_data(result);
            } catch (Error e) {
                critical(@"Error parsing JSON for response: $(e.message)");
                error(@" response: $(result)");
            }
            unowned Json.Node p_rootnode = p.get_root();
            Json.Node* cp = p_rootnode.copy();
            b.add_value(cp)
        .end_object();
        Json.Node node = b.get_root();
        return generate_stream(node);
    }

    internal size_t max_pkt_size = 60000;
    internal int keepalive_interval_ms = 1000;
    internal const string s_unicast_request = "unicast-request";
    internal const string s_unicast_request_id = "ID";
    internal const string s_unicast_request_request = "request";
    internal const string s_unicast_request_request_wait_reply = "wait-reply";
    internal const string s_unicast_request_request_unicast_id = "unicast-id";
    internal const string s_unicast_request_request_source_id = "source-id";
    internal const string s_unicast_keepalive = "unicast-keepalive";
    internal const string s_unicast_keepalive_id = "ID";
    internal const string s_unicast_response = "unicast-response";
    internal const string s_unicast_response_id = "ID";
    internal const string s_unicast_response_response = "response";
    internal const string s_broadcast_request = "broadcast-request";
    internal const string s_broadcast_request_id = "ID";
    internal const string s_broadcast_request_request = "request";
    internal const string s_broadcast_request_request_send_ack = "send-ack";
    internal const string s_broadcast_request_request_broadcast_id = "broadcast-id";
    internal const string s_broadcast_request_request_source_id = "source-id";
    internal const string s_broadcast_ack = "broadcast-ack";
    internal const string s_broadcast_ack_id = "ID";
    internal const string s_broadcast_ack_mac = "MAC";

    public ITaskletHandle udp_listen(IZcdUdpRequestMessageDelegate del_req,
                           IZcdUdpServiceMessageDelegate del_ser,
                           IZcdUdpCreateErrorHandler err,
                           uint16 port, string dev)
    {
        UdpListenTasklet t = new UdpListenTasklet();
        t.del_req = del_req;
        t.del_ser = del_ser;
        t.err = err;
        t.port = port;
        t.dev = dev;
        return tasklet.spawn(t);
    }
    internal class UdpListenTasklet : Object, ITaskletSpawnable
    {
        public IZcdUdpRequestMessageDelegate del_req;
        public IZcdUdpServiceMessageDelegate del_ser;
        public IZcdUdpCreateErrorHandler err;
        public uint16 port;
        public string dev;
        public void * func()
        {
            try {
                IServerDatagramSocket s = tasklet.get_server_datagram_socket(port, dev);
                debug(@"udp_listen: Listening on port $(port) at dev $(dev)");
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
                        string rmt_ip;
                        uint16 rmt_port;
                        size_t msglen = s.recvfrom(b, max_pkt_size, out rmt_ip, out rmt_port);
                        b[msglen++] = 0; // NULL terminate
                        UdpMsgTasklet t = new UdpMsgTasklet();
                        t.b = b;
                        t.msglen = msglen;
                        t.rmt_ip = rmt_ip;
                        t.rmt_port = rmt_port;
                        t.port = port;
                        t.dev = dev;
                        t.del_req = del_req;
                        t.del_ser = del_ser;
                        tasklet.spawn(t);
                    } catch (Error e) {
                        // temporary error
                        warning(@"udp_listen: temporary error $(e.message)");
                        tasklet.ms_wait(20);
                    }
                }
            } catch (Error e) {
                // udp_listen fatal error
                err.error_handler(e.copy());
            }
            return null;
        }
    }
    internal class UdpMsgTasklet : Object, ITaskletSpawnable
    {
        public uint8* b;
        public size_t msglen;
        public string rmt_ip;
        public uint16 rmt_port;
        public uint16 port;
        public string dev;
        public IZcdUdpRequestMessageDelegate del_req;
        public IZcdUdpServiceMessageDelegate del_ser;
        public void * func()
        {
            // There must be no '\0' in the message
            for (int i = 0; i < msglen-1; i++)
            {
                if (b[i] == 0)
                {
                    warning(@"udp_listen: malformed message has a NULL byte");
                    return null;
                }
            }
            if (b[msglen-1] != 0)
            {
                warning(@"udp_listen: malformed message has not a NULL terminator");
                return null;
            }
            unowned uint8[] buf;
            buf = (uint8[])b;
            buf.length = (int)msglen;
            string msg = (string)buf;
            free(b);
            debug(@"udp_listen: got: $(msg)");
            try {
                Json.Parser p_buf = new Json.Parser();
                p_buf.load_from_data(msg);
                unowned Json.Node buf_rootnode = p_buf.get_root();
                Json.Reader r_buf = new Json.Reader(buf_rootnode);
                if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
                string[] members = r_buf.list_members();
                if (members.length != 1) throw new MessageError.MALFORMED("root must have 1 member");
                switch (members[0]) {
                    case s_unicast_request:
                        r_buf.read_member(s_unicast_request);
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"the member $(s_unicast_request) must be an object");
                        if (!r_buf.read_member(s_unicast_request_id))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_unicast_request) must have $(s_unicast_request_id)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_id) must be a int");
                        if (r_buf.get_value().get_value_type() != typeof(int64))
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_id) must be a int");
                        int64 val = r_buf.get_int_value();
                        if (val > int.MAX || val < int.MIN)
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_id) overflows size of int");
                        int unicast_request_id = (int)val;
                        r_buf.end_member();
                        if (!r_buf.read_member(s_unicast_request_request))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_unicast_request) must have $(s_unicast_request_request)");
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_request) must be an object");
                        if (!r_buf.read_member(s_unicast_request_request_wait_reply))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_unicast_request_request) must have $(s_unicast_request_request_wait_reply)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_request_wait_reply) must be a boolean");
                        if (r_buf.get_value().get_value_type() != typeof(bool))
                            throw new MessageError.MALFORMED(@"$(s_unicast_request_request_wait_reply) must be a boolean");
                        bool unicast_request_request_wait_reply = r_buf.get_boolean_value();
                        r_buf.end_member();
                        r_buf.end_member();
                        r_buf.end_member();
                        string unicast_request_request_source_id;
                        string unicast_request_request_method_name;
                        string[] unicast_request_request_args;
                        unowned Json.Node node_req =
                            buf_rootnode.get_object().get_object_member(s_unicast_request).get_member(s_unicast_request_request);
                        parse_method_call(
                            node_req,
                            out unicast_request_request_source_id,
                            out unicast_request_request_method_name,
                            out unicast_request_request_args);
                        string unicast_request_request_unicast_id = parse_unicast_id(node_req);
                        if (del_ser.is_my_own_message(unicast_request_id))
                        {
                            return null;
                        }
                        UdpCallerInfo caller_info = new UdpCallerInfo(dev, rmt_ip, unicast_request_request_source_id);
                        IZcdDispatcher? disp = del_req.get_dispatcher_unicast(
                            unicast_request_id,
                            unicast_request_request_unicast_id,
                            unicast_request_request_method_name,
                            new ArrayList<string>.wrap(unicast_request_request_args),
                            caller_info);
                        if (disp != null)
                        {
                            ITaskletHandle? t_keepalive = null;
                            if (unicast_request_request_wait_reply)
                            {
                                UdpKeepaliveTasklet t = new UdpKeepaliveTasklet();
                                t.dev = dev;
                                t.port = port;
                                t.id = unicast_request_id;
                                t_keepalive = tasklet.spawn(t);
                            }
                            string resp = disp.execute();
                            if (t_keepalive != null)
                            {
                                t_keepalive.kill();
                                var p = new Json.Parser();
                                try {
                                    p.load_from_data(resp);
                                } catch (Error e) {
                                    critical(@"Error parsing JSON for response: $(e.message)");
                                    critical(@" method-name: $(unicast_request_request_method_name)");
                                    critical( " mode unicast");
                                    error(   @" response: $(resp)");
                                }
                                unowned Json.Node resp_rootnode = p.get_root();
                                if (resp_rootnode.get_node_type() != Json.NodeType.ARRAY &&
                                    resp_rootnode.get_node_type() != Json.NodeType.OBJECT)
                                {
                                    critical( "Error parsing JSON for response: root should be OBJECT or ARRAY");
                                    critical(@" method-name: $(unicast_request_request_method_name)");
                                    critical( " mode unicast");
                                    error(   @" response: $(resp)");
                                }
                                string json_resp = build_json_unicast_response(unicast_request_id, resp);
                                try {
                                    IClientDatagramSocket cs = tasklet.get_client_datagram_socket(port, dev);
                                    cs.sendto(json_resp.data, json_resp.length);
                                } catch (Error e) {
                                    // log message
                                    warning(@"udp_listen: Error sending response: $(e.message)");
                                    // terminate tasklet
                                    return null;
                                }
                            }
                            // done
                        }
                        // done
                        break;
                    case s_unicast_keepalive:
                        r_buf.read_member(s_unicast_keepalive);
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"the member $(s_unicast_keepalive) must be an object");
                        if (!r_buf.read_member(s_unicast_keepalive_id))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_unicast_keepalive) must have $(s_unicast_keepalive_id)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_unicast_keepalive_id) must be a int");
                        if (r_buf.get_value().get_value_type() != typeof(int64))
                            throw new MessageError.MALFORMED(@"$(s_unicast_keepalive_id) must be a int");
                        int64 val = r_buf.get_int_value();
                        if (val > int.MAX || val < int.MIN)
                            throw new MessageError.MALFORMED(@"$(s_unicast_keepalive_id) overflows size of int");
                        int unicast_keepalive_id = (int)val;
                        r_buf.end_member();
                        del_ser.got_keep_alive(unicast_keepalive_id);
                        // done
                        break;
                    case s_unicast_response:
                        r_buf.read_member(s_unicast_response);
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"the member $(s_unicast_response) must be an object");
                        if (!r_buf.read_member(s_unicast_response_id))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_unicast_response) must have $(s_unicast_response_id)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_unicast_response_id) must be a int");
                        if (r_buf.get_value().get_value_type() != typeof(int64))
                            throw new MessageError.MALFORMED(@"$(s_unicast_response_id) must be a int");
                        int64 val = r_buf.get_int_value();
                        if (val > int.MAX || val < int.MIN)
                            throw new MessageError.MALFORMED(@"$(s_unicast_response_id) overflows size of int");
                        int unicast_response_id = (int)val;
                        r_buf.end_member();
                        unowned Json.Node node_resp =
                            buf_rootnode.get_object().get_member(s_unicast_response);
                        string unicast_response_response = parse_unicast_response(node_resp);
                        del_ser.got_response(unicast_response_id, unicast_response_response);
                        // done
                        break;
                    case s_broadcast_request:
                        r_buf.read_member(s_broadcast_request);
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"the member $(s_broadcast_request) must be an object");
                        if (!r_buf.read_member(s_broadcast_request_id))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_broadcast_request) must have $(s_broadcast_request_id)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_id) must be a int");
                        if (r_buf.get_value().get_value_type() != typeof(int64))
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_id) must be a int");
                        int64 val = r_buf.get_int_value();
                        if (val > int.MAX || val < int.MIN)
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_id) overflows size of int");
                        int broadcast_request_id = (int)val;
                        r_buf.end_member();
                        if (!r_buf.read_member(s_broadcast_request_request))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_broadcast_request) must have $(s_broadcast_request_request)");
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_request) must be an object");
                        if (!r_buf.read_member(s_broadcast_request_request_send_ack))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_broadcast_request_request) must have $(s_broadcast_request_request_send_ack)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_request_send_ack) must be a boolean");
                        if (r_buf.get_value().get_value_type() != typeof(bool))
                            throw new MessageError.MALFORMED(@"$(s_broadcast_request_request_send_ack) must be a boolean");
                        bool broadcast_request_request_send_ack = r_buf.get_boolean_value();
                        r_buf.end_member();
                        r_buf.end_member();
                        r_buf.end_member();
                        string broadcast_request_request_source_id;
                        string broadcast_request_request_method_name;
                        string[] broadcast_request_request_args;
                        unowned Json.Node node_req =
                            buf_rootnode.get_object().get_object_member(s_broadcast_request).get_member(s_broadcast_request_request);
                        parse_method_call(
                            node_req,
                            out broadcast_request_request_source_id,
                            out broadcast_request_request_method_name,
                            out broadcast_request_request_args);
                        string broadcast_request_request_broadcast_id = parse_broadcast_id(node_req);
                        if (del_ser.is_my_own_message(broadcast_request_id))
                            return null;
                        if (broadcast_request_request_send_ack)
                        {
                            UdpAckTasklet t = new UdpAckTasklet();
                            t.dev = dev;
                            t.port = port;
                            t.id = broadcast_request_id;
                            tasklet.spawn(t);
                        }
                        UdpCallerInfo caller_info = new UdpCallerInfo(dev, rmt_ip, broadcast_request_request_source_id);
                        IZcdDispatcher? disp = del_req.get_dispatcher_broadcast(
                            broadcast_request_id,
                            broadcast_request_request_broadcast_id,
                            broadcast_request_request_method_name,
                            new ArrayList<string>.wrap(broadcast_request_request_args),
                            caller_info);
                        if (disp != null)
                        {
                            disp.execute();
                            // done
                        }
                        // done
                        break;
                    case s_broadcast_ack:
                        r_buf.read_member(s_broadcast_ack);
                        if (!r_buf.is_object())
                            throw new MessageError.MALFORMED(@"the member $(s_broadcast_ack) must be an object");
                        if (!r_buf.read_member(s_broadcast_ack_id))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_broadcast_ack) must have $(s_broadcast_ack_id)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_broadcast_ack_id) must be a int");
                        if (r_buf.get_value().get_value_type() != typeof(int64))
                            throw new MessageError.MALFORMED(@"$(s_broadcast_ack_id) must be a int");
                        int64 val = r_buf.get_int_value();
                        if (val > int.MAX || val < int.MIN)
                            throw new MessageError.MALFORMED(@"$(s_broadcast_ack_id) overflows size of int");
                        int broadcast_ack_id = (int)val;
                        r_buf.end_member();
                        if (!r_buf.read_member(s_broadcast_ack_mac))
                            throw new MessageError.MALFORMED(
                            @"the member $(s_broadcast_ack) must have $(s_broadcast_ack_mac)");
                        if (!r_buf.is_value())
                            throw new MessageError.MALFORMED(@"$(s_broadcast_ack_mac) must be a string");
                        if (r_buf.get_value().get_value_type() != typeof(string))
                            throw new MessageError.MALFORMED(@"$(s_broadcast_ack_mac) must be a string");
                        string broadcast_ack_mac = r_buf.get_string_value();
                        r_buf.end_member();
                        del_ser.got_ack(broadcast_ack_id, broadcast_ack_mac);
                        // done
                        break;
                    default:
                        throw new MessageError.MALFORMED(@"root has unknown member $(members[0])");
                }
            } catch (Error e) {
                // log message
                warning(@"udp_listen: Error parsing JSON of received message: $(e.message)");
                // terminate tasklet
                return null;
            }
            return null;
        }
    }
    internal class UdpKeepaliveTasklet : Object, ITaskletSpawnable
    {
        public uint16 port;
        public string dev;
        public int id;
        public void * func()
        {
            while (true)
            {
                string msg = build_json_keepalive(id);
                try {
                    IClientDatagramSocket cs = tasklet.get_client_datagram_socket(port, dev);
                    cs.sendto(msg.data, msg.length);
                } catch (Error e) {
                    // log message
                    warning(@"udp_listen: Error sending keepalive: $(e.message)");
                    // will keep on trying
                }
                tasklet.ms_wait(keepalive_interval_ms);
            }
        }
    }
    internal class UdpAckTasklet : Object, ITaskletSpawnable
    {
        public uint16 port;
        public string dev;
        public int id;
        public void * func()
        {
            for (int i = 0; i < 3; i++)
            {
                string msg = build_json_ack(dev, id);
                try {
                    IClientDatagramSocket cs = tasklet.get_client_datagram_socket(port, dev);
                    cs.sendto(msg.data, msg.length);
                } catch (Error e) {
                    // log message
                    warning(@"udp_listen: Error sending ack: $(e.message)");
                    // ignore this one, hope better luck on the other ones
                }
                tasklet.ms_wait(Random.int_range(10, 200));
            }
            return null;
        }
    }

    public void send_unicast_request
                (string dev, uint16 port, int id,
                 string unicast_id,
                 string m_name,
                 Gee.List<string> arguments,
                 string source_id,
                 bool wait_reply) throws ZCDError
    {
        // check JSON elements
        Json.Node* j_unicast_id;
        Json.Node* j_source_id;
        Gee.List<Json.Node> j_arguments = new ArrayList<Json.Node>();
        try {
            Json.Parser p = new Json.Parser();
            p.load_from_data(unicast_id);
            j_unicast_id = p.get_root().copy();
            p = new Json.Parser();
            p.load_from_data(source_id);
            j_source_id = p.get_root().copy();
            foreach (string argument in arguments)
            {
                p = new Json.Parser();
                p.load_from_data(argument);
                j_arguments.add(p.get_root().copy());
            }
        } catch (Error e) {
            error(@"send_unicast_request: Error parsing JSON element: $(e.message)");
        }
        // build JSON message
        Json.Builder b = new Json.Builder();
        b.begin_object()
            .set_member_name(s_unicast_request).begin_object()
                .set_member_name(s_unicast_request_id).add_int_value(id)
                .set_member_name(s_unicast_request_request).begin_object()
                    .set_member_name(s_unicast_request_request_unicast_id).add_value(j_unicast_id)
                    .set_member_name(s_unicast_request_request_source_id).add_value(j_source_id)
                    .set_member_name(s_unicast_request_request_wait_reply).add_boolean_value(wait_reply)
                    .set_member_name("method-name").add_string_value(m_name)
                    .set_member_name("arguments").begin_array();
                    foreach (Json.Node arg in j_arguments)
                    {
                        Json.Node* cp = arg.copy();
                        b.add_value(cp);
                    }
                    b.end_array()
                .end_object()
            .end_object()
        .end_object();
        Json.Node node = b.get_root();
        string msg = generate_stream(node);
        try {
            IClientDatagramSocket cs = tasklet.get_client_datagram_socket(port, dev);
            cs.sendto(msg.data, msg.length);
        } catch (Error e) {
            throw new ZCDError.GENERIC("Trying to send message");
        }
        // We use pointers to Json.Node because of a bug in vapi file of json-glib, which should be fixed in valac 0.28
        // Method b.add_value should declare that the argument is 'owned'.
        // If 'j_unicast_id' was not a pointer, here the release of 'b' would make the release of 'j_unicast_id' to fail.
    }

    public void send_broadcast_request
                (string dev, uint16 port, int id,
                 string broadcast_id,
                 string m_name,
                 Gee.List<string> arguments,
                 string source_id,
                 bool send_ack) throws ZCDError
    {
        // check JSON elements
        Json.Node* j_broadcast_id;
        Json.Node* j_source_id;
        Gee.List<Json.Node> j_arguments = new ArrayList<Json.Node>();
        try {
            Json.Parser p = new Json.Parser();
            p.load_from_data(broadcast_id);
            j_broadcast_id = p.get_root().copy();
            p = new Json.Parser();
            p.load_from_data(source_id);
            j_source_id = p.get_root().copy();
            foreach (string argument in arguments)
            {
                p = new Json.Parser();
                p.load_from_data(argument);
                j_arguments.add(p.get_root().copy());
            }
        } catch (Error e) {
            error(@"send_broadcast_request: Error parsing JSON element: $(e.message)");
        }
        // build JSON message
        Json.Builder b = new Json.Builder();
        b.begin_object()
            .set_member_name(s_broadcast_request).begin_object()
                .set_member_name(s_broadcast_request_id).add_int_value(id)
                .set_member_name(s_broadcast_request_request).begin_object()
                    .set_member_name(s_broadcast_request_request_broadcast_id).add_value(j_broadcast_id)
                    .set_member_name(s_broadcast_request_request_source_id).add_value(j_source_id)
                    .set_member_name(s_broadcast_request_request_send_ack).add_boolean_value(send_ack)
                    .set_member_name("method-name").add_string_value(m_name)
                    .set_member_name("arguments").begin_array();
                    foreach (Json.Node arg in j_arguments)
                    {
                        Json.Node* cp = arg.copy();
                        b.add_value(cp);
                    }
                    b.end_array()
                .end_object()
            .end_object()
        .end_object();
        Json.Node node = b.get_root();
        string msg = generate_stream(node);
        try {
            IClientDatagramSocket cs = tasklet.get_client_datagram_socket(port, dev);
            cs.sendto(msg.data, msg.length);
        } catch (Error e) {
            throw new ZCDError.GENERIC("Trying to send message");
        }
    }

    internal string build_json_keepalive(int id)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        b.begin_object()
            .set_member_name(s_unicast_keepalive).begin_object()
                .set_member_name(s_unicast_keepalive_id).add_int_value(id)
            .end_object()
        .end_object();
        Json.Node node = b.get_root();
        return generate_stream(node);
    }

    internal string build_json_ack(string dev, int id)
    {
        // build JSON message
        string mac = get_mac(dev).up();
        Json.Builder b = new Json.Builder();
        b.begin_object()
            .set_member_name(s_broadcast_ack).begin_object()
                .set_member_name(s_broadcast_ack_id).add_int_value(id)
                .set_member_name(s_broadcast_ack_mac).add_string_value(mac)
            .end_object()
        .end_object();
        Json.Node node = b.get_root();
        return generate_stream(node);
    }

    internal string build_json_unicast_response(int id, string result)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        Json.Parser p = new Json.Parser();
        b.begin_object()
            .set_member_name(s_unicast_response).begin_object()
                .set_member_name(s_unicast_response_id).add_int_value(id)
                .set_member_name(s_unicast_response_response);
                try {
                    p.load_from_data(result);
                } catch (Error e) {
                    critical(@"Error parsing JSON for response: $(e.message)");
                    error(@" response: $(result)");
                }
                unowned Json.Node p_rootnode = p.get_root();
                Json.Node* cp = p_rootnode.copy();
                b.add_value(cp)
            .end_object()
        .end_object();
        Json.Node node = b.get_root();
        return generate_stream(node);
    }

    internal string parse_unicast_id(Json.Node buf_rootnode) throws MessageError
    {
        Json.Reader r_buf = new Json.Reader(buf_rootnode);
        assert(r_buf.is_object());
        if (!r_buf.read_member(s_unicast_request_request_unicast_id))
            throw new MessageError.MALFORMED(@"$(s_unicast_request_request) must have $(s_unicast_request_request_unicast_id)");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"$(s_unicast_request_request_unicast_id) must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member(s_unicast_request_request_unicast_id);
        return generate_stream(node);
    }

    internal string parse_unicast_response(Json.Node buf_rootnode) throws MessageError
    {
        Json.Reader r_buf = new Json.Reader(buf_rootnode);
        assert(r_buf.is_object());
        if (!r_buf.read_member(s_unicast_response_response))
            throw new MessageError.MALFORMED(@"$(s_unicast_response) must have $(s_unicast_response_response)");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"$(s_unicast_response_response) must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member(s_unicast_response_response);
        return generate_stream(node);
    }

    internal string parse_broadcast_id(Json.Node buf_rootnode) throws MessageError
    {
        Json.Reader r_buf = new Json.Reader(buf_rootnode);
        assert(r_buf.is_object());
        if (!r_buf.read_member(s_broadcast_request_request_broadcast_id))
            throw new MessageError.MALFORMED(@"$(s_broadcast_request_request) must have $(s_broadcast_request_request_broadcast_id)");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"$(s_broadcast_request_request_broadcast_id) must be a valid JSON tree");
        r_buf.end_member();
        unowned Json.Node node = buf_rootnode.get_object().get_member(s_broadcast_request_request_broadcast_id);
        return generate_stream(node);
    }

    internal void parse_method_call(Json.Node buf_rootnode, out string source_id, out string method_name, out string[] args) throws MessageError
    {
        Json.Reader r_buf = new Json.Reader(buf_rootnode);
        assert(r_buf.is_object());
        if (!r_buf.read_member("source-id")) throw new MessageError.MALFORMED("object must have source-id");
        if (!r_buf.is_object() && !r_buf.is_array())
            throw new MessageError.MALFORMED(@"source-id must be a valid JSON tree");
        r_buf.end_member();
        if (!r_buf.read_member("method-name")) throw new MessageError.MALFORMED("object must have method-name");
        if (!r_buf.is_value()) throw new MessageError.MALFORMED("method-name must be a string");
        if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("method-name must be a string");
        method_name = r_buf.get_string_value();
        r_buf.end_member();
        if (!r_buf.read_member("arguments")) throw new MessageError.MALFORMED("object must have arguments");
        if (!r_buf.is_array()) throw new MessageError.MALFORMED("arguments must be an array");
        args = new string[r_buf.count_elements()];
        for (int j = 0; j < args.length; j++)
        {
            r_buf.read_element(j);
            if (!r_buf.is_object() && !r_buf.is_array()) throw new MessageError.MALFORMED("each argument must be a valid JSON tree");
            r_buf.end_element();
        }
        r_buf.end_member();
        for (int j = 0; j < args.length; j++)
        {
            unowned Json.Node node = buf_rootnode.get_object().get_array_member("arguments").get_element(j);
            args[j] = generate_stream(node);
        }
        unowned Json.Node node = buf_rootnode.get_object().get_member("source-id");
        source_id = generate_stream(node);
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

