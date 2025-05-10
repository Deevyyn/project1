import 'package:flutter_test/flutter_test.dart';
import 'package:cursortest/services/weather_service.dart';

void main() {
  test('OpenWeather API returns real-time weather data for Benin City', () async {
    final weatherService = WeatherService();
    
    // Get current weather
    final weatherData = await weatherService.getCurrentWeather();
    
    // Verify we got valid data
    expect(weatherData, isNotNull);
    expect(weatherData.temperature, isNotNull);
    expect(weatherData.humidity, isNotNull);
    expect(weatherData.windSpeed, isNotNull);
    expect(weatherData.description, isNotNull);
    
    // Print the weather data for manual verification
    print('\nCurrent Weather in Benin City:');
    print('Temperature: ${weatherData.temperature}°C');
    print('Feels Like: ${weatherData.feelsLike}°C');
    print('Humidity: ${(weatherData.humidity * 100).round()}%');
    print('Wind Speed: ${weatherData.windSpeed} m/s');
    print('Condition: ${weatherData.weatherCondition}');
    print('Description: ${weatherData.description}');
    print('Rain Intensity: ${weatherData.rainIntensity} mm/h');
    print('Visibility: ${weatherData.visibility / 1000} km');
    print('Time: ${weatherData.timestamp}');
  });

  test('OpenWeather API returns 5-day forecast for Benin City', () async {
    final weatherService = WeatherService();
    
    // Get forecast
    final forecastData = await weatherService.getWeatherForecast();
    
    // Verify we got valid forecast data
    expect(forecastData, isNotEmpty);
    expect(forecastData.length, lessThanOrEqualTo(5));
    
    // Print the forecast data for manual verification
    print('\n5-Day Forecast for Benin City:');
    for (var forecast in forecastData) {
      print('\nDate: ${forecast.timestamp}');
      print('Temperature: ${forecast.temperature}°C');
      print('Condition: ${forecast.weatherCondition}');
      print('Description: ${forecast.description}');
    }
  });
} 