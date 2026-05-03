SELECT 
    batsman,
    bowler,
    SUM(batsman_runs) AS runs,
    COUNT(*) AS balls,
    COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS dismissals
FROM deliveries
GROUP BY batsman, bowler
HAVING COUNT(*) > 50
ORDER BY dismissals DESC, runs DESC;
