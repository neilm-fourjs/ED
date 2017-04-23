
IMPORT com
IMPORT util

MAIN
	DEFINE l_ruin_id INTEGER
	DEFINE l_db STRING

	LET l_db = "ed+driver='dbmsqt',source='ed.db'"
	TRY
  	DATABASE l_db
	CATCH
		DISPLAY "Failed to connect to db:",l_db,"\n"||STATUS,"-",SQLERRMESSAGE
		EXIT PROGRAM	
	END TRY

{	CALL drops()
	CALL creates()
	CALL load1()
	CALL load2()}

{
	DROP TABLE ruins_data
	CREATE TABLE ruins_data (
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		active SMALLINT,
		data CHAR(20)
	)
}
	DECLARE cur CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id < 99990 ORDER BY ruin_id 
	FOREACH cur INTO l_ruin_id	
		CALL load3(l_ruin_id)
	END FOREACH
	
END MAIN
--------------------------------------------------------------------------------
FUNCTION load3(l_ruin_id)
	DEFINE l_ruin_id INTEGER
	DEFINE l_url STRING
	DEFINE l_req com.HttpRequest
	DEFINE l_res com.HttpResponse
--	DEFINE c base.channel
	DEFINE jo, jo2 util.JSONObject
	DEFINE z,x SMALLINT
	DEFINE r_data RECORD
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		active SMALLINT,
		data CHAR(20)
	END RECORD

