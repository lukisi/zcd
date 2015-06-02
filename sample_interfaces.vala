/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

interfaces.rpcidl
==========================================
NodeManager node
 InfoManager info
  string get_name()
  void set_name(string name) throws AuthError, BadArgsError
  int get_year()
  bool set_year(int year)
  License get_license()
 Calculator calc
  IDocument get_root()
  Gee.List<IDocument> get_children(IDocument parent)
  void add_children(IDocument parent, Gee.List<IDocument> children)
Statistics stats
 ChildrenViewer children_viewer
  Gee.List<string> int_to_string(Gee.List<int>)
Errors
 AuthError(GENERIC)
 BadArgsError(GENERIC,NULL_NOT_ALLOWED)

==========================================
 */

using Gee;
using zcd;

namespace AppDomain
{
    public errordomain AuthError {
        GENERIC
    }

    public errordomain BadArgsError {
        GENERIC,
        NULL_NOT_ALLOWED
    }

    public class License : Object
    {
        public string name {get; set;}
    }

    public interface IDocument : Object
    {
    }

    /** ----------------------------------------------------------------------
      * Main Module: identifiers for broadcast and unicast UDP remote calls.
      * ----------------------------------------------------------------------
      */

    /** Identifies a group of nodes
      */
    public class BroadcastID : Object
    {
    }

    /** Identifies a node
      */
    public class UnicastID : Object
    {
    }
}

