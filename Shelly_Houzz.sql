SELECT *
FROM public."houzz_1"

--Delete 18 records those have 'ts' = 0:
DELETE FROM public."houzz_1"
WHERE ts = 0

SELECT *
FROM public."houzz_1"
WHERE ts = 0
/*********************************Sanity Checking****************************************************/
/*sanity checking rule #1--all users should receive each newsletter once.*/
SELECT 
DISTINCT(user_id),nl_id, 
COUNT(event_type) AS count
FROM public."houzz_1"
WHERE event_type = 'nlsent'
GROUP BY user_id, nl_id
HAVING count(event_type)> 1 -- Results: No duplicated data were detected.


/*sanity checking rule #2-all newsletters must have received before they were opened.*/
--Meaning: we need to find out all the records: 1) were recorded opened, but never recorded sent;
--2) the first open time was before the receiving time;
WITH receivers AS
(SELECT 
 user_id, 
 nl_id,
 ts 
 FROM public."houzz_1"
 WHERE event_type = 'nlsent'
 ORDER BY 1),

openers AS
(SELECT 
 user_id, 
 nl_id,
 ts 
 FROM public."houzz_1"
 WHERE event_type = 'nlpv'
 ORDER BY 1)

SELECT o.user_id, 
o.nl_id,
MIN(o.ts) - r.ts AS gap
INTO TEMP TABLE rule2
FROM openers AS o
LEFT JOIN receivers AS r
ON o.user_id = r.user_id
AND o.nl_id = r.nl_id
GROUP BY 1, 2, r.ts
HAVING MIN(o.ts) - r.ts <=0
OR r.ts IS NULL
ORDER BY 3
--Results: 18 erroneous records were found (7 didn't match the time sequences, 11 were not recorded 'sent' while were recorded 'opened');

SELECT *
FROM rule2

/*Update table by taking out the erroneous data found on rule#2 -- 95 rows were deleted*/
DELETE FROM public."houzz_1"
WHERE user_id IN
 (SELECT user_id
 FROM rule2)
AND nl_id IN
  (SELECT nl_id
 FROM rule2)

/*sanity checking rule 3-all newsletters must have opened before they were clicked.*/
--Meaning: we need to find out all the records: 1) were recorded clicked, but never recorded opened;
--2) the first clicking time was before the first opening time;
WITH openers AS
(SELECT 
 user_id, 
 nl_id,
 ts 
 FROM public."houzz_1"
 WHERE event_type = 'nlpv'
 ORDER BY 1),
 
clickers AS
(SELECT 
 user_id, 
 nl_id,
 ts 
 FROM public."houzz_1"
 WHERE event_type = 'nllc'
 ORDER BY 1) 
 
SELECT c.user_id, 
c.nl_id,
MIN(c.ts) - MIN(o.ts) AS gap
INTO TEMP TABLE rule3
FROM clickers AS c
LEFT JOIN openers AS o
ON c.user_id = o.user_id
AND c.nl_id = o.nl_id
GROUP BY 1,2
HAVING MIN(c.ts) - MIN(o.ts) <=0
OR MIN(o.ts) IS NULL
ORDER BY 3
--Results: 142 erroneous records were found (21 didn't match the time sequences, others were not recorded 'opened' while were recorded 'clicked';


/*Update table by taking out the erroneous data found on rule#2 -- 736 rows were deleted*/
DELETE FROM public."houzz_1"
WHERE user_id IN
 (SELECT user_id
 FROM rule3)
AND nl_id IN
  (SELECT nl_id
 FROM rule3)


/*********************************open_rate analysis****************************************************/
/*1.	How many newsletters were sent vs. opened for nl_id 2885 and 2912? What’s the overall open rate for each newsletter?*/
DROP TABLE IF EXISTS open_rate;
--Count newsletter were sent:
SELECT nl_id,
COUNT(*) AS num_of_views 
INTO TEMP TABLE v1
FROM (
    SELECT DISTINCT user_id,
    nl_id
    FROM public."houzz_1" 
    WHERE event_type = 'nlsent'
) AS subquery
GROUP BY 1

--Count newsletter were opened:
SELECT nl_id,
COUNT(*) AS num_of_opens
INTO TEMP TABLE o1
FROM (
    SELECT DISTINCT user_id,
    nl_id
    FROM public."houzz_1" 
    WHERE event_type = 'nlpv'
) AS subquery
GROUP BY 1
 
--Calculate the open rate for each newsletter:
SELECT o1.nl_id,
v1.num_of_views,
o1.num_of_opens,
ROUND( o1.num_of_opens* 1.0 / v1.num_of_views* 1.0,2) AS open_rate
INTO TEMP TABLE open_rate
FROM o1
INNER JOIN v1
USING (nl_id)
GROUP BY 1,2,3
ORDER BY 4 DESC  --nl 2873 has the best open rate.


SELECT *
FROM open_rate


/*2.	What % of users opened the email within 1, 2, 3, 4, 5, 6, 7 days?*/
DROP TABLE IF EXISTS gap;

--Calculate the gap between the first open date and the sent date:
WITH sent_dt AS
(SELECT 
 DISTINCT user_id, 
 nl_id,
 dt
 FROM public."houzz_1"
 WHERE event_type = 'nlsent'
 ORDER BY 1),

open_dt AS
(SELECT 
 DISTINCT user_id, 
 nl_id,
 dt
 FROM public."houzz_1"
 WHERE event_type = 'nlpv'
 ORDER BY 1)

SELECT od.user_id, 
od.nl_id,
MIN(od.dt) - sd.dt AS gap
INTO TEMP TABLE gap
FROM open_dt AS od
LEFT JOIN sent_dt AS sd
ON od.user_id = sd.user_id
AND od.nl_id = sd.nl_id
GROUP BY 1, 2, sd.dt

--Calculate the overall percentage:
SELECT gap,
COUNT(user_id) AS openers,
ROUND(
COUNT(user_id) * 100.0 / (SELECT COUNT(user_id) FROM gap),
                          2
                          ) AS percentage_of_users
FROM gap
GROUP BY gap
ORDER BY gap

--Percentage of users opened by gap for each newsletter:
SELECT gap,
nl_id,
COUNT(user_id) AS openers,
ROUND(
COUNT(user_id) * 100.0 / (SELECT COUNT(user_id) FROM gap),
                          2
                          ) AS percentage_of_users
FROM gap
GROUP BY 2,1
ORDER BY gap

/*3.  Make a graph of the CTRs by link position for nl_id 2873 and 2885.*/
--Define CTR as: # clicks at a position / # opens
DROP TABLE IF EXISTS c1;

--Count clicks for each newsletter
SELECT nl_id,
COUNT(*) AS num_of_clicks,
event_type_param AS click_position
INTO TEMP TABLE c1
FROM (
    SELECT DISTINCT user_id,
    nl_id,
    event_type_param
    FROM public."houzz_1" 
    WHERE event_type = 'nllc'
    AND event_type_param NOT IN ('0', 'pv1', 'pv2')
) AS subquery
GROUP BY 1, event_type_param


--Calculate CTR for each newsletter:
DROP TABLE IF EXISTS CTR;
SELECT c1.num_of_clicks,
o1.num_of_opens,
ROUND( c1.num_of_clicks* 1.0 / o1.num_of_opens* 1.0,4) AS CTR,
o1.nl_id,
c1.click_position
INTO TEMP TABLE CTR
FROM c1
INNER JOIN o1
USING (nl_id)
GROUP BY 4,5,1,2
ORDER BY 4 DESC  

SELECT *
FROM CTR
