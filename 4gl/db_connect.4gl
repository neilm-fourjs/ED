
FUNCTION db_con()
	DEFINE l_db STRING

	LET l_db = "ed+driver='dbmsqt',source='ed.db'"
	TRY
  	DATABASE l_db
	CATCH
		DISPLAY "Failed to connect to db:",l_db,"\n"||STATUS,"-",SQLERRMESSAGE
		EXIT PROGRAM	
	END TRY
END FUNCTION