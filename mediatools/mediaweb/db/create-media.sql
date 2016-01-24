--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

DROP DATABASE media;
--
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
-- Name: media; Type: COMMENT; Schema: -; Owner: nico
--

COMMENT ON DATABASE media IS '28-6-2015 in principe alle media bestanden, w.o. music, books, films, series. Met deels tabellen specifiek voor soort media, en deels generiek, zoals groepen, verbanden en tags.
';


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


--
-- Name: pltcl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE pltcl;


ALTER PROCEDURAL LANGUAGE pltcl OWNER TO postgres;

--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


SET search_path = public, pg_catalog;

--
-- Name: appendline(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION appendline(character varying, character varying) RETURNS character varying
    LANGUAGE pltcl
    AS $_$
  return [string trim "$1\n$2"]
$_$;


ALTER FUNCTION public.appendline(character varying, character varying) OWNER TO postgres;

--
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
-- Name: action; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE action (
    id integer NOT NULL,
    action character varying,
    fullpath_action character varying,
    fullpath_other character varying,
    notes character varying,
    file_id integer,
    exec_output character varying,
    exec_status character varying,
    create_ts timestamp with time zone,
    exec_ts timestamp with time zone,
    exec_stderr character varying
);


ALTER TABLE public.action OWNER TO nico;

--
-- Name: COLUMN action.exec_stderr; Type: COMMENT; Schema: public; Owner: nico
--

COMMENT ON COLUMN action.exec_stderr IS 'stderr output of (cmdline) action.';


--
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
-- Name: action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE action_id_seq OWNED BY action.id;


--
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
-- Name: author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE author_id_seq OWNED BY author.id;


--
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
-- Name: book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE book_id_seq OWNED BY book.id;


--
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
-- Name: bookauthor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE bookauthor_id_seq OWNED BY bookauthor.id;


--
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
-- Name: bookformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE bookformat_id_seq OWNED BY bookformat.id;


--
-- Name: directory; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE directory (
    computer character varying(30),
    parent_id integer,
    parent_folder character varying(1023),
    fullpath character varying(1023),
    id integer NOT NULL,
    notes text
);


ALTER TABLE public.directory OWNER TO nico;

--
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
-- Name: directory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE directory_id_seq OWNED BY directory.id;


--
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
    directory_id integer,
    relfile_id integer,
    ts timestamp with time zone,
    notes text
);


ALTER TABLE public.file OWNER TO nico;

--
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
-- Name: file_deleted_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE file_deleted_id_seq OWNED BY file_deleted.id;


--
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
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;


--
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
-- Name: fileinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE fileinfo_id_seq OWNED BY fileinfo.id;


--
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
-- Name: filelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE filelog_id_seq OWNED BY filelog.id;


--
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
-- Name: filestatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE filestatus_id_seq OWNED BY filestatus.id;


--
-- Name: lobos_migrations; Type: TABLE; Schema: public; Owner: nico; Tablespace: 
--

CREATE TABLE lobos_migrations (
    name character varying(255)
);


ALTER TABLE public.lobos_migrations OWNER TO nico;

--
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
-- Name: relfile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE relfile_id_seq OWNED BY relfile.id;


--
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
-- Name: srcbak_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE srcbak_id_seq OWNED BY srcbak.id;


--
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
-- Name: stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nico
--

