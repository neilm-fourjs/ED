
IMPORT os
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
		distance_from_gs1 INTEGER,
		r_type CHAR(1)
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
DEFINE m_msg STRING
DEFINE m_max_s_distance, m_max_b_distance1, m_max_b_distance2 INTEGER
DEFINE m_loop_from, m_loop_step SMALLINT
DEFINE m_njm_got BOOLEAN
MAIN
	DEFINE l_ruin_id SMALLINT
	DEFINE r,x SMALLINT
	DEFINE r_type CHAR(1)
	DEFINE d INTEGER

	LET m_njm_got = TRUE
	LET m_loop_from = 22
	LET m_loop_step = 2
	LET m_max_s_distance = 5000
	LET m_max_b_distance1 = 800
	LET m_max_b_distance2 = 100000

	OPEN FORM solve FROM "solve"
	DISPLAY FORM solve

	CALL ui_message(FALSE, "Connecting to DB ..." )
-- connect to the database
	CALL db_connect.db_open()

	CALL ui_message(FALSE, "Declaring cursors ..." )
-- declare primary cursors
	DECLARE obe_cur CURSOR FOR SELECT UNIQUE data FROM ruins_data WHERE ruin_id = ? AND data IS NOT NULL ORDER BY data
	DECLARE r_cur CURSOR FOR SELECT ruins.*,system_name FROM ruins, ruins_systems
		WHERE ruin_id = ?
			AND ruins.system_id = ruins_systems.system_id
	DECLARE r_cur2 CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id != ? AND system_id = ? AND body_name = ?
	DECLARE cur CURSOR FOR 
		SELECT ruin_id, distance_from_gs1,ruintypename FROM ruins, ruins_systems
		 WHERE ruin_id < 99990 AND ruins_systems.system_id != 25 
			AND ruins_systems.system_id = ruins.system_id
		ORDER BY distance_from_gs1 

	CALL ui_message(FALSE, "Fetching data ..." )
-- get an array of only ruins with data
	FOREACH cur INTO l_ruin_id, d, r_type
		SELECT COUNT(*) INTO r FROM ruins_data WHERE ruin_id = l_ruin_id AND data IS NOT NULL
		IF r > 0 THEN
			LET ruins_with_data[ ruins_with_data.getLength() + 1 ].r_id = l_ruin_id
			LET ruins_with_data[ ruins_with_data.getLength() ].data_cnt = r
			LET ruins_with_data[ ruins_with_data.getLength() ].r_type = r_type
			IF d IS NULL THEN LET d = 0 END IF
			LET ruins_with_data[ ruins_with_data.getLength() ].distance_from_gs1 = d
		END IF
	END FOREACH
	CALL ruins_with_data.sort('data_cnt',TRUE)
	DISPLAY ruins_with_data.getLength()," Ruins sites with data."

	WHILE NOT int_flag
		CALL processed_ruins.clear()
		CALL solution.clear()
		CALL solution.appendElement()

		IF m_njm_got THEN
			CALL njm_got()
		END IF
	-- process the ruins with data to find all 101 datascans

		FOR x = m_loop_from TO 1 STEP (0 - m_loop_step)
			CALL ui_message(FALSE, SFMT( "Finding solution for %1 ...", x) )
			CALL find_data(x,m_max_b_distance1,"?")
			CALL find_data(x,m_max_b_distance2,"?")
		END FOR
		IF x != 1 THEN
			FOR r = m_loop_step TO 1 STEP -1
				CALL find_data(r,m_max_b_distance1,"?")
				CALL find_data(r,m_max_b_distance2,"?")
			END FOR
		END IF
		{FOR x = 25 TO 1 STEP -4
			CALL ui_message(FALSE, SFMT( "Finding solution for %1 ...", x) )
			CALL find_data(x,m_max_b_distance1,"A")
			CALL find_data(x,m_max_b_distance2,"A")
		END FOR
		FOR x = 25 TO 1 STEP -4
			CALL ui_message(FALSE, SFMT( "Finding solution for %1 ...", x) )
			CALL find_data(x,m_max_b_distance1,"B")
			CALL find_data(x,m_max_b_distance2,"B")
		END FOR
		FOR x = 25 TO 1 STEP -4
			CALL ui_message(FALSE, SFMT( "Finding solution for %1 ...", x) )
			CALL find_data(x,m_max_b_distance1,"G")
			CALL find_data(x,m_max_b_distance2,"G")
		END FOR}
		--CALL dump_results()

		CALL disp_results()
	END WHILE
	DISPLAY "Finished"
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

	MESSAGE "Results:",solution[ solution.getLength() ].ruin.getLength()
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

	IF solution[ solution.getLength() ].data.getLength() < 101 THEN
		CALL ui_message(TRUE, "* NOT SOLVED * - Ruins:"||l_tab.getLength()||" Systems:"||l_sys_cnt||" Data:"||solution[ solution.getLength() ].data.getLength() )
	ELSE
		CALL ui_message(FALSE, "Ruins:"||l_tab.getLength()||" Systems:"||l_sys_cnt||" Data:"||solution[ solution.getLength() ].data.getLength() )
	END IF
	LET x = 1
	LET int_flag = FALSE
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
		INPUT BY NAME m_njm_got,
									m_loop_from, m_loop_step,
									m_max_s_distance,
									m_max_b_distance1, 
									m_max_b_distance2
									ATTRIBUTE(WITHOUT DEFAULTS)
		END INPUT
		ON ACTION redo EXIT DIALOG
		ON ACTION close LET int_flag = TRUE EXIT DIALOG
		ON ACTION quit LET int_flag = TRUE EXIT DIALOG
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
FUNCTION find_data(l_min_data, l_max_b_dist, r_type)
	DEFINE x, r, l_min_data SMALLINT
	DEFINE l_max_b_dist INTEGER
	DEFINE r_type CHAR(1)

	FOR r = 1 TO ruins_with_data.getLength()
