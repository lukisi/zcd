/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

void make_common_skeleton(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;

namespace zcd
{
    namespace ModRpc
    {
        internal IZcdTasklet tasklet;

        public void init_tasklet_system(zcd.IZcdTasklet _tasklet)
        {
            zcd.init_tasklet_system(_tasklet);
            tasklet = _tasklet;
        }

        public interface IRpcErrorHandler : Object
        {
            public abstract void error_handler(Error e);
        }

        public abstract class CallerInfo : Object
        {
        }

        public class TcpCallerInfo : CallerInfo
        {
            internal TcpCallerInfo(string my_address, string peer_address)
            {
                this.my_address = my_address;
                this.peer_address = peer_address;
            }
            public string my_address {get; private set;}
            public string peer_address {get; private set;}
        }

        internal const string s_unicast_service_prefix_response = "RESPONSE:";
        internal const string s_unicast_service_prefix_fail = "FAIL:";
        internal const int udp_timeout_msec = 3000;
        internal HashMap<string, ZcdUdpServiceMessageDelegate>? map_udp_listening = null;
        internal class ZcdUdpServiceMessageDelegate : Object, IZcdUdpServiceMessageDelegate
        {
            public ZcdUdpServiceMessageDelegate()
            {
                waiting_for_response = new HashMap<int, WaitingForResponse>();
                waiting_for_ack = new HashMap<int, WaitingForAck>();
                waiting_for_recv = new HashMap<int, WaitingForRecv>();
            }

            private class WaitingForResponse : Object, IZcdTaskletSpawnable
            {
                public WaitingForResponse(ZcdUdpServiceMessageDelegate parent, int id, Timer timer, IZcdChannel ch)
                {
                    this.parent = parent;
                    this.id = id;
                    this.timer = timer;
                    this.ch = ch;
                    has_response = false;
                }
                private ZcdUdpServiceMessageDelegate parent;
                private int id;
                public Timer timer;
                private IZcdChannel ch;
                public string response;
                public bool has_response;
                public void* func()
                {
                    while (true)
                    {
                        if (has_response)
                        {
                            // report 'response' through 'ch'
                            ch.send_async(s_unicast_service_prefix_response + response);
                            parent.waiting_for_response.unset(id);
                            return null;
                        }
                        if (timer.is_expired())
                        {
                            // report communication error through 'ch'
                            ch.send_async(s_unicast_service_prefix_fail + "Timeout before reply or keepalive");
                            parent.waiting_for_response.unset(id);
                            return null;
                        }
                        tasklet.ms_wait(2);
                    }
                }
            }
            private HashMap<int, WaitingForResponse> waiting_for_response;

            private class WaitingForAck : Object, IZcdTaskletSpawnable
            {
                public WaitingForAck(ZcdUdpServiceMessageDelegate parent, int id, int timeout_msec, IZcdChannel ch)
                {
                    this.parent = parent;
                    this.id = id;
                    this.timeout_msec = timeout_msec;
                    this.ch = ch;
                    macs_list = new ArrayList<string>();
                }
                private ZcdUdpServiceMessageDelegate parent;
                private int id;
                private int timeout_msec;
                private IZcdChannel ch;
                public ArrayList<string> macs_list {get; private set;}
                public void* func()
                {
                    tasklet.ms_wait(timeout_msec);
                    // report 'macs_list' through 'ch'
                    ch.send_async(macs_list);
                    parent.waiting_for_ack.unset(id);
                    return null;
                }
            }
            private HashMap<int, WaitingForAck> waiting_for_ack;

            private class WaitingForRecv : Object, IZcdTaskletSpawnable
            {
                public WaitingForRecv(ZcdUdpServiceMessageDelegate parent, int id, int timeout_msec)
                {
                    this.parent = parent;
                    this.id = id;
                    this.timeout_msec = timeout_msec;
                }
                private ZcdUdpServiceMessageDelegate parent;
                private int id;
                private int timeout_msec;
                public void* func()
                {
                    tasklet.ms_wait(timeout_msec);
                    parent.waiting_for_recv.unset(id);
                    return null;
                }
            }
            private HashMap<int, WaitingForRecv> waiting_for_recv;

            internal void going_to_send_unicast_with_reply(int id, IZcdChannel ch)
            {
                var w = new WaitingForResponse(this, id, new Timer(udp_timeout_msec), ch);
                tasklet.spawn(w);
                waiting_for_response[id] = w;
            }

            internal void going_to_send_broadcast_with_ack(int id, IZcdChannel ch)
            {
                var w = new WaitingForAck(this, id, udp_timeout_msec, ch);
                tasklet.spawn(w);
                waiting_for_ack[id] = w;
            }

            internal void going_to_send_unicast_no_reply(int id)
            {
                var w = new WaitingForRecv(this, id, udp_timeout_msec);
                tasklet.spawn(w);
                waiting_for_recv[id] = w;
            }

            internal void going_to_send_broadcast_no_ack(int id)
            {
                var w = new WaitingForRecv(this, id, udp_timeout_msec);
                tasklet.spawn(w);
                waiting_for_recv[id] = w;
            }

            public bool is_my_own_message(int id)
            {
                if (waiting_for_response.has_key(id)) return true;
                if (waiting_for_ack.has_key(id)) return true;
                if (waiting_for_recv.has_key(id)) return true;
                return false;
            }

            public void got_keep_alive(int id)
            {
                if (waiting_for_response.has_key(id))
                {
                    waiting_for_response[id].timer = new Timer(udp_timeout_msec);
                }
            }

            public void got_response(int id, string response)
            {
                if (waiting_for_response.has_key(id))
                {
                    waiting_for_response[id].response = response;
                    waiting_for_response[id].has_response = true;
                }
            }

            public void got_ack(int id, string mac)
            {
                if (waiting_for_ack.has_key(id))
                {
                    if (! (mac in waiting_for_ack[id].macs_list))
                        waiting_for_ack[id].macs_list.add(mac);
                }
            }
        }

        internal class ZcdTcpAcceptErrorHandler : Object, IZcdTcpAcceptErrorHandler
        {
            private IRpcErrorHandler err;
            public ZcdTcpAcceptErrorHandler(IRpcErrorHandler err)
            {
                this.err = err;
            }

            public void error_handler(Error e)
            {
                err.error_handler(e);
            }
        }

        internal class ZcdUdpCreateErrorHandler : Object, IZcdUdpCreateErrorHandler
        {
            private IRpcErrorHandler err;
            private string k_map;
            public ZcdUdpCreateErrorHandler(IRpcErrorHandler err, string k_map)
            {
                this.err = err;
                this.k_map = k_map;
            }

            public void error_handler(Error e)
            {
                if (map_udp_listening != null)
                    map_udp_listening.unset(k_map);
                err.error_handler(e);
            }
        }

        internal class ZcdDispatcherForError : Object, IZcdDispatcher
        {
            private string domain;
            private string code;
            private string message;
            public ZcdDispatcherForError(string domain, string code, string message)
            {
                this.domain = domain;
                this.code = code;
                this.message = message;
            }

            public string execute()
            {
                return prepare_error(domain, code, message);
            }
        }

        internal class Timer : Object
        {
            protected TimeVal exp;
            public Timer(int64 msec_ttl)
            {
                set_time(msec_ttl);
            }

            protected void set_time(int64 msec_ttl)
            {
                exp = TimeVal();
                exp.get_current_time();
                long milli = (long)(msec_ttl % (int64)1000);
                long seconds = (long)(msec_ttl / (int64)1000);
                int64 check_seconds = (int64)exp.tv_sec;
                check_seconds += (int64)seconds;
                assert(check_seconds <= long.MAX);
                exp.add(milli*1000);
                exp.tv_sec += seconds;
            }

            public bool is_younger(Timer t)
            {
                if (exp.tv_sec > t.exp.tv_sec) return true;
                if (exp.tv_sec < t.exp.tv_sec) return false;
                if (exp.tv_usec > t.exp.tv_usec) return true;
                return false;
            }

            public bool is_expired()
            {
                Timer now = new Timer(0);
                return now.is_younger(this);
            }
        }
    }
}
    """);
    write_file("common_skeleton.vala", contents);
}

