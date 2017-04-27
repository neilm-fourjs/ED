SELECT ruins.ruin_id,ruins_systems.system_name||"  /  "||ruins.body_name,
ruins_data.groupname||ruins_data.obelisk_no,
trim(scan_data.item_1)||"/"||trim(scan_data.item_2),
scan_data.isverified
FROM ruins,ruins_data, scan_data, ruins_systems
WHERE ruins_data.data = "Technology 6"
and ruins.ruin_id = ruins_data.ruin_id
and ruins.system_id = ruins_systems.system_id
and ruins_data.ruintypename = scan_data.ruintypename
and ruins_data.groupname = scan_data.groupname
and ruins_data.obelisk_no = scan_data.obelisk_no
order by system_name, body_name