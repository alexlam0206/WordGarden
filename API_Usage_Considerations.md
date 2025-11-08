### API Usage Considerations for WordGarden

Here are some important points to keep in mind when using the Dictionaries API in your app:

#### 1. Rate Limits
The Oxford Dictionaries API has rate limits, which means you can only make a certain number of requests in a given time period. If you exceed these limits, your requests will be blocked.

*   **What to do:** For a production app, you should implement a caching mechanism to avoid fetching the same word multiple times. This will reduce the number of API calls and improve performance.

#### 2. Caching Responses
Caching is the process of storing the results of API requests locally on the device. When the user requests the same word again, you can load the data from the cache instead of making a new API call.

*   **How to implement:** You can use `Core Data`, `Realm`, or even a simple file-based cache (saving the JSON response to a file) to store the API responses. The `word` itself can be used as a key for the cache.

#### 3. Offline Fallback
If the user is offline, they won't be able to fetch word details from the API. To provide a good user experience, you should have an offline fallback.

*   **What to do:**
    *   If you have a cache, you can display the cached data when the user is offline.
    *   If the word is not in the cache and the user is offline, you should display a message indicating that an internet connection is required to fetch the details.
    *   You could also allow users to add their own definitions and examples, which would be available offline.

By considering these points, you can build a more robust and user-friendly app.
Include delete cache function in settings page.