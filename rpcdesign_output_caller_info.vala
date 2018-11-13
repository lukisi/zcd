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

void output_caller_info(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;

namespace SampleRpc
{
    public abstract class CallerInfo : Object
    {
        internal CallerInfo() {}
    }

    public abstract class Listener : Object
    {
        internal Listener() {}
    }

    public class StreamCallerInfo : CallerInfo
    {
        internal StreamCallerInfo(
            zcd.StreamCallerInfo src) throws HelperDeserializeError
        {
            source_id = deser_source_id(src.source_id);
            src_nic = deser_src_nic(src.src_nic);
            unicast_id = deser_unicast_id(src.unicast_id);
            m_name = src.m_name;
            wait_reply = src.wait_reply;
            listener = listener_from_zcd(src.listener);
        }

        public ISourceID source_id {get; private set;}
        public ISrcNic src_nic {get; private set;}
        public IUnicastID unicast_id {get; private set;}
        public string m_name {get; private set;}
        public bool wait_reply {get; private set;}
        public Listener listener {get; private set;}
    }

    public class DatagramCallerInfo : CallerInfo
    {
        internal DatagramCallerInfo(
            zcd.DatagramCallerInfo src) throws HelperDeserializeError
        {
            packet_id = src.packet_id;
            source_id = deser_source_id(src.source_id);
            src_nic = deser_src_nic(src.src_nic);
            broadcast_id = deser_broadcast_id(src.broadcast_id);
            m_name = src.m_name;
            send_ack = src.send_ack;
            listener = listener_from_zcd(src.listener);
        }

        public int packet_id {get; private set;}
        public ISourceID source_id {get; private set;}
        public ISrcNic src_nic {get; private set;}
        public IBroadcastID broadcast_id {get; private set;}
        public string m_name {get; private set;}
        public bool send_ack {get; private set;}
        public Listener listener {get; private set;}
    }

    public class StreamNetListener : Listener
    {
        internal StreamNetListener(
            string my_ip,
            uint16 tcp_port)
        {
            this.my_ip = my_ip;
            this.tcp_port = tcp_port;
        }

        public string my_ip {get; private set;}
        public uint16 tcp_port {get; private set;}
    }

    public class StreamSystemListener : Listener
    {
        internal StreamSystemListener(
            string listen_pathname)
        {
            this.listen_pathname = listen_pathname;
        }

        public string listen_pathname {get; private set;}
    }

    public class DatagramNetListener : Listener
    {
        internal DatagramNetListener(
            string my_dev,
            uint16 udp_port,
            string src_nic)
        {
            this.my_dev = my_dev;
            this.udp_port = udp_port;
            this.src_nic = src_nic;
        }

        public string my_dev {get; private set;}
        public uint16 udp_port {get; private set;}
        public string src_nic {get; private set;}
    }

    public class DatagramSystemListener : Listener
    {
        internal DatagramSystemListener(
            string listen_pathname,
            string send_pathname,
            string src_nic)
        {
            this.listen_pathname = listen_pathname;
            this.send_pathname = send_pathname;
            this.src_nic = src_nic;
        }

        public string listen_pathname {get; private set;}
        public string send_pathname {get; private set;}
        public string src_nic {get; private set;}
    }

    internal IUnicastID deser_unicast_id(string s_unicast_id) throws HelperDeserializeError
    {
        Object val;
        try {
            val = read_direct_object_notnull(typeof(IUnicastID), s_unicast_id);
        } catch (HelperNotJsonError e) {
            error(@"deser_unicast_id: Error parsing JSON: $(e.message)");
        } catch (HelperDeserializeError e) {
            throw new HelperDeserializeError.GENERIC(@"deser_unicast_id: $(e.message)");
        }
        if (val is ISerializable) {
            if (!((ISerializable)val).check_deserialization()) {
                throw new HelperDeserializeError.GENERIC("deser_unicast_id: bad deserialization");
            }
        }
        return (IUnicastID)val;
    }

    internal IBroadcastID deser_broadcast_id(string s_broadcast_id) throws HelperDeserializeError
    {
        Object val;
        try {
            val = read_direct_object_notnull(typeof(IBroadcastID), s_broadcast_id);
        } catch (HelperNotJsonError e) {
            error(@"deser_broadcast_id: Error parsing JSON: $(e.message)");
        } catch (HelperDeserializeError e) {
            throw new HelperDeserializeError.GENERIC(@"deser_broadcast_id: $(e.message)");
        }
        if (val is ISerializable) {
            if (!((ISerializable)val).check_deserialization()) {
                throw new HelperDeserializeError.GENERIC("deser_broadcast_id: bad deserialization");
            }
        }
        return (IBroadcastID)val;
    }

    internal ISourceID deser_source_id(string s_source_id) throws HelperDeserializeError
    {
        Object val;
        try {
            val = read_direct_object_notnull(typeof(ISourceID), s_source_id);
        } catch (HelperNotJsonError e) {
            error(@"deser_source_id: Error parsing JSON: $(e.message)");
        } catch (HelperDeserializeError e) {
            throw new HelperDeserializeError.GENERIC(@"deser_source_id: $(e.message)");
        }
        if (val is ISerializable) {
            if (!((ISerializable)val).check_deserialization()) {
                throw new HelperDeserializeError.GENERIC("deser_source_id: bad deserialization");
            }
        }
        return (ISourceID)val;
    }

    internal ISrcNic deser_src_nic(string s_src_nic) throws HelperDeserializeError
    {
        Object val;
        try {
            val = read_direct_object_notnull(typeof(ISrcNic), s_src_nic);
        } catch (HelperNotJsonError e) {
            error(@"deser_src_nic: Error parsing JSON: $(e.message)");
        } catch (HelperDeserializeError e) {
            throw new HelperDeserializeError.GENERIC(@"deser_src_nic: $(e.message)");
        }
        if (val is ISerializable) {
            if (!((ISerializable)val).check_deserialization()) {
                throw new HelperDeserializeError.GENERIC("deser_src_nic: bad deserialization");
            }
        }
        return (ISrcNic)val;
    }

    internal Listener listener_from_zcd(zcd.Listener src)
    {
        if (src is zcd.StreamNetListener) {
            zcd.StreamNetListener l = (zcd.StreamNetListener)src;
            return new StreamNetListener(l.my_ip, l.tcp_port);
        } else if (src is zcd.StreamSystemListener) {
            zcd.StreamSystemListener l = (zcd.StreamSystemListener)src;
            return new StreamSystemListener(l.listen_pathname);
        } else if (src is zcd.DatagramNetListener) {
            zcd.DatagramNetListener l = (zcd.DatagramNetListener)src;
            return new DatagramNetListener(l.my_dev, l.udp_port, l.src_nic);
        } else if (src is zcd.DatagramSystemListener) {
            zcd.DatagramSystemListener l = (zcd.DatagramSystemListener)src;
            return new DatagramSystemListener(l.listen_pathname, l.send_pathname, l.src_nic);
        } else {
            error("Unrecognized zcd.Listener");
        }
    }
}
    """);
    write_file("caller_info.vala", contents);
}