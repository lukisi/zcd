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

void main()
{
    /**
     This program reads file interfaces.rpcidl and creates the following:
      * common_helpers.vala   
      * common_skeleton.vala
      * common_stub.vala
      * sample_interfaces.vala
      * sample_skeleton.vala
      * sample_stub.vala
     Afterwards, you can:
      * Modify main namespace (SampleRpc) in *.vala
      * Create a convenience library with common_helpers.vala
      * Build the library with remaining files.
     */
    string[] lines = read_file("interfaces.rpcidl");
    print(@"lines.length = $(lines.length)\n");
    Root r0 = read_root(lines[0]);
    ModuleRemote m00 = read_module(lines[1]);
    Method m000 = read_method(lines[2]);
    int pos = 3;
    Gee.List<Root> roots = new ArrayList<Root>();
    Gee.List<Exception> errors = new ArrayList<Exception>();
    roots.add(r0);
    r0.modules.add(m00);
    m00.methods.add(m000);
    bool must_be_method = false;
    bool must_be_module = false;
    while (pos < lines.length)
    {
        print(@"pos $(pos)\n");
        string line = lines[pos++];
        if (line == "") continue;
        if (line == "Errors") break;
        if (line.has_prefix("   ")) error("indent error");
        if (line.has_prefix("  "))
        {
            if (must_be_module) error("must be module");
            Method _m = read_method(line);
            Root r = roots.last();
            ModuleRemote m = r.modules.last();
            m.methods.add(_m);
        }
        else if (line.has_prefix(" "))
        {
            if (must_be_method) error("must be method");
            ModuleRemote m = read_module(line);
            Root r = roots.last();
            r.modules.add(m);
        }
        else
        {
            if (must_be_module) error("must be module");
            if (must_be_method) error("must be method");
            Root r = read_root(line);
            roots.add(r);
        }
    }
    pos = 3;
    bool errors_def_found = false;
    while (pos < lines.length)
    {
        string line = lines[pos++];
        if (line == "Errors")
        {
            errors_def_found = true;
            break;
        }
    }
    if (errors_def_found) while (pos < lines.length)
    {
        print(@"pos $(pos)\n");
        string line = lines[pos++];
        if (line == "") continue;
        if (line.has_prefix("  ")) error("indent error");
        if (!line.has_prefix(" ")) error("indent error");
        while (line.has_prefix(" ")) line = line.substring(1);
        while (line.has_suffix(" ")) line = line.substring(0, line.length-1);
        if (!line.has_suffix(")")) error("bad error def");
        line = line.substring(0, line.length-1);
        string[] parts = line.split("(");
        if (parts.length != 2) error("bad error def");
        string errdomain = parts[0];
        string[] errcodes = parts[1].split(",");
        while (errdomain.has_prefix(" ")) errdomain = errdomain.substring(1);
        while (errdomain.has_suffix(" ")) errdomain = errdomain.substring(0, errdomain.length-1);
        if (errdomain == "") error("bad error def");
        Exception exc = new Exception(errdomain);
        foreach (string errcode in errcodes)
        {
            while (errcode.has_prefix(" ")) errcode = errcode.substring(1);
            while (errcode.has_suffix(" ")) errcode = errcode.substring(0, errcode.length-1);
            if (errcode == "") error("bad error def");
            exc.errcodes.add(errcode);
        }
        errors.add(exc);
    }
    foreach (Root r in roots) foreach (ModuleRemote m in r.modules) foreach (Method me in m.methods)
    {
        foreach (string s_error in me.s_errors)
        {
            bool absent = true;
            foreach (Exception exc in errors)
            {
                if (exc.errdomain == s_error)
                {
                    me.errors.add(exc);
                    absent = false;
                    break;
                }
            }
            if (absent) error(@"bad error name $(s_error)");
        }
    }
    print("parsed.\n");
    foreach (Root r in roots)
    {
        print(@"Root: class $(r.rootclass) name $(r.rootname).\n");
        foreach (ModuleRemote m in r.modules)
        {
            print(@" Module: class $(m.modclass) name $(m.modname).\n");
            foreach (Method me in m.methods)
            {
                print(@"  Method: returntype $(me.returntype) name $(me.name).\n");
                foreach (Argument arg in me.args)
                {
                    print(@"   Arg: class $(arg.argclass) name $(arg.argname).\n");
                }
                foreach (Exception error in me.errors)
                {
                    print(@"   Exception: domain $(error.errdomain) codes ");
                    foreach (string errcode in error.errcodes)
                    {
                        print(@"$(errcode),");
                    }
                    print(@".\n");
                }
            }
        }
    }
    make_common_helpers(roots, errors);
    make_common_skeleton(roots, errors);
    make_common_stub(roots, errors);
    make_sample_interfaces(roots, errors);
    make_sample_skeleton(roots, errors);
    make_sample_stub(roots, errors);
}

internal Root read_root(owned string line)
{
    if (line.has_prefix(" ")) error("must be root line");
    string[] ret = line.split(" ");
    if (ret.length != 2) error("root must have 2 words");
    return new Root(ret[0], ret[1]);
}

