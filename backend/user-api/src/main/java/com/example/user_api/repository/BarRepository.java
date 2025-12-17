package com.example.user_api.repository;

import com.example.user_api.entity.Bar;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BarRepository extends JpaRepository<Bar, Long> {

    // 根据吧名查询
    Bar findByBaname(String baname);

    // 判断吧名是否存在
    boolean existsByBaname(String baname);
}
