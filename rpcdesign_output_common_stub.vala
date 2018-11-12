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

void output_common_stub(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    public interface IAckCommunicator : Object
    {
        public abstract void process_src_nics_list(Gee.List<ISrcNic> src_nics_list);
    }

    internal delegate string FakeRmt(string m_name, Gee.List<string> arguments) throws zcd.ZCDError, StubError;

    internal class NotifyAckTasklet : Object, ITaskletSpawnable
    {
        public NotifyAckTasklet(IAckCommunicator notify_ack, IChannel ch)
        {
            this.notify_ack = notify_ack;
            this.ch = ch;
        }
        private IAckCommunicator notify_ack;
        private IChannel ch;
        public void * func()
        {
            ArrayList<string> s_src_nics_list = (ArrayList<string>)ch.recv();
            ArrayList<ISrcNic> src_nics_list = new ArrayList<ISrcNic>();
            foreach (string s_src_nic in s_src_nics_list)
            {
                try {
                    ISrcNic src_nic = deser_src_nic(s_src_nic);
                    src_nics_list.add(src_nic);
                } catch (HelperDeserializeError e) {
                    warning(@"Unrecognized ACK: $(e.message)");
                }
            }
            notify_ack.process_src_nics_list(src_nics_list);
            return null;
        }
    }
}
    """);
    write_file("common_stub.vala", contents);
}