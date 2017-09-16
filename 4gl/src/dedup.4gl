
IMPORT FGL db_connect

MAIN
	DEFINE l_ruin_id, x, y SMALLINT
	DEFINE r_type CHAR(1)
	DEFINE d_gs1 INTEGER
	DEFINE l_data CHAR(20)
	DEFINE l_data_str,l_prev_str STRING
	DEFINE l_ignore BOOLEAN

	OPEN FORM dedup FROM "dedup"
	DISPLAY FORM dedup

	CALL ui_message(FALSE, "Connecting to DB ..." )
-- connect to the database
	CALL db_connect.db_open()

	CALL ui_message(FALSE, "Declaring cursors ..." )
-- declare primary cursors
	DECLARE obe_cur CURSOR FOR 
		SELECT UNIQUE data FROM ruins_data 
			WHERE ruin_id = ? AND data IS NOT NULL ORDER BY data

	TRY
		CALL ui_message(FALSE,"Creating ruins_data index ...")
		CREATE INDEX rd_id ON ruins_data ( ruin_id )
	CATCH
		CALL ui_message(FALSE,"NOT Creating ruins_data index ...")
	END TRY
	TRY
		CALL ui_message(FALSE,"Creating ruins_systems index ...")
		CREATE INDEX rs_id ON ruins_systems ( system_id )
	CATCH
		CALL ui_message(FALSE,"NOT Creating ruins_systems index ...")
	END TRY

	DECLARE m_cur CURSOR FOR 
		SELECT ruin_id, distance_from_gs1 FROM ruins, ruins_systems
		 WHERE ruin_id < 99990
			AND ruins_systems.system_id = ruins.system_id
			AND ruins.ignore = 0
			AND ruins.data_cnt = 0
		ORDER BY distance_from_gs1 

	CALL ui_message(FALSE, "Fetching data #1 ..." )
-- get an array of only ruins with data
	LET x = 1
	FOREACH m_cur INTO l_ruin_id, d_gs1
		LET l_data_str = ""
		LET y = 0
		LET l_ignore = FALSE
		IF d_gs1 > 1500 THEN
			LET l_ignore = TRUE
		END IF
		FOREACH obe_cur USING l_ruin_id INTO l_data
			LET y = y + 1
			LET l_data_str = l_data_Str.append( comp_data( l_data CLIPPED )||":" )
		END FOREACH
		IF y > 0 THEN
			DISPLAY x,":",y,":",l_ruin_id,":",l_data_str,":",l_data_str.getLength()
		ELSE
			LET l_ignore = TRUE
		END IF
		UPDATE ruins SET (ignore,data,data_cnt) = (l_ignore,l_data_str,y)  WHERE ruin_id = l_ruin_id
		LET x = x + 1
	END FOREACH

	CALL ui_message(FALSE, "Fetching data #2 ..." )
	DECLARE m_cur2 CURSOR FOR 
		SELECT ruin_id, distance_from_gs1,ruintypename,data FROM ruins, ruins_systems
		 WHERE ruin_id < 99990
			AND ruins_systems.system_id = ruins.system_id
			AND ruins.ignore = 0
			AND ruins.data_cnt > 0
		ORDER BY data
	LET l_prev_str = "."
	FOREACH m_cur2 INTO l_ruin_id, d_gs1, r_type, l_data_str
		IF l_prev_str != l_data_str THEN
			DISPLAY x,":",l_ruin_id,":",l_data_str,":",l_data_str.getLength()
			LET x = x + 1
		END IF
		LET l_prev_str = l_data_str
	END FOREACH
END MAIN
--------------------------------------------------------------------------------
FUNCTION comp_data( l_data STRING )
	DEFINE x SMALLINT
	LET x = l_data.getIndexOf(" ",1)
	RETURN l_data.getCharAt(1)||l_data.subString(x+1,l_data.getLength())
END FUNCTION
