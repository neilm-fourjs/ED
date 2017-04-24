
DEFINE solution DYNAMIC ARRAY OF RECORD
		ruin DYNAMIC ARRAY OF RECORD
			r_d SMALLINT,
			sys_name VARCHAR(60),
			body_name VARCHAR(10),
			data DYNAMIC ARRAY OF CHAR(20)
		END RECORD,
		data DYNAMIC ARRAY OF CHAR(20)
	END RECORD
DEFINE processed_ruins DYNAMIC ARRAY OF SMALLINT
DEFINE ruins_with_data DYNAMIC ARRAY OF RECORD
		r_id SMALLINT,
		data_cnt SMALLINT
	END RECORD

TYPE t_rd_rec RECORD
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		active SMALLINT,
		data CHAR(20)
	END RECORD
TYPE t_r_rec RECORD
		system_id INTEGER,
		body_name VARCHAR(10),
		bodyDistance INTEGER,
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		coor_long DECIMAL(8,4),
		coor_lat DECIMAL(8,4),
		system_name VARCHAR(60)
	END RECORD
DEFINE m_min_data SMALLINT
MAIN
	DEFINE l_ruin_id SMALLINT
	DEFINE l_db STRING
	DEFINE r,x,y,l_sys_cnt,l_body_cnt SMALLINT
	DEFINE l_line, l_loc, l_body, l_prev_loc, l_prev_body STRING

-- connect to the database
	LET l_db = "ed+driver='dbmsqt',source='ed.db'"
	TRY
  	DATABASE l_db
	CATCH
		DISPLAY "Failed to connect to db:",l_db,"\n"||STATUS,"-",SQLERRMESSAGE
		EXIT PROGRAM	
	END TRY


-- declare primary cursors
	DECLARE obe_cur CURSOR FOR SELECT data FROM ruins_data WHERE ruin_id = ? AND data IS NOT NULL
	DECLARE r_cur CURSOR FOR SELECT ruins.*,system_name FROM ruins, ruins_systems
		WHERE ruin_id = ?
			AND ruins.system_id = ruins_systems.system_id
	DECLARE r_cur2 CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id != ? AND system_id = ? AND body_name = ?
	DECLARE cur CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id < 99990 AND system_id != 25 ORDER BY ruin_id

-- get an array of only ruins with data
	FOREACH cur INTO l_ruin_id	
		SELECT COUNT(*) INTO r FROM ruins_data WHERE ruin_id = l_ruin_id AND data IS NOT NULL
		IF r > 0 THEN
			LET ruins_with_data[ ruins_with_data.getLength() + 1 ].r_id = l_ruin_id
			LET ruins_with_data[ ruins_with_data.getLength() ].data_cnt = r
		END IF
	END FOREACH
	CALL ruins_with_data.sort('data_cnt',TRUE)
	DISPLAY ruins_with_data.getLength()," Ruins sites with data."
	{FOR x = 1 TO ruins_with_data.getLength()
		DISPLAY "Ruins:", ruins_with_data[ x ].r_id, " Data:",ruins_with_data[ x ].data_cnt
	END FOR}

	CALL solution.appendElement()

--	CALL njm_got()

-- process the ruins with data to find all 101 datascans
	LET m_min_data = 6
	CALL find_data()
	LET m_min_data = 4
	CALL find_data()
	LET m_min_data = 2
	CALL find_data()
	LET m_min_data = 1
	CALL find_data()

	DISPLAY "-------------------------------------------------"
	CALL solution[ solution.getLength() ].ruin.sort("sys_name",FALSE)

	LET r = 0
	LET l_prev_loc = "."
	LET l_sys_cnt = 0
	FOR x = 1 TO solution[ solution.getLength() ].ruin.getLength()
		CALL solution[ solution.getLength() ].ruin[x].data.sort(NULL,FALSE)
		LET l_loc = solution[ solution.getLength() ].ruin[x].sys_name," /  ",solution[ solution.getLength() ].ruin[x].body_name
		IF l_prev_loc != l_loc THEN
			DISPLAY "Location: ",l_loc
			LET l_sys_cnt = l_sys_cnt + 1
		END IF
		LET l_prev_loc = l_loc
		DISPLAY "    Ruins: GS", solution[ solution.getLength() ].ruin[x].r_d USING "<<<", 
			" DataScans: ",solution[ solution.getLength() ].ruin[x].data.getLength() USING "##"
		FOR y = 1 TO solution[ solution.getLength() ].ruin[x].data.getLength()
			DISPLAY "      ",solution[ solution.getLength() ].ruin[x].data[y]
		END FOR
	END FOR
	DISPLAY "Found: "||solution[ solution.getLength() ].data.getLength()||" datascans, from "||solution[ solution.getLength() ].ruin.getLength()||" ruin sites, on "||l_sys_cnt||" planets."

	DISPLAY "-------------------------------------------------"

	LET r = 0
	LET l_prev_loc = "."
	LET l_prev_body = "."
	LET l_sys_cnt = 0
	LET l_body_cnt = 0
	FOR x = 1 TO solution[ solution.getLength() ].ruin.getLength()
		LET l_loc = solution[ solution.getLength() ].ruin[x].sys_name
		LET l_body = solution[ solution.getLength() ].ruin[x].body_name
		IF l_prev_loc != l_loc THEN
			LET l_line = l_loc
			LET l_sys_cnt = l_sys_cnt + 1
		ELSE
			LET l_line = ""
		END IF
		LET l_line = l_line.append(",")
		IF l_prev_body != l_body THEN
			LET l_line = l_line.append(l_body)
			LET l_body_cnt = l_body_cnt + 1
		END IF
		LET l_line = l_line.append(",")
		LET l_prev_loc = l_loc
		LET l_prev_body = l_body
		LET l_line = l_line.append("GS"||solution[ solution.getLength() ].ruin[x].r_d)
		FOR y = 1 TO solution[ solution.getLength() ].ruin[x].data.getLength()
			IF y = 1 THEN
				DISPLAY l_line||","||solution[ solution.getLength() ].ruin[x].data[y]
			ELSE
				DISPLAY ",,,",solution[ solution.getLength() ].ruin[x].data[y]
			END IF
		END FOR
	END FOR
	DISPLAY "Found: "||solution[ solution.getLength() ].data.getLength()||" datascans, from "||solution[ solution.getLength() ].ruin.getLength()||" ruin sites, in "||l_sys_cnt||" systems on "||l_body_cnt||" planets."