-- if we got all 101 scans we can stop looking.
		IF NOT ruins_with_data[r].r_type MATCHES r_type THEN CONTINUE FOR END IF
		IF solution[ solution.getLength() ].data.getLength() = 101 THEN EXIT FOR END IF

		IF ruins_with_data[r].distance_from_gs1 > m_max_s_distance THEN CONTINUE FOR END IF

		-- are we skipping this ruins site?
		FOR x = 1 TO processed_ruins.getLength()	
			IF processed_ruins[x] = ruins_with_data[r].r_id THEN CONTINUE FOR END IF
		END FOR

		IF proc_ruin( ruins_with_data[r].r_id,  ruins_with_data[r].distance_from_gs1, l_min_data, l_max_b_dist ) = 0 THEN
		--	DISPLAY "That didn't work!"
		END IF

	END FOR
END FUNCTION
--------------------------------------------------------------------------------
-- process specific ruin site tto see if it has any needed data.
-- returns the number of new datascans
FUNCTION proc_ruin( r_id, d_from_gs1, l_min_data, l_max_b_dist )
	DEFINE r_id, l_min_data SMALLINT
	DEFINE d_from_gs1, l_max_b_dist INTEGER
	DEFINE r_cnt, x, l_other_scans SMALLINT
	DEFINE l_data CHAR(20)
	DEFINE other_ruins DYNAMIC ARRAY OF SMALLINT
	DEFINE l_avail_data_arr DYNAMIC ARRAY OF CHAR(20)
	DEFINE l_data_arr DYNAMIC ARRAY OF CHAR(20)
	DEFINE r_rec t_r_rec

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
	IF l_data_arr.getLength() < l_min_data THEN RETURN l_data_arr.getLength() END IF
	DISPLAY "Processing Ruins:",r_id, " Distance from GS1=",d_from_gs1, " New Data:",l_data_arr.getLength()

-- get more data about the ruins / body
	OPEN r_cur USING r_id
	FETCH r_cur INTO r_rec.* -- fetch system & body name for this ruin
	CLOSE r_cur
	IF r_rec.bodyDistance IS NULL THEN LET r_rec.bodyDistance = 32000 END IF
-- Max distance reject it.
	IF r_rec.bodyDistance > l_max_b_dist THEN RETURN l_data_arr.getLength() END IF

	FOR x = 1 TO l_data_arr.getLength() -- store new data
		LET solution[ solution.getLength() ].data[solution[ solution.getLength() ].data.getLength()+1 ] = l_data_arr[x]
	END FOR
	LET r_cnt = r_cnt + 1
	LET solution[ solution.getLength() ].ruin[ r_cnt ].r_id = r_id
	LET solution[ solution.getLength() ].ruin[ r_cnt ].x = r_cnt

	CALL l_data_arr.copyTo(solution[ solution.getLength() ].ruin[ r_cnt ].data )
	CALL l_avail_data_arr.copyTo(solution[ solution.getLength() ].ruin[ r_cnt ].avail_data )

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
	LET l_other_scans = 0
	FOR x = 1 TO other_ruins.getLength()
		DISPLAY r_rec.system_name,":Found another ruin on same body:", other_ruins[x]
		LET l_other_scans = l_other_scans + proc_ruin( other_ruins[x], d_from_gs1, 1, 0 )
	END FOR
	IF l_other_scans > 0 THEN
		CALL ui_message(FALSE, SFMT("System '%1' has '%2' other sites with '%3' needed scans",r_rec.system_name, other_ruins.getLength(), l_other_scans ) )
	END IF
	RETURN l_data_arr.getLength()
END FUNCTION
--------------------------------------------------------------------------------
-- load my got data - so only find sites for my needed data.
FUNCTION njm_got()
	DEFINE c base.Channel
	DEFINE l_file STRING
	LET l_file = "../etc/njm_got.txt"
	IF os.path.exists( l_file ) THEN
		CALL ui_message(FALSE, SFMT("Processing %1",l_file) )
		LET c = base.Channel.create()
		CALL c.openFile( l_file,"r")
		WHILE  NOT c.isEof()
			LET solution[ 1 ].data[  solution[ 1 ].data.getLength() + 1 ] = c.readLine()
		END WHILE
		CALL c.close()
	ELSE
		LET m_njm_got = FALSE
		CALL ui_message(FALSE, SFMT("Not found %1",l_file) )
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION ui_message(l_err BOOLEAN, l_mess STRING )
	DISPLAY l_mess
	IF l_err THEN
		ERROR l_mess
	ELSE
		MESSAGE l_mess
	END IF
	LET m_msg = m_msg.append( CURRENT||":"||l_mess||"\n" )
	DISPLAY m_msg TO msg
	CALL ui.Interface.refresh()
END FUNCTION