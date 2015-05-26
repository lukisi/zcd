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
            public abstract string get_name(ModRpc.CallerInfo? caller=null);
            public abstract void set_name(string name, ModRpc.CallerInfo? caller=null) throws AuthError, BadArgsError;
            public abstract int get_year(ModRpc.CallerInfo? caller=null);
            public abstract bool set_year(int year, ModRpc.CallerInfo? caller=null);
            public abstract License get_license(ModRpc.CallerInfo? caller=null);
        }

        public interface ICalculatorSkeleton : Object
        {
            public abstract IDocument get_root(ModRpc.CallerInfo? caller=null);
            public abstract Gee.List<IDocument> get_children(IDocument parent, ModRpc.CallerInfo? caller=null);
            public abstract void add_children(IDocument parent, Gee.List<IDocument> children, ModRpc.CallerInfo? caller=null);
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
            public abstract Gee.List<IDocument> list_leafs(ModRpc.CallerInfo? caller=null);
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
            public abstract INodeManagerSkeleton? get_node(CallerInfo caller);
            public abstract IStatisticsSkeleton? get_stats(CallerInfo caller);
        }

        public interface IRpcErrorHandler : Object
        {
            public abstract void error_handler(Error e);
        }

        internal errordomain InSkeletonDeserializeError {
            GENERIC
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
                IZcdDispatcher ret;
                if (m_name.has_prefix("node."))
                {
                    INodeManagerSkeleton? node = dlg.get_node(caller_info);
                    if (node == null) ret = null;
                    else ret = new ZcdNodeManagerDispatcher(node, m_name, args, caller_info);
                }
                else if (m_name.has_prefix("stats."))
                {
                    IStatisticsSkeleton? stats = dlg.get_stats(caller_info);
                    if (stats == null) ret = null;
                    else ret = new ZcdStatisticsDispatcher(stats, m_name, args, caller_info);
                }
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
                return ret;
            }

        }

        internal class ZcdDispatcherForError : Object, IZcdDispatcher
        {
            private string domain;
            private string code;
            private string message;
            public ZcdDispatcherForError(string domain, string code, string message)
            {
                this.domain = domain;
                this.code = code;
                this.message = message;
            }

            public string execute()
            {
                return prepare_error(domain, code, message);
            }
        }

        internal class ZcdNodeManagerDispatcher : Object, IZcdDispatcher
        {
            private INodeManagerSkeleton node;
            private string m_name;
            private ArrayList<string> args;
            private CallerInfo caller_info;
            public ZcdNodeManagerDispatcher(INodeManagerSkeleton node, string m_name, ArrayList<string> args, CallerInfo caller_info)
            {
                this.node = node;
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            private string execute_or_throw_deserialize() throws InSkeletonDeserializeError
            {
                string ret;
                if (m_name.has_prefix("node.info."))
                {
                    if (m_name == "node.info.get_name")
                    {
                        if (args.size != 0) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        string result = node.info.get_name(caller_info);
                        ret = prepare_return_value_string(result);
                    }
                    else if (m_name == "node.info.set_name")
                    {
                        if (args.size != 1) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        string arg0;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (string name)
                            string arg_name = "name";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            try {
                                arg0 = read_argument_string_notnull(args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            j++;
                        }

                        try {
                            node.info.set_name(arg0, caller_info);
                            ret = prepare_return_value_null();
                        } catch (AuthError e) {
                            string code = "";
                            if (e is AuthError.GENERIC) code = "GENERIC";
                            assert(code != "");
                            ret = prepare_error("AuthError", code, e.message);
                        } catch (BadArgsError e) {
                            string code = "";
                            if (e is BadArgsError.GENERIC) code = "GENERIC";
                            if (e is BadArgsError.NULL_NOT_ALLOWED) code = "NULL_NOT_ALLOWED";
                            assert(code != "");
                            ret = prepare_error("BadArgsError", code, e.message);
                        }
                    }
                    else if (m_name == "node.info.get_year")
                    {
                        if (args.size != 0) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        int result = node.info.get_year(caller_info);
                        ret = prepare_return_value_int64(result);
                    }
                    else if (m_name == "node.info.set_year")
                    {
                        if (args.size != 1) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        int arg0;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (int year)
                            string arg_name = "year";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            int64 val;
                            try {
                                val = read_argument_int64_notnull(args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            if (val > int.MAX || val < int.MIN)
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                            arg0 = (int)val;
                            j++;
                        }

                        bool result = node.info.set_year(arg0, caller_info);
                        ret = prepare_return_value_boolean(result);
                    }
                    else if (m_name == "node.info.get_license")
                    {
                        error("not implemented yet");
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in node.info: \"$(m_name)\"");
                    }
                }
                else if (m_name.has_prefix("node.calc."))
                {
                    error("not implemented yet");
                }
                else
                {
                    throw new InSkeletonDeserializeError.GENERIC(@"Unknown module in node: \"$(m_name)\"");
                }
                return ret;
            }

            public string execute()
            {
                string ret;
                try {
                    ret = execute_or_throw_deserialize();
                } catch(InSkeletonDeserializeError e) {
                    ret = prepare_error("DeserializeError", "GENERIC", e.message);
                }
                return ret;
            }
        }

        internal class ZcdStatisticsDispatcher : Object, IZcdDispatcher
        {
            private IStatisticsSkeleton stats;
            private string m_name;
            private ArrayList<string> args;
            private CallerInfo caller_info;
            public ZcdStatisticsDispatcher(IStatisticsSkeleton stats, string m_name, ArrayList<string> args, CallerInfo caller_info)
            {
                this.stats = stats;
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            private string execute_or_throw_deserialize() throws InSkeletonDeserializeError
            {
                error("not implemented yet");
            }

            public string execute()
            {
                string ret;
                try {
                    ret = execute_or_throw_deserialize();
                } catch(InSkeletonDeserializeError e) {
                    ret = prepare_error("DeserializeError", "GENERIC", e.message);
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
    }
}

