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
 */

using Tasklets;
using Gee;
using zcd;

namespace AppDomain
{
    namespace ModRpc
    {
        public void init()
        {
            // Register serializable types
            typeof(HCoord).class_peek();
            //typeof(BroadcastID).class_peek();
            //typeof(UnicastID).class_peek();
        }
    }

    public errordomain NeighborhoodRequestArcError {
        NOT_SAME_NETWORK,
        TOO_MANY_ARCS,
        TWO_ARCS_ON_COLLISION_DOMAIN,
        GENERIC
    }

    /** ======================================================================
      * Remote objects' interfaces
      * ======================================================================
      */

    /** This is the interface for a root-dispatcher object
      */
    public interface IAddressManagerRootDispatcher : Object
    {
        public INeighborhoodManager neighborhood_manager {
            get {
                return this._neighborhood_manager_getter();
            }
        }
        public abstract unowned INeighborhoodManager _neighborhood_manager_getter();

        public IQspnManager qspn_manager {
            get {
                return this._qspn_manager_getter();
            }
        }
        public abstract unowned IQspnManager _qspn_manager_getter();
    }

    public interface INeighborhoodManager : Object
    {
        public abstract void here_i_am(INeighborhoodNodeID my_id, string mac, string nic_addr,
                        IZcdCallerInfo? _rpc_caller=null) /* throws ZCDError */;
        public abstract void request_arc(INeighborhoodNodeID my_id, string mac, string nic_addr,
                        IZcdCallerInfo? _rpc_caller=null) throws /* ZCDError, */ NeighborhoodRequestArcError;
    }

    public interface IQspnManager : Object
    {
        public abstract void send_etp(HCoord sample, bool is_full,
                        IZcdCallerInfo? _rpc_caller=null) /* throws ZCDError */;
    }

    /** ======================================================================
      * Serializables interfaces and classes
      * ======================================================================
      */

    public interface INeighborhoodNodeID : Object
    {
    }

    /** Hierarchical coordinates of a gnode
      * Used in module Qspn.
      */
    public class HCoord : Object
    {
        public int lvl {get; set;}
        public int pos {get; set;}
        public HCoord(int lvl, int pos)
        {
            this.lvl = lvl;
            this.pos = pos;
        }
    }

    /** ----------------------------------------------------------------------
      * Main Module: identifiers for broadcast and unicast UDP remote calls.
      * ----------------------------------------------------------------------
      */

    /** Identifies a group of nodes
      */
    public class BroadcastID : Object
    {
        public INeighborhoodNodeID? ignore_nodeid {get; set;}
        public BroadcastID(INeighborhoodNodeID? ignore_nodeid=null)
        {
            this.ignore_nodeid = ignore_nodeid;
        }
    }

    /** Identifies a node
      */
    public class UnicastID : Object
    {
        public string mac {get; set;}
        public INeighborhoodNodeID nodeid {get; set;}
        public UnicastID(string mac, INeighborhoodNodeID nodeid)
        {
            this.mac = mac;
            this.nodeid = nodeid;
        }
    }
}

