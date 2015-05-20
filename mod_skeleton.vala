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
        public interface IInfoManagerSkeleton : Object
        {
            public abstract string get_name();
            public abstract void set_name(string name) throws AuthError, BadArgsError;
            public abstract int get_year();
            public abstract bool set_year(int year);
            public abstract License get_license();
        }

        public interface ICalculatorSkeleton : Object
        {
            public abstract IDocument get_root();
            public abstract Gee.List<IDocument> get_children(IDocument parent);
            public abstract void add_children(IDocument parent, Gee.List<IDocument> children);
        }

        public interface INodeManagerSkeleton : Object
        {
            protected abstract unowned IInfoManagerSkeleton info_getter();
            public IInfoManagerSkeleton info {get {return info_getter();}}
            protected abstract unowned ICalculatorSkeleton calc_getter();
            public ICalculatorSkeleton calc {get {return calc_getter();}}
        }

        public interface IChildrenViewerSkeleton : Object
        {
            public abstract Gee.List<IDocument> list_leafs();
        }

        public interface IStatisticsSkeleton : Object
        {
            protected abstract unowned IChildrenViewerSkeleton children_viewer_getter();
            public IChildrenViewerSkeleton children_viewer {get {return children_viewer_getter();}}
        }

        public abstract class CallerInfo : Object
        {
        }

        public interface IRpcDelegate : Object
        {
            public abstract INodeManagerSkeleton get_node(CallerInfo caller);
            public abstract IStatisticsSkeleton get_stats(CallerInfo caller);
        }

        public interface IRpcErrorHandler : Object
        {
            public abstract void error_handler(Error e);
        }

        public class TcpCallerInfo : CallerInfo
        {
            internal TcpCallerInfo(string my_address, string peer_address)
            {
                this.my_address = my_address;
                this.peer_address = peer_address;
            }
            public string my_address {get; private set;}
            public string peer_address {get; private set;}
        }

        internal class ZcdTcpDelegate : Object, IZcdTcpDelegate
        {
            private IRpcDelegate dlg;
            public ZcdTcpDelegate(IRpcDelegate dlg)
            {
                this.dlg = dlg;
            }

            public IZcdTcpRequestHandler get_new_handler()
            {
                return new ZcdTcpRequestHandler(dlg);
            }

        }

        internal class ZcdTcpRequestHandler : Object, IZcdTcpRequestHandler
        {
            private IRpcDelegate dlg;
            private string m_name;
            private ArrayList<string> args;
            private TcpCallerInfo? caller_info;
            public ZcdTcpRequestHandler(IRpcDelegate dlg)
            {
                this.dlg = dlg;
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
            }

            public void set_method_name(string m_name)
            {
                this.m_name = m_name;
            }

            public void add_argument(string arg)
            {
                args.add(arg);
            }

            public void set_caller_info(zcd.TcpCallerInfo caller_info)
            {
                this.caller_info = new TcpCallerInfo(caller_info.my_addr, caller_info.peer_addr);
            }

            public IZcdDispatcher? get_dispatcher()
            {
                IZcdDispatcher ret = new ZcdDispatcher(dlg, m_name, args, caller_info);
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
                return ret;
            }

        }

        internal class ZcdDispatcher : Object, IZcdDispatcher
        {
            private IRpcDelegate dlg;
            private string m_name;
            private ArrayList<string> args;
            private TcpCallerInfo caller_info;
            public ZcdDispatcher(IRpcDelegate dlg, string m_name, ArrayList<string> args, TcpCallerInfo caller_info)
            {
                this.dlg = dlg;
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            public string execute()
            {
                string ret;
                if (m_name.has_prefix("node."))
                {
                    INodeManagerSkeleton node = dlg.get_node(caller_info);
                    if (m_name.has_prefix("node.info."))
                    {
                        if (m_name == "node.info.get_name")
                        {
                            error("not implemented yet");
                        }
                        else if (m_name == "node.info.set_name")
                        {
                            string name = "sample";
                            try {
                                node.info.set_name(name);
                                ret = prepare_return_value_null();
                            } catch (AuthError e) {
                                // TODO discern error code
                                ret = prepare_error("AuthError", "GENERIC", e.message);
                            } catch (BadArgsError e) {
                                error("not implemented yet");
                            }
                        }
                        else if (m_name == "node.info.get_year")
                        {
                            error("not implemented yet");
                        }
                        else if (m_name == "node.info.set_year")
                        {
                            error("not implemented yet");
                        }
                        else if (m_name == "node.info.get_license")
                        {
                            error("not implemented yet");
                        }
                        else
                        {
                            ret = prepare_error("DeserializeError", "GENERIC", @"Unknown method in node.info: \"$(m_name)\"");
                        }
                    }
                    else if (m_name.has_prefix("node.calc."))
                    {
                        error("not implemented yet");
                    }
                    else
                    {
                        ret = prepare_error("DeserializeError", "GENERIC", @"Unknown module in node: \"$(m_name)\"");
                    }
                }
                else if (m_name.has_prefix("stats."))
                {
                    IStatisticsSkeleton stats = dlg.get_stats(caller_info);
                    error("not implemented yet");
                }
                else
                {
                    ret = prepare_error("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }

        }

        internal class ZcdTcpAcceptErrorHandler : Object, IZcdTcpAcceptErrorHandler
        {
            private IRpcErrorHandler err;
            public ZcdTcpAcceptErrorHandler(IRpcErrorHandler err)
            {
                this.err = err;
            }

            public void error_handler(Error e)
            {
                err.error_handler(e);
            }
        }

        public void tcp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string? my_addr = null)
        {
            zcd.tcp_listen(new ZcdTcpDelegate(dlg), new ZcdTcpAcceptErrorHandler(err), port, my_addr);
        }

        internal string prepare_return_value_null()
        {
            error("not implemented yet");
        }

        internal string prepare_error(string domain, string code, string message)
        {
            error("not implemented yet");
        }
    }
}