--	LET c = base.channel.create()	
--	CALL c.openFile("ruins44.json","r")
--	LET jo = util.JSONObject.parse(c.readLine())
--	CALL c.close()

	SELECT COUNT(*) INTO x FROM ruins_data WHERE ruin_id = l_ruin_id
	IF x > 0 THEN
		DISPLAY "Already some data for Ruin:"||l_ruin_id,":",x
		RETURN
	END IF

	DISPLAY "Getting data for Ruin:"||l_ruin_id
	LET l_url = "https://api.canonn.technology/api/v1/maps/ruininfo/"||l_ruin_id
	LET l_req = com.HttpRequest.Create(l_url)
	CALL l_req.setHeader("Content-Type","application/json")
	CALL l_req.setHeader("Accept-Encoding","gzip, deflate")
	CALL l_req.setMethod("GET")
	TRY
		CALL l_req.doRequest()
	CATCH
		IF STATUS != 0 THEN
			DISPLAY "doRequest status="||STATUS||" "||err_get(STATUS)
			RETURN
		END IF
	END TRY

	LET l_res = l_req.getResponse()
	LET jo = util.JSONObject.parse( l_res.getTextResponse() )

	LET r_data.ruin_id = l_ruin_id
	LET r_data.ruinTypeName = downshift(jo.get("ruinTypeName"))

	LET jo = jo.get( "obelisks" )

	FOR z = 1 TO jo.getLength()
		LET r_data.groupName = jo.name(z)
		LET jo2 = jo.get( jo.name(z) )
		FOR x = 1 TO jo2.getLength()
			LET r_data.obelisk_no = jo2.name(x)
			LET r_data.active = jo2.get( jo2.name(x) )
			LET r_data.data = NULL
			IF r_data.active = 1 THEN

				SELECT data INTO r_data.data FROM scan_data
    			WHERE ruinTypeName = r_data.ruinTypeName
    				AND groupName = r_data.groupName
    				AND obelisk_no = r_data.obelisk_no
				INSERT INTO ruins_data VALUES(r_data.*)
			END IF
		END FOR
		IF jo2.getLength() > 0 THEN
			DISPLAY "r_data:", jo2.getLength()
		END IF
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load2()
	DEFINE c base.channel
	DEFINE jo, jo2, jo3, jo4 util.JSONObject
	DEFINE ja util.JSONArray
	DEFINE z,x,y SMALLINT
	DEFINE scandata DYNAMIC ARRAY OF RECORD
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		data CHAR(20),
		item_1 CHAR(10),
		item_2 CHAR(10)
	END RECORD

	LET c = base.channel.create()	
	CALL c.openFile("scandata.json","r")
	LET jo = util.JSONObject.parse(c.readLine())
	CALL c.close()

	FOR z = 1 TO jo.getLength()
		LET jo2 = jo.get( jo.name(z) )
		FOR x = 1 TO jo2.getLength()
			LET jo3 = jo2.get( jo2.name(x) )
			FOR y = 1 TO jo3.getLength()
				LET jo4 = jo3.get( jo3.name(y) )
				CALL scandata.appendElement()
				LET scandata[ scandata.getLength() ].ruinTypeName = jo.name(z)
				LET scandata[ scandata.getLength() ].groupName = jo2.name(x)
				LET scandata[ scandata.getLength() ].obelisk_no = jo3.name(y)
				LET scandata[ scandata.getLength() ].data = jo4.get("scan")
				LET ja = jo4.get("items")
				IF ja IS NOT NULL THEN
					LET scandata[ scandata.getLength() ].item_1 = ja.get(1)
					LET scandata[ scandata.getLength() ].item_2 = ja.get(2)
				END IF
				DISPLAY scandata[ scandata.getLength() ].ruinTypeName,":",scandata[ scandata.getLength() ].groupName,scandata[ scandata.getLength() ].obelisk_no USING "<<","=",scandata[ scandata.getLength() ].data," Item1:",scandata[ scandata.getLength() ].item_1, " Item2:",scandata[ scandata.getLength() ].item_2
				INSERT INTO scan_data VALUES( scandata[ scandata.getLength() ].* )
			END FOR
		END FOR
	END FOR
	DISPLAY "ScanData:",scandata.getLength()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load1()
	DEFINE c base.channel
	DEFINE x,y SMALLINT

	DEFINE systems DYNAMIC ARRAY OF RECORD
		systemId INTEGER,
		systemName STRING,
		ruins DYNAMIC ARRAY OF RECORD
			ruinId INTEGER,
			bodyName STRING,
			ruinTypeName STRING,
			coordinates DYNAMIC ARRAY OF DECIMAL(7,4)
		END RECORD
	END RECORD
	DEFINE r_sys RECORD
		system_id INTEGER,
		system_name VARCHAR(60)
	END RECORD
	DEFINE rs RECORD
		system_id INTEGER,
		body_name VARCHAR(10),
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		coor_long DECIMAL(8,4),
		coor_lat DECIMAL(8,4)
	END RECORD
	DEFINE max_sys SMALLINT

	LET max_sys = 10
	LET c = base.channel.create()	
	CALL c.openFile("systemoverview.json","r")
	CALL util.JSON.parse( c.readLine(), systems )	
	CALL c.close()

	DISPLAY "Systems:",systems.getLength()

	DELETE FROM ruins_systems
	DELETE FROM ruins

	FOR x = 1 TO systems.getLength()
		LET r_sys.system_id = systems[x].systemId
		LET r_sys.system_name = systems[x].systemName
		IF systems[x].systemName.getLength() > max_sys THEN LET max_sys = systems[x].systemName.getLength() END IF
		INSERT INTO ruins_systems VALUES(r_sys.*)
		FOR y = 1 TO systems[x].ruins.getLength()
			LET rs.system_id = r_sys.system_id
			LET rs.body_name = systems[x].ruins[y].bodyName
			LET rs.ruin_id = systems[x].ruins[y].ruinId
			LET rs.ruinTypeName = systems[x].ruins[y].ruinTypeName
			LET rs.coor_long = systems[x].ruins[y].coordinates[1]
			LET rs.coor_lat = systems[x].ruins[y].coordinates[2]
			DISPLAY "RuinID:",rs.ruin_id," Coor:",systems[x].ruins[y].coordinates.getLength()," :",rs.coor_long,",",rs.coor_lat
			INSERT INTO ruins VALUES(rs.*)
		END FOR
	END FOR
	DISPLAY "Max System:",max_sys
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION drops()

	TRY
		DROP TABLE ruins_systems
	CATCH
	END TRY

	TRY
		DROP TABLE ruins
	CATCH
	END TRY

	TRY
		DROP TABLE scan_data
	CATCH
	END TRY

	TRY
		DROP TABLE user_data
	CATCH
	END TRY
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION creates()

	CREATE TABLE ruins_systems (
		system_id INTEGER,
		system_name VARCHAR(60)
	)
	CREATE TABLE ruins (
		system_id INTEGER,
		body_name VARCHAR(10),
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		coor_long DECIMAL(8,4),
		coor_lat DECIMAL(8,4)
	)
	CREATE TABLE scan_data (
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		data CHAR(20),
		item_1 CHAR(10),	
		item_2 CHAR(10)
	)
	CREATE TABLE user_data (
		user_id INTEGER,
		ruin_id INTEGER,	
		groupName CHAR(1),
		obelisk_no SMALLINT,
		data CHAR(20)
	)
END FUNCTION
