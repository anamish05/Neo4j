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
