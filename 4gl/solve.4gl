IMPORT FGL db_connect
IMPORT FGL calc_dist

DEFINE solution DYNAMIC ARRAY OF RECORD
		ruin DYNAMIC ARRAY OF RECORD
			x SMALLINT,
			r_id SMALLINT,
			r_type STRING,
			sys_name VARCHAR(60),
			sys_distance_from_gs1 INTEGER,
			body_name VARCHAR(10),
			body_distance INTEGER,
			data DYNAMIC ARRAY OF CHAR(20),
			avail_data DYNAMIC ARRAY OF CHAR(20)
		END RECORD,
		data DYNAMIC ARRAY OF CHAR(20)
	END RECORD
DEFINE processed_ruins DYNAMIC ARRAY OF SMALLINT
DEFINE ruins_with_data DYNAMIC ARRAY OF RECORD
		r_id SMALLINT,
		data_cnt SMALLINT,
		distance_from_gs1 INTEGER
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

MAIN
	DEFINE l_ruin_id SMALLINT
	DEFINE r,x SMALLINT
	DEFINE d INTEGER

-- connect to the database
	CALL db_connect.db_con()

-- declare primary cursors
	DECLARE obe_cur CURSOR FOR SELECT UNIQUE data FROM ruins_data WHERE ruin_id = ? AND data IS NOT NULL ORDER BY data
	DECLARE r_cur CURSOR FOR SELECT ruins.*,system_name FROM ruins, ruins_systems
		WHERE ruin_id = ?
			AND ruins.system_id = ruins_systems.system_id
	DECLARE r_cur2 CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id != ? AND system_id = ? AND body_name = ?
	DECLARE cur CURSOR FOR 
		SELECT ruin_id, distance_from_gs1 FROM ruins, ruins_systems
		 WHERE ruin_id < 99990 AND ruins_systems.system_id != 25 
			AND ruins_systems.system_id = ruins.system_id
		ORDER BY distance_from_gs1 

-- get an array of only ruins with data
	FOREACH cur INTO l_ruin_id, d
		SELECT COUNT(*) INTO r FROM ruins_data WHERE ruin_id = l_ruin_id AND data IS NOT NULL
		IF r > 0 THEN
			LET ruins_with_data[ ruins_with_data.getLength() + 1 ].r_id = l_ruin_id
			LET ruins_with_data[ ruins_with_data.getLength() ].data_cnt = r
			IF d IS NULL THEN LET d = 0 END IF
			LET ruins_with_data[ ruins_with_data.getLength() ].distance_from_gs1 = d
		END IF
	END FOREACH
	CALL ruins_with_data.sort('data_cnt',TRUE)
	DISPLAY ruins_with_data.getLength()," Ruins sites with data."
{
	FOR x = 1 TO ruins_with_data.getLength()
		DISPLAY "Ruins:", ruins_with_data[ x ].r_id, " Data:",ruins_with_data[ x ].data_cnt," Distance:", ruins_with_data[ x ].distance_from_gs1
	END FOR
}
	CALL solution.appendElement()

--	CALL njm_got()

-- process the ruins with data to find all 101 datascans
	CALL find_data(8,100000)
	CALL find_data(6,100000)
	CALL find_data(4,100000)
	CALL find_data(2,1000000)
	CALL find_data(1,1000000)

	CALL dump_results()

	CALL disp_results()

