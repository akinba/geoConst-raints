--=========================================== v0.5
  
  --DROP  FUNCTION geosrid(text);

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


  --DROP FUNCTION public.geoConst(TEXT,INTEGER,TEXT[] );

  CREATE OR REPLACE FUNCTION public.geoConst(text, integer, text[])
    RETURNS text AS
  $BODY$
  DECLARE r RECORD;
  BEGIN

    --check inputs
    CASE
  WHEN $1 not  in (select tablename::text from pg_tables where schemaname=current_schema())
    then return 'Error= Table name :'||$1||' not exist!'; 
  WHEN 'poly' != (select column_name FROM information_schema.columns WHERE table_schema =  current_schema() AND table_name = $1 AND data_type = 'USER-DEFINED')
    then return 'Error= '||$1||' doesn''t have geometry column!';
  WHEN $2 not in (select srid from spatial_ref_sys)
    then return 'Error= SRID value:'||$2||' not exist in public.spatial_ref_sys!';
  WHEN $2 != (select geosrid($1))
    then return 'Error= Given SRID:'||$2||','||$1||' mismatch with SRID:'||(select geosrid($1))||' !';
  WHEN array_length($3,1)>3
    then return 'Error= Max geometryType count=3 !';
  ELSE

    --drop all Constraits for POLY
    FOR r IN SELECT constraint_name
      FROM information_schema.constraint_column_usage WHERE table_name=quote_ident($1) and column_name='poly'
    LOOP
      EXECUTE 'ALTER TABLE IF EXISTS '||$1||' DROP CONSTRAINT IF EXISTS "'||r.constraint_name||'" ;';
    END LOOP;

    --isvalid
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_isvalid_poly CHECK (st_isvalid(poly) = true);';
    --bbox
    EXECUTE 'ALTER TABLE IF EXISTS '||$1||' ADD CONSTRAINT enforce_bbox_poly CHECK (st_intersects(st_pointonsurface(poly),st_makeenvelope(0::double precision, 4000000::double precision,  700000::double precision,  5000000::double precision, '||$2||')) = true);';
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

    return 'OK';
  end CASE;
  END

    $BODY$
    LANGUAGE plpgsql;
  COMMENT ON FUNCTION public.geoConst(text, integer, text[]) IS '[BSA] v0.5';


