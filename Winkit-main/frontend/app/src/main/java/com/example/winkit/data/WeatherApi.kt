package com.example.winkit.data
import com.example.winkit.BuildConfig
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query

// 1. Data classes to catch the OpenWeather JSON
data class WeatherResponse(
    val main: MainStats,
    val weather: List<WeatherDetail>,
    val name: String
)

data class MainStats(
    val temp: Double,
    val feels_like: Double,
    val humidity: Int
)

data class WeatherDetail(
    val main: String, // e.g., "Rain", "Clouds", "Clear"
    val description: String
)

// 2. Retrofit Interface
interface OpenWeatherService {
    @GET("data/2.5/weather")
    suspend fun getCurrentWeather(
        @Query("q") city: String = "Chennai",
        @Query("units") units: String = "metric",
        @Query("appid") apiKey: String = BuildConfig.OPENWEATHER_API_KEY // 🔴 PASTE KEY HERE
    ): WeatherResponse
}

// 3. Network Builder
object WeatherNetwork {
    val api: OpenWeatherService by lazy {
        Retrofit.Builder()
            .baseUrl("https://api.openweathermap.org/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(OpenWeatherService::class.java)
    }
}
