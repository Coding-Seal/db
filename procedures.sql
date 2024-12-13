CREATE VIEW FewGoodsWH1 AS
	SELECT * FROM warehouse1 WHERE good_count < 5;

SELECT 
    s.good_id AS good_id,
    SUM(s.good_count) AS total_count
FROM 
    sales s
WHERE 
    s.create_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY 
    s.good_id
ORDER BY 
    total_count DESC
LIMIT 5;


-- CREATE OR REPLACE FUNCTION get_products_to_transport()
-- RETURNS TABLE(good_name VARCHAR(20), good_count INTEGER, priority DOUBLE PRECISION)AS 
-- $$
-- SELECT goods.name, SUM(warehouse2.good_count) AS "count", goods.priority FROM
-- 	goods JOIN warehouse2 ON warehouse2.good_id = goods.id 
-- 	GROUP BY goods.id ORDER BY goods.priority DESC;
-- $$ 
-- LANGUAGE SQL;

-- SELECT * FROM get_products_to_transport();

-- CREATE OR REPLACE FUNCTION get_products_to_transport_num(n INT)
-- RETURNS TABLE(good_name VARCHAR(20), good_count INTEGER, priority DOUBLE PRECISION)
-- AS $$;
--     SELECT * FROM get_products_to_transport() LIMIT n;
-- $$ LANGUAGE SQL;

-- SELECT * FROM get_products_to_transport_num(3);

-- CREATE OR REPLACE FUNCTION get_dates_product_saled_more(lhs INT, rhs INT)
-- RETURNS TABLE(sale_date DATE)
-- AS $$;
--     SELECT lhs_table.create_date FROM (
-- 		SELECT SUM(good_count) AS total_count, create_date FROM sales WHERE sales.good_id = lhs GROUP BY sales.create_date) AS lhs_table
-- 		JOIN 
-- 		(SELECT SUM(good_count) AS total_count, create_date FROM sales WHERE sales.good_id = rhs GROUP BY sales.create_date) AS rhs_table
-- 		ON lhs_table.create_date = rhs_table.create_date AND lhs_table.total_count > rhs_table.total_count;
-- $$ LANGUAGE SQL;

-- -- SELECT * FROM get_dates_product_saled_more(3, 1);

CREATE OR REPLACE FUNCTION get_best_performing_good(lhs DATE, rhs DATE)
RETURNS TABLE(good_id INT, total_count INT)
AS $$;
    SELECT sales.good_id AS good_id, SUM(sales.good_count) AS total_count 
		FROM sales WHERE sales.create_date BETWEEN lhs AND rhs
		GROUP BY sales.good_id ORDER BY total_count DESC LIMIT 1;
$$ LANGUAGE SQL;

SELECT * FROM get_best_performing_good('2024-08-12', '2024-11-13');

-- CREATE OR REPLACE FUNCTION get_worst_performing_good(lhs DATE, rhs DATE)
-- RETURNS TABLE(good_id INT, total_count INT)
-- AS $$;
--     SELECT sales.good_id AS good_id, SUM(sales.good_count) AS total_count 
-- 		FROM sales WHERE sales.create_date BETWEEN lhs AND rhs
-- 		GROUP BY sales.good_id ORDER BY total_count ASC LIMIT 1;
-- $$ LANGUAGE SQL;

-- -- SELECT * FROM get_worst_performing_good('2024-08-12', '2024-11-13');

-- CREATE OR REPLACE FUNCTION prevent_low_inventory_insert()
-- RETURNS TRIGGER
-- AS $low_inventory$
-- 		DECLARE stock1 INT;
-- 	    DECLARE stock2 INT;
-- 	    BEGIN
-- 	    -- Получаем количество товара на первом складе
-- 	    SELECT COALESCE(wh1.good_count, 0) INTO stock1
-- 	    FROM warehouse1 wh1
-- 	    WHERE wh1.good_id = NEW.good_id;
	    
-- 	    -- Получаем количество товара на втором складе
-- 	    SELECT COALESCE(wh2.good_count, 0) INTO stock2
-- 	    FROM warehouse2 wh2
-- 	    WHERE wh2.good_id = NEW.good_id;
		
-- 	    -- Проверяем, достаточно ли товара на обоих складах
-- 	    IF NEW.good_count > stock1+stock2 THEN
-- 	        RAISE EXCEPTION 'Недостаточно товара на складе для выполнения заказа';
-- 	    END IF;
-- 		RETURN NEW;
-- 	END;
-- $low_inventory$ LANGUAGE plpgsql;


-- CREATE OR REPLACE TRIGGER prevent_low_inventory_insert
-- 	BEFORE INSERT ON sales FOR EACH ROW
-- 	EXECUTE FUNCTION prevent_low_inventory_insert();

