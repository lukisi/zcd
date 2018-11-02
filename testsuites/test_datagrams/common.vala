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
using zcd;
using TaskletSystem;

bool verbose;
IListenerHandle listen_s;
ArrayList<int> mymsgs;
int mynextmsgindex;
ServerDatagramDelegate datagram_dlg;

int main(string[] args)
{
    verbose = false; // default
    OptionContext oc = new OptionContext("<options>");
    OptionEntry[] entries = new OptionEntry[2];
    int index = 0;
    entries[index++] = {"verbose", 'v', 0, OptionArg.NONE, ref verbose, "Be verbose", null};
    entries[index++] = { null };
    oc.add_main_entries(entries, null);
    try {
        oc.parse(ref args);
    }
    catch (OptionError e) {
        print(@"Error parsing options: $(e.message)\n");
        return 1;
    }

    // Initialize tasklet system
    PthTaskletImplementer.init();
    ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
    // Pass tasklet system to the ZCD library
    init_tasklet_system(tasklet);

    // check LISTEN_PATHNAME does not exist
    if (FileUtils.test(LISTEN_PATHNAME, FileTest.EXISTS)) error(@"pathname $(LISTEN_PATHNAME) exists.");
    // IDs for my own messages:
    mymsgs = new ArrayList<int>();
    for (int i = 1; i < 10; i++) mymsgs.add(PID*1000+i);
    mynextmsgindex = 0;

    // start tasklet for LISTEN_PATHNAME
    datagram_dlg = new ServerDatagramDelegate();
    IErrorHandler error_handler = new ServerErrorHandler(@"for datagram_system_listen $(LISTEN_PATHNAME) $(SEND_PATHNAME) $(ACK_MAC)");
    listen_s = datagram_system_listen(LISTEN_PATHNAME, SEND_PATHNAME, ACK_MAC, datagram_dlg, error_handler);
    if (verbose) print("I am listening.\n");

    // start tasklet for timeout error
    tasklet.spawn(new TimeoutTasklet());

    // Behaviour peculiar node.
    do_peculiar();

    tasklet.ms_wait(50);
    listen_s.kill();
    if (verbose) print("I ain't listening anymore.\n");
    return 0;
}

class ServerErrorHandler : Object, IErrorHandler
{
    private string name;
    public ServerErrorHandler(string name)
    {
        this.name = name;
    }

    public void error_handler(Error e)
    {
        error(@"ServerErrorHandler '$(name)': $(e.message)");
    }
}

class ServerDatagramDelegate : Object, IDatagramDelegate
{
    public ServerDatagramDelegate() {
        sent_msgs = new ArrayList<int>();
        reported_acks = new ArrayList<string>();
    }
    private ArrayList<int> sent_msgs;
    private ArrayList<string> reported_acks;

    public void sending_msg(int id) {
        sent_msgs.add(id);
    }

    public bool is_my_own_message(int packet_id)
    {
        return packet_id in sent_msgs;
    }

    public void got_ack(int packet_id, string ack_mac)
    {
        if (packet_id in sent_msgs) {
            string reporting_ack = @"$(packet_id) from $(ack_mac)";
            if (reporting_ack in reported_acks) return;
            if (verbose) print(@"Got ack for $(reporting_ack).\n");
            reported_acks.add(reporting_ack);
        }
    }

    public IDatagramDispatcher? get_dispatcher(DatagramCallerInfo caller_info)
    {
        assert(caller_info.listener is DatagramSystemListener);
        DatagramSystemListener _listener = (DatagramSystemListener)caller_info.listener;
        if (verbose) print(@"_listener.listen_pathname = '$(_listener.listen_pathname)'.\n");
        if (verbose) print(@"_listener.send_pathname = '$(_listener.send_pathname)'.\n");
        if (verbose) print(@"_listener.ack_mac = '$(_listener.ack_mac)'.\n");
        if (verbose) print(@"caller_info.packet_id = '$(caller_info.packet_id)'.\n");
        if (verbose) print(@"caller_info.source_id = '$(caller_info.source_id)'.\n");
        if (verbose) print(@"caller_info.src_nic = '$(caller_info.src_nic)'.\n");
        if (verbose) print(@"caller_info.broadcast_id = '$(caller_info.broadcast_id)'.\n");
        if (verbose) print(@"caller_info.m_name = '$(caller_info.m_name)'.\n");
        if (verbose) print(@"caller_info.send_ack = $(caller_info.send_ack ? "TRUE" : "FALSE").\n");
        return new ServerDatagramDispatcher();
    }
}

class TimeoutTasklet : Object, ITaskletSpawnable
{
    public void * func()
    {
        tasklet.ms_wait(10000);
        listen_s.kill();
        error("Timeout expired");
    }
}