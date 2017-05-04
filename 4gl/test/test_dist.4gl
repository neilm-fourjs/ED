IMPORT FGL db_connect
MAIN

	CALL db_connect.db_open()

	DISPLAY calc_distance(118.78125 , -56.4375 , -97.1875, 1) -- meene to gs1

END MAIN