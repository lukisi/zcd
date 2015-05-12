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

    public interface IZcdTcpDelegate : Object
    {
        public abstract IZcdTcpRequestHandler get_new_handler();
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
            while (true) {
                IConnectedStreamSocket c = s.accept();
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
    }

}

