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

using Gee;
using zcd;

namespace AppDomain
{
    namespace ModRpc
    {
        internal IZcdTasklet tasklet;

        public void init_tasklet_system(zcd.IZcdTasklet _tasklet)
        {
            zcd.init_tasklet_system(_tasklet);
            tasklet = _tasklet;
        }

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
            public abstract Gee.List<string> int_to_string(Gee.List<int> lst, ModRpc.CallerInfo? caller=null);
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
            public ZcdNodeManagerDispatcher(INodeManagerSkeleton node, string m_name, Gee.List<string> args, CallerInfo caller_info)
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
                        if (args.size != 0) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        License result = node.info.get_license(caller_info);
                        ret = prepare_return_value_object(result);
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in node.info: \"$(m_name)\"");
                    }
                }
                else if (m_name.has_prefix("node.calc."))
                {
                    if (m_name == "node.calc.get_root")
                    {
                        if (args.size != 0) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        IDocument result = node.calc.get_root(caller_info);
                        ret = prepare_return_value_object(result);
                    }
                    else if (m_name == "node.calc.get_children")
                    {
                        if (args.size != 1) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        IDocument arg0;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (IDocument parent)
                            string arg_name = "parent";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            Object val;
                            try {
                                val = read_argument_object_notnull(typeof(IDocument), args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            if (val is ISerializable)
                                if (!((ISerializable)val).check_serialization())
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                            arg0 = (IDocument)val;
                            j++;
                        }

                        Gee.List<IDocument> result = node.calc.get_children(arg0, caller_info);
                        ret = prepare_return_value_array_of_object(result);
                    }
                    else if (m_name == "node.calc.add_children")
                    {
                        if (args.size != 2) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        IDocument arg0;
                        Gee.List<IDocument> arg1;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (IDocument parent)
                            string arg_name = "parent";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            Object val;
                            try {
                                val = read_argument_object_notnull(typeof(IDocument), args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            if (val is ISerializable)
                                if (!((ISerializable)val).check_serialization())
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                            arg0 = (IDocument)val;
                            j++;
                        }
                        {
                            // deserialize arg1 (Gee.List<IDocument> children)
                            string arg_name = "children";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            Gee.List<Object> values;
                            try {
                                values = read_argument_array_of_object(typeof(IDocument), args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            foreach (Object val in values) if (val is ISerializable)
                                if (!((ISerializable)val).check_serialization())
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                            arg1 = (Gee.List<IDocument>)values;
                            j++;
                        }

                        node.calc.add_children(arg0, arg1, caller_info);
                        ret = prepare_return_value_null();
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in node.calc: \"$(m_name)\"");
                    }
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
            public ZcdStatisticsDispatcher(IStatisticsSkeleton stats, string m_name, Gee.List<string> args, CallerInfo caller_info)
            {
                this.stats = stats;
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            private string execute_or_throw_deserialize() throws InSkeletonDeserializeError
            {
                string ret;
                if (m_name.has_prefix("stats.children_viewer."))
                {
                    if (m_name == "stats.children_viewer.int_to_string")
                    {
                        if (args.size != 1) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        Gee.List<int> arg0;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (Gee.List<int> lst)
                            string arg_name = "lst";
                            string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                            Gee.List<int64?> values;
                            try {
                                values = read_argument_array_of_int64(args[j]);
                            } catch (HelperNotJsonError e) {
                                critical(@"Error parsing JSON for argument: $(e.message)");
                                critical(@" method-name: $(m_name)");
                                error(@" argument #$(j): $(args[j])");
                            } catch (HelperDeserializeError e) {
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                            }
                            arg0 = new ArrayList<int>();
                            foreach (int64 val in values)
                            {
                                if (val > int.MAX || val < int.MIN)
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                                arg0.add((int)val);
                            }
                            j++;
                        }

                        Gee.List<string> result = stats.children_viewer.int_to_string(arg0, caller_info);
                        ret = prepare_return_value_array_of_string(result);
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in stats.children_viewer: \"$(m_name)\"");
                    }
                }
                else
                {
                    throw new InSkeletonDeserializeError.GENERIC(@"Unknown module in stats: \"$(m_name)\"");
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

        public class UnicastCallerInfo : CallerInfo
        {
            internal UnicastCallerInfo(string dev, string peer_address, UnicastID unicastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.unicastid = unicastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public UnicastID unicastid {get; private set;}
        }

        public class BroadcastCallerInfo : CallerInfo
        {
            internal BroadcastCallerInfo(string dev, string peer_address, BroadcastID broadcastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.broadcastid = broadcastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public BroadcastID broadcastid {get; private set;}
        }

        internal class ZcdUdpRequestMessageDelegate : Object, IZcdUdpRequestMessageDelegate
        {
            private IRpcDelegate dlg;
            public ZcdUdpRequestMessageDelegate(IRpcDelegate dlg)
            {
                this.dlg = dlg;
            }

            public IZcdDispatcher? get_dispatcher_unicast(
                int id, string unicast_id,
                string m_name, Gee.List<string> arguments,
                zcd.UdpCallerInfo caller_info)
            {
                // deserialize UnicastID unicastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(UnicastID), unicast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for unicast_id: $(e.message)");
                    error(   @" unicast_id: $(unicast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    return null;
                }
                if (val is ISerializable)
                    if (!((ISerializable)val).check_serialization())
                    {
                        // couldn't verify if it's for me
                        return null;
                    }
                UnicastID unicastid = (UnicastID)val;
                // call delegate
                UnicastCallerInfo my_caller_info = new UnicastCallerInfo(caller_info.dev, caller_info.peer_addr, unicastid);
                IZcdDispatcher ret;
                if (m_name.has_prefix("node."))
                {
                    INodeManagerSkeleton? node = dlg.get_node(my_caller_info);
                    if (node == null) ret = null;
                    else ret = new ZcdNodeManagerDispatcher(node, m_name, arguments, my_caller_info);
                }
                else if (m_name.has_prefix("stats."))
                {
                    IStatisticsSkeleton? stats = dlg.get_stats(my_caller_info);
                    if (stats == null) ret = null;
                    else ret = new ZcdStatisticsDispatcher(stats, m_name, arguments, my_caller_info);
                }
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }

            public IZcdDispatcher? get_dispatcher_broadcast(
                int id, string broadcast_id,
                string m_name, Gee.List<string> arguments,
                zcd.UdpCallerInfo caller_info)
            {
                // deserialize BroadcastID broadcastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(BroadcastID), broadcast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for broadcast_id: $(e.message)");
                    error(   @" broadcast_id: $(broadcast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    return null;
                }
                if (val is ISerializable)
                    if (!((ISerializable)val).check_serialization())
                        // couldn't verify if it's for me
                        return null;
                BroadcastID broadcastid = (BroadcastID)val;
                // call delegate
                BroadcastCallerInfo my_caller_info = new BroadcastCallerInfo(caller_info.dev, caller_info.peer_addr, broadcastid);
                IZcdDispatcher ret;
                if (m_name.has_prefix("node."))
                {
                    INodeManagerSkeleton? node = dlg.get_node(my_caller_info);
                    if (node == null) ret = null;
                    else ret = new ZcdNodeManagerDispatcher(node, m_name, arguments, my_caller_info);
                }
                else if (m_name.has_prefix("stats."))
                {
                    IStatisticsSkeleton? stats = dlg.get_stats(my_caller_info);
                    if (stats == null) ret = null;
                    else ret = new ZcdStatisticsDispatcher(stats, m_name, arguments, my_caller_info);
                }
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }
        }

        internal const int udp_timeout_msec = 3000;
        internal class ZcdUdpServiceMessageDelegate : Object, IZcdUdpServiceMessageDelegate
        {
            private IRpcDelegate dlg;
            public ZcdUdpServiceMessageDelegate(IRpcDelegate dlg)
            {
                this.dlg = dlg;
                waiting_for_response = new HashMap<int, WaitingForResponse>();
                waiting_for_ack = new HashMap<int, WaitingForAck>();
                expected_ping_ids = new ArrayList<int>();
                expected_pong_ids = new HashMap<int, IZcdChannel>();
            }

            private class WaitingForResponse : Object, IZcdTaskletSpawnable
            {
                public int id;
                public Timer timer;
                public IZcdChannel ch;
                public string response;
                public bool has_response = false;
                public void* func()
                {
                    while (true)
                    {
                        if (has_response)
                        {
                            // report 'response' through 'ch'
                            ch.send(s_unicast_service_prefix_response + response);
                            return null;
                        }
                        if (timer.is_expired())
                        {
                            // report communication error through 'ch'
                            ch.send(s_unicast_service_prefix_fail + "Timeout before reply or keepalive");
                            return null;
                        }
                        tasklet.ms_wait(2);
                    }
                }
            }
            private HashMap<int, WaitingForResponse> waiting_for_response;

            private class WaitingForAck : Object, IZcdTaskletSpawnable
            {
                public WaitingForAck()
                {
                    macs_list = new ArrayList<string>();
                }
                public int id;
                public int timeout_msec;
                public IZcdChannel ch;
                public ArrayList<string> macs_list;
                public void* func()
                {
                    tasklet.ms_wait(timeout_msec);
                    // report 'macs_list' through 'ch'
                    ch.send(macs_list);
                    return null;
                }
            }
            private HashMap<int, WaitingForAck> waiting_for_ack;

            internal void going_to_send_unicast(int id, IZcdChannel ch)
            {
                var w = new WaitingForResponse();
                w.id = id;
                w.ch = ch;
                w.timer = new Timer(udp_timeout_msec);
                tasklet.spawn(w);
                waiting_for_response[id] = w;
            }

            internal void going_to_send_broadcast(int id, IZcdChannel ch)
            {
                var w = new WaitingForAck();
                w.id = id;
                w.ch = ch;
                w.timeout_msec = udp_timeout_msec;
                tasklet.spawn(w);
                waiting_for_ack[id] = w;
            }

            public bool is_my_own_message(int id)
            {
                if (waiting_for_response.has_key(id)) return true;
                if (waiting_for_ack.has_key(id)) return true;
                return false;
            }

            public bool is_ping_request_for_me(int id)
            {
                return (id in expected_ping_ids);
            }

            public void got_ping_response(int id, long delta_usec)
            {
                if (expected_pong_ids.has_key(id))
                    expected_pong_ids[id].send(delta_usec);
            }

            public void got_keep_alive(int id)
            {
                if (waiting_for_response.has_key(id))
                {
                    waiting_for_response[id].timer = new Timer(udp_timeout_msec);
                }
            }

            public void got_response(int id, string response)
            {
                if (waiting_for_response.has_key(id))
                {
                    waiting_for_response[id].response = response;
                    waiting_for_response[id].has_response = true;
                }
            }

            public void got_ack(int id, string mac)
            {
                if (waiting_for_ack.has_key(id))
                {
                    if (! (mac in waiting_for_ack[id].macs_list))
                        waiting_for_ack[id].macs_list.add(mac);
                }
            }

            private ArrayList<int> expected_ping_ids;
            internal void expect_ping(int id)
            {
                expected_ping_ids.add(id);
                if (expected_ping_ids.size > 200) expected_ping_ids.remove_at(0);
            }

            private HashMap<int, IZcdChannel> expected_pong_ids;
            internal void expect_pong(int id, IZcdChannel ch)
            {
                expected_pong_ids[id] = ch;
            }
            internal void release_pong(int id)
            {
                expected_pong_ids.unset(id);
            }
        }

        internal class ZcdUdpCreateErrorHandler : Object, IZcdUdpCreateErrorHandler
        {
            private IRpcErrorHandler err;
            private string k_map;
            public ZcdUdpCreateErrorHandler(IRpcErrorHandler err, string k_map)
            {
                this.err = err;
                this.k_map = k_map;
            }

            public void error_handler(Error e)
            {
                if (map_udp_listening != null)
                    map_udp_listening.unset(k_map);
                err.error_handler(e);
            }
        }

        public void tcp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string? my_addr=null)
        {
            zcd.tcp_listen(new ZcdTcpDelegate(dlg), new ZcdTcpAcceptErrorHandler(err), port, my_addr);
        }

        internal HashMap<string, ZcdUdpServiceMessageDelegate>? map_udp_listening = null;
        public void udp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string dev)
        {
            if (map_udp_listening == null) map_udp_listening = new HashMap<string, ZcdUdpServiceMessageDelegate>();
            string k_map = @"$(dev):$(port)";
            ZcdUdpRequestMessageDelegate del_req = new ZcdUdpRequestMessageDelegate(dlg);
            ZcdUdpServiceMessageDelegate del_ser = new ZcdUdpServiceMessageDelegate(dlg);
            ZcdUdpCreateErrorHandler del_err = new ZcdUdpCreateErrorHandler(err, k_map);
            map_udp_listening[k_map] = del_ser;
            zcd.udp_listen(del_req, del_ser, del_err, port, dev);
        }

        public void prepare_ping(int id, string dev, uint16 port)
        {
            string k_map = @"$(dev):$(port)";
            if (map_udp_listening == null) return;
            if (! map_udp_listening.has_key(k_map)) return;
            ZcdUdpServiceMessageDelegate del_ser = map_udp_listening[k_map];
            del_ser.expect_ping(id);
        }

        internal class Timer : Object
        {
            protected TimeVal exp;
            public Timer(int64 msec_ttl)
            {
                set_time(msec_ttl);
            }

            protected void set_time(int64 msec_ttl)
            {
                exp = TimeVal();
                exp.get_current_time();
                long milli = (long)(msec_ttl % (int64)1000);
                long seconds = (long)(msec_ttl / (int64)1000);
                int64 check_seconds = (int64)exp.tv_sec;
                check_seconds += (int64)seconds;
                assert(check_seconds <= long.MAX);
                exp.add(milli*1000);
                exp.tv_sec += seconds;
            }

            public bool is_younger(Timer t)
            {
                if (exp.tv_sec > t.exp.tv_sec) return true;
                if (exp.tv_sec < t.exp.tv_sec) return false;
                if (exp.tv_usec > t.exp.tv_usec) return true;
                return false;
            }

            public bool is_expired()
            {
                Timer now = new Timer(0);
                return now.is_younger(this);
            }
        }
    }
}

