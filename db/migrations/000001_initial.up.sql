--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Debian 16.4-1.pgdg120+1)
-- Dumped by pg_dump version 16.3

-- Started on 2024-12-09 19:56:16 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 879 (class 1247 OID 16392)
-- Name: Role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Role" AS ENUM (
    'User',
    'Admin'
);


--
-- TOC entry 230 (class 1255 OID 16397)
-- Name: check_links(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_links() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF EXISTS (	SELECT 1 FROM sales WHERE sales.good_id = OLD.id) THEN
		RAISE EXCEPTION 'Еще есть заявки на товар';
	END IF;

	IF EXISTS (	SELECT 1 FROM warehouse1 WHERE warehouse1.good_id = OLD.id) THEN
		RAISE EXCEPTION 'Товар лежит на 1 складе';
	END IF;
		
	IF EXISTS (	SELECT 1 FROM warehouse2 WHERE warehouse2.good_id = OLD.id) THEN
		RAISE EXCEPTION 'Товар лежит на 2 складе';
	END IF;
	RETURN NEW;
END;$$;


--
-- TOC entry 231 (class 1255 OID 16398)
-- Name: delete_good(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.delete_good(IN good_id integer)
    LANGUAGE plpgsql
    AS $$BEGIN
    DELETE FROM public.goods
    WHERE id = good_id;
END;$$;


--
-- TOC entry 232 (class 1255 OID 16399)
-- Name: delete_user(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.delete_user(IN user_id integer)
    LANGUAGE plpgsql
    AS $$BEGIN
    DELETE FROM public.users
    WHERE id = user_id;
END;$$;


--
-- TOC entry 233 (class 1255 OID 16400)
-- Name: delete_wh1(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.delete_wh1(IN p_good_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM public.warehouse1
    WHERE good_id = p_good_id;
END;
$$;


--
-- TOC entry 234 (class 1255 OID 16401)
-- Name: delete_wh2(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.delete_wh2(IN p_good_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM public.warehouse2
    WHERE good_id = p_good_id;
END;
$$;


--
-- TOC entry 235 (class 1255 OID 16402)
-- Name: get_all_goods_with_amounts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_all_goods_with_amounts() RETURNS TABLE(good_id integer, good_name character varying, good_priority double precision, warehouse1_count integer, warehouse2_count integer)
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN QUERY
    SELECT 
        g.id AS good_id,
        g.name AS good_name,
        g.priority AS good_priority,
        COALESCE(w1.good_count, 0) AS warehouse1_count,
        COALESCE(w2.good_count, 0) AS warehouse2_count
    FROM 
        public.goods g
    LEFT JOIN 
        public.warehouse1 w1 ON g.id = w1.good_id
    LEFT JOIN 
        public.warehouse2 w2 ON g.id = w2.good_id;
END;$$;


--
-- TOC entry 236 (class 1255 OID 16403)
-- Name: get_all_sales_with_good_names(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_all_sales_with_good_names() RETURNS TABLE(sale_id integer, good_name character varying, good_count integer, sale_date date)
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN QUERY
    SELECT 
        s.id AS sale_id,
        g.name AS good_name,
        s.good_count AS good_count,
        s.create_date AS sale_date
    FROM 
        public.sales s
    JOIN 
        public.goods g ON s.good_id = g.id;
END;$$;


--
-- TOC entry 238 (class 1255 OID 16404)
-- Name: get_good_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_good_by_id(p_good_id integer) RETURNS TABLE(good_id integer, good_name character varying, good_priority double precision, warehouse1_count integer, warehouse2_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.id AS good_id,
        g.name AS good_name,
        g.priority AS good_priority,
        COALESCE(w1.good_count, 0) AS warehouse1_count,
        COALESCE(w2.good_count, 0) AS warehouse2_count
    FROM 
        public.goods g
    LEFT JOIN 
        public.warehouse1 w1 ON g.id = w1.good_id
    LEFT JOIN 
        public.warehouse2 w2 ON g.id = w2.good_id
    WHERE 
        g.id = p_good_id;
END;
$$;


--
-- TOC entry 239 (class 1255 OID 16405)
-- Name: get_good_demand(integer, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_good_demand(p_good_id integer, p_start_date date, p_end_date date) RETURNS TABLE(sale_date date, total_demand integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.create_date AS sale_date,
        SUM(s.good_count) AS total_demand
    FROM 
        public.sales s
    WHERE 
        s.good_id = p_good_id
        AND s.create_date BETWEEN p_start_date AND p_end_date
    GROUP BY 
        s.create_date
    ORDER BY 
        s.create_date;
END;
$$;


--
-- TOC entry 240 (class 1255 OID 16406)
-- Name: get_sale_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_sale_by_id(p_sale_id integer) RETURNS TABLE(sale_id integer, good_id integer, good_name character varying, good_count integer, sale_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id AS sale_id,
        s.good_id AS good_id,
        g.name AS good_name,
        s.good_count AS good_count,
        s.create_date AS sale_date
    FROM 
        public.sales s
    JOIN 
        public.goods g ON s.good_id = g.id
    WHERE 
        s.id = p_sale_id;
END;
$$;


--
-- TOC entry 241 (class 1255 OID 16407)
-- Name: get_user_by_login(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_by_login(p_login character varying) RETURNS TABLE(user_id integer, login character varying, passhash character varying, role public."Role")
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.login AS login,
        u.passhash AS passhash,
        u.role AS role
    FROM 
        public.users u
    WHERE 
        u.login = p_login;
END;
$$;


--
-- TOC entry 242 (class 1255 OID 16408)
-- Name: insert_good(character varying, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_good(good_name character varying, good_priority double precision DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO public.goods (name, priority)
    VALUES (good_name, good_priority)
    RETURNING id INTO new_id;

    RETURN new_id;
END;$$;


--
-- TOC entry 243 (class 1255 OID 16409)
-- Name: insert_in_wh1(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_in_wh1(p_good_id integer, p_good_count integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id INT;
BEGIN
    INSERT INTO public.warehouse1 (good_id, good_count)
    VALUES (p_good_id, p_good_count)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;


--
-- TOC entry 244 (class 1255 OID 16410)
-- Name: insert_in_wh2(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_in_wh2(p_good_id integer, p_good_count integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id INT;
BEGIN
    INSERT INTO public.warehouse2 (good_id, good_count)
    VALUES (p_good_id, p_good_count)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;


--
-- TOC entry 249 (class 1255 OID 16411)
-- Name: insert_sale(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_sale(sale_good_id integer, sale_good_count integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
    available_in_warehouse1 INTEGER;
    available_in_warehouse2 INTEGER;
    total_available INTEGER;
    new_sale_id INTEGER;
BEGIN
    -- Get available goods from warehouse1
    SELECT good_count INTO available_in_warehouse1
    FROM public.warehouse1
    WHERE good_id = sale_good_id;

    -- Get available goods from warehouse2
    SELECT good_count INTO available_in_warehouse2
    FROM public.warehouse2
    WHERE good_id = sale_good_id;

    -- Calculate total available goods
    total_available := COALESCE(available_in_warehouse1, 0) + COALESCE(available_in_warehouse2, 0);

    -- Check if there is enough stock to fulfill the sale
    IF total_available < sale_good_count THEN
        RAISE EXCEPTION 'Not enough goods available for sale. Available: %, Required: %', total_available, sale_good_count;
    END IF;

    -- Process sale from warehouse1 first
    IF available_in_warehouse1 IS NOT NULL AND available_in_warehouse1 >= sale_good_count THEN
        UPDATE public.warehouse1
        SET good_count = good_count - sale_good_count
        WHERE good_id = sale_good_id;
        
        -- Insert new sale record and return its ID
        INSERT INTO public.sales (good_id, good_count)
        VALUES (sale_good_id, sale_good_count)
        RETURNING id INTO new_sale_id;

        RETURN new_sale_id;  -- Return the newly created sale ID
    ELSE
        -- Deduct all from warehouse1 and calculate remaining needed from warehouse2
        IF available_in_warehouse1 IS NOT NULL THEN
            sale_good_count := sale_good_count - available_in_warehouse1;
            UPDATE public.warehouse1
            SET good_count = 0  -- Set to zero since all are sold from warehouse1
            WHERE good_id = sale_good_id;
        END IF;

        -- Now fulfill the remaining count from warehouse2 if possible
        IF available_in_warehouse2 IS NOT NULL AND available_in_warehouse2 >= sale_good_count THEN
            UPDATE public.warehouse2
            SET good_count = good_count - sale_good_count
            WHERE good_id = sale_good_id;

            -- Insert new sale record and return its ID
            INSERT INTO public.sales (good_id, good_count)
            VALUES (sale_good_id, sale_good_count)
            RETURNING id INTO new_sale_id;

            RETURN new_sale_id;  -- Return the newly created sale ID
        ELSE
            RAISE EXCEPTION 'Not enough goods available in both warehouses to fulfill the order.';
        END IF;
    END IF;
END;$$;


--
-- TOC entry 237 (class 1255 OID 16502)
-- Name: insert_user(character varying, character varying, public."Role"); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_user(user_login character varying, user_passhash character varying, user_role public."Role") RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_user_id INTEGER;
BEGIN
    INSERT INTO public.users (login, passhash, role)
    VALUES (user_login, user_passhash, user_role)
    RETURNING id INTO new_user_id;

    RETURN new_user_id;
END;
$$;


--
-- TOC entry 257 (class 1255 OID 16413)
-- Name: prevent_low_inventory_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_low_inventory_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE stock1 INT;
DECLARE stock2 INT;
BEGIN
	-- Получаем количество товара на первом складе
	SELECT COALESCE(wh1.good_count, 0) INTO stock1
		FROM warehouse1 wh1
		WHERE wh1.good_id = NEW.good_id;
	    
	-- Получаем количество товара на втором складе
	SELECT COALESCE(wh2.good_count, 0) INTO stock2
		FROM warehouse2 wh2
		WHERE wh2.good_id = NEW.good_id;
		
	-- Проверяем, достаточно ли товара на обоих складах
	IF NEW.good_count > stock1+stock2 THEN
		RAISE EXCEPTION 'Недостаточно товара на складе для выполнения заказа';
	END IF;
	
	RETURN NEW;
END;$$;


--
-- TOC entry 258 (class 1255 OID 16414)
-- Name: update_good(character varying, double precision); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_good(IN new_name character varying, IN new_priority double precision)
    LANGUAGE plpgsql
    AS $$BEGIN
    UPDATE public.goods
    SET name = new_name, priority = new_priority
    WHERE id = good_id;
END;$$;


--
-- TOC entry 259 (class 1255 OID 16415)
-- Name: update_user(integer, character varying, character varying, public."Role"); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_user(IN user_id integer, IN new_login character varying, IN new_passhash character varying, IN new_role public."Role")
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE public.users
    SET login = new_login, passhash = new_passhash, role = new_role
    WHERE id = user_id;
END;$$;


--
-- TOC entry 260 (class 1255 OID 16416)
-- Name: update_wh1(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_wh1(IN p_good_id integer, IN p_good_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.warehouse1
    SET good_count = p_good_count
    WHERE good_id = p_good_id;
END;
$$;


--
-- TOC entry 261 (class 1255 OID 16417)
-- Name: update_wh2(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_wh2(IN p_good_id integer, IN p_good_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.warehouse2
    SET good_count = p_good_count
    WHERE good_id = p_good_id;
END;
$$;


--
-- TOC entry 262 (class 1255 OID 16418)
-- Name: use_cach_dummy(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.use_cach_dummy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE wh1_has_good BOOLEAN;
BEGIN
	SELECT EXISTS (
        SELECT 1
        FROM warehouse1 wh1
        WHERE wh1.good_id = NEW.good_id
    ) INTO wh1_has_good;
	
	IF wh1_has_good AND OLD.good_count > NEW.good_count THEN
		RAISE EXCEPTION 'На первом складе есть этот товар';
	END IF;
	RETURN NEW;
END;$$;


--
-- TOC entry 216 (class 1259 OID 16419)
-- Name: goods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.goods (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    priority double precision NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 16422)
-- Name: goods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.goods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3446 (class 0 OID 0)
-- Dependencies: 217
-- Name: goods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.goods_id_seq OWNED BY public.goods.id;


--
-- TOC entry 218 (class 1259 OID 16423)
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    good_id integer NOT NULL,
    good_count integer NOT NULL,
    create_date date DEFAULT CURRENT_DATE NOT NULL
);


--
-- TOC entry 219 (class 1259 OID 16427)
-- Name: sales_good_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_good_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3447 (class 0 OID 0)
-- Dependencies: 219
-- Name: sales_good_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_good_id_seq OWNED BY public.sales.good_id;


--
-- TOC entry 220 (class 1259 OID 16428)
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3448 (class 0 OID 0)
-- Dependencies: 220
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- TOC entry 215 (class 1259 OID 16384)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


--
-- TOC entry 221 (class 1259 OID 16429)
-- Name: top_five_performing_goods; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.top_five_performing_goods AS
 SELECT good_id,
    sum(good_count) AS total_count
   FROM public.sales s
  WHERE (create_date >= (CURRENT_DATE - '1 mon'::interval))
  GROUP BY good_id
  ORDER BY (sum(good_count)) DESC
 LIMIT 5;


--
-- TOC entry 222 (class 1259 OID 16433)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    login character varying(20) NOT NULL,
    id integer NOT NULL,
    passhash character varying NOT NULL,
    role public."Role" NOT NULL
);


--
-- TOC entry 223 (class 1259 OID 16438)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3449 (class 0 OID 0)
-- Dependencies: 223
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 224 (class 1259 OID 16439)
-- Name: warehouse1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse1 (
    id integer NOT NULL,
    good_id integer NOT NULL,
    good_count integer NOT NULL
);


--
-- TOC entry 225 (class 1259 OID 16442)
-- Name: warehouse1_good_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse1_good_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3450 (class 0 OID 0)
-- Dependencies: 225
-- Name: warehouse1_good_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse1_good_id_seq OWNED BY public.warehouse1.good_id;


--
-- TOC entry 226 (class 1259 OID 16443)
-- Name: warehouse1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3451 (class 0 OID 0)
-- Dependencies: 226
-- Name: warehouse1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse1_id_seq OWNED BY public.warehouse1.id;


--
-- TOC entry 227 (class 1259 OID 16444)
-- Name: warehouse2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse2 (
    id integer NOT NULL,
    good_id integer NOT NULL,
    good_count integer NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 16447)
-- Name: warehouse2_good_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse2_good_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3452 (class 0 OID 0)
-- Dependencies: 228
-- Name: warehouse2_good_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse2_good_id_seq OWNED BY public.warehouse2.good_id;


--
-- TOC entry 229 (class 1259 OID 16448)
-- Name: warehouse2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3453 (class 0 OID 0)
-- Dependencies: 229
-- Name: warehouse2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse2_id_seq OWNED BY public.warehouse2.id;


--
-- TOC entry 3259 (class 2604 OID 16449)
-- Name: goods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goods ALTER COLUMN id SET DEFAULT nextval('public.goods_id_seq'::regclass);


--
-- TOC entry 3260 (class 2604 OID 16450)
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- TOC entry 3261 (class 2604 OID 16451)
-- Name: sales good_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales ALTER COLUMN good_id SET DEFAULT nextval('public.sales_good_id_seq'::regclass);


--
-- TOC entry 3263 (class 2604 OID 16452)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3264 (class 2604 OID 16453)
-- Name: warehouse1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse1 ALTER COLUMN id SET DEFAULT nextval('public.warehouse1_id_seq'::regclass);


--
-- TOC entry 3265 (class 2604 OID 16454)
-- Name: warehouse1 good_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse1 ALTER COLUMN good_id SET DEFAULT nextval('public.warehouse1_good_id_seq'::regclass);


--
-- TOC entry 3266 (class 2604 OID 16455)
-- Name: warehouse2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse2 ALTER COLUMN id SET DEFAULT nextval('public.warehouse2_id_seq'::regclass);


--
-- TOC entry 3267 (class 2604 OID 16456)
-- Name: warehouse2 good_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse2 ALTER COLUMN good_id SET DEFAULT nextval('public.warehouse2_good_id_seq'::regclass);


--
-- TOC entry 3274 (class 2606 OID 16458)
-- Name: goods goods_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goods
    ADD CONSTRAINT goods_name_key UNIQUE (name);


--
-- TOC entry 3276 (class 2606 OID 16460)
-- Name: goods goods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goods
    ADD CONSTRAINT goods_pkey PRIMARY KEY (id);


--
-- TOC entry 3268 (class 2606 OID 16461)
-- Name: sales sales_good_count_check; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sales
    ADD CONSTRAINT sales_good_count_check CHECK ((good_count > 0)) NOT VALID;


--
-- TOC entry 3278 (class 2606 OID 16463)
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- TOC entry 3272 (class 2606 OID 16388)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3280 (class 2606 OID 16465)
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- TOC entry 3282 (class 2606 OID 16467)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3269 (class 2606 OID 16468)
-- Name: warehouse1 warehouse1_good_count_check; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.warehouse1
    ADD CONSTRAINT warehouse1_good_count_check CHECK ((good_count >= 0)) NOT VALID;


--
-- TOC entry 3284 (class 2606 OID 16470)
-- Name: warehouse1 warehouse1_good_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse1
    ADD CONSTRAINT warehouse1_good_id_key UNIQUE (good_id);


--
-- TOC entry 3286 (class 2606 OID 16472)
-- Name: warehouse1 warehouse1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse1
    ADD CONSTRAINT warehouse1_pkey PRIMARY KEY (id);


--
-- TOC entry 3270 (class 2606 OID 16473)
-- Name: warehouse2 warehouse2_good_count_check; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.warehouse2
    ADD CONSTRAINT warehouse2_good_count_check CHECK ((good_count >= 0)) NOT VALID;


--
-- TOC entry 3288 (class 2606 OID 16475)
-- Name: warehouse2 warehouse2_good_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse2
    ADD CONSTRAINT warehouse2_good_id_key UNIQUE (good_id);


--
-- TOC entry 3290 (class 2606 OID 16477)
-- Name: warehouse2 warehouse2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse2
    ADD CONSTRAINT warehouse2_pkey PRIMARY KEY (id);


--
-- TOC entry 3294 (class 2620 OID 16478)
-- Name: goods check_links; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_links BEFORE DELETE ON public.goods FOR EACH STATEMENT EXECUTE FUNCTION public.check_links();


--
-- TOC entry 3295 (class 2620 OID 16479)
-- Name: sales prevent_low_inventory_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_low_inventory_insert BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION public.prevent_low_inventory_insert();


--
-- TOC entry 3296 (class 2620 OID 16480)
-- Name: warehouse2 use_cache_dummy; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER use_cache_dummy BEFORE UPDATE ON public.warehouse2 FOR EACH ROW EXECUTE FUNCTION public.use_cach_dummy();


--
-- TOC entry 3291 (class 2606 OID 16481)
-- Name: sales fk_sales_goods; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT fk_sales_goods FOREIGN KEY (good_id) REFERENCES public.goods(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3292 (class 2606 OID 16486)
-- Name: warehouse1 fk_warehouse1_goods; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse1
    ADD CONSTRAINT fk_warehouse1_goods FOREIGN KEY (good_id) REFERENCES public.goods(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3293 (class 2606 OID 16491)
-- Name: warehouse2 fk_warehouse2_goods; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse2
    ADD CONSTRAINT fk_warehouse2_goods FOREIGN KEY (good_id) REFERENCES public.goods(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-12-09 19:56:16 MSK

--
-- PostgreSQL database dump complete
--

