--===========================================
  SELECT 'SELECT geoConstraits('''||table_name||''',32768,''GEOMETRY'');' from information_schema.columns
    WHERE table_schema='public' and column_name='poly'
          AND columns.udt_name='geometry'
    ORDER BY table_name;
          --and data_type='bytea'


  SELECT DISTINCT st_srid(poly),st_ndims(poly), geometrytype(poly)
    from ulke_pafta_1000;

  update ulke_pafta_1000 set poly= st_setsrid(poly,32768);

  SELECT DISTINCT st_srid(poly),st_ndims(poly), geometrytype(poly)
    from ulke_pafta_5000;

  update ulke_pafta_5000 set poly= st_setsrid(poly,32768);


  --=========================================== v0.1
    DROP FUNCTION public.geoconstraits(TEXT,INTEGER,TEXT );
    CREATE OR REPLACE FUNCTION geoConstraits(  TEXT,INTEGER,TEXT )
       RETURNS VOID  AS $$

  BEGIN
    --unique
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS '||$1||'_objectid_uniq;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT '||$1||'_objectid_uniq UNIQUE(objectid);';
   --bbox
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_bbox_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_bbox_poly
    CHECK (st_intersects(st_pointonsurface(poly),
           st_makeenvelope(0::double precision,
                           4000000::double precision,
                           600000::double precision,
                           5000000::double precision, '||$2||')) = true);';
    --ndims
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_dims_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_dims_poly CHECK (st_ndims(poly) = 2);';
    --srid
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_srid_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_srid_poly CHECK (st_srid(poly) ='||$2||');';
    --gtype
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_gtype_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) ='''||$3||''');';
    --isvalid
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_isvalid_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_isvalid_poly CHECK (st_isvalid(poly) = true);';
  END

    $$  LANGUAGE plpgsql   ;


  SELECT geoConstraits( 'ada',32768,'POINT');


--=========================================== v0.2
  DROP FUNCTION public.geoconstraits(TEXT,INTEGER,TEXT[] );

  CREATE OR REPLACE FUNCTION public.geoConstraits(text, integer, text[])
    RETURNS void AS
  $BODY$
  DECLARE r RECORD;
  BEGIN

    --drop all Constraits for POLY
    FOR r IN SELECT constraint_name
      FROM information_schema.constraint_column_usage WHERE table_name=quote_ident($1) and column_name='poly'
    LOOP
      EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS '||r.constraint_name||';';
    END LOOP;

    --unique
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS '||$1||'_objectid_uniq;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT '||$1||'_objectid_uniq UNIQUE(objectid);';
   --bbox
    --EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_bbox_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_bbox_poly
    CHECK (st_intersects(st_pointonsurface(poly),
           st_makeenvelope(0::double precision, 4000000::double precision,  600000::double precision,  5000000::double precision, '||$2||')) = true);';
    --ndims
    --EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_dims_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_dims_poly CHECK (st_ndims(poly) = 2);';
    --srid
    --EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_srid_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_srid_poly CHECK (st_srid(poly) ='||$2||');';
    --gtype
    --EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_gtype_poly;';
    IF array_length($3,1)=1 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||'''));';
      ELSEIF array_length($3,1)=2 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||''','''||$3[2]||'''));';
      ELSEIF array_length($3,1)=3 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||''','''||$3[2]||''','''||$3[3]||'''));';
        END IF ;
    --isvalid
    --EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS enforce_isvalid_poly;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_isvalid_poly CHECK (st_isvalid(poly) = true);';
  END

    $BODY$
    LANGUAGE plpgsql;
  COMMENT ON FUNCTION public.geoconstraits(text, integer, text[]) IS '[BSA] v0.2';




  SELECT 'SELECT geoConstraits('''||table_name||''',32768,''{"GEOMETRY"}'');' from information_schema.columns
    WHERE table_schema='public' and column_name='poly'
          AND columns.udt_name='geometry' and is_updatable ='YES'
    ORDER BY table_name;


    SELECT geoConstraits( 'ada',32768,'{"POINT"}');
  SELECT geoConstraits( 'parsel_fonksiyon',32768,'{"POLYGON","MULTIPOLYGON"}');



--=========================================== v0.3
  
  DROP  FUNCTION geosrid(text);

      CREATE OR REPLACE FUNCTION public.geosrid(text)
      returns integer as 
      $$
      DECLARE a integer;
      BEGIN
      execute 'select distinct st_srid(poly)  from '||$1||' where poly is not null;' into a;
      return a;
      END
      $$
      LANGUAGE plpgsql;


  DROP FUNCTION public.geoconstraits(TEXT,INTEGER,TEXT[] );

  CREATE OR REPLACE FUNCTION public.geoConstraits(text, integer, text[])
    RETURNS text AS
  $BODY$
  DECLARE r RECORD;
  BEGIN

    --check inputs
    CASE
  WHEN $1 not  in (select tablename::text from pg_tables where schemaname=current_schema())
    then return 'Hata= Girdiginiz tablo ismi:'||$1||' veri tabanında yok!'; 
  WHEN 'poly' != (select column_name FROM information_schema.columns WHERE table_schema =  current_schema() AND table_name = 'ada' AND data_type = 'USER-DEFINED')
    then return 'Hata= Girdiğiniz '||$1||' tablo su geometrik değil veya poly kolonu yok';
  WHEN $2 not in (select srid from spatial_ref_sys)
    then return 'Hata= Girdiginiz SRID:'||$2||' public.spatial_ref_sys tablosunda bulunmuyor!';
  WHEN $2 != (select geosrid($1))
    then return 'Hata= Girdiğiniz SRID:'||$2||','||$1||' tablosunun SRID:'||(select geosrid($1))||' ile uyuşmuyor!';
  WHEN array_length($3,1)>3
    then return 'Hata= En fazla 3 adet geometri tipi belirtebilirsiniz!';
  ELSE

    --drop all Constraits for POLY
    FOR r IN SELECT constraint_name
      FROM information_schema.constraint_column_usage WHERE table_name=quote_ident($1) and column_name='poly'
    LOOP
      EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS "'||r.constraint_name||'" ;';
    END LOOP;

    --unique
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS '||$1||'_objectid_uniq;';
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT '||$1||'_objectid_uniq UNIQUE(objectid);';
   --bbox
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_bbox_poly CHECK (st_intersects(st_pointonsurface(poly),st_makeenvelope(0::double precision, 4000000::double precision,  600000::double precision,  5000000::double precision, '||$2||')) = true);';
    --ndims
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_dims_poly CHECK (st_ndims(poly) = 2);';
    --srid
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_srid_poly CHECK (st_srid(poly) ='||$2||');';
    --gtype
    IF array_length($3,1)=1 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||'''));';
      ELSEIF array_length($3,1)=2 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||''','''||$3[2]||'''));';
      ELSEIF array_length($3,1)=3 THEN
        EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_gtype_poly CHECK (geometrytype(poly) in ('''||$3[1]||''','''||$3[2]||''','''||$3[3]||'''));';
        END IF ;
    --isvalid
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_isvalid_poly CHECK (st_isvalid(poly) = true);';
    return 'OK';
  end CASE;
  END

    $BODY$
    LANGUAGE plpgsql;
  COMMENT ON FUNCTION public.geoconstraits(text, integer, text[]) IS '[BSA] v0.3';




  SELECT 'SELECT geoConstraits('''||table_name||''',32768,''{"GEOMETRY"}'');' from information_schema.columns
    WHERE table_schema='public' and column_name='poly'
          AND columns.udt_name='geometry' and is_updatable ='YES'
    ORDER BY table_name;


    SELECT geoConstraits( 'ada',32768,'{"POINT"}');
  SELECT geoConstraits( 'parsel_fonksiyon',32768,'{"POLYGON","MULTIPOLYGON"}');
