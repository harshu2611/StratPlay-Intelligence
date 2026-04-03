-- ════════════════════════════════════════════════════════════
-- SECTION 4: HEAD-TO-HEAD & MATCH INSIGHTS
-- ════════════════════════════════════════════════════════════

-- 4.1  Head-to-Head Win Record Between All Team Pairs
SELECT
    LEAST(team1, team2)    AS team_a,
    GREATEST(team1, team2) AS team_b,
    COUNT(*)               AS total_matches,
    SUM(CASE WHEN match_winner = LEAST(team1, team2)    THEN 1 ELSE 0 END) AS team_a_wins,
    SUM(CASE WHEN match_winner = GREATEST(team1, team2) THEN 1 ELSE 0 END) AS team_b_wins,
    SUM(CASE WHEN result IN ('tie','no result')          THEN 1 ELSE 0 END) AS draws_no_result
FROM matches
WHERE result NOT IN ('no result')
GROUP BY LEAST(team1, team2), GREATEST(team1, team2)
ORDER BY total_matches DESC;


-- 4.2  Successful Run Chase Analysis — Score Distribution & Win Rate
WITH chases AS (
    SELECT
        m.match_id,
        m.season,
        m.venue,
        SUM(CASE WHEN d.innings = 1 THEN d.total_runs ELSE 0 END) AS target_set,
        SUM(CASE WHEN d.innings = 2 THEN d.total_runs ELSE 0 END) AS chased,
        MAX(CASE WHEN d.innings = 2 THEN d.team_batting END)       AS chasing_team,
        m.match_winner
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    WHERE d.is_super_over = FALSE AND m.toss_decision = 'field'
    GROUP BY m.match_id, m.season, m.venue, m.match_winner
)
SELECT
    CASE
        WHEN target_set BETWEEN 100 AND 149 THEN '100-149'
        WHEN target_set BETWEEN 150 AND 169 THEN '150-169'
        WHEN target_set BETWEEN 170 AND 189 THEN '170-189'
        WHEN target_set BETWEEN 190 AND 209 THEN '190-209'
        ELSE '210+'
    END AS target_bracket,
    COUNT(*)                                                      AS total_chases,
    SUM(CASE WHEN chasing_team = match_winner THEN 1 ELSE 0 END) AS successful_chases,
    ROUND(SUM(CASE WHEN chasing_team = match_winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS chase_success_pct
FROM chases
GROUP BY target_bracket
ORDER BY target_bracket;


-- 4.3  Player of the Match — Most Awards
SELECT
    m.player_of_match::text  AS player,
    COUNT(*)                  AS pom_awards,
    COUNT(DISTINCT m.season)  AS seasons_won_in
FROM matches m
WHERE m.player_of_match IS NOT NULL
  AND m.result NOT IN ('no result')
GROUP BY m.player_of_match
ORDER BY pom_awards DESC
LIMIT 20;
