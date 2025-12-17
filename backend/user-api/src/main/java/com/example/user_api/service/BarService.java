package com.example.user_api.service;

import com.example.user_api.entity.Bar;
import java.util.List;

public interface BarService {
    List<Bar> getAllBars();
    Bar getBarById(Long id);
    Bar getBarByName(String baname);
    Bar createBar(Bar bar);
    Bar updateBar(Bar bar);
    void deleteBar(Long id);
}
