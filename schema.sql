-- Drop tables if they exist
DROP TABLE IF EXISTS goal_assists;
DROP TABLE IF EXISTS goals;
DROP TABLE IF EXISTS match_appearances;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS leagues;

-- ============================================
-- SCHEMA DESIGN
-- ============================================

CREATE TABLE leagues (
    league_id INT PRIMARY KEY,
    league_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),               -- NULL KILLER #2
    tier INT,                          -- NULL KILLER #3
    founded_year INT
);

CREATE TABLE teams (
    team_id INT PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    league_id INT,                     -- NULL KILLER #1
    stadium VARCHAR(100),
    city VARCHAR(50),
    FOREIGN KEY (league_id) REFERENCES leagues(league_id)
);

CREATE TABLE players (
    player_id INT PRIMARY KEY,
    player_name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50),           -- NULL KILLER #4
    position VARCHAR(20),              -- NULL KILLER #2
    current_team_id INT,               -- NULL KILLER #1
    age INT,
    market_value DECIMAL(10,2),        -- NULL KILLER #3
    FOREIGN KEY (current_team_id) REFERENCES teams(team_id)
);

CREATE TABLE matches (
    match_id INT PRIMARY KEY,
    home_team_id INT,
    away_team_id INT,
    match_date DATE NOT NULL,
    competition VARCHAR(50),           -- NULL KILLER #2
    home_score INT,
    away_score INT,
    status VARCHAR(20),                -- NULL KILLER #1
    FOREIGN KEY (home_team_id) REFERENCES teams(team_id),
    FOREIGN KEY (away_team_id) REFERENCES teams(team_id)
);

