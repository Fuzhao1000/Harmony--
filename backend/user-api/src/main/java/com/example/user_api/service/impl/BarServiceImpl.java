package com.example.user_api.service.impl;

import com.example.user_api.entity.Bar;
import com.example.user_api.repository.BarRepository;
import com.example.user_api.service.BarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class BarServiceImpl implements BarService {

    @Autowired
    private BarRepository barRepository;

    @Override
    public List<Bar> getAllBars() {
        return barRepository.findAll();
    }

    @Override
    public Bar getBarById(Long id) {
        return barRepository.findById(id).orElse(null);
    }

    @Override
    public Bar getBarByName(String baname) {
        return barRepository.findByBaname(baname);
    }

    @Override
    public Bar createBar(Bar bar) {
        return barRepository.save(bar);
    }

    @Override
    public Bar updateBar(Bar bar) {
        if (bar.getId() == null) return null;
        return barRepository.save(bar);
    }

    @Override
    public void deleteBar(Long id) {
        barRepository.deleteById(id);
    }
}