ALTER SEQUENCE stats_id_seq OWNED BY stats.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY action ALTER COLUMN id SET DEFAULT nextval('action_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY author ALTER COLUMN id SET DEFAULT nextval('author_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY book ALTER COLUMN id SET DEFAULT nextval('book_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor ALTER COLUMN id SET DEFAULT nextval('bookauthor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookformat ALTER COLUMN id SET DEFAULT nextval('bookformat_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY directory ALTER COLUMN id SET DEFAULT nextval('directory_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file_deleted ALTER COLUMN id SET DEFAULT nextval('file_deleted_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY fileinfo ALTER COLUMN id SET DEFAULT nextval('fileinfo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY filelog ALTER COLUMN id SET DEFAULT nextval('filelog_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY filestatus ALTER COLUMN id SET DEFAULT nextval('filestatus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY relfile ALTER COLUMN id SET DEFAULT nextval('relfile_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY srcbak ALTER COLUMN id SET DEFAULT nextval('srcbak_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nico
--

ALTER TABLE ONLY stats ALTER COLUMN id SET DEFAULT nextval('stats_id_seq'::regclass);


--
-- Name: author_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY author
    ADD CONSTRAINT author_primary_key_id PRIMARY KEY (id);


--
-- Name: author_unique_fullname; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY author
    ADD CONSTRAINT author_unique_fullname UNIQUE (fullname);


--
-- Name: book_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY book
    ADD CONSTRAINT book_primary_key_id PRIMARY KEY (id);


--
-- Name: bookauthor_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_primary_key_id PRIMARY KEY (id);


--
-- Name: bookformat_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY bookformat
    ADD CONSTRAINT bookformat_primary_key_id PRIMARY KEY (id);


--
-- Name: directory_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_primary_key_id PRIMARY KEY (id);


--
-- Name: directory_unique_fullpath; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_unique_fullpath UNIQUE (fullpath);


--
-- Name: pk_action_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY action
    ADD CONSTRAINT pk_action_id PRIMARY KEY (id);


--
-- Name: pk_file; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY file
    ADD CONSTRAINT pk_file PRIMARY KEY (id);


--
-- Name: relfile_primary_key_id; Type: CONSTRAINT; Schema: public; Owner: nico; Tablespace: 
--

ALTER TABLE ONLY relfile
    ADD CONSTRAINT relfile_primary_key_id PRIMARY KEY (id);


--
-- Name: fki_action_file_id; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX fki_action_file_id ON action USING btree (file_id);


--
-- Name: ix_file_1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_1 ON file USING btree (filesize);


--
-- Name: ix_file_2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_2 ON file USING btree (filename);


--
-- Name: ix_file_deleted_1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_deleted_1 ON file_deleted USING btree (filesize);


--
-- Name: ix_file_deleted_2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_file_deleted_2 ON file_deleted USING btree (filename);


--
-- Name: ix_fileinfo1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_fileinfo1 ON fileinfo USING btree (file_id);


--
-- Name: ix_fileinfo2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_fileinfo2 ON fileinfo USING btree (fullpath);


--
-- Name: ix_filelog1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filelog1 ON filelog USING btree (file_id);


--
-- Name: ix_filelog2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filelog2 ON filelog USING btree (fullpath);


--
-- Name: ix_filestatus1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filestatus1 ON filestatus USING btree (file_id);


--
-- Name: ix_filestatus2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_filestatus2 ON filestatus USING btree (fullpath);


--
-- Name: ix_srcbak1; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_srcbak1 ON srcbak USING btree (fullpath_src);


--
-- Name: ix_srcbak2; Type: INDEX; Schema: public; Owner: nico; Tablespace: 
--

CREATE INDEX ix_srcbak2 ON srcbak USING btree (fullpath_bak);


--
-- Name: bookauthor_fkey_author_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_fkey_author_id FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE SET NULL;


--
-- Name: bookauthor_fkey_book_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookauthor
    ADD CONSTRAINT bookauthor_fkey_book_id FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE SET NULL;


--
-- Name: bookformat_fkey_book_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY bookformat
    ADD CONSTRAINT bookformat_fkey_book_id FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE SET NULL;


--
-- Name: file_fkey_directory_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fkey_directory_id FOREIGN KEY (directory_id) REFERENCES directory(id) ON DELETE SET NULL;


--
-- Name: file_fkey_relfile_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fkey_relfile_id FOREIGN KEY (relfile_id) REFERENCES relfile(id) ON DELETE SET NULL;


--
-- Name: fk_action_file_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY action
    ADD CONSTRAINT fk_action_file_id FOREIGN KEY (file_id) REFERENCES file(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- Name: relfile_fkey_bookformat_id; Type: FK CONSTRAINT; Schema: public; Owner: nico
--

ALTER TABLE ONLY relfile
    ADD CONSTRAINT relfile_fkey_bookformat_id FOREIGN KEY (bookformat_id) REFERENCES bookformat(id) ON DELETE SET NULL;


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

