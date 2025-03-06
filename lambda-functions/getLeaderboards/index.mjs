// Import the Redis client
import { Redis } from '@upstash/redis';

// Initialize the Redis client using environment variables
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Export the handler function
export const handler = async (event) => {
  try {
    // Check if the event is a GET request to retrieve the leaderboard
    if (event.httpMethod === 'GET') {
      // Fetch all entries from the longestWord hash
      const longestWords = await redis.hgetall('leaderboard:longestWord');

      if (!longestWords) {
        return {
          statusCode: 200,
          body: JSON.stringify({ leaderboard: [] }),
        };
      }

      // Compute the word lengths and store in an array
      const users = [];
      for (const [username, word] of Object.entries(longestWords)) {
        users.push({
          username: username,
          longestWord: word,
          wordLength: word.length,
        });
      }

      // Sort the array by word length in descending order
      users.sort((a, b) => b.wordLength - a.wordLength);

      // Get the top 10 users
      const topUsers = users.slice(0, 10);

      // Return the top 10 users
      return {
        statusCode: 200,
        body: JSON.stringify({ leaderboard: topUsers }),
      };
    }

    // If it's a POST request, handle updating the leaderboards
    if (event.httpMethod === 'POST') {
      // Parse the request body
      let body;
      if (typeof event.body === 'string') {
        body = JSON.parse(event.body);
      } else if (typeof event.body === 'object' && event.body !== null) {
        body = event.body;
      } else {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Invalid or missing event body' }),
        };
      }

      // Extract the required fields from the request body
      const { userID, username, highestScore, longestWord } = body;

      // Validate the presence of required fields
      if (!userID || !username || highestScore === undefined || !longestWord) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Missing required user data' }),
        };
      }

      // Store the highest score in a sorted set (leaderboard)
      await redis.zadd('leaderboard:highestScore', {
        score: highestScore,
        member: username,
      });

      // Store the longest word in a hash, where the key is the username
      await redis.hset('leaderboard:longestWord', {
        [username]: longestWord,
      });

      // Return a success response
      return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Leaderboard and user data updated successfully' }),
      };
    }

    // Unsupported HTTP method
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method Not Allowed' }),
    };
  } catch (error) {
    console.error('Error processing request:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
