Databases Supported
===================
Currently MySQL/MariaDB **5.7** (and greater) is supported.   Any Linux distribution that uses an
older version should install at least version 5.7 via [MySQL Download](http://dev.mysql.com/downloads/mysql/) or the latest version via [MariaDB Download](https://downloads.mariadb.org/)

Interaction with the Database
=============================

OpenBMP stores the parsed BMP messages in a database. The DB is updated realtime as messages are received.

The design allows for admins, network engineers, scripts/programs, etc. to interact with the Database in a read-only fashion.   A single database instance running with 8G of RAM and 4 vCPU's can handle several routers with several full Internet routing bgp peers. 

Behaviors
---------
* BGP information will persist in the DB so long as the data is being updated.  
* When openbmp is stopped, the data will still be there in the DB but the routers table will be updated to indicate that BMP router(s) are not connected with a term code of 65535 and term text indicating openbmp was stopped/not running.  Peers are unchanged to allow going back in time to check their last known states.  
* When openbmp is started it will add/re-add routers and peers when BMP messages are received.  When the router is added, all router associated peers in the DB will have a state set to zero to indicate the peer is not connected.  When PEER UP or monitoring information is received for the peer, the peer state will change to indicate it's active/up.  
* A special timestamp field (**_db_timestamp_**) in the **rib** table is used to indicate if the RIB entry is stale or not.  The **rib.db_timestamp** should always be _greater than or equal to_ the **peer.timestmap**.  RIB entries that have an older **db_timestamp** than the peer timestmap remain for historical reporting.  These older RIB entries can be safely purged based on admin/retention policy using something like: `DELETE r  FROM rib r JOIN bgp_peers p ON (r.peer_hash_id = p.hash_id) WHERE r.db_timestamp < p.timestamp;` 



Primary Keys
------------
OpenBMP is not just logging BMP/BGP messages, instead it is actively maintaining the information.   Therefore, there is a need for OpenBMP to update existing objects, such as NLRI and timestamps.   To facilitate this, each table includes a **hash_id** which is currently a MD5 hash of various columns.  Each table hash_id is computed on column information instead of requiring multiple column primary keys or unique key constraints.   

To facilitate table linking, **hash_id's** of other tables are referenced.  Each table defines the reference to other table hash_id's.


#Schema documentation

Generated by MySQL Workbench Model Documentation v1.0.0 - Copyright (c) 2015 Hieu Le

##Table: `as_path_analysis`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `asn` | INT | Not null |   |   |
| `asn_left` | INT | Not null | `0` |   |
| `asn_right` | INT | Not null | `0` |   |
| `rib_hash_id` | CHAR(32) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `isIPv4` | BIT | Not null | `b'1'` |   |
| `isWithdrawn` | BIT | Not null | `b'0'` |   |
| `timestamp` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `bgp_nexthop`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `nexthop` | VARCHAR(46) | Not null |   |   |
| `ls_prefix_hash_id` | CHAR(32) |  | `NULL` |   |
| `ls_prefix` | VARCHAR(46) |  | `NULL` |   |
| `ls_prefix_len` | TINYINT |  | `NULL` |   |
| `ls_src_node_hash_id` | CHAR(32) |  | `NULL` |   |
| `ls_peer_hash_id` | CHAR(32) |  | `NULL` |   |
| `ls_area_id` | VARCHAR(46) |  | `NULL` |   |
| `ls_metric` | INT |  | `NULL` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `bgp_peers`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `router_hash_id` | CHAR(32) | Not null |   |   |
| `peer_rd` | VARCHAR(32) | Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `peer_addr` | VARCHAR(40) | Not null |   |   |
| `name` | VARCHAR(200) |  | `NULL` |   |
| `peer_bgp_id` | VARCHAR(15) | Not null |   |   |
| `peer_as` | INT | Not null |   |   |
| `state` | TINYINT | Not null | `1` |   |
| `isL3VPNpeer` | TINYINT | Not null | `0` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `collectors`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `state` | ENUM |  | `NULL` |   |
| `admin_id` | VARCHAR(64) | Not null |   |   |
| `routers` | VARCHAR(4096) |  | `NULL` |   |
| `router_count` | INT | Not null |   |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `community_analysis`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `community` | VARCHAR(22) | PRIMARY, Not null |   |   |
| `part1` | INT | Not null | `0` |   |
| `part2` | INT | Not null | `0` |   |
| `path_attr_hash_id` | CHAR(32) | PRIMARY, Not null |   |   |
| `peer_hash_id` | CHAR(32) | PRIMARY, Not null |   |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP()` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `community`, `peer_hash_id`, `path_attr_hash_id` | PRIMARY |   |
| idx_community | `community` | INDEX |   |
| idx_part1 | `part1` | INDEX |   |
| idx_part2 | `part2` | INDEX |   |
| idx_peer_hash | `peer_hash_id` | INDEX |   |


##Table: `gen_active_asns`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `asn` | INT | PRIMARY, Not null |   |   |
| `old` | BIT | Not null | `b'0'` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `asn` | PRIMARY |   |


##Table: `gen_asn_stats`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `asn` | INT | PRIMARY, Not null |   |   |
| `isTransit` | TINYINT | Not null | `0` |   |
| `isOrigin` | TINYINT | Not null | `0` |   |
| `transit_v4_prefixes` | BIGINT | Not null | `0` |   |
| `transit_v6_prefixes` | BIGINT | Not null | `0` |   |
| `origin_v4_prefixes` | BIGINT | Not null | `0` |   |
| `origin_v6_prefixes` | BIGINT | Not null | `0` |   |
| `repeats` | BIGINT | Not null | `0` |   |
| `timestamp` | TIMESTAMP | PRIMARY, Not null | `CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP()` |   |
| `transit_v4_change` | DECIMAL | Not null | `0.00000` |   |
| `transit_v6_change` | DECIMAL | Not null | `0.00000` |   |
| `origin_v4_change` | DECIMAL | Not null | `0.00000` |   |
| `origin_v6_change` | DECIMAL | Not null | `0.00000` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `asn`, `timestamp` | PRIMARY |   |


##Table: `gen_asn_stats_last`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `asn` | INT | PRIMARY, Not null |   |   |
| `isTransit` | TINYINT | Not null | `0` |   |
| `isOrigin` | TINYINT | Not null | `0` |   |
| `transit_v4_prefixes` | BIGINT | Not null | `0` |   |
| `transit_v6_prefixes` | BIGINT | Not null | `0` |   |
| `origin_v4_prefixes` | BIGINT | Not null | `0` |   |
| `origin_v6_prefixes` | BIGINT | Not null | `0` |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP()` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `asn` | PRIMARY |   |


##Table: `gen_chg_stats_byasn`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `interval_time` | DATETIME(6) | PRIMARY, Not null |   |   |
| `peer_hash_id` | CHAR(32) | PRIMARY, Not null |   |   |
| `origin_as` | INT | PRIMARY, Not null |   |   |
| `updates` | INT | Not null | `0` |   |
| `withdraws` | INT | Not null | `0` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `interval_time`, `peer_hash_id`, `origin_as` | PRIMARY |   |
| idx_interval | `interval_time` | INDEX |   |
| idx_peer_hash_id | `peer_hash_id` | INDEX |   |
| idx_origin_as | `origin_as` | INDEX |   |


##Table: `gen_chg_stats_bypeer`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `interval_time` | DATETIME(6) | PRIMARY, Not null |   |   |
| `peer_hash_id` | CHAR(32) | PRIMARY, Not null |   |   |
| `updates` | INT | Not null | `0` |   |
| `withdraws` | INT | Not null | `0` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `interval_time`, `peer_hash_id` | PRIMARY |   |
| idx_interval | `interval_time` | INDEX |   |
| idx_peer_hash_id | `peer_hash_id` | INDEX |   |


##Table: `gen_chg_stats_byprefix`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `interval_time` | DATETIME(6) | PRIMARY, Not null |   |   |
| `peer_hash_id` | CHAR(32) | PRIMARY, Not null |   |   |
| `prefix` | VARCHAR(46) | PRIMARY, Not null |   |   |
| `prefix_len` | TINYINT | PRIMARY, Not null |   |   |
| `updates` | INT | Not null | `0` |   |
| `withdraws` | INT | Not null | `0` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `interval_time`, `peer_hash_id`, `prefix`, `prefix_len` | PRIMARY |   |
| idx_interval | `interval_time` | INDEX |   |
| idx_peer_hash_id | `peer_hash_id` | INDEX |   |
| idx_prefix_full | `prefix`, `prefix_len` | INDEX |   |


##Table: `gen_prefix_validation`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix` | VARBINARY(16) | PRIMARY, Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `prefix_len` | TINYINT | PRIMARY, Not null | `0` |   |
| `recv_origin_as` | INT | PRIMARY, Not null |   |   |
| `rpki_origin_as` | INT |  | `NULL` |   |
| `irr_origin_as` | INT |  | `NULL` |   |
| `irr_source` | VARCHAR(32) |  | `NULL` |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP()` |   |
| `prefix_bits` | VARCHAR(128) | Not null |   |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `prefix`, `prefix_len`, `recv_origin_as` | PRIMARY |   |
| idx_origin | `recv_origin_as` | INDEX |   |
| idx_prefix | `prefix` | INDEX |   |
| idx_prefix_full | `prefix`, `prefix_len` | INDEX |   |
| idx_prefix_bits | `prefix_bits` | INDEX |   |


##Table: `gen_whois_asn`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `asn` | INT | PRIMARY, Not null |   |   |
| `as_name` | VARCHAR(128) |  | `NULL` |   |
| `org_id` | VARCHAR(64) |  | `NULL` |   |
| `org_name` | VARCHAR(255) |  | `NULL` |   |
| `remarks` | TEXT |  | `NULL` |   |
| `address` | VARCHAR(255) |  | `NULL` |   |
| `city` | VARCHAR(64) |  | `NULL` |   |
| `state_prov` | VARCHAR(32) |  | `NULL` |   |
| `postal_code` | VARCHAR(32) |  | `NULL` |   |
| `country` | VARCHAR(24) |  | `NULL` |   |
| `raw_output` | TEXT |  | `NULL` |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP()` |   |
| `source` | VARCHAR(64) |  | `NULL` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `asn` | PRIMARY |   |


##Table: `gen_whois_route`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix` | VARBINARY(16) | PRIMARY, Not null |   |   |
| `prefix_len` | INT | PRIMARY, Not null | `0` |   |
| `descr` | BLOB |  | `NULL` |   |
| `origin_as` | INT | PRIMARY, Not null |   |   |
| `source` | VARCHAR(32) | Not null |   |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP()` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `prefix`, `prefix_len`, `origin_as` | PRIMARY |   |
| idx_origin_as | `origin_as` | INDEX |   |


##Table: `geo_ip`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `addr_type` | ENUM | Not null |   |   |
| `ip_start` | VARBINARY(16) | PRIMARY, Not null |   |   |
| `ip_end` | VARBINARY(16) | Not null |   |   |
| `country` | CHAR(2) | Not null |   |   |
| `stateprov` | VARCHAR(80) | Not null |   |   |
| `city` | VARCHAR(80) | Not null |   |   |
| `latitude` | FLOAT | Not null |   |   |
| `longitude` | FLOAT | Not null |   |   |
| `timezone_offset` | FLOAT | Not null |   |   |
| `timezone_name` | VARCHAR(64) | Not null |   |   |
| `isp_name` | VARCHAR(128) | Not null |   |   |
| `connection_type` | ENUM |  | `NULL` |   |
| `organization_name` | VARCHAR(128) |  | `NULL` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `ip_start` | PRIMARY |   |
| idx_city | `city` | INDEX |   |
| idx_stateprov | `stateprov` | INDEX |   |
| idx_country | `country` | INDEX |   |
| idx_addr_type | `addr_type` | INDEX |   |
| idx_ip_end | `ip_end` | INDEX |   |
| idx_ip_range | `ip_start`, `ip_end` | INDEX |   |


##Table: `geo_location`

###Description: 


###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `country` | VARCHAR(50) | PRIMARY, Not null |   |   |
| `city` | VARCHAR(50) | PRIMARY, Not null |   |   |
| `latitude` | FLOAT | Not null |   |   |
| `longitude` | FLOAT | Not null |   |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `country`, `city` | PRIMARY |   |



##Table: `l3vpn_log`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `type` | ENUM | Not null |   |   |
| `prefix` | VARCHAR(40) | Not null |   |   |
| `rd` | VARCHAR(30) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `timestamp` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `l3vpn_rib`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `origin_as` | INT | Not null |   |   |
| `rd` | VARCHAR(30) | Not null |   |   |
| `prefix` | VARCHAR(40) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_bcast_bin` | VARBINARY(16) | Not null |   |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `ls_links`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `id` | BIGINT | Not null |   |   |
| `mt_id` | INT |  | `0` |   |
| `interface_addr` | VARCHAR(46) | Not null |   |   |
| `neighbor_addr` | VARCHAR(46) | Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `protocol` | ENUM |  | `NULL` |   |
| `local_link_id` | INT | Not null |   |   |
| `remote_link_id` | INT | Not null |   |   |
| `local_node_hash_id` | CHAR(32) | Not null |   |   |
| `remote_node_hash_id` | CHAR(32) | Not null |   |   |
| `admin_group` | INT | Not null |   |   |
| `max_link_bw` | INT |  | `0` |   |
| `max_resv_bw` | INT |  | `0` |   |
| `unreserved_bw` | VARCHAR(100) |  | `NULL` |   |
| `te_def_metric` | INT | Not null |   |   |
| `protection_type` | VARCHAR(60) |  | `NULL` |   |
| `mpls_proto_mask` | ENUM |  | `NULL` |   |
| `igp_metric` | INT | Not null |   |   |
| `srlg` | VARCHAR(128) | Not null |   |   |
| `name` | VARCHAR(255) | Not null |   |   |
| `isWithdrawn` | BIT | Not null | `b'0'` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `ls_nodes`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `id` | BIGINT | Not null |   |   |
| `asn` | INT | Not null |   |   |
| `bgp_ls_id` | INT | Not null |   |   |
| `igp_router_id` | VARCHAR(46) | Not null |   |   |
| `ospf_area_id` | VARCHAR(16) | Not null |   |   |
| `protocol` | ENUM |  | `NULL` |   |
| `router_id` | VARCHAR(46) | Not null |   |   |
| `isis_area_id` | VARCHAR(46) | Not null |   |   |
| `flags` | VARCHAR(20) | Not null |   |   |
| `name` | VARCHAR(255) | Not null |   |   |
| `isWithdrawn` | BIT | Not null | `b'0'` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `ls_prefixes`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `id` | BIGINT | Not null |   |   |
| `local_node_hash_id` | CHAR(32) | Not null |   |   |
| `mt_id` | INT | Not null |   |   |
| `protocol` | ENUM |  | `NULL` |   |
| `prefix` | VARCHAR(46) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_bcast_bin` | VARBINARY(16) | Not null |   |   |
| `ospf_route_type` | ENUM |  | `NULL` |   |
| `igp_flags` | VARCHAR(20) | Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `route_tag` | INT |  | `NULL` |   |
| `ext_route_tag` | BIGINT |  | `NULL` |   |
| `metric` | INT | Not null |   |   |
| `ospf_fwd_addr` | VARCHAR(46) |  | `NULL` |   |
| `isWithdrawn` | BIT | Not null | `b'0'` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `path_attr_log`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `timestamp` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `path_attrs`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `origin` | VARCHAR(16) | Not null |   |   |
| `as_path` | VARCHAR(8192) | Not null |   |   |
| `as_path_count` | INT |  | `NULL` |   |
| `origin_as` | INT |  | `NULL` |   |
| `next_hop` | VARCHAR(40) |  | `NULL` |   |
| `med` | INT |  | `NULL` |   |
| `local_pref` | INT |  | `NULL` |   |
| `aggregator` | VARCHAR(64) |  | `NULL` |   |
| `community_list` | VARCHAR(4096) |  | `NULL` |   |
| `ext_community_list` | VARCHAR(2048) |  | `NULL` |   |
| `cluster_list` | VARCHAR(2048) |  | `NULL` |   |
| `isAtomicAgg` | TINYINT |  | `0` |   |
| `nexthop_isIPv4` | TINYINT |  | `1` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `peer_down_events`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `id` | BIGINT | Auto increments, Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `bmp_reason` | TINYINT |  | `NULL` |   |
| `bgp_err_code` | INT |  | `NULL` |   |
| `bgp_err_subcode` | INT |  | `NULL` |   |
| `error_text` | VARCHAR(255) |  | `NULL` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `peer_up_events`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `id` | BIGINT | Auto increments, Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `local_ip` | VARCHAR(40) | Not null |   |   |
| `local_bgp_id` | VARCHAR(15) | Not null |   |   |
| `local_port` | INT | Not null |   |   |
| `local_hold_time` | INT | Not null |   |   |
| `local_asn` | INT | Not null |   |   |
| `remote_port` | INT | Not null |   |   |
| `remote_hold_time` | INT | Not null |   |   |
| `sent_capabilities` | VARCHAR(4096) |  | `NULL` |   |
| `recv_capabilities` | VARCHAR(4096) |  | `NULL` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `rib`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `path_attr_hash_id` | CHAR(32) | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `isIPv4` | TINYINT | Not null |   |   |
| `origin_as` | INT | Not null |   |   |
| `prefix` | VARCHAR(40) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_bcast_bin` | VARBINARY(16) | Not null |   |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `routers`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `hash_id` | CHAR(32) | Not null |   |   |
| `name` | VARCHAR(200) | Not null |   |   |
| `ip_address` | VARCHAR(40) | Not null |   |   |
| `router_AS` | INT |  | `NULL` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `rpki_history_stats`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `total_prefix` | INT | Not null |   |   |
| `total_violations` | INT | Not null |   |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `rpki_validator`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix` | VARBINARY(16) | PRIMARY, Not null |   |   |
| `prefix_len` | TINYINT | PRIMARY, Not null | `0` |   |
| `prefix_len_max` | TINYINT | PRIMARY, Not null | `0` |   |
| `origin_as` | INT | PRIMARY, Not null |   |   |
| `timestamp` | TIMESTAMP | Not null | `CURRENT_TIMESTAMP()` |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `prefix`, `prefix_len`, `prefix_len_max`, `origin_as` | PRIMARY |   |
| idx_origin | `origin_as` | INDEX |   |
| idx_prefix | `prefix` | INDEX |   |
| idx_prefix_full | `prefix`, `prefix_len` | INDEX |   |


##Table: `stat_reports`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `id` | BIGINT | Auto increments, Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `prefixes_rejected` | BIGINT |  | `NULL` |   |
| `known_dup_prefixes` | BIGINT |  | `NULL` |   |
| `known_dup_withdraws` | BIGINT |  | `NULL` |   |
| `updates_invalid_by_cluster_list` | BIGINT |  | `NULL` |   |
| `updates_invalid_by_as_path_loop` | BIGINT |  | `NULL` |   |
| `timestamp` | TIMESTAMP(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `unicast_rib_lookup`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix_bin` | VARBINARY(16) | PRIMARY, Not null |   |   |
| `prefix_bcast_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_len` | INT | PRIMARY, Not null |   |   |
| `origin_as` | INT | Not null |   |   |
| `isIPv4` | BIT | Not null |   |   |
| `isLS` | BIT | Not null |   |   |
| `refCount` | INT | Not null |   |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `prefix_bin`, `prefix_len` | PRIMARY |   |
| idx_prefix | `prefix_bin` | INDEX |   |
| idx_prefix_bcast | `prefix_bcast_bin` | INDEX |   |
| idx_prefix_range | `prefix_bcast_bin`, `prefix_bin` | INDEX |   |


##Table: `users`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `username` | VARCHAR(50) | PRIMARY, Not null |   |   |
| `password` | VARCHAR(50) | Not null |   |   |
| `type` | VARCHAR(10) | Not null |   |   |


### Indices: 

| Name | Columns | Type | Description |
| --- | --- | --- | --- |
| PRIMARY | `username` | PRIMARY |   |


##Table: `watcher_origin_suppress`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_len` | TINYINT | Not null |   |   |
| `allowed_origin_as` | INT | Not null |   |   |
| `notes` | VARCHAR(255) |  | `NULL` |   |
| `timestamp` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `watcher_prefix_log`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `prefix_bin` | VARBINARY(16) | Not null |   |   |
| `prefix_len` | TINYINT | Not null |   |   |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `watcher_rule_num` | INT | Not null |   |   |
| `watcher_rule_name` | VARCHAR(255) | Not null | `''` |   |
| `count` | INT | Not null | `1` |   |
| `origin_as` | INT | Not null |   |   |
| `prev_origin_as` | INT |  | `NULL` |   |
| `aggregate_prefix_bin` | VARBINARY(16) |  | `NULL` |   |
| `aggregate_prefix_len` | TINYINT |  | `NULL` |   |
| `aggregate_origin_as` | INT |  | `NULL` |   |
| `analysis_output` | TEXT |  | `NULL` |   |
| `period_ts` | DATETIME(6) | Not null |   |   |
| `first_ts` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




##Table: `withdrawn_log`

###Description: 



###Columns: 

| Column | Data type | Attributes | Default | Description |
| --- | --- | --- | --- | ---  |
| `peer_hash_id` | CHAR(32) | Not null |   |   |
| `prefix` | VARCHAR(40) | Not null |   |   |
| `prefix_len` | INT | Not null |   |   |
| `timestamp` | DATETIME(6) | Not null | `CURRENT_TIMESTAMP()` |   |




