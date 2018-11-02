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

bool launched;
// Node alpha: pid=1234, I=wlan0
const int PID = 1234;
const string LISTEN_PATHNAME = "recv_1234_wlan0";
const string ACK_MAC = "fe:aa:aa:aa:aa:aa";
const string SEND_PATHNAME = "send_1234_wlan0";

void do_peculiar() {
    // wait for "launch()"
    launched = false;
    while (! launched) tasklet.ms_wait(5);

    // message: alpha1
    int packet_id = mymsgs[mynextmsgindex++];
    datagram_dlg.sending_msg(packet_id);
    try {
        send_datagram_system(SEND_PATHNAME, packet_id,
            "{}", "{}", "{}",
            "alpha1", new ArrayList<string>(), true);
    } catch (ZCDError e) {
        error(@"alpha_main: alpha1: $(e.message)");
    }

    // wait 400 ms"
    tasklet.ms_wait(400);
}

class ServerDatagramDispatcher : Object, IDatagramDispatcher
{
    public void execute(string m_name, Gee.List<string> args, DatagramCallerInfo caller_info)
    {
        string next = "";
        if (verbose) print(@"executing $(m_name)(");
        foreach (string arg in args)
        {
            if (verbose) print(@"$(next)'$(arg)'");
            next = ", ";
        }
        if (verbose) print(")\n");
        if (m_name == "launch") launched = true;
    }
}