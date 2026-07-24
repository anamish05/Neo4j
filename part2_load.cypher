WITH [
  {id: 0, name: "other"}, {id: 1, name: "academic/educator"}, {id: 2, name: "artist"},
  {id: 3, name: "clerical/admin"}, {id: 4, name: "college/grad student"}, {id: 5, name: "customer service"},
  {id: 6, name: "doctor/health care"}, {id: 7, name: "executive/managerial"}, {id: 8, name: "farmer"},
  {id: 9, name: "homemaker"}, {id: 10, name: "K-12 student"}, {id: 11, name: "lawyer"},
  {id: 12, name: "programmer"}, {id: 13, name: "retired"}, {id: 14, name: "sales/marketing"},
  {id: 15, name: "tradesman/craftsman"}, {id: 16, name: "unemployed"}, {id: 17, name: "writer"},
  {id: 18, name: "technician/engineer"}, {id: 19, name: "executive/managerial"}, {id: 20, name: "scientist"}
] AS occupations
UNWIND occupations AS occ
MERGE (o:Occupation {occupationId: occ.id})
ON CREATE SET o.name = occ.name;

CREATE CONSTRAINT unique_user_id IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;
CREATE CONSTRAINT unique_movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;
CREATE CONSTRAINT unique_genre_name IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;
CREATE CONSTRAINT unique_occupation_id IF NOT EXISTS FOR (o:Occupation) REQUIRE o.occupationId IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/users.csv' AS row
MERGE (u:User {userId: toInteger(row.UserID)})
ON CREATE SET 
  u.gender = row.Gender,
  u.age = toInteger(row.Age),
  u.zipCode = row.`Zip-code`;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/movies.csv' AS row
WITH row, apoc.text.regexGroups(row.Title, "(.*) \\((\\d{4})\\)")[0] AS parsedTitle
MERGE (m:Movie {movieId: toInteger(row.MovieID)})
ON CREATE SET 
  m.title = coalesce(parsedTitle[1], row.Title),
  m.year = toInteger(parsedTitle[2]);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/movies.csv' AS row
UNWIND split(row.Genres, "|") AS genreName
MERGE (g:Genre {name: genreName});

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/main/users.csv' AS row
CALL (row) {
  MATCH (u:User {userId: toInteger(row.UserID)})
  MATCH (o:Occupation {occupationId: toInteger(row.Occupation)})
  MERGE (u)-[:HAS_OCCUPATION]->(o)
} IN TRANSACTIONS OF 5000 ROWS;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/main/movies.csv' AS row
CALL (row) {
  MATCH (m:Movie {movieId: toInteger(row.MovieID)})
  WITH m, split(row.Genres, '|') AS genres
  UNWIND genres AS genreName
  MATCH (g:Genre {name: genreName})
  MERGE (m)-[:IN_GENRE]->(g)
} IN TRANSACTIONS OF 5000 ROWS;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/main/ratings.csv' AS row
CALL (row) {
  MATCH (u:User {userId: toInteger(row.UserID)})
  MATCH (m:Movie {movieId: toInteger(row.MovieID)})
  MERGE (u)-[r:RATED]->(m)
  ON CREATE SET 
    r.rating = toFloat(row.Rating),
    r.timestamp = toInteger(row.Timestamp)
} IN TRANSACTIONS OF 10000 ROWS;