END MAIN
--------------------------------------------------------------------------------
FUNCTION find_data()
	DEFINE x,r, r_id SMALLINT
	FOR r = 1 TO ruins_with_data.getLength()
		LET r_id = ruins_with_data[r].r_id
		-- are we skipping this ruins site?
		FOR x = 1 TO processed_ruins.getLength()	
			IF r_id = processed_ruins[x] THEN CONTINUE FOR END IF
		END FOR

		CALL proc_ruin( r_id )
-- if we got all 101 scans we can stop looking.
		IF solution[ solution.getLength() ].data.getLength() = 101 THEN EXIT FOR END IF
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION proc_ruin( r_id )
	DEFINE r_id SMALLINT
	DEFINE r_cnt, x SMALLINT
	DEFINE l_data CHAR(20)
	DEFINE other_ruins DYNAMIC ARRAY OF SMALLINT
	DEFINE l_data_arr DYNAMIC ARRAY OF CHAR(20)
	DEFINE r_rec t_r_rec
--	DISPLAY "Processing from ",r_id

	LET r_cnt = solution[ solution.getLength() ].ruin.getLength()
-- look at the data available at this ruin site and store and new data sets
	FOREACH obe_cur USING r_id INTO l_data
		FOR x = 1 TO solution[ solution.getLength() ].data.getLength()
			IF solution[ solution.getLength() ].data[x] = l_data THEN
				CONTINUE FOREACH
			END IF
		END FOR
		FOR x = 1 TO l_data_arr.getLength() -- handle duplicate data
			IF l_data_arr[x] = l_data THEN CONTINUE FOREACH END IF
		END FOR
		LET l_data_arr[ l_data_arr.getLength() + 1 ] = l_data
	END FOREACH

-- if we got new data then store the ruin id
	IF l_data_arr.getLength() >= m_min_data THEN
		FOR x = 1 TO l_data_arr.getLength() -- store new data
			LET solution[ solution.getLength() ].data[solution[ solution.getLength() ].data.getLength()+1 ] = l_data_arr[x]
		END FOR
		LET r_cnt = r_cnt + 1
		LET solution[ solution.getLength() ].ruin[ r_cnt ].r_d = r_id
		CALL l_data_arr.copyTo(solution[ solution.getLength() ].ruin[ r_cnt ].data )
		LET processed_ruins[processed_ruins.getLength()+1] = r_id
-- since we got data from this ruins - look to see if any more ruins on same body
		OPEN r_cur USING r_id
		FETCH r_cur INTO r_rec.* -- fetch system & body name for this ruin
		CLOSE r_cur
		LET solution[ solution.getLength() ].ruin[ r_cnt ].body_name = r_rec.body_name
		LET solution[ solution.getLength() ].ruin[ r_cnt ].sys_name = r_rec.system_name
		DISPLAY r_id," Found ",l_data_arr.getLength()," new scans:",r_rec.system_name
-- loop through any more ruins at the same system & body
		FOREACH r_cur2 USING r_id, r_rec.system_id, r_rec.body_name INTO r_id
			FOR x = 1 TO processed_ruins.getLength()	
				IF r_id = processed_ruins[x] THEN CONTINUE FOR END IF
			END FOR
			LET other_ruins[ other_ruins.getLength() + 1 ] = r_id
		END FOREACH
		FOR x = 1 TO other_ruins.getLength()
			DISPLAY "Found another ruin on same body:", other_ruins[x]
			CALL proc_ruin( other_ruins[x] )
		END FOR
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION njm_got()
	DEFINE c base.Channel
	LET c = base.Channel.create()
	CALL c.openFile("njm_got","r")
	WHILE  NOT c.isEof()
		LET solution[ 1 ].data[  solution[ 1 ].data.getLength() + 1 ] = c.readLine()
	END WHILE
	CALL c.close()
END FUNCTION
--------------------------------------------------------------------------------