MATCH (m:Movie)-[:IN_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (u:User)-[r:RATED]->(m)
WITH m, AVG(r.rating) AS avgRating, COUNT(r) AS voteCount
WHERE avgRating > 4.0
RETURN m.title AS Title, 
       m.year AS Year, 
       ROUND(avgRating, 2) AS AverageRating, 
       voteCount AS TotalVotes
ORDER BY AverageRating DESC;

MATCH (u:User)-[r:RATED {rating: 5.0}]->(m:Movie)
WITH u, COUNT(m) AS topRatedCount
WHERE topRatedCount > 50
RETURN u.userId AS UserId, 
       u.gender AS Gender, 
       u.age AS Age, 
       topRatedCount AS HighRatingsCount
ORDER BY HighRatingsCount DESC;

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

MATCH (u1:User {userId: 1}), (u2:User {userId: 100})
MATCH path = shortestPath((u1)-[:RATED*..10]-(u2))
RETURN path;
