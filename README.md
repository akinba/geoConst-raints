# geoConstraits
version : 0.4
##Usage
	CREATE FUNTION https://github.com/akinba/geoConstraits/blob/master/geoConstraits.sql
	
    SELECT geoConstraits( 'tableName',srid, geometryTypeArray[]);

##Exemple

	SELECT geoConstraits( 'geopoi',4326,'{"POINT"}');
  	SELECT geoConstraits( 'parSel',2320,'{"POLYGON","MULTIPOLYGON"}');
