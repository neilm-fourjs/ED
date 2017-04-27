SELECT rs.system_name[1,28],r.body_name Body, ruin_id id, ruintypename ruin
 FROM ruins r, ruins_systems rs
WHERE r.system_id = rs.system_id
ORDER BY ruin_id
