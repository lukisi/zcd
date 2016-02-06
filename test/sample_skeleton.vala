using Gee;
using zcd;
using TaskletSystem;

namespace SampleRpc
{
    /*namespace ModRpc
    {*/
        public interface INotificatoreSkeleton : Object
        {
            public abstract void scrivi(string msg, CallerInfo? caller=null);
        }

        public interface IRisponditoreSkeleton : Object
        {
            public abstract string salutami(CallerInfo? caller=null);
        }

        public interface IOperatoreSkeleton : Object
        {
            protected abstract unowned INotificatoreSkeleton note_getter();
            public INotificatoreSkeleton note {get {return note_getter();}}
            protected abstract unowned IRisponditoreSkeleton res_getter();
            public IRisponditoreSkeleton res {get {return res_getter();}}
        }

        public interface IRpcDelegate : Object
        {
            public abstract Gee.List<IOperatoreSkeleton> get_op_set(CallerInfo caller);
        }

        internal errordomain InSkeletonDeserializeError {
            GENERIC
        }

        internal class ZcdOperatoreDispatcher : Object, IZcdDispatcher
        {
            private string m_name;
            private ArrayList<string> args;
            private CallerInfo caller_info;
            private Gee.List<IOperatoreSkeleton> op_set;
            public ZcdOperatoreDispatcher(Gee.List<IOperatoreSkeleton> op_set, string m_name, Gee.List<string> args, CallerInfo caller_info)
            {
                this.op_set = new ArrayList<IOperatoreSkeleton>();
                this.op_set.add_all(op_set);
                this.m_name = m_name;
                this.args = new ArrayList<string>();
                this.args.add_all(args);
                this.caller_info = caller_info;
            }

            private string execute_or_throw_deserialize(IOperatoreSkeleton op) throws InSkeletonDeserializeError
            {
                string ret;
                if (m_name.has_prefix("op.note."))
                {
                    if (m_name == "op.note.scrivi")
                    {
                        if (args.size != 1) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                        // arguments:
                        string arg0;
                        // position:
                        int j = 0;
                        {
                            // deserialize arg0 (string msg)
                            string arg_name = "msg";
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

                        op.note.scrivi(arg0, caller_info);
                        ret = prepare_return_value_null();
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in op.note: \"$(m_name)\"");
                    }
                }
                else if (m_name.has_prefix("op.res."))
                {
                    if (m_name == "op.res.salutami")
                    {
                        if (args.size != 0) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");


                        string result = op.res.salutami(caller_info);
                        ret = prepare_return_value_string(result);
                    }
                    else
                    {
                        throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in op.res: \"$(m_name)\"");
                    }
                }
                else
                {
                    throw new InSkeletonDeserializeError.GENERIC(@"Unknown module in op: \"$(m_name)\"");
                }
                return ret;
            }

