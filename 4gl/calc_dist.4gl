IMPORT util
FUNCTION calc_distance(x,y,z, r_id)
	DEFINE x,y,z DECIMAL(10,4)
	DEFINE r_id INTEGER
	DEFINE f_x,f_y,f_Z DECIMAL(10,4)
	DEFINE d INTEGER
	
	SELECT edsmCoordX, edsmCoordY, edsmCoordZ
		INTO f_x,f_y,f_Z
		FROM ruins_systems, ruins WHERE ruin_id = r_id AND ruins_systems.system_id = ruins.system_id
{
	DISPLAY "X,",x," from gs"||r_id||" X:",f_x
	DISPLAY "Y,",y," from gs"||r_id||" Y:",f_y
	DISPLAY "Z,",z," from gs"||r_id||" Z:",f_z
}
	LET d = util.Math.sqrt( ((x - f_x)*((x - f_x))) + ((y - f_y)*(y - f_y)) + ((z - f_z)*(z - f_z))) 
	IF d IS NULL THEN LET d = 0 END IF
	RETURN d
END FUNCTION