CREATE TABLE goals (
    goal_id INT PRIMARY KEY,
    match_id INT,
    player_id INT,
    minute INT,
    goal_type VARCHAR(20),             -- NULL KILLER #2
    penalty BOOLEAN,
    FOREIGN KEY (match_id) REFERENCES matches(match_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

CREATE TABLE transfers (
    transfer_id INT PRIMARY KEY,
    player_id INT,
    from_team_id INT,
    to_team_id INT,
    transfer_date DATE,
    fee DECIMAL(10,2),                 -- NULL KILLER #3
    contract_years INT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (from_team_id) REFERENCES teams(team_id),
    FOREIGN KEY (to_team_id) REFERENCES teams(team_id)
);

CREATE TABLE match_appearances (
    appearance_id INT PRIMARY KEY,
    match_id INT,
    player_id INT,
    minutes_played INT,                -- NULL KILLER #3
    rating DECIMAL(3,1),               -- NULL KILLER #3
    yellow_cards INT,
    red_cards INT,
    FOREIGN KEY (match_id) REFERENCES matches(match_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- ============================================
-- TEST DATA (REALISTIC)
-- ============================================

-- Leagues with NULL scenarios
INSERT INTO leagues VALUES
(1, 'Premier League', 'EN', 1, 1992),
(2, 'La Liga', 'ES', 1, 1929),
(3, 'Serie A', 'IT', 1, 1898),
(4, 'Bundesliga', 'DE', 1, 1963),
(5, 'Ligue 1', 'FR', 1, 1932),
(6, 'Saudi Pro League', NULL, 1, 2008),                                      -- NULL country (new league, data incomplete)
(7, 'MLS', 'US', NULL, 1993);                                                -- NULL tier (not officially ranked)

-- Teams
INSERT INTO teams VALUES
(101, 'Manchester City', 1, 'Etihad Stadium', 'Manchester'),
(102, 'Real Madrid', 2, 'Santiago Bernabeu', 'Madrid'),
(103, 'Barcelona', 2, 'Camp Nou', 'Barcelona'),
(104, 'Bayern Munich', 4, 'Allianz Arena', 'Munich'),
(105, 'Paris Saint-Germain', 5, 'Parc des Princes', 'Paris'),
(106, 'Al Nassr', 6, 'Mrsool Park', 'Riyadh'),
(107, 'Inter Miami', 7, 'DRV PNK Stadium', 'Miami'),
(108, 'Al Hilal', 6, 'King Fahd Stadium', 'Riyadh'),
(109, 'Free Agent FC', NULL, NULL, NULL);                                    -- NULL league (free agents/retired)

-- Players with various NULL scenarios
INSERT INTO players VALUES
(1, 'Erling Haaland', 'NO', 'Forward', 101, 24, 180.00),                     -- Active goal scorer
(2, 'Kylian Mbappe', 'FR', 'Forward', 102, 25, 180.00),                      -- Active goal scorer
(3, 'Vinicius Junior', 'BR', 'Forward', 102, 24, 150.00),                    -- Active goal scorer
(4, 'Kevin De Bruyne', 'BE', 'Midfielder', 101, 33, 80.00),                  -- Playmaker
(5, 'Cristiano Ronaldo', 'PT', 'Forward', 106, 39, 15.00),                   -- Active in Saudi
(6, 'Lionel Messi', 'AR', 'Forward', 107, 37, 25.00),                        -- Active in MLS
(7, 'Neymar Jr', 'BR', 'Forward', 108, 32, 45.00),                           -- Active in Saudi
(8, 'Robert Lewandowski', 'PL', 'Forward', 103, 36, 45.00),                  -- Active at Barcelona
(9, 'Sergio Busquets', 'ES', 'Midfielder', 107, 36, 5.00),                   -- Veteran midfielder
(10, 'Eden Hazard', 'BE', NULL, NULL, 33, NULL),                             -- RETIRED (NULL position, team, value)
(11, 'Gareth Bale', 'WL', NULL, NULL, 35, NULL),                             -- RETIRED (NULL position, team, value)
(12, 'Youth Prospect', NULL, 'Forward', 101, 17, 2.00);                      -- Youth player (NULL nationality - dual citizen deciding)

-- Matches with various statuses
INSERT INTO matches VALUES
(201, 101, 104, '2024-09-15', 'Champions League', 3, 1, 'completed'),
(202, 102, 103, '2024-09-18', 'La Liga', 4, 2, 'completed'),                 -- El Clasico
(203, 105, 102, '2024-09-20', 'Champions League', 1, 3, 'completed'),
(204, 101, 102, '2024-09-25', NULL, 2, 2, 'completed'),                      -- Friendly match (NULL competition)
(205, 103, 104, '2024-09-28', 'Champions League', NULL, NULL, 'postponed'),  -- Postponed due to weather
(206, 106, 108, '2024-10-01', 'Saudi Pro League', 5, 4, 'completed'),        -- Saudi derby
(207, 107, 101, '2024-10-05', 'Friendly', 1, 2, 'completed'),                -- MLS All-Stars vs City
(208, 102, 104, '2024-10-10', 'Champions League', NULL, NULL, 'scheduled'),  -- Future match
(209, 103, 102, '2024-10-15', 'La Liga', NULL, NULL, 'cancelled');           -- Cancelled match
-- Note: Hazard and Bale (retired) have NO recent match appearances (KILLER #1)

-- Goals - REALISTIC! Top scorers actually score
INSERT INTO goals VALUES
(301, 201, 1, 12, 'right_foot', FALSE),                                      -- Haaland goal 1
(302, 201, 1, 45, 'header', FALSE),                                          -- Haaland goal 2
(303, 201, 1, 67, 'left_foot', FALSE),                                       -- Haaland goal 3 (hat-trick!)
(304, 202, 2, 15, 'right_foot', FALSE),                                      -- Mbappe goal 1
(305, 202, 2, 34, NULL, TRUE),                                               -- Mbappe penalty (NULL type - data missing)
(306, 202, 3, 78, 'left_foot', FALSE),                                       -- Vinicius goal
(307, 202, 8, 52, 'header', FALSE),                                          -- Lewandowski goal
(308, 203, 2, 23, 'penalty', TRUE),                                          -- Mbappe penalty
(309, 203, 2, 56, 'right_foot', FALSE),                                      -- Mbappe goal 2
(310, 203, 3, 89, 'left_foot', FALSE),                                       -- Vinicius goal
(311, 206, 5, 15, 'header', FALSE),                                          -- Ronaldo goal 1
(312, 206, 5, 30, 'penalty', TRUE),                                          -- Ronaldo penalty
(313, 206, 5, 52, 'right_foot', FALSE),                                      -- Ronaldo goal 2
(314, 206, 7, 71, NULL, FALSE),                                              -- Neymar goal (NULL type)
(315, 207, 6, 44, 'left_foot', FALSE),                                       -- Messi goal
(316, 204, 8, 67, 'right_foot', FALSE);                                      -- Lewandowski in friendly
-- Note: De Bruyne (4), Busquets (9) are midfielders - fewer goals expected
-- Hazard (10) and Bale (11) retired - NO recent goals (KILLER #1)

-- Transfers with NULL fees (free transfers are common for end-of-contract)
INSERT INTO transfers VALUES
(401, 2, 105, 102, '2024-06-01', 0.00, 5),                                   -- Mbappe to Real Madrid (free!)
(402, 6, 105, 107, '2023-07-15', NULL, 2),                                   -- Messi to Miami (undisclosed)
(403, 5, 102, 106, '2023-01-01', NULL, 3),                                   -- Ronaldo to Al Nassr (undisclosed)
(404, 1, 104, 101, '2022-07-01', 60.00, 5),                                  -- Haaland to City
(405, 4, 104, 101, '2015-08-30', 76.00, 6),                                  -- De Bruyne to City
(406, 9, 103, 107, '2023-07-01', NULL, 2),                                   -- Busquets to Miami (free)
(407, 10, 102, 109, '2023-10-01', NULL, 0),                                  -- Hazard retirement (NULL fee)
(408, 11, 101, 109, '2023-01-09', NULL, 0);                                  -- Bale retirement (NULL fee)

-- Match appearances - REALISTIC participation
INSERT INTO match_appearances VALUES
(501, 201, 1, 90, 9.5, 0, 0),                                                -- Haaland hat-trick
(502, 201, 4, 90, 8.5, 1, 0),                                                -- De Bruyne assist
(503, 202, 2, 90, 9.2, 0, 0),                                                -- Mbappe brace
(504, 202, 3, 85, 8.0, 0, 0),                                                -- Vinicius
(505, 202, 8, 90, 8.5, 0, 0),                                                -- Lewandowski
(506, 203, 2, 90, 9.5, 0, 0),                                                -- Mbappe
(507, 203, 3, 90, 8.5, 1, 0),                                                -- Vinicius
(508, 206, 5, 90, 10.0, 0, 0),                                               -- Ronaldo hat-trick
(509, 206, 7, 90, 8.5, 1, 0),                                                -- Neymar
(510, 207, 6, 70, NULL, 0, 0),                                               -- Messi (rating not recorded)
(511, 207, 9, 90, 7.0, 0, 0),                                                -- Busquets
(512, 204, 4, NULL, 7.5, 0, 0);                                              -- De Bruyne (minutes not recorded)
-- Note: Hazard (10) and Bale (11) retired - NO recent appearances (KILLER #1)