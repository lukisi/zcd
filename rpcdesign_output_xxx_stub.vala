/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

void output_xxx_stub(Root r, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    public interface INeighborhoodManagerStub : Object
    {
        public abstract void here_i_am(INeighborhoodNodeIDMessage my_id, string my_mac, string my_nic_addr) throws StubError, DeserializeError;
        public abstract bool can_you_export(bool i_can_export) throws StubError, DeserializeError;
        public abstract void nop() throws StubError, DeserializeError;
    }

    public interface IIdentityManagerStub : Object
    {
        public abstract IDuplicationData? match_duplication(int migration_id, IIdentityID peer_id, IIdentityID old_id, IIdentityID new_id, string old_id_new_mac, string old_id_new_linklocal) throws StubError, DeserializeError;
    }

    public interface IQspnManagerStub : Object
    {
        public abstract IQspnEtpMessage get_full_etp(IQspnAddress requesting_address) throws PippoError, StubError, DeserializeError;
    }

    public interface INodeStub : Object
    {
        protected abstract unowned INeighborhoodManagerStub neighborhood_manager_getter();
        public INeighborhoodManagerStub neighborhood_manager {get {return neighborhood_manager_getter();}}
        protected abstract unowned IIdentityManagerStub identity_manager_getter();
        public IIdentityManagerStub identity_manager {get {return identity_manager_getter();}}
        protected abstract unowned IQspnManagerStub qspn_manager_getter();
        public IQspnManagerStub qspn_manager {get {return qspn_manager_getter();}}
    }

    public INodeStub get_node_stream_net(
        string peer_ip, uint16 tcp_port,
        ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
        bool wait_reply)
    {
        return new StreamNetNodeStub(peer_ip, tcp_port,
            source_id, unicast_id, src_nic,
            wait_reply);
    }

    public INodeStub get_node_stream_system(
        string send_pathname,
        ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
        bool wait_reply)
    {
        return new StreamSystemNodeStub(send_pathname,
            source_id, unicast_id, src_nic,
            wait_reply);
    }

    public INodeStub get_node_datagram_net(
        string my_dev, uint16 udp_port,
        int packet_id,
        ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
        SampleRpc.IAckCommunicator? notify_ack=null)
    {
        return new DatagramNetNodeStub(my_dev, udp_port,
            source_id, broadcast_id, src_nic,
            notify_ack);
    }

    public INodeStub get_node_datagram_system(
        string send_pathname,
        int packet_id,
        ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
        SampleRpc.IAckCommunicator? notify_ack=null)
    {
        return new DatagramSystemNodeStub(send_pathname,
            source_id, broadcast_id, src_nic,
            notify_ack);
    }

    internal class StreamNetNodeStub : Object, INodeStub
    {
        private string s_source_id;
        private string s_unicast_id;
        private string s_src_nic;
        private string peer_ip;
        private uint16 tcp_port;
        private bool wait_reply;
        private NeighborhoodManagerRemote _neighborhood_manager;
        private IdentityManagerRemote _identity_manager;
        private QspnManagerRemote _qspn_manager;
        public StreamNetNodeStub(
            string peer_ip, uint16 tcp_port,
            ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
            bool wait_reply)
        {
            s_source_id = prepare_direct_object(source_id);
            s_unicast_id = prepare_direct_object(unicast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.peer_ip = peer_ip;
            this.tcp_port = tcp_port;
            this.wait_reply = wait_reply;
            _neighborhood_manager = new NeighborhoodManagerRemote(this.call);
            _identity_manager = new IdentityManagerRemote(this.call);
            _qspn_manager = new QspnManagerRemote(this.call);
        }

        protected unowned INeighborhoodManagerStub neighborhood_manager_getter()
        {
            return _neighborhood_manager;
        }

        protected unowned IIdentityManagerStub identity_manager_getter()
        {
            return _identity_manager;
        }

        protected unowned IQspnManagerStub qspn_manager_getter()
        {
            return _qspn_manager;
        }

        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            string ret =
                zcd.send_stream_net(
                peer_ip, tcp_port,
                s_source_id, s_src_nic, s_unicast_id, m_name, arguments,
                wait_reply);
            if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
            return ret;
        }
    }

    internal class StreamSystemNodeStub : Object, INodeStub
    {
        private string s_source_id;
        private string s_unicast_id;
        private string s_src_nic;
        private string send_pathname;
        private bool wait_reply;
        private NeighborhoodManagerRemote _neighborhood_manager;
        private IdentityManagerRemote _identity_manager;
        private QspnManagerRemote _qspn_manager;
        public StreamSystemNodeStub(
            string send_pathname,
            ISourceID source_id, IUnicastID unicast_id, ISrcNic src_nic,
            bool wait_reply)
        {
            s_source_id = prepare_direct_object(source_id);
            s_unicast_id = prepare_direct_object(unicast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.send_pathname = send_pathname;
            this.wait_reply = wait_reply;
            _neighborhood_manager = new NeighborhoodManagerRemote(this.call);
            _identity_manager = new IdentityManagerRemote(this.call);
            _qspn_manager = new QspnManagerRemote(this.call);
        }

        protected unowned INeighborhoodManagerStub neighborhood_manager_getter()
        {
            return _neighborhood_manager;
        }

        protected unowned IIdentityManagerStub identity_manager_getter()
        {
            return _identity_manager;
        }

        protected unowned IQspnManagerStub qspn_manager_getter()
        {
            return _qspn_manager;
        }

        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            string ret =
                zcd.send_stream_system(
                send_pathname,
                s_source_id, s_src_nic, s_unicast_id, m_name, arguments,
                wait_reply);
            if (!wait_reply) throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
            return ret;
        }
    }

    internal class DatagramNetNodeStub : Object, INodeStub
    {
        private string s_source_id;
        private string s_broadcast_id;
        private string s_src_nic;
        private string my_dev;
        private uint16 udp_port;
        private IAckCommunicator? notify_ack;
        private NeighborhoodManagerRemote _neighborhood_manager;
        private IdentityManagerRemote _identity_manager;
        private QspnManagerRemote _qspn_manager;
        public DatagramNetNodeStub(
            string my_dev, uint16 udp_port,
            ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
            IAckCommunicator? notify_ack=null)
        {
            s_source_id = prepare_direct_object(source_id);
            s_broadcast_id = prepare_direct_object(broadcast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.my_dev = my_dev;
            this.udp_port = udp_port;
            this.notify_ack = notify_ack;
            _neighborhood_manager = new NeighborhoodManagerRemote(this.call);
            _identity_manager = new IdentityManagerRemote(this.call);
            _qspn_manager = new QspnManagerRemote(this.call);
        }

        protected unowned INeighborhoodManagerStub neighborhood_manager_getter()
        {
            return _neighborhood_manager;
        }

        protected unowned IIdentityManagerStub identity_manager_getter()
        {
            return _identity_manager;
        }

        protected unowned IQspnManagerStub qspn_manager_getter()
        {
            return _qspn_manager;
        }

        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            IChannel ch = tasklet.get_channel();
            int packet_id = Random.int_range(0, int.MAX);
            string k_map = @"$(my_dev):$(udp_port)";

            if (notify_ack != null)
            {
                assert(map_datagram_listening != null && map_datagram_listening.has_key(k_map));
                DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                datagram_dlg.going_to_send_broadcast_with_ack(packet_id, ch);
            }
            else
            {
                if (map_datagram_listening != null && map_datagram_listening.has_key(k_map))
                {
                    DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                    datagram_dlg.going_to_send_broadcast_no_ack(packet_id);
                }
            }

            zcd.send_datagram_net(
                my_dev, udp_port,
                packet_id,
                s_source_id, s_src_nic, s_broadcast_id, m_name, arguments,
                notify_ack!=null);

            if (notify_ack != null)  // and no error was thrown before...
            {
                tasklet.spawn(new NotifyAckTasklet(notify_ack, ch));
            }
            // This implementation of FakeRmt will never return a value.
            throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
        }
    }

    internal class DatagramSystemNodeStub : Object, INodeStub
    {
        private string s_source_id;
        private string s_broadcast_id;
        private string s_src_nic;
        private string send_pathname;
        private IAckCommunicator? notify_ack;
        private NeighborhoodManagerRemote _neighborhood_manager;
        private IdentityManagerRemote _identity_manager;
        private QspnManagerRemote _qspn_manager;
        public DatagramSystemNodeStub(
            string send_pathname,
            ISourceID source_id, IBroadcastID broadcast_id, ISrcNic src_nic,
            IAckCommunicator? notify_ack=null)
        {
            s_source_id = prepare_direct_object(source_id);
            s_broadcast_id = prepare_direct_object(broadcast_id);
            s_src_nic = prepare_direct_object(src_nic);
            this.send_pathname = send_pathname;
            this.notify_ack = notify_ack;
            _neighborhood_manager = new NeighborhoodManagerRemote(this.call);
            _identity_manager = new IdentityManagerRemote(this.call);
            _qspn_manager = new QspnManagerRemote(this.call);
        }

        protected unowned INeighborhoodManagerStub neighborhood_manager_getter()
        {
            return _neighborhood_manager;
        }

        protected unowned IIdentityManagerStub identity_manager_getter()
        {
            return _identity_manager;
        }

        protected unowned IQspnManagerStub qspn_manager_getter()
        {
            return _qspn_manager;
        }

        private string call(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError
        {
            IChannel ch = tasklet.get_channel();
            int packet_id = Random.int_range(0, int.MAX);
            string k_map = @"$(send_pathname)";

            if (notify_ack != null)
            {
                assert(map_datagram_listening != null && map_datagram_listening.has_key(k_map));
                DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                datagram_dlg.going_to_send_broadcast_with_ack(packet_id, ch);
            }
            else
            {
                if (map_datagram_listening != null && map_datagram_listening.has_key(k_map))
                {
                    DatagramDelegate datagram_dlg = map_datagram_listening[k_map];
                    datagram_dlg.going_to_send_broadcast_no_ack(packet_id);
                }
            }

            zcd.send_datagram_system(
                send_pathname,
                packet_id,
                s_source_id, s_src_nic, s_broadcast_id, m_name, arguments,
                notify_ack!=null);

            if (notify_ack != null)  // and no error was thrown before...
            {
                tasklet.spawn(new NotifyAckTasklet(notify_ack, ch));
            }
            // This implementation of FakeRmt will never return a value.
            throw new StubError.DID_NOT_WAIT_REPLY(@"Didn't wait reply for a call to $(m_name)");
        }
    }

    internal class NeighborhoodManagerRemote : Object, INeighborhoodManagerStub
    {
        private unowned FakeRmt rmt;
        public NeighborhoodManagerRemote(FakeRmt rmt)
        {
            this.rmt = rmt;
        }

        public void here_i_am(INeighborhoodNodeIDMessage arg0, string arg1, string arg2) throws StubError, DeserializeError
        {
            string m_name = "node.neighborhood_manager.here_i_am";
            ArrayList<string> args = new ArrayList<string>();
            {
                // serialize arg0 (INeighborhoodNodeIDMessage my_id)
                args.add(prepare_argument_object(arg0));
            }
            {
                // serialize arg1 (string my_mac)
                args.add(prepare_argument_string(arg1));
            }
            {
                // serialize arg2 (string my_nic_addr)
                args.add(prepare_argument_string(arg2));
            }

            string resp;
            try {
                resp = rmt(m_name, args);
            }
            catch (zcd.ZCDError e) {
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

        public bool can_you_export(bool arg0) throws StubError, DeserializeError
        {
            string m_name = "node.neighborhood_manager.can_you_export";
            ArrayList<string> args = new ArrayList<string>();
            {
                // serialize arg0 (bool i_can_export)
                args.add(prepare_argument_boolean(arg0));
            }

            string resp;
            try {
                resp = rmt(m_name, args);
            }
            catch (zcd.ZCDError e) {
                throw new StubError.GENERIC(e.message);
            }

            // deserialize response
            string? error_domain = null;
            string? error_code = null;
            string? error_message = null;
            string doing = @"Reading return-value of $(m_name)";
            bool ret;
            try {
                ret = read_return_value_bool_notnull(resp, out error_domain, out error_code, out error_message);
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

        public void nop() throws StubError, DeserializeError
        {
            string m_name = "node.neighborhood_manager.nop";
            ArrayList<string> args = new ArrayList<string>();

            string resp;
            try {
                resp = rmt(m_name, args);
            }
            catch (zcd.ZCDError e) {
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

    internal class IdentityManagerRemote : Object, IIdentityManagerStub
    {
        private unowned FakeRmt rmt;
        public IdentityManagerRemote(FakeRmt rmt)
        {
            this.rmt = rmt;
        }

        public IDuplicationData? match_duplication(int arg0, IIdentityID arg1, IIdentityID arg2, IIdentityID arg3, string arg4, string arg5) throws StubError, DeserializeError
        {
            string m_name = "node.identity_manager.match_duplication";
            ArrayList<string> args = new ArrayList<string>();
            {
                // serialize arg0 (int migration_id)
                args.add(prepare_argument_int64(arg0));
            }
            {
                // serialize arg1 (IIdentityID peer_id)
                args.add(prepare_argument_object(arg1));
            }
            {
                // serialize arg2 (IIdentityID old_id)
                args.add(prepare_argument_object(arg2));
            }
            {
                // serialize arg3 (IIdentityID new_id)
                args.add(prepare_argument_object(arg3));
            }
            {
                // serialize arg4 (string old_id_new_mac)
                args.add(prepare_argument_string(arg4));
            }
            {
                // serialize arg5 (string old_id_new_linklocal)
                args.add(prepare_argument_string(arg5));
            }

            string resp;
            try {
                resp = rmt(m_name, args);
            }
            catch (zcd.ZCDError e) {
                throw new StubError.GENERIC(e.message);
            }

            // deserialize response
            string? error_domain = null;
            string? error_code = null;
            string? error_message = null;
            string doing = @"Reading return-value of $(m_name)";
            Object? ret;
            try {
                ret = read_return_value_object_maybe(typeof(IDuplicationData), resp, out error_domain, out error_code, out error_message);
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
            if (ret == null) return null;
            if (ret is ISerializable)
                if (!((ISerializable)ret).check_deserialization())
                    throw new DeserializeError.GENERIC(@"$(doing): instance of $(ret.get_type().name()) has not been fully deserialized");
            return (IDuplicationData)ret;
        }

    }

    internal class QspnManagerRemote : Object, IQspnManagerStub
    {
        private unowned FakeRmt rmt;
        public QspnManagerRemote(FakeRmt rmt)
        {
            this.rmt = rmt;
        }

        public IQspnEtpMessage get_full_etp(IQspnAddress arg0) throws PippoError, StubError, DeserializeError
        {
            string m_name = "node.qspn_manager.get_full_etp";
            ArrayList<string> args = new ArrayList<string>();
            {
                // serialize arg0 (IQspnAddress requesting_address)
                args.add(prepare_argument_object(arg0));
            }

            string resp;
            try {
                resp = rmt(m_name, args);
            }
            catch (zcd.ZCDError e) {
                throw new StubError.GENERIC(e.message);
            }

            // deserialize response
            string? error_domain = null;
            string? error_code = null;
            string? error_message = null;
            string doing = @"Reading return-value of $(m_name)";
            Object ret;
            try {
                ret = read_return_value_object_notnull(typeof(IQspnEtpMessage), resp, out error_domain, out error_code, out error_message);
            } catch (HelperNotJsonError e) {
                error(@"Error parsing JSON for return-value of $(m_name): $(e.message)");
            } catch (HelperDeserializeError e) {
                throw new DeserializeError.GENERIC(@"$(doing): $(e.message)");
            }
            if (error_domain != null)
            {
                string error_domain_code = @"$(error_domain).$(error_code)";
                if (error_domain_code == "PippoError.GENERIC")
                    throw new PippoError.GENERIC(error_message);
                if (error_domain_code == "DeserializeError.GENERIC")
                    throw new DeserializeError.GENERIC(error_message);
                throw new DeserializeError.GENERIC(@"$(doing): unrecognized error $(error_domain_code) $(error_message)");
            }
            if (ret is ISerializable)
                if (!((ISerializable)ret).check_deserialization())
                    throw new DeserializeError.GENERIC(@"$(doing): instance of $(ret.get_type().name()) has not been fully deserialized");
            return (IQspnEtpMessage)ret;
        }

    }
}
    """);
    write_file(@"$(r.rootname)_stub.vala", contents);
}