use ipl;
select * from ball_by_ball;
select * from batting_style;
select * from bowling_style;
select * from city;
select * from country;
select * from extra_runs;
select * from extra_type;
select * from matches;
select * from out_type;
select * from outcome;
select * from player;
select * from player_match;
select * from rolee;
select * from season;
select * from team;
select * from toss_decision;
select * from umpire;
select * from venue;
select * from wicket_taken;
select * from win_by;
----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- -------------------------- OBJECTIVE QUESTIONS---------------------------------------------- --
-- 1.	List the different dtypes of columns in table “ball_by_ball” (using information schema)

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ball_by_ball';
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- 2.What is the total number of runs scored in 1st season by RCB (bonus: also include the extra runs using the extra runs table)
SELECT 
    SUM(b.Runs_Scored) + COALESCE(SUM(e.Extra_Runs), 0) AS Total_Runs
FROM ball_by_ball b
JOIN matches m 
    ON b.Match_Id = m.Match_Id
JOIN Team t 
    ON b.Team_Batting = t.Team_Id
LEFT JOIN extra_runs e 
    ON b.Match_Id = e.Match_Id
    AND b.Over_Id = e.Over_Id
    AND b.Ball_Id = e.Ball_Id
    AND b.Innings_No = e.Innings_No
WHERE t.Team_Name = 'Royal Challengers Bangalore'
  AND m.Season_Id = (
      SELECT MIN(Season_Id)
      FROM matches
  );
-----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- 3.How many players were more than the age of 25 during season 2014?

SELECT 
    '2014' AS Season,
    COUNT(DISTINCT p.Player_Id) AS Player_Count_age_more_than_25
FROM player p
JOIN player_match pm 
    ON p.Player_Id = pm.Player_Id
JOIN matches m 
    ON pm.Match_Id = m.Match_Id
JOIN season s 
    ON m.Season_Id = s.Season_Id
WHERE s.Season_Year = 2014
  AND TIMESTAMPDIFF(YEAR, p.DOB, '2014-04-01') > 25;
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- 4.How many matches did RCB win in 2013?

SELECT COUNT(*) AS Matches_won_in_2013
FROM matches m JOIN season s 
ON m.Season_Id=s.Season_Id
WHERE s.Season_Year=2013
AND m.Match_Winner=2;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
-- 5.List the top 10 players according to their strike rate in the last 4 seasons
SELECT
    p.Player_Name,
    ROUND((SUM(bb.Runs_Scored) * 100.0) / COUNT(bb.Ball_Id), 2) AS Strike_Rate
FROM player p
JOIN ball_by_ball bb
    ON p.Player_Id = bb.Striker
JOIN matches m
    ON bb.Match_Id = m.Match_Id
JOIN season s
    ON m.Season_Id = s.Season_Id
WHERE s.Season_Year BETWEEN 2014 AND 2017
GROUP BY p.Player_Id, p.Player_Name
ORDER BY Strike_Rate DESC
LIMIT 10;

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- 6.What are the average runs scored by each batsman considering all the seasons?

SELECT
    p.Player_Name,
    AVG(bb.Runs_Scored) AS Average_Runs
FROM player p
JOIN ball_by_ball bb
    ON p.Player_Id = bb.Striker
GROUP BY p.Player_Id, p.Player_Name;

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- 7.What are the average wickets taken by each bowler considering all the seasons?
SELECT 
    p.Player_Id,
    p.Player_Name,
    ROUND(COUNT(w.Match_Id) * 1.0 / COUNT(DISTINCT bb.Match_Id), 2) AS Avg_Wickets_Per_Match
FROM player p
JOIN ball_by_ball bb 
    ON p.Player_Id = bb.Bowler
LEFT JOIN wicket_taken w 
    ON bb.Match_Id = w.Match_Id 
   AND bb.Over_Id = w.Over_Id 
   AND bb.Ball_Id = w.Ball_Id 
   AND bb.Innings_No = w.Innings_No
   AND w.Kind_Out NOT IN (3, 5, 6)
GROUP BY p.Player_Id, p.Player_Name
ORDER BY Avg_Wickets_Per_Match DESC;

------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- 8.List all the players who have average runs scored greater than the overall average and 
-- who have taken wickets greater than the overall average

