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
int status;
const string test_unicast_id = "749723";
const string test_source_id = "123456";
const string method_name = "my_app.do_stuff";
void metronome()
{
    status = 0;
    print("metronome: started. now waits for a beat.\n");
    ch_metronome.recv();
    print("metronome: got the beat. now wait a little...\n");
    real_tasklet.ms_wait(10);
    print("metronome: now tell the simulator to accept the connection...\n");
    ch_server_accepts_connection.send(0);
}

void main()
{
    /* This test acts as a client for a remote call in TCP.
     * A program gets a TcpClient to connect to 169.254.0.1 on port 269, to talk to identity 749723 from identity 123456. Then, it uses the object to transmit a call and get a response. The module requests the connection and the sending of a well formatted message. The request specifies to not wait for the reply: the program gets an empty string.
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_server_accepts_connection = real_tasklet.get_channel();
    ch_metronome = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome));
    zcd.init_tasklet_system(fake_tasklet);

    try {
        fake_tasklet.prepare_get_client_stream_socket(
            /* connect func */
            () => {
                print("simulator: the connection has been requested...\n");
                ch_server_accepts_connection.recv();
                print("simulator: now reporting that the connection is done.\n");
            },
            /* recv func */
            (b, maxlen) => {
                /*uint8* b, size_t maxlen*/
                error("should not get there");
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
                    assert(method_name in s);
                    assert(test_unicast_id in s);
                    assert(test_source_id in s);
                    assert("\"wait-reply\":false" in s);
                }
                return;
            },
            /* close func */
            () => {
                print(@"going to fake closing of connection.\n");
                return;
            }
        );
        // Prepare a TcpClient. This does not open a connection yet.
        string ser_my_source_id = @"{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":$(test_source_id)}}";
        string ser_dest_unicast_id = @"{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":$(test_unicast_id)}}";
        TcpClient tcp = zcd.tcp_client("169.254.0.1", 269, ser_my_source_id, ser_dest_unicast_id);

        // simulate a remote call.
        real_tasklet.ms_wait(10);
        print("first beat to metronome...\n");
        ch_metronome.send(0);
        print("first beat to metronome has been sent.\n");
        string res = tcp.enqueue_call(method_name, new ArrayList<string>.wrap({"{\"argument\":1}", "{\"argument\":\"ab\"}"}), false);

        print(@"res = '$(res)'\n");
        assert(res == "");
    }
    catch (ZCDError e)
    {
        error(@"Got a ZdcError: $(e.message)");
    }
    print("TcpClient went out of scope.\n");

    PthTaskletImplementer.kill();
}

