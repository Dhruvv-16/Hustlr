package com.example.winkit.ui.screens.onboarding

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScheduleScreen(onBack: () -> Unit, onFinish: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    var selectedStore by remember { mutableStateOf("Chennai Hub (CH-7)") }
    
    // Set to keep track of multiple selected shifts
    val selectedShifts = remember { mutableStateListOf<String>() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(24.dp)
            .systemBarsPadding()
    ) {
        // Top Bar & Progress
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            IconButton(onClick = onBack, modifier = Modifier.size(32.dp)) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
            }
            Spacer(modifier = Modifier.width(16.dp))
            LinearProgressIndicator(
                progress = { 0.5f }, // 50%
                modifier = Modifier.weight(1f).height(8.dp).clip(RoundedCornerShape(4.dp)),
                color = Color(0xFF006C7A),
                trackColor = Color(0xFFE0E0E0)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text("50%", color = Color(0xFF006C7A), fontWeight = FontWeight.Bold, fontSize = 12.sp)
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Headers
        Text("Setup Your\nSchedule", fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF0A192F), lineHeight = 40.sp)
        Spacer(modifier = Modifier.height(8.dp))
        Text("This data helps us calculate your risk premium accurately based on location and time.", color = Color.Gray, fontSize = 14.sp)

        Spacer(modifier = Modifier.height(32.dp))

        // Dropdown for Store
        Text("PRIMARY DARK STORE", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
        Spacer(modifier = Modifier.height(8.dp))
        
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded }
        ) {
            OutlinedTextField(
                value = selectedStore,
                onValueChange = {},
                readOnly = true,
                leadingIcon = { Icon(Icons.Default.LocationOn, contentDescription = null, tint = Color(0xFF006C7A)) },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                modifier = Modifier.menuAnchor().fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(unfocusedBorderColor = Color.LightGray)
            )
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                listOf("Chennai Hub (CH-7)", "Bangalore Central (BLR-1)", "Mumbai South (BOM-4)").forEach { selectionOption ->
                    DropdownMenuItem(
                        text = { Text(selectionOption) },
                        onClick = {
                            selectedStore = selectionOption
                            expanded = false
                        }
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Shifts List
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text("TYPICAL SHIFTS", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
            Surface(color = Color(0xFFE8EAF6), shape = RoundedCornerShape(4.dp)) {
                Text("Multiple allowed", color = Color(0xFF3F51B5), fontSize = 10.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
            }
        }
        Spacer(modifier = Modifier.height(12.dp))

        ShiftItem("Morning Rush", "6:00 AM - 10:00 AM", "High Demand", Color(0xFFFFEBEE), Color(0xFFD32F2F), selectedShifts)
        Spacer(modifier = Modifier.height(12.dp))
        ShiftItem("Mid-Day Stable", "10:00 AM - 2:00 PM", null, Color.Transparent, Color.Transparent, selectedShifts)
        Spacer(modifier = Modifier.height(12.dp))
        ShiftItem("Evening Surge", "6:00 PM - 10:00 PM", "High Risk", Color(0xFFFFEBEE), Color(0xFFD32F2F), selectedShifts)

        Spacer(modifier = Modifier.weight(1f))

        Button(
            onClick = onFinish,
            enabled = selectedShifts.isNotEmpty(),
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0A192F), disabledContainerColor = Color.LightGray)
        ) {
            Text("Continue", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun ShiftItem(title: String, time: String, tag: String?, tagBg: Color, tagText: Color, selectedList: MutableList<String>) {
    val isSelected = selectedList.contains(title)
    
    Surface(
        modifier = Modifier.fillMaxWidth().clickable { 
            if (isSelected) selectedList.remove(title) else selectedList.add(title) 
        },
        shape = RoundedCornerShape(12.dp),
        border = BorderStroke(1.dp, if (isSelected) Color(0xFF006C7A) else Color.LightGray),
        color = Color.White
    ) {
        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Outlined.Circle,
                contentDescription = null,
                tint = if (isSelected) Color(0xFF006C7A) else Color.LightGray
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.Bold, color = Color(0xFF0A192F))
                Text(time, color = Color.Gray, fontSize = 12.sp)
            }
            if (tag != null) {
                Surface(color = tagBg, shape = RoundedCornerShape(4.dp)) {
                    Text(tag, color = tagText, fontSize = 10.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                }
            }
        }
    }
}