END MAIN
--------------------------------------------------------------------------------
-- display results to a table
FUNCTION disp_results()
	DEFINE x, l_sys_cnt SMALLINT
	DEFINE l_tab DYNAMIC ARRAY OF RECORD
		idx SMALLINT,
		sys  STRING,
		sysd INTEGER,
		body STRING,
		bodyd INTEGER,
		site STRING,
		data STRING
	END RECORD
	DEFINE sd DYNAMIC ARRAY OF CHAR(20)
	DEFINE asd DYNAMIC ARRAY OF CHAR(20)
	DEFINE l_prev_loc STRING

	OPEN FORM solve FROM "solve"
	DISPLAY FORM solve
	LET l_sys_cnt = 0
	LET l_prev_loc = "."
	CALL solution[ solution.getLength() ].ruin.sort("sys_name",FALSE)
	FOR x = 1 TO solution[ solution.getLength() ].ruin.getLength()

		CALL l_tab.appendElement()
		LET l_tab[ l_tab.getLength() ].idx = solution[ solution.getLength() ].ruin[x].x
		LET l_tab[ l_tab.getLength() ].sys = solution[ solution.getLength() ].ruin[x].sys_name
		LET l_tab[ l_tab.getLength() ].sysd = solution[ solution.getLength() ].ruin[x].sys_distance_from_gs1
		LET l_tab[ l_tab.getLength() ].body = solution[ solution.getLength() ].ruin[x].body_name
		LET l_tab[ l_tab.getLength() ].bodyd = solution[ solution.getLength() ].ruin[x].body_distance
		LET l_tab[ l_tab.getLength() ].site = "GS"||solution[ solution.getLength() ].ruin[x].r_id||" ("||
								solution[ solution.getLength() ].ruin[x].r_type ||")"

		LET l_tab[ l_tab.getLength() ].data = solution[ solution.getLength() ].ruin[x].data.getLength()||" of "||
 					solution[ solution.getLength() ].ruin[x].avail_data.getLength()

		IF l_prev_loc != l_tab[ l_tab.getLength() ].sys THEN
			LET l_sys_cnt = l_sys_cnt + 1
		END IF
		LET l_prev_loc = l_tab[ l_tab.getLength() ].sys
	END FOR
	MESSAGE "Ruins:", l_tab.getLength(), " Systems:",l_sys_cnt, " Data:", solution[ solution.getLength() ].data.getLength()

	LET x = 1
	DIALOG ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY l_tab TO arr.*
			BEFORE ROW
				LET x = arr_curr()
				LET sd = solution[ solution.getLength() ].ruin[x].data
				LET asd = solution[ solution.getLength() ].ruin[x].avail_data
		END DISPLAY
		DISPLAY ARRAY sd TO arr2.*
		END DISPLAY
		DISPLAY ARRAY asd TO arr3.*
		END DISPLAY
		ON ACTION cancel EXIT DIALOG
		ON ACTION quit EXIT DIALOG
	END DIALOG
END FUNCTION
--------------------------------------------------------------------------------
-- dump results to console
FUNCTION dump_results()
	DEFINE r,x,y,l_sys_cnt,l_body_cnt SMALLINT
	DEFINE l_line, l_loc, l_body, l_prev_loc, l_prev_body STRING

	DISPLAY "-------------------------------------------------"
	--CALL solution[ solution.getLength() ].ruin.sort("sys_name",FALSE)

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
		LET l_line = l_line.append("GS"||solution[ solution.getLength() ].ruin[x].r_id)
		FOR y = 1 TO solution[ solution.getLength() ].ruin[x].data.getLength()
			IF y = 1 THEN
				DISPLAY l_line||","||solution[ solution.getLength() ].ruin[x].data[y]
			ELSE
				DISPLAY ",,,",solution[ solution.getLength() ].ruin[x].data[y]
			END IF
		END FOR
	END FOR
	DISPLAY "Found: "||solution[ solution.getLength() ].data.getLength()||" datascans, from "||solution[ solution.getLength() ].ruin.getLength()||" ruin sites, in "||l_sys_cnt||" systems on "||l_body_cnt||" planets."

END FUNCTION
--------------------------------------------------------------------------------
-- process all ruins sites to search for data.
FUNCTION find_data(l_min_data, l_max_dist)
	DEFINE x, r, l_min_data SMALLINT
	DEFINE l_max_dist INTEGER

	FOR r = 1 TO ruins_with_data.getLength()
-- if we got all 101 scans we can stop looking.
		IF solution[ solution.getLength() ].data.getLength() = 101 THEN EXIT FOR END IF

		-- are we skipping this ruins site?
		FOR x = 1 TO processed_ruins.getLength()	
			IF processed_ruins[x] = ruins_with_data[r].r_id THEN CONTINUE FOR END IF
		END FOR

		CALL proc_ruin( ruins_with_data[r].r_id,  ruins_with_data[r].distance_from_gs1, l_min_data, l_max_dist )

	END FOR
