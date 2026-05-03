SELECT 
    bowler,
    COUNT(*) AS total_balls,
    COUNT(CASE WHEN total_runs = 0 THEN 1 END) AS dot_balls,
    ROUND(COUNT(CASE WHEN total_runs = 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS dot_ball_pct
FROM deliveries
GROUP BY bowler
HAVING COUNT(*) > 300
ORDER BY dot_ball_pct DESC;