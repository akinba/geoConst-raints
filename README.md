# GeoConstraints
version : 0.4
##Usage
	CREATE FUNTION https://github.com/akinba/geoConstraits/blob/master/geoConst.sql
	
    SELECT geoConst( 'tableName',srid, geometryTypeArray[]);

##Exemple

	SELECT geoConst( 'poi', 4326, array['POINT']);
  	SELECT geoConst( 'area',2320, array['POLYGON','MULTIPOLYGON']);
