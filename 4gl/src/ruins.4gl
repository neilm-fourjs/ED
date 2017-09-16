
IMPORT com
IMPORT util
IMPORT FGL db_connect

MAIN

	CALL db_connect.db_open()

	IF ARG_VAL(1) = "redo" THEN
		IF fgl_winQuestion("Confirm",
			"Are you sure you want to recreate all tables & data","No","Yes|No",
			"question",0) = "No" THEN
			EXIT PROGRAM
		END IF
		CALL load_bodies()
		CALL load_ruins()
		CALL load_systems()
		CALL load_scandata()
	END IF

	CALL load_ruinsdata()

END MAIN
--------------------------------------------------------------------------------
FUNCTION load_ruinsdata()
	DEFINE l_ruin_id INTEGER

	IF ARG_VAL(1) = "redo" OR ARG_VAL(1) = "justdata" THEN
		TRY
			DROP TABLE ruins_data
		CATCH
		END TRY
		CREATE TABLE ruins_data (
			ruin_id INTEGER,
			ruinTypeName CHAR(5),
			groupName CHAR(1),
			obelisk_no SMALLINT,
			active SMALLINT,
			data CHAR(20)
		)
	END IF

	DECLARE cur CURSOR FOR SELECT ruin_id FROM ruins WHERE ruin_id < 99990 ORDER BY ruin_id 
	FOREACH cur INTO l_ruin_id	
		CALL load_ruinsdata2(l_ruin_id)
	END FOREACH
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_ruinsdata2(l_ruin_id)
	DEFINE l_ruin_id INTEGER
	DEFINE l_url STRING
	DEFINE l_req com.HttpRequest
	DEFINE l_res com.HttpResponse
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
FUNCTION load_scandata()
	DEFINE c base.channel
	DEFINE jo, jo2, jo3, jo4 util.JSONObject
	DEFINE ja util.JSONArray
	DEFINE z,x,y SMALLINT
	DEFINE scandata DYNAMIC ARRAY OF RECORD
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		isVerified SMALLINT,
		data CHAR(20),
		item_1 CHAR(10),
		item_2 CHAR(10),
		score SMALLINT
	END RECORD

	TRY
		DROP TABLE scan_data
	CATCH
	END TRY
	CREATE TABLE scan_data (
		ruinTypeName CHAR(5),
		groupName CHAR(1),
		obelisk_no SMALLINT,
		isVerified SMALLINT,
		data CHAR(20),
		item_1 CHAR(10),	
		item_2 CHAR(10),
		score SMALLINT
	)

	LET c = base.channel.create()	
	CALL c.openFile("../json/scandata.json","r")
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
				LET scandata[ scandata.getLength() ].isVerified = jo4.get("isVerified")
				LET ja = jo4.get("items")
				IF ja IS NOT NULL THEN
					LET scandata[ scandata.getLength() ].item_1 = ja.get(1)
					LET scandata[ scandata.getLength() ].item_2 = ja.get(2)
				END IF
				LET scandata[ scandata.getLength() ].score = 0
				DISPLAY scandata[ scandata.getLength() ].ruinTypeName,":",scandata[ scandata.getLength() ].groupName,scandata[ scandata.getLength() ].obelisk_no USING "<<","=",scandata[ scandata.getLength() ].data," Item1:",scandata[ scandata.getLength() ].item_1, " Item2:",scandata[ scandata.getLength() ].item_2
				INSERT INTO scan_data VALUES( scandata[ scandata.getLength() ].* )
			END FOR
		END FOR
	END FOR
	DISPLAY "ScanData:",scandata.getLength()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_systems()
	DEFINE c base.channel
	DEFINE x SMALLINT
	DEFINE systems DYNAMIC ARRAY OF RECORD
		id INTEGER,
		name STRING,
		distance_from_gs1 INTEGER,
		edsmCoordX DECIMAL(9,4),
		edsmCoordY DECIMAL(9,4),
		edsmCoordZ DECIMAL(9,4)
	END RECORD
	DEFINE max_sys SMALLINT

	TRY
		DROP TABLE ruins_systems
	CATCH
	END TRY
	CREATE TABLE ruins_systems (
		system_id INTEGER,
		system_name VARCHAR(40),
		distance_from_gs1 INTEGER,
		edsmCoordX DECIMAL(9,4),
		edsmCoordY DECIMAL(9,4),
		edsmCoordZ DECIMAL(9,4)
	)

	LET max_sys = 10
	LET c = base.channel.create()	
	CALL c.openFile("../json/stellar.json","r")
	CALL util.JSON.parse( c.readLine(), systems )	
	CALL c.close()

	DISPLAY "Systems:",systems.getLength()
	FOR x = 1 TO systems.getLength()
		LET systems[x].distance_from_gs1 = calc_distance(systems[x].edsmCoordX, systems[x].edsmCoordY, systems[x].edsmCoordY, 1)
		IF systems[x].name.getLength() > max_sys THEN LET max_sys = systems[x].name.getLength() END IF
		INSERT INTO ruins_systems VALUES(systems[x].*)
	END FOR
	DISPLAY "Max System Name:",max_sys
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_bodies()
	DEFINE c base.channel
	DEFINE x SMALLINT
	DEFINE bodies DYNAMIC ARRAY OF RECORD
		id INTEGER,
		name STRING,
    systemId INTEGER,
		distance INTEGER
	END RECORD
	DEFINE max_b SMALLINT

	TRY
		DROP TABLE ruins_bodies
	CATCH
	END TRY
	CREATE TABLE ruins_bodies (
		body_id INTEGER,
		body_name VARCHAR(20),
    system_id INTEGER,
		distance INTEGER
	)

	LET max_b = 1
	LET c = base.channel.create()	
	CALL c.openFile("../json/bodies.json","r")
	CALL util.JSON.parse( c.readLine(), bodies )	
	CALL c.close()

	DISPLAY "Bodies:",bodies.getLength()
	FOR x = 1 TO bodies.getLength()
		IF bodies[x].name.getLength() > max_b THEN LET max_b = bodies[x].name.getLength() END IF
		INSERT INTO ruins_bodies VALUES(bodies[x].*)
	END FOR
	DISPLAY "Max Body Name:",max_b
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_ruins()
	DEFINE c base.channel
	DEFINE x,y SMALLINT

	DEFINE systems DYNAMIC ARRAY OF RECORD
		systemId INTEGER,
		systemName STRING,
		ruins DYNAMIC ARRAY OF RECORD
			ruinId INTEGER,
			bodyName STRING,
			bodyId INTEGER,
			ruinTypeName STRING,
			coordinates DYNAMIC ARRAY OF DECIMAL(7,4)
		END RECORD
	END RECORD

	DEFINE rs RECORD
		system_id INTEGER,
		body_name VARCHAR(10),
		bodyDistance INTEGER,
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		coor_long DECIMAL(8,4),
		coor_lat DECIMAL(8,4),
		data_cnt SMALLINT,
		score SMALLINT,
		ignore SMALLINT,
		data VARCHAR(100)
	END RECORD

	TRY
		DROP TABLE ruins
	CATCH
	END TRY
	CREATE TABLE ruins (
		system_id INTEGER,
		body_name VARCHAR(10),
		bodyDistance INTEGER,
		ruin_id INTEGER,
		ruinTypeName CHAR(5),
		coor_long DECIMAL(8,4),
		coor_lat DECIMAL(8,4),
		data_cnt SMALLINT,
		score SMALLINT,
		ignore SMALLINT,
		data VARCHAR(100)
	)

	LET c = base.channel.create()	
	CALL c.openFile("../json/systemoverview.json","r")
	CALL util.JSON.parse( c.readLine(), systems )	
	CALL c.close()

	FOR x = 1 TO systems.getLength()
		FOR y = 1 TO systems[x].ruins.getLength()
			LET rs.system_id = systems[x].systemId
			LET rs.body_name = systems[x].ruins[y].bodyName
			LET rs.ruin_id = systems[x].ruins[y].ruinId
			LET rs.ruinTypeName = systems[x].ruins[y].ruinTypeName
			LET rs.coor_long = systems[x].ruins[y].coordinates[1]
			LET rs.coor_lat = systems[x].ruins[y].coordinates[2]
			LET rs.bodyDistance = 0
			LET rs.score = 0
			LET rs.data_cnt = 0
			LET rs.ignore = FALSE
			LET rs.data = NULL
			SELECT distance INTO rs.bodyDistance FROM ruins_bodies
			 WHERE ruins_bodies.system_id = rs.system_id
				AND ruins_bodies.body_name = rs.body_name
			DISPLAY "RuinID:",rs.ruin_id," Coor:",systems[x].ruins[y].coordinates.getLength()," :",rs.coor_long,",",rs.coor_lat
			INSERT INTO ruins VALUES(rs.*)
		END FOR
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION user_data()

	TRY
		DROP TABLE scan_data
	CATCH
	END TRY

	CREATE TABLE user_data (
		user_id INTEGER,
		ruin_id INTEGER,	
		groupName CHAR(1),
		obelisk_no SMALLINT,
		data CHAR(20)
	)
END FUNCTION
