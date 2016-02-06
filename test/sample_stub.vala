using Gee;
using zcd;

namespace SampleRpc
{
    /*namespace ModRpc
    {*/
        public interface INotificatoreStub : Object
        {
            public abstract void scrivi(string msg) throws StubError, DeserializeError;
        }

        public interface IRisponditoreStub : Object
        {
            public abstract string salutami() throws StubError, DeserializeError;
        }

        public interface IOperatoreStub : Object
        {
            protected abstract unowned INotificatoreStub note_getter();
            public INotificatoreStub note {get {return note_getter();}}
            protected abstract unowned IRisponditoreStub res_getter();
            public IRisponditoreStub res {get {return res_getter();}}
        }

        public IOperatoreStub get_op_tcp_client(string peer_address, uint16 peer_port, ISourceID source_id, IUnicastID unicast_id)
        {
            return new OperatoreTcpClientRootStub(peer_address, peer_port, source_id, unicast_id);
        }

        internal class OperatoreTcpClientRootStub : Object, IOperatoreStub, ITcpClientRootStub
        {
            private TcpClient client;
            private string peer_address;
            private uint16 peer_port;
            private string s_source_id;
            private string s_unicast_id;
            private bool hurry;
            private bool wait_reply;
            private NotificatoreRemote _note;
            private RisponditoreRemote _res;
            public OperatoreTcpClientRootStub(string peer_address, uint16 peer_port, ISourceID source_id, IUnicastID unicast_id)
            {
                this.peer_address = peer_address;
                this.peer_port = peer_port;
                s_source_id = prepare_direct_object(source_id);
                s_unicast_id = prepare_direct_object(unicast_id);
                client = tcp_client(peer_address, peer_port, s_source_id, s_unicast_id);
                hurry = false;
                wait_reply = true;
                _note = new NotificatoreRemote(this.call);
                _res = new RisponditoreRemote(this.call);
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

            protected unowned INotificatoreStub note_getter()
            {
                return _note;
            }

            protected unowned IRisponditoreStub res_getter()
            {
                return _res;
            }

            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                if (hurry && !client.is_queue_empty())
                {
                    client = tcp_client(peer_address, peer_port, s_source_id, s_unicast_id);
                }
                // TODO See destructor of TcpClient. If the low level library ZCD is able to ensure
                //  that the destructor is not called when a call is in progress, then this
                //  local_reference is not needed.
                TcpClient local_reference = client;
                string ret = local_reference.enqueue_call(m_name, arguments, wait_reply);
                if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
                return ret;
            }
        }

        public IOperatoreStub get_op_unicast(string dev, uint16 port, ISourceID source_id, IUnicastID unicast_id, bool wait_reply)
        {
            return new OperatoreUnicastRootStub(dev, port, source_id, unicast_id, wait_reply);
        }

        internal class OperatoreUnicastRootStub : Object, IOperatoreStub
        {
            private string s_source_id;
            private string s_unicast_id;
            private string dev;
            private uint16 port;
            private bool wait_reply;
            private NotificatoreRemote _note;
            private RisponditoreRemote _res;
            public OperatoreUnicastRootStub(string dev, uint16 port, ISourceID source_id, IUnicastID unicast_id, bool wait_reply)
            {
                s_source_id = prepare_direct_object(source_id);
                s_unicast_id = prepare_direct_object(unicast_id);
                this.dev = dev;
                this.port = port;
                this.wait_reply = wait_reply;
                _note = new NotificatoreRemote(this.call);
                _res = new RisponditoreRemote(this.call);
            }

            protected unowned INotificatoreStub note_getter()
            {
                return _note;
            }

