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

// Node beta: pid=567, I=wlan0
const int PID = 567;
const string LISTEN_PATHNAME = "recv_567_wlan0";
const string PSEUDOMAC = "fe:bb:bb:bb:bb:bb";
const string SEND_PATHNAME = "send_567_wlan0";

void do_peculiar() {
    // wait a bit then launch
    tasklet.ms_wait(50);
    int packet_id = mymsgs[mynextmsgindex++];
    datagram_dlg.sending_msg(packet_id);
    try {
        send_datagram_system(SEND_PATHNAME, packet_id,
            "{}", my_src_nic, "{}",
            "launch", new ArrayList<string>(), true);
    } catch (ZCDError e) {
        error(@"beta_main: launch: $(e.message)");
    }

    // wait 500 ms"
    tasklet.ms_wait(500);
}

void do_peculiar_check() {
    // Check that beta receives ack from alpha for its msg:
    int i1 = events.index_of(">ack_567001_fe:aa:aa:aa:aa:aa\n");
    assert(i1 >= 0);
    // Check that beta receives ack from gamma for its msg:
    int i2 = events.index_of(">ack_567001_fe:cc:cc:cc:cc:cc\n");
    assert(i2 >= 0);
    // Check that beta doesn't receive its own req:
    int i3 = events.index_of(">req_567001_launch\n");
    assert(i3 < 0);
    // Check that beta receives req from alpha:
    int i4 = events.index_of(">req_1234001_alpha1\n");
    assert(i4 >= i1);
    assert(i4 >= i2);
    // Check that beta receives req from gamma:
    int i5 = events.index_of(">req_890001_gamma1\n");
    assert(i5 >= i4);
/*

alpha events:
>req_567001_launch
>ack_1234001_fe:bb:bb:bb:bb:bb
---------------

beta events:
>ack_567001_fe:cc:cc:cc:cc:cc
>ack_567001_fe:aa:aa:aa:aa:aa
>req_1234001_alpha1
>req_890001_gamma1
---------------

gamma events:
>req_567001_launch
---------------

*/
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
    }
}