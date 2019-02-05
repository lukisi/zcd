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

[CCode (array_length = false, array_null_terminated = true)]
string[] _pathnames;
bool verbose;

int main(string[] _args)
{
    verbose = false;
    OptionContext oc = new OptionContext("<options>");
    OptionEntry[] entries = new OptionEntry[3];
    int index = 0;
    entries[index++] = {"in", 'i', 0, OptionArg.STRING_ARRAY, ref _pathnames, "Interfaces (e.g. -i 123_eth0). You can use it multiple times.", null};
    entries[index++] = {"verbose", 'v', 0, OptionArg.NONE, ref verbose, "Prints messages.", null};
    entries[index++] = { null };
    oc.add_main_entries(entries, null);
    try {
        oc.parse(ref _args);
    }
    catch (OptionError e) {
        print(@"Error parsing options: $(e.message)\n");
        return 1;
    }
    ArrayList<string> pathnames = new ArrayList<string>.wrap(_pathnames);

    ArrayList<string> listen_pathnames = new ArrayList<string>();
    ArrayList<string> send_pathnames = new ArrayList<string>();
    foreach (string s in pathnames)
    {
        listen_pathnames.add(@"send_$(s)");
        send_pathnames.add(@"recv_$(s)");
    }

    foreach (string listen_pathname in listen_pathnames)
    {
        // check listen_pathname does not exist
        if (FileUtils.test(listen_pathname, FileTest.EXISTS)) error(@"pathname $(listen_pathname) exists.");

        // start a thread to listen to the listen_pathname.
        Listener listener = new Listener(listen_pathname, send_pathnames);
        /*Thread<void*> listener_thread = */
        new Thread<void*> ("listener", listener.thread_func);
    }

    // register handlers for SIGINT and SIGTERM to exit
    Posix.@signal(Posix.Signal.INT, safe_exit);
    Posix.@signal(Posix.Signal.TERM, safe_exit);
    // Wait for SIGINT
    while (true)
    {
        Thread.usleep(10000);
        if (do_me_exit) break;
    }

    // TODO kill threads
    foreach (string listen_pathname in listen_pathnames)
        FileUtils.unlink(listen_pathname);

    return 0;
}

bool do_me_exit = false;
void safe_exit(int sig)
{
    // We got here because of a signal. Quick processing.
    do_me_exit = true;
}

class Listener : Object
{
    private string listen_pathname;
    private Gee.List<string> send_pathnames;
    private int packet_num;
    public Listener(string listen_pathname, Gee.List<string> send_pathnames)
    {
        this.listen_pathname = listen_pathname;
        this.send_pathnames = send_pathnames;
        packet_num = 0;
    }

    public void* thread_func () {
        try {
            Socket s = new Socket(SocketFamily.UNIX, SocketType.DATAGRAM, SocketProtocol.DEFAULT);
            assert (s != null);
            s.bind(new UnixSocketAddress(listen_pathname), true); // reuse?
            uint8[] buffer = new uint8[65536];
            while (true) {
                /*SocketAddress addr;
                ssize_t r = s.receive_from(out addr, buffer);*/
                ssize_t r = s.receive_from(null, buffer);
                if (r <= 0) error(@"receive_from returns $(r)");
                buffer[r] = 0; // null-terminate string
                string packet = (string)buffer;
                packet_num++;
                if (verbose) print(@"[$(printabletime())] Got packet #$(packet_num) from listener $(listen_pathname): $(packet)\n");

                // start a thread to write to the send_pathnames.
                foreach (string send_pathname in send_pathnames)
                {
                    Writer writer = new Writer(send_pathname, packet, packet_num, listen_pathname);
                    new Thread<void*> ("writer", writer.thread_func);
                }
            }
        } catch (Error e) {
            error(@"While reading from $(listen_pathname): $(e.message)");
        }
    }
}

class Writer : Object
{
    private string send_pathname;
    private string packet;
    private int packet_num;
    private string listen_pathname;
    public Writer(string send_pathname, string packet, int packet_num, string listen_pathname)
    {
        this.send_pathname = send_pathname;
        this.packet = packet;
        this.packet_num = packet_num;
        this.listen_pathname = listen_pathname;
    }

    public void* thread_func () {
        try {
            Thread.usleep(100);
            Socket s = new Socket(SocketFamily.UNIX, SocketType.DATAGRAM, SocketProtocol.DEFAULT);
            assert (s != null);
            // Check send_pathname DOES exist
            if (FileUtils.test(send_pathname, FileTest.EXISTS))
            {
                s.send_to(new UnixSocketAddress(send_pathname), packet.data);
                if (verbose) print(@"[$(printabletime())] Sent packet #$(packet_num) from listener $(listen_pathname) to $(send_pathname).\n");
            }
            return null;
        } catch (Error e) {
            message(@"While writing to $(send_pathname): $(e.message)");
            return null;
        }
    }
}

string printabletime()
{
    TimeVal now = TimeVal();
    now.get_current_time();
    string s_usec = @"$(now.tv_usec + 1000000)";
    s_usec = s_usec.substring(1);
    string s_sec = @"$(now.tv_sec)";
    s_sec = s_sec.substring(s_sec.length-3);
    return @"$(s_sec).$(s_usec)";
}