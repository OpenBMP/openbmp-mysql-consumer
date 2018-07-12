#!/usr/bin/env bash

MYSQL_CMD="mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h 127.0.0.1 openBMP"

CUR_VERSION="1.23"

if [[ -f /data/mysql/schema-version ]]; then
    source /data/mysql/schema-version
else
    SCHEMA_VERSION=""
fi

# --------------------------------------------------------------
# Version 1.20 to current version
# --------------------------------------------------------------

if [[ $SCHEMA_VERSION = "1.22" ]]; then

echo "Upgrading from $SCHEMA_VERSION to $CUR_VERSION"
$MYSQL_CMD <<UPGRADE

alter table path_attrs add column large_community_list varchar(3000) DEFAULT NULL;

drop view IF EXISTS v_routes;
CREATE  VIEW v_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified, r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits,r.isPrePolicy,r.isAdjRibIn
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
       WHERE r.isWithdrawn = False;

drop view IF EXISTS v_all_routes;
CREATE  VIEW v_all_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified,r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id);


drop view IF EXISTS v_routes_history;
CREATE VIEW v_routes_history AS
  SELECT
                rtr.name as RouterName, rtr.ip_address as RouterAddress,
	        p.name AS PeerName,
                pathlog.prefix AS Prefix,pathlog.prefix_len AS PrefixLen,
                path.origin AS Origin,path.origin_as AS Origin_AS,
                    path.med AS MED,path.local_pref AS LocalPref,path.next_hop AS NH,
                path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,
                p.peer_as AS PeerASN,  p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                pathlog.id,pathlog.timestamp AS LastModified,
               pathlog.path_attr_hash_id as path_attr_hash_id, pathlog.peer_hash_id, rtr.hash_id as router_hash_id
        FROM path_attr_log pathlog
                 STRAIGHT_JOIN path_attrs path
                                 ON (pathlog.path_attr_hash_id = path.hash_id AND
                                         pathlog.peer_hash_id = path.peer_hash_id)
                 STRAIGHT_JOIN bgp_peers p ON (pathlog.peer_hash_id = p.hash_id)
	         STRAIGHT_JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
                  ORDER BY id Desc;


drop view IF EXISTS v_routes_withdraws;
CREATE VIEW v_routes_withdraws AS
SELECT  rtr.name as RouterName, rtr.ip_address as RouterAddress,
	p.name AS PeerName,
        log.prefix AS Prefix,log.prefix_len AS PrefixLen,
        path.origin AS Origin,path.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
        path.next_hop AS NH,path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,
        path.community_list AS Communities,
        path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
        path.cluster_list AS ClusterList,
        path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
        p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,log.id AS id,log.timestamp AS LastModified,
        log.path_attr_hash_id AS path_attr_hash_id,log.peer_hash_id AS peer_hash_id,rtr.hash_id AS router_hash_id
    FROM withdrawn_log log
         STRAIGHT_JOIN path_attrs path ON (path.hash_id = log.path_attr_hash_id and path.peer_hash_id = log.peer_hash_id)
         STRAIGHT_JOIN bgp_peers p ON (log.peer_hash_id = p.hash_id)
         LEFT JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
    ORDER BY log.timestamp desc;

drop view IF EXISTS v_l3vpn_routes;
CREATE VIEW v_l3vpn_routes AS
	select if((length(rtr.name) > 0),rtr.name,rtr.ip_address) AS RouterName,
	if((length(p.name) > 0),p.name,p.peer_addr) AS PeerName,
 	r.rd AS RD,r.prefix AS Prefix,r.prefix_len AS PrefixLen,path.origin AS Origin,
 	r.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
 	path.next_hop AS NH,path.as_path AS AS_Path,
	path.as_path_count AS ASPath_Count,path.community_list AS Communities,
	path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
  path.cluster_list AS ClusterList,
	path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
	r.isIPv4 AS isIPv4,p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,
	r.timestamp AS LastModified,r.first_added_timestamp AS FirstAddedTimestamp,
	r.prefix_bin AS prefix_bin,r.path_id AS path_id,r.labels AS labels,r.hash_id AS rib_hash_id,
	r.path_attr_hash_id AS path_hash_id,r.peer_hash_id AS peer_hash_id,
	rtr.hash_id AS router_hash_id,r.isWithdrawn AS isWithdrawn,
	r.prefix_bits AS prefix_bits,r.isPrePolicy AS isPrePolicy,r.isAdjRibIn AS isAdjRibIn
     from bgp_peers p
               join l3vpn_rib r on (r.peer_hash_id = p.hash_id)
	    join path_attrs path on (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
              join routers rtr on (p.router_hash_id = rtr.hash_id)
      where  r.isWithdrawn = 0;


UPGRADE


# --------------------------------------------------------------
# Version 1.20 to current version
# --------------------------------------------------------------

elif [[ $SCHEMA_VERSION = "1.20" ||  $SCHEMA_VERSION = "1.21" ]]; then

echo "Upgrading from $SCHEMA_VERSION to $CUR_VERSION"
$MYSQL_CMD <<UPGRADE

alter table path_attrs add column large_community_list varchar(3000) DEFAULT NULL;

drop view IF EXISTS v_routes;
CREATE  VIEW v_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified, r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits,r.isPrePolicy,r.isAdjRibIn
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
       WHERE r.isWithdrawn = False;

drop view IF EXISTS v_all_routes;
CREATE  VIEW v_all_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified,r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id);


drop view IF EXISTS v_routes_history;
CREATE VIEW v_routes_history AS
  SELECT
                rtr.name as RouterName, rtr.ip_address as RouterAddress,
	        p.name AS PeerName,
                pathlog.prefix AS Prefix,pathlog.prefix_len AS PrefixLen,
                path.origin AS Origin,path.origin_as AS Origin_AS,
                    path.med AS MED,path.local_pref AS LocalPref,path.next_hop AS NH,
                path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,
                p.peer_as AS PeerASN,  p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                pathlog.id,pathlog.timestamp AS LastModified,
               pathlog.path_attr_hash_id as path_attr_hash_id, pathlog.peer_hash_id, rtr.hash_id as router_hash_id
        FROM path_attr_log pathlog
                 STRAIGHT_JOIN path_attrs path
                                 ON (pathlog.path_attr_hash_id = path.hash_id AND
                                         pathlog.peer_hash_id = path.peer_hash_id)
                 STRAIGHT_JOIN bgp_peers p ON (pathlog.peer_hash_id = p.hash_id)
	         STRAIGHT_JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
                  ORDER BY id Desc;