            protected unowned IRisponditoreStub res_getter()
            {
                return _res;
            }

            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                return call_unicast_udp(m_name, arguments, dev, port, s_source_id, s_unicast_id, wait_reply);
            }
        }

        public IOperatoreStub get_op_broadcast
        (Gee.Collection<string> devs, uint16 port, ISourceID source_id, IBroadcastID broadcast_id, IAckCommunicator? notify_ack=null)
        {
            return new OperatoreBroadcastRootStub(devs, port, source_id, broadcast_id, notify_ack);
        }

        internal class OperatoreBroadcastRootStub : Object, IOperatoreStub
        {
            private string s_source_id;
            private string s_broadcast_id;
            private Gee.Collection<string> devs;
            private uint16 port;
            private IAckCommunicator? notify_ack;
            private NotificatoreRemote _note;
            private RisponditoreRemote _res;
            public OperatoreBroadcastRootStub
            (Gee.Collection<string> devs, uint16 port, ISourceID source_id, IBroadcastID broadcast_id, IAckCommunicator? notify_ack=null)
            {
                s_source_id = prepare_direct_object(source_id);
                s_broadcast_id = prepare_direct_object(broadcast_id);
                this.devs = new ArrayList<string>();
                this.devs.add_all(devs);
                this.port = port;
                this.notify_ack = notify_ack;
                _note = new NotificatoreRemote(this.call);
                _res = new RisponditoreRemote(this.call);
            }

            protected unowned INotificatoreStub note_getter()
            {
                return _note;
            }

            protected unowned IRisponditoreStub res_getter()
            {
                return _res;
            }

            private string call(string m_name, Gee.List<string> arguments) throws ZCDError, StubError
            {
                return call_broadcast_udp(m_name, arguments, devs, port, s_source_id, s_broadcast_id, notify_ack);
            }
        }

        internal class NotificatoreRemote : Object, INotificatoreStub
        {
            private unowned FakeRmt rmt;
            public NotificatoreRemote(FakeRmt rmt)
            {
                this.rmt = rmt;
            }

            public void scrivi(string arg0) throws StubError, DeserializeError
            {
                string m_name = "op.note.scrivi";
                ArrayList<string> args = new ArrayList<string>();
                {
                    // serialize arg0 (string msg)
                    args.add(prepare_argument_string(arg0));
                }

                string resp;
                try {
                    resp = rmt(m_name, args);
                }
                catch (ZCDError e) {
                    throw new StubError.GENERIC(e.message);
                }
                // The following catch is to be added only for methods that return void.
                catch (StubError.DID_NOT_WAIT_REPLY e) {return;}

                // deserialize response
                string? error_domain = null;
                string? error_code = null;
                string? error_message = null;
                string doing = @"Reading return-value of $(m_name)";
                try {
                    read_return_value_void(resp, out error_domain, out error_code, out error_message);
                } catch (HelperNotJsonError e) {
                    error(@"Error parsing JSON for return-value of $(m_name): $(e.message)");
                } catch (HelperDeserializeError e) {
                    throw new DeserializeError.GENERIC(@"$(doing): $(e.message)");
                }
                if (error_domain != null)
                {
                    string error_domain_code = @"$(error_domain).$(error_code)";
                    if (error_domain_code == "DeserializeError.GENERIC")
                        throw new DeserializeError.GENERIC(error_message);
                    throw new DeserializeError.GENERIC(@"$(doing): unrecognized error $(error_domain_code) $(error_message)");
                }
                return;
            }

        }

        internal class RisponditoreRemote : Object, IRisponditoreStub
        {
            private unowned FakeRmt rmt;
            public RisponditoreRemote(FakeRmt rmt)
            {
                this.rmt = rmt;
            }

            public string salutami() throws StubError, DeserializeError
            {
                string m_name = "op.res.salutami";
                ArrayList<string> args = new ArrayList<string>();

                string resp;
                try {
                    resp = rmt(m_name, args);
                }
                catch (ZCDError e) {
                    throw new StubError.GENERIC(e.message);
                }

                // deserialize response
                string? error_domain = null;
                string? error_code = null;
                string? error_message = null;
                string doing = @"Reading return-value of $(m_name)";
                string ret;
                try {
                    ret = read_return_value_string_notnull(resp, out error_domain, out error_code, out error_message);
                } catch (HelperNotJsonError e) {
                    error(@"Error parsing JSON for return-value of $(m_name): $(e.message)");
                } catch (HelperDeserializeError e) {
                    throw new DeserializeError.GENERIC(@"$(doing): $(e.message)");
                }
                if (error_domain != null)
                {
                    string error_domain_code = @"$(error_domain).$(error_code)";
                    if (error_domain_code == "DeserializeError.GENERIC")
                        throw new DeserializeError.GENERIC(error_message);
                    throw new DeserializeError.GENERIC(@"$(doing): unrecognized error $(error_domain_code) $(error_message)");
                }
                return ret;
            }

        }

    /*}*/
}