WITH batting_avg AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        AVG(bb.Runs_Scored) AS Avg_Runs
    FROM player p
    JOIN ball_by_ball bb 
        ON p.Player_Id = bb.Striker
    GROUP BY p.Player_Id, p.Player_Name
),
bowling_wkts AS (
    SELECT 
        p.Player_Id,
        COUNT(w.Match_Id) AS Total_Wickets
    FROM player p
    JOIN ball_by_ball bb 
        ON p.Player_Id = bb.Bowler
    LEFT JOIN wicket_taken w 
        ON bb.Match_Id = w.Match_Id 
       AND bb.Over_Id = w.Over_Id 
       AND bb.Ball_Id = w.Ball_Id 
       AND bb.Innings_No = w.Innings_No
       AND w.Kind_Out NOT IN (3, 5, 6)
    GROUP BY p.Player_Id
)
SELECT 
    ba.Player_Name,
    ba.Avg_Runs,
    bw.Total_Wickets
FROM batting_avg ba
JOIN bowling_wkts bw 
    ON ba.Player_Id = bw.Player_Id
WHERE ba.Avg_Runs > (SELECT AVG(Avg_Runs) FROM batting_avg)
  AND bw.Total_Wickets > (SELECT AVG(Total_Wickets) FROM bowling_wkts)
ORDER BY ba.Avg_Runs DESC, bw.Total_Wickets DESC;

--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- 9.Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.

CREATE TABLE rcb_record AS
SELECT
    v.Venue_Id,
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE WHEN m.Match_Winner <> 2 THEN 1 ELSE 0 END) AS Losses,
    COUNT(*) AS Total_Matches
FROM matches m
JOIN venue v 
    ON m.Venue_Id = v.Venue_Id
WHERE m.Team_1 = 2 OR m.Team_2 = 2
GROUP BY v.Venue_Id, v.Venue_Name
ORDER BY Wins DESC;
select * from rcb_record;

------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- 10.What is the impact of bowling style on wickets taken?

SELECT
    bs.Bowling_Skill,
    COUNT(w.Match_Id) AS Total_Wickets
FROM player p
JOIN bowling_style bs 
    ON p.Bowling_skill = bs.Bowling_Id
JOIN ball_by_ball bb 
    ON p.Player_Id = bb.Bowler
LEFT JOIN wicket_taken w 
    ON bb.Match_Id = w.Match_Id 
   AND bb.Over_Id = w.Over_Id 
   AND bb.Ball_Id = w.Ball_Id 
   AND bb.Innings_No = w.Innings_No
   AND w.Kind_Out NOT IN (3, 5, 6)
GROUP BY bs.Bowling_Skill
ORDER BY Total_Wickets DESC;

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
-- 11.Write the SQL query to provide a status of whether the performance of the team is better than the previous year's performance
-- on the basis of the number of runs scored by the team in the season and the number of wickets taken 
WITH team_season_stats AS (
    SELECT
        s.Season_Year,
        bb.Team_Batting AS Team_Id,
        SUM(bb.Runs_Scored) AS Total_Runs
    FROM ball_by_ball bb
    JOIN matches m 
        ON bb.Match_Id = m.Match_Id
    JOIN season s 
        ON m.Season_Id = s.Season_Id
    GROUP BY s.Season_Year, bb.Team_Batting
),
team_season_wickets AS (
    SELECT
        s.Season_Year,
        bb.Team_Bowling AS Team_Id,
        COUNT(w.Match_Id) AS Total_Wickets
    FROM ball_by_ball bb
    JOIN matches m 
        ON bb.Match_Id = m.Match_Id
    JOIN season s 
        ON m.Season_Id = s.Season_Id
    LEFT JOIN wicket_taken w 
        ON bb.Match_Id = w.Match_Id 
       AND bb.Over_Id = w.Over_Id 
       AND bb.Ball_Id = w.Ball_Id 
       AND bb.Innings_No = w.Innings_No
       AND w.Kind_Out NOT IN (3, 5, 6)
    GROUP BY s.Season_Year, bb.Team_Bowling
),
team_combined AS (
    SELECT
        r.Season_Year,
        r.Team_Id,
        r.Total_Runs,
        w.Total_Wickets
    FROM team_season_stats r
    JOIN team_season_wickets w 
        ON r.Season_Year = w.Season_Year 
       AND r.Team_Id = w.Team_Id
)
SELECT
    t.Team_Id,
    tm.Team_Name,
    t.Season_Year,
    t.Total_Runs,
    t.Total_Wickets,
    LAG(t.Total_Runs) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year) AS Prev_Season_Runs,
    LAG(t.Total_Wickets) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year) AS Prev_Season_Wickets,
    CASE 
        WHEN t.Total_Runs > LAG(t.Total_Runs) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year)
         AND t.Total_Wickets > LAG(t.Total_Wickets) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year)
        THEN 'Improved'
        WHEN t.Total_Runs < LAG(t.Total_Runs) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year)
         AND t.Total_Wickets < LAG(t.Total_Wickets) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year)
        THEN 'Declined'
        WHEN LAG(t.Total_Runs) OVER (PARTITION BY t.Team_Id ORDER BY t.Season_Year) IS NULL
        THEN 'No Previous Data'
        ELSE 'Mixed'
    END AS Performance_Status
