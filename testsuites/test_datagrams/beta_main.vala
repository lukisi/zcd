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

    // Node beta: pid=567, I=wlan0
    string listen_pathname = "recv_567_wlan0";
    string send_pathname = "send_567_wlan0";
    string ack_mac = "fe:bb:bb:bb:bb:bb";
    // check listen_pathname does not exist
    if (FileUtils.test(listen_pathname, FileTest.EXISTS)) error(@"pathname $(listen_pathname) exists.");
    // IDs for my own messages:
    ArrayList<int> mymsgs = new ArrayList<int>.wrap(
        {567001,567002,567003,567004,567005,567006,567007,567008,567009});
    int mynextmsgindex = 0;

    // start tasklet for listen_pathname
    ServerDatagramDelegate datagram_dlg = new ServerDatagramDelegate();
    IErrorHandler error_handler = new ServerErrorHandler(@"for datagram_system_listen $(listen_pathname) $(send_pathname) $(ack_mac)");
    listen_s = datagram_system_listen(listen_pathname, send_pathname, ack_mac, datagram_dlg, error_handler);
    if (verbose) print("I am listening.\n");

    // start tasklet for timeout error
    tasklet.spawn(new TimeoutTasklet());

    // Behaviour node beta.

    // wait a bit then launch
    tasklet.ms_wait(50);
    int packet_id = mymsgs[mynextmsgindex++];
    datagram_dlg.sending_msg(packet_id);
    try {
        send_datagram_system(send_pathname, packet_id,
            "{}", "{}", "{}",
            "launch", new ArrayList<string>(), true);
    } catch (ZCDError e) {
        error(@"beta_main: launch: $(e.message)");
    }

    // TODO

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
    }
    private ArrayList<int> sent_msgs;

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
            if (verbose) print(@"Got ack for $(packet_id) from $(ack_mac).\n");
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

class ServerDatagramDispatcher : Object, IDatagramDispatcher
{
    public void execute(string m_name, Gee.List<string> args, DatagramCallerInfo caller_info)
    {
        string next = "";
        if (verbose) print(@"party_a executing $(m_name)(");
        foreach (string arg in args)
        {
            if (verbose) print(@"$(next)'$(arg)'");
            next = ", ";
        }
        if (verbose) print(")\n");
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