drop view IF EXISTS v_routes_withdraws;
CREATE VIEW v_routes_withdraws AS
SELECT  rtr.name as RouterName, rtr.ip_address as RouterAddress,
	p.name AS PeerName,
        log.prefix AS Prefix,log.prefix_len AS PrefixLen,
        path.origin AS Origin,path.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
        path.next_hop AS NH,path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,
        path.community_list AS Communities,
        path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
        path.cluster_list AS ClusterList,
        path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
        p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,log.id AS id,log.timestamp AS LastModified,
        log.path_attr_hash_id AS path_attr_hash_id,log.peer_hash_id AS peer_hash_id,rtr.hash_id AS router_hash_id
    FROM withdrawn_log log
         STRAIGHT_JOIN path_attrs path ON (path.hash_id = log.path_attr_hash_id and path.peer_hash_id = log.peer_hash_id)
         STRAIGHT_JOIN bgp_peers p ON (log.peer_hash_id = p.hash_id)
         LEFT JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
    ORDER BY log.timestamp desc;

drop view IF EXISTS v_l3vpn_routes;
CREATE VIEW v_l3vpn_routes AS
	select if((length(rtr.name) > 0),rtr.name,rtr.ip_address) AS RouterName,
	if((length(p.name) > 0),p.name,p.peer_addr) AS PeerName,
 	r.rd AS RD,r.prefix AS Prefix,r.prefix_len AS PrefixLen,path.origin AS Origin,
 	r.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
 	path.next_hop AS NH,path.as_path AS AS_Path,
	path.as_path_count AS ASPath_Count,path.community_list AS Communities,
	path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
  path.cluster_list AS ClusterList,
	path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
	r.isIPv4 AS isIPv4,p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,
	r.timestamp AS LastModified,r.first_added_timestamp AS FirstAddedTimestamp,
	r.prefix_bin AS prefix_bin,r.path_id AS path_id,r.labels AS labels,r.hash_id AS rib_hash_id,
	r.path_attr_hash_id AS path_hash_id,r.peer_hash_id AS peer_hash_id,
	rtr.hash_id AS router_hash_id,r.isWithdrawn AS isWithdrawn,
	r.prefix_bits AS prefix_bits,r.isPrePolicy AS isPrePolicy,r.isAdjRibIn AS isAdjRibIn
     from bgp_peers p
               join l3vpn_rib r on (r.peer_hash_id = p.hash_id)
	    join path_attrs path on (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
              join routers rtr on (p.router_hash_id = rtr.hash_id)
      where  r.isWithdrawn = 0;

DROP TABLE IF EXISTS as_path_analysis;
CREATE TABLE as_path_analysis (
  asn int(10) unsigned NOT NULL,
  asn_left int(10) unsigned NOT NULL DEFAULT 0,
  asn_right int(10) unsigned NOT NULL DEFAULT 0,
  asn_left_is_peering tinyint DEFAULT 0,
  timestamp datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (asn,asn_left_is_peering,asn_left,asn_right),
  KEY idx_asn_left (asn_left),
  KEY idx_asn_right (asn_right),
  KEY idx_ts (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
    PARTITION BY KEY (asn)
    PARTITIONS 48;

 alter table gen_asn_stats add index idx_ts (timestamp);
 alter table gen_prefix_validation remove partitioning;
 alter table gen_prefix_validation engine=innodb;


UPGRADE


# --------------------------------------------------------------
# Version 1.19 to current version
# --------------------------------------------------------------

elif [[ $SCHEMA_VERSION = "1.19" ]]; then

echo "Upgrading from 1.19 to $CUR_VERSION"
$MYSQL_CMD <<UPGRADE
alter table path_attrs add column large_community_list varchar(3000) DEFAULT NULL;

drop view IF EXISTS v_routes;
CREATE  VIEW v_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified, r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits,r.isPrePolicy,r.isAdjRibIn
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
       WHERE r.isWithdrawn = False;

drop view IF EXISTS v_all_routes;
CREATE  VIEW v_all_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified,r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id);


drop view IF EXISTS v_routes_history;
CREATE VIEW v_routes_history AS
  SELECT
                rtr.name as RouterName, rtr.ip_address as RouterAddress,
	        p.name AS PeerName,
                pathlog.prefix AS Prefix,pathlog.prefix_len AS PrefixLen,
                path.origin AS Origin,path.origin_as AS Origin_AS,
                    path.med AS MED,path.local_pref AS LocalPref,path.next_hop AS NH,
                path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,
                p.peer_as AS PeerASN,  p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                pathlog.id,pathlog.timestamp AS LastModified,
               pathlog.path_attr_hash_id as path_attr_hash_id, pathlog.peer_hash_id, rtr.hash_id as router_hash_id
        FROM path_attr_log pathlog
                 STRAIGHT_JOIN path_attrs path
                                 ON (pathlog.path_attr_hash_id = path.hash_id AND
                                         pathlog.peer_hash_id = path.peer_hash_id)
                 STRAIGHT_JOIN bgp_peers p ON (pathlog.peer_hash_id = p.hash_id)
	         STRAIGHT_JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
                  ORDER BY id Desc;


drop view IF EXISTS v_routes_withdraws;
CREATE VIEW v_routes_withdraws AS
SELECT  rtr.name as RouterName, rtr.ip_address as RouterAddress,
	p.name AS PeerName,
        log.prefix AS Prefix,log.prefix_len AS PrefixLen,
        path.origin AS Origin,path.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
        path.next_hop AS NH,path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,
        path.community_list AS Communities,
        path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
        path.cluster_list AS ClusterList,
        path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
        p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,log.id AS id,log.timestamp AS LastModified,
        log.path_attr_hash_id AS path_attr_hash_id,log.peer_hash_id AS peer_hash_id,rtr.hash_id AS router_hash_id
    FROM withdrawn_log log
         STRAIGHT_JOIN path_attrs path ON (path.hash_id = log.path_attr_hash_id and path.peer_hash_id = log.peer_hash_id)
         STRAIGHT_JOIN bgp_peers p ON (log.peer_hash_id = p.hash_id)
         LEFT JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
    ORDER BY log.timestamp desc;

drop view IF EXISTS v_l3vpn_routes;
CREATE VIEW v_l3vpn_routes AS
	select if((length(rtr.name) > 0),rtr.name,rtr.ip_address) AS RouterName,
	if((length(p.name) > 0),p.name,p.peer_addr) AS PeerName,
 	r.rd AS RD,r.prefix AS Prefix,r.prefix_len AS PrefixLen,path.origin AS Origin,
 	r.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
 	path.next_hop AS NH,path.as_path AS AS_Path,
	path.as_path_count AS ASPath_Count,path.community_list AS Communities,
	path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
  path.cluster_list AS ClusterList,
	path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
	r.isIPv4 AS isIPv4,p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,
	r.timestamp AS LastModified,r.first_added_timestamp AS FirstAddedTimestamp,
	r.prefix_bin AS prefix_bin,r.path_id AS path_id,r.labels AS labels,r.hash_id AS rib_hash_id,
	r.path_attr_hash_id AS path_hash_id,r.peer_hash_id AS peer_hash_id,
	rtr.hash_id AS router_hash_id,r.isWithdrawn AS isWithdrawn,
	r.prefix_bits AS prefix_bits,r.isPrePolicy AS isPrePolicy,r.isAdjRibIn AS isAdjRibIn
     from bgp_peers p
               join l3vpn_rib r on (r.peer_hash_id = p.hash_id)
	    join path_attrs path on (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
              join routers rtr on (p.router_hash_id = rtr.hash_id)
      where  r.isWithdrawn = 0;

  DROP trigger IF EXISTS upd_as_path_analysis;

DROP TABLE IF EXISTS as_path_analysis;
CREATE TABLE as_path_analysis (
  asn int(10) unsigned NOT NULL,
  asn_left int(10) unsigned NOT NULL DEFAULT 0,
  asn_right int(10) unsigned NOT NULL DEFAULT 0,
  path_attr_hash_id char(32) NOT NULL,
  timestamp datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (path_attr_hash,asn),
  KEY idx_asn_left (asn_left),
  KEY idx_asn_right (asn_right),
  KEY idx_asn (asn),
  KEY idx_ts (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
    PARTITION BY KEY (path_attr_hash_id)
    PARTITIONS 48;

  ALTER TABLE gen_chg_stats_byprefix ROW_FORMAT=compressed KEY_BLOCK_SIZE=4;

  alter table withdrawn_log add index idx_origin (origin_as);
UPGRADE

# --------------------------------------------------------------
# Version 1.18 to current version
# --------------------------------------------------------------
elif [[ $SCHEMA_VERSION = "1.18" ]]; then

echo "Upgrading from 1.18 to $CUR_VERSION"
$MYSQL_CMD <<UPGRADE
alter table path_attrs add column large_community_list varchar(3000) DEFAULT NULL;

drop view IF EXISTS v_routes;
CREATE  VIEW v_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified, r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits,r.isPrePolicy,r.isAdjRibIn
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
       WHERE r.isWithdrawn = False;

drop view IF EXISTS v_all_routes;
CREATE  VIEW v_all_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified,r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id);


drop view IF EXISTS v_routes_history;
CREATE VIEW v_routes_history AS
  SELECT
                rtr.name as RouterName, rtr.ip_address as RouterAddress,
	        p.name AS PeerName,
                pathlog.prefix AS Prefix,pathlog.prefix_len AS PrefixLen,
                path.origin AS Origin,path.origin_as AS Origin_AS,
                    path.med AS MED,path.local_pref AS LocalPref,path.next_hop AS NH,
                path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,
                p.peer_as AS PeerASN,  p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                pathlog.id,pathlog.timestamp AS LastModified,
               pathlog.path_attr_hash_id as path_attr_hash_id, pathlog.peer_hash_id, rtr.hash_id as router_hash_id
        FROM path_attr_log pathlog
                 STRAIGHT_JOIN path_attrs path
                                 ON (pathlog.path_attr_hash_id = path.hash_id AND
                                         pathlog.peer_hash_id = path.peer_hash_id)
                 STRAIGHT_JOIN bgp_peers p ON (pathlog.peer_hash_id = p.hash_id)
	         STRAIGHT_JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
                  ORDER BY id Desc;


drop view IF EXISTS v_routes_withdraws;
CREATE VIEW v_routes_withdraws AS
SELECT  rtr.name as RouterName, rtr.ip_address as RouterAddress,
	p.name AS PeerName,
        log.prefix AS Prefix,log.prefix_len AS PrefixLen,
        path.origin AS Origin,path.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
        path.next_hop AS NH,path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,
        path.community_list AS Communities,
        path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
        path.cluster_list AS ClusterList,
        path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
        p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,log.id AS id,log.timestamp AS LastModified,
        log.path_attr_hash_id AS path_attr_hash_id,log.peer_hash_id AS peer_hash_id,rtr.hash_id AS router_hash_id
    FROM withdrawn_log log
         STRAIGHT_JOIN path_attrs path ON (path.hash_id = log.path_attr_hash_id and path.peer_hash_id = log.peer_hash_id)
         STRAIGHT_JOIN bgp_peers p ON (log.peer_hash_id = p.hash_id)
         LEFT JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
    ORDER BY log.timestamp desc;

drop view IF EXISTS v_l3vpn_routes;
CREATE VIEW v_l3vpn_routes AS
	select if((length(rtr.name) > 0),rtr.name,rtr.ip_address) AS RouterName,
	if((length(p.name) > 0),p.name,p.peer_addr) AS PeerName,
 	r.rd AS RD,r.prefix AS Prefix,r.prefix_len AS PrefixLen,path.origin AS Origin,
 	r.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
 	path.next_hop AS NH,path.as_path AS AS_Path,
	path.as_path_count AS ASPath_Count,path.community_list AS Communities,
	path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
  path.cluster_list AS ClusterList,
	path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
	r.isIPv4 AS isIPv4,p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,
	r.timestamp AS LastModified,r.first_added_timestamp AS FirstAddedTimestamp,
	r.prefix_bin AS prefix_bin,r.path_id AS path_id,r.labels AS labels,r.hash_id AS rib_hash_id,
	r.path_attr_hash_id AS path_hash_id,r.peer_hash_id AS peer_hash_id,
	rtr.hash_id AS router_hash_id,r.isWithdrawn AS isWithdrawn,
	r.prefix_bits AS prefix_bits,r.isPrePolicy AS isPrePolicy,r.isAdjRibIn AS isAdjRibIn
     from bgp_peers p
               join l3vpn_rib r on (r.peer_hash_id = p.hash_id)
	    join path_attrs path on (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
              join routers rtr on (p.router_hash_id = rtr.hash_id)
      where  r.isWithdrawn = 0;

drop event IF EXISTS chg_stats_bypeer;
CREATE EVENT chg_stats_bypeer
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_bypeer (interval_time, peer_hash_id, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id);

drop event IF EXISTS chg_stats_byprefix;
CREATE EVENT chg_stats_byprefix
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_byprefix (interval_time, peer_hash_id, prefix, prefix_len, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.prefix is null, w.prefix, c.prefix) as prefix,
              if (c.prefix is null, w.prefix_len, c.prefix_len) as prefix_len,
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, prefix, prefix_len, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id,prefix,prefix_len) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, prefix, prefix_len, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id,prefix,prefix_len) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id
                AND c.prefix = w.prefix and c.prefix_len = w.prefix_len);

drop event IF EXISTS chg_stats_byasn;
CREATE EVENT chg_stats_byasn
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_byasn (interval_time, peer_hash_id,origin_as, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.origin_as is null, w.origin_as, c.origin_as),
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, origin_as, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id,origin_as) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, origin_as, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id,origin_as) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id
                and c.origin_as = w.origin_as);

    DROP trigger IF EXISTS upd_as_path_analysis;

