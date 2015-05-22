/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

using Tasklets;
using Gee;
using zcd;

namespace AppDomain
{
    namespace ModRpc
    {
        public errordomain StubError
        {
            GENERIC
        }

        public errordomain DeserializeError
        {
            GENERIC
        }

        public interface ITcpClientRootStub : Object
        {
            protected abstract bool hurry_getter();
            protected abstract void hurry_setter(bool new_value);
            public bool hurry {
                get {
                    return hurry_getter();
                }
                set {
                    hurry_setter(value);
                }
            }

            protected abstract bool wait_reply_getter();
            protected abstract void wait_reply_setter(bool new_value);
            public bool wait_reply {
                get {
                    return wait_reply_getter();
                }
                set {
                    wait_reply_setter(value);
                }
            }
        }

        internal delegate string FakeRmt(string m_name, Gee.List<string> arguments) throws ZCDError;

        public interface IInfoManagerStub : Object
        {
            public abstract string get_name() throws StubError, DeserializeError;
            public abstract void set_name(string name) throws AuthError, BadArgsError, StubError, DeserializeError;
            public abstract int get_year() throws StubError, DeserializeError;
            public abstract bool set_year(int year) throws StubError, DeserializeError;
            public abstract License get_license() throws StubError, DeserializeError;
        }

        public interface ICalculatorStub : Object
        {
            public abstract IDocument get_root() throws StubError, DeserializeError;
            public abstract Gee.List<IDocument> get_children(IDocument parent) throws StubError, DeserializeError;
            public abstract void add_children(IDocument parent, Gee.List<IDocument> children) throws StubError, DeserializeError;
        }

        public interface INodeManagerStub : Object
        {
            protected abstract unowned IInfoManagerStub info_getter();
            public IInfoManagerStub info {get {return info_getter();}}
            protected abstract unowned ICalculatorStub calc_getter();
            public ICalculatorStub calc {get {return calc_getter();}}
        }

        public interface IChildrenViewerStub : Object
        {
            public abstract Gee.List<IDocument> list_leafs() throws StubError, DeserializeError;
        }

        public interface IStatisticsStub : Object
        {
            protected abstract unowned IChildrenViewerStub children_viewer_getter();
            public IChildrenViewerStub children_viewer {get {return children_viewer_getter();}}
        }

        public INodeManagerStub get_node_tcp_client(string peer_address, uint16 peer_port)
        {
            return new NodeManagerTcpClientRootStub(peer_address, peer_port);
        }

        public INodeManagerStub get_node_unicast(string dev, uint16 port, UnicastID unicast_id)
        {
            error("not implemented yet");
        }

        public INodeManagerStub get_node_broadcast(string dev, uint16 port, BroadcastID broadcast_id)
        {
            error("not implemented yet");
        }

        public IStatisticsStub get_stats_tcp_client(string peer_address, uint16 peer_port)
        {
            error("not implemented yet");
        }

        public IStatisticsStub get_stats_unicast(string dev, uint16 port, UnicastID unicast_id)
        {
            error("not implemented yet");
        }

        public IStatisticsStub get_stats_broadcast(string dev, uint16 port, BroadcastID broadcast_id)
        {
            error("not implemented yet");
        }

        internal class NodeManagerTcpClientRootStub : Object, INodeManagerStub, ITcpClientRootStub
        {
            private TcpClient client;
            private string peer_address;
            private uint16 peer_port;
            private bool hurry;
            private bool wait_reply;
            private InfoManagerRemote _info;
            public NodeManagerTcpClientRootStub(string peer_address, uint16 peer_port)
            {
                this.peer_address = peer_address;
                this.peer_port = peer_port;
                client = tcp_client(peer_address, peer_port);
                hurry = false;
                wait_reply = true;
                _info = new InfoManagerRemote(this.call);
            }

            public bool hurry_getter()
            {
                return hurry;
            }

            public void hurry_setter(bool new_value)
            {
                hurry = new_value;
            }

            public bool wait_reply_getter()
            {
                return wait_reply;
            }

            public void wait_reply_setter(bool new_value)
            {
                wait_reply = new_value;
            }

            protected unowned IInfoManagerStub info_getter()
            {
                return _info;
            }

            protected unowned ICalculatorStub calc_getter()
            {
                error("not implemented yet");
            }

            private string call(string m_name, Gee.List<string> arguments) throws ZCDError
            {
                if (hurry && !client.is_queue_empty())
                {
                    client = tcp_client(peer_address, peer_port);
                }
                // TODO See destructor of TcpClient. If the low level library ZCD is able to ensure
                //  that the destructor is not called when a call is in progress, then this
                //  local_reference is not needed.
                TcpClient local_reference = client;
                string ret = local_reference.enqueue_call(m_name, arguments, wait_reply);
                return ret;
            }
        }

