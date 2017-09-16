IMPORT os

PUBLIC DEFINE m_msg STRING
--------------------------------------------------------------------------------
FUNCTION db_open()
	DEFINE l_stat INTEGER
	DEFINE l_msg STRING
	CALL openDB("../db/ed.db") RETURNING l_stat, l_msg
	IF l_stat != 0 THEN
		CALL fgl_winMessage("Failed","Database open failed!\n"||l_stat||"-"||l_msg,"exclamation")
		EXIT PROGRAM
	END IF
END FUNCTION

FUNCTION openDB( l_dbname )
	DEFINE l_dbname, l_dbpath STRING
	DEFINE l_msg STRING
	DEFINE l_created BOOLEAN
	LET l_dbpath = os.path.join( os.path.pwd(), l_dbname )

	LET l_created = FALSE
-- does final path db exist
	IF NOT os.path.exists( l_dbpath ) THEN
		LET l_msg = "db missing, "
--  does a local db exist here
		IF NOT os.path.exists( l_dbname ) THEN
--    create a new local db
			TRY
				CREATE DATABASE l_dbname
				LET l_msg = l_msg.append( "created, " )
			CATCH
				RETURN STATUS, l_msg||SQLERRMESSAGE
			END TRY
			LET l_created = TRUE
		ELSE
--    copy an existing db to the final db path
			IF os.path.copy( os.path.join( base.Application.getProgramDir(),l_dbname ), os.path.pwd() ) THEN
				LET l_msg = l_msg.append("Copied ")
			ELSE
				LET l_msg = l_msg.append("Copy failed! ")
				RETURN STATUS, l_msg||ERR_GET(STATUS)
			END IF
		END IF
	ELSE
		LET l_msg = "db exists, "
	END IF

-- connect to final path db
	TRY
		DATABASE l_dbpath
		LET l_msg = l_msg.append("Connected okay.")
	CATCH
		RETURN STATUS, l_msg||SQLERRMESSAGE
	END TRY

--	IF l_created THEN LET l_msg = l_msg.append( db_add_tables() ) END IF

	RETURN 0,l_msg
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