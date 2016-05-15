--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

DROP DATABASE music;
--
-- Name: music; Type: DATABASE; Schema: -; Owner: nico
--

CREATE DATABASE music WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE music OWNER TO nico;

\connect music

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: music; Type: COMMENT; Schema: -; Owner: nico
--

COMMENT ON DATABASE music IS '19-6-2015 Alle music files, overgenomen uit MySQL';


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: album; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE album (
    id integer NOT NULL,
    generic integer,
    path character varying(1023) DEFAULT NULL::character varying,
    artist integer,
    name character varying(255) DEFAULT NULL::character varying,
    notes text,
    file_exists integer,
    is_symlink integer,
    realpath character varying(1023)
);


ALTER TABLE public.album OWNER TO postgres;

--
-- Name: album_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE album_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.album_id_seq OWNER TO postgres;

--
-- Name: album_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE album_id_seq OWNED BY album.id;


--
-- Name: generic; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE generic (
    id integer NOT NULL,
    gentype character varying(20) DEFAULT NULL::character varying,
    freq numeric,
    freq_history numeric,
    play_count integer
);


ALTER TABLE public.generic OWNER TO postgres;

--
-- Name: albumgen; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW albumgen AS
 SELECT a.id,
    a.generic,
    a.path,
    a.artist,
    a.name,
    a.notes,
    g.id AS g_id,
    g.play_count,
    g.freq,
    g.freq_history,
    g.gentype
   FROM (album a
     JOIN generic g ON ((a.generic = g.id)));


ALTER TABLE public.albumgen OWNER TO postgres;

--
-- Name: member; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE member (
    id integer NOT NULL,
    mgroup integer,
    generic integer
);


ALTER TABLE public.member OWNER TO postgres;

