-- 1.	Создать запрос на выборку сувениров по материалу

SELECT s.id AS souvenir_id, s.short_name AS souvenir_name, m.id AS material_id, m.name AS material_name
FROM souvenirs AS s
JOIN souvenir_materials AS m ON s.id_material = m.id
WHERE m.name = 'металл';

-- 2.	Создать запрос на выборку поставок сувениров за промежуток времени

SELECT sp.id, sp.data, ps.amount, ps.price, s.short_name AS souvenir_name,  pr.name AS provider_name,  pr.contact_person
FROM souvenir_procurements AS sp
JOIN procurement_souvenirs AS ps ON sp.id=ps.id_procurement
JOIN souvenirs AS s ON s.id=ps.id_souvenir
JOIN providers AS pr ON pr.id=sp.id_provider
WHERE sp.data BETWEEN '2024-01-01' AND '2024-12-01';

-- 3.	Создать запрос на выборку сувениров по категориям 
-- и отсортировать по популярности от самого непопулярного

SELECT s.id AS souvenir_id, s.short_name AS souvenir_name, s.rating, sc.name AS category_name
FROM souvenirs AS s
JOIN souvenir_categories AS sc ON s.id_category = sc.id
WHERE sc.name = 'Зонты-трости'
ORDER BY s.rating ASC;

-- 4.	Создать запрос на выборку всех поставщиков, поставляющих категорию товара

SELECT DISTINCT pr.id AS provider_id, pr.name AS provider_name, pr.contact_person, sc.name AS category_name
FROM providers AS pr
JOIN souvenir_procurements AS sp ON pr.id = sp.id_provider
JOIN procurement_souvenirs AS ps ON sp.id = ps.id_procurement
JOIN souvenirs AS s ON ps.id_souvenir = s.id
JOIN souvenir_categories AS sc ON s.id_category = sc.id
WHERE sc.name = 'Стилусы'

-- 5.	Создать запрос на выборку поставок сувениров за промежуток времени и отсортировать по статусу

SELECT sp.id AS souvenir_id, sp.data, s.short_name AS souvenir_name, st.id AS status_id, st.name AS status
FROM souvenir_procurements AS sp
JOIN procurement_souvenirs AS ps ON sp.id=ps.id_procurement
JOIN souvenirs AS s ON s.id=ps.id_souvenir
JOIN procurement_statuses AS st ON st.id=sp.id_status
WHERE sp.data BETWEEN '2024-01-01' AND '2024-12-01'
ORDER BY st.id ASC;

-- 6.	Создать объект для вывода категорий, в зависимости от выбранной

SELECT * FROM souvenir_categories AS c
WHERE c.id_parent = (SELECT id FROM souvenir_categories WHERE name = 'Аксессуары для мобильных');

-- 7.	Создать объект для проверки правильности занесения данных в таблицу SouvenirsCategories

CREATE OR REPLACE FUNCTION check_souvenir_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- name не пустой
    IF NEW.name IS NULL OR NEW.name = '' THEN
        RAISE EXCEPTION 'name cannot be empty';
    END IF;

    -- id_parent существуюет
    IF NEW.id_parent IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM souvenir_categories WHERE ID = NEW.id_parent
    ) THEN
        RAISE EXCEPTION 'id_parent % does not exist', NEW.id_parent;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_category
BEFORE INSERT OR UPDATE ON souvenir_categories
FOR EACH ROW
EXECUTE FUNCTION check_souvenir_categories()

-- -- Проверка
-- INSERT INTO souvenir_categories (id, id_parent, name)
-- VALUES(1, 3, 'чехол')

-- 8.	Создать объект оповещения пользователя при отсутствии поставок товаров,
-- отсутствующих на складе или количество которых меньше чем 50 шт.

CREATE OR REPLACE FUNCTION notify_stock_count()
RETURNS TRIGGER AS $$
DECLARE
    notification TEXT;
    stock_count INT;
BEGIN
    SELECT SUM(amount) INTO stock_count
    FROM souvenir_stores
    WHERE id_souvenir = NEW.id_souvenir;

    IF stock_count IS NULL OR stock_count < 50 THEN
        notification := 'Оповещение об отсутствии поставки товара ' || NEW.id_souvenir || 
                        ' (количество: ' || COALESCE(stock_count, 0) || ' шт.)';
        RAISE NOTICE '%', notification;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_stock_count
BEFORE INSERT OR UPDATE ON souvenir_stores
FOR EACH ROW
EXECUTE FUNCTION notify_stock_count();


-- -- Проверка
-- UPDATE souvenir_stores
-- SET amount = 15
-- WHERE id_souvenir = 8519;

