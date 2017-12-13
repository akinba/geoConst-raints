
  SELECT 'SELECT geoConst('''||table_name||''',32768,array['POLYGON']);' from information_schema.columns
    WHERE table_schema='public' and column_name='poly'
          AND columns.udt_name='geometry' and is_updatable ='YES'
    ORDER BY table_name;


  SELECT DISTINCT st_srid(poly),st_ndims(poly), geometrytype(poly)
    from parcel;

	SELECT geoConst( 'poi', 4326, array['POINT']);
  	SELECT geoConst( 'area',2320, array['POLYGON','MULTIPOLYGON']);