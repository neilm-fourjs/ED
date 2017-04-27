SELECT ruins_data.ruin_id,
ruins_data.ruintypename,
ruins_data.groupname||ruins_data.obelisk_no,
ruins_data.data,
scan_data.isverified,
trim(scan_data.item_1)||"/"||scan_data.item_2
FROM ruins_data, scan_data
WHERE ruins_data.data = "Language 21"
and ruins_data.ruintypename = scan_data.ruintypename
and ruins_data.groupname = scan_data.groupname
and ruins_data.obelisk_no = scan_data.obelisk_no

