# geoConstraints
version : 0.4
##Usage
	CREATE FUNTION https://github.com/akinba/geoConstraits/blob/master/geoConstraits.sql
	
    SELECT geoConst( 'tableName',srid, geometryTypeArray[]);

##Exemple

	SELECT geoConst( 'geopoi',4326,'{"POINT"}');
  	SELECT geoConst( 'parSel',2320,'{"POLYGON","MULTIPOLYGON"}');
