using Gee;
using TaskletSystem;
using zcd;

namespace SampleRpc
{
    /*namespace ModRpc
    {*/
        public errordomain StubError
        {
            DID_NOT_WAIT_REPLY,
            GENERIC
        }

        public errordomain DeserializeError
        {
            GENERIC
        }

        public interface ISerializable : Object
        {
            public abstract bool check_deserialization();
        }

        internal delegate string FakeRmt(string m_name, Gee.List<string> arguments) throws ZCDError, StubError;

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

        internal string call_unicast_udp(
                string m_name, Gee.List<string> arguments,
                string dev,
                uint16 port,
                string s_source_id,
                string s_unicast_id,
                bool wait_reply) throws ZCDError, StubError
        {
            int id = Random.int_range(0, int.MAX);
            string k_map = @"$(dev):$(port)";
            ZcdUdpServiceMessageDelegate? del_ser = null;
            IChannel ch = tasklet.get_channel();
            if (wait_reply)
            {
                if (map_udp_listening != null && map_udp_listening.has_key(k_map))
                {
                    del_ser = map_udp_listening[k_map];
                    del_ser.going_to_send_unicast_with_reply(id, ch);
                }
                else
                {
                    wait_reply = false;
                }
            }
            else
            {
                if (map_udp_listening != null && map_udp_listening.has_key(k_map))
                {
                    del_ser = map_udp_listening[k_map];
                    del_ser.going_to_send_unicast_no_reply(id);
                }
            }
            try {
                send_unicast_request(dev, port, id, s_unicast_id, m_name, arguments, s_source_id, wait_reply);
            } catch (Error e) {
                throw new StubError.GENERIC(e.message);
            }
            if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
            string reply = (string)ch.recv();
            if (reply.has_prefix(s_unicast_service_prefix_fail))
            {
                throw new StubError.GENERIC(reply.substring(s_unicast_service_prefix_fail.length));
            }
            else if (reply.has_prefix(s_unicast_service_prefix_response))
            {
                return reply.substring(s_unicast_service_prefix_response.length);
            }
            else
            {
                error("Unexpected message through channel of ZcdUdpServiceMessageDelegate");
            }
        }

        public interface IAckCommunicator : Object
        {
            public abstract void process_macs_list(Gee.List<string> macs_list);
        }

        internal string call_broadcast_udp(
                string m_name, Gee.List<string> arguments,
                Gee.Collection<string> devs,
                uint16 port,
                string s_source_id,
                string s_broadcast_id,
                IAckCommunicator? notify_ack) throws ZCDError, StubError
        {
            ArrayList<IChannel> lst_ch = new ArrayList<IChannel>();
            bool ok = false;
            string last_error_message = "";
            foreach (string dev in devs)
            {
                int id = Random.int_range(0, int.MAX);
                string k_map = @"$(dev):$(port)";
                ZcdUdpServiceMessageDelegate? del_ser = null;
                IChannel ch = tasklet.get_channel();
                lst_ch.add(ch);
                if (notify_ack != null)
                {
                    if (map_udp_listening != null && map_udp_listening.has_key(k_map))
                    {
                        del_ser = map_udp_listening[k_map];
                        del_ser.going_to_send_broadcast_with_ack(id, ch);
                    }
                    else
                    {
                        notify_ack = null;
                    }
                }
                else
                {
                    if (map_udp_listening != null && map_udp_listening.has_key(k_map))
                    {
                        del_ser = map_udp_listening[k_map];
                        del_ser.going_to_send_broadcast_no_ack(id);
                    }
                }
                try {
                    send_broadcast_request(dev, port, id, s_broadcast_id, m_name, arguments, s_source_id, (notify_ack != null));
                    ok = true;
                } catch (Error e) {
                    last_error_message = e.message;
                }
            }

            if (!ok) throw new StubError.GENERIC(last_error_message);

            if (notify_ack != null)
            {
                NotifyAckTasklet t = new NotifyAckTasklet();
                t.notify_ack = notify_ack;
                t.lst_ch = lst_ch;
                tasklet.spawn(t);
            }
            throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
        }
        internal class NotifyAckTasklet : Object, ITaskletSpawnable
        {
            public IAckCommunicator notify_ack;
            public ArrayList<IChannel> lst_ch;
            public void * func()
            {
                ArrayList<string> macs_list = new ArrayList<string>();
                foreach (IChannel ch in lst_ch)
                {
                    ArrayList<string> macs_list_part = (ArrayList<string>)ch.recv();
                    macs_list.add_all(macs_list_part);
                }
                notify_ack.process_macs_list(macs_list);
                return null;
            }
        }
    /*}*/
}
