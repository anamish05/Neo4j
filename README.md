# Neo4j

Part 1   

<img width="881" height="377" alt="image" src="https://github.com/user-attachments/assets/df4c5715-ecbc-457f-b8be-f6865b3a712f" />  

1. Which entities became nodes and which - edges?
   Nodes are nouns - user, movie, genre, occupation. They are autonomous objects.
   Edges - are relationships, actions. Rated, in genre, has occupation. They connect nodes.  
2. User's rate for a movie — is an edge (User)-[:RATED]->(Movie) or node (Rating)? Explain. Both approaches have real trade-off
   First approach (chosen by me) allows quickly traveres a graph, takes less memory, but does not allow create history of
   changes for reviews or comments to reviews. Second approach allows this, but takes more memory.
3. Why it is more convenient to store genres as nodes and not as list of characteristics of movie?
   For example to find movies with a particular genre DB has to traverse each node to check its genre, so it's O(N).
   However if genre is a node, it's just 1 operation (O(1)).

Part 2  
-- load users --
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/users.csv' AS row  
MERGE (u:User {userId: toInteger(row.UserID)})  
ON CREATE SET   
  u.gender = row.Gender,  
  u.age = toInteger(row.Age),  
  u.zipCode = row.`Zip-code`;  

--load movies--  
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/movies.csv' AS row  
WITH row, apoc.text.regexGroups(row.Title, "(.*) \\((\\d{4})\\)")[0] AS parsedTitle  
MERGE (m:Movie {movieId: toInteger(row.MovieID)})  
ON CREATE SET   
  m.title = coalesce(parsedTitle[1], row.Title),  
  m.year = toInteger(parsedTitle[2]);  

  -- load genres--  
  LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/refs/heads/main/movies.csv' AS row  
UNWIND split(row.Genres, "|") AS genreName  
MERGE (g:Genre {name: genreName});  

  
 --load edges--  
 LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/anamish05/Neo4j/main/users.csv' AS row  
CALL (row) {  
  MATCH (u:User {userId: toInteger(row.UserID)})  
  MATCH (o:Occupation {occupationId: toInteger(row.Occupation)})  
  MERGE (u)-[:HAS_OCCUPATION]->(o)  
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


 
Part 3  
-- find thrillers with ratings >4---  
MATCH (m:Movie)-[:IN_GENRE]->(g:Genre {name: 'Thriller'})  
MATCH (u:User)-[r:RATED]->(m)   
WITH m, AVG(r.rating) AS avgRating, COUNT(r) AS voteCount  
WHERE avgRating > 4.0  
RETURN m.title AS Title,   
       m.year AS Year,   
       ROUND(avgRating, 2) AS AverageRating,   
       voteCount AS TotalVotes  
ORDER BY AverageRating DESC;  

--- find users rated 5 to more than 50 movies---  
MATCH (u:User)-[r:RATED {rating: 5.0}]->(m:Movie)  
WITH u, COUNT(m) AS topRatedCount  
WHERE topRatedCount > 50  
RETURN u.userId AS UserId,   
       u.gender AS Gender,   
       u.age AS Age,   
       topRatedCount AS HighRatingsCount  
ORDER BY HighRatingsCount DESC;  

--- find movies that were rated by 2 users more than 4 ---  
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})  
WHERE r1.rating >= 4.0 AND r2.rating >= 4.0  
RETURN m.movieId AS MovieId,  
       m.title AS Title,  
       m.year AS Year,  
       r1.rating AS RatingUser1,  
       r2.rating AS RatingUser2;  

--- find genres that constantly receive great reviews - median rate and ratings number ---  
// 1. Знаходимо фільми та їхній середній рейтинг  
MATCH (m:Movie)<-[r:RATED]-(:User)  
WITH m, AVG(r.rating) AS movieAvg, COUNT(r) AS movieVotes  
// 2. Зв'язуємо ці фільми з їхніми жанрами  
MATCH (m)-[:IN_GENRE]->(g:Genre)  
// 3. Агрегуємо показники на рівні жанрів  
RETURN g.name AS Genre,  
       ROUND(AVG(movieAvg), 2) AS GenreAvgRating,  
       SUM(movieVotes) AS TotalGenreVotes,  
       COUNT(m) AS TotalMovies  