        internal class StatisticsTcpClientRootStub : Object, IStatisticsStub, ITcpClientRootStub
        {
            private TcpClient client;
            private bool hurry;
            private bool wait_reply;
            public StatisticsTcpClientRootStub(string peer_address, uint16 peer_port)
            {
                client = tcp_client(peer_address, peer_port);
                hurry = false;
                wait_reply = true;
            }

            public bool hurry_getter()
            {
                return hurry;
            }

            public void hurry_setter(bool new_value)
            {
                hurry = new_value;
            }

            public bool wait_reply_getter()
            {
                return wait_reply;
            }

            public void wait_reply_setter(bool new_value)
            {
                wait_reply = new_value;
            }

            protected unowned IChildrenViewerStub children_viewer_getter()
            {
                error("not implemented yet");
            }
        }

        internal class InfoManagerRemote : Object, IInfoManagerStub
        {
            private unowned FakeRmt rmt;
            public InfoManagerRemote(FakeRmt rmt)
            {
                this.rmt = rmt;
            }

            public string get_name() throws StubError, DeserializeError
            {
                error("not implemented yet");
            }

            public void set_name(string name) throws AuthError, BadArgsError, StubError, DeserializeError
            {
                ArrayList<string> args = new ArrayList<string>();
                // serialize
                Json.Builder b = new Json.Builder();
                b.begin_object()
                    .set_member_name("argument").add_string_value(name)
                .end_object();
                Json.Generator g = new Json.Generator();
                g.pretty = false;
                g.root = b.get_root();
                args.add(g.to_data(null));
                string ret;
                try {
                    ret = rmt("node.info.set_name", args);
                } catch (ZCDError e) {
                    throw new StubError.GENERIC(e.message);
                }
                // deserialize
                Json.Parser p = new Json.Parser();
                try {
                    p.load_from_data(ret);
                } catch (Error e) {
                    error(@"Error parsing JSON for return-value of node.info.set_name: $(e.message)");
                }
                Json.Reader r = new Json.Reader(p.get_root());
                string doing = "Reading return-value of node.info.set_name";
                if (!r.is_object())
                    throw new DeserializeError.GENERIC(@"$(doing): root JSON node must be an object");
                string[] members = r.list_members();
                if ("return-value" in members)
                {
                    r.read_member("return-value");
                    if (!r.get_null_value())
                        throw new DeserializeError.GENERIC(@"$(doing): return-value must be null");
                    r.end_member();
                    // void return-value ok
                }
                else if (("error-domain" in members) && ("error-code" in members) && ("error-message" in members))
                {
                    r.read_member("error-domain");
                    if (!r.is_value())
                        throw new DeserializeError.GENERIC(@"$(doing): error-domain must be a string");
                    if (r.get_value().get_value_type() != typeof(string))
                        throw new DeserializeError.GENERIC(@"$(doing): error-domain must be a string");
                    string error_domain = r.get_string_value();
                    r.end_member();
                    r.read_member("error-code");
                    if (!r.is_value())
                        throw new DeserializeError.GENERIC(@"$(doing): error-code must be a string");
                    if (r.get_value().get_value_type() != typeof(string))
                        throw new DeserializeError.GENERIC(@"$(doing): error-code must be a string");
                    string error_code = r.get_string_value();
                    r.end_member();
                    r.read_member("error-message");
                    if (!r.is_value())
                        throw new DeserializeError.GENERIC(@"$(doing): error-message must be a string");
                    if (r.get_value().get_value_type() != typeof(string))
                        throw new DeserializeError.GENERIC(@"$(doing): error-message must be a string");
                    string error_message = r.get_string_value();
                    r.end_member();
                    string error_domain_code = @"$(error_domain).$(error_code)";
                    if (error_domain_code == "AuthError.GENERIC")
                        throw new AuthError.GENERIC(error_message);
                    if (error_domain_code == "BadArgsError.GENERIC")
                        throw new BadArgsError.GENERIC(error_message);
                    if (error_domain_code == "BadArgsError.NULL_NOT_ALLOWED")
                        throw new BadArgsError.NULL_NOT_ALLOWED(error_message);
                    throw new DeserializeError.GENERIC(@"$(doing): unrecognized error $(error_domain_code)");
                }
                else
                {
                    throw new DeserializeError.GENERIC(@"$(doing): root JSON node must have return-value or error-*");
                }
            }

            public int get_year() throws StubError, DeserializeError
            {
                error("not implemented yet");
            }

            public bool set_year(int year) throws StubError, DeserializeError
            {
                error("not implemented yet");
            }

            public License get_license() throws StubError, DeserializeError
            {
                error("not implemented yet");
            }
        }
    }
}

