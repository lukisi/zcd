/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2016 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
using TaskletSystem;
using zcd;

delegate void SimpleFuncDelegate();
class SimpleTaskletSpawner : Object, ITaskletSpawnable
{
    public SimpleTaskletSpawner(owned SimpleFuncDelegate x)
    {
        this.x = (owned) x;
    }
    private SimpleFuncDelegate x;
    public void * func()
    {
        x();
        return null;
    }
}

ITasklet real_tasklet;
FakeTaskletSystemImplementer fake_tasklet;

IChannel ch_metronome;
IChannel ch_server_accepts_connection;
IChannel ch_client_waits_reply;
IChannel ch_server_sends_reply_len;
int status;
void metronome()
{
    status = 0;
    ch_metronome.recv();
    real_tasklet.ms_wait(10);
    ch_server_accepts_connection.send(0);
    ch_client_waits_reply.recv();
    ch_server_sends_reply_len.send(200);
}

void main()
{
    /* This test acts as a client for a remote call in TCP.
     * 
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_server_accepts_connection = real_tasklet.get_channel();
    ch_metronome = real_tasklet.get_channel();
    ch_client_waits_reply = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome));
    zcd.init_tasklet_system(fake_tasklet);

    try {
        fake_tasklet.prepare_get_client_stream_socket(
            /* recv func */
            (b, maxlen) => {
                /*uint8* b, size_t maxlen*/
                print(@"going to fake a recv of at most $(maxlen) bytes.\n");
                error("not implemented yet");
                // TODO
            },
            /* send func */
            (b, len) => {
                /*uint8* b, size_t len*/
                print(@"going to fake a send of $(len) bytes.\n");
                if (len == 4) print(@" first 4 bytes are $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
                else
                {
                    string s = (string)b;
                    print(@" content: '$(s)'.\n");
                }
                // TODO improve output?
                return;
            },
            /* close func */
            () => {
                print(@"going to fake closing of connection.\n");
                // TODO error on future trials?
                return;
            }
        );
        // Prepare a TcpClient. This does not open a connection yet.
        string ser_my_source_id = "{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":123456}}";
        string ser_dest_unicast_id = "{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":749723}}";
        TcpClient tcp = zcd.tcp_client("169.254.0.1", 269, ser_my_source_id, ser_dest_unicast_id);

        // simulate a remote call.
        ch_metronome.send(0);
        string res = tcp.enqueue_call("a.b", new ArrayList<string>.wrap({"{\"argument\":1}", "{\"argument\":\"ab\"}"}), true);

        print(@"res = $(res)\n");
        real_tasklet.ms_wait(100);
    }
    catch (ZCDError e)
    {
        error(@"Got a ZdcError: $(e.message)");
    }

    PthTaskletImplementer.kill();
}

