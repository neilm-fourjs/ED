select s.* from ruins_data r, scan_data s
where r.active = 1
and r.ruinTypeName = s.ruinTypeName
and r.groupName = s.groupName
and r.obelisk_no = s.obelisk_no
