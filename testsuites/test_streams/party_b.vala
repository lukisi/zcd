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

void party_b_body() {
    tasklet.ms_wait(300);
    print("party b try and send 'wrong' no-reply.\n");
    try {
        string ret = send_stream_system(
            "conn_10_1_1_1",
            "{}", "{}", "{}",
            "wrong", new ArrayList<string>.wrap({"{}", "{}"}), false);
        print(@"send_stream_system returns '$(ret)'\n");
    } catch (ZCDError e) {
        error(@"ZCDError $(e.message)");
    }
    tasklet.ms_wait(300);
    print("party b try and send 'wrong' with-reply.\n");
    try {
        string ret = send_stream_system(
            "conn_10_1_1_1",
            "{}", "{}", "{}",
            "wrong", new ArrayList<string>.wrap({"{}", "{}"}), true);
        assert_not_reached();
    } catch (ZCDError e) {
        print(@"Expected ZCDError $(e.message)\n");
    }
    tasklet.ms_wait(300);
    print("party b try and send 'void' no-reply.\n");
    try {
        string ret = send_stream_system(
            "conn_10_1_1_1",
            "{}", "{}", "{}",
            "void", new ArrayList<string>.wrap({"{}", "{}"}), false);
        print(@"send_stream_system returns '$(ret)'\n");
    } catch (ZCDError e) {
        error(@"ZCDError $(e.message)");
    }
    tasklet.ms_wait(300);
    print("party b try and send 'test1' with-reply.\n");
    try {
        string ret = send_stream_system(
            "conn_10_1_1_1",
            "{}", "{}", "{}",
            "test1", new ArrayList<string>.wrap({"{}", "{}"}), true);
        print(@"send_stream_system returns '$(ret)'\n");
    } catch (ZCDError e) {
        error(@"ZCDError $(e.message)");
    }
}