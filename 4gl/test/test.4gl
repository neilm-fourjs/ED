
CONSTANT C_MAX=4

TYPE t_item CHAR(1)
DEFINE data DYNAMIC ARRAY OF t_item
DEFINE m_i, m_loop, m_combo INTEGER
DEFINE m_combos DYNAMIC ARRAY OF STRING
DEFINE m_combos_x DYNAMIC ARRAY OF INTEGER
MAIN
	DEFINE x SMALLINT
	FOR x = 1 TO C_MAX
		LET data[x] = ASCII(64+x)
	END FOR

	LET m_combo = data.getLength()
	CALL combos( data.getLength() )
	DISPLAY "Combos:",m_combo

	LET m_i = 0
	CALL show_arr()
	CALL do_loop( data.getLength() )

	DISPLAY "-------------------"
	FOR x = 1 TO m_combos.getLength()
		DISPLAY x," ",m_combos[x]," ",m_combos_x[x]
	END FOR

END MAIN
--------------------------------------------------------------------------------
FUNCTION do_loop(x)
	DEFINE x, y SMALLINT
	IF x = 0 THEN RETURN END IF
	LET m_loop = x

	FOR y = 1 TO data.getLength()
		CALL do_loop(x-1)
		IF x != m_loop THEN CALL swap(y) END IF
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION combos(x)
	DEFINE x INTEGER
	IF x = 1 THEN RETURN END IF
	LET m_combo = m_combo * (x-1)
	CALL combos(x-1)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION show_arr()
	DEFINE l_res STRING
	DEFINE x INTEGER
	LET l_res = ""
	FOR x = 1 TO data.getLength()
		LET l_res = l_res.append( data[x] )
	END FOR

	LET m_i = m_i + 1
	DISPLAY l_res," - ", m_i
	FOR x = 1 TO m_combos.getLength()
		IF m_combos[x] = l_res THEN RETURN END IF
	END FOR
	LET m_combos_x[x] = m_i
	LET m_combos[x] = l_res

--	IF m_i = 24 THEN 
--		DISPLAY "At target, exit program"
--		EXIT PROGRAM 
--	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION swap(x)
	DEFINE x,y SMALLINT
	DEFINE item t_item
	IF x > data.getLength() THEN LET x = 1 END IF
	LET y = x + 1
	IF y > data.getLength() THEN LET y = 1 END IF
--	DISPLAY x,",",y
	LET item = data[x]
	IF x > C_MAX THEN 
		DISPLAY "Error, abort!"
		EXIT PROGRAM
	END IF
	LET data[x] = data[y]
	LET data[y] = item
	CALL show_arr()	
END FUNCTION
--------------------------------------------------------------------------------