            public string execute()
            {
                assert(! op_set.is_empty);
                string ret = "";
                if (op_set.size == 1)
                {
                    try {
                        ret = execute_or_throw_deserialize(op_set[0]);
                    } catch(InSkeletonDeserializeError e) {
                        ret = prepare_error("DeserializeError", "GENERIC", e.message);
                    }
                }
                else
                {
                    foreach (var op in op_set)
                    {
                        try {
                            execute_or_throw_deserialize(op);
                        } catch(InSkeletonDeserializeError e) {
                        }
                    }
                }
                return ret;
            }
        }

        public class TcpclientCallerInfo : CallerInfo
        {
            internal TcpclientCallerInfo(string my_address, string peer_address, ISourceID sourceid, IUnicastID unicastid)
            {
                this.my_address = my_address;
                this.peer_address = peer_address;
                this.sourceid = sourceid;
                this.unicastid = unicastid;
            }
            public string my_address {get; private set;}
            public string peer_address {get; private set;}
            public ISourceID sourceid {get; private set;}
            public IUnicastID unicastid {get; private set;}
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
            private string unicast_id;
            private TcpclientCallerInfo? caller_info;
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

            public void set_unicast_id (string unicast_id)
            {
                this.unicast_id = unicast_id;
            }

            public void set_caller_info(TcpCallerInfo caller_info)
            {
                ISourceID sourceid;
                IUnicastID unicastid;
               {
                // deserialize IUnicastID unicastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(IUnicastID), unicast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for unicast_id: $(e.message)");
                    error(   @" unicast_id: $(unicast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    warning(@"get_dispatcher_unicast: couldn't verify if it's for me: $(e.message)");
                    return;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_unicast: couldn't verify if it's for me: bad deserialization");
                        return;
                    }
                }
                unicastid = (IUnicastID)val;
               }
               {
                // deserialize ISourceID sourceid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(ISourceID), caller_info.source_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for source_id: $(e.message)");
                    error(   @" unicast_id: $(caller_info.source_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify whom it's from
                    warning(@"get_dispatcher_unicast: couldn't verify whom it's from: $(e.message)");
                    return;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_unicast: couldn't verify whom it's from: bad deserialization");
                        return;
                    }
                }
                sourceid = (ISourceID)val;
               }
                this.caller_info = new TcpclientCallerInfo(caller_info.my_address, caller_info.peer_address, sourceid, unicastid);
            }

            public IZcdDispatcher? get_dispatcher()
            {
                IZcdDispatcher? ret = null;
              if (caller_info != null)
              {
                if (m_name.has_prefix("op."))
                {
                    Gee.List<IOperatoreSkeleton> op_set = dlg.get_op_set(caller_info);
                    if (op_set.is_empty) ret = null;
                    else ret = new ZcdOperatoreDispatcher(op_set, m_name, args, caller_info);
                }
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
              }
                args = new ArrayList<string>();
                m_name = "";
                caller_info = null;
                return ret;
            }

        }

        public class UnicastCallerInfo : CallerInfo
        {
            internal UnicastCallerInfo(string dev, string peer_address, ISourceID sourceid, IUnicastID unicastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.sourceid = sourceid;
                this.unicastid = unicastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public ISourceID sourceid {get; private set;}
            public IUnicastID unicastid {get; private set;}
        }

        public class BroadcastCallerInfo : CallerInfo
        {
            internal BroadcastCallerInfo(string dev, string peer_address, ISourceID sourceid, IBroadcastID broadcastid)
            {
                this.dev = dev;
                this.peer_address = peer_address;
                this.sourceid = sourceid;
                this.broadcastid = broadcastid;
            }
            public string dev {get; private set;}
            public string peer_address {get; private set;}
            public ISourceID sourceid {get; private set;}
            public IBroadcastID broadcastid {get; private set;}
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
                UdpCallerInfo caller_info)
            {
                ISourceID sourceid;
                IUnicastID unicastid;
               {
                // deserialize IUnicastID unicastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(IUnicastID), unicast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for unicast_id: $(e.message)");
                    error(   @" unicast_id: $(unicast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    warning(@"get_dispatcher_unicast: couldn't verify if it's for me: $(e.message)");
                    return null;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_unicast: couldn't verify if it's for me: bad deserialization");
                        return null;
                    }
                }
                unicastid = (IUnicastID)val;
               }
               {
                // deserialize ISourceID sourceid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(ISourceID), caller_info.source_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for source_id: $(e.message)");
                    error(   @" unicast_id: $(caller_info.source_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify whom it's from
                    warning(@"get_dispatcher_unicast: couldn't verify whom it's from: $(e.message)");
                    return null;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_unicast: couldn't verify whom it's from: bad deserialization");
                        return null;
                    }
                }
                sourceid = (ISourceID)val;
               }
                // call delegate
                UnicastCallerInfo my_caller_info = new UnicastCallerInfo(caller_info.dev, caller_info.peer_address, sourceid, unicastid);
                IZcdDispatcher ret;
                if (m_name.has_prefix("op."))
                {
                    Gee.List<IOperatoreSkeleton> op_set = dlg.get_op_set(my_caller_info);
                    if (op_set.is_empty) ret = null;
                    else ret = new ZcdOperatoreDispatcher(op_set, m_name, arguments, my_caller_info);
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
                UdpCallerInfo caller_info)
            {
                ISourceID sourceid;
                IBroadcastID broadcastid;
               {
                // deserialize IBroadcastID broadcastid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(IBroadcastID), broadcast_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for broadcast_id: $(e.message)");
                    error(   @" broadcast_id: $(broadcast_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify if it's for me
                    warning(@"get_dispatcher_broadcast: couldn't verify if it's for me: $(e.message)");
                    return null;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_broadcast: couldn't verify if it's for me: bad deserialization");
                        return null;
                    }
                }
                broadcastid = (IBroadcastID)val;
               }
               {
                // deserialize ISourceID sourceid
                Object val;
                try {
                    val = read_direct_object_notnull(typeof(ISourceID), caller_info.source_id);
                } catch (HelperNotJsonError e) {
                    critical(@"Error parsing JSON for source_id: $(e.message)");
                    error(   @" unicast_id: $(caller_info.source_id)");
                } catch (HelperDeserializeError e) {
                    // couldn't verify whom it's from
                    warning(@"get_dispatcher_unicast: couldn't verify whom it's from: $(e.message)");
                    return null;
                }
                if (val is ISerializable)
                {
                    if (!((ISerializable)val).check_deserialization())
                    {
                        // couldn't verify if it's for me
                        warning(@"get_dispatcher_unicast: couldn't verify whom it's from: bad deserialization");
                        return null;
                    }
                }
                sourceid = (ISourceID)val;
               }
                // call delegate
                BroadcastCallerInfo my_caller_info = new BroadcastCallerInfo(caller_info.dev, caller_info.peer_address, sourceid, broadcastid);
                IZcdDispatcher ret;
                if (m_name.has_prefix("op."))
                {
                    Gee.List<IOperatoreSkeleton> op_set = dlg.get_op_set(my_caller_info);
                    if (op_set.is_empty) ret = null;
                    else ret = new ZcdOperatoreDispatcher(op_set, m_name, arguments, my_caller_info);
                }
                else
                {
                    ret = new ZcdDispatcherForError("DeserializeError", "GENERIC", @"Unknown root in method name: \"$(m_name)\"");
                }
                return ret;
            }
        }

        public ITaskletHandle tcp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string? my_addr=null)
        {
            return zcd.tcp_listen(new ZcdTcpDelegate(dlg), new ZcdTcpAcceptErrorHandler(err), port, my_addr);
        }

        public ITaskletHandle udp_listen(IRpcDelegate dlg, IRpcErrorHandler err, uint16 port, string dev)
        {
            if (map_udp_listening == null) map_udp_listening = new HashMap<string, ZcdUdpServiceMessageDelegate>();
            string k_map = @"$(dev):$(port)";
            ZcdUdpRequestMessageDelegate del_req = new ZcdUdpRequestMessageDelegate(dlg);
            ZcdUdpServiceMessageDelegate del_ser = new ZcdUdpServiceMessageDelegate();
            ZcdUdpCreateErrorHandler del_err = new ZcdUdpCreateErrorHandler(err, k_map);
            map_udp_listening[k_map] = del_ser;
            return zcd.udp_listen(del_req, del_ser, del_err, port, dev);
        }
    /*}*/
}