FROM team_combined t
JOIN team tm 
    ON t.Team_Id = tm.Team_Id
ORDER BY t.Team_Id, t.Season_Year;

----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- 12.Can you derive more KPIs for the team strategy?
WITH team_batting AS (
    SELECT
        bb.Team_Batting AS Team_Id,
        SUM(bb.Runs_Scored) AS Total_Runs,
        COUNT(*) AS Total_Balls,
        ROUND(SUM(CASE WHEN bb.Over_Id BETWEEN 1 AND 6 THEN bb.Runs_Scored ELSE 0 END) / 6.0, 2) AS Powerplay_RunRate,
        ROUND(SUM(CASE WHEN bb.Over_Id BETWEEN 16 AND 20 THEN bb.Runs_Scored ELSE 0 END) / 5.0, 2) AS Death_Overs_RunRate,
        SUM(CASE WHEN bb.Runs_Scored = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN bb.Runs_Scored = 6 THEN 1 ELSE 0 END) AS Sixes,
        ROUND(SUM(CASE WHEN bb.Runs_Scored IN (4,6) THEN bb.Runs_Scored ELSE 0 END) * 100.0 
              / NULLIF(SUM(bb.Runs_Scored),0), 2) AS Boundary_Pct
    FROM ball_by_ball bb
    GROUP BY bb.Team_Batting
),
team_bowling AS (
    SELECT
        bb.Team_Bowling AS Team_Id,
        COUNT(w.Match_Id) AS Total_Wickets,
        ROUND(SUM(CASE WHEN bb.Over_Id BETWEEN 1 AND 6 THEN bb.Runs_Scored ELSE 0 END) / 6.0, 2) AS Powerplay_Economy,
        ROUND(SUM(CASE WHEN bb.Over_Id BETWEEN 16 AND 20 THEN bb.Runs_Scored ELSE 0 END) / 5.0, 2) AS Death_Overs_Economy,
        SUM(CASE WHEN bb.Runs_Scored = 0 THEN 1 ELSE 0 END) AS Dot_Balls,
        COUNT(*) AS Total_Balls_Bowled,
        ROUND(SUM(CASE WHEN bb.Runs_Scored = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Dot_Ball_Pct
    FROM ball_by_ball bb
    LEFT JOIN wicket_taken w 
        ON bb.Match_Id = w.Match_Id 
       AND bb.Over_Id = w.Over_Id 
       AND bb.Ball_Id = w.Ball_Id 
       AND bb.Innings_No = w.Innings_No
       AND w.Kind_Out NOT IN (3, 5, 6)
    GROUP BY bb.Team_Bowling
),
team_wins AS (
    SELECT
        Match_Winner AS Team_Id,
        COUNT(*) AS Total_Wins
    FROM matches
    WHERE Match_Winner IS NOT NULL
    GROUP BY Match_Winner
),
team_matches AS (
    SELECT Team_Id, COUNT(*) AS Total_Matches
    FROM (
        SELECT Team_1 AS Team_Id, Match_Id FROM matches
        UNION ALL
        SELECT Team_2 AS Team_Id, Match_Id FROM matches
    ) t
    GROUP BY Team_Id
)
SELECT
    tm.Team_Id,
    t.Team_Name,
    tmatch.Total_Matches,
    COALESCE(tw.Total_Wins, 0) AS Total_Wins,
    ROUND(COALESCE(tw.Total_Wins, 0) * 100.0 / tmatch.Total_Matches, 2) AS Win_Pct,
    tb.Total_Runs,
    tb.Powerplay_RunRate,
    tb.Death_Overs_RunRate,
    tb.Boundary_Pct,
    bw.Total_Wickets,
    bw.Powerplay_Economy,
    bw.Death_Overs_Economy,
    bw.Dot_Ball_Pct
FROM team_matches tmatch
JOIN team t 
    ON tmatch.Team_Id = t.Team_Id
LEFT JOIN team_wins tw 
    ON tmatch.Team_Id = tw.Team_Id
LEFT JOIN team_batting tb 
    ON tmatch.Team_Id = tb.Team_Id
LEFT JOIN team_bowling bw 
    ON tmatch.Team_Id = bw.Team_Id
LEFT JOIN team_matches tm 
    ON tmatch.Team_Id = tm.Team_Id
ORDER BY Win_Pct DESC;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- 13.Using SQL, write a query to find out the average wickets taken by each bowler in each venue.
-- Also, rank the gender according to the average value.

SELECT
    p.Player_Name,
    v.Venue_Name,
    ROUND(
        COUNT(w.Match_Id) * 1.0 / COUNT(DISTINCT bb.Match_Id),
        2
    ) AS Average_Wickets,
    RANK() OVER (
        PARTITION BY v.Venue_Id
        ORDER BY COUNT(w.Match_Id) * 1.0 / COUNT(DISTINCT bb.Match_Id) DESC
    ) AS Venue_Rank
FROM player p
JOIN ball_by_ball bb
    ON p.Player_Id = bb.Bowler
JOIN matches m
    ON bb.Match_Id = m.Match_Id
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
LEFT JOIN wicket_taken w
    ON bb.Match_Id = w.Match_Id
    AND bb.Over_Id = w.Over_Id
    AND bb.Ball_Id = w.Ball_Id
    AND bb.Innings_No = w.Innings_No
    AND w.Kind_Out NOT IN (3, 5, 6)
GROUP BY
    p.Player_Id,
    p.Player_Name,
    v.Venue_Id,
    v.Venue_Name
ORDER BY
    v.Venue_Name,
    Venue_Rank;
    
-----------------------------------------------------------------------------------------------------    
-----------------------------------------------------------------------------------------------------
-- 14.	Which of the given players have consistently performed well in past seasons? 
-- (will you use any visualization to solve the problem)
SELECT
    p.Player_Name,
    s.Season_Year,
    SUM(bb.Runs_Scored) AS Total_Runs
FROM player p
JOIN ball_by_ball bb
    ON p.Player_Id = bb.Striker
JOIN matches m
    ON bb.Match_Id = m.Match_Id
JOIN season s
    ON m.Season_Id = s.Season_Id
GROUP BY
    p.Player_Id,
    p.Player_Name,
    s.Season_Year
ORDER BY
    p.Player_Name,
    s.Season_Year;
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- 15.Are there players whose performance is more suited to specific venues or conditions? 
-- (how would you present this using charts?) 
SELECT
    p.Player_Name,
    v.Venue_Name,
    ROUND(SUM(bb.Runs_Scored) * 1.0 / COUNT(DISTINCT bb.Match_Id), 2) AS Avg_Runs_Per_Match
FROM player p
JOIN ball_by_ball bb
    ON p.Player_Id = bb.Striker
JOIN matches m
    ON bb.Match_Id = m.Match_Id
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
GROUP BY
    p.Player_Id,
    p.Player_Name,
    v.Venue_Id,
    v.Venue_Name
ORDER BY Avg_Runs_Per_Match DESC;

--------------------------------------------------------------------------------------------------------
                                                  -- SUBJECTIVE--
------------------------------------------------------------------------------------------------------------
-- 1.How does the toss decision affect the result of the match? 
-- (which visualizations could be used to present your answer better) And is the impact limited to only specific venues?
SELECT
    v.Venue_Name, td.Toss_Name, COUNT(*) AS Total_Matches,
    ROUND(SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Win_Pct
FROM Matches m
JOIN Venue v ON m.Venue_Id = v.Venue_Id
JOIN Toss_Decision td ON m.Toss_Decide = td.Toss_Id
WHERE m.Match_Winner IS NOT NULL
GROUP BY v.Venue_Id, td.Toss_Name
HAVING COUNT(*) >= 5;       

--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- 2.	Suggest some of the players who would be best fit for the team.
SELECT 
    p.Player_Name,
    COALESCE(b.Total_Runs, 0) AS Total_Runs,
    COALESCE(w.Total_Wickets, 0) AS Total_Wickets,
    (COALESCE(b.Total_Runs, 0) + 
     COALESCE(w.Total_Wickets, 0) * 20) AS Performance_Score
FROM Player p

LEFT JOIN (
    SELECT 
        Striker AS Player_Id,
        SUM(Runs_Scored) AS Total_Runs
    FROM Ball_by_Ball
    GROUP BY Striker
) b ON p.Player_Id = b.Player_Id

LEFT JOIN (
    SELECT 
        Player_Out AS Player_Id,
        COUNT(*) AS Total_Wickets
    FROM Wicket_Taken
    GROUP BY Player_Out
) w ON p.Player_Id = w.Player_Id

ORDER BY Performance_Score DESC
LIMIT 10;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- 3.What are some of the parameters that should be focused on while selecting the players?
SELECT
    p.Player_Name,
    COUNT(DISTINCT bb.Match_Id) AS Matches_Played,
    SUM(bb.Runs_Scored) AS Total_Runs,
    ROUND(SUM(bb.Runs_Scored) * 100.0 / COUNT(*), 2) AS Strike_Rate,
    COUNT(DISTINCT CASE
        WHEN w.Kind_Out NOT IN (3, 5, 6)
        THEN CONCAT(w.Match_Id, '-', w.Over_Id, '-', w.Ball_Id, '-', w.Innings_No)
    END) AS Total_Wickets
FROM Player p
LEFT JOIN Ball_by_Ball bb
    ON p.Player_Id = bb.Striker
LEFT JOIN Wicket_Taken w
    ON bb.Match_Id = w.Match_Id
    AND bb.Over_Id = w.Over_Id
    AND bb.Ball_Id = w.Ball_Id
    AND bb.Innings_No = w.Innings_No
GROUP BY
    p.Player_Id,
    p.Player_Name
ORDER BY
    Total_Runs DESC;
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- 4.Which players offer versatility in their skills and can contribute effectively with both bat and ball?can you visualize the data for the same)
SELECT 
    p.Player_Name,
    COALESCE(b.Total_Runs, 0) AS Total_Runs,
    COALESCE(w.Total_Wickets, 0) AS Total_Wickets
FROM Player p
LEFT JOIN (
    SELECT 
        Striker AS Player_Id,
        SUM(Runs_Scored) AS Total_Runs
    FROM Ball_by_Ball
    GROUP BY Striker
) b ON p.Player_Id = b.Player_Id
LEFT JOIN (
    SELECT 
        bb.Bowler AS Player_Id,
        COUNT(*) AS Total_Wickets
    FROM Ball_by_Ball bb
    JOIN Wicket_Taken wt
        ON bb.Match_Id = wt.Match_Id
        AND bb.Over_Id = wt.Over_Id
        AND bb.Ball_Id = wt.Ball_Id
        AND bb.Innings_No = wt.Innings_No
    WHERE wt.Player_Out <> bb.Bowler
    GROUP BY bb.Bowler
) w ON p.Player_Id = w.Player_Id
WHERE b.Total_Runs > 0
  AND w.Total_Wickets > 0
ORDER BY Total_Runs DESC, Total_Wickets DESC;
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-- 5.Are there players whose presence positively influences the morale and performance of the team? (justify your answer using Visualisation)
SELECT 
    p.Player_Name,
    COUNT(DISTINCT pm.Match_Id) AS Matches_Played,
    COUNT(DISTINCT CASE 
        WHEN m.Match_Winner = pm.Team_Id THEN m.Match_Id 
    END) AS Team_Wins,
    COUNT(DISTINCT CASE 
        WHEN m.Man_of_the_Match = p.Player_Id THEN m.Match_Id 
    END) AS Man_of_the_Match
FROM Player p
JOIN Player_Match pm 
    ON p.Player_Id = pm.Player_Id
JOIN Matches m 
    ON pm.Match_Id = m.Match_Id
GROUP BY p.Player_Id, p.Player_Name
HAVING Team_Wins > 0
ORDER BY Team_Wins DESC, Man_of_the_Match DESC;
--------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
-- 6.What would you suggest to RCB before going to the mega auction? 
SELECT 
    p.Player_Name,
    COUNT(DISTINCT pm.Match_Id) AS Matches_Played,
    SUM(CASE 
        WHEN b.Striker = p.Player_Id 
        THEN b.Runs_Scored 
        ELSE 0 
    END) AS Total_Runs,
    ROUND(
        SUM(CASE 
            WHEN b.Striker = p.Player_Id 
            THEN b.Runs_Scored 
            ELSE 0 
        END) / COUNT(DISTINCT pm.Match_Id), 2
    ) AS Avg_Runs_Per_Match,
    COUNT(DISTINCT wt.Match_Id, wt.Over_Id, wt.Ball_Id, wt.Innings_No) AS Wickets
FROM Player p
JOIN Player_Match pm 
    ON p.Player_Id = pm.Player_Id
JOIN Team t 
    ON pm.Team_Id = t.Team_Id
LEFT JOIN Ball_by_Ball b 
    ON p.Player_Id = b.Striker
    AND pm.Match_Id = b.Match_Id
LEFT JOIN Wicket_Taken wt 
    ON p.Player_Id = wt.Player_Out
    AND pm.Match_Id = wt.Match_Id
WHERE t.Team_Name LIKE '%Bangalore%'
GROUP BY p.Player_Id, p.Player_Name
ORDER BY Total_Runs DESC, Wickets DESC;

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- 7.What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies
SELECT
    m.Match_Id,
    m.Match_Date,
    t1.Team_Name AS Team_1,
    t2.Team_Name AS Team_2,
    SUM(b.Runs_Scored) AS Total_Runs
FROM Matches m
JOIN Ball_by_Ball b
    ON m.Match_Id = b.Match_Id
JOIN Team t1
    ON m.Team_1 = t1.Team_Id
JOIN Team t2
    ON m.Team_2 = t2.Team_Id
GROUP BY
    m.Match_Id,
    m.Match_Date,
    t1.Team_Name,
    t2.Team_Name
HAVING SUM(b.Runs_Scored) >= 300
ORDER BY Total_Runs DESC;

----------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- 8.Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB.
SELECT
    CASE
        WHEN m.Venue_Id = 1 THEN 'Home'
        ELSE 'Away'
    END AS Match_Type,
    COUNT(*) AS Matches_Played,
    SUM(CASE
            WHEN m.Match_Winner = 2 THEN 1
            ELSE 0
        END) AS Matches_Won,
    ROUND(
        SUM(CASE
                WHEN m.Match_Winner = 2 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
        2
    ) AS Win_Percentage
FROM Matches m
WHERE (m.Team_1 = 2 OR m.Team_2 = 2)
GROUP BY
    CASE
        WHEN m.Venue_Id = 1 THEN 'Home'
        ELSE 'Away'
    END
ORDER BY Win_Percentage DESC;

------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- 9.Come up with a visual and analytical analysis of the RCB's past season's performance and potential reasons for them not winning a trophy.
SELECT
    s.Season_Year,
    COUNT(m.Match_Id) AS Matches_Played,
    SUM(
        CASE
            WHEN m.Match_Winner = 2 THEN 1
            ELSE 0
        END
    ) AS Matches_Won,
    COUNT(m.Match_Id) -
    SUM(
        CASE
            WHEN m.Match_Winner = 2 THEN 1
            ELSE 0
        END
    ) AS Matches_Lost,
    ROUND(
        SUM(
            CASE
                WHEN m.Match_Winner = 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(m.Match_Id),
        2
    ) AS Win_Percentage
FROM Matches m
JOIN Season s
    ON m.Season_Id = s.Season_Id
WHERE m.Team_1 = 2
   OR m.Team_2 = 2
GROUP BY
    s.Season_Year
ORDER BY
    s.Season_Year;
    
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- 10.How would you approach this problem, if the objective and subjective questions weren't given?
SELECT
    COUNT(DISTINCT m.Match_Id) AS Total_Matches,
    COUNT(DISTINCT b.Striker) AS Total_Players,
    COUNT(DISTINCT b.Team_Batting) AS Total_Teams,
    COUNT(DISTINCT m.Season_Id) AS Total_Seasons,
    SUM(b.Runs_Scored) AS Total_Runs
FROM Matches m
JOIN Ball_by_Ball b
    ON m.Match_Id = b.Match_Id;
    
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- 11.In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" instead of "Delhi_Daredevils". 
-- Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".

UPDATE Team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Id = 6;

SELECT *
FROM Team
WHERE Team_Id = 6;

----------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