ORDER BY GenreAvgRating DESC;  

--- recommendation: users with similar taste viewed these movies ---   
// 1. Беремо цільового користувача (Target User)  
MATCH (target:User {userId: 1})-[r1:RATED]->(m:Movie)  
WHERE r1.rating >= 4.0  
// 2. Знаходимо схожих користувачів (Similar Users), які високо оцінили ТІ Ж САМІ фільми  
MATCH (similar:User)-[r2:RATED]->(m)  
WHERE similar <> target AND r2.rating >= 4.0  
// 3. Рахуємо "коефіцієнт схожості" (кількість спільних улюблених фільмів)  
WITH target, similar, COUNT(m) AS commonMoviesCount  
WHERE commonMoviesCount >= 3 // Мінімальний поріг схожості (можна коригувати)  
// 4. Знаходимо фільми, які оцінили схожі користувачі, АЛЕ ще НЕ бачив цільовий користувач  
MATCH (similar)-[r3:RATED]->(rec:Movie)  
WHERE r3.rating >= 4.0   
  AND NOT (target)-[:RATED]->(rec)  
// 5. Агрегуємо та зважуємо рекомендації  
RETURN rec.movieId AS MovieId,  
       rec.title AS Title,  
       ROUND(AVG(r3.rating), 2) AS AvgScoreFromSimilarUsers,  
       COUNT(DISTINCT similar) AS RecommendedByUsersCount  
ORDER BY RecommendedByUsersCount DESC, AvgScoreFromSimilarUsers DESC  
LIMIT 10;  

--- find shortest path between 2 users according to the watched movies----  
MATCH (u1:User {userId: 1}), (u2:User {userId: 100})  
MATCH path = shortestPath((u1)-[:RATED*..10]-(u2))  
RETURN path;   


1. Що означає довжина шляху в даному контексті?
   Довжина шляху зв'язує ноди і є парною завжди. 
2. Один хоп — це один крок по ребру RATED, а значить — шлях довжини 2 означає, що два користувачі оцінили один і той самий фільм.  
3. Як інтерпретувати шлях довжини 4? Довжини 6?
   Довжина 4 - у юзерів немає жодного спільного фільму, але є місток у вигляді третього юзера, який подивився ці 2 фільми (транзитивність).
   Довжина 6 - тут уже між юзерами 2 інших юзери, які подивилися фільми, які подивилися ці юзери, тому ланцюг тепер з 6 рукостискань.

Part 4  
-- detect supernodes--  
// 1. Топ-5 користувачів за кількістю оцінок  
MATCH (u:User)  
RETURN "User" AS Label,   
       u.userId AS Identifier,   
       COUNT { (u)-[:RATED]->() } AS Degree  
ORDER BY Degree DESC  
LIMIT 5  
  
UNION ALL  
  
// 2. Топ-5 найпопулярніших фільмів  
MATCH (m:Movie)  
RETURN "Movie" AS Label,   
       m.title AS Identifier,   
       COUNT { (m)<-[:RATED]-() } AS Degree  
ORDER BY Degree DESC  
LIMIT 5  
  
UNION ALL  
  
// 3. Топ-5 наймасовіших жанрів  
MATCH (g:Genre)  
RETURN "Genre" AS Label,   
       g.name AS Identifier,   
       COUNT { (g)<-[:IN_GENRE]-() } AS Degree  
ORDER BY Degree DESC  
LIMIT 5;  

1. Які вузли виявилися супервузлами? Скільки у них зв’язків?  
Дуже активні користувачі 4169, 1680, 4277,1941,1181. ТАкож дуже популярні фільми як American beauty, star wars, Jurastic park.
Також  дуже популярні жанри drama, comedy, action, thriller, romance.  
2. Чому запит, що зачіпає такий вузол, працює повільніше, ніж запит по «звичайному» вузлу з тими самими індексами?  
якщо у вузла сотні тисяч зв'язків, БД треба їх усі обійти, к-сть операцій зростає експоненційно.  
3. Яку конкретну стратегію з лекцій ви б застосували для цього датасету? (Підказка: подивіться на жанрові вузли — вони теж супервузли?) Що з ними робити?
Перетворити жанри у властивості до вузлів фільмів. Або створити проміжні сутності. Або обмежити глибину проходу графу.

Part 5   
