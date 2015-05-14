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
using Tasklets;

public string test_libs(string s1, string s2) throws Error
{
    var b = new Json.Builder();
    var p1 = new Json.Parser();
    var p2 = new Json.Parser();
    // the Parser must not be destructed until we generate the JSON output.
    b.begin_object()
        .set_member_name("return-value").begin_object()
            .set_member_name("number").add_int_value(3)
            .set_member_name("list").begin_array();
                {
                    p1.load_from_data(s1);
                    b.add_value(p1.get_root());
                }
                {
                    p2.load_from_data(s2);
                    b.add_value(p2.get_root());
                }
            b.end_array()
        .end_object()
    .end_object();
    var g = new Json.Generator();
    g.pretty = false;
    g.root = b.get_root();
    return g.to_data(null);
}

namespace zcd
{
    public string get_mac(string iface)
    {
        return macgetter.get_mac(iface);
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
        public string my_addr;
        public string peer_addr;
    }

    public interface IZcdTcpRequestHandler : Object
    {
        public abstract void set_method_name(string m_name);
        public abstract void add_argument(string arg);
        public abstract void set_caller_info(TcpCallerInfo caller_info);
        public abstract IZcdDispatcher? get_dispatcher();
    }

    public interface IZcdDispatcher : Object
    {
        public abstract string execute();
    }

    public interface IZcdTcpAcceptErrorHandler : Object
    {
        public abstract void error_handler(Error e);
    }

    internal size_t max_msg_size = 10000000;