END FUNCTION
--------------------------------------------------------------------------------
-- process specific ruin site tto see if it has any needed data.
FUNCTION proc_ruin( r_id, d_from_gs1, l_min_data, l_max_dist )
	DEFINE r_id, l_min_data SMALLINT
	DEFINE d_from_gs1, l_max_dist INTEGER
	DEFINE r_cnt, x SMALLINT
	DEFINE l_data CHAR(20)
	DEFINE other_ruins DYNAMIC ARRAY OF SMALLINT
	DEFINE l_avail_data_arr DYNAMIC ARRAY OF CHAR(20)
	DEFINE l_data_arr DYNAMIC ARRAY OF CHAR(20)
	DEFINE r_rec t_r_rec
--	DISPLAY "Processing from ",r_id

	LET r_cnt = solution[ solution.getLength() ].ruin.getLength()
-- look at the data available at this ruin site and store and new data sets
	FOREACH obe_cur USING r_id INTO l_data
		LET l_avail_data_arr[ l_avail_data_arr.getLength() + 1 ] = l_data
		FOR x = 1 TO solution[ solution.getLength() ].data.getLength()
			IF solution[ solution.getLength() ].data[x] = l_data THEN
				CONTINUE FOREACH
			END IF
		END FOR
		LET l_data_arr[ l_data_arr.getLength() + 1 ] = l_data
	END FOREACH

-- if we got more new data than the min then store the ruin add to solution
	IF l_data_arr.getLength() < l_min_data THEN RETURN END IF

-- get more data about the ruins / body
	OPEN r_cur USING r_id
	FETCH r_cur INTO r_rec.* -- fetch system & body name for this ruin
	CLOSE r_cur

-- Max distance reject it.
	IF r_rec.bodyDistance > l_max_dist THEN
		RETURN
	END IF

	FOR x = 1 TO l_data_arr.getLength() -- store new data
		LET solution[ solution.getLength() ].data[solution[ solution.getLength() ].data.getLength()+1 ] = l_data_arr[x]
	END FOR
	LET r_cnt = r_cnt + 1
	LET solution[ solution.getLength() ].ruin[ r_cnt ].r_id = r_id
	LET solution[ solution.getLength() ].ruin[ r_cnt ].x = r_cnt
&ifdef genero310
	CALL l_data_arr.copyTo(solution[ solution.getLength() ].ruin[ r_cnt ].data )
	CALL l_avail_data_arr.copyTo(solution[ solution.getLength() ].ruin[ r_cnt ].avail_data )
&else
	CALL g300_copyArr( l_data_arr, solution[ solution.getLength() ].ruin[ r_cnt ].data )
	CALL g300_copyArr( l_avail_data_arr, solution[ solution.getLength() ].ruin[ r_cnt ].avail_data )
&endif
	LET processed_ruins[processed_ruins.getLength()+1] = r_id
	LET solution[ solution.getLength() ].ruin[ r_cnt ].r_type = r_rec.ruinTypeName
	LET solution[ solution.getLength() ].ruin[ r_cnt ].body_name = r_rec.body_name
	LET solution[ solution.getLength() ].ruin[ r_cnt ].sys_name = r_rec.system_name
	LET solution[ solution.getLength() ].ruin[ r_cnt ].body_distance = r_rec.bodyDistance
	LET solution[ solution.getLength() ].ruin[ r_cnt ].sys_distance_from_gs1 = d_from_gs1
	DISPLAY r_id," Found ",l_data_arr.getLength()," new scans:",r_rec.system_name
-- since we got data from this ruins - look to see if any more ruins on same body
-- loop through any more ruins at the same system & body
	FOREACH r_cur2 USING r_id, r_rec.system_id, r_rec.body_name INTO r_id
		FOR x = 1 TO processed_ruins.getLength()	
			IF r_id = processed_ruins[x] THEN CONTINUE FOR END IF
		END FOR
		LET other_ruins[ other_ruins.getLength() + 1 ] = r_id
	END FOREACH
	FOR x = 1 TO other_ruins.getLength()
		DISPLAY "Found another ruin on same body:", other_ruins[x]
		CALL proc_ruin( other_ruins[x], d_from_gs1, 1, 0 )
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
-- load my got data - so only find sites for my needed data.
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
FUNCTION g300_copyArr(l_src,l_trg)
	DEFINE l_src, l_trg DYNAMIC ARRAY OF CHAR(20)
	DEFINE x SMALLINT
	FOR x = 1 TO l_src.getLength()
		LET l_trg[x] = l_src[x]
	END FOR
END FUNCTION