
  SELECT 'SELECT geoConstraits('''||table_name||''',32768,''{"GEOMETRY"}'');' from information_schema.columns
    WHERE table_schema='public' and column_name='poly'
          AND columns.udt_name='geometry' and is_updatable ='YES'
    ORDER BY table_name;


  SELECT DISTINCT st_srid(poly),st_ndims(poly), geometrytype(poly)
    from parcel;

  SELECT geoConstraits( 'geopoi',32768,'{"POINT"}');
  SELECT geoConstraits( 'parcel,32768,'{"POLYGON","MULTIPOLYGON"}');