    public void tcp_listen(IZcdTcpDelegate del, IZcdTcpAcceptErrorHandler err, uint16 port, string? my_addr = null)
    {
        TcpListenTasklet t = new TcpListenTasklet();
        t.del = del;
        t.err = err;
        t.port = port;
        t.my_addr = my_addr;
        Tasklet.tasklet_callback((_t) => {
            TcpListenTasklet t_t = (TcpListenTasklet) _t;
            tcp_listen_tasklet(t_t.del, t_t.err, t_t.port, t_t.my_addr);
        }, t);
    }
    internal class TcpListenTasklet : Object
    {
        public IZcdTcpDelegate del;
        public IZcdTcpAcceptErrorHandler err;
        public uint16 port;
        public string? my_addr;
    }
    internal void tcp_listen_tasklet(IZcdTcpDelegate del, IZcdTcpAcceptErrorHandler err, uint16 port, string? my_addr)
    {
        try {
            ServerStreamSocket s = new ServerStreamSocket(port, 5, my_addr);
            debug(@"tcp_listen: Listening on port $(port) at address $(my_addr == null ? "any" : my_addr)");
            while (true) {
                IConnectedStreamSocket c = s.accept();
                debug(@"tcp_listen: got a connection");
                var req = del.get_new_handler();
                TcpAcceptTasklet t = new TcpAcceptTasklet();
                t.c = c;
                t.req = req;
                Tasklet.tasklet_callback((_t) => {
                    TcpAcceptTasklet t_t = (TcpAcceptTasklet) _t;
                    tcp_accept_tasklet(t_t.c, t_t.req);
                }, t);
            }
        } catch (Error e) {
            err.error_handler(e.copy());
        }
    }
    internal class TcpAcceptTasklet : Object
    {
        public IConnectedStreamSocket c;
        public IZcdTcpRequestHandler req;
    }
    internal void tcp_accept_tasklet(IConnectedStreamSocket c, IZcdTcpRequestHandler req)
    {
        while (true)
        {
            // Get one message
            void * m;
            size_t s;
            try {
                get_one_message(c, out m, out s);
            } catch (RecvMessageError e) {
                // log message
                warning(@"tcp_listen: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                // abort tasklet
                return;
            }
            unowned uint8[] buf;
            buf = (uint8[])m;
            buf.length = (int)s;

            // Parse JSON
            string method_name;
            string[] args;
            try {
                Json.Parser p_buf = new Json.Parser();
                p_buf.load_from_data((string)buf);
                Json.Node buf_rootnode = p_buf.get_root();
                Json.Reader r_buf = new Json.Reader(buf_rootnode);
                if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
                if (!r_buf.read_member("method-name")) throw new MessageError.MALFORMED("root must have method-name");
                if (!r_buf.is_value()) throw new MessageError.MALFORMED("method-name must be a string");
                if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("method-name must be a string");
                method_name = r_buf.get_string_value();
                r_buf.end_member();
                if (!r_buf.read_member("arguments")) throw new MessageError.MALFORMED("root must have arguments");
                if (!r_buf.is_array()) throw new MessageError.MALFORMED("arguments must be an array");
                args = new string[r_buf.count_elements()];
                for (int j = 0; j < args.length; j++)
                {
                    r_buf.read_element(j);
                    Json.Generator g = new Json.Generator();
                    g.pretty = false;
                    g.root = r_buf.get_value();
                    args[j] = g.to_data(null);
                    r_buf.end_element();
                }
                r_buf.end_member();
            } catch (Error e) {
                // log message
                warning(@"tcp_listen: Error parsing JSON of received message: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                // abort tasklet
                if (m != null) free(m);
                return;
            }

            // Get dispatcher
            TcpCallerInfo caller = new TcpCallerInfo();
            caller.my_addr = c.my_address;
            caller.peer_addr = c.peer_address;
            req.set_method_name(method_name);
            foreach (string arg in args) req.add_argument(arg);
            req.set_caller_info(caller);
            IZcdDispatcher? d = req.get_dispatcher();
            if (d == null)
            {
                // log message
                warning("tcp_listen: Delegate did not return a dispatcher for a received message.");
                // close connection
                try {c.close();} catch (Error e) {}
                // abort tasklet
                if (m != null) free(m);
                return;
            }

            // Execute
            string result = d.execute();
            string resp = build_json_response(result);
            // Send response
            try {
                send_one_message(c, resp);
            } catch (SendMessageError e) {
                // log message
                warning(@"tcp_listen: Error sending JSON of response: $(e.message)");
                // close connection
                try {c.close();} catch (Error e) {}
                // abort tasklet
                if (m != null) free(m);
                return;
            }
            if (m != null) free(m);
        }
    }

    public TcpClient tcp_client(string addr, uint16 port)
    {
        return new TcpClient(addr, port);
    }

    public class TcpClient : Object
    {
        private string addr;
        private uint16 port;
        private ClientStreamSocket? s;
        private IConnectedStreamSocket? c;
        private bool connected;
        private bool processing;
        private ArrayList<int> queue;
        internal TcpClient(string addr, uint16 port)
        {
            this.addr = addr;
            this.port = port;
            try {
                s = new ClientStreamSocket();
            } catch (Error e) {error(e.message);}
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

        public string enqueue_call(string m_name, Gee.List<string> arguments) throws ZCDError
        {
            int id = Random.int_range(0, int.MAX);
            queue.add(id);
            while (processing || queue[0] != id) ms_wait(10);
            processing = true;
            queue.remove_at(0);
            if (!connected)
            {
                try {
                    c = s.socket_connect(addr, port);
                } catch (Error e) {
                    // log message
                    warning(@"enqueue_call: could not connect to $(addr):$(port) - $(e.message)");
                    // new socket for future tentatives
                    try {
                        s = new ClientStreamSocket();
                    } catch (Error e) {error(e.message);}
                    // return error
                    processing = false;
                    throw new ZCDError.GENERIC("Trying to connect");
                }
                s = null;
                connected = true;
            }
            // build JSON message
            string msg = build_json_request(m_name, arguments);
            // Send message
            try {
                send_one_message(c, msg);
            } catch (SendMessageError e) {
                // log message
                warning(@"enqueue_call: Error sending JSON of message: $(e.message)");
                // new socket for future tentatives
                try {
                    s = new ClientStreamSocket();
                } catch (Error e) {error(e.message);}
                // close connection
                try {c.close();} catch (Error e) {}
                c = null;
                // return error
                processing = false;
                connected = false;
                throw new ZCDError.GENERIC("Trying to send message");
            }

            // Wait for result
            // Get one message
            void * m;
            size_t sz;
            try {
                get_one_message(c, out m, out sz);
            } catch (RecvMessageError e) {
                // log message
                warning(@"enqueue_call: $(e.message)");
                // new socket for future tentatives
                try {
                    s = new ClientStreamSocket();
                } catch (Error e) {error(e.message);}
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
                Json.Node buf_rootnode = p_buf.get_root();
                Json.Reader r_buf = new Json.Reader(buf_rootnode);
                if (!r_buf.is_object()) throw new MessageError.MALFORMED("root must be an object");
                if (!r_buf.read_member("response")) throw new MessageError.MALFORMED("root must have response");
                if (!r_buf.is_value()) throw new MessageError.MALFORMED("response must be a string");
                if (r_buf.get_value().get_value_type() != typeof(string)) throw new MessageError.MALFORMED("response must be a string");
                result = r_buf.get_string_value();
                r_buf.end_member();
            } catch (Error e) {
                // log message
                warning(@"enqueue_call: Error parsing JSON of received response: $(e.message)");
                // new socket for future tentatives
                try {
                    s = new ClientStreamSocket();
                } catch (Error e) {error(e.message);}
                // close connection
                try {c.close();} catch (Error e) {}
                c = null;
                // return error
                processing = false;
                connected = false;
                throw new ZCDError.GENERIC("Trying to get response");
            }
            
            processing = false;

            error("not implemented yet");
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
            c.send_new(buf_numbytes, 4);
            c.send_new(msg.data, msg.length);
        } catch (Error e) {
            throw new SendMessageError.GENERIC(@"$(e.message)");
        }
    }

    // the caller has to free m.
    internal void get_one_message(IConnectedStreamSocket c, out void * m, out size_t s) throws RecvMessageError
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
                ssize_t len = c.recv_new(b, maxlen);
                maxlen -= len;
                b += len;
            } catch (Error e) {
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
                ssize_t len = c.recv_new(b, maxlen);
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
    }

    internal string build_json_request(string m_name, Gee.List<string> arguments)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        Json.Parser[] p = new Json.Parser[arguments.size];
        // the Parser must not be destructed until we generate the JSON output.
        b.begin_object()
            .set_member_name("method-name").add_string_value(m_name)
            .set_member_name("arguments").begin_array();
                for (int j = 0; j < arguments.size; j++)
                {
                    p[j] = new Json.Parser();
                    try {
                        p[j].load_from_data(arguments[j]);
                    } catch (Error e) {
                        warning(@"Error parsing JSON for argument: $(e.message)");
                        warning(@" method-name: $(m_name)");
                        error(@" argument #$(j): $(arguments[j])");
                    }
                    b.add_value(p[j].get_root());
                }
            b.end_array()
        .end_object();
        var g = new Json.Generator();
        g.pretty = false;
        g.root = b.get_root();
        return g.to_data(null);
    }

    internal string build_json_response(string result)
    {
        // build JSON message
        Json.Builder b = new Json.Builder();
        Json.Parser p = new Json.Parser();
        // the Parser must not be destructed until we generate the JSON output.
        b.begin_object()
            .set_member_name("response");
            try {
                p.load_from_data(result);
            } catch (Error e) {
                warning(@"Error parsing JSON for response: $(e.message)");
                error(@" response: $(result)");
            }
            b.add_value(p.get_root())
        .end_object();
        var g = new Json.Generator();
        g.pretty = false;
        g.root = b.get_root();
        return g.to_data(null);
    }
}

