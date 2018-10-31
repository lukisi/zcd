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

    // start tasklet for party_a
    PartyATasklet t_a = new PartyATasklet();
    ITaskletHandle th_a = tasklet.spawn(t_a);

    // start tasklet for party_b
    PartyBTasklet t_b = new PartyBTasklet();
    ITaskletHandle th_b = tasklet.spawn(t_b);

    // wait
    while (true)
    {
        tasklet.ms_wait(300);
        if (! th_b.is_running())
        {
            party_a_cleanup();
            return 0;
        }
        if (! th_a.is_running())
        {
            error("test not completed.");
        }
    }
}

class PartyATasklet : Object, ITaskletSpawnable
{
    public void * func()
    {
        party_a_body();
        return null;
    }
}

class PartyBTasklet : Object, ITaskletSpawnable
{
    public void * func()
    {
        party_b_body();
        return null;
    }
}