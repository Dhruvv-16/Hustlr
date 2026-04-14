package com.example.winkit.domain.models

enum class EnvironmentType { CLEAR_DAY, NIGHT, HEATWAVE, RAIN, SMOG }

data class DashboardState(
    val environment: EnvironmentType,
    val wetBulbTemp: Int,
    val aqi: Int,
    val storeStatus: String
)