--
-- Name: mgroup; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE mgroup (
    id integer NOT NULL,
    name character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.mgroup OWNER TO postgres;

--
-- Name: albums; Type: VIEW; Schema: public; Owner: nico
--

CREATE VIEW albums AS
 SELECT g.id,
    a.path,
    g.freq,
    g.freq_history,
    g.play_count
   FROM generic g,
    album a,
    member mem,
    mgroup mg
  WHERE ((((a.generic = g.id) AND (mem.generic = g.id)) AND (mem.mgroup = mg.id)) AND ((mg.name)::text = 'Albums'::text));


ALTER TABLE public.albums OWNER TO nico;

--
-- Name: artist; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE artist (
    id integer NOT NULL,
    generic integer,
    path character varying(255) DEFAULT NULL::character varying,
    name character varying(255) DEFAULT NULL::character varying,
    notes text
);


ALTER TABLE public.artist OWNER TO postgres;

--
-- Name: artist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE artist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.artist_id_seq OWNER TO postgres;

--
-- Name: artist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE artist_id_seq OWNED BY artist.id;


--
-- Name: cassette; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cassette (
    id integer,
    bandnr character varying(10) DEFAULT NULL::character varying,
    titel character varying(255) DEFAULT NULL::character varying,
    artiest character varying(255) DEFAULT NULL::character varying,
    notes character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.cassette OWNER TO postgres;

--
-- Name: generic_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE generic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.generic_id_seq OWNER TO postgres;

--
-- Name: generic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE generic_id_seq OWNED BY generic.id;


--
-- Name: member_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.member_id_seq OWNER TO postgres;

--
-- Name: member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE member_id_seq OWNED BY member.id;


--
-- Name: mgroup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE mgroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mgroup_id_seq OWNER TO postgres;

--
-- Name: mgroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE mgroup_id_seq OWNED BY mgroup.id;


--
-- Name: musicfile; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE musicfile (
    id integer NOT NULL,
    path character varying(1023) DEFAULT NULL::character varying,
    file_exists integer,
    trackname character varying(255) DEFAULT NULL::character varying,
    seconds integer,
    vbr integer,
    filesize integer,
    bitrate integer,
    notes text,
    generic integer,
    album integer,
    artistname character varying(255) DEFAULT NULL::character varying,
    artist integer,
    is_symlink integer,
    realpath character varying(1023)
);


ALTER TABLE public.musicfile OWNER TO postgres;

--
-- Name: musicfile_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE musicfile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.musicfile_id_seq OWNER TO postgres;

--
-- Name: musicfile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE musicfile_id_seq OWNED BY musicfile.id;


--
-- Name: played; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE played (
    id integer NOT NULL,
    kind character varying(10) DEFAULT NULL::character varying,
    datetime timestamp without time zone,
    generic integer
);


ALTER TABLE public.played OWNER TO postgres;

--
-- Name: played_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE played_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.played_id_seq OWNER TO postgres;

--
-- Name: played_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE played_id_seq OWNED BY played.id;


--
-- Name: property; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE property (
    id integer NOT NULL,
    name character varying(50) DEFAULT NULL::character varying,
    value character varying(255) DEFAULT NULL::character varying,
    generic integer
);


ALTER TABLE public.property OWNER TO postgres;

--
-- Name: property_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_id_seq OWNER TO postgres;

--
-- Name: property_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE property_id_seq OWNED BY property.id;


--
-- Name: singles; Type: VIEW; Schema: public; Owner: nico
--

CREATE VIEW singles AS
 SELECT g.id,
    m.path,
    g.freq,
    g.freq_history,
    g.play_count
   FROM generic g,
    musicfile m,
    member mem,
    mgroup mg
  WHERE ((((m.generic = g.id) AND (mem.generic = g.id)) AND (mem.mgroup = mg.id)) AND ((mg.name)::text = 'Singles-car'::text));


ALTER TABLE public.singles OWNER TO nico;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY album ALTER COLUMN id SET DEFAULT nextval('album_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY artist ALTER COLUMN id SET DEFAULT nextval('artist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY generic ALTER COLUMN id SET DEFAULT nextval('generic_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member ALTER COLUMN id SET DEFAULT nextval('member_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY mgroup ALTER COLUMN id SET DEFAULT nextval('mgroup_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY musicfile ALTER COLUMN id SET DEFAULT nextval('musicfile_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY played ALTER COLUMN id SET DEFAULT nextval('played_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY property ALTER COLUMN id SET DEFAULT nextval('property_id_seq'::regclass);


--
-- Name: album_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY album
    ADD CONSTRAINT album_pkey PRIMARY KEY (id);


--
-- Name: artist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY artist
    ADD CONSTRAINT artist_pkey PRIMARY KEY (id);


--
-- Name: generic_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY generic
    ADD CONSTRAINT generic_pkey PRIMARY KEY (id);


--
-- Name: member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY member
    ADD CONSTRAINT member_pkey PRIMARY KEY (id);


--
-- Name: mgroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY mgroup
    ADD CONSTRAINT mgroup_pkey PRIMARY KEY (id);


--
-- Name: musicfile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY musicfile
    ADD CONSTRAINT musicfile_pkey PRIMARY KEY (id);


--
-- Name: played_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY played
    ADD CONSTRAINT played_pkey PRIMARY KEY (id);


--
-- Name: property_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY property
    ADD CONSTRAINT property_pkey PRIMARY KEY (id);


--
-- Name: ix_album_artist; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_album_artist ON album USING btree (artist);


--
-- Name: ix_album_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_album_generic ON album USING btree (generic);


--
-- Name: ix_album_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_album_id ON album USING btree (id);


--
-- Name: ix_artist_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_artist_generic ON artist USING btree (generic);


--
-- Name: ix_artist_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_artist_id ON artist USING btree (id);


--
-- Name: ix_cassette_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_cassette_id ON cassette USING btree (id);


--
-- Name: ix_generic_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_generic_id ON generic USING btree (id);


--
-- Name: ix_member_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_member_generic ON member USING btree (generic);


--
-- Name: ix_member_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_member_id ON member USING btree (id);


--
-- Name: ix_member_mgroup; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_member_mgroup ON member USING btree (mgroup);


--
-- Name: ix_mgroup_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_mgroup_id ON mgroup USING btree (id);


--
-- Name: ix_musicfile_album; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_musicfile_album ON musicfile USING btree (album);


--
-- Name: ix_musicfile_artist; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_musicfile_artist ON musicfile USING btree (artist);


--
-- Name: ix_musicfile_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_musicfile_generic ON musicfile USING btree (generic);


--
-- Name: ix_musicfile_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_musicfile_id ON musicfile USING btree (id);


--
-- Name: ix_played_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_played_generic ON played USING btree (generic);


--
-- Name: ix_played_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_played_id ON played USING btree (id);


--
-- Name: ix_property_generic; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_property_generic ON property USING btree (generic);


--
-- Name: ix_property_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX ix_property_id ON property USING btree (id);


--
-- Name: album_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY album
    ADD CONSTRAINT album_ibfk_1 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: album_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY album
    ADD CONSTRAINT album_ibfk_2 FOREIGN KEY (artist) REFERENCES artist(id) ON DELETE CASCADE;


--
-- Name: artist_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY artist
    ADD CONSTRAINT artist_ibfk_1 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: member_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member
    ADD CONSTRAINT member_ibfk_1 FOREIGN KEY (mgroup) REFERENCES mgroup(id) ON DELETE CASCADE;


--
-- Name: member_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member
    ADD CONSTRAINT member_ibfk_2 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: musicfile_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY musicfile
    ADD CONSTRAINT musicfile_ibfk_1 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: musicfile_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY musicfile
    ADD CONSTRAINT musicfile_ibfk_2 FOREIGN KEY (album) REFERENCES album(id) ON DELETE CASCADE;


--
-- Name: musicfile_ibfk_3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY musicfile
    ADD CONSTRAINT musicfile_ibfk_3 FOREIGN KEY (artist) REFERENCES artist(id) ON DELETE CASCADE;


--
-- Name: played_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY played
    ADD CONSTRAINT played_ibfk_2 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: property_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY property
    ADD CONSTRAINT property_ibfk_2 FOREIGN KEY (generic) REFERENCES generic(id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