-- CREATE OR REPLACE FUNCTION low_good_count_insert()
-- RETURNS TRIGGER
-- AS $low_good_count$
-- 	BEGIN
-- 	    IF NEW.good_count < 1 THEN
-- 	        RAISE EXCEPTION 'Слишком маленькое кол-во товара в заявке (меньше 1)';
-- 	    END IF;
-- 		RETURN NEW;
-- 	END;
-- $low_good_count$ LANGUAGE plpgsql;

-- CREATE OR REPLACE TRIGGER prevent_low_inventory_insert
-- 	BEFORE INSERT ON sales FOR EACH STATEMENT
-- 	EXECUTE FUNCTION low_good_count_insert();

CREATE OR REPLACE FUNCTION use_cache_dummy()
RETURNS TRIGGER
AS $use_cache_dummy$
	DECLARE wh1_has_good BOOLEAN;
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
	END;
$use_cache_dummy$ LANGUAGE plpgsql;

-- CREATE OR REPLACE TRIGGER use_cache_dummy
-- 	BEFORE UPDATE ON warehouse2 FOR EACH ROW
-- 	EXECUTE FUNCTION use_cache_dummy();

-- CREATE OR REPLACE FUNCTION check_links()
-- RETURNS TRIGGER
-- AS $check_links$
-- 	BEGIN
-- 		IF EXISTS (	SELECT 1 FROM sales WHERE sales.good_id = OLD.id) THEN
-- 	        RAISE EXCEPTION 'Еще есть заявки на товар';
-- 	    END IF;

-- 		IF EXISTS (	SELECT 1 FROM warehouse1 WHERE warehouse1.good_id = OLD.id) THEN
-- 	        RAISE EXCEPTION 'Товар лежит на 1 складе';
-- 	    END IF;
		
-- 		IF EXISTS (	SELECT 1 FROM warehouse2 WHERE warehouse2.good_id = OLD.id) THEN
-- 			RAISE EXCEPTION 'Товар лежит на 2 складе';
-- 	    END IF;
-- 		RETURN NEW;
-- 	END;
-- $check_links$ LANGUAGE plpgsql;

-- CREATE OR REPLACE TRIGGER check_links
-- 	BEFORE DELETE ON goods FOR EACH STATEMENT
-- 	EXECUTE FUNCTION check_links();



CREATE OR REPLACE PROCEDURE forecast_demand(
    p_good_id INT,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql AS $$
DECLARE
    demand_cursor CURSOR FOR
        SELECT create_date, SUM(good_count) AS good_count 
        FROM sales 
        WHERE good_id = p_good_id AND create_date BETWEEN p_start_date AND p_end_date
        GROUP BY create_date 
        ORDER BY create_date;

    v_record RECORD;
    v_avg_demand DOUBLE PRECISION;
	v_last_demand DOUBLE PRECISION;
BEGIN
    -- Создаем временную таблицу для хранения данных о спросе
    CREATE TEMPORARY TABLE temp_demand_data (
        day_number INT,
        good_count DOUBLE PRECISION
    );

    OPEN demand_cursor;

    LOOP
        FETCH demand_cursor INTO v_record; 
        EXIT WHEN NOT FOUND;

        INSERT INTO temp_demand_data (day_number, good_count) 
        VALUES (EXTRACT(DOY FROM v_record.create_date), v_record.good_count);
    END LOOP;

    CLOSE demand_cursor;

    WHILE (SELECT COUNT(*) FROM temp_demand_data) > 2 LOOP
        WITH averaged AS (
            SELECT 
                (d1.good_count::DOUBLE PRECISION + d2.good_count::DOUBLE PRECISION) / 2 AS avg_good_count,
                d1.day_number AS day_number
            FROM 
                (SELECT * FROM temp_demand_data ORDER BY day_number LIMIT 1) d1,
                (SELECT * FROM temp_demand_data ORDER BY day_number LIMIT 1 OFFSET 1) d2
        )
        INSERT INTO temp_demand_data (day_number, good_count)
        SELECT day_number, avg_good_count FROM averaged;

        DELETE FROM temp_demand_data WHERE day_number = (SELECT MIN(day_number) FROM temp_demand_data);
    END LOOP;

    SELECT good_count INTO v_avg_demand FROM temp_demand_data LIMIT 1;
	SELECT good_count INTO v_last_demand FROM temp_demand_data LIMIT 1 OFFSET 1;

	
	
	-- RAISE NOTICE 'Прогнозируемый спрос на последний день %: %', p_good_id, v_last_demand;

    RAISE NOTICE 'Прогнозируемый спрос на следующий день для товара %: %', p_good_id, v_last_demand +(v_last_demand - v_avg_demand);

    DROP TABLE IF EXISTS temp_demand_data;
END;
$$
;

CALL forecast_demand(1, '2024-11-17', '2024-11-22');


