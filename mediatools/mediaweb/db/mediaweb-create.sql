--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.10
-- Dumped by pg_dump version 9.3.10
-- Started on 2016-01-10 20:53:21 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 2133 (class 1262 OID 16861)
-- Name: media; Type: DATABASE; Schema: -; Owner: nico
--

CREATE DATABASE media WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE media OWNER TO nico;

\connect media

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 2134 (class 1262 OID 16861)
-- Dependencies: 2133
-- Name: media; Type: COMMENT; Schema: -; Owner: nico
--

COMMENT ON DATABASE media IS '28-6-2015 in principe alle media bestanden, w.o. music, books, films, series. Met deels tabellen specifiek voor soort media, en deels generiek, zoals groepen, verbanden en tags.
';


--
-- TOC entry 200 (class 3079 OID 11787)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2137 (class 0 OID 0)
-- Dependencies: 200
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 636 (class 2612 OID 17618)
-- Name: pltcl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE pltcl;


ALTER PROCEDURAL LANGUAGE pltcl OWNER TO postgres;

--
-- TOC entry 201 (class 3079 OID 17083)
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- TOC entry 2138 (class 0 OID 0)
-- Dependencies: 201
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


SET search_path = public, pg_catalog;

--
-- TOC entry 225 (class 1255 OID 17620)
-- Name: appendline(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION appendline(character varying, character varying) RETURNS character varying
    LANGUAGE pltcl
    AS $_$
  return [string trim "$1\n$2"]
$_$;


ALTER FUNCTION public.appendline(character varying, character varying) OWNER TO postgres;

--
-- TOC entry 224 (class 1255 OID 17619)
-- Name: tcl_max(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION tcl_max(integer, integer) RETURNS integer
    LANGUAGE pltcl STRICT
    AS $_$
    if {$1 > $2} {return $1}
    return $2
$_$;


ALTER FUNCTION public.tcl_max(integer, integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 177 (class 1259 OID 16936)
-- Name: action; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE action (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    action character varying,
    fullpath_action character varying,
    fullpath_other character varying,
    notes character varying
);


ALTER TABLE public.action OWNER TO nico;

--
-- TOC entry 176 (class 1259 OID 16934)
-- Name: action_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.action_id_seq OWNER TO nico;

--
-- TOC entry 2139 (class 0 OID 0)
-- Dependencies: 176
-- Name: action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE action_id_seq OWNED BY action.id;


--
-- TOC entry 191 (class 1259 OID 17446)
-- Name: author; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE author (
    notes text,
    lastname character varying(100),
    firstname character varying(100),
    fullname character varying(200),
    id integer NOT NULL
);


ALTER TABLE public.author OWNER TO nico;

--
-- TOC entry 190 (class 1259 OID 17444)
-- Name: author_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE author_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.author_id_seq OWNER TO nico;

--
-- TOC entry 2140 (class 0 OID 0)
-- Dependencies: 190
-- Name: author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE author_id_seq OWNED BY author.id;


--
-- TOC entry 193 (class 1259 OID 17459)
-- Name: book; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE book (
    tags character varying(1023),
    pubdate date,
    publisher character varying(100),
    isbn13 character varying(20),
    title character varying(200),
    language character varying(30),
    id integer NOT NULL,
    notes text,
    edition character varying(10),
    isbn10 character varying(15),
    authors character varying(1023),
    npages integer
);


ALTER TABLE public.book OWNER TO nico;

--
-- TOC entry 192 (class 1259 OID 17457)
-- Name: book_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE book_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.book_id_seq OWNER TO nico;

--
-- TOC entry 2141 (class 0 OID 0)
-- Dependencies: 192
-- Name: book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE book_id_seq OWNED BY book.id;


--
-- TOC entry 195 (class 1259 OID 17481)
-- Name: bookauthor; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE bookauthor (
    notes text,
    author_id integer,
    book_id integer,
    id integer NOT NULL
);


ALTER TABLE public.bookauthor OWNER TO nico;

--
-- TOC entry 194 (class 1259 OID 17479)
-- Name: bookauthor_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE bookauthor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bookauthor_id_seq OWNER TO nico;

--
-- TOC entry 2142 (class 0 OID 0)
-- Dependencies: 194
-- Name: bookauthor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE bookauthor_id_seq OWNED BY bookauthor.id;


--
-- TOC entry 197 (class 1259 OID 17510)
-- Name: bookformat; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE bookformat (
    notes text,
    format character varying(20),
    book_id integer,
    id integer NOT NULL
);


ALTER TABLE public.bookformat OWNER TO nico;

--
-- TOC entry 196 (class 1259 OID 17508)
-- Name: bookformat_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE bookformat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bookformat_id_seq OWNER TO nico;

--
-- TOC entry 2143 (class 0 OID 0)
-- Dependencies: 196
-- Name: bookformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE bookformat_id_seq OWNED BY bookformat.id;


--
-- TOC entry 188 (class 1259 OID 17388)
-- Name: directory; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE directory (
    computer character varying(30),
    parent_id integer,
    parent_folder character varying(1023),
    fullpath character varying(1023),
    id integer NOT NULL
);


ALTER TABLE public.directory OWNER TO nico;

--
-- TOC entry 187 (class 1259 OID 17386)
-- Name: directory_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE directory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directory_id_seq OWNER TO nico;

--
-- TOC entry 2144 (class 0 OID 0)
-- Dependencies: 187
-- Name: directory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE directory_id_seq OWNED BY directory.id;


--
-- TOC entry 171 (class 1259 OID 16905)
-- Name: file; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE file (
    id integer NOT NULL,
    fullpath character varying,
    folder character varying,
    filename character varying,
    filesize integer,
    ts_cet character varying,
    md5 character varying,
    goal character varying,
    importance character varying,
    computer character varying,
    srcbak character varying,
    action character varying,
    directory_id integer,
    relfile_id integer,
    ts timestamp with time zone
);


ALTER TABLE public.file OWNER TO nico;

--
-- TOC entry 173 (class 1259 OID 16914)
-- Name: file_deleted; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE file_deleted (
    id integer NOT NULL,
    fullpath character varying,
    folder character varying,
    filename character varying,
    filesize integer,
    ts_cet character varying,
    md5 character varying,
    goal character varying,
    importance character varying,
    computer character varying,
    srcbak character varying,
    action character varying
);


ALTER TABLE public.file_deleted OWNER TO nico;

--
-- TOC entry 172 (class 1259 OID 16912)
-- Name: file_deleted_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE file_deleted_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.file_deleted_id_seq OWNER TO nico;

--
-- TOC entry 2145 (class 0 OID 0)
-- Dependencies: 172
-- Name: file_deleted_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE file_deleted_id_seq OWNED BY file_deleted.id;


--
-- TOC entry 170 (class 1259 OID 16903)
-- Name: file_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.file_id_seq OWNER TO nico;

--
-- TOC entry 2146 (class 0 OID 0)
-- Dependencies: 170
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;


--
-- TOC entry 185 (class 1259 OID 16978)
-- Name: filestatus; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE filestatus (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    file_id integer,
    fullpath character varying,
    status character varying,
    notes character varying
);


ALTER TABLE public.filestatus OWNER TO nico;

--
-- TOC entry 186 (class 1259 OID 16987)
-- Name: file_with_status; Type: VIEW; Schema: public; Owner: nico
--

CREATE VIEW file_with_status AS
 SELECT f.id,
    f.fullpath,
    f.folder,
    f.filename,
    f.filesize,
    f.ts_cet,
    f.md5,
    f.goal,
    f.importance,
    f.computer,
    f.srcbak,
    f.action,
    fs.status
   FROM (file f
     LEFT JOIN filestatus fs ON ((fs.file_id = f.id)));


ALTER TABLE public.file_with_status OWNER TO nico;

--
-- TOC entry 181 (class 1259 OID 16956)
-- Name: fileinfo; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE fileinfo (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    file_id integer,
    fullpath character varying,
    name character varying,
    value character varying,
    notes character varying
);


ALTER TABLE public.fileinfo OWNER TO nico;

--
-- TOC entry 180 (class 1259 OID 16954)
-- Name: fileinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE fileinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fileinfo_id_seq OWNER TO nico;

--
-- TOC entry 2147 (class 0 OID 0)
-- Dependencies: 180
-- Name: fileinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE fileinfo_id_seq OWNED BY fileinfo.id;


--
-- TOC entry 183 (class 1259 OID 16967)
-- Name: filelog; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE filelog (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    file_id integer,
    fullpath character varying,
    action character varying,
    notes character varying,
    oldstatus character varying,
    newstatus character varying
);


ALTER TABLE public.filelog OWNER TO nico;

--
-- TOC entry 182 (class 1259 OID 16965)
-- Name: filelog_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE filelog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.filelog_id_seq OWNER TO nico;

--
-- TOC entry 2148 (class 0 OID 0)
-- Dependencies: 182
-- Name: filelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE filelog_id_seq OWNED BY filelog.id;


--
-- TOC entry 184 (class 1259 OID 16976)
-- Name: filestatus_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE filestatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.filestatus_id_seq OWNER TO nico;

--
-- TOC entry 2149 (class 0 OID 0)
-- Dependencies: 184
-- Name: filestatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE filestatus_id_seq OWNED BY filestatus.id;


--
-- TOC entry 189 (class 1259 OID 17399)
-- Name: lobos_migrations; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE lobos_migrations (
    name character varying(255)
);


ALTER TABLE public.lobos_migrations OWNER TO nico;

--
-- TOC entry 199 (class 1259 OID 17546)
-- Name: relfile; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE relfile (
    relpath character varying(1023),
    md5 character varying(35),
    bookformat_id integer,
    ts timestamp with time zone,
    filename character varying(1023),
    id integer NOT NULL,
    notes text,
    filesize integer,
    ts_cet character varying(30),
    relfolder character varying(1023)
);


ALTER TABLE public.relfile OWNER TO nico;

--
-- TOC entry 198 (class 1259 OID 17544)
-- Name: relfile_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE relfile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relfile_id_seq OWNER TO nico;

--
-- TOC entry 2150 (class 0 OID 0)
-- Dependencies: 198
-- Name: relfile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE relfile_id_seq OWNED BY relfile.id;


--
-- TOC entry 179 (class 1259 OID 16945)
-- Name: srcbak; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE srcbak (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    id_src integer,
    id_bak integer,
    fullpath_src character varying,
    fullpath_bak character varying,
    ts_cet_src character varying,
    ts_cet_bak character varying,
    filesize_src integer,
    filesize_bak integer,
    md5_src character varying,
    md5_bak character varying
);


ALTER TABLE public.srcbak OWNER TO nico;

--
-- TOC entry 178 (class 1259 OID 16943)
-- Name: srcbak_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE srcbak_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.srcbak_id_seq OWNER TO nico;

--
-- TOC entry 2151 (class 0 OID 0)
-- Dependencies: 178
-- Name: srcbak_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE srcbak_id_seq OWNED BY srcbak.id;


--
-- TOC entry 175 (class 1259 OID 16927)
-- Name: stats; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE stats (
    id integer NOT NULL,
    ts_cet timestamp without time zone,
    nfiles integer,
    ngbytes numeric,
    ngoal integer,
    nimportance integer,
    nsrcbak integer,
    naction integer,
    notes character varying
);


ALTER TABLE public.stats OWNER TO nico;

--
-- TOC entry 174 (class 1259 OID 16925)
-- Name: stats_id_seq; Type: SEQUENCE; Schema: public; Owner: nico
--

CREATE SEQUENCE stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stats_id_seq OWNER TO nico;

--
-- TOC entry 2152 (class 0 OID 0)
-- Dependencies: 174
-- Name: stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE stats_id_seq OWNED BY stats.id;


--
-- TOC entry 1976 (class 2604 OID 16939)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY action ALTER COLUMN id SET DEFAULT nextval('action_id_seq'::regclass);


--
-- TOC entry 1982 (class 2604 OID 17449)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY author ALTER COLUMN id SET DEFAULT nextval('author_id_seq'::regclass);


--
-- TOC entry 1983 (class 2604 OID 17462)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY book ALTER COLUMN id SET DEFAULT nextval('book_id_seq'::regclass);


--
-- TOC entry 1984 (class 2604 OID 17484)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor ALTER COLUMN id SET DEFAULT nextval('bookauthor_id_seq'::regclass);


--
-- TOC entry 1985 (class 2604 OID 17513)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookformat ALTER COLUMN id SET DEFAULT nextval('bookformat_id_seq'::regclass);


--
-- TOC entry 1981 (class 2604 OID 17391)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY directory ALTER COLUMN id SET DEFAULT nextval('directory_id_seq'::regclass);


--
-- TOC entry 1973 (class 2604 OID 16908)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);


--
-- TOC entry 1974 (class 2604 OID 16917)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file_deleted ALTER COLUMN id SET DEFAULT nextval('file_deleted_id_seq'::regclass);


--
-- TOC entry 1978 (class 2604 OID 16959)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY fileinfo ALTER COLUMN id SET DEFAULT nextval('fileinfo_id_seq'::regclass);


--
-- TOC entry 1979 (class 2604 OID 16970)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY filelog ALTER COLUMN id SET DEFAULT nextval('filelog_id_seq'::regclass);


--
-- TOC entry 1980 (class 2604 OID 16981)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY filestatus ALTER COLUMN id SET DEFAULT nextval('filestatus_id_seq'::regclass);


--
-- TOC entry 1986 (class 2604 OID 17549)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY relfile ALTER COLUMN id SET DEFAULT nextval('relfile_id_seq'::regclass);


--
-- TOC entry 1977 (class 2604 OID 16948)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY srcbak ALTER COLUMN id SET DEFAULT nextval('srcbak_id_seq'::regclass);


--
-- TOC entry 1975 (class 2604 OID 16930)
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY stats ALTER COLUMN id SET DEFAULT nextval('stats_id_seq'::regclass);


--
-- TOC entry 2004 (class 2606 OID 17454)
-- Name: author_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY author
    ADD CONSTRAINT author_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 2006 (class 2606 OID 17456)
-- Name: author_unique_fullname; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY author
    ADD CONSTRAINT author_unique_fullname UNIQUE (fullname);


--
-- TOC entry 2008 (class 2606 OID 17467)
-- Name: book_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY book
    ADD CONSTRAINT book_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 2010 (class 2606 OID 17489)
-- Name: bookauthor_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 2012 (class 2606 OID 17518)
-- Name: bookformat_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY bookformat
    ADD CONSTRAINT bookformat_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 2000 (class 2606 OID 17396)
-- Name: directory_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 2002 (class 2606 OID 17398)
-- Name: directory_unique_fullpath; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_unique_fullpath UNIQUE (fullpath);


--
-- TOC entry 2014 (class 2606 OID 17554)
-- Name: relfile_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY relfile
    ADD CONSTRAINT relfile_primary_key_id PRIMARY KEY (id);


--
-- TOC entry 1987 (class 1259 OID 16921)
-- Name: ix_file_1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_1 ON file USING btree (filesize);


--
-- TOC entry 1988 (class 1259 OID 16922)
-- Name: ix_file_2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_2 ON file USING btree (filename);


--
-- TOC entry 1989 (class 1259 OID 16923)
-- Name: ix_file_deleted_1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_deleted_1 ON file_deleted USING btree (filesize);


--
-- TOC entry 1990 (class 1259 OID 16924)
-- Name: ix_file_deleted_2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_deleted_2 ON file_deleted USING btree (filename);


--
-- TOC entry 1993 (class 1259 OID 16963)
-- Name: ix_fileinfo1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_fileinfo1 ON fileinfo USING btree (file_id);


--
-- TOC entry 1994 (class 1259 OID 16964)
-- Name: ix_fileinfo2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_fileinfo2 ON fileinfo USING btree (fullpath);


--
-- TOC entry 1995 (class 1259 OID 16974)
-- Name: ix_filelog1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filelog1 ON filelog USING btree (file_id);


--
-- TOC entry 1996 (class 1259 OID 16975)
-- Name: ix_filelog2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filelog2 ON filelog USING btree (fullpath);


--
-- TOC entry 1997 (class 1259 OID 16985)
-- Name: ix_filestatus1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filestatus1 ON filestatus USING btree (file_id);


--
-- TOC entry 1998 (class 1259 OID 16986)
-- Name: ix_filestatus2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filestatus2 ON filestatus USING btree (fullpath);


--
-- TOC entry 1991 (class 1259 OID 16952)
-- Name: ix_srcbak1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_srcbak1 ON srcbak USING btree (fullpath_src);


--
-- TOC entry 1992 (class 1259 OID 16953)
-- Name: ix_srcbak2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_srcbak2 ON srcbak USING btree (fullpath_bak);


--
-- TOC entry 2017 (class 2606 OID 17490)
-- Name: bookauthor_fkey_author_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_fkey_author_id FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE SET NULL;


--
-- TOC entry 2018 (class 2606 OID 17495)
-- Name: bookauthor_fkey_book_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_fkey_book_id FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE SET NULL;


--
-- TOC entry 2019 (class 2606 OID 17519)
-- Name: bookformat_fkey_book_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookformat
    ADD CONSTRAINT bookformat_fkey_book_id FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE SET NULL;


--
-- TOC entry 2015 (class 2606 OID 17407)
-- Name: file_fkey_directory_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fkey_directory_id FOREIGN KEY (directory_id) REFERENCES directory(id) ON DELETE SET NULL;


--
-- TOC entry 2016 (class 2606 OID 17560)
-- Name: file_fkey_relfile_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fkey_relfile_id FOREIGN KEY (relfile_id) REFERENCES relfile(id) ON DELETE SET NULL;


--
-- TOC entry 2020 (class 2606 OID 17555)
-- Name: relfile_fkey_bookformat_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY relfile
    ADD CONSTRAINT relfile_fkey_bookformat_id FOREIGN KEY (bookformat_id) REFERENCES bookformat(id) ON DELETE SET NULL;


--
-- TOC entry 2136 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2016-01-10 20:53:22 CET

--
-- PostgreSQL database dump complete
--

