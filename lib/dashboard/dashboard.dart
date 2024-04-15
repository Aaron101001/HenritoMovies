import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: const RecentMovies(),
    );
  }
}

class RecentMovies extends StatefulWidget {
  const RecentMovies({Key? key}) : super(key: key);

  @override
  _RecentMoviesState createState() => _RecentMoviesState();
}

class _RecentMoviesState extends State<RecentMovies> {
  late List<dynamic> _recentMoviesData = [];
  late List<dynamic> _recentSeriesData = [];
  late Map<int, String> _genres = {};

  @override
  void initState() {
    super.initState();
    _fetchRecentData();
    _fetchGenres();
  }

  Future<void> _fetchRecentData() async {
    final movieUrl =
        'https://api.themoviedb.org/3/movie/popular?api_key=ded71725655780ba4d50e97a4eccdeec';
    final seriesUrl =
        'https://api.themoviedb.org/3/tv/popular?api_key=ded71725655780ba4d50e97a4eccdeec';

    final movieResponse = await http.get(Uri.parse(movieUrl));
    final seriesResponse = await http.get(Uri.parse(seriesUrl));

    if (movieResponse.statusCode == 200 && seriesResponse.statusCode == 200) {
      final movieData = json.decode(movieResponse.body)['results'];
      final seriesData = json.decode(seriesResponse.body)['results'];

      setState(() {
        _recentMoviesData = movieData;
        _recentSeriesData = seriesData;
      });
    } else {
      throw Exception('Failed to load recent data');
    }
  }

  Future<void> _fetchGenres() async {
    final genreUrl =
        'https://api.themoviedb.org/3/genre/movie/list?api_key=ded71725655780ba4d50e97a4eccdeec';
    final response = await http.get(Uri.parse(genreUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['genres'];
      final Map<int, String> genres = {};
      for (var genre in data) {
        genres[genre['id']] = genre['name'];
      }
      setState(() {
        _genres = genres;
      });
    } else {
      throw Exception('Failed to load genres');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Henrito Movies'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        children: _buildSections(),
      ),
    );
  }

  List<Widget> _buildSections() {
    List<Widget> sections = [];
    sections.add(_buildMovieCarousel());

    List<dynamic> allData = [..._recentMoviesData, ..._recentSeriesData];

    Map<String, List<dynamic>> dataByGenre = {};
    for (var item in allData) {
      List<int> genreIds = List<int>.from(item['genre_ids']);
      for (var genreId in genreIds) {
        String genreName = _genres[genreId] ?? 'Otros';
        dataByGenre.putIfAbsent(genreName, () => []);
        dataByGenre[genreName]!.add(item);
      }
    }

    dataByGenre.forEach((genre, data) {
      sections.add(_buildSectionHeader(genre));
      sections.add(_buildGenreItemList(data));
      sections.add(SizedBox(height: 20));
    });

    return sections;
  }

  Widget _buildMovieCarousel() {
    if (_recentMoviesData.length < 5) {
      return SizedBox.shrink(); 
    }
    final topMovies = _recentMoviesData.sublist(0, 5);
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 3),
      ),
      items: topMovies.map<Widget>((movie) {
        final imageUrl = 'https://image.tmdb.org/t/p/w500${movie['backdrop_path']}';
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () => _showMovieDetails(context, movie),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                child: Image.network(imageUrl),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  void _showMovieDetails(BuildContext context, dynamic movie) async {
    // ignore: unused_local_variable
    final youtubeApiKey = 'AIzaSyA4jNbxcGEW8S8U7U1QYYThnn6yJRFp0rk';
    final trailerUrl =
        'https://api.themoviedb.org/3/movie/${movie['id']}/videos?api_key=ded71725655780ba4d50e97a4eccdeec';

    final response = await http.get(Uri.parse(trailerUrl));
    if (response.statusCode == 200) {
      final videoData = json.decode(response.body)['results'];
      if (videoData.isNotEmpty) {
        final videoKey = videoData[0]['key'];
        _showTrailerDialog(context, movie, videoKey);
      } else {
        _showNoTrailerDialog(context, movie);
      }
    } else {
      _showNoTrailerDialog(context, movie);
    }
  }

  void _showTrailerDialog(BuildContext context, dynamic movie, String videoKey) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(movie['title'] ?? movie['name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (movie['release_date'] != null)
                Text('Release Date: ${movie['release_date']}'),
              if (movie['overview'] != null)
                Text('Overview: ${movie['overview']}'),
              SizedBox(height: 10),
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoKey,
                  flags: YoutubePlayerFlags(
                    autoPlay: true,
                    mute: false,
                  ),
                ),
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNoTrailerDialog(BuildContext context, dynamic movie) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(movie['title'] ?? movie['name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (movie['release_date'] != null)
                Text('Release Date: ${movie['release_date']}'),
              if (movie['overview'] != null)
                Text('Overview: ${movie['overview']}'),
              SizedBox(height: 10),
              Text('Trailer not available.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGenreItemList(List<dynamic> dataList) {
    return Container(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: dataList.map<Widget>((item) {
          final imageUrl = 'https://image.tmdb.org/t/p/w500${item['backdrop_path']}';
          final genreIds = List<int>.from(item['genre_ids']);
          final genres = genreIds.map((id) => _genres[id]).toList().join(', ');
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => _showMovieDetails(context, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(imageUrl),
                  ),
                  SizedBox(height: 5),
                  Text(item['title'] ?? item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(genres),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
