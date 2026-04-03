-- 1. TEAM PERFORMANCE QUERIES

-- Win % by Team

SELECT 
    match_winner AS team,
    COUNT(*) AS wins,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM matches), 2) AS win_percentage
FROM matches
WHERE match_winner IS NOT NULL
GROUP BY match_winner
ORDER BY win_percentage DESC;

-- Matches Played by Each Team

SELECT team, COUNT(*) AS matches_played
FROM (
    SELECT team1 AS Team FROM matches
    UNION ALL
    SELECT team2 FROM matches
) AS t
GROUP BY team
ORDER BY matches_played DESC;

-- Home vs Away Performance

SELECT 
    team1 AS home_team,
    COUNT(*) AS Home_matches,
    SUM(CASE WHEN match_winner = team1 THEN 1 ELSE 0 END) AS Home_wins
FROM matches
GROUP BY team1;

-- 2. TOSS IMPACT ANALYSIS

-- Toss Decision Vs Match Result

SELECT 
    toss_decision,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END) AS wins_after_toss
FROM matches
WHERE toss_decision IS NOT NULL
  AND toss_decision IN ('bat', 'field')
GROUP BY toss_decision;

-- 3. PLAYER PERFORMANCE (BATSMAN)

-- Top Batsman By Runs

SELECT batter, SUM(batter_runs) AS Total_runs
FROM deliveries
GROUP BY batter
ORDER BY Total_runs DESC
LIMIT 10;

-- Strike Rate of Batsman

SELECT batter, SUM(batter_runs)*100.0/COUNT(ball_number) AS Strike_Rate
FROM deliveries
GROUP BY batter
HAVING COUNT(ball_number)> 100
ORDER BY Strike_Rate DESC;

-- Consistent Players (High Average)

SELECT batter, SUM(batter_runs)/COUNT(DISTINCT match_id) AS Avg_Runs
FROM deliveries
GROUP BY batter
ORDER BY Avg_Runs DESC
LIMIT 100;

-- 4. PLAYER PERFORMANCE (BOWLERS)

-- Top Bowlers by Wickets

SELECT bowler, COUNT(*) AS wickets
FROM deliveries
WHERE is_wicket = true AND wicket_kind NOT IN ('run out')
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 15;

-- Best Economy Rate

SELECT bowler, SUM(total_runs)/(COUNT(ball_number)/6.0) AS Economy
FROM deliveries
GROUP BY bowler
HAVING COUNT(ball_number) > 2500
ORDER BY Economy ASC
LIMIT 15;

-- 5. MATCH & VENUE INSIGHTS

-- Average Score Per Venue Per Innings
 
SELECT venue, AVG(total_runs_per_innings) AS Avg_Runs_Per_Innings
FROM (
    SELECT match_id, innings, SUM(total_runs) AS total_runs_per_innings
    FROM deliveries
    GROUP BY match_id, innings
	) AS d	
JOIN matches AS m 
ON d.match_id = m.match_id
GROUP BY venue
ORDER BY Avg_Runs_Per_Innings DESC;

-- Average Score Per Venue Per Match

SELECT venue, AVG(total_runs_per_match) AS Avg_Runs_Per_Match
FROM (
    SELECT match_id, SUM(total_runs) AS total_runs_per_match
    FROM deliveries
    GROUP BY match_id
	) AS d
JOIN matches m 
ON d.match_id = m.match_id
GROUP BY venue
ORDER BY Avg_Runs_Per_Match DESC;

-- Win % Bat First Vs Chase

SELECT  CASE
			WHEN win_by_runs > 0 THEN 'Bat First'
			ELSE 'Chasing'
		END AS Strategy,
		COUNT(*) AS wins
FROM matches
GROUP BY strategy;

-- High Scoring Matches (>180 runs)

SELECT match_id , SUM(total_runs) AS total_Score
FROM deliveries
GROUP BY match_id, innings
HAVING SUM(total_runs) > 180
ORDER BY total_Score DESC;

-- 6. VENUE DOMINANCE

-- Performance of Team At Different Venue

SELECT venue, match_winner, COUNT(*) AS wins
FROM matches
GROUP BY venue, match_winner
ORDER BY wins DESC;

-- 7. PLAYER COMPARISON BASE

SELECT 
    batter,
    SUM(batter_runs) AS runs,
    COUNT(ball_number) AS balls,
    SUM(batter_runs) * 100.0 / COUNT(ball_number) AS strike_rate
FROM deliveries
GROUP BY batter
ORDER BY strike_rate DESC;



