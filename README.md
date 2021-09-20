# movie-search
An iOS demo app that finds movies in The Open Movie Database. 

## Screenshots.
|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%201.png)|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%202.png)|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%203.png)|
|-------|-------|-------|
|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%204.png)|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%205.png)|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%206.png)|
|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%207.png)|![image](https://github.com/ncke/movie-search/blob/cd9c2846c9cab4568a3c08ef479033748822900f/Other/screenshot%208.png)|![image](https://github.com/ncke/movie-search/blob/b04be1ef44ed66871dbb9e3bb7c6c5936ba945bf/Other/screenshot%209.png)|

## The Open Movie Database API and API Key.

The Open Movie Database (OMDb) API is maintained by Brian Fritz (see http://www.omdbapi.com). If you want to run the application in a live environment, you will first need to obtain an API key from the OMDb. Keys are available at no cost [here](http://www.omdbapi.com/apikey.aspx).

Once you have an API key, edit it into the `MovieServiceEndpoint.swift` file as shown below:
![image](https://github.com/ncke/movie-search/blob/c1a9f1233d98342028b63cd2c41905014d570c72/Other/apikey.png)

## Description.

This app has an MVVM-C architecture with a single coordinator and two screens. The search screen allows the user to enter movie keywords and begin a search, it also shows the results. Tapping on a result will transition to a detail screen to show information for that movie.

### Coordinator:
* SearchCoordinator: handles routing between screens using a navigation controller. The coordinator also manages the API gateway and data stores.

The coordinator provides model instances to the user interface elements as required. Models are immediately available if they are already cached, or they may arrive later if fetched through the movie service API gateway. This means that updates must be notified to the user interface as new models arrive.

### Models:
* Movie: represents summary information about a movie.
* MovieDetail: detailed movie information.
* Poster: a movie poster, encapsulates data that can be used to generate a `UIImage`.
* MovieSearch: represents a search result returned by the service (only used by the API gateway which unwraps the individual `Movie` objects).

The Movie Detail model interprets the structured text of the `awards` field to produce the hieroglyphic representation. A similar approach is used for critic's scores. These help to add some visual interest to the detail information.

### Data Store:
* DataStore: a generic data store that provides store/fetch functionality.
* RandomAccessDataStore: a generic data store that provides random access based on an index.

The data stores are both based on `NSCache` which provides a simple thread-safe store.

### Network Service:
* MovieService: the API gateway providing access to search results, detailed movie information and poster images.
* MovieServiceDelegate: used to pass search results back to the app as they arrive.
* MovieServiceEndpoint: an enum used to construct URL's for the service.
* MovieServiceOperation: an `Operation` subclass to perform individual requests.

Callers only need to interact with the `MovieService` class and implement a `MovieServiceDelegate`.

The OMDb API uses paging with ten movies returned for each request. The app fetches the first ten pages automatically, delaying 0.5 seconds between the first three services calls and then 3 seconds between the remainder (to reduce pressure on the remote service and preserve local bandwidth for poster requests). Rather than callbacks, a delegate is used to return search results (to the coordinator) because multiple sets of result (pages) are anticipated.

### User Interface:
* SearchViewController: uses a collection view to present results, can animtate a banner to show errors.
* MovieCollectionViewCell: the collection view cell used to show movie summaries in the search view controller.
* DetailViewController: shows movie details, the header has adaptive constraints to reduce the size of the poster in landscape orientation.
* DetailTableViewCell: a table view cell used by the detail view controller (movie information is shown in using a table).

## Toolchain.

Xcode 12.5.1 and Swift 5.

## Future Development.

The app would benefit from tests to provide stability for ongoing development.

The movie search is currently limited to showing the first hundred results. Ideally, further results would be polled from the service when the user scrolls to the end of the list with a placeholder shown. A simple alternative would be to include a message at the end of the list stating that more results are available (we do know how many) -- this prompts the user to refine their search.

The size of the poster cache is limited to 400 items because of the larger data sizes involved (usually around 40Kb per poster). Once evicted from the cache, posters are not re-fetched from the service unless a new search request is made. In practice this is not problematic, but ideally the app would re-fetch automatically.

The OMDb service is returning some duplicate search results, even within the same page. These could be filtered out by IMDB identifier. Time constraints.
