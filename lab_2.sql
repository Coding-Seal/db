-- -- INSERT
-- -- insert new good
-- INSERT INTO goods ("name", "priority") VALUES ('new good', 1.5);

-- -- insert new sale
-- INSERT INTO sales ("good_id", "good_count", "create_date") VALUES ((SELECT ("id") FROM goods WHERE goods.name = 'new new good'), 6, CURRENT_DATE);

-- -- add new good,add some amount to w1 and w2
-- BEGIN;
-- 	INSERT INTO goods ("name", "priority") VALUES ('new new good', 3);
-- 	INSERT INTO warehouse1 ("good_id", "good_count") VALUES ((SELECT ("id") FROM goods WHERE goods.name = 'new new good'), 3);
-- 	INSERT INTO warehouse2 ("good_id", "good_count") VALUES ((SELECT ("id") FROM goods WHERE goods.name = 'new new good'), 5);
-- COMMIT;

-- -- add new good,add some amount to w1 and w2 check w1

-- DO
-- $do$
-- BEGIN
-- 	INSERT INTO goods ("name", "priority") VALUES ('latest good', 3);
-- 	INSERT INTO warehouse1 ("good_id", "good_count") VALUES ((SELECT ("id") FROM goods WHERE goods.name = 'latest good'), 3);
-- 	INSERT INTO warehouse2 ("good_id", "good_count") VALUES ((SELECT ("id") FROM goods WHERE goods.name = 'latest good'), 5);
	
-- 	IF ((SELECT SUM(warehouse1.good_count) FROM warehouse1) > 10) THEN
-- 		ROLLBACK;
-- 	END IF;
	
-- COMMIT;
-- END
-- $do$

-- -- SELECT
-- -- Select  goods asc name desc prior
-- SELECT * FROM goods ORDER BY goods.name ASC, goods.priority DESC;

-- -- SUM goods on a date
-- SELECT SUM("good_count") FROM sales WHERE sales.create_date = CURRENT_DATE;

-- -- Get all sales with good of priority less then
-- SELECT * FROM sales WHERE sales.good_id IN (SELECT "id" FROM goods WHERE goods.priority < 1);

-- -- Get all goods that are not in warehouse 1
-- SELECT * FROM goods WHERE goods.id NOT IN (SELECT "good_id" FROM warehouse1);

-- -- ALL sales and all goods
-- SELECT * FROM sales RIGHT JOIN goods ON sales.good_id = goods.id;

-- SELECT * FROM (SELECT * FROM goods LEFT JOIN 
-- 	(SELECT "good_id" FROM sales WHERE sales.create_date = CURRENT_DATE )as sales_today 
-- 	ON goods.id = sales_today.good_id) AS outp WHERE outp.good_id IS NULL;

-- SELECT SUM(w.good_count) FROM 
-- 	(SELECT * FROM warehouse1 UNION SELECT * FROM warehouse2) AS w 
-- 	WHERE w.good_id = 3;

-- SELECT * FROM goods LEFT JOIN
-- 	(SELECT s.good_id, SUM(s.good_count) FROM sales AS s 
-- 	WHERE s.create_date BETWEEN '2005-09-15' AND '2025-07-23' 
-- 	GROUP BY s.good_id ORDER BY s.good_id DESC LIMIT 5) as s
-- 	ON goods.id = s.good_id;

-- DELETE FROM sales WHERE sales.create_date < '2005-09-15';

-- DELETE FROM goods WHERE NOT EXISTS (SELECT 1 FROM sales WHERE goods.id = sales.good_id);

-- DELETE FROM goods WHERE goods.name = 'some good';



-- DELETE FROM warehouse1 as w1 USING (SELECT * FROM goods ORDER BY goods.priority LIMIT 1) AS n WHERE w1.good_id = n.id;
-- BEGIN;
-- DELETE FROM warehouse1 w WHERE w.good_id IN (SELECT goods.id FROM goods ORDER BY goods.priority LIMIT 1);
-- END;

-- BEGIN;
-- DELETE FROM warehouse1 w WHERE w.good_id IN (SELECT goods.id FROM goods ORDER BY goods.priority LIMIT 1);
-- ROLLBACK;


-- UPDATE warehouse1 as w1 SET good_count = 5 
-- 	WHERE w1.good_id IN 
-- 	(SELECT goods.id FROM goods WHERE goods.name = 'new new good');

-- UPDATE warehouse1 as w1 SET good_count = good_count - 5 
-- 	WHERE w1.good_id IN 
	-- (SELECT goods.id FROM goods WHERE goods.name = 'new new good');

-- DO
-- $do$
-- DECLARE
-- 	good_count1 warehouse1.good_count%type;
-- 	selected_good_id goods.id%type;
	
-- BEGIN
-- 	SELECT goods.id FROM goods INTO selected_good_id WHERE goods.name = 'new new good';
-- 	SELECT w1.good_count FROM warehouse1 as w1 INTO good_count1
-- 		WHERE w1.good_id = selected_good_id;
-- 	IF (good_count1 >= 5) THEN
-- 		UPDATE warehouse1 as w1 SET good_count = good_count - 5 
-- 			WHERE w1.good_id = selected_good_id;
-- 	ELSE
-- 		UPDATE warehouse1 as w1 SET good_count = 0 
-- 			WHERE w1.good_id = selected_good_id;
-- 		UPDATE warehouse2 as w2 SET good_count = good_count - 5 + good_count1 
-- 			WHERE w2.good_id = selected_good_id;
-- 	END IF;
-- COMMIT;
-- END;
-- $do$


DO
$do$
DECLARE
	good_id_to_delete goods.id%type;
	good_id_to_replace goods.id%type;
BEGIN
	SELECT goods.id FROM goods INTO good_id_to_delete WHERE goods.name = 'new good';
	SELECT goods.id FROM goods INTO good_id_to_replace WHERE goods.name = 'latest good';

	UPDATE sales SET good_id = good_id_to_replace WHERE good_id = good_id_to_delete;
	DELETE FROM sales WHERE sales.good_id = good_id_to_replace;

	COMMIT;
END
$do$
	
