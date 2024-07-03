import 'package:flutter/material.dart';
import 'weather_api.dart';
import 'weather_page.dart';
import 'package:weather/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SharedPreferences _preferences;

  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  final Map<String, Weather?> _weatherData = {
    'New Delhi': null,
    'Mumbai': null,
    'Noida': null,
    'Lucknow': null,
  };

  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData(); // Fetch initial weather data for searched cities
    _initSharedPreferences(); // Initialize shared preferences to store and retrieve last search

    _searchFocusNode.addListener(() {
      setState(() {}); // Update state when the focus on the search field
    });
  }

  /// Initializes shared preferences and retrieves the last search term
  Future<void> _initSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    setState(() {
      _lastSearch = _preferences.getString('lastSearch') ?? '';
    });
  }

  /// Fetches weather data for the searched cities and updates the state
  void _fetchWeatherData() {
    _weatherData.keys.forEach((name) {
      _wf.currentWeatherByCityName(name).then((weather) {
        setState(() {
          _weatherData[name] = weather;
        });
      }).catchError((error) {});
    });
  }

  /// Handles the search action, saves the search term, and navigates to the weather page
  void _onSearch() {
    String searchedItem = _searchController.text;
    _saveRecentSearch(searchedItem);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherPage(cityName: searchedItem),
      ),
    );
  }

  /// Saves the recent search term to shared preferences
  void _saveRecentSearch(String search) async {
    _lastSearch = search;
    await _preferences.setString('lastSearch', _lastSearch);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(onPressed: _fetchWeatherData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchField(), // Builds the search field
              const SizedBox(height: 16),
              if (_searchFocusNode.hasFocus && _lastSearch.isNotEmpty) _buildRecentSearchTile(), // Displays recent search if the search field is focused
              const SizedBox(height: 16),
              ..._weatherData.keys.map((name) => _buildWeatherContainer(name)), // Builds weather containers for predefined cities
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search bar with a search button
  Widget _buildSearchField() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search for a city',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _onSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }

  /// Builds the weather container for a given city
  Widget _buildWeatherContainer(String name) {
    Weather? weather = _weatherData[name];

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue.withOpacity(0.6),
        image: weather != null
            ? DecorationImage(
          image: NetworkImage(
            "http://openweathermap.org/img/wn/${weather.weatherIcon}@4x.png",
          ),
          fit: BoxFit.scaleDown,
        )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                if (weather != null)
                  Text(
                    '${weather.weatherDescription}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (weather != null)
                  Text(
                    '${weather.temperature?.celsius?.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                    ),
                  ),
                const Spacer(),
                if (weather != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9.0),
                    child: Column(
                      children: [
                        Text(
                          'H: ${weather.tempMax?.celsius?.toStringAsFixed(0)}° C ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'L: ${weather.tempMin?.celsius?.toStringAsFixed(0)}° C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (weather == null)
                  const Text(
                    'Fetching...',
                    style: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dropdown for the recent search city
  Widget _buildRecentSearchTile() {
    return Container(
      height: 25,
      color: Colors.transparent,
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_lastSearch),
            const Text(
              'last searched',
              style: TextStyle(
                color: Colors.black38,
                fontSize: 14,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _searchController.text = _lastSearch;
            _onSearch(); // Executes search on tapping the recent search tile
          });
        },
      ),
    );
  }
}
