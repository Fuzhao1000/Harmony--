package com.example.user_api.controller;

import com.example.user_api.entity.Bar;
import com.example.user_api.service.BarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/bars")
public class BarController {

    @Autowired
    private BarService barService;

    @GetMapping
    public List<Bar> getAllBars() {
        return barService.getAllBars();
    }

    @GetMapping("/{id}")
    public Bar getBarById(@PathVariable Long id) {
        return barService.getBarById(id);
    }

    @GetMapping("/byName")
    public Bar getBarByName(@RequestParam String baname) {
        return barService.getBarByName(baname);
    }

    @PostMapping
    public Bar createBar(@RequestBody Bar bar) {
        return barService.createBar(bar);
    }

    @PutMapping
    public Bar updateBar(@RequestBody Bar bar) {
        return barService.updateBar(bar);
    }

    @DeleteMapping("/{id}")
    public void deleteBar(@PathVariable Long id) {
        barService.deleteBar(id);
    }
}
