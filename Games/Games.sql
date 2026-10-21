/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Исмагилов Самат
 * Дата: 11.02.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
WITH users_pay AS (SELECT COUNT(id) AS total_players, SUM(
                                CASE
	                    	  	WHEN payer=1 THEN 1
	                    		ELSE 0
	                    	    END) AS paying_players
FROM fantasy.users)
SELECT *, paying_players::float / total_players AS paying_share_percent
FROM users_pay;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH race_pay AS (
SELECT r.race, SUM(CASE
	             	WHEN u.payer=1 THEN 1
	             	ELSE 0
	              END) AS paying_players, COUNT(u.id) AS users_count
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY race
)
SELECT *, paying_players::float / users_count AS paying_share_percent
FROM race_pay;

-- Задача 2. Исследование внутриигровых покупок

-- 2.1. Статистические показатели по полю amount:
SELECT COUNT(transaction_id) AS total_transactions, SUM(amount) AS total_amount, MIN(amount) AS min_amount, 
       MAX(amount) AS max_amount, AVG(amount) AS avg_amount, 
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount, STDDEV(amount) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
WITH amount_stats AS (SELECT SUM(CASE
	   WHEN amount=0 THEN 1
	   ELSE 0
	   END) AS zero_amount_transactions, COUNT(transaction_id) AS total_transactions
FROM fantasy.events)
SELECT zero_amount_transactions, zero_amount_transactions::float / total_transactions AS zero_amount_percentage
FROM amount_stats;

-- 2.3: Популярные эпические предметы:
SELECT i.game_items, COUNT(e.transaction_id) AS item_sales_count, COUNT(e.transaction_id)::float / (SELECT COUNT(transaction_id)
FROM fantasy.events
WHERE amount != 0) AS share_of_total_sales,
COUNT(DISTINCT e.id)::float / (SELECT COUNT(DISTINCT id)
FROM fantasy.events
WHERE amount != 0) AS share_of_buyers
FROM fantasy.events AS e
LEFT JOIN fantasy.items AS i ON i.item_code = e.item_code
WHERE amount != 0
GROUP BY i.game_items
ORDER BY item_sales_count;



-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH player_avg_price AS (
    SELECT 
        u.id,
        u.race_id,
        AVG(e.amount) AS avg_price_per_purchase_per_player
    FROM fantasy.users u
    LEFT JOIN fantasy.events e ON u.id = e.id AND e.amount > 0
    GROUP BY u.id, u.race_id
    HAVING COUNT(e.transaction_id) > 0
)
SELECT r.race, COUNT(DISTINCT u.id) AS total_registered, COUNT(DISTINCT CASE 
	                                          WHEN e.transaction_id IS NOT NULL THEN u.id 
											  END) AS players_with_purchases, COUNT(DISTINCT CASE 
	                                          WHEN e.transaction_id IS NOT NULL THEN u.id 
											  END)::float / COUNT(DISTINCT u.id) AS share_percent,
											  COUNT(DISTINCT CASE 
											  	WHEN e.transaction_id IS NOT NULL AND payer=1 THEN u.id
											  END
											  )::float / COUNT(DISTINCT CASE 
	                                          WHEN e.transaction_id IS NOT NULL THEN u.id 
											  END) AS payers_share_among_purchasers, 
											  COUNT(e.transaction_id)::float / COUNT(DISTINCT 
											                                         CASE 
											                                         	WHEN e.transaction_id IS NOT NULL THEN u.id
											                                         END) AS avg_purchases_per_purchaser,
											  AVG(p.avg_price_per_purchase_per_player) AS avg_price_per_purchase_per_player,
											  SUM(e.amount)::float / COUNT(DISTINCT 
											                                         CASE 
											                                         	WHEN e.transaction_id IS NOT NULL THEN u.id
											                                         END) AS avg_revenue_per_purchaser
FROM fantasy.users AS u
LEFT JOIN fantasy.events AS e ON u.id = e.id AND e.amount != 0
LEFT JOIN fantasy.race AS r ON r.race_id = u.race_id
LEFT JOIN player_avg_price p ON u.id = p.id
GROUP BY r.race;