internal ModuleRemote read_module(owned string line)
{
    if (line.has_prefix("  ")) error("must be module line");
    if (!line.has_prefix(" ")) error("must be module line");
    line = line.substring(1);
    string[] ret = line.split(" ");
    if (ret.length != 2) error("module must have 2 words");
    return new ModuleRemote(ret[0], ret[1]);
}

internal Method read_method(owned string line)
{
    if (line.has_prefix("   ")) error("must be method line");
    if (!line.has_prefix("  ")) error("must be method line");
    line = line.substring(2);
    string[] parts = line.split(" ");
    if (parts.length < 2) error("method must have type");
    string mtype = parts[0];
    line = line.substring(mtype.length+1);
    if (line.has_prefix(" ")) error("only one space between words");
    parts = line.split("(");
    if (parts.length < 2) error("method must have name before '('");
    string mname = parts[0];
    line = line.substring(mname.length+1);
    parts = line.split(")");
    if (parts.length != 2) error("method must have one ')'");
    Gee.List<Argument> args = read_args(parts[0]);
    Gee.List<string> s_errors = new ArrayList<string>();
    if (parts[1] != "")
    {
        s_errors.add_all(read_errors(parts[1]));
    }
    Method ret = new Method();
    ret.returntype = mtype;
    ret.name = mname;
    ret.s_errors.add_all(s_errors);
    ret.args.add_all(args);
    return ret;
}

internal Gee.List<Argument> read_args(owned string line)
{
    Gee.List<Argument> ret = new ArrayList<Argument>();
    string[] args = line.split(",");
    foreach (string arg in args)
    {
        Argument a = read_arg(arg);
        ret.add(a);
    }
    return ret;
}

internal Argument read_arg(owned string line)
{
    while (line.has_prefix(" ")) line = line.substring(1);
    while (line.has_suffix(" ")) line = line.substring(0, line.length-1);
    string[] ret = line.split(" ");
    if (ret.length != 2) error("arg must have 2 words");
    return new Argument(ret[0], ret[1]);
}

internal Gee.List<string> read_errors(owned string line)
{
    Gee.List<string> ret = new ArrayList<string>();
    int pos = line.index_of("throws ");
    if (pos < 0) error("must be throws");
    line = line.substring(pos+7);
    string[] errs = line.split(",");
    foreach (string err in errs)
    {
        while (err.has_prefix(" ")) err = err.substring(1);
        while (err.has_suffix(" ")) err = err.substring(0, err.length-1);
        if (err == "") error("must be an exception name");
        ret.add(err);
        print(@"throws $(err)\n");
    }
    return ret;
}

public class Root : Object
{
    public Root(string rootclass, string rootname)
    {
        this.rootclass = rootclass;
        this.rootname = rootname;
        modules = new ArrayList<ModuleRemote>();
    }
    public string rootclass {get; private set;}
    public string rootname {get; private set;}
    public Gee.List<ModuleRemote> modules {get; private set;}
}

public class ModuleRemote : Object
{
    public ModuleRemote(string modclass, string modname)
    {
        this.modclass = modclass;
        this.modname = modname;
        methods = new ArrayList<Method>();
    }
    public string modclass {get; private set;}
    public string modname {get; private set;}
    public Gee.List<Method> methods {get; private set;}
}

public class Exception : Object
{
    public Exception(string errdomain)
    {
        this.errdomain = errdomain;
        errcodes = new ArrayList<string>();
    }
    public string errdomain {get; private set;}
    public Gee.List<string> errcodes {get; private set;}
}

public class Argument : Object
{
    public Argument(string argclass, string argname)
    {
        this.argclass = argclass;
        this.argname = argname;
    }
    public string argclass {get; private set;}
    public string argname {get; private set;}
}

public class Method : Object
{
    public Method()
    {
        
        args = new ArrayList<Argument>();
        errors = new ArrayList<Exception>();
        s_errors = new ArrayList<string>();
    }
    public string returntype;
    public string name;
    public Gee.List<Argument> args;
    public Gee.List<Exception> errors;
    public Gee.List<string> s_errors;
}

public string[] read_file(string path)
{
    string[] ret;
    try
    {
        string contents;
        assert(FileUtils.get_contents(path, out contents));
        ret = contents.split("\n");
    }
    catch (FileError e)
    {
        error(@"$(e.domain): $(e.code): $(e.message)");
    }
    return ret;
}

public void write_file(string path, string contents)
{
    try
    {
        assert(FileUtils.set_contents(path, contents));
    }
    catch (FileError e)
    {
        error(@"$(e.domain): $(e.code): $(e.message)");
    }
}

public string prettyformat(owned string s)
{
    if(s.has_prefix("\n"))
        return multiline(s);
    return "  " + s + "\n";
}

internal string multiline(owned string s)
{
    s = s.substring(1);
    int pos = s.last_index_of("\n");
    s = s.substring(0, pos+1);
    return s;
}