DROP TABLE IF EXISTS as_path_analysis;
CREATE TABLE as_path_analysis (
  asn int(10) unsigned NOT NULL,
  asn_left int(10) unsigned NOT NULL DEFAULT 0,
  asn_right int(10) unsigned NOT NULL DEFAULT 0,
  path_attr_hash_id char(32) NOT NULL,
  timestamp datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (path_attr_hash,asn),
  KEY idx_asn_left (asn_left),
  KEY idx_asn_right (asn_right),
  KEY idx_asn (asn),
  KEY idx_ts (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
    PARTITION BY KEY (path_attr_hash_id)
    PARTITIONS 48;


  ALTER TABLE gen_chg_stats_byprefix ROW_FORMAT=compressed KEY_BLOCK_SIZE=4;

UPGRADE

else
# --------------------------------------------------------------
# Version 1.17 to current version
# --------------------------------------------------------------
echo "Upgrading from 1.17 to $CUR_VERSION"

$MYSQL_CMD <<UPGRADE
alter table path_attrs add column large_community_list varchar(3000) DEFAULT NULL;

drop view IF EXISTS v_routes;
CREATE  VIEW v_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified, r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits,r.isPrePolicy,r.isAdjRibIn
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
       WHERE r.isWithdrawn = False;

drop view IF EXISTS v_all_routes;
CREATE  VIEW v_all_routes AS
       SELECT  if (length(rtr.name) > 0, rtr.name, rtr.ip_address) AS RouterName,
                if(length(p.name) > 0, p.name, p.peer_addr) AS PeerName,
                r.prefix AS Prefix,r.prefix_len AS PrefixLen,
                path.origin AS Origin,r.origin_as AS Origin_AS,path.med AS MED,
                path.local_pref AS LocalPref,path.next_hop AS NH,path.as_path AS AS_Path,
                path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,
                path.aggregator AS Aggregator,p.peer_addr AS PeerAddress, p.peer_as AS PeerASN,r.isIPv4 as isIPv4,
                p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                r.timestamp AS LastModified,r.first_added_timestamp as FirstAddedTimestamp,r.prefix_bin as prefix_bin,
                r.path_id, r.labels,
                r.hash_id as rib_hash_id,
                r.path_attr_hash_id as path_hash_id, r.peer_hash_id, rtr.hash_id as router_hash_id,r.isWithdrawn,
                r.prefix_bits
        FROM bgp_peers p JOIN rib r ON (r.peer_hash_id = p.hash_id)
            JOIN path_attrs path ON (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
            JOIN routers rtr ON (p.router_hash_id = rtr.hash_id);


drop view IF EXISTS v_routes_history;
CREATE VIEW v_routes_history AS
  SELECT
                rtr.name as RouterName, rtr.ip_address as RouterAddress,
	        p.name AS PeerName,
                pathlog.prefix AS Prefix,pathlog.prefix_len AS PrefixLen,
                path.origin AS Origin,path.origin_as AS Origin_AS,
                    path.med AS MED,path.local_pref AS LocalPref,path.next_hop AS NH,
                path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,path.community_list AS Communities,
                path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
                path.cluster_list AS ClusterList,path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,
                p.peer_as AS PeerASN,  p.isIPv4 as isPeerIPv4, p.isL3VPNpeer as isPeerVPN,
                pathlog.id,pathlog.timestamp AS LastModified,
               pathlog.path_attr_hash_id as path_attr_hash_id, pathlog.peer_hash_id, rtr.hash_id as router_hash_id
        FROM path_attr_log pathlog
                 STRAIGHT_JOIN path_attrs path
                                 ON (pathlog.path_attr_hash_id = path.hash_id AND
                                         pathlog.peer_hash_id = path.peer_hash_id)
                 STRAIGHT_JOIN bgp_peers p ON (pathlog.peer_hash_id = p.hash_id)
	         STRAIGHT_JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
                  ORDER BY id Desc;


drop view IF EXISTS v_routes_withdraws;
CREATE VIEW v_routes_withdraws AS
SELECT  rtr.name as RouterName, rtr.ip_address as RouterAddress,
	p.name AS PeerName,
        log.prefix AS Prefix,log.prefix_len AS PrefixLen,
        path.origin AS Origin,path.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
        path.next_hop AS NH,path.as_path AS AS_Path,path.as_path_count AS ASPath_Count,
        path.community_list AS Communities,
        path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
        path.cluster_list AS ClusterList,
        path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
        p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,log.id AS id,log.timestamp AS LastModified,
        log.path_attr_hash_id AS path_attr_hash_id,log.peer_hash_id AS peer_hash_id,rtr.hash_id AS router_hash_id
    FROM withdrawn_log log
         STRAIGHT_JOIN path_attrs path ON (path.hash_id = log.path_attr_hash_id and path.peer_hash_id = log.peer_hash_id)
         STRAIGHT_JOIN bgp_peers p ON (log.peer_hash_id = p.hash_id)
         LEFT JOIN routers rtr ON (p.router_hash_id = rtr.hash_id)
    ORDER BY log.timestamp desc;

drop view IF EXISTS v_l3vpn_routes;
CREATE VIEW v_l3vpn_routes AS
	select if((length(rtr.name) > 0),rtr.name,rtr.ip_address) AS RouterName,
	if((length(p.name) > 0),p.name,p.peer_addr) AS PeerName,
 	r.rd AS RD,r.prefix AS Prefix,r.prefix_len AS PrefixLen,path.origin AS Origin,
 	r.origin_as AS Origin_AS,path.med AS MED,path.local_pref AS LocalPref,
 	path.next_hop AS NH,path.as_path AS AS_Path,
	path.as_path_count AS ASPath_Count,path.community_list AS Communities,
	path.ext_community_list AS ExtCommunities,path.large_community_list AS LargeCommunities,
  path.cluster_list AS ClusterList,
	path.aggregator AS Aggregator,p.peer_addr AS PeerAddress,p.peer_as AS PeerASN,
	r.isIPv4 AS isIPv4,p.isIPv4 AS isPeerIPv4,p.isL3VPNpeer AS isPeerVPN,
	r.timestamp AS LastModified,r.first_added_timestamp AS FirstAddedTimestamp,
	r.prefix_bin AS prefix_bin,r.path_id AS path_id,r.labels AS labels,r.hash_id AS rib_hash_id,
	r.path_attr_hash_id AS path_hash_id,r.peer_hash_id AS peer_hash_id,
	rtr.hash_id AS router_hash_id,r.isWithdrawn AS isWithdrawn,
	r.prefix_bits AS prefix_bits,r.isPrePolicy AS isPrePolicy,r.isAdjRibIn AS isAdjRibIn
     from bgp_peers p
               join l3vpn_rib r on (r.peer_hash_id = p.hash_id)
	    join path_attrs path on (path.hash_id = r.path_attr_hash_id and path.peer_hash_id = r.peer_hash_id)
              join routers rtr on (p.router_hash_id = rtr.hash_id)
      where  r.isWithdrawn = 0;

# Fix bgp_ls node issue where nodes were being suppressed
drop view v_ls_nodes;
CREATE VIEW v_ls_nodes AS
SELECT r.name as RouterName,r.ip_address as RouterIP,
       p.name as PeerName, p.peer_addr as PeerIP,igp_router_id as IGP_RouterId,
    ls_nodes.name as NodeName,
         if (ls_nodes.protocol like 'OSPF%', igp_router_id, router_id) as RouterId,
         ls_nodes.id, ls_nodes.bgp_ls_id as bgpls_id, ls_nodes.ospf_area_id as OspfAreaId,
         ls_nodes.isis_area_id as ISISAreaId, ls_nodes.protocol, flags, ls_nodes.timestamp,
         ls_nodes.asn,path_attrs.as_path as AS_Path,path_attrs.local_pref as LocalPref,
         path_attrs.med as MED,path_attrs.next_hop as NH,links.mt_id,
         ls_nodes.hash_id,ls_nodes.path_attr_hash_id,ls_nodes.peer_hash_id,r.hash_id as router_hash_id
      FROM ls_nodes LEFT JOIN path_attrs ON (ls_nodes.path_attr_hash_id = path_attrs.hash_id AND ls_nodes.peer_hash_id = path_attrs.peer_hash_id)
        JOIN ls_links links ON (ls_nodes.hash_id = links.local_node_hash_id and links.isWithdrawn = False)
            JOIN bgp_peers p on (p.hash_id = ls_nodes.peer_hash_id) JOIN
                             routers r on (p.router_hash_id = r.hash_id)
         WHERE not ls_nodes.igp_router_id regexp "\..[1-9A-F]00$" AND ls_nodes.igp_router_id not like "%]" and ls_nodes.iswithdrawn = False
    GROUP BY ls_nodes.peer_hash_id,ls_nodes.hash_id,links.mt_id;



# Update as path analysis to be more efficent
DROP TABLE IF EXISTS as_path_analysis;
CREATE TABLE as_path_analysis (
  asn int(10) unsigned NOT NULL,
  asn_left int(10) unsigned NOT NULL DEFAULT 0,
  asn_right int(10) unsigned NOT NULL DEFAULT 0,
  path_attr_hash_id char(32) NOT NULL,
  timestamp datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (path_attr_hash,asn),
  KEY idx_asn_left (asn_left),
  KEY idx_asn_right (asn_right),
  KEY idx_asn (asn),
  KEY idx_ts (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
    PARTITION BY KEY (path_attr_hash_id)
    PARTITIONS 48;

DROP trigger IF EXISTS upd_as_path_analysis;
DROP trigger IF EXISTS ins_as_path_analysis;
delimiter /
CREATE TRIGGER ins_as_path_analysis BEFORE INSERT ON as_path_analysis
FOR EACH ROW
    BEGIN
        IF (new.asn = 0 AND new.isWithdrawn = 1) THEN
            UPDATE as_path_analysis SET isWithdrawn = 1 WHERE rib_hash_id = new.rib_hash_id and asn != 0;
            SET new.rib_hash_id = null;
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'NoError, prefixes set to withdrawn state';
        END IF;

    END/
delimiter ;

# Added prefix_bits, idx_prefix_bits and engine to InnodB with partitions
drop table IF EXISTS gen_prefix_validation;
CREATE TABLE gen_prefix_validation (
  prefix varbinary(16) NOT NULL,
  isIPv4 tinyint(4) NOT NULL,
  prefix_len tinyint(3) unsigned NOT NULL DEFAULT '0',
  recv_origin_as int(10) unsigned NOT NULL,
  rpki_origin_as int(10) unsigned DEFAULT NULL,
  irr_origin_as int(10) unsigned DEFAULT NULL,
  irr_source varchar(32) DEFAULT NULL,
  timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  prefix_bits varchar(128) NOT NULL,
  PRIMARY KEY (prefix,prefix_len,recv_origin_as),
  KEY idx_origin (recv_origin_as) USING HASH,
  KEY idx_prefix (prefix) USING BTREE,
  KEY idx_prefix_full (prefix,prefix_len) USING HASH,
  KEY idx_prefix_bits (prefix_bits) USING BTREE
) ENGINE=Innodb DEFAULT CHARSET=latin1 KEY_BLOCK_SIZE=4 ROW_FORMAT=COMPRESSED
PARTITION BY HASH (prefix_len)
PARTITIONS 24;

# Below adds an update to the first_added_timestamp if the time is too old (refreshes the first_added_timestamp)
drop trigger rib_pre_update;
delimiter //
CREATE TRIGGER rib_pre_update BEFORE UPDATE on rib
  FOR EACH ROW
  BEGIN
      # Allow per session disabling of trigger (set @TRIGGER_DISABLED=TRUE to disable, set @TRIGGER_DISABLED=FALSE to enable)
      IF ( @TRIGGER_DISABLED is null OR @TRIGGER_DISABLED = FALSE ) THEN
           # Update gen_prefix_validation table (RPKI/IRR)
           IF (new.origin_as > 0 AND new.origin_as != 23456 AND old.isWithdrawn = True AND new.isWithdrawn = True) THEN
                     INSERT IGNORE INTO gen_prefix_validation (prefix,prefix_len,recv_origin_as,rpki_origin_as,irr_origin_as,irr_source,prefix_bits,isIPv4)

                          SELECT SQL_SMALL_RESULT new.prefix_bin,new.prefix_len,new.origin_as,
                                                       rpki.origin_as, w.origin_as,w.source,new.prefix_bits,new.isIPv4
                                   FROM (SELECT new.prefix_bin as prefix_bin, new.prefix_len as prefix_len, new.origin_as as origin_as, new.prefix_bits,
                                                     new.isIPv4) rib
                                             LEFT JOIN gen_whois_route w ON (new.prefix_bin = w.prefix AND
                                                        new.prefix_len = w.prefix_len)
                                             LEFT JOIN rpki_validator rpki ON (new.prefix_bin = rpki.prefix AND
                                                        new.prefix_len >= rpki.prefix_len and new.prefix_len <= rpki.prefix_len_max)

                           ON DUPLICATE KEY UPDATE rpki_origin_as = values(rpki_origin_as),
                                                                       irr_origin_as=values(irr_origin_as),irr_source=values(irr_source);
        END IF;


        # Make sure we are updating a duplicate
        IF (new.hash_id = old.hash_id AND new.peer_hash_id = old.peer_hash_id) THEN
            IF (new.isWithdrawn = False) THEN
              IF (old.path_attr_hash_id != new.path_attr_hash_id AND old.path_attr_hash_id != '') THEN
                   # Add path log if the path has changed
                    INSERT IGNORE INTO path_attr_log (prefix,prefix_len,path_attr_hash_id,peer_hash_id,origin_as,timestamp)
                                VALUES (old.prefix,old.prefix_len,old.path_attr_hash_id,old.peer_hash_id,old.origin_as,
                                        old.timestamp);

              END IF;

              # Update first_added_timestamp if withdrawn for a long timestamp
              IF (old.isWithdrawn = True AND old.timestamp < date_sub(new.timestamp, INTERVAL 6 HOUR)) THEN
                  SET new.first_added_timestamp = current_timestamp(6);
              END IF;

            ELSE
               # Add log entry for withdrawn prefix
                INSERT IGNORE INTO withdrawn_log
                        (prefix,prefix_len,peer_hash_id,path_attr_hash_id,origin_as,timestamp)
                            VALUES (old.prefix,old.prefix_len,old.peer_hash_id,
                                    old.path_attr_hash_id,old.origin_as,new.timestamp);
            END IF;

        END IF;
      END IF;
  END;//
delimiter ;


# Add stats for changes
drop table if exists gen_chg_stats_bypeer;
create table gen_chg_stats_bypeer (
    interval_time datetime(6) NOT NULL,
    peer_hash_id char(32) NOT NULL,
    updates int unsigned not null default 0,
    withdraws int unsigned not null default 0,
    PRIMARY KEY (interval_time, peer_hash_id),
    KEY idx_interval (interval_time),
    KEY idx_peer_hash_id (peer_hash_id)
) Engine=Innodb CHARSET=latin1
  PARTITION BY RANGE COLUMNS(interval_time)
  (PARTITION p2017_10 VALUES LESS THAN ('2017-11-01') ENGINE = InnoDB,
  PARTITION p2017_11 VALUES LESS THAN ('2017-12-01') ENGINE = InnoDB,
  PARTITION p2017_12 VALUES LESS THAN ('2018-01-01') ENGINE = InnoDB,
  PARTITION p2018_01 VALUES LESS THAN ('2018-02-01') ENGINE = InnoDB,
  PARTITION p2018_02 VALUES LESS THAN ('2018-03-01') ENGINE = InnoDB,
  PARTITION p2018_03 VALUES LESS THAN ('2018-04-01') ENGINE = InnoDB,
  PARTITION p2018_04 VALUES LESS THAN ('2018-05-01') ENGINE = InnoDB,
  PARTITION pOther VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB);

drop event chg_stats_bypeer;
CREATE EVENT chg_stats_bypeer
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_bypeer (interval_time, peer_hash_id, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id);

drop table if exists gen_chg_stats_byprefix;
create table gen_chg_stats_byprefix (
    interval_time datetime(6) NOT NULL,
    peer_hash_id char(32) NOT NULL,
    prefix varchar(46) NOT NULL,
    prefix_len tinyint unsigned NOT NULL,
    updates int unsigned not null default 0,
    withdraws int unsigned not null default 0,
    PRIMARY KEY (interval_time, peer_hash_id, prefix,prefix_len),
    KEY idx_interval (interval_time),
    KEY idx_peer_hash_id (peer_hash_id),
    KEY idx_prefix_full (prefix,prefix_len)
) Engine=Innodb CHARSET=latin1 KEY_BLOCK_SIZE=4 ROW_FORMAT=COMPRESSED
  PARTITION BY RANGE COLUMNS(interval_time)
  (PARTITION p2017_10 VALUES LESS THAN ('2017-11-01') ENGINE = InnoDB,
  PARTITION p2017_11 VALUES LESS THAN ('2017-12-01') ENGINE = InnoDB,
  PARTITION p2017_12 VALUES LESS THAN ('2018-01-01') ENGINE = InnoDB,
  PARTITION p2018_01 VALUES LESS THAN ('2018-02-01') ENGINE = InnoDB,
  PARTITION p2018_02 VALUES LESS THAN ('2018-03-01') ENGINE = InnoDB,
  PARTITION p2018_03 VALUES LESS THAN ('2018-04-01') ENGINE = InnoDB,
  PARTITION p2018_04 VALUES LESS THAN ('2018-05-01') ENGINE = InnoDB,
  PARTITION pOther VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB);

drop event chg_stats_byprefix;
CREATE EVENT chg_stats_byprefix
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_byprefix (interval_time, peer_hash_id, prefix, prefix_len, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.prefix is null, w.prefix, c.prefix) as prefix,
              if (c.prefix is null, w.prefix_len, c.prefix_len) as prefix_len,
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, prefix, prefix_len, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id,prefix,prefix_len) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, prefix, prefix_len, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id,prefix,prefix_len) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id
                AND c.prefix = w.prefix and c.prefix_len = w.prefix_len);

drop table if exists gen_chg_stats_byasn;
create table gen_chg_stats_byasn (
    interval_time datetime(6) NOT NULL,
    peer_hash_id char(32) NOT NULL,
    origin_as int unsigned not null,
    updates int unsigned not null default 0,
    withdraws int unsigned not null default 0,
    PRIMARY KEY (interval_time, peer_hash_id, origin_as),
    KEY idx_interval (interval_time),
    KEY idx_peer_hash_id (peer_hash_id),
    KEY idx_origin_as (origin_as)
) Engine=Innodb CHARSET=latin1
  PARTITION BY RANGE  COLUMNS(interval_time)
  (PARTITION p2017_10 VALUES LESS THAN ('2017-11-01') ENGINE = InnoDB,
  PARTITION p2017_11 VALUES LESS THAN ('2017-12-01') ENGINE = InnoDB,
  PARTITION p2017_12 VALUES LESS THAN ('2018-01-01') ENGINE = InnoDB,
  PARTITION p2018_01 VALUES LESS THAN ('2018-02-01') ENGINE = InnoDB,
  PARTITION p2018_02 VALUES LESS THAN ('2018-03-01') ENGINE = InnoDB,
  PARTITION p2018_03 VALUES LESS THAN ('2018-04-01') ENGINE = InnoDB,
  PARTITION p2018_04 VALUES LESS THAN ('2018-05-01') ENGINE = InnoDB,
  PARTITION pOther VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB);

drop event chg_stats_byasn;
CREATE EVENT chg_stats_byasn
  ON SCHEDULE EVERY 5 MINUTE
  DO
      # Count updates and withdraws by interval
      REPLACE INTO gen_chg_stats_byasn (interval_time, peer_hash_id,origin_as, updates,withdraws)
        SELECT c.IntervalTime,if (c.peer_hash_id is null, w.peer_hash_id, c.peer_hash_id) as peer_hash_id,
              if (c.origin_as is null, w.origin_as, c.origin_as),
              if (c.updates is null, 0, c.updates) as updates,
              if (w.withdraws is null, 0, w.withdraws) as withdraws
          FROM
            (SELECT
                from_unixtime(unix_timestamp(c.timestamp) - unix_timestamp(c.timestamp) % 60.0) AS IntervalTime,
                peer_hash_id, origin_as, count(c.peer_hash_id) as updates
              FROM path_attr_log c
              WHERE c.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                    AND c.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
              GROUP BY IntervalTime,c.peer_hash_id,origin_as) c

           LEFT JOIN
               (SELECT
                  from_unixtime(unix_timestamp(w.timestamp) - unix_timestamp(w.timestamp) % 60.0) AS IntervalTime,
                  peer_hash_id, origin_as, count(w.peer_hash_id) as withdraws
                FROM withdrawn_log w
                WHERE w.timestamp >= date_format(date_sub(current_timestamp, INTERVAL 25 MINUTE), "%Y-%m-%d %H:%i:00")
                      AND w.timestamp <= date_format(current_timestamp, "%Y-%m-%d %H:%i:00")
                GROUP BY IntervalTime,w.peer_hash_id,origin_as) w
            ON (c.IntervalTime = w.IntervalTime AND c.peer_hash_id = w.peer_hash_id
                and c.origin_as = w.origin_as);


# Create l3vpn rib trigger
drop trigger l3vpn_rib_pre_update;
delimiter //
CREATE TRIGGER l3vpn_rib_pre_update BEFORE UPDATE on l3vpn_rib
  FOR EACH ROW
  BEGIN
      # Allow per session disabling of trigger (set @TRIGGER_DISABLED=TRUE to disable, set @TRIGGER_DISABLED=FALSE to enable)
      IF ( @TRIGGER_DISABLED is null OR @TRIGGER_DISABLED = FALSE ) THEN

        # Make sure we are updating a duplicate
        IF (new.hash_id = old.hash_id AND new.peer_hash_id = old.peer_hash_id) THEN
            IF (new.isWithdrawn = False) THEN
              IF (old.path_attr_hash_id != new.path_attr_hash_id AND old.path_attr_hash_id != '') THEN
                   # Add path log if the path has changed
                    INSERT IGNORE INTO l3vpn_log (type,rd,prefix,prefix_len,path_attr_hash_id,peer_hash_id,timestamp)
                                VALUES ('changed', old.rd, old.prefix,old.prefix_len,old.path_attr_hash_id,old.peer_hash_id,
                                        old.timestamp);
              END IF;

              # Update first_added_timestamp if withdrawn for a long timestamp
              IF (old.isWithdrawn = True AND old.timestamp < date_sub(new.timestamp, INTERVAL 6 HOUR)) THEN
                  SET new.first_added_timestamp = current_timestamp(6);
              END IF;

            ELSE
                # Add log entry for withdrawn prefix
                INSERT IGNORE INTO l3vpn_log
                       (type,rd,prefix,prefix_len,peer_hash_id,path_attr_hash_id,timestamp)
                           VALUES ('withdrawn', old.rd, old.prefix,old.prefix_len,old.peer_hash_id,
                                   old.path_attr_hash_id,new.timestamp);
            END IF;

        END IF;
      END IF;
  END;//
delimiter ;

drop table if exists gen_asn_stats;
CREATE TABLE gen_asn_stats (
  asn int(10) unsigned NOT NULL,
  isTransit tinyint(4) NOT NULL DEFAULT 0,
  isOrigin tinyint(4) NOT NULL DEFAULT 0,
  transit_v4_prefixes bigint(20) unsigned NOT NULL DEFAULT 0,
  transit_v6_prefixes bigint(20) unsigned NOT NULL DEFAULT 0,
  origin_v4_prefixes bigint(20) unsigned NOT NULL DEFAULT 0,
  origin_v6_prefixes bigint(20) unsigned NOT NULL DEFAULT 0,
  repeats bigint(20) unsigned NOT NULL DEFAULT 0,
  timestamp timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  transit_v4_change decimal(8,5) NOT NULL DEFAULT 0.00000,
  transit_v6_change decimal(8,5) NOT NULL DEFAULT 0.00000,
  origin_v4_change decimal(8,5) NOT NULL DEFAULT 0.00000,
  origin_v6_change decimal(8,5) NOT NULL DEFAULT 0.00000,
  PRIMARY KEY (asn,timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


drop trigger ins_gen_asn_stats;
delimiter //
CREATE TRIGGER ins_gen_asn_stats BEFORE INSERT ON gen_asn_stats
FOR EACH ROW
    BEGIN
        declare last_ts timestamp default current_timestamp;
        declare v4_o_count bigint(20) unsigned default 0;
        declare v6_o_count bigint(20) unsigned default 0;
        declare v4_t_count bigint(20) unsigned default 0;
        declare v6_t_count bigint(20) unsigned default 0;

        SELECT transit_v4_prefixes,transit_v6_prefixes,origin_v4_prefixes,
                    origin_v6_prefixes,timestamp
            INTO v4_t_count,v6_t_count,v4_o_count,v6_o_count,last_ts
            FROM gen_asn_stats WHERE asn = new.asn
            ORDER BY timestamp DESC limit 1;

        IF (new.transit_v4_prefixes = v4_t_count AND new.transit_v6_prefixes = v6_t_count
                AND new.origin_v4_prefixes = v4_o_count AND new.origin_v6_prefixes = v6_o_count) THEN
            set new.timestamp = last_ts;
        ELSE
            IF (v4_t_count > 0 AND new.transit_v4_prefixes > 0 AND new.transit_v4_prefixes != v4_t_count) THEN
                SET new.transit_v4_change = cast(if(new.transit_v4_prefixes > v4_t_count,
                                               new.transit_v4_prefixes / v4_t_count,
                                               v4_t_count / new.transit_v4_prefixes * -1) as decimal(8,5));
            END IF;

            IF (v6_t_count > 0 AND new.transit_v6_prefixes > 0 AND new.transit_v6_prefixes != v6_t_count) THEN
                SET new.transit_v6_change = cast(if(new.transit_v6_prefixes > v6_t_count,
                                               new.transit_v6_prefixes / v6_t_count,
                                               v6_t_count / new.transit_v6_prefixes * -1) as decimal(8,5));
            END IF;

            IF (v4_o_count > 0 AND new.origin_v4_prefixes > 0 AND new.origin_v4_prefixes != v4_o_count) THEN
                SET new.origin_v4_change = cast(if(new.origin_v4_prefixes > v4_o_count,
                                              new.origin_v4_prefixes / v4_o_count,
                                              v4_o_count / new.origin_v4_prefixes * -1) as decimal(8,5));
            END IF;

            IF (v6_o_count > 0 AND new.origin_v6_prefixes > 0 AND new.origin_v6_prefixes != v6_o_count) THEN
                SET new.origin_v6_change = cast(if(new.origin_v6_prefixes > v6_o_count,
                                              new.origin_v6_prefixes / v6_o_count,
                                              v6_o_count / new.origin_v6_prefixes * -1) as decimal(8,5));
            END IF;
        END IF;
    END//
delimiter ;

# add origin_as to path_attr_log and withdrawn_log
alter IGNORE table path_attr_log add column origin_as int(10) unsigned NOT NULL, add key idx_origin_as (origin_as);
alter IGNORE table withdrawn_log add column origin_as int(10) unsigned NOT NULL, add key idx_origin_as (origin_as);

UPGRADE

fi

if [ $? -eq 0 ]; then
   echo "SCHEMA_VERSION=$CUR_VERSION" > /data/mysql/schema-version
   echo "Schema upgraded to version $CUR_VERSION"
else
   echo "ERROR: failed to upgrade schema to version $CUR_VERSION. You might need to manually fix this."
   echo "       Using a fresh DB can fix this. Run 'rm -rf /var/openbmp/mysql/*' before starting the container."
   exit 1
fi
