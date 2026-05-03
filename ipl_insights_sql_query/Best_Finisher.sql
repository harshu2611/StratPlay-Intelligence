SELECT 
    d.batsman,
    AVG(runs_in_match) AS avg_runs
FROM (
    SELECT 
        match_id,
        batsman,
        SUM(batsman_runs) AS runs_in_match
    FROM deliveries
    GROUP BY match_id, batsman
) d
JOIN matches m ON d.match_id = m.match_id
WHERE m.winner IS NOT NULL
GROUP BY d.batsman
HAVING COUNT(*) > 20
ORDER BY avg_runs DESC;