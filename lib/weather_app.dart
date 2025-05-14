import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_api_project/weather.dart';
import 'package:flutter_api_project/weather_detail_item.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> with TickerProviderStateMixin {
  bool isLoading = true;
  String errorMessage = '';
  Weather? currentWeather;
  List<Weather> dailyForecast = [];
  List<String> cities = ['New York', 'London', 'Tokyo', 'Sydney', 'Paris'];
  String selectedCity = 'New York';
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    fetchWeather(selectedCity);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    const apiKey = '2db5196e56d70af8d089101a67b1137d';

    try {
      final currentResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey'));

      if (currentResponse.statusCode == 200) {
        final data = json.decode(currentResponse.body);
        currentWeather = Weather.fromJson(data);

        final forecastResponse = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$city&units=metric&appid=$apiKey'));

        if (forecastResponse.statusCode == 200) {
          final forecastData = json.decode(forecastResponse.body);

          final List<dynamic> list = forecastData['list'];
          final Map<String, Weather> dailyMap = {};

          for (var item in list) {
            final weather = Weather.fromForecast(item);
            final day = DateFormat('yyyy-MM-dd').format(weather.date);

            if (!dailyMap.containsKey(day)) {
              dailyMap[day] = weather;
            }
          }

          dailyForecast = dailyMap.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          if (dailyForecast.length > 5) {
            dailyForecast = dailyForecast.sublist(0, 5);
          }

          setState(() {
            isLoading = false;
            selectedCity = city;
          });

          _fadeController.reset();
          _slideController.reset();
          _fadeController.forward();
          _slideController.forward();
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load weather data';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return '☀️';
      case '01n':
        return '🌙';
      case '02d':
      case '02n':
        return '⛅';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧️';
      case '10d':
      case '10n':
        return '🌦️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '🌈';
    }
  }

  LinearGradient getWeatherGradient(String iconCode) {
    if (iconCode.startsWith('01')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A91FF), Color(0xFF6BBBF7)],
      );
    } else if (iconCode.startsWith('02') ||
        iconCode.startsWith('03') ||
        iconCode.startsWith('04')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6B8AF2), Color(0xFF8B9DF2)],
      );
    } else if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF425D89), Color(0xFF698AAE)],
      );
    } else if (iconCode.startsWith('11')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2D3A5C), Color(0xFF46537A)],
      );
    } else if (iconCode.startsWith('13')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7BA0C8), Color(0xFFA8C5E5)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7E889B), Color(0xFFA8B0C2)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: currentWeather != null
                  ? getWeatherGradient(currentWeather!.iconCode)
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6B8AF2), Color(0xFF8B9DF2)],
                    ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : currentWeather == null
                        ? Container()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: selectedCity,
                                          icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.white),
                                          dropdownColor:
                                              const Color(0xFF6B8AF2),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              fetchWeather(newValue);
                                            }
                                          },
                                          items: cities
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      DateFormat('EEEE, d MMMM')
                                          .format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${currentWeather!.temperature.round()}°',
                                              style: const TextStyle(
                                                fontSize: 70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              currentWeather!.description,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.arrow_upward_rounded,
                                                    size: 16),
                                                Text(
                                                    '${currentWeather!.tempMax.round()}°',
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                const SizedBox(width: 16),
                                                const Icon(
                                                    Icons
                                                        .arrow_downward_rounded,
                                                    size: 16),
                                                Text(
                                                    '${currentWeather!.tempMin.round()}°',
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          getWeatherIcon(
                                              currentWeather!.iconCode),
                                          style: const TextStyle(fontSize: 80),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          WeatherDetailItem(
                                            icon: Icons.water_drop_outlined,
                                            value:
                                                '${currentWeather!.humidity}%',
                                            label: 'Humidity',
                                          ),
                                          WeatherDetailItem(
                                            icon: Icons.air_outlined,
                                            value:
                                                '${currentWeather!.windSpeed} km/h',
                                            label: 'Wind',
                                          ),
                                          WeatherDetailItem(
                                            icon: Icons.visibility_outlined,
                                            value:
                                                '${(currentWeather!.visibility / 1000).toStringAsFixed(1)} km',
                                            label: 'Visibility',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      '5-Day Forecast',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: dailyForecast.length,
                                        itemBuilder: (context, index) {
                                          final forecast = dailyForecast[index];
                                          return Container(
                                            width: 100,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  DateFormat('E')
                                                      .format(forecast.date),
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  getWeatherIcon(
                                                      forecast.iconCode),
                                                  style: const TextStyle(
                                                      fontSize: 30),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${forecast.temperature.round()}°',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
